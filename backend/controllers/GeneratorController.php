<?php
/**
 * ═══════════════════════════════════════════════════════════════════
 *  Generator Controller – Bitar PMS
 *  Handles API requests for Daily Logs, bridging to Python FastAPI
 * ═══════════════════════════════════════════════════════════════════
 */

class GeneratorController {
    private $db;
    private $python_api_url = "http://localhost:8000/api/v1/generator/analyze";

    public function __construct() {
        // Assume Database class is available globally or included in router
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Submit a new daily log
     */
    public function addDailyLog() {
        $data = json_decode(file_get_contents("php://input"), true);
        
        $generator_id    = $data['generator_id']    ?? null;
        $submitted_hours = isset($data['submitted_hours']) ? $data['submitted_hours'] : null; // Cumulative meter reading
        $manual_hours    = isset($data['manual_hours'])    ? floatval($data['manual_hours']) : null; // Direct "hours worked today"
        $date            = $data['date'] ?? date('Y-m-d');

        if (!$generator_id) {
            http_response_code(400);
            echo json_encode(['error' => 'generator_id is required']);
            return;
        }
        if ($submitted_hours === null && $manual_hours === null) {
            http_response_code(400);
            echo json_encode(['error' => 'At least one of submitted_hours (meter reading) or manual_hours (hours worked today) is required']);
            return;
        }

        // Fetch generator details
        $stmt = $this->db->prepare("SELECT * FROM generators WHERE id = ?");
        $stmt->execute([$generator_id]);
        $generator = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$generator) {
            http_response_code(404);
            echo json_encode(['error' => 'Generator not found']);
            return;
        }

        // Fetch previous log (EXCLUDING TODAY so resubmissions calculate against yesterday)
        $stmt = $this->db->prepare("SELECT submitted_hours FROM daily_logs WHERE generator_id = ? AND date < CURDATE() ORDER BY date DESC, id DESC LIMIT 1");
        $stmt->execute([$generator_id]);
        $prevLog   = $stmt->fetch(PDO::FETCH_ASSOC);
        $prev_hours = $prevLog ? floatval($prevLog['submitted_hours']) : floatval($generator['initial_meter_reading'] ?? 0);

        // ── Decision Tree ──────────────────────────────────────────────────────
        $input_method    = '';
        $calculated_hours = 0;
        $new_meter_value  = $submitted_hours;   // what we'll store as "submitted_hours" in DB
        $mismatch_flag    = false;

        $has_meter  = ($submitted_hours !== null);
        $has_manual = ($manual_hours    !== null);

        if ($has_meter && !$has_manual) {
            // ── Scenario B: Meter Only ──
            $input_method = 'Meter Only';
            $submitted_hours = floatval($submitted_hours);
            if ($prev_hours !== null && $submitted_hours < $prev_hours) {
                http_response_code(400);
                echo json_encode(['error' => "Meter reading ($submitted_hours) cannot be less than previous reading ($prev_hours)"]);
                return;
            }
            $calculated_hours = ($prev_hours !== null) ? ($submitted_hours - $prev_hours) : 0;
            $new_meter_value  = $submitted_hours;

        } elseif ($has_manual && !$has_meter) {
            // ── Scenario A: Hours Only ──
            $input_method = 'Hours Only';
            $calculated_hours = $manual_hours;
            // Roll the meter forward in the background so future deltas still work
            $new_meter_value  = ($prev_hours !== null) ? ($prev_hours + $manual_hours) : $manual_hours;

        } else {
            // ── Scenario C: Both ──
            $input_method = 'Both';
            $submitted_hours = floatval($submitted_hours);
            $meter_delta = ($prev_hours !== null) ? ($submitted_hours - $prev_hours) : 0;
            // Cross-reference: allow ±0.5h tolerance for rounding
            if (abs($meter_delta - $manual_hours) > 0.5) {
                $mismatch_flag = true;
            }
            // Trust the meter reading as primary source; flag mismatch for AI
            $calculated_hours = $meter_delta;
            $new_meter_value  = $submitted_hours;
        }
        // ──────────────────────────────────────────────────────────────────────

        $factory_burn_rate = floatval($generator['expected_fuel_consumption_per_hour'] ?? 0);
        $expected_fuel     = $calculated_hours * $factory_burn_rate;

        // Fetch current fuel price for historical locking
        $priceStmt = $this->db->prepare("SELECT cost_per_liter FROM fuel_movements WHERE generator_id = ? AND type='Refill' ORDER BY date DESC LIMIT 1");
        $priceStmt->execute([$generator_id]);
        $latestPrice = $priceStmt->fetchColumn();
        $fuel_price_at_time = $latestPrice ? floatval($latestPrice) : 850.0;

        // Save to DB
        $stmt = $this->db->prepare("
            INSERT INTO daily_logs 
            (generator_id, date, submitted_hours, calculated_hours_worked, expected_factory_fuel_burn, status_flag, fuel_price_at_time) 
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ");
        $stmt->execute([
            $generator_id, $date, $new_meter_value,
            $calculated_hours, $expected_fuel,
            $mismatch_flag ? 'Data Entry Mismatch' : 'Pending Analysis',
            $fuel_price_at_time
        ]);
        
        $log_id = $this->db->lastInsertId();

        echo json_encode([
            'status'       => 'success',
            'message'      => 'Daily log added successfully',
            'log_id'       => $log_id,
            'input_method' => $input_method,
            'hours_worked' => $calculated_hours,
            'mismatch'     => $mismatch_flag
        ]);
    }


    /**
     * Run Python API Analysis
     */
    public function runAnalysis() {
        $log_id = $_GET['log_id'] ?? null;
        if (!$log_id) {
            $input = json_decode(file_get_contents('php://input'), true);
            $log_id = $input['log_id'] ?? null;
        }

        if (!$log_id) {
            http_response_code(400);
            echo json_encode(['error' => 'Missing log_id']);
            return;
        }

        // Fetch current log
        $stmt = $this->db->prepare("SELECT * FROM daily_logs WHERE id = ?");
        $stmt->execute([$log_id]);
        $log = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$log) {
            // Fallback: Check if the log_id was actually a generator_daily_reports ID
            $stmtFallback = $this->db->prepare("SELECT generator_id, date FROM generator_daily_reports WHERE id = ?");
            $stmtFallback->execute([$log_id]);
            $oldReport = $stmtFallback->fetch(PDO::FETCH_ASSOC);
            
            if ($oldReport) {
                // Find corresponding daily_logs entry
                $stmtFind = $this->db->prepare("SELECT * FROM daily_logs WHERE generator_id = ? AND date = ? ORDER BY id DESC LIMIT 1");
                $stmtFind->execute([$oldReport['generator_id'], $oldReport['date']]);
                $log = $stmtFind->fetch(PDO::FETCH_ASSOC);
                if ($log) {
                    $log_id = $log['id']; // Correct the log_id to the daily_logs ID
                }
            }
        }

        if (!$log) {
            http_response_code(404);
            echo json_encode(['error' => 'Log not found in daily_logs or generator_daily_reports']);
            return;
        }

        $generator_id = $log['generator_id'];

        // Fetch generator details
        $stmt = $this->db->prepare("SELECT * FROM generators WHERE id = ?");
        $stmt->execute([$generator_id]);
        $generator = $stmt->fetch(PDO::FETCH_ASSOC);

        // Fetch previous reading
        $stmt = $this->db->prepare("SELECT submitted_hours, admin_actual_fuel, predicted_fuel_remaining FROM daily_logs WHERE generator_id = ? AND id < ? ORDER BY date DESC, id DESC LIMIT 1");
        $stmt->execute([$generator_id, $log_id]);
        $prevLog = $stmt->fetch(PDO::FETCH_ASSOC);
        $prev_hours = $prevLog ? $prevLog['submitted_hours'] : null;

        // Previous tank level: prefer previous day's physical dip, then AI prediction, then generator's current_fuel field
        $prev_tank_level = null;
        if ($prevLog) {
            if ($prevLog['admin_actual_fuel'] !== null) {
                $prev_tank_level = floatval($prevLog['admin_actual_fuel']);
            } elseif ($prevLog['predicted_fuel_remaining'] !== null) {
                $prev_tank_level = floatval($prevLog['predicted_fuel_remaining']);
            }
        }
        if ($prev_tank_level === null) {
            $prev_tank_level = floatval($generator['current_fuel'] ?? 800);
        }

        // Fetch historical logs for ML
        $stmt = $this->db->prepare("SELECT calculated_hours_worked, admin_actual_fuel FROM daily_logs WHERE generator_id = ? AND id < ? ORDER BY date DESC LIMIT 14");
        $stmt->execute([$generator_id, $log_id]);
        $historical_logs = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Prepare payload for Python Microservice
        $factory_burn_rate = $generator['expected_fuel_consumption_per_hour'] ?? 0;
        
        // Determine input method used when log was submitted
        $input_method = 'Meter Only'; // default for legacy logs
        if ($log['status_flag'] === 'Data Entry Mismatch') {
            $input_method = 'Both (Mismatch)';
        }
        
        // Fetch today's fuel refills (sum of fuel added today for this generator)
        $refillStmt = $this->db->prepare("
            SELECT COALESCE(SUM(amount), 0) as total_added 
            FROM fuel_movements 
            WHERE generator_id = ? AND DATE(date) = ? AND type IN ('Refill', 'Transfer_In')
        ");
        $refillStmt->execute([$generator_id, $log['date']]);
        $refill = $refillStmt->fetch(PDO::FETCH_ASSOC);
        $fuel_added_today = floatval($refill['total_added'] ?? 0);
        
        // Fetch latest fuel price from fuel movements
        $priceStmt = $this->db->prepare("SELECT cost_per_liter FROM fuel_movements WHERE generator_id = ? AND type='Refill' ORDER BY date DESC LIMIT 1");
        $priceStmt->execute([$generator_id]);
        $latestPrice = $priceStmt->fetchColumn();
        $fuel_price = $latestPrice ? floatval($latestPrice) : 850.0;
        
        // Use historical locked price if available
        if (isset($log['fuel_price_at_time']) && floatval($log['fuel_price_at_time']) > 0) {
            $fuel_price = floatval($log['fuel_price_at_time']);
        }

        $payload = [
            "generator_id"              => (int)$generator_id,
            "submission_date"           => $log['date'],
            "submitted_hours"           => (float)$log['submitted_hours'],
            "previous_day_hours"        => $prev_hours !== null ? (float)$prev_hours : null,
            "calculated_hours_worked"   => (float)$log['calculated_hours_worked'],
            "input_method"              => $input_method,
            "factory_burn_rate_per_hour"=> (float)$factory_burn_rate,
            // New enterprise fuel fields
            "previous_tank_level"       => $prev_tank_level,
            "fuel_added_today"          => $fuel_added_today,
            "agent_reported_tank"       => $log['admin_actual_fuel'] !== null ? (float)$log['admin_actual_fuel'] : null,
            "fuel_price_per_liter"      => $fuel_price,
            "historical_logs"           => $historical_logs
        ];

        // Native PHP Gemini API Call
        $previous_tank = $payload['previous_tank_level'];
        $fuel_added = $payload['fuel_added_today'];
        $agent_tank = $payload['agent_reported_tank'];
        $fuel_price = $payload['fuel_price_per_liter'];
        $consumption_rate = $payload['factory_burn_rate_per_hour'];
        $input_method = $payload['input_method'];
        $hours_worked_today = $payload['calculated_hours_worked'];
        $submitted_hours = $payload['submitted_hours'];
        $previous_day_hours = $payload['previous_day_hours'];

        $agent_tank_display = $agent_tank !== null ? $agent_tank : "NOT_PROVIDED";

        $system_prompt = "
SYSTEM ROLE:
You are an expert Enterprise Generator & Fuel Management AI Engine. Your job is to analyze daily generator logs, calculate fuel burn rates, integrate fuel deliveries, and detect theft or mechanical anomalies (The \"VOL\" Flag) based on strict mathematical rules.

=== LIVE INPUT DATA ===
Input Method Used: {$input_method}
Previous Meter Hours: {$previous_day_hours}
Current Meter Hours: {$submitted_hours}
Pre-Calculated Run Time (by system): {$hours_worked_today} hours
Factory Consumption Rate: {$consumption_rate} L/h
Previous Tank Level: {$previous_tank} L
Fuel Added Today (Refills): {$fuel_added} L
Agent Reported Current Tank: {$agent_tank_display}
Fuel Price Per Liter: {$fuel_price} CFA/L

=== SYSTEM RULES & LOGIC ===

STEP 1: DETERMINE REAL RUN TIME
- Trust the Pre-Calculated Run Time of {$hours_worked_today} hours already computed by the system.
- If Input Method is \"Both (Mismatch)\": Immediately flag vol_theft_alert=true, error_type=\"DATA_ENTRY_MISMATCH\".
- IF Run Time > 24 hours: Return status \"error\" with error_type \"RUNTIME_EXCEEDS_24H\".
- IF Run Time == 0: This is a BASELINE SETUP. Set all fuel fields to 0, no anomaly.

STEP 2: THE ESTIMATES (THE BASELINE)
- Estimated Fuel Spent = Run Time * Factory Consumption Rate = {$hours_worked_today} * {$consumption_rate}
- Estimated Tank Remaining = (Previous Tank Level + Fuel Added Today) - Estimated Fuel Spent = ({$previous_tank} + {$fuel_added}) - Estimated Fuel Spent

STEP 3: THE ACTUALS & VARIANCE
If Agent Reported Current Tank is NOT \"NOT_PROVIDED\":
- Actual Fuel Spent = (Previous Tank Level + Fuel Added Today) - Agent Reported Current Tank = ({$previous_tank} + {$fuel_added}) - {$agent_tank_display}
- Actual Consumption Rate (L/h) = Actual Fuel Spent / Run Time
- Missing Fuel Variance (Liters) = Actual Fuel Spent - Estimated Fuel Spent
- Financial Loss = Missing Fuel Variance * {$fuel_price} (ONLY if variance > 0)
If Agent Reported Current Tank is \"NOT_PROVIDED\":
- Set actual_fuel_spent_l = null, actual_consumption_rate_lh = null, missing_fuel_variance_l = 0.0, financial_loss_amount = 0.0

STEP 4: THE \"VOL\" ANOMALY THRESHOLD
- IF Actual Consumption Rate > Factory Consumption Rate by more than 5%: Set vol_theft_alert = true
- IF Actual Fuel Spent is massively lower than expected (>5% extra fuel remaining): Flag \"SENSOR_ERROR_OR_UNRECORDED_REFILL\" in ai_diagnosis_message
- IF Input Method is \"Both (Mismatch)\": Set vol_theft_alert = true, error_type = \"DATA_ENTRY_MISMATCH\"

=== REQUIRED JSON OUTPUT FORMAT ===
Respond STRICTLY in valid JSON. No markdown. No extra text. Exact keys:
{
  \"status\": \"success\" | \"error\",
  \"engine_run_time_hours\": float,
  \"estimated_fuel_spent_l\": float,
  \"estimated_remaining_tank_l\": float,
  \"actual_fuel_spent_l\": float or null,
  \"actual_consumption_rate_lh\": float or null,
  \"missing_fuel_variance_l\": float,
  \"financial_loss_amount\": float,
  \"vol_theft_alert\": boolean,
  \"ai_diagnosis_message\": \"string\"
}
";

        $gemini_api_key = $_ENV['GEMINI_API_KEY'] ?? '';
        if (empty($gemini_api_key)) {
            http_response_code(500);
            echo json_encode(['error' => 'GEMINI_API_KEY is missing in backend .env']);
            return;
        }

        $gemini_url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=" . $gemini_api_key;
        $gemini_payload = [
            'contents' => [
                [
                    'parts' => [
                        ['text' => $system_prompt]
                    ]
                ]
            ],
            'generationConfig' => [
                'responseMimeType' => 'application/json'
            ]
        ];

        if (session_status() === PHP_SESSION_ACTIVE) {
            session_write_close();
        }
        $ch = curl_init($gemini_url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($gemini_payload));
        curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 10);
        curl_setopt($ch, CURLOPT_TIMEOUT, 120); // Gemini can be slow, allow up to 2 minutes
        $response = curl_exec($ch);
        $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if (!$response) {
            http_response_code(500);
            echo json_encode(['error' => 'No response from Gemini API. Check your network.']);
            return;
        }
        if ($http_code === 429) {
            http_response_code(429);
            echo json_encode(['error' => 'AI quota exceeded. You have reached the daily limit for AI analysis. Please try again tomorrow or upgrade your Gemini API plan.']);
            return;
        }
        if ($http_code !== 200) {
            http_response_code(500);
            $errBody = json_decode($response, true);
            $errMsg = $errBody['error']['message'] ?? $response;
            echo json_encode(['error' => 'Gemini API error: ' . $errMsg]);
            return;
        }

        $gemini_data = json_decode($response, true);
        $raw_text = $gemini_data['candidates'][0]['content']['parts'][0]['text'] ?? '{}';
        
        // Clean up markdown
        $raw_text = trim($raw_text);
        if (str_starts_with($raw_text, "```json")) $raw_text = substr($raw_text, 7);
        if (str_starts_with($raw_text, "```")) $raw_text = substr($raw_text, 3);
        if (str_ends_with($raw_text, "```")) $raw_text = substr($raw_text, 0, -3);

        $ai_result = json_decode(trim($raw_text), true);
        if (!$ai_result) {
            http_response_code(500);
            echo json_encode(['error' => 'Failed to parse Gemini response as JSON', 'raw' => $raw_text]);
            return;
        }

        // Map to frontend metrics
        $metrics = [
            "hours_worked_today"         => $ai_result["engine_run_time_hours"] ?? 0.0,
            "expected_fuel_burn_factory" => $ai_result["estimated_fuel_spent_l"] ?? 0.0,
            "ml_predicted_fuel_burn"     => null,
            "predicted_remaining_fuel"   => $ai_result["estimated_remaining_tank_l"] ?? 0.0,
            "actual_fuel_spent"          => $ai_result["actual_fuel_spent_l"] ?? null,
            "actual_consumption_rate"    => $ai_result["actual_consumption_rate_lh"] ?? null,
            "missing_fuel_variance"      => $ai_result["missing_fuel_variance_l"] ?? 0.0,
            "financial_loss_cfa"         => $ai_result["financial_loss_amount"] ?? 0.0,
            "anomaly_detected"           => $ai_result["vol_theft_alert"] ?? false,
            "vol_theft_alert"            => $ai_result["vol_theft_alert"] ?? false,
            "admin_actual_fuel"          => $log['admin_actual_fuel'] !== null ? (float)$log['admin_actual_fuel'] : null,
        ];
        $ai_report = $ai_result["ai_diagnosis_message"] ?? "Analysis complete.";
            
            $status_flag = $metrics['anomaly_detected'] ? 'Anomaly Detected' : 'Normal';

            // Update Database with AI metrics
            $stmt = $this->db->prepare("
                UPDATE daily_logs 
                SET ml_predicted_fuel_burn = ?, 
                    predicted_fuel_remaining = ?,
                    actual_fuel_spent = ?,
                    actual_consumption_rate = ?,
                    missing_fuel_variance = ?,
                    financial_loss_cfa = ?,
                    ai_report = ?, 
                    status_flag = ? 
                WHERE id = ?
            ");
            $stmt->execute([
                $metrics['ml_predicted_fuel_burn'],
                $metrics['predicted_remaining_fuel'],
                $metrics['actual_fuel_spent'],
                $metrics['actual_consumption_rate'],
                $metrics['missing_fuel_variance'],
                $metrics['financial_loss_cfa'],
                $ai_report,
                $status_flag,
                $log_id
            ]);

            echo json_encode([
                'status' => 'success',
                'metrics' => $metrics,
                'ai_report' => $ai_report
            ]);

    }

    /**
     * Get Today's Logs for the Dashboard
     */
    /**
     * Get Logs for a specific month for the Dashboard
     */
    public function getMonthLogs() {
        $date = $_GET['date'] ?? date('Y-m-d');
        // Extract year and month from the date (e.g. '2026-08')
        $yearMonth = substr($date, 0, 7);
        $generator_id = $_GET['generator_id'] ?? null;
        
        $stmt = $this->db->prepare("
            SELECT d.*, g.name as generator_name 
            FROM daily_logs d
            JOIN generators g ON d.generator_id = g.id
            WHERE d.date LIKE ? AND d.generator_id = ?
            ORDER BY d.date DESC, d.created_at DESC
        ");
        $stmt->execute([$yearMonth . '%', $generator_id]);
        $logs = $stmt->fetchAll(PDO::FETCH_ASSOC);

        echo json_encode(['status' => 'success', 'data' => $logs]);
    }

    /**
     * Update Admin Actual Fuel (Override)
     */
    public function updateActualFuel() {
        $raw = file_get_contents("php://input");
        $data = json_decode($raw, true);
        $log_id = $data['log_id'] ?? null;
        $actual_fuel = $data['actual_fuel'] ?? null;

        if (!$log_id || $actual_fuel === null) {
            http_response_code(400);
            echo json_encode(['error' => 'log_id and actual_fuel are required']);
            return;
        }

        $stmt = $this->db->prepare("UPDATE daily_logs SET admin_actual_fuel = ? WHERE id = ?");
        $stmt->execute([$actual_fuel, $log_id]);

        // Automatically re-run the AI analysis with the new actual fuel.
        // We must set $_GET['log_id'] because php://input can only be read once
        // (already consumed above), so runAnalysis() reads from $_GET instead.
        $_GET['log_id'] = $log_id;
        $this->runAnalysis();
    }

    public function verifyLog() {
        $data = json_decode(file_get_contents("php://input"), true);
        $log_id = $data['log_id'] ?? null;

        if (!$log_id) {
            http_response_code(400);
            echo json_encode(['error' => 'log_id is required']);
            return;
        }

        $stmt = $this->db->prepare("UPDATE daily_logs SET status_flag = 'Verified' WHERE id = ?");
        $stmt->execute([$log_id]);

        // Fetch the verified log to update the generator's official fuel level
        $stmt = $this->db->prepare("SELECT generator_id, predicted_fuel_remaining, admin_actual_fuel FROM daily_logs WHERE id = ?");
        $stmt->execute([$log_id]);
        $log = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($log) {
            $new_fuel = $log['admin_actual_fuel'] !== null ? $log['admin_actual_fuel'] : $log['predicted_fuel_remaining'];
            if ($new_fuel !== null) {
                $updateGen = $this->db->prepare("UPDATE generators SET current_fuel = ? WHERE id = ?");
                $updateGen->execute([$new_fuel, $log['generator_id']]);
            }
        }

        echo json_encode(['status' => 'success', 'message' => 'Log verified successfully']);
    }

    /**
     * Uses Gemini Vision to extract numbers from a meter photo
     */
    public function extractMeterReading() {
        if (!isset($_FILES['photo']) || $_FILES['photo']['error'] !== UPLOAD_ERR_OK) {
            http_response_code(400);
            echo json_encode(['error' => 'No valid photo uploaded']);
            return;
        }

        $tmpName = $_FILES['photo']['tmp_name'];
        $mimeType = mime_content_type($tmpName);
        $imageData = base64_encode(file_get_contents($tmpName));

        $gemini_api_key = $_ENV['GEMINI_API_KEY'] ?? '';
        if (empty($gemini_api_key)) {
            http_response_code(500);
            echo json_encode(['error' => 'GEMINI_API_KEY is missing in backend .env']);
            return;
        }

        $gemini_url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=" . $gemini_api_key;
        
        $gemini_payload = [
            'contents' => [
                [
                    'parts' => [
                        ['text' => 'Extract the exact number displayed on this generator meter screen. Respond with ONLY the number (can include decimals). Ignore any other text. No explanation.'],
                        ['inline_data' => [
                            'mime_type' => $mimeType,
                            'data' => $imageData
                        ]]
                    ]
                ]
            ]
        ];

        $ch = curl_init($gemini_url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($gemini_payload));
        curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 10);
        curl_setopt($ch, CURLOPT_TIMEOUT, 60);
        $response = curl_exec($ch);
        $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if (!$response || $http_code !== 200) {
            http_response_code(500);
            echo json_encode(['error' => 'AI failed to process the image. Response code: ' . $http_code]);
            return;
        }

        $result = json_decode($response, true);
        $text = $result['candidates'][0]['content']['parts'][0]['text'] ?? '';
        
        $number = preg_replace('/[^0-9.]/', '', $text);
        
        echo json_encode([
            'status' => 'success',
            'extracted_value' => $number
        ]);
    }

    /**
     * Export Monthly Report to Native Excel XML Format
     */
    public function exportMonthlyReport() {
        $start_date = $_GET['start_date'] ?? '';
        $end_date = $_GET['end_date'] ?? '';
        $generator_id = $_GET['generator_id'] ?? null;

        if (empty($start_date) || empty($end_date)) {
            http_response_code(400);
            echo json_encode(['error' => 'start_date and end_date are required']);
            return;
        }

        $start_ts = strtotime($start_date);
        $end_ts = strtotime($end_date);
        $days = round(($end_ts - $start_ts) / 86400) + 1;

        // Fetch Generators
        if ($generator_id) {
            $stmt = $this->db->prepare("SELECT id, name, capacity_kva, fuel_capacity, expected_fuel_consumption_per_hour FROM generators WHERE id = ? ORDER BY id");
            $stmt->execute([$generator_id]);
        } else {
            $stmt = $this->db->prepare("SELECT id, name, capacity_kva, fuel_capacity, expected_fuel_consumption_per_hour FROM generators ORDER BY id");
            $stmt->execute();
        }
        $generators = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Fetch Logs
        if ($generator_id) {
            $stmt = $this->db->prepare("SELECT * FROM daily_logs WHERE date >= ? AND date <= ? AND generator_id = ? ORDER BY id ASC");
            $stmt->execute([$start_date, $end_date, $generator_id]);
        } else {
            $stmt = $this->db->prepare("SELECT * FROM daily_logs WHERE date >= ? AND date <= ? ORDER BY id ASC");
            $stmt->execute([$start_date, $end_date]);
        }
        $logs = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $logs_by_date_gen = [];
        foreach ($logs as $log) {
            $logs_by_date_gen[$log['date']][$log['generator_id']] = $log;
        }

        header('Content-Type: application/vnd.ms-excel; charset=UTF-8');
        header('Content-Disposition: attachment; filename="export_' . $start_date . '_to_' . $end_date . '.xls"');
        header('Access-Control-Expose-Headers: Content-Disposition');
        
        echo '<?xml version="1.0"?>' . "\n";
        echo '<?mso-application progid="Excel.Sheet"?>' . "\n";
        echo '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"' . "\n";
        echo ' xmlns:o="urn:schemas-microsoft-com:office:office"' . "\n";
        echo ' xmlns:x="urn:schemas-microsoft-com:office:excel"' . "\n";
        echo ' xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"' . "\n";
        echo ' xmlns:html="http://www.w3.org/TR/REC-html40">' . "\n";
        
        echo ' <Styles>' . "\n";
        echo '  <Style ss:ID="Default" ss:Name="Normal"><Alignment ss:Vertical="Bottom"/><Borders/><Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11" ss:Color="#000000"/><Interior/><NumberFormat/><Protection/></Style>' . "\n";
        echo '  <Style ss:ID="Bold"><Font ss:Bold="1"/></Style>' . "\n";
        echo '  <Style ss:ID="Header"><Font ss:Bold="1"/><Interior ss:Color="#DDDDDD" ss:Pattern="Solid"/><Borders><Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/></Borders></Style>' . "\n";
        echo '  <Style ss:ID="CellBorder"><Borders><Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/></Borders></Style>' . "\n";
        echo '  <Style ss:ID="DBHeader"><Alignment ss:Horizontal="Center" ss:Vertical="Center"/><Font ss:Bold="1" ss:Size="11"/><Interior ss:Color="#FFD966" ss:Pattern="Solid"/><Borders><Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/></Borders></Style>' . "\n";
        echo '  <Style ss:ID="DBData"><Interior ss:Color="#FFF2CC" ss:Pattern="Solid"/><Borders><Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/></Borders></Style>' . "\n";
        echo '  <Style ss:ID="DBRatio"><Font ss:Italic="1"/><Interior ss:Color="#D9EAD3" ss:Pattern="Solid"/><Borders><Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/></Borders></Style>' . "\n";
        echo '  <Style ss:ID="RedBox"><Font ss:Bold="1" ss:Color="#FFFFFF"/><Interior ss:Color="#FF0000" ss:Pattern="Solid"/><Borders><Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/></Borders></Style>' . "\n";
        echo '  <Style ss:ID="FillGreen"><Borders><Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/></Borders><Interior ss:Color="#D9EAD3" ss:Pattern="Solid"/></Style>' . "\n";
        echo '  <Style ss:ID="FillOrange"><Borders><Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/></Borders><Interior ss:Color="#FCE5CD" ss:Pattern="Solid"/></Style>' . "\n";
        echo '  <Style ss:ID="FillYellow"><Borders><Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/></Borders><Interior ss:Color="#FFFF00" ss:Pattern="Solid"/></Style>' . "\n";
        echo '  <Style ss:ID="FillBlue"><Borders><Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/></Borders><Interior ss:Color="#C9DAF8" ss:Pattern="Solid"/></Style>' . "\n";
        echo '  <Style ss:ID="FillGrey"><Borders><Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/></Borders><Interior ss:Color="#D9D9D9" ss:Pattern="Solid"/></Style>' . "\n";
        echo '  <Style ss:ID="FillDarkBlue"><Borders><Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/></Borders><Interior ss:Color="#A4C2F4" ss:Pattern="Solid"/></Style>' . "\n";
        
        // --- NEW PRECISE STYLES FOR BARRIMAGE EXACT REPLICA ---
        $borderStr = '<Borders><Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/><Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/></Borders>';
        
        echo '  <Style ss:ID="TitleBox"><Alignment ss:Horizontal="Center" ss:Vertical="Center"/><Font ss:Bold="1" ss:Italic="1" ss:Size="14"/><Interior ss:Color="#FFE699" ss:Pattern="Solid"/>' . $borderStr . '</Style>' . "\n";
        echo '  <Style ss:ID="HeaderBarimage"><Alignment ss:Horizontal="Center" ss:Vertical="Center"/><Font ss:Size="9"/><Interior ss:Color="#C6E0B4" ss:Pattern="Solid"/>' . $borderStr . '</Style>' . "\n";
        
        // Headers
        echo '  <Style ss:ID="HeadBatiment"><Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:WrapText="1"/><Font ss:Bold="1" ss:Size="9"/><Interior ss:Color="#5B9BD5" ss:Pattern="Solid"/>' . $borderStr . '</Style>' . "\n";
        echo '  <Style ss:ID="HeadNormal"><Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:WrapText="1"/><Font ss:Bold="1" ss:Size="9"/><Interior ss:Color="#C6E0B4" ss:Pattern="Solid"/>' . $borderStr . '</Style>' . "\n";
        echo '  <Style ss:ID="HeadCons"><Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:WrapText="1"/><Font ss:Bold="1" ss:Size="9"/><Interior ss:Color="#E7E6E6" ss:Pattern="Solid"/>' . $borderStr . '</Style>' . "\n";
        echo '  <Style ss:ID="HeadCompteur"><Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:WrapText="1"/><Font ss:Bold="1" ss:Size="9"/><Interior ss:Color="#9BC2E6" ss:Pattern="Solid"/>' . $borderStr . '</Style>' . "\n";
        echo '  <Style ss:ID="HeadMoy"><Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:WrapText="1"/><Font ss:Bold="1" ss:Size="9"/><Interior ss:Color="#C6E0B4" ss:Pattern="Solid"/>' . $borderStr . '</Style>' . "\n";
        echo '  <Style ss:ID="HeadQte"><Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:WrapText="1"/><Font ss:Bold="1" ss:Size="9"/><Interior ss:Color="#F8CBAD" ss:Pattern="Solid"/>' . $borderStr . '</Style>' . "\n";
        echo '  <Style ss:ID="HeadSurplus"><Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:WrapText="1"/><Font ss:Bold="1" ss:Size="9"/><Interior ss:Color="#FFFF00" ss:Pattern="Solid"/>' . $borderStr . '</Style>' . "\n";
        echo '  <Style ss:ID="HeadValSurplus"><Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:WrapText="1"/><Font ss:Bold="1" ss:Size="9"/><Interior ss:Color="#00B0F0" ss:Pattern="Solid"/>' . $borderStr . '</Style>' . "\n";
        echo '  <Style ss:ID="HeadManquant"><Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:WrapText="1"/><Font ss:Bold="1" ss:Size="9"/><Interior ss:Color="#D9D9D9" ss:Pattern="Solid"/>' . $borderStr . '</Style>' . "\n";
        echo '  <Style ss:ID="HeadValManquant"><Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:WrapText="1"/><Font ss:Bold="1" ss:Size="9"/><Interior ss:Color="#8EA9DB" ss:Pattern="Solid"/>' . $borderStr . '</Style>' . "\n";
        
        // Data Rows
        echo '  <Style ss:ID="DataBatiment"><Font ss:Bold="1" ss:Italic="1"/><Interior ss:Color="#9BC2E6" ss:Pattern="Solid"/>' . $borderStr . '</Style>' . "\n";
        echo '  <Style ss:ID="DataNormal"><Alignment ss:Horizontal="Center" ss:Vertical="Center"/><Font ss:Bold="1"/><Interior ss:Color="#C6E0B4" ss:Pattern="Solid"/>' . $borderStr . '</Style>' . "\n";
        echo '  <Style ss:ID="DataCons"><Alignment ss:Horizontal="Center" ss:Vertical="Center"/><Font ss:Bold="1"/><Interior ss:Color="#E7E6E6" ss:Pattern="Solid"/><NumberFormat ss:Format="0.00"/>' . $borderStr . '</Style>' . "\n";
        echo '  <Style ss:ID="DataCompteur"><Alignment ss:Horizontal="Center" ss:Vertical="Center"/><Font ss:Bold="1"/><Interior ss:Color="#9BC2E6" ss:Pattern="Solid"/><NumberFormat ss:Format="0"/>' . $borderStr . '</Style>' . "\n";
        echo '  <Style ss:ID="DataMoy"><Alignment ss:Horizontal="Center" ss:Vertical="Center"/><Font ss:Bold="1"/><Interior ss:Color="#C6E0B4" ss:Pattern="Solid"/><NumberFormat ss:Format="0"/>' . $borderStr . '</Style>' . "\n";
        echo '  <Style ss:ID="DataQte"><Alignment ss:Horizontal="Center" ss:Vertical="Center"/><Font ss:Bold="1"/><Interior ss:Color="#F8CBAD" ss:Pattern="Solid"/><NumberFormat ss:Format="0"/>' . $borderStr . '</Style>' . "\n";
        echo '  <Style ss:ID="DataSurplus"><Alignment ss:Horizontal="Center" ss:Vertical="Center"/><Font ss:Bold="1"/><Interior ss:Color="#FFFF00" ss:Pattern="Solid"/><NumberFormat ss:Format="0\ &quot;L&quot;"/>' . $borderStr . '</Style>' . "\n";
        echo '  <Style ss:ID="DataValSurplus"><Alignment ss:Horizontal="Center" ss:Vertical="Center"/><Font ss:Bold="1"/><Interior ss:Color="#00B0F0" ss:Pattern="Solid"/><NumberFormat ss:Format="#,##0\ &quot;FCFA&quot;;\-#,##0\ &quot;FCFA&quot;;\-\ &quot;FCFA&quot;"/>' . $borderStr . '</Style>' . "\n";
        echo '  <Style ss:ID="DataManquant"><Alignment ss:Horizontal="Center" ss:Vertical="Center"/><Font ss:Bold="1"/><Interior ss:Color="#D9D9D9" ss:Pattern="Solid"/><NumberFormat ss:Format="0\ &quot;L&quot;"/>' . $borderStr . '</Style>' . "\n";
        echo '  <Style ss:ID="DataValManquant"><Alignment ss:Horizontal="Center" ss:Vertical="Center"/><Font ss:Bold="1"/><Interior ss:Color="#8EA9DB" ss:Pattern="Solid"/><NumberFormat ss:Format="#,##0\ &quot;FCFA&quot;;\-#,##0\ &quot;FCFA&quot;;\-\ &quot;FCFA&quot;"/>' . $borderStr . '</Style>' . "\n";
        
        echo '  <Style ss:ID="RedBoxData"><Font ss:Bold="1"/><Interior ss:Color="#E7E6E6" ss:Pattern="Solid"/><NumberFormat ss:Format="#,##0\ &quot;FCFA&quot;;\-#,##0\ &quot;FCFA&quot;;\-\ &quot;FCFA&quot;"/>' . $borderStr . '</Style>' . "\n";

        echo ' </Styles>' . "\n";

        // Sheets for each day
        for ($i = 0; $i < $days; $i++) {
            $ts = $start_ts + ($i * 86400);
            $date_str = date('Y-m-d', $ts);
            $sheet_title = date('M-d', $ts);
            
            echo ' <Worksheet ss:Name="' . htmlspecialchars($sheet_title) . '">' . "\n";
            echo '  <Table>' . "\n";
            
            $grid = [];
            foreach ($generators as $idx => $gen) {
                $row_idx = floor($idx / 4) * 7 + 1;
                $col_idx = ($idx % 4) * 6 + 1;
                $log = $logs_by_date_gen[$date_str][$gen['id']] ?? null;
                
                // Row 1: Name
                $grid[$row_idx][$col_idx] = ['val' => $gen['name'], 'style' => 'Bold', 'mergeAcross' => 4];
                
                // Row 2: Headers
                $grid[$row_idx+1][$col_idx] = ['val' => 'CAPACITE :', 'style' => 'Header'];
                $grid[$row_idx+1][$col_idx+1] = ['val' => 'APPRO', 'style' => 'Header'];
                $grid[$row_idx+1][$col_idx+2] = ['val' => '', 'style' => 'Header'];
                $grid[$row_idx+1][$col_idx+3] = ['val' => 'CONS', 'style' => 'Header'];
                $grid[$row_idx+1][$col_idx+4] = ['val' => 'L/H', 'style' => 'Header'];
                
                // Row 3: Values
                $cap = $gen['capacity_kva'] . " KVA/" . $gen['fuel_capacity'] . " L";
                if ($log) {
                    $cons = $log['ml_predicted_fuel_burn'] ?? 0;
                    if ($log['admin_actual_fuel'] !== null) $cons = $log['admin_actual_fuel'];
                    $lh_rate = $log['calculated_hours_worked'];
                    $lh = $lh_rate > 0 ? $cons / $lh_rate : 0;
                    
                    $grid[$row_idx+2][$col_idx] = ['val' => $cap, 'style' => 'CellBorder'];
                    $grid[$row_idx+2][$col_idx+1] = ['val' => '', 'style' => 'CellBorder'];
                    $grid[$row_idx+2][$col_idx+2] = ['val' => '', 'style' => 'CellBorder'];
                    $grid[$row_idx+2][$col_idx+3] = ['val' => round($cons, 2), 'style' => 'CellBorder', 'type' => 'Number'];
                    $grid[$row_idx+2][$col_idx+4] = ['val' => round($lh, 2), 'style' => 'CellBorder', 'type' => 'Number'];
                } else {
                    $grid[$row_idx+2][$col_idx] = ['val' => $cap, 'style' => 'CellBorder'];
                    $grid[$row_idx+2][$col_idx+1] = ['val' => '', 'style' => 'CellBorder'];
                    $grid[$row_idx+2][$col_idx+2] = ['val' => '', 'style' => 'CellBorder'];
                    $grid[$row_idx+2][$col_idx+3] = ['val' => '', 'style' => 'CellBorder'];
                    $grid[$row_idx+2][$col_idx+4] = ['val' => '', 'style' => 'CellBorder'];
                }
                
                // Row 4: Heure Count
                $grid[$row_idx+3][$col_idx] = ['val' => 'HEURE COUNT', 'style' => 'Header'];
                $grid[$row_idx+3][$col_idx+1] = ['val' => $log ? $log['submitted_hours'] : '', 'style' => 'CellBorder', 'mergeAcross' => 1, 'type' => 'Number'];
                
                // Row 5: Total Gazoil
                $grid[$row_idx+4][$col_idx] = ['val' => 'TOTAL GAZOIL', 'style' => 'Header'];
                $grid[$row_idx+4][$col_idx+1] = ['val' => $log ? round($cons, 2) : '', 'style' => 'CellBorder', 'mergeAcross' => 1, 'type' => 'Number'];
            }
            
            $max_row = empty($grid) ? 0 : max(array_keys($grid));
            for ($r = 1; $r <= $max_row; $r++) {
                if (!isset($grid[$r])) continue;
                echo '   <Row ss:Index="' . $r . '">' . "\n";
                $max_col = max(array_keys($grid[$r]));
                for ($c = 1; $c <= $max_col; $c++) {
                    if (!isset($grid[$r][$c])) continue;
                    $cell = $grid[$r][$c];
                    $merge = isset($cell['mergeAcross']) ? ' ss:MergeAcross="' . $cell['mergeAcross'] . '"' : '';
                    $style = isset($cell['style']) ? ' ss:StyleID="' . $cell['style'] . '"' : '';
                    $type = isset($cell['type']) ? $cell['type'] : 'String';
                    if ($cell['val'] === '') {
                        echo '    <Cell ss:Index="' . $c . '"' . $merge . $style . '></Cell>' . "\n";
                    } else {
                        echo '    <Cell ss:Index="' . $c . '"' . $merge . $style . '><Data ss:Type="' . $type . '">' . htmlspecialchars($cell['val']) . '</Data></Cell>' . "\n";
                    }
                }
                echo '   </Row>' . "\n";
            }
            
            echo '  </Table>' . "\n";
            echo ' </Worksheet>' . "\n";
        }

        // D.B Sheet
        echo ' <Worksheet ss:Name="D.B">' . "\n";
        echo '  <Table>' . "\n";
        echo '   <Column ss:Width="200"/>' . "\n";
        echo '   <Column ss:Width="150"/>' . "\n";
        echo '   <Column ss:Width="150"/>' . "\n";
        
        echo '   <Row>' . "\n";
        echo '    <Cell></Cell>' . "\n";
        echo '    <Cell ss:StyleID="Bold"><Data ss:Type="String">TOTAL</Data></Cell>' . "\n";
        echo '    <Cell ss:StyleID="Bold"><Data ss:Type="String">BARIMAGE</Data></Cell>' . "\n";
        echo '   </Row>' . "\n";
        
        $db_sum_fuel = 0;
        $db_sum_hours = 0;
        foreach ($generators as $gen) {
            $total_fuel = 0;
            $total_hours = 0;
            
            foreach ($logs as $log) {
                if ($log['generator_id'] == $gen['id']) {
                    $f = 0;
                    if ($log['admin_actual_fuel'] !== null) $f = floatval($log['admin_actual_fuel']);
                    elseif ($log['ml_predicted_fuel_burn'] !== null) $f = floatval($log['ml_predicted_fuel_burn']);
                    $total_fuel += $f;
                    $total_hours += floatval($log['calculated_hours_worked'] ?? 0);
                }
            }
            
            $db_sum_fuel += $total_fuel;
            $db_sum_hours += $total_hours;
            $ratio = $total_hours > 0 ? $total_fuel / $total_hours : 0;
            
            // Row 1: Generator Name, Total Fuel, Merged Ratio
            echo '   <Row>' . "\n";
            echo '    <Cell ss:StyleID="FillOrange"><Data ss:Type="String">' . htmlspecialchars($gen['name']) . '</Data></Cell>' . "\n";
            echo '    <Cell ss:StyleID="CellBorder"><Data ss:Type="Number">' . round($total_fuel, 2) . '</Data></Cell>' . "\n";
            echo '    <Cell ss:MergeDown="1" ss:StyleID="FillBlue"><Data ss:Type="Number">' . $ratio . '</Data></Cell>' . "\n";
            echo '   </Row>' . "\n";
            
            // Row 2: HEUR COUNT, Total Hours
            echo '   <Row>' . "\n";
            echo '    <Cell ss:StyleID="FillGreen"><Data ss:Type="String">HEUR COUNT</Data></Cell>' . "\n";
            echo '    <Cell ss:StyleID="CellBorder"><Data ss:Type="Number">' . round($total_hours, 2) . '</Data></Cell>' . "\n";
            echo '   </Row>' . "\n";
            
            // Blank row separator
            echo '   <Row ss:Height="10"></Row>' . "\n";
        }
        
        echo '  </Table>' . "\n";
        echo ' </Worksheet>' . "\n";

        // BARRIMAGE Sheet
        echo ' <Worksheet ss:Name="BARRIMAGE">' . "\n";
        echo '  <Table>' . "\n";
        echo '   <Column ss:Width="160"/>' . "\n"; // A: BATIMENT
        echo '   <Column ss:Width="120"/>' . "\n"; // B: NORMAL CONS
        echo '   <Column ss:Width="120"/>' . "\n"; // C: QTE CONS
        echo '   <Column ss:Width="90"/>' . "\n";  // D: COMPTEUR
        echo '   <Column ss:Width="110"/>' . "\n"; // E: MOYENNE
        echo '   <Column ss:Width="120"/>' . "\n"; // F: QTE NORMAL
        echo '   <Column ss:Width="100"/>' . "\n"; // G: SURPLUS
        echo '   <Column ss:Width="120"/>' . "\n"; // H: VAL SURPLUS
        echo '   <Column ss:Width="100"/>' . "\n"; // I: MANQUANT
        echo '   <Column ss:Width="130"/>' . "\n"; // J: VAL MANQUANT
        echo '   <Column ss:Width="20"/>' . "\n";
        echo '   <Column ss:Width="220"/>' . "\n"; // L: Red Box Column
        
        // Row 1: Blank
        echo '   <Row ss:Height="15"></Row>' . "\n";

        // Row 2: "Mar-26" title (Merged from E to H)
        $month_title = date('M-y', strtotime($start_date));
        echo '   <Row ss:Height="30">' . "\n";
        echo '    <Cell ss:Index="5" ss:MergeAcross="3" ss:StyleID="TitleBox"><Data ss:Type="String">' . $month_title . '</Data></Cell>' . "\n";
        echo '   </Row>' . "\n";

        // Row 3: Blank
        echo '   <Row ss:Height="15"></Row>' . "\n";

        // Row 4: "Barimage" header over column B
        echo '   <Row>' . "\n";
        echo '    <Cell ss:Index="2" ss:StyleID="HeaderBarimage"><Data ss:Type="String">Barimage</Data></Cell>' . "\n";
        echo '   </Row>' . "\n";
        
        // Row 5: Headers
        $headers = [
            'BUILDING', "NORMAL\nCONSUMPTION\nPER HOUR", "Consumed\nFuel\nQuantity\n(L)",
            "HOURS RUN\n(H)", "AVERAGE\nCONSUMPTION\n(L/H)", "NORMAL\nFUEL QUANTITY\n(L)",
            "FUEL DIFF\nSURPLUS\n(L)", "SURPLUS VALUE\n(CFA)", "FUEL DIFF\nMISSING\n(L)", "MISSING VALUE\n(CFA)"
        ];
        
        $headerStyles = ['HeadBatiment', 'HeadNormal', 'HeadCons', 'HeadCompteur', 'HeadMoy', 'HeadQte', 'HeadSurplus', 'HeadValSurplus', 'HeadManquant', 'HeadValManquant'];
        
        echo '   <Row ss:Height="75">' . "\n";
        for($i=0; $i<count($headers); $i++) {
            echo '    <Cell ss:StyleID="' . $headerStyles[$i] . '"><Data ss:Type="String">' . htmlspecialchars($headers[$i]) . '</Data></Cell>' . "\n";
        }
        echo '   </Row>' . "\n";
        
        $r = 6;
        $sum_total_fuel = 0;
        $sum_total_hours = 0;
        $sum_qte_normal = 0;
        $sum_surplus = 0;
        $sum_val_surplus = 0;
        $sum_manquant = 0;
        $sum_val_manquant = 0;
        
        $gen_stats = [];

        // First pass: Calculate all totals and store stats
        foreach ($generators as $gen) {
            $total_fuel = 0;
            $total_hours = 0;
            foreach ($logs as $log) {
                if ($log['generator_id'] == $gen['id']) {
                    $f = 0;
                    if ($log['admin_actual_fuel'] !== null) $f = floatval($log['admin_actual_fuel']);
                    elseif ($log['ml_predicted_fuel_burn'] !== null) $f = floatval($log['ml_predicted_fuel_burn']);
                    $total_fuel += $f;
                    $total_hours += floatval($log['calculated_hours_worked'] ?? 0);
                }
            }
            $normal_cons = floatval($gen['expected_fuel_consumption_per_hour'] ?? 0);
            
            $moyenne = $total_hours > 0 ? $total_fuel / $total_hours : 0;
            $qte_normal = $total_hours * $normal_cons;
            $surplus = ($qte_normal - $total_fuel > 0) ? $qte_normal - $total_fuel : 0;
            $val_surplus = $surplus * 1200;
            $manquant = ($qte_normal - $total_fuel < 0) ? $total_fuel - $qte_normal : 0;
            $val_manquant = $manquant * 1200;

            $sum_total_fuel += $total_fuel;
            $sum_total_hours += $total_hours;
            $sum_qte_normal += $qte_normal;
            $sum_surplus += $surplus;
            $sum_val_surplus += $val_surplus;
            $sum_manquant += $manquant;
            $sum_val_manquant += $val_manquant;
            
            $gen_stats[] = [
                'name' => $gen['name'],
                'normal_cons' => $normal_cons,
                'total_fuel' => round($total_fuel, 2),
                'total_hours' => round($total_hours, 2),
                'moyenne' => $moyenne,
                'qte_normal' => $qte_normal,
                'surplus' => $surplus,
                'val_surplus' => $val_surplus,
                'manquant' => $manquant,
                'val_manquant' => $val_manquant
            ];
        }
        
        $final_diff = $sum_val_surplus - $sum_val_manquant;

        // Second pass: Output XML rows
        foreach ($gen_stats as $stat) {
            echo '   <Row>' . "\n";
            echo '    <Cell ss:StyleID="DataBatiment"><Data ss:Type="String">' . htmlspecialchars($stat['name']) . '</Data></Cell>' . "\n";
            echo '    <Cell ss:StyleID="DataNormal"><Data ss:Type="Number">' . $stat['normal_cons'] . '</Data></Cell>' . "\n";
            echo '    <Cell ss:StyleID="DataCons"><Data ss:Type="Number">' . $stat['total_fuel'] . '</Data></Cell>' . "\n";
            echo '    <Cell ss:StyleID="DataCompteur"><Data ss:Type="Number">' . $stat['total_hours'] . '</Data></Cell>' . "\n";
            echo '    <Cell ss:StyleID="DataMoy" ss:Formula="=IF(RC[-1]&gt;0, RC[-2]/RC[-1], 0)"><Data ss:Type="Number">' . $stat['moyenne'] . '</Data></Cell>' . "\n";
            echo '    <Cell ss:StyleID="DataQte" ss:Formula="=RC[-2]*RC[-4]"><Data ss:Type="Number">' . $stat['qte_normal'] . '</Data></Cell>' . "\n";
            echo '    <Cell ss:StyleID="DataSurplus" ss:Formula="=IF((RC[-1]-RC[-4])&gt;0, RC[-1]-RC[-4], 0)"><Data ss:Type="Number">' . $stat['surplus'] . '</Data></Cell>' . "\n";
            echo '    <Cell ss:StyleID="DataValSurplus" ss:Formula="=RC[-1]*1200"><Data ss:Type="Number">' . $stat['val_surplus'] . '</Data></Cell>' . "\n";
            echo '    <Cell ss:StyleID="DataManquant" ss:Formula="=IF((RC[-3]-RC[-6])&lt;0, RC[-6]-RC[-3], 0)"><Data ss:Type="Number">' . $stat['manquant'] . '</Data></Cell>' . "\n";
            echo '    <Cell ss:StyleID="DataValManquant" ss:Formula="=RC[-1]*1200"><Data ss:Type="Number">' . $stat['val_manquant'] . '</Data></Cell>' . "\n";
            
            // Add Red Box difference exactly like screenshot (on row 6 and 7)
            if ($r == 6) {
                echo '    <Cell ss:Index="12" ss:StyleID="RedBox"><Data ss:Type="String">SURPLUS/MISSING DIFFERENCE</Data></Cell>' . "\n";
            } elseif ($r == 7) {
                echo '    <Cell ss:Index="12" ss:StyleID="RedBoxData"><Data ss:Type="Number">' . $final_diff . '</Data></Cell>' . "\n";
            }
            echo '   </Row>' . "\n";
            $r++;
        }
        
        // Blank Row 
        echo '   <Row ss:Height="15"></Row>' . "\n";

        // Totals row
        $tot_moyenne = $sum_total_hours > 0 ? $sum_total_fuel / $sum_total_hours : 0;
        echo '   <Row>' . "\n";
        echo '    <Cell ss:StyleID="Bold"><Data ss:Type="String">TOTAL</Data></Cell>' . "\n";
        echo '    <Cell></Cell>' . "\n";
        echo '    <Cell ss:StyleID="CellBorder"><Data ss:Type="Number">' . round($sum_total_fuel, 2) . '</Data></Cell>' . "\n";
        echo '    <Cell ss:StyleID="CellBorder"><Data ss:Type="Number">' . round($sum_total_hours, 2) . '</Data></Cell>' . "\n";
        echo '    <Cell ss:StyleID="CellBorder"><Data ss:Type="Number">' . $tot_moyenne . '</Data></Cell>' . "\n";
        echo '    <Cell ss:StyleID="CellBorder"><Data ss:Type="Number">' . $sum_qte_normal . '</Data></Cell>' . "\n";
        echo '    <Cell ss:StyleID="CellBorder"><Data ss:Type="Number">' . $sum_surplus . '</Data></Cell>' . "\n";
        echo '    <Cell ss:StyleID="CellBorder"><Data ss:Type="Number">' . $sum_val_surplus . '</Data></Cell>' . "\n";
        echo '    <Cell ss:StyleID="CellBorder"><Data ss:Type="Number">' . $sum_manquant . '</Data></Cell>' . "\n";
        echo '    <Cell ss:StyleID="CellBorder"><Data ss:Type="Number">' . $sum_val_manquant . '</Data></Cell>' . "\n";
        echo '   </Row>' . "\n";
        
        echo '  </Table>' . "\n";
        echo ' </Worksheet>' . "\n";

        echo '</Workbook>' . "\n";
    }
}
