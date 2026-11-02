<?php
require_once __DIR__ . '/../core/DataQualityEngine.php';

class AgentController {

    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    private function getUserId() {
        $token = JWT::getBearerToken();
        if ($token) {
            $decoded = JWT::decode($token);
            if ($decoded && isset($decoded['user_id'])) {
                return (int)$decoded['user_id'];
            }
        }
        return 1;
    }

    public function dashboardStats() {
        AuthMiddleware::requireLogin();
        
        // Mocking or aggregating real data.
        // Buildings count
        $buildingsStmt = $this->db->query("SELECT COUNT(*) as count FROM buildings");
        $assignedBuildings = $buildingsStmt->fetchColumn();
        
        // Generator readings pending
        $genPendingStmt = $this->db->query("SELECT COUNT(*) as count FROM generator_daily_reports WHERE status = 'Pending Verification'");
        $genPending = $genPendingStmt->fetchColumn();
        
        $genRejectedStmt = $this->db->query("SELECT COUNT(*) as count FROM generator_daily_reports WHERE status = 'Rejected'");
        $genRejected = $genRejectedStmt->fetchColumn();

        $genSubmittedTodayStmt = $this->db->query("SELECT COUNT(*) as count FROM generator_daily_reports WHERE DATE(submitted_at) = CURDATE()");
        $genSubmittedToday = $genSubmittedTodayStmt->fetchColumn();

        // Apartment readings pending
        // Count apartments that have no reading this month
        $aptTotalStmt = $this->db->query("SELECT COUNT(*) as count FROM electricity_subscriptions WHERE amps = 0 OR amps IS NULL");
        $aptTotal = $aptTotalStmt->fetchColumn();

        $aptReadMonthStmt = $this->db->query("SELECT COUNT(*) as count FROM electricity_meter_readings WHERE MONTH(reading_date) = MONTH(CURDATE()) AND YEAR(reading_date) = YEAR(CURDATE())");
        $aptReadMonth = $aptReadMonthStmt->fetchColumn();

        $aptRejectedStmt = $this->db->query("SELECT COUNT(*) as count FROM electricity_meter_readings WHERE status = 'Rejected'");
        $aptRejected = $aptRejectedStmt->fetchColumn();

        // Subscription tasks expiring within 5 days
        try {
            $subTasksStmt = $this->db->query("
                SELECT COUNT(*) FROM electricity_subscriptions es
                JOIN apartments a ON es.apartment_id = a.id
                WHERE es.status = 'Active' 
                AND es.end_date IS NOT NULL
                AND es.end_date >= CURDATE()
                AND es.end_date <= DATE_ADD(CURDATE(), INTERVAL 5 DAY)
                AND (es.amps IS NULL OR es.amps = 0)
                AND NOT EXISTS (
                    SELECT 1 FROM agent_subscription_readings asr
                    WHERE asr.subscription_id = es.id 
                    AND asr.status = 'Pending'
                    AND MONTH(asr.created_at) = MONTH(CURDATE())
                )
            ");
            $subTasksCount = $subTasksStmt->fetchColumn();
        } catch (Exception $e) {
            $subTasksCount = 0;
        }

        echo json_encode([
            'assignedBuildings' => $assignedBuildings,
            'pendingGenReadings' => $assignedBuildings - $genSubmittedToday > 0 ? $assignedBuildings - $genSubmittedToday : 0,
            'submittedGenToday' => $genSubmittedToday,
            'rejectedGen' => $genRejected,
            'totalApartments' => $aptTotal,
            'pendingAptReadings' => $aptTotal - $aptReadMonth > 0 ? $aptTotal - $aptReadMonth : 0,
            'completedAptMonth' => $aptReadMonth,
            'rejectedApt' => $aptRejected,
            'pendingSubTasks' => (int)$subTasksCount,
        ]);
    }

    public function getGeneratorHistory() {
        AuthMiddleware::requireLogin();
        $stmt = $this->db->query("
            SELECT r.*, b.name as building_name, 
            r.photo_meter_path as meter_photo_url, r.fuel_photo_path as fuel_photo_url,
            r.rejection_reason as admin_notes, r.date as date, r.current_meter_hours as generator_counter
            FROM generator_daily_reports r
            JOIN generators g ON r.generator_id = g.id
            JOIN buildings b ON g.building_id = b.id
            ORDER BY r.submitted_at DESC
        ");
        echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
    }

    // ─── NEW: Subscription Collection Methods ─────────────────────────────────

    /**
     * Get unpaid/partially paid subscription invoices for the agent to collect.
     */
    public function getUnpaidSubscriptionInvoices() {
        AuthMiddleware::requireLogin();
        try {
            $stmt = $this->db->prepare("
                SELECT 
                    ei.id as invoice_id,
                    ei.amount,
                    ei.amount_paid,
                    (ei.amount - ei.amount_paid) as remaining,
                    ei.due_date,
                    ei.status as invoice_status,
                    a.code as apartment_code,
                    b.id as building_id,
                    b.name as building_name,
                    t.full_name as tenant_name,
                    t.phone as tenant_phone
                FROM electricity_invoices ei
                JOIN apartments a ON ei.apartment_id = a.id
                JOIN buildings b ON a.building_id = b.id
                LEFT JOIN contracts c ON a.id = c.apartment_id AND c.status = 'Active'
                LEFT JOIN tenants t ON c.tenant_id = t.id
                WHERE ei.status IN ('Unpaid', 'Partially Paid')
                AND (ei.type IN ('Subscription', 'Fixed Subscription', 'Meter') OR ei.type = '')
                ORDER BY ei.due_date ASC, b.name ASC, a.code ASC
            ");
            $stmt->execute();
            $invoices = $stmt->fetchAll(PDO::FETCH_ASSOC);

            // Fetch collection history for the agent
            $histStmt = $this->db->prepare("
                SELECT 
                    ft.id, ft.amount, DATE(ft.created_at) as transaction_date, ft.notes as description,
                    a.code as apartment_code, b.name as building_name, t.full_name as tenant_name
                FROM financial_transactions ft
                JOIN electricity_invoices ei ON ft.invoice_id = ei.id AND ft.transaction_type = 'subscription_invoice'
                JOIN apartments a ON ei.apartment_id = a.id
                JOIN buildings b ON a.building_id = b.id
                LEFT JOIN contracts c ON a.id = c.apartment_id AND c.status = 'Active'
                LEFT JOIN tenants t ON c.tenant_id = t.id
                WHERE ft.created_by = ?
                ORDER BY ft.created_at DESC LIMIT 100
            ");
            $histStmt->execute([$this->getUserId()]);
            $history = $histStmt->fetchAll(PDO::FETCH_ASSOC);

            echo json_encode([
                'tasks' => $invoices,
                'history' => $history
            ]);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    /**
     * Submit collection of a subscription payment.
     */
    public function submitSubscriptionPayment() {
        AuthMiddleware::requireLogin();
        
        $data = json_decode(file_get_contents('php://input'), true);
        $invoice_id = $data['invoice_id'] ?? null;
        $amount_collected = floatval($data['amount_collected'] ?? 0);
        $status = $data['status'] ?? 'still_didnt_pay'; // 'collected' or 'still_didnt_pay'
        $agent_id = $this->getUserId();

        if (!$invoice_id) {
            http_response_code(400);
            echo json_encode(['error' => 'Missing invoice_id']);
            return;
        }

        if ($status === 'still_didnt_pay' || $amount_collected <= 0) {
            // Log attempt or simply return success without doing anything
            echo json_encode(['success' => true, 'message' => 'Noted as unpaid.']);
            return;
        }

        try {
            $this->db->beginTransaction();

            $invStmt = $this->db->prepare("SELECT amount, amount_paid FROM electricity_invoices WHERE id = ?");
            $invStmt->execute([$invoice_id]);
            $invoice = $invStmt->fetch(PDO::FETCH_ASSOC);

            if (!$invoice) {
                throw new Exception("Invoice not found.");
            }

            $new_amount_paid = floatval($invoice['amount_paid']) + $amount_collected;
            $new_status = 'Unpaid';
            if ($new_amount_paid >= floatval($invoice['amount'])) {
                $new_status = 'Paid';
            } elseif ($new_amount_paid > 0) {
                $new_status = 'Partially Paid';
            }

            $updStmt = $this->db->prepare("UPDATE electricity_invoices SET amount_paid = ?, status = ? WHERE id = ?");
            $updStmt->execute([$new_amount_paid, $new_status, $invoice_id]);

            // Create financial transaction
            $ftStmt = $this->db->prepare("
                INSERT INTO financial_transactions (transaction_type, amount, invoice_id, notes, created_by)
                VALUES ('subscription_invoice', ?, ?, 'Agent collected electricity payment', ?)
            ");
            $ftStmt->execute([$amount_collected, $invoice_id, $agent_id]);

            $this->db->commit();
            echo json_encode(['success' => true, 'message' => 'Payment collected successfully.']);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    // ─── NEW: Subscription Task Methods ───────────────────────────────────────

    /**
     * Request QR Authorization from Tenant (Pings the tenant's computer)
     */
    public function requestQrAuthorization() {
        try {
            AuthMiddleware::requireLogin();
            $data = json_decode(file_get_contents('php://input'), true);
            $invoiceIds = $data['invoice_ids'] ?? [];

            if (empty($invoiceIds) || !is_array($invoiceIds)) {
                throw new Exception("Invalid invoice data");
            }

            // Create placeholders for IN clause
            $placeholders = implode(',', array_fill(0, count($invoiceIds), '?'));
            
            $stmt = $this->db->prepare("
                UPDATE electricity_invoices 
                SET qr_requested_at = NOW() 
                WHERE id IN ($placeholders)
            ");
            $stmt->execute($invoiceIds);

            echo json_encode(['status' => 'success']);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
        }
    }

    /**
     * Get all subscription tasks (apartments with subscriptions expiring in ≤5 days)
     * Returns pending, accepted, and rejected submissions as well.
     */
    public function getSubscriptionTasks() {
        AuthMiddleware::requireLogin();
        try {
            $today = date('Y-m-d');
            $thirtyDaysLater = date('Y-m-d', strtotime('+30 days'));

            // All active subscriptions (both Meter and Fixed Amp) with billing within 30 days
            $stmt = $this->db->prepare("
                SELECT 
                    es.id as subscription_id,
                    es.apartment_id,
                    es.type as subscription_type,
                    es.start_date,
                    es.end_date,
                    es.next_billing_date,
                    es.monthly_fee,
                    es.amps,
                    es.status as subscription_status,
                    a.code as apartment_code,
                    b.id as building_id,
                    b.name as building_name,
                    t.full_name as tenant_name,
                    t.phone as tenant_phone,
                    DATEDIFF(es.next_billing_date, CURDATE()) as days_until_expiry,
                    es.last_meter_reading as previous_reading,
                    (SELECT reading_date FROM electricity_meter_readings 
                     WHERE apartment_id = a.id 
                     ORDER BY reading_date DESC, id DESC LIMIT 1) as previous_reading_date,
                    (SELECT id FROM agent_subscription_readings 
                     WHERE subscription_id = es.id 
                     ORDER BY created_at DESC LIMIT 1) as latest_submission_id,
                    (SELECT status FROM agent_subscription_readings 
                     WHERE subscription_id = es.id 
                     ORDER BY created_at DESC LIMIT 1) as latest_submission_status,
                    (SELECT rejection_reason FROM agent_subscription_readings 
                     WHERE subscription_id = es.id 
                     ORDER BY created_at DESC LIMIT 1) as rejection_reason,
                    (SELECT current_reading FROM agent_subscription_readings 
                     WHERE subscription_id = es.id 
                     ORDER BY created_at DESC LIMIT 1) as submitted_reading
                FROM electricity_subscriptions es
                JOIN apartments a ON es.apartment_id = a.id
                JOIN buildings b ON a.building_id = b.id
                LEFT JOIN contracts c ON a.id = c.apartment_id AND c.status = 'Active'
                LEFT JOIN tenants t ON c.tenant_id = t.id
                WHERE es.status = 'Active'
                AND es.next_billing_date IS NOT NULL
                AND es.next_billing_date <= ?
                ORDER BY es.next_billing_date ASC, b.name ASC, a.code ASC
            ");
            $stmt->execute([$thirtyDaysLater]);
            $tasks = $stmt->fetchAll(PDO::FETCH_ASSOC);

            // Also get all agent submissions (all statuses) for history tabs
            $histStmt = $this->db->prepare("
                SELECT 
                    asr.*,
                    a.code as apartment_code,
                    b.name as building_name,
                    t.full_name as tenant_name,
                    es.start_date as sub_start_date,
                    es.end_date as sub_end_date,
                    es.type as subscription_type,
                    es.amps
                FROM agent_subscription_readings asr
                JOIN apartments a ON asr.apartment_id = a.id
                JOIN buildings b ON a.building_id = b.id
                JOIN electricity_subscriptions es ON asr.subscription_id = es.id
                LEFT JOIN contracts c ON a.id = c.apartment_id AND c.status = 'Active'
                LEFT JOIN tenants t ON c.tenant_id = t.id
                ORDER BY asr.created_at DESC
                LIMIT 100
            ");
            $histStmt->execute();
            $history = $histStmt->fetchAll(PDO::FETCH_ASSOC);

            echo json_encode([
                'tasks' => $tasks,
                'history' => $history
            ]);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    /**
     * Agent submits meter reading for an expiring subscription
     */
    public function storeSubscriptionMeterReading() {
        AuthMiddleware::requireLogin();

        $apartment_id = $_POST['apartment_id'] ?? null;
        $subscription_id = $_POST['subscription_id'] ?? null;
        $current_reading = $_POST['current_reading'] ?? 0; // Default to 0 for fixed subscriptions
        $previous_reading = $_POST['previous_reading'] ?? 0;
        $notes = $_POST['notes'] ?? '';
        $amount_collected = floatval($_POST['amount_collected'] ?? 0);
        $submitted_by = $this->getUserId();
        $latitude = isset($_POST['latitude']) && $_POST['latitude'] !== '' ? (float)$_POST['latitude'] : null;
        $longitude = isset($_POST['longitude']) && $_POST['longitude'] !== '' ? (float)$_POST['longitude'] : null;

        if (!$apartment_id || !$subscription_id) {
            http_response_code(400);
            echo json_encode(['error' => 'Missing required fields: apartment_id, subscription_id']);
            return;
        }

        // Photo upload (mandatory)
        $uploadDir = __DIR__ . '/../../uploads/subscription-meters/';
        if (!is_dir($uploadDir)) {
            mkdir($uploadDir, 0777, true);
        }

        $photoPath = null;
        if (isset($_FILES['meter_photo']) && $_FILES['meter_photo']['error'] === 0) {
            $ext = pathinfo($_FILES['meter_photo']['name'], PATHINFO_EXTENSION);
            $filename = time() . '_subm_' . rand(1000, 9999) . '.' . $ext;
            if (move_uploaded_file($_FILES['meter_photo']['tmp_name'], $uploadDir . $filename)) {
                $photoPath = 'uploads/subscription-meters/' . $filename;
            }
        } elseif (isset($_POST['meter_photo_base64']) && !empty($_POST['meter_photo_base64'])) {
            $base64Data = $_POST['meter_photo_base64'];
            if (strpos($base64Data, 'base64:') === 0) {
                $base64Data = substr($base64Data, 7);
            }
            $bytes = base64_decode($base64Data);
            if ($bytes !== false && strlen($bytes) > 0) {
                $filename = time() . '_subm_' . rand(1000, 9999) . '.jpg';
                if (file_put_contents($uploadDir . $filename, $bytes)) {
                    $photoPath = 'uploads/subscription-meters/' . $filename;
                }
            } else {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid base64 photo data received. (Length: ' . strlen($_POST['meter_photo_base64']) . ')']);
                return;
            }
        } elseif (isset($_FILES['meter_photo'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Photo upload failed (Error Code: ' . $_FILES['meter_photo']['error'] . '). File may be too large for server limits.']);
            return;
        } else {
            http_response_code(400);
            $postKeys = implode(', ', array_keys($_POST));
            echo json_encode(['error' => 'Meter photo is missing entirely from the request. Received POST keys: ' . $postKeys]);
            return;
        }

        $consumption = max(0, floatval($current_reading) - floatval($previous_reading));
        $month = date('n');
        $year = date('Y');

        try {
            $this->db->beginTransaction();

            // If there is an existing rejected reading for this subscription this month, update it
            $existStmt = $this->db->prepare("
                SELECT id FROM agent_subscription_readings 
                WHERE subscription_id = ? AND status = 'Rejected' 
                AND billing_month = ? AND billing_year = ?
                ORDER BY created_at DESC LIMIT 1
            ");
            $existStmt->execute([$subscription_id, $month, $year]);
            $existing = $existStmt->fetchColumn();

            if ($existing) {
                // Re-submit: update existing rejected record
                $upd = $this->db->prepare("
                    UPDATE agent_subscription_readings 
                    SET previous_reading = ?, current_reading = ?, consumption = ?, 
                        notes = ?, photo_path = ?, status = 'Pending',
                        rejection_reason = NULL, reviewed_by = NULL, reviewed_at = NULL,
                        submitted_by = ?, created_at = NOW(),
                        latitude = ?, longitude = ?, amount_collected = ?
                    WHERE id = ?
                ");
                $upd->execute([$previous_reading, $current_reading, $consumption, $notes, $photoPath, $submitted_by, $latitude, $longitude, $amount_collected, $existing]);
            } else {
                // Get building/apartment/tenant info for denormalization
                $infoStmt = $this->db->prepare("
                    SELECT b.name as building_name, a.code as apartment_code, t.full_name as tenant_name
                    FROM apartments a
                    JOIN buildings b ON a.building_id = b.id
                    LEFT JOIN contracts c ON a.id = c.apartment_id AND c.status = 'Active'
                    LEFT JOIN tenants t ON c.tenant_id = t.id
                    WHERE a.id = ? LIMIT 1
                ");
                $infoStmt->execute([$apartment_id]);
                $info = $infoStmt->fetch(PDO::FETCH_ASSOC);

                $ins = $this->db->prepare("
                    INSERT INTO agent_subscription_readings 
                    (apartment_id, subscription_id, building_name, apartment_code, tenant_name,
                     previous_reading, current_reading, consumption, notes, photo_path, 
                     status, submitted_by, billing_month, billing_year, latitude, longitude, amount_collected)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'Pending', ?, ?, ?, ?, ?, ?)
                ");
                $ins->execute([
                    $apartment_id, $subscription_id,
                    $info['building_name'] ?? '', $info['apartment_code'] ?? '', $info['tenant_name'] ?? '',
                    $previous_reading, $current_reading, $consumption,
                    $notes, $photoPath, $submitted_by, $month, $year, $latitude, $longitude, $amount_collected
                ]);
            }

            $logStmt = $this->db->prepare("INSERT INTO activity_logs (user_id, action, entity_type, entity_id, details) VALUES (?, 'Electricity Subscription', 'Subscription', ?, ?)");
            $logStmt->execute([$submitted_by, $subscription_id, "Submitted meter reading (Consumption: {$consumption} kWh)"]);

            $this->db->commit();
            echo json_encode(['success' => true, 'message' => 'Meter reading submitted for admin review.']);
        } catch (PDOException $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    /**
     * Get pending agent subscription readings (for admin to review)
     */
    public function getPendingSubscriptionReadings() {
        AuthMiddleware::requireLogin();
        try {
            $stmt = $this->db->query("
                SELECT asr.*, 
                       a.code as apartment_code, b.name as building_name,
                       t.full_name as tenant_name, u.name as submitter_name,
                       es.start_date, es.end_date, es.monthly_fee, es.amps
                FROM agent_subscription_readings asr
                JOIN apartments a ON asr.apartment_id = a.id
                JOIN buildings b ON a.building_id = b.id
                JOIN electricity_subscriptions es ON asr.subscription_id = es.id
                LEFT JOIN contracts c ON a.id = c.apartment_id AND c.status = 'Active'
                LEFT JOIN tenants t ON c.tenant_id = t.id
                LEFT JOIN users u ON asr.submitted_by = u.id
                WHERE asr.status = 'Pending'
                ORDER BY asr.created_at DESC
            ");
            echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    /**
     * Admin verifies (accepts/rejects) an agent subscription reading.
     * On accept: auto-renews the electricity subscription by 1 month and stores meter reading.
     */
    public function verifySubscriptionReading($reading_id) {
        AuthMiddleware::requireLogin();
        try {
            $data = json_decode(file_get_contents('php://input'), true);
            $status = $data['status'] ?? null; // 'Accepted' or 'Rejected'
            $rejectionReason = $data['rejection_reason'] ?? null;
            $adminId = $data['user_id'] ?? 1;

            if (!in_array($status, ['Accepted', 'Rejected'])) {
                http_response_code(400);
                echo json_encode(['error' => 'Status must be Accepted or Rejected']);
                return;
            }

            // Get the reading details
            $readStmt = $this->db->prepare("SELECT * FROM agent_subscription_readings WHERE id = ?");
            $readStmt->execute([$reading_id]);
            $reading = $readStmt->fetch(PDO::FETCH_ASSOC);

            if (!$reading) {
                http_response_code(404);
                echo json_encode(['error' => 'Reading not found']);
                return;
            }

            $this->db->beginTransaction();

            // Update the reading status
            $updStmt = $this->db->prepare("
                UPDATE agent_subscription_readings 
                SET status = ?, rejection_reason = ?, reviewed_by = ?, reviewed_at = NOW()
                WHERE id = ?
            ");
            $updStmt->execute([$status, $rejectionReason, $adminId, $reading_id]);

            if ($status === 'Accepted') {
                $subId = $reading['subscription_id'];
                $apartmentId = $reading['apartment_id'];

                // Get the current subscription
                $subStmt = $this->db->prepare("SELECT * FROM electricity_subscriptions WHERE id = ?");
                $subStmt->execute([$subId]);
                $sub = $subStmt->fetch(PDO::FETCH_ASSOC);

                if ($sub) {
                    // Advance subscription by 1 month
                    $newStartDate = date('Y-m-d', strtotime($sub['end_date'] . ' +1 day'));
                    $newEndDate = date('Y-m-d', strtotime($sub['end_date'] . ' +1 month'));

                    $colCheckStmt = $this->db->query("SHOW COLUMNS FROM electricity_subscriptions LIKE 'last_meter_reading'");
                    $hasLastMeter = $colCheckStmt->fetch();

                    if ($hasLastMeter) {
                        $renewStmt = $this->db->prepare("
                            UPDATE electricity_subscriptions 
                            SET start_date = ?, end_date = ?, 
                                next_billing_date = ?,
                                last_meter_reading = ?
                            WHERE id = ?
                        ");
                        $renewStmt->execute([$newStartDate, $newEndDate, $newEndDate, $reading['current_reading'], $subId]);
                    } else {
                        $renewStmt = $this->db->prepare("
                            UPDATE electricity_subscriptions 
                            SET start_date = ?, end_date = ?, next_billing_date = ?
                            WHERE id = ?
                        ");
                        $renewStmt->execute([$newStartDate, $newEndDate, $newEndDate, $subId]);
                    }

                    // Auto-generate subscription invoice for the new month (Fixed Fee)
                    if ($sub['monthly_fee'] > 0) {
                        $monthStr = date('Y-m', strtotime($newStartDate));
                        $invCheck = $this->db->prepare("SELECT id FROM electricity_invoices WHERE apartment_id = ? AND type IN ('Subscription', 'Fixed Subscription') AND DATE_FORMAT(due_date, '%Y-%m') = ?");
                        $invCheck->execute([$apartmentId, $monthStr]);
                        $existingInvId = $invCheck->fetchColumn();
                        if (!$existingInvId) {
                            $invStmt = $this->db->prepare("INSERT INTO electricity_invoices (apartment_id, type, amount, due_date) VALUES (?, 'Subscription', ?, ?)");
                            $invStmt->execute([$apartmentId, $sub['monthly_fee'], $newStartDate]);
                            $invoiceId = $this->db->lastInsertId();
                        } else {
                            $invoiceId = $existingInvId;
                        }

                        // Apply the collected amount to the subscription invoice
                        if (isset($reading['amount_collected']) && floatval($reading['amount_collected']) > 0) {
                            $amt = floatval($reading['amount_collected']);
                            $payStmt = $this->db->prepare("
                                UPDATE electricity_invoices 
                                SET amount_paid = amount_paid + ?, 
                                    status = CASE WHEN amount_paid + ? >= amount THEN 'Paid' ELSE 'Partially Paid' END 
                                WHERE id = ?
                            ");
                            $payStmt->execute([$amt, $amt, $invoiceId]);
                            
                            $ftStmt = $this->db->prepare("
                                INSERT INTO financial_transactions (transaction_type, amount, invoice_id, notes, created_by, apartment_id, building_id)
                                VALUES ('subscription_invoice', ?, ?, 'Agent collected subscription payment during meter submission', ?, ?, ?)
                            ");
                            $ftStmt->execute([$amt, $invoiceId, $reading['submitted_by'], $apartmentId, $reading['building_id'] ?? null]);
                        }
                    }

                    // Also save this as an official electricity_meter_reading record for Metered usage
                    // We generate an invoice for the Meter usage if consumption > 0
                    if ($reading['consumption'] > 0 || ($sub['amps'] == 0 && $reading['current_reading'] > 0)) {
                        // Get price_per_kwh from generator
                        $ppkStmt = $this->db->prepare("
                            SELECT g.price_per_kw 
                            FROM generators g 
                            JOIN apartments a ON g.building_id = a.building_id 
                            WHERE a.id = ? LIMIT 1
                        ");
                        $ppkStmt->execute([$apartmentId]);
                        $pricePerKwh = $ppkStmt->fetchColumn() ?: 0;
                        $billAmount = $reading['consumption'] * floatval($pricePerKwh);

                        $meterIns = $this->db->prepare("
                            INSERT INTO electricity_meter_readings 
                            (apartment_id, previous_reading, current_reading, consumption, 
                             price_per_kwh, bill_amount, reading_date, photo_path, notes, 
                             status, submitted_by, billing_month, billing_year)
                            VALUES (?, ?, ?, ?, ?, ?, CURDATE(), ?, ?, 'Verified', ?, MONTH(CURDATE()), YEAR(CURDATE()))
                        ");
                        $meterIns->execute([
                            $apartmentId,
                            $reading['previous_reading'],
                            $reading['current_reading'],
                            $reading['consumption'],
                            $pricePerKwh,
                            $billAmount,
                            $reading['photo_path'],
                            $reading['notes'],
                            $reading['submitted_by']
                        ]);

                        // Auto-generate invoice for the meter usage
                        if ($billAmount > 0) {
                            $invStmt = $this->db->prepare("
                                INSERT INTO electricity_invoices (apartment_id, type, amount, due_date)
                                VALUES (?, 'Meter', ?, DATE_ADD(CURDATE(), INTERVAL 7 DAY))
                            ");
                            $invStmt->execute([
                                $apartmentId,
                                $billAmount
                            ]);
                        }
                    }
                }

                // Send notification to the agent who submitted
                if ($reading['submitted_by']) {
                    $notifMsg = "Your meter reading for {$reading['building_name']} - Apt {$reading['apartment_code']} (Tenant: {$reading['tenant_name']}) has been ACCEPTED. Subscription renewed for next month.";
                    $notifStmt = $this->db->prepare("
                        INSERT INTO notifications (user_id, title, message, type, reference_id, seen_by_agent)
                        VALUES (?, 'Meter Reading Accepted ✅', ?, 'agent_reading_accepted', ?, 0)
                    ");
                    $notifStmt->execute([$reading['submitted_by'], $notifMsg, $reading_id]);
                }
            } else {
                // Rejected — notify the agent
                if ($reading['submitted_by']) {
                    $reason = $rejectionReason ?: 'Please resubmit with correct information.';
                    
                    // Notification 1: Rejection Reason
                    $notifMsg1 = "Your meter reading submission for Apartment {$reading['apartment_code']} has been rejected. Reason: {$reason}";
                    $notifStmt1 = $this->db->prepare("
                        INSERT INTO notifications (user_id, title, message, type, reference_id, seen_by_agent)
                        VALUES (?, 'Meter Reading Rejected ❌', ?, 'agent_reading_rejected', ?, 0)
                    ");
                    $notifStmt1->execute([$reading['submitted_by'], $notifMsg1, $reading_id]);
                    
                    // Notification 2: New Action Required
                    $notifMsg2 = "Apartment {$reading['apartment_code']} requires a new meter reading submission.";
                    $notifStmt2 = $this->db->prepare("
                        INSERT INTO notifications (user_id, title, message, type, reference_id, seen_by_agent)
                        VALUES (?, 'Action Required 🚨', ?, 'agent_action_required', ?, 0)
                    ");
                    $notifStmt2->execute([$reading['submitted_by'], $notifMsg2, $reading_id]);
                }
            }

            $this->db->commit();
            echo json_encode(['success' => true, 'message' => "Reading {$status} successfully."]);
        } catch (PDOException $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    /**
     * Get agent's unread decision notifications (accept/reject)
     */
    public function getAgentReadingNotifications() {
        AuthMiddleware::requireLogin();
        try {
            $userId = $_GET['user_id'] ?? 1;

            $stmt = $this->db->prepare("
                SELECT * FROM notifications 
                WHERE user_id = ? 
                AND type IN ('agent_reading_accepted', 'agent_reading_rejected')
                AND (seen_by_agent = 0 OR seen_by_agent IS NULL)
                ORDER BY created_at DESC
            ");
            $stmt->execute([$userId]);
            echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    /**
     * Mark agent notification as seen
     */
    public function markAgentNotificationSeen($id) {
        AuthMiddleware::requireLogin();
        try {
            $stmt = $this->db->prepare("UPDATE notifications SET seen_by_agent = 1, is_read = 1 WHERE id = ?");
            $stmt->execute([$id]);
            echo json_encode(['success' => true]);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    // ─── Existing Generator/Apartment Reading Methods ──────────────────────────

    /**
     * Get all apartments in a building with their latest electricity reading and subscription info.
     * Used by the agent "Submit Apartment Reading" page.
     */
    public function getBuildingApartments(string $building_id) {
        AuthMiddleware::requireLogin();
        try {
            $stmt = $this->db->prepare("
                SELECT
                    a.id as apartment_id,
                    a.code as apartment_code,
                    b.name as building_name,
                    t.full_name as tenant_name,
                    t.phone as tenant_phone,
                    -- Latest meter reading
                    (SELECT current_reading FROM electricity_meter_readings
                     WHERE apartment_id = a.id
                     ORDER BY reading_date DESC, id DESC LIMIT 1) as last_reading,
                    (SELECT reading_date FROM electricity_meter_readings
                     WHERE apartment_id = a.id
                     ORDER BY reading_date DESC, id DESC LIMIT 1) as last_reading_date,
                    (SELECT status FROM electricity_meter_readings
                     WHERE apartment_id = a.id
                     ORDER BY reading_date DESC, id DESC LIMIT 1) as last_reading_status,
                    -- Days since last reading (for 7-day cooldown check)
                    DATEDIFF(CURDATE(), (
                        SELECT reading_date FROM electricity_meter_readings
                        WHERE apartment_id = a.id
                        ORDER BY reading_date DESC, id DESC LIMIT 1
                    )) as days_since_last_reading,
                    -- Active subscription info
                    es.id as subscription_id,
                    es.type as subscription_type,
                    es.amps,
                    es.monthly_fee,
                    es.next_billing_date,
                    es.last_meter_reading as subscription_prev_reading,
                    (SELECT status FROM agent_subscription_readings
                     WHERE subscription_id = es.id
                     ORDER BY created_at DESC LIMIT 1) as latest_submission_status
                FROM apartments a
                JOIN buildings b ON a.building_id = b.id
                LEFT JOIN contracts c ON a.id = c.apartment_id AND c.status = 'Active'
                LEFT JOIN tenants t ON c.tenant_id = t.id
                LEFT JOIN electricity_subscriptions es ON es.apartment_id = a.id AND es.status = 'Active'
                WHERE a.building_id = ?
                ORDER BY a.code ASC
            ");
            $stmt->execute([$building_id]);
            $apartments = $stmt->fetchAll(PDO::FETCH_ASSOC);
            echo json_encode($apartments);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function getApartmentHistory() {
        AuthMiddleware::requireLogin();
        $stmt = $this->db->query("
            SELECT r.*, a.code as apartment_code, b.name as building_name,
            r.photo_path as meter_photo_url, r.rejection_reason as admin_notes, r.reading_date as date
            FROM electricity_meter_readings r
            JOIN apartments a ON r.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            ORDER BY r.submitted_at DESC
        ");
        echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
    }

    public function storeGeneratorReading() {
        AuthMiddleware::requireLogin();
        
        $json = json_decode(file_get_contents("php://input"), true) ?? [];
        $data = array_merge($_POST, $json);

        $building_id = $data['building_id'] ?? null;
        $generator_id = $data['generator_id'] ?? null;

        if (!$generator_id && $building_id) {
            $genStmt = $this->db->prepare("SELECT id, current_fuel FROM generators WHERE building_id = ? LIMIT 1");
            $genStmt->execute([$building_id]);
            $generator = $genStmt->fetch();
            $generator_id = $generator['id'] ?? null;
        }

        if (!$generator_id && !$building_id) {
            $genStmt = $this->db->query("SELECT id FROM generators LIMIT 1");
            $generator_id = $genStmt->fetchColumn() ?: null;
        }

        if (!$generator_id) {
            http_response_code(400);
            echo json_encode(['error' => 'Building ID or Generator ID is required']);
            return;
        }

        $gen_id = $generator_id;
        
        $submitted_hours = (isset($data['submitted_hours']) && $data['submitted_hours'] !== '') ? floatval($data['submitted_hours']) : null;
        $manual_hours = (isset($data['manual_hours']) && $data['manual_hours'] !== '') ? floatval($data['manual_hours']) : null;
        
        // Fetch previous log from daily_logs for AI Engine baseline (EXCLUDING TODAY so resubmissions calculate against yesterday)
        $dlStmt = $this->db->prepare("SELECT submitted_hours FROM daily_logs WHERE generator_id = ? AND date < CURDATE() ORDER BY date DESC, id DESC LIMIT 1");
        $dlStmt->execute([$gen_id]);
        $prevDl = $dlStmt->fetch(PDO::FETCH_ASSOC);
        
        // Also fetch generator initial meter reading
        $genStmt = $this->db->prepare("SELECT initial_meter_reading, expected_fuel_consumption_per_hour FROM generators WHERE id = ?");
        $genStmt->execute([$gen_id]);
        $generatorData = $genStmt->fetch(PDO::FETCH_ASSOC);
        
        $prev_hours = $prevDl ? floatval($prevDl['submitted_hours']) : floatval($generatorData['initial_meter_reading'] ?? 0);

        // ── Decision Tree ──────────────────────────────────────────────────────
        $calculated_hours = 0;
        $new_meter_value  = $submitted_hours;   // what we'll store as "submitted_hours" in DB
        $mismatch_flag    = false;

        $has_meter  = ($submitted_hours !== null);
        $has_manual = ($manual_hours    !== null);
        
        // Handle legacy payload (where input_method is not provided)
        if (!$has_meter && !$has_manual) {
             $has_meter = true;
             $submitted_hours = !empty($data['generator_counter']) ? floatval($data['generator_counter']) : (!empty($data['running_hours']) ? floatval($data['running_hours']) : 0);
             $new_meter_value = $submitted_hours;
        }

        if ($has_meter && !$has_manual) {
            $input_method = 'Meter Only';
            $calculated_hours = ($prev_hours !== null) ? ($submitted_hours - $prev_hours) : 0;
            $new_meter_value  = $submitted_hours;
        } elseif ($has_manual && !$has_meter) {
            $input_method = 'Hours Only';
            $calculated_hours = $manual_hours;
            $new_meter_value  = ($prev_hours !== null) ? ($prev_hours + $manual_hours) : $manual_hours;
        } else {
            $input_method = 'Both';
            $meter_delta = ($prev_hours !== null) ? ($submitted_hours - $prev_hours) : 0;
            if (abs($meter_delta - $manual_hours) > 0.5) {
                $mismatch_flag = true;
                $input_method = 'Both (Mismatch)';
            }
            $calculated_hours = $meter_delta;
            $new_meter_value  = $submitted_hours;
        }
        
        $counter = $new_meter_value;
        $running_hours = $calculated_hours;

        $current_kwh = !empty($data['current_kwh']) ? $data['current_kwh'] : 0;
        $fuel_added = !empty($data['fuel_added']) ? $data['fuel_added'] : 0;
        $remaining_fuel = !empty($data['remaining_fuel']) ? $data['remaining_fuel'] : (!empty($data['current_fuel']) ? $data['current_fuel'] : 0);
        $spare_fuel = !empty($data['spare_fuel']) ? $data['spare_fuel'] : 0;
        $notes = $data['notes'] ?? '';

        // Photos
        $uploadDir = __DIR__ . '/../../uploads/generator-readings/';
        if (!is_dir($uploadDir)) {
            mkdir($uploadDir, 0777, true);
        }

        $meterPhotoPath = null;
        if (isset($_FILES['meter_photo']) && $_FILES['meter_photo']['error'] === 0) {
            $filename = time() . '_meter_' . basename($_FILES['meter_photo']['name']);
            if (move_uploaded_file($_FILES['meter_photo']['tmp_name'], $uploadDir . $filename)) {
                $meterPhotoPath = 'uploads/generator-readings/' . $filename;
            }
        }

        $fuelPhotoPath = null;
        if (isset($_FILES['fuel_photo']) && $_FILES['fuel_photo']['error'] === 0) {
            $filename = time() . '_fuel_' . basename($_FILES['fuel_photo']['name']);
            if (move_uploaded_file($_FILES['fuel_photo']['tmp_name'], $uploadDir . $filename)) {
                $fuelPhotoPath = 'uploads/generator-readings/' . $filename;
            }
        }

        // Fetch previous kwh / meter hours
        $prevStmt = $this->db->prepare("SELECT current_kwh, current_meter_hours, meter_hours FROM generator_daily_reports WHERE generator_id = ? ORDER BY date DESC, created_at DESC LIMIT 1");
        $prevStmt->execute([$gen_id]);
        $prevReport = $prevStmt->fetch(PDO::FETCH_ASSOC);
        $previous_meter = $prevReport ? (floatval($prevReport['current_meter_hours'] ?? 0) > 0 ? floatval($prevReport['current_meter_hours']) : floatval($prevReport['meter_hours'] ?? $prevReport['current_kwh'] ?? 0)) : floatval($prev_hours ?? 0);
        $previous_kwh = $previous_meter;

        // If current_kwh is not explicitly set, use the counter/meter reading
        if (empty($current_kwh) || floatval($current_kwh) == 0) {
            $current_kwh = $counter;
        }
        $kwh_produced = max(0, floatval($current_kwh) - $previous_kwh);

        $submitted_by = $this->getUserId();

        $stmt = $this->db->prepare("
            INSERT INTO generator_daily_reports 
            (generator_id, date, fuel_added, fuel_remaining, spare_remaining, running_hours, meter_hours, current_meter_hours, previous_meter_hours, current_kwh, previous_kwh, kwh_produced, notes, photo_meter_path, fuel_photo_path, status, submitted_at, cost_per_liter, submitted_by)
            VALUES (?, CURDATE(), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'Pending Verification', NOW(), 0, ?)
            ON DUPLICATE KEY UPDATE 
            fuel_added = VALUES(fuel_added),
            fuel_remaining = VALUES(fuel_remaining),
            spare_remaining = VALUES(spare_remaining),
            running_hours = VALUES(running_hours),
            meter_hours = VALUES(meter_hours),
            current_meter_hours = VALUES(current_meter_hours),
            previous_meter_hours = VALUES(previous_meter_hours),
            current_kwh = VALUES(current_kwh),
            previous_kwh = VALUES(previous_kwh),
            kwh_produced = VALUES(kwh_produced),
            notes = VALUES(notes),
            photo_meter_path = COALESCE(VALUES(photo_meter_path), photo_meter_path),
            fuel_photo_path = COALESCE(VALUES(fuel_photo_path), fuel_photo_path),
            status = 'Pending Verification',
            submitted_at = NOW(),
            submitted_by = COALESCE(VALUES(submitted_by), submitted_by)
        ");
        
        $stmt->execute([
            $gen_id, $fuel_added, $remaining_fuel, $spare_fuel, $running_hours, $counter, $counter, $previous_meter, $current_kwh, $previous_kwh, $kwh_produced, $notes, $meterPhotoPath, $fuelPhotoPath, $submitted_by
        ]);

        // ─── Data Quality Scan ────────────────────────────────────────────────
        $engine = new DataQualityEngine();
        $stmtRep = $this->db->prepare("SELECT * FROM generator_daily_reports WHERE generator_id = ? AND date = CURDATE()");
        $stmtRep->execute([$gen_id]);
        $insertedReport = $stmtRep->fetch(PDO::FETCH_ASSOC);

        if ($insertedReport) {
            $prevStmt2 = $this->db->prepare("SELECT current_meter_hours FROM generator_daily_reports WHERE generator_id = ? AND submitted_at < ? ORDER BY submitted_at DESC LIMIT 1");
            $prevStmt2->execute([$gen_id, $insertedReport['submitted_at']]);
            $insertedReport['previous_meter_hours'] = $prevStmt2->fetchColumn() ?: null;

            // Make sure photo paths match what the rules check
            $insertedReport['photo_meter_path'] = $insertedReport['photo_meter_path'] ?? $insertedReport['meter_photo_path'] ?? null;

            $engine->validateRecord('AgentGenerator', 'generator_daily_reports', $insertedReport['id'], $insertedReport, $submitted_by);
        }
        // ──────────────────────────────────────────────────────────────────────

        // Insert into the new AI daily_logs table
        $factory_burn_rate = floatval($generatorData['expected_fuel_consumption_per_hour'] ?? 0);
        $expected_fuel     = $calculated_hours * $factory_burn_rate;

        // Fetch current fuel price for historical locking
        $priceStmt = $this->db->prepare("SELECT cost_per_liter FROM fuel_movements WHERE generator_id = ? AND type='Refill' ORDER BY date DESC LIMIT 1");
        $priceStmt->execute([$gen_id]);
        $latestPrice = $priceStmt->fetchColumn();
        $fuel_price_at_time = $latestPrice ? floatval($latestPrice) : 850.0;
        
        // Prevent duplicate daily_logs on the same day if re-submitted
        $dlCheckStmt = $this->db->prepare("SELECT id FROM daily_logs WHERE generator_id = ? AND date = CURDATE()");
        $dlCheckStmt->execute([$gen_id]);
        $existingDlId = $dlCheckStmt->fetchColumn();
        
        if ($existingDlId) {
            $dlUpdateStmt = $this->db->prepare("
                UPDATE daily_logs 
                SET submitted_hours = ?, calculated_hours_worked = ?, expected_factory_fuel_burn = ?, status_flag = ?, fuel_price_at_time = ?
                WHERE id = ?
            ");
            $dlUpdateStmt->execute([
                $new_meter_value, $calculated_hours, $expected_fuel,
                $mismatch_flag ? 'Data Entry Mismatch' : 'Pending Analysis',
                $fuel_price_at_time, $existingDlId
            ]);
        } else {
            $dlInsertStmt = $this->db->prepare("
                INSERT INTO daily_logs 
                (generator_id, date, submitted_hours, calculated_hours_worked, expected_factory_fuel_burn, status_flag, fuel_price_at_time) 
                VALUES (?, CURDATE(), ?, ?, ?, ?, ?)
            ");
            $dlInsertStmt->execute([
                $gen_id, $new_meter_value,
                $calculated_hours, $expected_fuel,
                $mismatch_flag ? 'Data Entry Mismatch' : 'Pending Analysis',
                $fuel_price_at_time
            ]);
        }

        $logStmt = $this->db->prepare("INSERT INTO activity_logs (user_id, action, entity_type, entity_id, details) VALUES (?, 'Generator Log', 'Generator', ?, ?)");
        $logStmt->execute([$submitted_by, $gen_id, "Submitted daily report (Fuel Added: {$fuel_added}L)"]);

        echo json_encode(['success' => true]);

    }

    public function storeApartmentReading() {
        AuthMiddleware::requireLogin();
        
        $apartment_id   = $_POST['apartment_id'] ?? null;
        $notes          = $_POST['notes'] ?? '';
        $submitted_by   = $this->getUserId();

        if (!$apartment_id) {
            http_response_code(400);
            echo json_encode(['error' => 'Missing apartment_id']);
            return;
        }

        // ─── Get subscription type for this apartment ─────────────────────────
        $subStmt = $this->db->prepare("
            SELECT type, monthly_fee, amps, cost_per_amp
            FROM electricity_subscriptions
            WHERE apartment_id = ? AND status = 'Active'
            LIMIT 1
        ");
        $subStmt->execute([$apartment_id]);
        $subscription = $subStmt->fetch(PDO::FETCH_ASSOC);

        $isFixed = $subscription && in_array($subscription['type'], ['Fixed Monthly', 'Fixed Amp']);

        // ─── Upload photo directory ────────────────────────────────────────────
        $uploadDir = __DIR__ . '/../../uploads/electricity-meters/';
        if (!is_dir($uploadDir)) mkdir($uploadDir, 0777, true);

        $photoPath = null;
        if (isset($_FILES['meter_photo']) && $_FILES['meter_photo']['error'] === 0) {
            $filename = time() . '_' . basename($_FILES['meter_photo']['name']);
            if (move_uploaded_file($_FILES['meter_photo']['tmp_name'], $uploadDir . $filename)) {
                $photoPath = 'uploads/electricity-meters/' . $filename;
            }
        }

        // ═══════════════════════════════════════════════════════════════════════
        // FIXED SUBSCRIPTION FLOW
        // Agent just confirms monthly payment — no kWh reading needed.
        // Bill amount = fixed monthly fee from subscription.
        // ═══════════════════════════════════════════════════════════════════════
        if ($isFixed) {
            $bill_amount = floatval($subscription['monthly_fee']);

            // Check for duplicate this billing month
            $dupStmt = $this->db->prepare("
                SELECT id FROM electricity_meter_readings
                WHERE apartment_id = ?
                  AND billing_month = MONTH(CURDATE())
                  AND billing_year  = YEAR(CURDATE())
                  AND status NOT IN ('Rejected')
                LIMIT 1
            ");
            $dupStmt->execute([$apartment_id]);
            if ($dupStmt->fetchColumn()) {
                http_response_code(429);
                echo json_encode([
                    'error'   => 'duplicate',
                    'message' => 'A fixed payment confirmation has already been submitted for this apartment this month.'
                ]);
                return;
            }

            $stmt = $this->db->prepare("
                INSERT INTO electricity_meter_readings
                    (apartment_id, previous_reading, current_reading, consumption,
                     price_per_kwh, bill_amount, reading_date, photo_path, notes,
                     status, submitted_at, billing_month, billing_year, submitted_by)
                VALUES (?, 0, 0, 0, 0, ?, CURDATE(), ?, ?, 'Pending', NOW(), MONTH(CURDATE()), YEAR(CURDATE()), ?)
            ");
            $stmt->execute([$apartment_id, $bill_amount, $photoPath, $notes, $submitted_by]);
            $report_id = $this->db->lastInsertId();

            // ─── Data Quality Scan ────────────────────────────────────────────
            $engine = new DataQualityEngine();
            $stmtRep = $this->db->prepare("SELECT * FROM electricity_meter_readings WHERE id = ?");
            $stmtRep->execute([$report_id]);
            if ($insertedReport = $stmtRep->fetch(PDO::FETCH_ASSOC)) {
                $engine->validateRecord('AgentApartmentReading', 'electricity_meter_readings', $report_id, $insertedReport, $submitted_by);
            }
            // ──────────────────────────────────────────────────────────────────

            $logStmt = $this->db->prepare("INSERT INTO activity_logs (user_id, action, entity_type, entity_id, details) VALUES (?, 'Electricity Reading', 'Apartment', ?, ?)");
            $logStmt->execute([$submitted_by, $apartment_id, "Submitted fixed monthly payment confirmation"]);


            echo json_encode([
                'success'     => true,
                'type'        => 'fixed',
                'bill_amount' => $bill_amount,
                'message'     => 'Fixed payment confirmation submitted for admin approval.'
            ]);
            return;
        }

        // ═══════════════════════════════════════════════════════════════════════
        // METERED SUBSCRIPTION FLOW
        // Agent provides kWh reading + mandatory photo.
        // ═══════════════════════════════════════════════════════════════════════
        $current_reading = $_POST['current_reading'] ?? null;

        if (!$current_reading) {
            http_response_code(400);
            echo json_encode(['error' => 'Current reading is required for metered subscriptions']);
            return;
        }

        if (!$photoPath) {
            http_response_code(400);
            echo json_encode(['error' => 'Electricity Meter Photo is required for metered readings']);
            return;
        }

        // ─── 7-Day Cooldown (metered only) ────────────────────────────────────
        $cooldownStmt = $this->db->prepare("
            SELECT reading_date, DATEDIFF(CURDATE(), reading_date) as days_ago
            FROM electricity_meter_readings
            WHERE apartment_id = ?
            ORDER BY reading_date DESC, id DESC
            LIMIT 1
        ");
        $cooldownStmt->execute([$apartment_id]);
        $lastReading = $cooldownStmt->fetch(PDO::FETCH_ASSOC);

        if ($lastReading && (int)$lastReading['days_ago'] < 7) {
            $daysLeft = 7 - (int)$lastReading['days_ago'];
            http_response_code(429);
            echo json_encode([
                'error'             => 'cooldown',
                'message'           => "A reading was already submitted on {$lastReading['reading_date']}. You can submit the next reading in {$daysLeft} day(s).",
                'last_reading_date' => $lastReading['reading_date'],
                'days_left'         => $daysLeft
            ]);
            return;
        }
        // ──────────────────────────────────────────────────────────────────────

        // Get previous reading & price
        $prevStmt = $this->db->prepare("SELECT current_reading, price_per_kwh FROM electricity_meter_readings WHERE apartment_id = ? ORDER BY reading_date DESC LIMIT 1");
        $prevStmt->execute([$apartment_id]);
        $prev = $prevStmt->fetch();

        $previous_reading = $prev ? $prev['current_reading'] : 0;
        $price_per_kwh    = $prev ? $prev['price_per_kwh']   : 0;

        if ($price_per_kwh == 0) {
            $ppkStmt = $this->db->prepare("
                SELECT g.price_per_kw FROM generators g
                JOIN apartments a ON g.building_id = a.building_id
                WHERE a.id = ? LIMIT 1
            ");
            $ppkStmt->execute([$apartment_id]);
            $price_per_kwh = $ppkStmt->fetchColumn() ?: 0;
        }

        $consumption = max(0, $current_reading - $previous_reading);
        $bill_amount = $consumption * $price_per_kwh;

        $stmt = $this->db->prepare("
            INSERT INTO electricity_meter_readings
                (apartment_id, previous_reading, current_reading, consumption,
                 price_per_kwh, bill_amount, reading_date, photo_path, notes,
                 status, submitted_at, billing_month, billing_year, submitted_by)
            VALUES (?, ?, ?, ?, ?, ?, CURDATE(), ?, ?, 'Pending', NOW(), MONTH(CURDATE()), YEAR(CURDATE()), ?)
        ");
        $stmt->execute([
            $apartment_id, $previous_reading, $current_reading,
            $consumption, $price_per_kwh, $bill_amount,
            $photoPath, $notes, $submitted_by
        ]);
        $report_id = $this->db->lastInsertId();

        // ─── Data Quality Scan ────────────────────────────────────────────────
        $engine = new DataQualityEngine();
        $stmtRep = $this->db->prepare("SELECT * FROM electricity_meter_readings WHERE id = ?");
        $stmtRep->execute([$report_id]);
        if ($insertedReport = $stmtRep->fetch(PDO::FETCH_ASSOC)) {
            $engine->validateRecord('AgentApartmentReading', 'electricity_meter_readings', $report_id, $insertedReport, $submitted_by);
        }
        // ──────────────────────────────────────────────────────────────────────

        $logStmt = $this->db->prepare("INSERT INTO activity_logs (user_id, action, entity_type, entity_id, details) VALUES (?, 'Electricity Reading', 'Apartment', ?, ?)");
        $logStmt->execute([$submitted_by, $apartment_id, "Submitted meter reading (Consumption: {$consumption} kWh)"]);
        echo json_encode([
            'success'     => true,
            'type'        => 'metered',
            'consumption' => $consumption,
            'bill_amount' => $bill_amount,
            'message'     => 'Meter reading submitted for admin review.'
        ]);
    }


    public function agentReports() {
        AuthMiddleware::requireLogin();
        try {
            $startDate = $_GET['start_date'] ?? date('Y-m-d');
            $endDate = $_GET['end_date'] ?? date('Y-m-d');

            // Find all agent workers
            $stmtWorkers = $this->db->prepare("SELECT id, name FROM users WHERE role = 'agent'");
            $stmtWorkers->execute();
            $agents = $stmtWorkers->fetchAll(PDO::FETCH_ASSOC);

            // Fetch tasks for each agent
            foreach ($agents as &$agent) {
                $agentId = $agent['id'];
                
                // Generator reports
                $stmtGen = $this->db->prepare("
                    SELECT r.*, 'Generator Reading' as task_type, r.submitted_at as submission_date, CONCAT(b.name, ' - ', g.name) as location_info
                    FROM generator_daily_reports r
                    JOIN generators g ON r.generator_id = g.id
                    JOIN buildings b ON g.building_id = b.id
                    WHERE r.submitted_by = ? AND DATE(r.submitted_at) BETWEEN ? AND ?
                ");
                $stmtGen->execute([$agentId, $startDate, $endDate]);
                $genTasks = $stmtGen->fetchAll(PDO::FETCH_ASSOC);

                // Electricity meter readings
                $stmtElec = $this->db->prepare("
                    SELECT r.*, 'Electricity Meter Reading' as task_type, r.submitted_at as submission_date, CONCAT(b.name, ' - Apt ', a.code) as location_info
                    FROM electricity_meter_readings r
                    JOIN apartments a ON r.apartment_id = a.id
                    JOIN buildings b ON a.building_id = b.id
                    WHERE r.submitted_by = ? AND DATE(r.submitted_at) BETWEEN ? AND ?
                ");
                $stmtElec->execute([$agentId, $startDate, $endDate]);
                $elecTasks = $stmtElec->fetchAll(PDO::FETCH_ASSOC);

                // Subscription meter readings
                $stmtSub = $this->db->prepare("
                    SELECT r.*, 'Subscription Meter Reading' as task_type, r.created_at as submission_date, CONCAT(r.building_name, ' - Apt ', r.apartment_code) as location_info
                    FROM agent_subscription_readings r
                    WHERE r.submitted_by = ? AND DATE(r.created_at) BETWEEN ? AND ?
                ");
                $stmtSub->execute([$agentId, $startDate, $endDate]);
                $subTasks = $stmtSub->fetchAll(PDO::FETCH_ASSOC);

                $allTasks = array_merge($genTasks, $elecTasks, $subTasks);
                
                // Sort tasks by date desc
                usort($allTasks, function($a, $b) {
                    return strtotime($b['submission_date']) - strtotime($a['submission_date']);
                });

                $agent['tasks'] = $allTasks;
                $agent['tasks_count'] = count($allTasks);
            }

            echo json_encode($agents);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    // ─── Agent Apartment Purchase Methods ─────────────────────────────────────

    /**
     * Get all buildings + apartments for the agent to submit purchases for,
     * plus the agent's own purchase submission history.
     */
    public function getApartmentPurchaseTasks() {
        $user = AuthMiddleware::requireLogin();
        try {
            $userId = $_GET['user_id'] ?? $user['user_id'] ?? 1;
            $isAdmin = in_array(strtolower($user['role'] ?? ''), ['admin', 'super_admin', 'manager']);

            $statusCheck = $this->db->query("SHOW COLUMNS FROM apartment_cost_deployments LIKE 'status'");
            $hasStatus = $statusCheck->fetch();

            if ($isAdmin) {
                if ($hasStatus) {
                    $histStmt = $this->db->prepare("
                        SELECT acd.*, a.code as apartment_code, b.name as building_name,
                               u.name as reviewer_name, submitter.name as submitter_name
                        FROM apartment_cost_deployments acd
                        JOIN apartments a ON acd.apartment_id = a.id
                        JOIN buildings b ON a.building_id = b.id
                        LEFT JOIN users u ON acd.reviewed_by = u.id
                        LEFT JOIN users submitter ON acd.submitted_by = submitter.id
                        WHERE acd.submitted_by IS NOT NULL
                        ORDER BY acd.created_at DESC
                        LIMIT 300
                    ");
                } else {
                    $histStmt = $this->db->prepare("
                        SELECT acd.*, a.code as apartment_code, b.name as building_name,
                               'Accepted' as status, NULL as reviewer_name, NULL as submitter_name
                        FROM apartment_cost_deployments acd
                        JOIN apartments a ON acd.apartment_id = a.id
                        JOIN buildings b ON a.building_id = b.id
                        WHERE acd.apartment_id IS NOT NULL
                        ORDER BY acd.date DESC
                        LIMIT 150
                    ");
                }
                $histStmt->execute();
            } else {
                if ($hasStatus) {
                    $histStmt = $this->db->prepare("
                        SELECT acd.*, a.code as apartment_code, b.name as building_name,
                               u.name as reviewer_name, NULL as submitter_name
                        FROM apartment_cost_deployments acd
                        JOIN apartments a ON acd.apartment_id = a.id
                        JOIN buildings b ON a.building_id = b.id
                        LEFT JOIN users u ON acd.reviewed_by = u.id
                        WHERE acd.submitted_by = ?
                        ORDER BY acd.created_at DESC
                        LIMIT 100
                    ");
                } else {
                    $histStmt = $this->db->prepare("
                        SELECT acd.*, a.code as apartment_code, b.name as building_name,
                               'Accepted' as status, NULL as reviewer_name, NULL as submitter_name
                        FROM apartment_cost_deployments acd
                        JOIN apartments a ON acd.apartment_id = a.id
                        JOIN buildings b ON a.building_id = b.id
                        WHERE acd.apartment_id IS NOT NULL
                        ORDER BY acd.date DESC
                        LIMIT 50
                    ");
                }
                $histStmt->execute([$userId]);
            }
            $history = $histStmt->fetchAll(PDO::FETCH_ASSOC);

            echo json_encode([
                'history'   => $history,
            ]);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    /**
     * Agent submits an apartment purchase (cost deployment).
     * Requires: apartment_id, supplier_name, amount, date, notes + receipt image.
     */
    public function storeApartmentPurchase() {
        AuthMiddleware::requireLogin();

        $apartment_id  = $_POST['apartment_id']  ?? null;
        $supplier_name = $_POST['supplier_name']  ?? '';
        $amount        = $_POST['amount']         ?? null;
        $date          = $_POST['date']           ?? date('Y-m-d');
        $notes         = $_POST['notes']          ?? '';
        $submitted_by  = $this->getUserId();

        if (!$apartment_id || !$amount) {
            http_response_code(400);
            echo json_encode(['error' => 'apartment_id and amount are required']);
            return;
        }

        // Handle receipt image upload (mandatory for agent submissions)
        $uploadDir = __DIR__ . '/../uploads/receipts/agent/';
        if (!is_dir($uploadDir)) {
            mkdir($uploadDir, 0777, true);
        }

        $receiptPath = null;
        if (isset($_FILES['receipt_image']) && $_FILES['receipt_image']['error'] === UPLOAD_ERR_OK) {
            $fileInfo  = pathinfo($_FILES['receipt_image']['name']);
            $extension = strtolower($fileInfo['extension']);
            $allowed   = ['jpg', 'jpeg', 'png', 'webp', 'pdf'];
            if (!in_array($extension, $allowed)) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid file type. Allowed: jpg, jpeg, png, webp, pdf']);
                return;
            }
            $filename = uniqid('agent_purchase_') . '.' . $extension;
            if (move_uploaded_file($_FILES['receipt_image']['tmp_name'], $uploadDir . $filename)) {
                $receiptPath = 'uploads/receipts/agent/' . $filename;
            }
        } else {
            http_response_code(400);
            echo json_encode(['error' => 'Receipt image is required as proof of purchase']);
            return;
        }

        try {
            // Check if status column exists
            $statusCheck = $this->db->query("SHOW COLUMNS FROM apartment_cost_deployments LIKE 'status'");
            $hasStatus = $statusCheck->fetch();

            if ($hasStatus) {
                // Check for an existing rejected submission for the same apartment/date
                $existStmt = $this->db->prepare("
                    SELECT id FROM apartment_cost_deployments
                    WHERE apartment_id = ? AND submitted_by = ? AND status = 'Rejected'
                      AND date = ? AND supplier_name = ?
                    ORDER BY created_at DESC LIMIT 1
                ");
                $existStmt->execute([$apartment_id, $submitted_by, $date, $supplier_name]);
                $existing = $existStmt->fetchColumn();

                if ($existing) {
                    // Re-submit rejected entry
                    $upd = $this->db->prepare("
                        UPDATE apartment_cost_deployments
                        SET amount = ?, notes = ?, receipt_image = ?,
                            status = 'Pending', rejection_reason = NULL,
                            reviewed_by = NULL, reviewed_at = NULL,
                            created_at = NOW()
                        WHERE id = ?
                    ");
                    $upd->execute([$amount, $notes, $receiptPath, $existing]);
                    echo json_encode(['success' => true, 'message' => 'Purchase resubmitted for review.']);
                    return;
                }

                $stmt = $this->db->prepare("
                    INSERT INTO apartment_cost_deployments
                        (apartment_id, supplier_name, amount, receipt_image, notes, date, status, submitted_by, created_at)
                    VALUES (?, ?, ?, ?, ?, ?, 'Pending', ?, NOW())
                ");
                $stmt->execute([$apartment_id, $supplier_name, $amount, $receiptPath, $notes, $date, $submitted_by]);
            } else {
                // Fallback: insert without status column (migration not run yet)
                $stmt = $this->db->prepare("
                    INSERT INTO apartment_cost_deployments
                        (apartment_id, supplier_name, amount, receipt_image, notes, date)
                    VALUES (?, ?, ?, ?, ?, ?)
                ");
                $stmt->execute([$apartment_id, $supplier_name, $amount, $receiptPath, $notes, $date]);
            }

            // Get building/apartment info for the notification
            $infoStmt = $this->db->prepare("
                SELECT a.code as apartment_code, b.name as building_name
                FROM apartments a JOIN buildings b ON a.building_id = b.id
                WHERE a.id = ? LIMIT 1
            ");
            $infoStmt->execute([$apartment_id]);
            $info = $infoStmt->fetch(PDO::FETCH_ASSOC);

            // Notify admins
            try {
                $adminsStmt = $this->db->query("SELECT id FROM users WHERE role IN ('admin', 'super_admin') LIMIT 5");
                $admins = $adminsStmt->fetchAll(PDO::FETCH_COLUMN);
                foreach ($admins as $adminId) {
                    $notifMsg = "Agent submitted a purchase of \${$amount} for {$info['building_name']} - Apt {$info['apartment_code']}. Please review.";
                    $notifStmt = $this->db->prepare("
                        INSERT INTO notifications (user_id, title, message, type, seen_by_agent)
                        VALUES (?, 'New Purchase Submission 🛒', ?, 'agent_purchase_pending', 0)
                    ");
                    $notifStmt->execute([$adminId, $notifMsg]);
                }
            } catch (Exception $ne) {
                // Notification failure is non-fatal
            }

            echo json_encode(['success' => true, 'message' => 'Purchase submitted for admin review.']);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    /**
     * Get all pending agent apartment purchase submissions (for admin review).
     */
    public function getPendingApartmentPurchases() {
        AuthMiddleware::requireLogin();
        try {
            // Check if status column exists
            $statusCheck = $this->db->query("SHOW COLUMNS FROM apartment_cost_deployments LIKE 'status'");
            $hasStatus = $statusCheck->fetch();

            if (!$hasStatus) {
                echo json_encode([]);
                return;
            }

            $stmt = $this->db->query("
                SELECT acd.*,
                       a.code as apartment_code, b.name as building_name,
                       u.name as submitter_name
                FROM apartment_cost_deployments acd
                JOIN apartments a ON acd.apartment_id = a.id
                JOIN buildings b ON a.building_id = b.id
                LEFT JOIN users u ON acd.submitted_by = u.id
                WHERE acd.status = 'Pending' AND acd.submitted_by IS NOT NULL
                ORDER BY acd.created_at DESC
            ");
            echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    /**
     * Admin accepts or rejects an agent apartment purchase submission.
     */
    public function verifyApartmentPurchase($purchase_id) {
        AuthMiddleware::requireLogin();
        try {
            $data            = json_decode(file_get_contents('php://input'), true);
            $status          = $data['status']           ?? null; // 'Accepted' or 'Rejected'
            $rejectionReason = $data['rejection_reason'] ?? null;
            $adminId         = $data['user_id']          ?? 1;

            if (!in_array($status, ['Accepted', 'Rejected'])) {
                http_response_code(400);
                echo json_encode(['error' => 'Status must be Accepted or Rejected']);
                return;
            }

            // Fetch the purchase details
            $purchaseStmt = $this->db->prepare("
                SELECT acd.*, a.code as apartment_code, b.name as building_name
                FROM apartment_cost_deployments acd
                JOIN apartments a ON acd.apartment_id = a.id
                JOIN buildings b ON a.building_id = b.id
                WHERE acd.id = ?
            ");
            $purchaseStmt->execute([$purchase_id]);
            $purchase = $purchaseStmt->fetch(PDO::FETCH_ASSOC);

            if (!$purchase) {
                http_response_code(404);
                echo json_encode(['error' => 'Purchase not found']);
                return;
            }

            // Update status
            $updStmt = $this->db->prepare("
                UPDATE apartment_cost_deployments
                SET status = ?, rejection_reason = ?, reviewed_by = ?, reviewed_at = NOW()
                WHERE id = ?
            ");
            $updStmt->execute([$status, $rejectionReason, $adminId, $purchase_id]);

            // Notify the agent
            if ($purchase['submitted_by']) {
                if ($status === 'Accepted') {
                    $notifMsg = "Your purchase of \${$purchase['amount']} for {$purchase['building_name']} - Apt {$purchase['apartment_code']} has been ACCEPTED and recorded.";
                    $notifType  = 'agent_purchase_accepted';
                    $notifTitle = 'Purchase Accepted ✅';
                } else {
                    $reason     = $rejectionReason ?: 'Please resubmit with correct information.';
                    $notifMsg   = "Your purchase submission for {$purchase['building_name']} - Apt {$purchase['apartment_code']} was REJECTED. Reason: {$reason}";
                    $notifType  = 'agent_purchase_rejected';
                    $notifTitle = 'Purchase Rejected ❌';
                }

                $notifStmt = $this->db->prepare("
                    INSERT INTO notifications (user_id, title, message, type, reference_id, seen_by_agent)
                    VALUES (?, ?, ?, ?, ?, 0)
                ");
                $notifStmt->execute([$purchase['submitted_by'], $notifTitle, $notifMsg, $notifType, $purchase_id]);
            }

            echo json_encode(['success' => true, 'message' => "Purchase {$status} successfully."]);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function getSmartTasks() {
        AuthMiddleware::requireLogin();
        $tasks = [];
        
        // 0. Generator Logs (Buildings needing report today or have a rejected report)
        $genStmt = $this->db->query("
            SELECT g.id, g.name, b.id as building_id, b.name as building_name 
            FROM generators g
            JOIN buildings b ON g.building_id = b.id
            WHERE NOT EXISTS (
                SELECT 1 FROM generator_daily_reports gdr 
                WHERE gdr.generator_id = g.id AND gdr.date = CURDATE() AND gdr.status != 'Rejected'
            )
        ");
        while ($row = $genStmt->fetch(PDO::FETCH_ASSOC)) {
            $tasks[] = [
                'id' => 'gen_log_' . $row['id'],
                'task_tag' => 'DAILY GENERATOR CHECK',
                'title' => $row['name'] . ' (' . $row['building_name'] . ')',
                'description' => "Required submission between 7:00 AM and 11:59 PM.",
                'action_text' => 'Tap to log daily generator status',
                'status' => 'pending',
                'action_type' => 'GENERATOR_LOG',
                'entity_id' => $row['id']
            ];
        }

        // 1. Expiring Contracts (High Priority)
        $contractsStmt = $this->db->query("
            SELECT c.id, c.end_date, t.full_name as tenant_name, a.code as apartment_code, b.name as building_name
            FROM contracts c
            JOIN tenants t ON c.tenant_id = t.id
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE c.status = 'Active' AND c.end_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 15 DAY)
        ");
        while ($row = $contractsStmt->fetch(PDO::FETCH_ASSOC)) {
            $tasks[] = [
                'id' => 'contract_' . $row['id'],
                'task_tag' => 'EXPIRING CONTRACT',
                'title' => $row['building_name'] . ' - Apt ' . $row['apartment_code'],
                'description' => "Contact Tenant {$row['tenant_name']}. Contract expires on {$row['end_date']}.",
                'action_text' => 'Tap to view contract details',
                'status' => 'pending',
                'action_type' => 'EXPIRING_CONTRACT',
                'entity_id' => $row['id']
            ];
        }

        // 2. Upcoming Subscription Expiries (Based on next_billing_date like getSubscriptionTasks)
        $subsStmt = $this->db->prepare("
            SELECT es.id, es.next_billing_date, es.end_date, es.type, es.monthly_fee, es.last_meter_reading, a.code as apartment_code, b.name as building_name, t.full_name as tenant_name,
                   (SELECT status FROM agent_subscription_readings WHERE subscription_id = es.id ORDER BY created_at DESC LIMIT 1) as latest_status,
                   DATEDIFF(es.next_billing_date, CURDATE()) as days_until_expiry
            FROM electricity_subscriptions es
            JOIN apartments a ON es.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            LEFT JOIN contracts c ON a.id = c.apartment_id AND c.status = 'Active'
            LEFT JOIN tenants t ON c.tenant_id = t.id
            WHERE es.status = 'Active' 
            AND es.next_billing_date IS NOT NULL 
            AND es.next_billing_date <= ?
        ");
        $subsStmt->execute([date('Y-m-d', strtotime('+30 days'))]);
        
        while ($row = $subsStmt->fetch(PDO::FETCH_ASSOC)) {
            // Only show if not pending review
            if ($row['latest_status'] === 'Pending') continue;
            
            $tasks[] = [
                'id' => 'sub_' . $row['id'],
                'task_tag' => 'SUBSCRIPTION REVIEW',
                'title' => $row['building_name'] . ' - Apt ' . $row['apartment_code'],
                'description' => "Billing due on {$row['next_billing_date']}. Tenant: " . ($row['tenant_name'] ?: 'None'),
                'action_text' => 'Tap to review subscription',
                'status' => 'pending',
                'action_type' => 'SUBSCRIPTION_REVIEW',
                'entity_id' => $row['id'],
                // Include extras needed by the modal
                'building_name' => $row['building_name'],
                'apartment_code' => $row['apartment_code'],
                'tenant_name' => $row['tenant_name'],
                'subscription_type' => $row['type'],
                'monthly_fee' => $row['monthly_fee'],
                'previous_reading' => $row['last_meter_reading'],
                'days_until_expiry' => $row['days_until_expiry']
            ];
        }

        // 3. Monthly Meter Cycles (If between 25th and 5th of next month)
        $day = (int)date('d');
        if ($day >= 25 || $day <= 5) {
            $buildingsStmt = $this->db->query("SELECT id, name FROM buildings");
            while ($b = $buildingsStmt->fetch(PDO::FETCH_ASSOC)) {
                $tasks[] = [
                    'id' => 'meter_cycle_' . $b['id'],
                    'task_tag' => 'METER CYCLE',
                    'title' => $b['name'],
                    'description' => "Submit monthly electricity meter readings for this building.",
                    'action_text' => 'Tap to start meter readings',
                    'status' => 'pending',
                    'action_type' => 'METER_READING',
                    'entity_id' => $b['id']
                ];
            }
        }

        // 4. Pending Collections (Unpaid Rent Invoices)
        $collectionsStmt = $this->db->query("
            SELECT b.id, b.name, COUNT(ri.id) as unpaid_count, SUM(ri.amount) as total_due, GROUP_CONCAT(DISTINCT a.code ORDER BY a.code ASC SEPARATOR ', ') as apartments_list
            FROM rent_invoices ri
            JOIN contracts c ON ri.contract_id = c.id
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE ri.status != 'Paid'
            GROUP BY b.id, b.name
            HAVING unpaid_count > 0
        ");
        while ($row = $collectionsStmt->fetch(PDO::FETCH_ASSOC)) {
            $tasks[] = [
                'id' => 'collection_' . $row['id'],
                'task_tag' => 'RENT COLLECTION',
                'title' => $row['name'],
                'unpaid_count' => $row['unpaid_count'],
                'total_due' => $row['total_due'],
                'apartments_list' => $row['apartments_list'],
                'action_text' => 'Tap to start collections',
                'status' => 'pending',
                'action_type' => 'RENT_COLLECTION',
                'entity_id' => $row['id']
            ];
        }

        // 5. Pending Electricity Collections (Unpaid Electricity Invoices)
        $elecStmt = $this->db->query("
            SELECT b.id, b.name, COUNT(ei.id) as unpaid_count, SUM(ei.amount - COALESCE(ei.amount_paid, 0)) as total_due, GROUP_CONCAT(DISTINCT a.code ORDER BY a.code ASC SEPARATOR ', ') as apartments_list
            FROM electricity_invoices ei
            JOIN apartments a ON ei.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE ei.status != 'Paid'
            GROUP BY b.id, b.name
            HAVING unpaid_count > 0
        ");
        while ($row = $elecStmt->fetch(PDO::FETCH_ASSOC)) {
            $tasks[] = [
                'id' => 'elec_collection_' . $row['id'],
                'task_tag' => 'ELECTRICITY COLLECTION',
                'title' => $row['name'],
                'unpaid_count' => $row['unpaid_count'],
                'total_due' => $row['total_due'],
                'apartments_list' => $row['apartments_list'],
                'action_text' => 'Tap to start collections',
                'status' => 'pending',
                'action_type' => 'ELECTRICITY_COLLECTION',
                'entity_id' => $row['id']
            ];
        }

        echo json_encode(['success' => true, 'tasks' => $tasks]);
    }

    public function quickEditReading() {
        AuthMiddleware::requireLogin();
        
        $type = $_POST['type'] ?? ''; // 'generator' or 'meter'
        $id = $_POST['id'] ?? null;
        
        if (!$id || !in_array($type, ['generator', 'meter'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Invalid parameters']);
            return;
        }

        $table = ($type === 'generator') ? 'generator_daily_reports' : 'electricity_meter_readings';
        $statusField = ($type === 'generator') ? 'status' : 'status'; // Both have status field

        // Check if within 15 minutes and not verified
        $checkStmt = $this->db->prepare("
            SELECT id FROM {$table} 
            WHERE id = ? 
            AND status = 'Pending Verification'
            AND TIMESTAMPDIFF(MINUTE, created_at, NOW()) <= 15
        ");
        $checkStmt->execute([$id]);
        if (!$checkStmt->fetch()) {
            http_response_code(403);
            echo json_encode(['error' => 'Edit window expired or report already verified. Please submit a Correction Request.']);
            return;
        }

        if ($type === 'generator') {
            $running_hours = $_POST['running_hours'] ?? null;
            $current_kwh = $_POST['current_kwh'] ?? null;
            $fuel_added = $_POST['fuel_added'] ?? null;
            
            $update = $this->db->prepare("UPDATE generator_daily_reports SET running_hours = COALESCE(?, running_hours), current_kwh = COALESCE(?, current_kwh), fuel_added = COALESCE(?, fuel_added) WHERE id = ?");
            $update->execute([$running_hours, $current_kwh, $fuel_added, $id]);
        } else {
            $current_reading = $_POST['current_reading'] ?? null;
            if ($current_reading) {
                // Fetch previous reading to update consumption
                $prevStmt = $this->db->prepare("SELECT previous_reading, price_per_kwh FROM electricity_meter_readings WHERE id = ?");
                $prevStmt->execute([$id]);
                $r = $prevStmt->fetch(PDO::FETCH_ASSOC);
                
                $consumption = max(0, $current_reading - $r['previous_reading']);
                $bill = $consumption * $r['price_per_kwh'];
                
                $update = $this->db->prepare("UPDATE electricity_meter_readings SET current_reading = ?, consumption = ?, bill_amount = ? WHERE id = ?");
                $update->execute([$current_reading, $consumption, $bill, $id]);
            }
        }

        echo json_encode(['success' => true, 'message' => 'Reading updated successfully.']);
    }

    public function requestCorrection() {
        AuthMiddleware::requireLogin();
        
        $type = $_POST['type'] ?? '';
        $entity_id = $_POST['entity_id'] ?? null;
        $proposed_value = $_POST['proposed_value'] ?? null;
        $notes = $_POST['notes'] ?? '';
        $submitted_by = $this->getUserId();
        
        if (!in_array($type, ['generator_reading', 'electricity_reading']) || !$entity_id || $proposed_value === null) {
            http_response_code(400);
            echo json_encode(['error' => 'Missing required fields']);
            return;
        }

        $photoPath = null;
        $uploadDir = __DIR__ . '/../../uploads/corrections/';
        if (!is_dir($uploadDir)) {
            mkdir($uploadDir, 0777, true);
        }
        if (isset($_FILES['photo']) && $_FILES['photo']['error'] === 0) {
            $filename = time() . '_' . basename($_FILES['photo']['name']);
            if (move_uploaded_file($_FILES['photo']['tmp_name'], $uploadDir . $filename)) {
                $photoPath = 'uploads/corrections/' . $filename;
            }
        }

        // Fetch original value based on type
        $original_value = null;
        if ($type === 'generator_reading') {
            $stmt = $this->db->prepare("SELECT current_kwh FROM generator_daily_reports WHERE id = ?");
            $stmt->execute([$entity_id]);
            $original_value = $stmt->fetchColumn();
        } else {
            $stmt = $this->db->prepare("SELECT current_reading FROM electricity_meter_readings WHERE id = ?");
            $stmt->execute([$entity_id]);
            $original_value = $stmt->fetchColumn();
        }

        $insert = $this->db->prepare("
            INSERT INTO correction_requests (type, entity_id, original_value, proposed_value, notes, photo_path, submitted_by)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ");
        $insert->execute([$type, $entity_id, $original_value, $proposed_value, $notes, $photoPath, $submitted_by]);

        echo json_encode(['success' => true, 'message' => 'Correction request submitted to admin for approval.']);
    }

    public function getAgentPurchases() {
        AuthMiddleware::requireLogin();
        $user_id = $this->getUserId();
        $dateFilter = $_GET['date'] ?? null;
        $user = $_SESSION['user'] ?? null;
        $role = strtolower($user['role'] ?? '');
        $isAdmin = ($role === 'admin' || $role === 'superadmin' || isset($_GET['all']));

        $this->db->exec("CREATE TABLE IF NOT EXISTS agent_purchases (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL,
            building_name VARCHAR(100) DEFAULT 'Galaxy',
            apartment_number VARCHAR(50) DEFAULT 'A1',
            supplier VARCHAR(100) NOT NULL,
            amount VARCHAR(50) NOT NULL,
            items VARCHAR(255) DEFAULT 'General Material',
            notes TEXT,
            status VARCHAR(50) DEFAULT 'Pending Review',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )");

        if ($isAdmin) {
            if (!empty($dateFilter) && $dateFilter !== 'all') {
                $stmt = $this->db->prepare("
                    SELECT p.*, u.name as submitter_name 
                    FROM agent_purchases p 
                    LEFT JOIN users u ON p.user_id = u.id 
                    WHERE DATE(p.created_at) = ? 
                    ORDER BY p.created_at DESC
                ");
                $stmt->execute([$dateFilter]);
            } else {
                $stmt = $this->db->query("
                    SELECT p.*, u.name as submitter_name 
                    FROM agent_purchases p 
                    LEFT JOIN users u ON p.user_id = u.id 
                    ORDER BY p.created_at DESC
                ");
            }
        } else {
            if (!empty($dateFilter) && $dateFilter !== 'all') {
                $stmt = $this->db->prepare("SELECT * FROM agent_purchases WHERE user_id = ? AND DATE(created_at) = ? ORDER BY created_at DESC");
                $stmt->execute([$user_id, $dateFilter]);
            } else {
                $stmt = $this->db->prepare("SELECT * FROM agent_purchases WHERE user_id = ? ORDER BY created_at DESC");
                $stmt->execute([$user_id]);
            }
        }

        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        echo json_encode($rows);
    }

    public function approveAgentPurchase($id) {
        AuthMiddleware::requireLogin();
        $stmt = $this->db->prepare("UPDATE agent_purchases SET status = 'Approved' WHERE id = ?");
        $stmt->execute([$id]);
        echo json_encode(['success' => true, 'message' => 'Purchase approved successfully.']);
    }

    public function rejectAgentPurchase($id) {
        AuthMiddleware::requireLogin();
        $stmt = $this->db->prepare("UPDATE agent_purchases SET status = 'Rejected' WHERE id = ?");
        $stmt->execute([$id]);
        echo json_encode(['success' => true, 'message' => 'Purchase rejected successfully.']);
    }

    public function storeAgentPurchase() {
        AuthMiddleware::requireLogin();
        $user_id = $this->getUserId();
        
        $json = json_decode(file_get_contents("php://input"), true) ?? [];
        $data = array_merge($_POST, $json);

        $building = !empty($data['building']) ? trim($data['building']) : (!empty($data['building_name']) ? trim($data['building_name']) : 'Galaxy');
        $apartment = !empty($data['apartment']) ? trim($data['apartment']) : (!empty($data['apartment_number']) ? trim($data['apartment_number']) : 'A1');
        $supplier = !empty($data['supplier']) ? trim($data['supplier']) : 'Hardware Store';
        
        $rawAmount = $data['amount'] ?? '0';
        $numericAmount = floatval(preg_replace('/[^0-9.]/', '', $rawAmount));
        if (!str_contains(strtolower($rawAmount), 'cfa') && !str_contains($rawAmount, '$')) {
            $amount = 'CFA ' . number_format($numericAmount, 0);
        } else {
            $amount = $rawAmount;
        }

        $items = !empty($data['items']) ? trim($data['items']) : 'General Material';
        $notes = $data['notes'] ?? '';
        $fullNotes = $items ? "Items: {$items} • " . $notes : $notes;

        // 1. Insert into agent_purchases
        $this->db->exec("CREATE TABLE IF NOT EXISTS agent_purchases (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL,
            building_name VARCHAR(100) DEFAULT 'Galaxy',
            apartment_number VARCHAR(50) DEFAULT 'A1',
            supplier VARCHAR(100) NOT NULL,
            amount VARCHAR(50) NOT NULL,
            items VARCHAR(255) DEFAULT 'General Material',
            notes TEXT,
            status VARCHAR(50) DEFAULT 'Pending Review',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )");

        $stmt = $this->db->prepare("INSERT INTO agent_purchases (user_id, building_name, apartment_number, supplier, amount, items, notes, status) VALUES (?, ?, ?, ?, ?, ?, ?, 'Pending Review')");
        $stmt->execute([$user_id, $building, $apartment, $supplier, $amount, $items, $notes]);
        $insertId = $this->db->lastInsertId();

        // 2. Find matching apartment_id in database & insert into apartment_cost_deployments
        $aptStmt = $this->db->prepare("
            SELECT a.id 
            FROM apartments a 
            JOIN buildings b ON a.building_id = b.id 
            WHERE (b.name LIKE ? OR b.name LIKE ?) 
              AND (a.code LIKE ? OR a.code LIKE ?) 
            LIMIT 1
        ");
        $aptStmt->execute(["%$building%", "$building%", "%$apartment%", "$apartment%"]);
        $aptId = $aptStmt->fetchColumn();

        if (!$aptId) {
            $aptStmt2 = $this->db->prepare("SELECT id FROM apartments WHERE code LIKE ? LIMIT 1");
            $aptStmt2->execute(["%$apartment%"]);
            $aptId = $aptStmt2->fetchColumn();
        }

        if ($aptId) {
            $this->db->exec("CREATE TABLE IF NOT EXISTS apartment_cost_deployments (
                id INT AUTO_INCREMENT PRIMARY KEY,
                apartment_id INT NOT NULL,
                supplier_name VARCHAR(255),
                amount DECIMAL(15,2),
                receipt_image TEXT,
                notes TEXT,
                date DATE,
                status VARCHAR(50) DEFAULT 'Pending',
                rejection_reason TEXT,
                submitted_by INT,
                reviewed_by INT,
                reviewed_at TIMESTAMP NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )");

            $stmtDep = $this->db->prepare("
                INSERT INTO apartment_cost_deployments (apartment_id, supplier_name, amount, notes, date, status, submitted_by)
                VALUES (?, ?, ?, ?, CURDATE(), 'Pending', ?)
            ");
            $stmtDep->execute([$aptId, $supplier, $numericAmount, $fullNotes, $user_id]);
        }

        $logStmt = $this->db->prepare("INSERT INTO activity_logs (user_id, action, entity_type, entity_id, details) VALUES (?, 'Purchase Submission', 'Purchase', ?, ?)");
        $logStmt->execute([$user_id, $insertId, "Submitted purchase for {$building} Apt {$apartment} ({$amount})"]);

        // Notify admins
        try {
            $adminsStmt = $this->db->query("SELECT id FROM users WHERE role IN ('admin', 'super_admin') LIMIT 5");
            $admins = $adminsStmt->fetchAll(PDO::FETCH_COLUMN);
            foreach ($admins as $adminId) {
                $notifMsg = "Agent submitted a purchase of {$amount} for {$building} - Apt {$apartment}. Please review.";
                $notifStmt = $this->db->prepare("
                    INSERT INTO notifications (user_id, title, message, type, seen_by_agent)
                    VALUES (?, 'New Purchase Submission 🛒', ?, 'agent_purchase_pending', 0)
                ");
                $notifStmt->execute([$adminId, $notifMsg]);
            }
        } catch (Exception $ne) {
            // Notification failure is non-fatal
        }

        echo json_encode(['success' => true, 'id' => $insertId]);
    }
}

