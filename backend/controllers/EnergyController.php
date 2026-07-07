<?php
class EnergyController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    // --- Generators CRUD ---
    public function getGenerators() {
        try {
            $stmt = $this->db->query("
                SELECT g.*, b.name as building_name 
                FROM generators g
                JOIN buildings b ON g.building_id = b.id
                ORDER BY g.created_at DESC
            ");
            echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function getGenerator($id) {
        try {
            $stmt = $this->db->prepare("
                SELECT g.*, b.name as building_name 
                FROM generators g
                JOIN buildings b ON g.building_id = b.id
                WHERE g.id = ?
            ");
            $stmt->execute([$id]);
            $generator = $stmt->fetch(PDO::FETCH_ASSOC);
            if ($generator) {
                echo json_encode($generator);
            } else {
                http_response_code(404);
                echo json_encode(['error' => 'Generator not found']);
            }
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function storeGenerator() {
        try {
            $data = json_decode(file_get_contents("php://input"), true);
            $stmt = $this->db->prepare("
                INSERT INTO generators (
                    building_id, name, brand, model, serial_number, capacity_kva, fuel_capacity, 
                    current_fuel, spare_fuel, purchase_date, status, notes, 
                    baseline_fuel_per_hour, price_per_kw,
                    expected_fuel_consumption_per_hour, expected_fuel_consumption_per_kwh,
                    maintenance_interval_hours, min_fuel_level_alert,
                    normal_operating_thresholds, alert_thresholds
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ");
            $stmt->execute([
                $data['building_id'],
                $data['name'],
                $data['brand'] ?? null,
                $data['model'] ?? null,
                $data['serial_number'] ?? null,
                $data['capacity_kva'] ?? 0,
                $data['fuel_capacity'] ?? 0,
                $data['current_fuel'] ?? 0,
                $data['spare_fuel'] ?? 0,
                $data['purchase_date'] ?? null,
                $data['status'] ?? 'Offline',
                $data['notes'] ?? null,
                $data['baseline_fuel_per_hour'] ?? 0,
                $data['price_per_kw'] ?? 0,
                $data['expected_fuel_consumption_per_hour'] ?? null,
                $data['expected_fuel_consumption_per_kwh'] ?? null,
                $data['maintenance_interval_hours'] ?? 250,
                $data['min_fuel_level_alert'] ?? 100,
                isset($data['normal_operating_thresholds']) ? json_encode($data['normal_operating_thresholds']) : null,
                isset($data['alert_thresholds']) ? json_encode($data['alert_thresholds']) : null
            ]);
            echo json_encode(['message' => 'Generator created successfully', 'id' => $this->db->lastInsertId()]);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function updateGenerator($id) {
        try {
            $data = json_decode(file_get_contents("php://input"), true);
            $stmt = $this->db->prepare("
                UPDATE generators 
                SET name = ?, brand = ?, model = ?, serial_number = ?, capacity_kva = ?, 
                    fuel_capacity = ?, current_fuel = ?, spare_fuel = ?, purchase_date = ?, 
                    status = ?, notes = ?, baseline_fuel_per_hour = ?, price_per_kw = ?,
                    expected_fuel_consumption_per_hour = ?, expected_fuel_consumption_per_kwh = ?,
                    maintenance_interval_hours = ?, min_fuel_level_alert = ?,
                    normal_operating_thresholds = ?, alert_thresholds = ?
                WHERE id = ?
            ");
            $stmt->execute([
                $data['name'],
                $data['brand'] ?? null,
                $data['model'] ?? null,
                $data['serial_number'] ?? null,
                $data['capacity_kva'] ?? 0,
                $data['fuel_capacity'] ?? 0,
                $data['current_fuel'] ?? 0,
                $data['spare_fuel'] ?? 0,
                $data['purchase_date'] ?? null,
                $data['status'] ?? 'Offline',
                $data['notes'] ?? null,
                $data['baseline_fuel_per_hour'] ?? 0,
                $data['price_per_kw'] ?? 0,
                $data['expected_fuel_consumption_per_hour'] ?? null,
                $data['expected_fuel_consumption_per_kwh'] ?? null,
                $data['maintenance_interval_hours'] ?? 250,
                $data['min_fuel_level_alert'] ?? 100,
                isset($data['normal_operating_thresholds']) ? (is_string($data['normal_operating_thresholds']) ? $data['normal_operating_thresholds'] : json_encode($data['normal_operating_thresholds'])) : null,
                isset($data['alert_thresholds']) ? (is_string($data['alert_thresholds']) ? $data['alert_thresholds'] : json_encode($data['alert_thresholds'])) : null,
                $id
            ]);
            echo json_encode(['message' => 'Generator updated successfully']);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function deleteGenerator($id) {
        try {
            $stmt = $this->db->prepare("DELETE FROM generators WHERE id = ?");
            $stmt->execute([$id]);
            echo json_encode(['message' => 'Generator deleted successfully']);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function updateGeneratorStatus($id) {
        try {
            $data = json_decode(file_get_contents("php://input"), true);
            $stmt = $this->db->prepare("UPDATE generators SET status = ? WHERE id = ?");
            $stmt->execute([$data['status'], $id]);
            echo json_encode(['message' => 'Status updated successfully']);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    // --- Daily Reports ---
    public function getDailyReports($generator_id) {
        try {
            $stmt = $this->db->prepare("
                SELECT r.*, u.name as submitter_name 
                FROM generator_daily_reports r
                LEFT JOIN users u ON r.submitted_by = u.id
                WHERE r.generator_id = ?
                ORDER BY r.date DESC, r.created_at DESC
            ");
            $stmt->execute([$generator_id]);
            echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function storeDailyReading() {
        try {
            $data = json_decode(file_get_contents("php://input"), true) ?: $_POST;
            $generatorId = $data['generator_id'] ?? null;
            if (!$generatorId) {
                // backward compat
                $genStmt = $this->db->prepare("SELECT * FROM generators WHERE building_id = ?");
                $genStmt->execute([$data['building_id']]);
                $generator = $genStmt->fetch(PDO::FETCH_ASSOC);
                if ($generator) $generatorId = $generator['id'];
            } else {
                $genStmt = $this->db->prepare("SELECT * FROM generators WHERE id = ?");
                $genStmt->execute([$generatorId]);
                $generator = $genStmt->fetch(PDO::FETCH_ASSOC);
            }

            if (!$generator) {
                http_response_code(404);
                echo json_encode(['error' => 'Generator not found']);
                return;
            }

            // Handle Photo Upload
            $photoPath = null;
            if (isset($_FILES['photo']) && $_FILES['photo']['error'] == UPLOAD_ERR_OK) {
                $uploadDir = __DIR__ . '/../../uploads/generators/';
                if (!is_dir($uploadDir)) mkdir($uploadDir, 0777, true);
                $ext = pathinfo($_FILES['photo']['name'], PATHINFO_EXTENSION);
                $filename = time() . '_' . rand(1000, 9999) . '.' . $ext;
                $photoPath = 'uploads/generators/' . $filename;
                move_uploaded_file($_FILES['photo']['tmp_name'], $uploadDir . $filename);
            }

            // Handle Fuel Photo Upload (Optional)
            $fuelPhotoPath = null;
            if (isset($_FILES['fuel_photo']) && $_FILES['fuel_photo']['error'] == UPLOAD_ERR_OK) {
                $uploadDir = __DIR__ . '/../../uploads/generators/';
                if (!is_dir($uploadDir)) mkdir($uploadDir, 0777, true);
                $ext = pathinfo($_FILES['fuel_photo']['name'], PATHINFO_EXTENSION);
                $filename = time() . '_fuel_' . rand(1000, 9999) . '.' . $ext;
                $fuelPhotoPath = 'uploads/generators/' . $filename;
                move_uploaded_file($_FILES['fuel_photo']['tmp_name'], $uploadDir . $filename);
            }

            // Fetch previous report for calculating produced & hours
            $prevStmt = $this->db->prepare("SELECT current_kwh, meter_hours FROM generator_daily_reports WHERE generator_id = ? ORDER BY date DESC, created_at DESC LIMIT 1");
            $prevStmt->execute([$generatorId]);
            $prevReport = $prevStmt->fetch(PDO::FETCH_ASSOC);

            $previousKwh = $prevReport ? floatval($prevReport['current_kwh']) : 0;
            $previousHours = $prevReport ? floatval($prevReport['meter_hours']) : 0;

            $currentKwh = floatval($data['current_kwh'] ?? 0);
            $currentHours = floatval($data['meter_hours'] ?? 0);

            $kwhProduced = max(0, $currentKwh - $previousKwh);
            $runningHours = max(0, $currentHours - $previousHours);

            // Baseline calculations for fuel estimations
            $baselineFuelPerHour = floatval($generator['expected_fuel_consumption_per_hour'] ?? 0);
            $baselineFuelPerKwh = floatval($generator['expected_fuel_consumption_per_kwh'] ?? 0);
            
            // Try to find historical averages from AI Profile or just recent averages
            $aiStmt = $this->db->prepare("SELECT AVG(actual_fuel_used / NULLIF(running_hours, 0)) as avg_per_hour, AVG(actual_fuel_used / NULLIF(kwh_produced, 0)) as avg_per_kwh FROM generator_daily_reports WHERE generator_id = ? AND status = 'Verified'");
            $aiStmt->execute([$generatorId]);
            $aiStats = $aiStmt->fetch(PDO::FETCH_ASSOC);

            $estPerHour = $aiStats['avg_per_hour'] > 0 ? floatval($aiStats['avg_per_hour']) : $baselineFuelPerHour;
            $estPerKwh = $aiStats['avg_per_kwh'] > 0 ? floatval($aiStats['avg_per_kwh']) : $baselineFuelPerKwh;

            $estUsedByHours = $runningHours * $estPerHour;
            $estUsedByKwh = $kwhProduced * $estPerKwh;
            
            $estimatedFuelUsed = $estUsedByHours > 0 ? $estUsedByHours : $estUsedByKwh;
            $currentFuelLevel = floatval($generator['current_fuel'] ?? 0);
            $estimatedFuelRemaining = max(0, $currentFuelLevel - $estimatedFuelUsed);

            $this->db->beginTransaction();

            $stmt = $this->db->prepare("
                INSERT INTO generator_daily_reports 
                (generator_id, date, meter_hours, running_hours, previous_kwh, current_kwh, kwh_produced, 
                 estimated_fuel_used, estimated_fuel_remaining, photo_path, fuel_photo_path, notes, submitted_by, status)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'Pending Verification')
                ON DUPLICATE KEY UPDATE
                meter_hours = VALUES(meter_hours),
                running_hours = VALUES(running_hours),
                previous_kwh = VALUES(previous_kwh),
                current_kwh = VALUES(current_kwh),
                kwh_produced = VALUES(kwh_produced),
                estimated_fuel_used = VALUES(estimated_fuel_used),
                estimated_fuel_remaining = VALUES(estimated_fuel_remaining),
                photo_path = COALESCE(VALUES(photo_path), photo_path),
                fuel_photo_path = COALESCE(VALUES(fuel_photo_path), fuel_photo_path),
                notes = VALUES(notes),
                submitted_by = VALUES(submitted_by),
                status = 'Pending Verification'
            ");

            $userId = $data['user_id'] ?? 1;

            $stmt->execute([
                $generatorId,
                $data['date'] ?? date('Y-m-d'),
                $currentHours,
                $runningHours,
                $previousKwh,
                $currentKwh,
                $kwhProduced,
                $estimatedFuelUsed,
                $estimatedFuelRemaining,
                $photoPath,
                $fuelPhotoPath,
                $data['notes'] ?? null,
                $userId
            ]);

            $this->db->commit();
            echo json_encode(['message' => 'Daily reading submitted successfully', 'estimated_fuel_remaining' => $estimatedFuelRemaining]);
        } catch (PDOException $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function verifyActualFuel() {
        try {
            $data = json_decode(file_get_contents("php://input"), true);
            $reportId = $data['report_id'];
            $actualFuelRemaining = floatval($data['actual_fuel_remaining']);

            $reportStmt = $this->db->prepare("SELECT * FROM generator_daily_reports WHERE id = ?");
            $reportStmt->execute([$reportId]);
            $report = $reportStmt->fetch(PDO::FETCH_ASSOC);

            if (!$report) {
                http_response_code(404);
                echo json_encode(['error' => 'Report not found']);
                return;
            }

            $generatorId = $report['generator_id'];
            $genStmt = $this->db->prepare("SELECT current_fuel FROM generators WHERE id = ?");
            $genStmt->execute([$generatorId]);
            $generator = $genStmt->fetch(PDO::FETCH_ASSOC);
            
            $prevFuel = floatval($generator['current_fuel']);
            
            // Calculate actual used
            $actualFuelUsed = max(0, $prevFuel - $actualFuelRemaining);
            $estimatedFuelUsed = floatval($report['estimated_fuel_used']);
            $fuelDifference = $actualFuelUsed - $estimatedFuelUsed;

            $alertLevel = 'Normal';
            $discrepancyReason = null;
            $probabilities = null;

            if ($estimatedFuelUsed > 0) {
                $diffPercent = abs($fuelDifference) / $estimatedFuelUsed;

                if ($diffPercent > 0.15) {
                    $alertLevel = 'Critical';
                    if ($fuelDifference > 0) {
                        $probabilities = json_encode(['Theft' => 55, 'Leakage' => 25, 'Mechanical' => 15, 'Data_Entry' => 5]);
                        $discrepancyReason = "Critical Alert: Consumed " . round($fuelDifference, 1) . "L more than expected. High probability of Theft or Leakage.";
                    } else {
                        $probabilities = json_encode(['Data_Entry' => 60, 'Meter_Manipulation' => 30, 'Mechanical' => 10]);
                        $discrepancyReason = "Critical Alert: Consumed " . round(abs($fuelDifference), 1) . "L less than expected.";
                    }
                } else if ($diffPercent > 0.05) {
                    $alertLevel = 'Warning';
                    if ($fuelDifference > 0) {
                        $probabilities = json_encode(['Mechanical' => 50, 'Heavy_Load' => 40, 'Leakage' => 10]);
                        $discrepancyReason = "Warning: Consumed " . round($fuelDifference, 1) . "L more than expected.";
                    } else {
                        $probabilities = json_encode(['Data_Entry' => 80, 'Under_Load' => 20]);
                        $discrepancyReason = "Warning: Consumed " . round(abs($fuelDifference), 1) . "L less than expected.";
                    }
                }
            }

            $efficiencyScore = 0;
            if ($actualFuelUsed > 0) {
                $efficiencyScore = floatval($report['kwh_produced']) / $actualFuelUsed;
            }

            $this->db->beginTransaction();

            // Update Report
            $updateStmt = $this->db->prepare("
                UPDATE generator_daily_reports 
                SET actual_fuel_remaining = ?, actual_fuel_used = ?, fuel_difference = ?, 
                    efficiency_score = ?, alert_level = ?, discrepancy_reason = ?, status = 'Verified'
                WHERE id = ?
            ");
            $updateStmt->execute([
                $actualFuelRemaining,
                $actualFuelUsed,
                $fuelDifference,
                $efficiencyScore,
                $alertLevel,
                $discrepancyReason,
                $reportId
            ]);

            // Insert Alerts
            if ($alertLevel !== 'Normal' && $discrepancyReason) {
                $alertStmt = $this->db->prepare("INSERT INTO generator_alerts (generator_id, report_id, alert_type, message, severity, probabilities) VALUES (?, ?, 'Consumption Anomaly', ?, ?, ?)");
                $alertStmt->execute([$generatorId, $reportId, $discrepancyReason, $alertLevel, $probabilities]);
            }

            // Update generator's current fuel
            $genUpdate = $this->db->prepare("UPDATE generators SET current_fuel = ? WHERE id = ?");
            $genUpdate->execute([$actualFuelRemaining, $generatorId]);

            $this->db->commit();
            echo json_encode(['message' => 'Fuel verification completed', 'alert_level' => $alertLevel, 'fuel_difference' => $fuelDifference]);
        } catch (PDOException $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function getPendingGeneratorReadings() {
        try {
            $stmt = $this->db->query("
                SELECT r.*, g.name as generator_name, b.name as building_name, u.name as submitter_name
                FROM generator_daily_reports r
                JOIN generators g ON r.generator_id = g.id
                JOIN buildings b ON g.building_id = b.id
                LEFT JOIN users u ON r.submitted_by = u.id
                WHERE r.status = 'Pending Verification'
                ORDER BY r.date DESC, r.created_at DESC
            ");
            echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function verifyGeneratorReading($id) {
        try {
            $data = json_decode(file_get_contents("php://input"), true);
            $status = $data['status']; // 'Verified' or 'Rejected'
            $rejectionReason = $data['rejection_reason'] ?? null;
            $adminId = $data['user_id'] ?? 1;

            $stmt = $this->db->prepare("
                UPDATE generator_daily_reports 
                SET status = ?, approved_by = ?, rejection_reason = ?
                WHERE id = ?
            ");
            $stmt->execute([$status, $adminId, $rejectionReason, $id]);
            
            // Trigger Python AI Analysis if Verified
            if ($status === 'Verified') {
                $selStmt = $this->db->prepare("SELECT generator_id, date FROM generator_daily_reports WHERE id = ?");
                $selStmt->execute([$id]);
                $rep = $selStmt->fetch(PDO::FETCH_ASSOC);
                
                if ($rep) {
                    $ch = curl_init('http://localhost:5000/analyze/daily');
                    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
                    curl_setopt($ch, CURLOPT_POST, true);
                    curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
                    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode([
                        'generator_id' => $rep['generator_id'],
                        'date' => $rep['date']
                    ]));
                    // 2 second timeout so it doesn't block PHP if Python is down
                    curl_setopt($ch, CURLOPT_TIMEOUT, 2);
                    curl_exec($ch);
                    curl_close($ch);
                }
            }
            
            echo json_encode(['message' => 'Generator reading verification updated.']);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    // --- Smart Predictions & Stats ---
    public function getGeneratorStats($building_id) {
        try {
            // Get Generator by building_id
            $genStmt = $this->db->prepare("SELECT * FROM generators WHERE building_id = ?");
            $genStmt->execute([$building_id]);
            $generator = $genStmt->fetch(PDO::FETCH_ASSOC);

            if (!$generator) {
                // Return 200 with null generator to avoid console 404 errors for buildings without generators
                echo json_encode(['generator' => null]);
                return;
            }
            
            $id = $generator['id']; // actual generator id

            // Get Reports for the current month
            $startOfMonth = date('Y-m-01');
            $endOfMonth = date('Y-m-t');
            
            $monthReportsStmt = $this->db->prepare("
                SELECT SUM(actual_fuel_used) as fuel_used_month, 
                       SUM(kwh_produced) as kwh_produced_month, 
                       SUM(running_hours) as running_hours_month,
                       AVG(kwh_produced / NULLIF(actual_fuel_used, 0)) as avg_efficiency
                FROM generator_daily_reports 
                WHERE generator_id = ? AND date BETWEEN ? AND ?
            ");
            $monthReportsStmt->execute([$id, $startOfMonth, $endOfMonth]);
            $monthStats = $monthReportsStmt->fetch(PDO::FETCH_ASSOC);

            // Get Today's report
            $today = date('Y-m-d');
            $todayReportsStmt = $this->db->prepare("
                SELECT SUM(actual_fuel_used) as fuel_used_today, 
                       SUM(kwh_produced) as kwh_produced_today, 
                       SUM(running_hours) as running_hours_today
                FROM generator_daily_reports 
                WHERE generator_id = ? AND date = ?
            ");
            $todayReportsStmt->execute([$id, $today]);
            $todayStats = $todayReportsStmt->fetch(PDO::FETCH_ASSOC);

            // Calculate historical averages for prediction
            $histStmt = $this->db->prepare("
                SELECT AVG(actual_fuel_used) as avg_daily_fuel,
                       AVG(kwh_produced) as avg_daily_kwh
                FROM generator_daily_reports
                WHERE generator_id = ?
            ");
            $histStmt->execute([$id]);
            $history = $histStmt->fetch(PDO::FETCH_ASSOC);

            $avgDailyFuel = floatval($history['avg_daily_fuel']);
            if ($avgDailyFuel == 0) $avgDailyFuel = 1; // avoid division by zero
            $avgDailyKwh = floatval($history['avg_daily_kwh']);
            
            $estimatedDays = $generator['current_fuel'] / $avgDailyFuel;
            $fuelNextMonth = $avgDailyFuel * 30;

            // Get latest cost_per_liter from fuel movements
            try {
                $priceStmt = $this->db->prepare("SELECT cost_per_liter FROM generator_fuel_movements WHERE generator_id = ? AND type = 'Refill' ORDER BY date DESC, created_at DESC LIMIT 1");
                $priceStmt->execute([$id]);
                $latestPrice = $priceStmt->fetchColumn();
                $dieselPrice = $latestPrice ?: 0;
            } catch (Exception $e) {
                $dieselPrice = 0;
            }

            $stats = [
                'generator' => $generator,
                'today' => [
                    'fuel_used' => $todayStats['fuel_used_today'] ?: 0,
                    'kwh_produced' => $todayStats['kwh_produced_today'] ?: 0,
                    'running_hours' => $todayStats['running_hours_today'] ?: 0,
                    'estimated_cost' => ($todayStats['fuel_used_today'] ?: 0) * $dieselPrice
                ],
                'month' => [
                    'fuel_used' => $monthStats['fuel_used_month'] ?: 0,
                    'kwh_produced' => $monthStats['kwh_produced_month'] ?: 0,
                    'running_hours' => $monthStats['running_hours_month'] ?: 0,
                    'estimated_cost' => ($monthStats['fuel_used_month'] ?: 0) * $dieselPrice,
                    'efficiency_score' => $monthStats['avg_efficiency'] ? round($monthStats['avg_efficiency'], 2) : 0
                ],
                'predictions' => [
                    'avg_daily_fuel' => round($avgDailyFuel, 2),
                    'estimated_remaining_days' => round($estimatedDays),
                    'fuel_next_month' => round($fuelNextMonth),
                    'cost_next_month' => round($fuelNextMonth * $dieselPrice, 2),
                    'next_week_kwh' => round($avgDailyKwh * 7),
                    'next_month_kwh' => round($avgDailyKwh * 30)
                ]
            ];

            echo json_encode($stats);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function getEnergyDashboardStats() {
        try {
            // Aggregate across all buildings
            $stmt = $this->db->query("
                SELECT 
                    SUM(g.current_fuel) as total_fuel,
                    (SELECT SUM(bill_amount) FROM electricity_meter_readings WHERE MONTH(reading_date) = MONTH(CURRENT_DATE())) as month_revenue,
                    (SELECT SUM(fuel_added * cost_per_liter) FROM generator_daily_reports WHERE MONTH(date) = MONTH(CURRENT_DATE())) as month_fuel_cost
                FROM generators g
            ");
            $dashboard = $stmt->fetch(PDO::FETCH_ASSOC);

            // Fetch chart data (last 7 days fuel consumption)
            $chartStmt = $this->db->query("
                SELECT date, SUM(fuel_added) as total_fuel_used, SUM(kwh_produced) as total_kwh
                FROM generator_daily_reports
                WHERE date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
                GROUP BY date
                ORDER BY date ASC
            ");
            $chartData = $chartStmt->fetchAll(PDO::FETCH_ASSOC);

            echo json_encode([
                'overview' => $dashboard,
                'chart' => $chartData
            ]);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    // --- Alerts ---
    public function getAlerts() {
        try {
            $stmt = $this->db->query("SELECT * FROM energy_alerts ORDER BY created_at DESC LIMIT 50");
            echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    // --- Enterprise AI & Executive Dashboard ---
    public function getExecutiveDashboardStats() {
        try {
            // Aggregate across all generators
            $stmt = $this->db->query("
                SELECT g.*, b.name as building_name
                FROM generators g
                LEFT JOIN buildings b ON g.building_id = b.id
            ");
            $generators = $stmt->fetchAll(PDO::FETCH_ASSOC);

            // Fetch chart data (last 30 days)
            $chartStmt = $this->db->query("
                SELECT date, SUM(actual_fuel_consumption) as total_fuel_used, SUM(kwh_produced) as total_kwh, SUM(cost_of_electricity) as total_cost
                FROM generator_daily_reports
                WHERE date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
                GROUP BY date
                ORDER BY date ASC
            ");
            $chartData = $chartStmt->fetchAll(PDO::FETCH_ASSOC);

            // Fetch alerts
            $alertStmt = $this->db->query("
                SELECT a.*, g.name as generator_name, b.name as building_name 
                FROM generator_alerts a
                JOIN generators g ON a.generator_id = g.id
                LEFT JOIN buildings b ON g.building_id = b.id
                WHERE a.status = 'Unresolved'
                ORDER BY a.created_at DESC LIMIT 20
            ");
            $alerts = $alertStmt->fetchAll(PDO::FETCH_ASSOC);

            // Calculate dynamic health scores
            $processedGenerators = [];
            foreach ($generators as $g) {
                // Efficiency Score
                $effScore = $g['efficiency_score'] ?? 100;

                // Reliability (based on outages)
                $outageStmt = $this->db->prepare("SELECT SUM(outages_count) FROM generator_daily_reports WHERE generator_id = ? AND date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)");
                $outageStmt->execute([$g['id']]);
                $outages = intval($outageStmt->fetchColumn());
                $relScore = max(0, 100 - ($outages * 10));

                // Accuracy (based on variance)
                $varStmt = $this->db->prepare("SELECT AVG(ABS(fuel_variance)) FROM generator_daily_reports WHERE generator_id = ? AND date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)");
                $varStmt->execute([$g['id']]);
                $avgVar = floatval($varStmt->fetchColumn());
                $accScore = max(0, 100 - ($avgVar * 2));

                $overallHealth = round(($effScore + $relScore + $accScore) / 3);
                $riskScore = max(0, 100 - $overallHealth);

                // Update generator table if needed (lazy sync)
                $updStmt = $this->db->prepare("UPDATE generators SET health_score = ?, risk_score = ?, reliability_score = ?, fuel_accuracy_score = ? WHERE id = ?");
                $updStmt->execute([$overallHealth, $riskScore, $relScore, $accScore, $g['id']]);

                $g['health_score'] = $overallHealth;
                $g['risk_score'] = $riskScore;
                $g['reliability_score'] = $relScore;
                $g['fuel_accuracy_score'] = $accScore;
                $processedGenerators[] = $g;
            }

            echo json_encode([
                'generators' => $processedGenerators,
                'chart' => $chartData,
                'alerts' => $alerts
            ]);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function getSmartMonitoringAlerts() {
        try {
            $stmt = $this->db->query("
                SELECT a.*, g.name as generator_name, b.name as building_name, r.date as report_date
                FROM generator_alerts a
                JOIN generators g ON a.generator_id = g.id
                LEFT JOIN buildings b ON g.building_id = b.id
                LEFT JOIN generator_daily_reports r ON a.report_id = r.id
                ORDER BY a.created_at DESC
                LIMIT 50
            ");
            echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function resolveSmartAlert($id) {
        try {
            $stmt = $this->db->prepare("UPDATE generator_alerts SET status = 'Resolved' WHERE id = ?");
            $stmt->execute([$id]);
            echo json_encode(['message' => 'Alert resolved successfully']);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    // --- AI Engine & Summaries ---
    public function getAISummaries() {
        try {
            // Get all generators and their latest fuel/status
            $stmt = $this->db->query("SELECT id, name, current_fuel, status FROM generators");
            $generators = $stmt->fetchAll(PDO::FETCH_ASSOC);

            // Fetch yesterday's reports to see who is missing data
            $yesterday = date('Y-m-d', strtotime('-1 day'));
            $repStmt = $this->db->prepare("SELECT generator_id, actual_fuel_used, kwh_produced, running_hours, efficiency_score FROM generator_daily_reports WHERE date = ?");
            $repStmt->execute([$yesterday]);
            $yesterdayReports = $repStmt->fetchAll(PDO::FETCH_ASSOC);
            $reportedGenIds = array_column($yesterdayReports, 'generator_id');

            // Generate Daily Summary text programmatically
            $attentionNeeded = [];
            
            foreach ($generators as $gen) {
                // Check if reading is missing
                if (!in_array($gen['id'], $reportedGenIds)) {
                    $attentionNeeded[] = "• {$gen['name']} Generator: No reading entered yesterday.";
                }
                
                // Check fuel levels
                $avgFuelStmt = $this->db->prepare("SELECT AVG(actual_fuel_used) FROM generator_daily_reports WHERE generator_id = ? AND actual_fuel_used > 0");
                $avgFuelStmt->execute([$gen['id']]);
                $avgDailyFuel = floatval($avgFuelStmt->fetchColumn());
                
                if ($avgDailyFuel > 0 && $gen['current_fuel'] > 0) {
                    $daysRemaining = round($gen['current_fuel'] / $avgDailyFuel);
                    if ($daysRemaining <= 3) {
                        $attentionNeeded[] = "• {$gen['name']} Generator: Fuel remaining for approx. {$daysRemaining} days.";
                    }
                } else if ($gen['current_fuel'] < 50) {
                    $attentionNeeded[] = "• {$gen['name']} Generator: Fuel is very low ({$gen['current_fuel']} L).";
                }
                
                // Check maintenance (dummy check for now, can be expanded)
                if ($gen['status'] === 'Maintenance') {
                    $attentionNeeded[] = "• {$gen['name']} Generator: Currently under maintenance.";
                }
            }

            $attentionCount = count($attentionNeeded);
            $dailySummary = "Good morning. Today there are {$attentionCount} generators requiring attention:\n\n" . implode("\n", $attentionNeeded);
            if ($attentionCount === 0) {
                $dailySummary = "Good morning. All generators are operating normally. No immediate attention is required.";
            }

            // Generate Weekly Summary
            $weekStart = date('Y-m-d', strtotime('-7 days'));
            $weekStmt = $this->db->prepare("
                SELECT SUM(actual_fuel_used) as total_fuel, 
                       SUM(running_hours) as total_hours, 
                       SUM(actual_fuel_used * (SELECT cost_per_liter FROM fuel_movements WHERE generator_id = generator_daily_reports.generator_id ORDER BY date DESC LIMIT 1)) as total_cost,
                       MAX(actual_fuel_used) as max_fuel,
                       MIN(efficiency_score) as min_eff
                FROM generator_daily_reports 
                WHERE date >= ?
            ");
            $weekStmt->execute([$weekStart]);
            $weekStats = $weekStmt->fetch(PDO::FETCH_ASSOC);
            
            // Find highest consumption generator
            $highStmt = $this->db->prepare("SELECT g.name, SUM(r.actual_fuel_used) as tot FROM generator_daily_reports r JOIN generators g ON r.generator_id = g.id WHERE r.date >= ? GROUP BY g.id ORDER BY tot DESC LIMIT 1");
            $highStmt->execute([$weekStart]);
            $highest = $highStmt->fetch(PDO::FETCH_ASSOC);
            
            // Find lowest efficiency
            $lowStmt = $this->db->prepare("SELECT g.name, AVG(r.efficiency_score) as eff FROM generator_daily_reports r JOIN generators g ON r.generator_id = g.id WHERE r.date >= ? AND r.efficiency_score > 0 GROUP BY g.id ORDER BY eff ASC LIMIT 1");
            $lowStmt->execute([$weekStart]);
            $lowest = $lowStmt->fetch(PDO::FETCH_ASSOC);

            $weeklySummary = "Weekly Generator Report:\n\n";
            $weeklySummary .= "• Total Fuel Consumed: " . round($weekStats['total_fuel'] ?? 0) . " Liters\n";
            $weeklySummary .= "• Total Estimated Cost: " . round($weekStats['total_cost'] ?? 0) . " CFA\n";
            $weeklySummary .= "• Total Operating Hours: " . round($weekStats['total_hours'] ?? 0) . " Hours\n";
            $weeklySummary .= "• Highest Consumption Generator: " . ($highest['name'] ?? 'N/A') . "\n";
            $weeklySummary .= "• Lowest Efficiency Generator: " . ($lowest['name'] ?? 'N/A') . "\n";
            
            // Save to DB (optional, but requested for history)
            $today = date('Y-m-d');
            $saveStmt = $this->db->prepare("INSERT INTO generator_ai_summaries (date, daily_summary, weekly_summary) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE daily_summary = VALUES(daily_summary), weekly_summary = VALUES(weekly_summary)");
            $saveStmt->execute([$today, $dailySummary, $weeklySummary]);

            echo json_encode([
                'daily_summary' => $dailySummary,
                'weekly_summary' => $weeklySummary
            ]);

        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function aiChatQuery() {
        try {
            $data = json_decode(file_get_contents("php://input"), true);
            $query = strtolower($data['query'] ?? '');
            $response = "I couldn't understand that query. I can answer questions about fuel consumption, remaining days, maintenance, and reports.";

            if (strpos($query, 'most fuel') !== false || strpos($query, 'highest consumption') !== false) {
                // "Which generator consumed the most fuel this month?"
                $monthStart = date('Y-m-01');
                $stmt = $this->db->prepare("SELECT g.name, SUM(r.actual_fuel_used) as tot FROM generator_daily_reports r JOIN generators g ON r.generator_id = g.id WHERE r.date >= ? GROUP BY g.id ORDER BY tot DESC LIMIT 1");
                $stmt->execute([$monthStart]);
                $res = $stmt->fetch(PDO::FETCH_ASSOC);
                if ($res) {
                    $response = "The generator that consumed the most fuel this month is **{$res['name']}** with " . round($res['tot']) . " Liters.";
                }
            } else if (strpos($query, 'days of fuel remain') !== false) {
                // "How many days of fuel remain for Galaxy?"
                preg_match('/for\s+([a-z0-9\s]+)\??/i', $query, $matches);
                if (!empty($matches[1])) {
                    $genName = trim($matches[1]);
                    $stmt = $this->db->prepare("SELECT id, name, current_fuel FROM generators WHERE name LIKE ? LIMIT 1");
                    $stmt->execute(["%$genName%"]);
                    $gen = $stmt->fetch(PDO::FETCH_ASSOC);
                    if ($gen) {
                        $avgStmt = $this->db->prepare("SELECT AVG(actual_fuel_used) FROM generator_daily_reports WHERE generator_id = ? AND actual_fuel_used > 0");
                        $avgStmt->execute([$gen['id']]);
                        $avgFuel = floatval($avgStmt->fetchColumn());
                        if ($avgFuel > 0) {
                            $days = round($gen['current_fuel'] / $avgFuel);
                            $response = "Based on recent consumption patterns, **{$gen['name']}** has approximately **{$days} days** of fuel remaining ({$gen['current_fuel']} Liters).";
                        } else {
                            $response = "I don't have enough historical data to estimate remaining days for {$gen['name']}.";
                        }
                    } else {
                        $response = "I couldn't find a generator matching '{$genName}'.";
                    }
                } else {
                     $response = "Please specify a generator name, like 'How many days of fuel remain for Galaxy?'";
                }
            } else if (strpos($query, 'maintenance') !== false) {
                // "Which generators need maintenance this week?"
                $stmt = $this->db->query("SELECT name FROM generators WHERE status = 'Maintenance'");
                $maint = $stmt->fetchAll(PDO::FETCH_ASSOC);
                if ($maint) {
                    $names = implode(", ", array_column($maint, 'name'));
                    $response = "The following generators are currently marked for maintenance: **{$names}**.";
                } else {
                    $response = "No generators are currently scheduled for maintenance this week based on the system status.";
                }
            } else if (strpos($query, 'report') !== false && strpos($query, 'export') === false && strpos($query, 'print') === false) {
                $response = "To view detailed reports, please navigate to the Export & Printing section or use the 'Export' buttons in the Dashboard. Would you like me to trigger an export?";
            } else if (strpos($query, 'export') !== false || strpos($query, 'print') !== false) {
                $response = "ACTION_TRIGGER_EXPORT"; // Magic string the frontend will catch to trigger its own export logic
            } else {
                // Generic fallback, querying basic stats
                $stmt = $this->db->query("SELECT SUM(current_fuel) FROM generators");
                $totalFuel = $stmt->fetchColumn();
                $response = "I am an AI Assistant for the Generator Management System. Currently, the total fuel across all generators is **{$totalFuel} Liters**. Ask me about fuel consumption, remaining days, or reports!";
            }

            echo json_encode(['response' => $response]);

        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    // --- Calendar Events ---
    public function getCalendarEvents() {
        try {
            $events = [];

            // 1. Daily Reports (Readings)
            $reportStmt = $this->db->query("
                SELECT r.id, r.date, g.name as gen_name, r.kwh_produced 
                FROM generator_daily_reports r 
                JOIN generators g ON r.generator_id = g.id
                WHERE r.date >= DATE_SUB(CURDATE(), INTERVAL 2 MONTH)
            ");
            while ($row = $reportStmt->fetch(PDO::FETCH_ASSOC)) {
                $events[] = [
                    'id' => 'rep_' . $row['id'],
                    'title' => "Reading: {$row['gen_name']} (+{$row['kwh_produced']} kWh)",
                    'date' => $row['date'],
                    'type' => 'reading',
                    'color' => '#3b82f6' // blue
                ];
            }

            // 2. Fuel Refills
            $fuelStmt = $this->db->query("
                SELECT f.id, DATE(f.date) as event_date, g.name as gen_name, f.amount 
                FROM fuel_movements f 
                JOIN generators g ON f.generator_id = g.id
                WHERE f.type = 'Refill' AND f.date >= DATE_SUB(CURDATE(), INTERVAL 2 MONTH)
            ");
            while ($row = $fuelStmt->fetch(PDO::FETCH_ASSOC)) {
                $events[] = [
                    'id' => 'fuel_' . $row['id'],
                    'title' => "Refill: {$row['gen_name']} ({$row['amount']} L)",
                    'date' => $row['event_date'],
                    'type' => 'refill',
                    'color' => '#10b981' // green
                ];
            }

            // 3. Maintenance (Using alerts or status for now)
            $maintStmt = $this->db->query("
                SELECT a.id, DATE(a.created_at) as event_date, g.name as gen_name 
                FROM generator_alerts a 
                JOIN generators g ON a.generator_id = g.id
                WHERE a.severity IN ('Critical', 'Warning') AND a.created_at >= DATE_SUB(CURDATE(), INTERVAL 2 MONTH)
            ");
            while ($row = $maintStmt->fetch(PDO::FETCH_ASSOC)) {
                $events[] = [
                    'id' => 'alert_' . $row['id'],
                    'title' => "Alert: {$row['gen_name']}",
                    'date' => $row['event_date'],
                    'type' => 'maintenance',
                    'color' => '#ef4444' // red
                ];
            }

            echo json_encode($events);

        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }
    
    public function getAIInsights($id) {
        try {
            $response = [];
            
            // Get latest analysis
            $stmt = $this->db->prepare("SELECT * FROM generator_analysis WHERE generator_id = ? ORDER BY reading_date DESC LIMIT 7");
            $stmt->execute([$id]);
            $response['analysis_history'] = $stmt->fetchAll(PDO::FETCH_ASSOC);
            $response['latest_analysis'] = $response['analysis_history'][0] ?? null;
            
            // Get predictions
            $stmt = $this->db->prepare("SELECT * FROM generator_predictions WHERE generator_id = ? ORDER BY prediction_date DESC LIMIT 1");
            $stmt->execute([$id]);
            $response['predictions'] = $stmt->fetch(PDO::FETCH_ASSOC);
            
            // Get active alerts
            $stmt = $this->db->prepare("SELECT * FROM generator_alerts WHERE generator_id = ? AND resolved_at IS NULL ORDER BY created_at DESC");
            $stmt->execute([$id]);
            $response['active_alerts'] = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            echo json_encode($response);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }
}
