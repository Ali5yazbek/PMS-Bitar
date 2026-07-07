<?php
class AgentController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    private function getUserId() {
        // Normally this would come from AuthMiddleware / decoded JWT or Session
        // For now we get it from request headers or assume auth is passed
        // This system uses localStorage token, AuthMiddleware::getUserId() is not implemented here.
        // We will assume the frontend sends the user_id or we get it from somewhere.
        // Since Bitar PMS doesn't pass user ID explicitly in endpoints usually (admin mostly), 
        // we will fetch all for the agent or try to get it if we can.
        return 1; // Default fallback if needed
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

    // ─── NEW: Subscription Task Methods ───────────────────────────────────────

    /**
     * Get all subscription tasks (apartments with subscriptions expiring in ≤5 days)
     * Returns pending, accepted, and rejected submissions as well.
     */
    public function getSubscriptionTasks() {
        AuthMiddleware::requireLogin();
        try {
            $today = date('Y-m-d');
            $fiveDaysLater = date('Y-m-d', strtotime('+5 days'));

            // Active subscriptions expiring within 5 days
            $stmt = $this->db->prepare("
                SELECT 
                    es.id as subscription_id,
                    es.apartment_id,
                    es.start_date,
                    es.end_date,
                    es.monthly_fee,
                    es.status as subscription_status,
                    a.code as apartment_code,
                    b.id as building_id,
                    b.name as building_name,
                    t.full_name as tenant_name,
                    t.phone as tenant_phone,
                    DATEDIFF(es.end_date, CURDATE()) as days_until_expiry,
                    (SELECT current_reading FROM electricity_meter_readings 
                     WHERE apartment_id = a.id 
                     ORDER BY reading_date DESC, id DESC LIMIT 1) as previous_reading,
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
                AND es.end_date IS NOT NULL
                AND es.end_date >= ?
                AND es.end_date <= ?
                AND (es.amps IS NULL OR es.amps = 0)
                ORDER BY es.end_date ASC, b.name ASC, a.code ASC
            ");
            $stmt->execute([$today, $fiveDaysLater]);
            $tasks = $stmt->fetchAll(PDO::FETCH_ASSOC);

            // Also get all agent submissions (all statuses) for history tabs
            $histStmt = $this->db->prepare("
                SELECT 
                    asr.*,
                    a.code as apartment_code,
                    b.name as building_name,
                    t.full_name as tenant_name,
                    es.start_date as sub_start_date,
                    es.end_date as sub_end_date
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
        $current_reading = $_POST['current_reading'] ?? null;
        $previous_reading = $_POST['previous_reading'] ?? 0;
        $notes = $_POST['notes'] ?? '';
        $submitted_by = $_POST['submitted_by'] ?? 1;

        if (!$apartment_id || !$subscription_id || $current_reading === null) {
            http_response_code(400);
            echo json_encode(['error' => 'Missing required fields: apartment_id, subscription_id, current_reading']);
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
        } else {
            http_response_code(400);
            echo json_encode(['error' => 'Meter photo is required as proof.']);
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
                        submitted_by = ?, created_at = NOW()
                    WHERE id = ?
                ");
                $upd->execute([$previous_reading, $current_reading, $consumption, $notes, $photoPath, $submitted_by, $existing]);
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
                     status, submitted_by, billing_month, billing_year)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'Pending', ?, ?, ?)
                ");
                $ins->execute([
                    $apartment_id, $subscription_id,
                    $info['building_name'] ?? '', $info['apartment_code'] ?? '', $info['tenant_name'] ?? '',
                    $previous_reading, $current_reading, $consumption,
                    $notes, $photoPath, $submitted_by, $month, $year
                ]);
            }

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
                       es.start_date, es.end_date, es.monthly_fee
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

                    // Auto-generate subscription invoice for the new month
                    if ($sub['monthly_fee'] > 0) {
                        $monthStr = date('Y-m', strtotime($newStartDate));
                        $invCheck = $this->db->prepare("SELECT id FROM electricity_invoices WHERE apartment_id = ? AND type IN ('Subscription', 'Fixed Subscription') AND DATE_FORMAT(due_date, '%Y-%m') = ?");
                        $invCheck->execute([$apartmentId, $monthStr]);
                        if (!$invCheck->fetch()) {
                            $invStmt = $this->db->prepare("INSERT INTO electricity_invoices (apartment_id, type, amount, due_date) VALUES (?, 'Subscription', ?, ?)");
                            $invStmt->execute([$apartmentId, $sub['monthly_fee'], $newStartDate]);
                        }
                    }

                    // Also save this as an official electricity_meter_reading record
                    if ($reading['current_reading'] > 0) {
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
                    $notifMsg = "Your meter reading for {$reading['building_name']} - Apt {$reading['apartment_code']} was REJECTED. Reason: {$reason}";
                    $notifStmt = $this->db->prepare("
                        INSERT INTO notifications (user_id, title, message, type, reference_id, seen_by_agent)
                        VALUES (?, 'Meter Reading Rejected ❌', ?, 'agent_reading_rejected', ?, 0)
                    ");
                    $notifStmt->execute([$reading['submitted_by'], $notifMsg, $reading_id]);
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
        
        $building_id = $_POST['building_id'] ?? null;
        if (!$building_id) {
            http_response_code(400);
            echo json_encode(['error' => 'Building ID is required']);
            return;
        }

        // Find generator for this building
        $genStmt = $this->db->prepare("SELECT id, current_fuel FROM generators WHERE building_id = ? LIMIT 1");
        $genStmt->execute([$building_id]);
        $generator = $genStmt->fetch();
        if (!$generator) {
            http_response_code(404);
            echo json_encode(['error' => 'No generator found for this building']);
            return;
        }

        $gen_id = $generator['id'];
        $counter = !empty($_POST['generator_counter']) ? $_POST['generator_counter'] : 0;
        $running_hours = !empty($_POST['running_hours']) ? $_POST['running_hours'] : 0;
        $current_kwh = !empty($_POST['current_kwh']) ? $_POST['current_kwh'] : 0;
        $fuel_added = !empty($_POST['fuel_added']) ? $_POST['fuel_added'] : 0;
        $remaining_fuel = !empty($_POST['remaining_fuel']) ? $_POST['remaining_fuel'] : 0;
        $spare_fuel = !empty($_POST['spare_fuel']) ? $_POST['spare_fuel'] : 0;
        $notes = $_POST['notes'] ?? '';

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

        // Fetch previous kwh
        $prevStmt = $this->db->prepare("SELECT current_kwh FROM generator_daily_reports WHERE generator_id = ? ORDER BY date DESC, created_at DESC LIMIT 1");
        $prevStmt->execute([$gen_id]);
        $prevReport = $prevStmt->fetch(PDO::FETCH_ASSOC);
        $previous_kwh = $prevReport ? floatval($prevReport['current_kwh']) : 0;
        $kwh_produced = max(0, $current_kwh - $previous_kwh);

        $submitted_by = $_POST['submitted_by'] ?? 1;

        $stmt = $this->db->prepare("
            INSERT INTO generator_daily_reports 
            (generator_id, date, fuel_added, fuel_remaining, spare_remaining, running_hours, current_meter_hours, current_kwh, previous_kwh, kwh_produced, notes, photo_meter_path, fuel_photo_path, status, submitted_at, cost_per_liter, submitted_by)
            VALUES (?, CURDATE(), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'Pending Verification', NOW(), 0, ?)
            ON DUPLICATE KEY UPDATE 
            fuel_added = VALUES(fuel_added),
            fuel_remaining = VALUES(fuel_remaining),
            spare_remaining = VALUES(spare_remaining),
            running_hours = VALUES(running_hours),
            current_meter_hours = VALUES(current_meter_hours),
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
            $gen_id, $fuel_added, $remaining_fuel, $spare_fuel, $running_hours, $counter, $current_kwh, $previous_kwh, $kwh_produced, $notes, $meterPhotoPath, $fuelPhotoPath, $submitted_by
        ]);

        echo json_encode(['success' => true]);
    }

    public function storeApartmentReading() {
        AuthMiddleware::requireLogin();
        
        $apartment_id = $_POST['apartment_id'] ?? null;
        $current_reading = $_POST['current_reading'] ?? null;
        $notes = $_POST['notes'] ?? '';
        $submitted_by = $_POST['submitted_by'] ?? 1;

        if (!$apartment_id || !$current_reading) {
            http_response_code(400);
            echo json_encode(['error' => 'Missing required fields']);
            return;
        }

        // Get previous reading
        $prevStmt = $this->db->prepare("SELECT current_reading, price_per_kwh FROM electricity_meter_readings WHERE apartment_id = ? ORDER BY reading_date DESC LIMIT 1");
        $prevStmt->execute([$apartment_id]);
        $prev = $prevStmt->fetch();
        
        $previous_reading = $prev ? $prev['current_reading'] : 0;
        $price_per_kwh = $prev ? $prev['price_per_kwh'] : 0; // In real life might fetch from generator/settings
        
        if ($price_per_kwh == 0) {
            // Get from generators building if possible
            $ppkStmt = $this->db->prepare("
                SELECT g.price_per_kw 
                FROM generators g 
                JOIN apartments a ON g.building_id = a.building_id 
                WHERE a.id = ? LIMIT 1
            ");
            $ppkStmt->execute([$apartment_id]);
            $price_per_kwh = $ppkStmt->fetchColumn() ?: 0;
        }

        $consumption = max(0, $current_reading - $previous_reading);
        $bill_amount = $consumption * $price_per_kwh;

        // Photo
        $uploadDir = __DIR__ . '/../../uploads/electricity-meters/';
        if (!is_dir($uploadDir)) {
            mkdir($uploadDir, 0777, true);
        }

        $photoPath = null;
        if (isset($_FILES['meter_photo']) && $_FILES['meter_photo']['error'] === 0) {
            $filename = time() . '_' . basename($_FILES['meter_photo']['name']);
            if (move_uploaded_file($_FILES['meter_photo']['tmp_name'], $uploadDir . $filename)) {
                $photoPath = 'uploads/electricity-meters/' . $filename;
            }
        } else {
            http_response_code(400);
            echo json_encode(['error' => 'Electricity Meter Photo is required']);
            return;
        }

        $stmt = $this->db->prepare("
            INSERT INTO electricity_meter_readings 
            (apartment_id, previous_reading, current_reading, consumption, price_per_kwh, bill_amount, reading_date, photo_path, notes, status, submitted_at, billing_month, billing_year, submitted_by)
            VALUES (?, ?, ?, ?, ?, ?, CURDATE(), ?, ?, 'Pending', NOW(), MONTH(CURDATE()), YEAR(CURDATE()), ?)
        ");
        
        $stmt->execute([
            $apartment_id, $previous_reading, $current_reading, $consumption, $price_per_kwh, $bill_amount, $photoPath, $notes, $submitted_by
        ]);

        echo json_encode(['success' => true]);
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
}

