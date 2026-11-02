<?php
class ElectricityController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    // --- Subscriptions ---
    public function getSubscriptions() {
        try {
            $stmt = $this->db->query("
                SELECT es.*, a.code as apartment_code, b.name as building_name
                FROM electricity_subscriptions es
                JOIN apartments a ON es.apartment_id = a.id
                JOIN buildings b ON a.building_id = b.id
            ");
            echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function getApartmentSubscription($apartment_id) {
        try {
            $stmt = $this->db->prepare("
                SELECT * FROM electricity_subscriptions 
                WHERE apartment_id = ? LIMIT 1
            ");
            $stmt->execute([$apartment_id]);
            $sub = $stmt->fetch(PDO::FETCH_ASSOC);
            echo json_encode($sub ?: ['status' => 'None']);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function getBuildingSubscriptions($building_id) {
        try {
            // Get all apartments for this building, left join their subscription
            $stmt = $this->db->prepare("
                SELECT a.id as apartment_id, a.code as apartment_code,
                       t.full_name as tenant_name, t.user_id as tenant_user_id,
                       es.id as subscription_id, es.type, es.monthly_fee, es.amps, es.cost_per_amp, es.start_date, es.end_date, es.status as subscription_status, es.price_per_kwh, es.last_meter_reading,
                       (SELECT current_reading FROM electricity_meter_readings WHERE apartment_id = a.id ORDER BY reading_date DESC, id DESC LIMIT 1) as last_reading,
                       (SELECT SUM(amount - amount_paid) FROM electricity_invoices WHERE apartment_id = a.id AND type IN ('Subscription', 'Fixed Subscription', 'Meter') AND status != 'Paid') as unpaid_balance,
                       (SELECT SUM(amount_paid) FROM electricity_invoices WHERE apartment_id = a.id AND type IN ('Subscription', 'Fixed Subscription', 'Meter')) as paid_amount
                FROM apartments a
                LEFT JOIN electricity_subscriptions es ON a.id = es.apartment_id
                LEFT JOIN contracts c ON a.id = c.apartment_id AND c.status IN ('Active', 'Approved')
                LEFT JOIN tenants t ON c.tenant_id = t.id
                WHERE a.building_id = ?
                ORDER BY a.code ASC
            ");
            $stmt->execute([$building_id]);
            echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function renewSubscription($apartment_id) {
        try {
            $this->db->beginTransaction();

            $stmt = $this->db->prepare("SELECT * FROM electricity_subscriptions WHERE apartment_id = ?");
            $stmt->execute([$apartment_id]);
            $sub = $stmt->fetch(PDO::FETCH_ASSOC);

            if (!$sub || $sub['status'] !== 'Active') {
                http_response_code(400);
                echo json_encode(['error' => 'No active subscription found for this apartment.']);
                return;
            }

            $dueDate = $sub['next_billing_date'] ?: date('Y-m-d');
            $monthlyFee = $sub['monthly_fee'];

            // Create new invoice for the renewal month
            $invStmt = $this->db->prepare("
                INSERT INTO electricity_invoices (apartment_id, type, amount, due_date) 
                VALUES (?, 'Subscription', ?, ?)
            ");
            $invStmt->execute([$apartment_id, $monthlyFee, $dueDate]);

            // Advance next_billing_date and end_date by 1 month
            $updStmt = $this->db->prepare("
                UPDATE electricity_subscriptions 
                SET next_billing_date = DATE_ADD(?, INTERVAL 1 MONTH),
                    end_date = CASE WHEN end_date IS NOT NULL THEN DATE_ADD(end_date, INTERVAL 1 MONTH) ELSE end_date END
                WHERE id = ?
            ");
            $updStmt->execute([$dueDate, $sub['id']]);

            $this->db->commit();
            echo json_encode(['message' => 'Subscription renewed successfully. Invoice generated.', 'new_next_billing_date' => date('Y-m-d', strtotime($dueDate . ' + 1 month'))]);
        } catch (PDOException $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function storeSubscription($apartment_id = null) {
        try {
            $data = json_decode(file_get_contents("php://input"), true);
            $apartment_id = $apartment_id ?? $data['apartment_id'];
            
            $amps      = floatval($data['amps'] ?? 0);
            $costPerAmp = floatval($data['cost_per_amp'] ?? 0);
            $monthlyFee = ($amps > 0 && $costPerAmp > 0)
                ? ($amps * $costPerAmp)
                : floatval($data['monthly_fee'] ?? 0);

            $type = $data['type'] ?? 'Meter';

            // RBAC: Agents cannot create subscriptions for Terminated tenants
            $currentUser = AuthMiddleware::requireLogin();
            if (isset($currentUser['role']) && $currentUser['role'] === 'agent') {
                $tStmt = $this->db->prepare("
                    SELECT t.status 
                    FROM contracts c 
                    JOIN tenants t ON c.tenant_id = t.id 
                    WHERE c.apartment_id = ? 
                    ORDER BY c.id DESC LIMIT 1
                ");
                $tStmt->execute([$apartment_id]);
                $tRecord = $tStmt->fetch();
                if ($tRecord && $tRecord['status'] === 'Terminated') {
                    http_response_code(403);
                    echo json_encode(['error' => 'Agents are not authorized to create subscriptions for Terminated tenants.']);
                    return;
                }
            }

            // ─── Auto-compute dates (server-authoritative with client override) ───
            $startDate       = !empty($data['start_date']) ? $data['start_date'] : date('Y-m-d');
            $endDate         = !empty($data['end_date']) ? $data['end_date'] : date('Y-m-d', strtotime($startDate . ' + 30 days'));
            $nextBillingDate = !empty($data['next_billing_date']) ? $data['next_billing_date'] : $endDate;
            // ──────────────────────────────────────────────────────────────────

            $price_per_kwh      = isset($data['price_per_kwh'])      ? floatval($data['price_per_kwh'])      : null;
            $last_meter_reading = isset($data['starting_reading'])   ? floatval($data['starting_reading'])
                                : (isset($data['last_meter_reading']) ? floatval($data['last_meter_reading']) : null);

            $this->db->beginTransaction();

            // Check if a subscription already exists for this apartment
            $checkStmt = $this->db->prepare("SELECT * FROM electricity_subscriptions WHERE apartment_id = ?");
            $checkStmt->execute([$apartment_id]);
            $existing = $checkStmt->fetch(PDO::FETCH_ASSOC);

            if ($existing) {
                // ── UPDATE existing subscription ──────────────────────────────
                $stmt = $this->db->prepare("
                    UPDATE electricity_subscriptions
                    SET type              = ?,
                        monthly_fee       = ?,
                        amps              = ?,
                        cost_per_amp      = ?,
                        start_date        = ?,
                        end_date          = ?,
                        next_billing_date = ?,
                        status            = ?,
                        price_per_kwh     = ?,
                        last_meter_reading = ?
                    WHERE apartment_id = ?
                ");
                $stmt->execute([
                    $type, $monthlyFee, $amps, $costPerAmp,
                    $startDate, $endDate, $nextBillingDate,
                    $data['status'] ?? 'Active',
                    $price_per_kwh, $last_meter_reading,
                    $apartment_id
                ]);
                $subscription_id = $existing['id'];

                // Log history
                $histStmt = $this->db->prepare(
                    "INSERT INTO subscription_history (subscription_id, action, previous_value, new_value, reason, performed_by)
                     VALUES (?, 'Updated', ?, ?, 'Admin Update', ?)"
                );
                $histStmt->execute([
                    $subscription_id,
                    json_encode($existing),
                    json_encode(array_merge($existing, [
                        'type' => $type, 'monthly_fee' => $monthlyFee,
                        'amps' => $amps, 'cost_per_amp' => $costPerAmp,
                        'start_date' => $startDate, 'end_date' => $endDate,
                        'status' => $data['status'] ?? 'Active'
                    ])),
                    $data['user_id'] ?? 1
                ]);
            } else {
                // ── INSERT new subscription ───────────────────────────────────
                $stmt = $this->db->prepare("
                    INSERT INTO electricity_subscriptions
                        (apartment_id, type, monthly_fee, amps, cost_per_amp,
                         start_date, end_date, next_billing_date,
                         status, price_per_kwh, last_meter_reading)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ");
                $stmt->execute([
                    $apartment_id, $type, $monthlyFee, $amps, $costPerAmp,
                    $startDate, $endDate, $nextBillingDate,
                    $data['status'] ?? 'Active',
                    $price_per_kwh, $last_meter_reading
                ]);
                $subscription_id = $this->db->lastInsertId();

                // Log history
                $histStmt = $this->db->prepare(
                    "INSERT INTO subscription_history (subscription_id, action, previous_value, new_value, reason, performed_by)
                     VALUES (?, 'Created', NULL, ?, 'New Subscription', ?)"
                );
                $histStmt->execute([
                    $subscription_id,
                    json_encode(['type' => $type, 'monthly_fee' => $monthlyFee,
                                 'amps' => $amps, 'cost_per_amp' => $costPerAmp,
                                 'start_date' => $startDate, 'end_date' => $endDate,
                                 'status' => $data['status'] ?? 'Active']),
                    $data['user_id'] ?? 1
                ]);
            }

            // ── Baseline or initial meter reading for Meter-type subscriptions ────────────
            if ($type === 'Meter') {
                if (isset($data['starting_reading']) && trim($data['starting_reading']) !== '') {
                    $baselineReading = floatval($data['starting_reading']);
                    $pricePerKwh     = floatval($price_per_kwh ?? 0);

                    // Insert baseline record with consumption = 0 and bill_amount = 0 as verified opening meter
                    $baseStmt = $this->db->prepare("
                        INSERT INTO electricity_meter_readings
                            (apartment_id, previous_reading, current_reading, price_per_kwh,
                             consumption, bill_amount, reading_date, status, submitted_by)
                        VALUES (?, ?, ?, ?, 0, 0, ?, 'Verified', ?)
                    ");
                    $baseStmt->execute([
                        $apartment_id, $baselineReading, $baselineReading, $pricePerKwh,
                        $startDate, $data['user_id'] ?? 1
                    ]);

                    // Update last_meter_reading on subscription record
                    $this->db->prepare("UPDATE electricity_subscriptions SET last_meter_reading = ? WHERE id = ?")
                             ->execute([$baselineReading, $subscription_id]);
                } else if (isset($data['current_reading']) && trim($data['current_reading']) !== '') {
                    $startReading  = floatval($last_meter_reading ?? 0);
                    $currentReading = floatval($data['current_reading']);
                    $pricePerKwh   = floatval($price_per_kwh ?? 0);
                    $consumption   = max(0, $currentReading - $startReading);
                    $billAmount    = $consumption * $pricePerKwh;

                    $meterStmt = $this->db->prepare("
                        INSERT INTO electricity_meter_readings
                            (apartment_id, previous_reading, current_reading, price_per_kwh,
                             consumption, bill_amount, reading_date, status, submitted_by)
                        VALUES (?, ?, ?, ?, ?, ?, ?, 'Pending Verification', ?)
                    ");
                    $meterStmt->execute([
                        $apartment_id, $startReading, $currentReading, $pricePerKwh,
                        $consumption, $billAmount, $endDate, $data['user_id'] ?? 1
                    ]);

                    // Generate corresponding meter invoice
                    $this->db->prepare(
                        "INSERT INTO electricity_invoices (apartment_id, type, amount, due_date)
                         VALUES (?, 'Meter', ?, ?)"
                    )->execute([$apartment_id, $billAmount, $endDate]);
                }
            }

            // ── Auto-generate subscription invoice for Fixed plans ────────────
            if (($data['status'] ?? 'Active') === 'Active' && $monthlyFee > 0 && $type !== 'Meter') {
                $monthStr = date('Y-m', strtotime($startDate));
                $invCheck = $this->db->prepare(
                    "SELECT id FROM electricity_invoices
                     WHERE apartment_id = ?
                       AND type IN ('Subscription', 'Fixed Subscription')
                       AND DATE_FORMAT(due_date, '%Y-%m') = ?"
                );
                $invCheck->execute([$apartment_id, $monthStr]);
                if (!$invCheck->fetch()) {
                    $this->db->prepare(
                        "INSERT INTO electricity_invoices (apartment_id, type, amount, due_date)
                         VALUES (?, 'Subscription', ?, ?)"
                    )->execute([$apartment_id, $monthlyFee, $startDate]);
                } else {
                    $this->db->prepare(
                        "UPDATE electricity_invoices SET amount = ?
                         WHERE apartment_id = ?
                           AND type IN ('Subscription', 'Fixed Subscription')
                           AND DATE_FORMAT(due_date, '%Y-%m') = ?
                           AND status = 'Unpaid'"
                    )->execute([$monthlyFee, $apartment_id, $monthStr]);
                }
            }

            $this->db->commit();
            echo json_encode([
                'message'    => 'Subscription saved successfully',
                'start_date' => $startDate,
                'end_date'   => $endDate,
            ]);
        } catch (Exception $e) {
            if ($this->db->inTransaction()) $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function switchPlan($apartment_id, $sub_id) {
        try {
            $data = json_decode(file_get_contents("php://input"), true) ?: $_POST;
            $newPricePerKwh = floatval($data['price_per_kwh'] ?? 0);
            $initialReading = floatval($data['initial_reading'] ?? 0);

            $this->db->beginTransaction();

            // 1. Fetch current subscription
            $stmt = $this->db->prepare("SELECT * FROM electricity_subscriptions WHERE id = ? AND apartment_id = ?");
            $stmt->execute([$sub_id, $apartment_id]);
            $currentSub = $stmt->fetch(PDO::FETCH_ASSOC);

            if (!$currentSub || $currentSub['type'] === 'Meter') {
                throw new Exception("Invalid subscription or already on a Meter plan.");
            }

            // 2. Proration Logic
            $startDate = new DateTime($currentSub['start_date']);
            $currentDate = new DateTime(); // Today
            
            // If the start date is in the future, days used is 0
            if ($startDate > $currentDate) {
                $daysUsed = 0;
            } else {
                $daysUsed = $startDate->diff($currentDate)->days;
            }

            $monthlyFee = floatval($currentSub['monthly_fee']);
            $dailyRate = $monthlyFee / 30; // 30-day month average for proration
            $proratedAmount = round($dailyRate * $daysUsed, 2);

            // 3. Generate Prorated Invoice
            if ($proratedAmount > 0) {
                $invStmt = $this->db->prepare("
                    INSERT INTO electricity_invoices (apartment_id, type, amount, due_date, notes)
                    VALUES (?, 'Prorated Switch', ?, ?, 'Prorated charge for switching plan mid-cycle')
                ");
                $invStmt->execute([$apartment_id, $proratedAmount, $currentDate->format('Y-m-d')]);
            }

            // 4. Update Subscription
            $nextBillingDate = clone $currentDate;
            $nextBillingDate->modify('+1 month');

            $updateStmt = $this->db->prepare("
                UPDATE electricity_subscriptions
                SET type = 'Meter',
                    start_date = ?,
                    next_billing_date = ?,
                    last_meter_reading = ?,
                    price_per_kwh = ?,
                    amps = 0,
                    monthly_fee = 0
                WHERE id = ?
            ");
            $updateStmt->execute([
                $currentDate->format('Y-m-d'),
                $nextBillingDate->format('Y-m-d'),
                $initialReading,
                $newPricePerKwh,
                $sub_id
            ]);

            $this->db->commit();
            echo json_encode(['message' => 'Plan switched to Meter successfully.']);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function updateFee($apartment_id, $sub_id) {
        try {
            $data = json_decode(file_get_contents("php://input"), true);
            $newFee = floatval($data['monthly_fee'] ?? 0);
            
            $this->db->beginTransaction();
            
            $stmt = $this->db->prepare("UPDATE electricity_subscriptions SET monthly_fee = ? WHERE id = ? AND apartment_id = ?");
            $stmt->execute([$newFee, $sub_id, $apartment_id]);
            
            // Also update any unpaid current subscription invoice
            $updInv = $this->db->prepare("UPDATE electricity_invoices SET amount = ? WHERE apartment_id = ? AND type IN ('Subscription', 'Fixed Subscription') AND status = 'Unpaid'");
            $updInv->execute([$newFee, $apartment_id]);
            
            // Log history
            $histStmt = $this->db->prepare("INSERT INTO subscription_history (subscription_id, action, previous_value, new_value, reason, performed_by) VALUES (?, 'Updated Fee', NULL, ?, 'Admin changed fee inline', ?)");
            $histStmt->execute([$sub_id, $newFee, $data['user_id'] ?? 1]);

            $this->db->commit();
            echo json_encode(['message' => 'Monthly fee updated successfully']);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function requestRenewal($apartment_id) {
        try {
            // Find active tenant
            $stmt = $this->db->prepare("
                SELECT t.user_id 
                FROM contracts c 
                JOIN tenants t ON c.tenant_id = t.id 
                WHERE c.apartment_id = ? AND c.status IN ('Active', 'Approved') LIMIT 1
            ");
            $stmt->execute([$apartment_id]);
            $tenant = $stmt->fetch(PDO::FETCH_ASSOC);

            if (!$tenant || !$tenant['user_id']) {
                http_response_code(400);
                echo json_encode(['error' => 'No active tenant user found for this apartment.']);
                return;
            }

            // Create notification for tenant
            $notifStmt = $this->db->prepare("
                INSERT INTO notifications (user_id, title, message, type, reference_id) 
                VALUES (?, 'Generator Subscription Renewal', 'Your generator subscription is expiring soon. Would you like to renew?', 'generator_renewal_request', ?)
            ");
            $notifStmt->execute([$tenant['user_id'], $apartment_id]);

            echo json_encode(['message' => 'Renewal request sent to tenant successfully.']);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function respondRenewal($apartment_id) {
        try {
            $data = json_decode(file_get_contents('php://input'), true);
            $decision = $data['decision'] ?? null;
            $notificationId = $data['notification_id'] ?? null;

            if (!in_array($decision, ['Accept', 'Reject', 'Pause']) || !$notificationId) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid decision or missing notification ID.']);
                return;
            }

            // Mark the tenant's notification as read
            $stmt = $this->db->prepare("UPDATE notifications SET is_read = 1 WHERE id = ?");
            $stmt->execute([$notificationId]);

            // Find the apartment code for the admin notification
            $aptStmt = $this->db->prepare("SELECT code FROM apartments WHERE id = ?");
            $aptStmt->execute([$apartment_id]);
            $apt = $aptStmt->fetch(PDO::FETCH_ASSOC);
            $aptCode = $apt ? $apt['code'] : 'Unknown';

            // Send notification to all admins (role = admin or role = superadmin)
            $adminStmt = $this->db->prepare("SELECT id FROM users WHERE role IN ('admin', 'superadmin')");
            $adminStmt->execute();
            $admins = $adminStmt->fetchAll(PDO::FETCH_ASSOC);

            foreach ($admins as $admin) {
                $notifStmt = $this->db->prepare("
                    INSERT INTO notifications (user_id, title, message, type, reference_id) 
                    VALUES (?, 'Tenant Renewal Response', ?, 'tenant_renewal_response', ?)
                ");
                $message = "The tenant in apartment $aptCode has responded to the renewal request with: $decision.";
                $notifStmt->execute([$admin['id'], $message, $apartment_id]);
            }

            // If accepted, auto renew
            if ($decision === 'Accept') {
                $this->renewSubscription($apartment_id);
                return;
            }

            echo json_encode(['message' => "Successfully recorded $decision."]);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    // --- Meter Readings ---
    public function getMeterReadings($apartment_id) {
        try {
            $stmt = $this->db->prepare("
                SELECT * FROM electricity_meter_readings
                WHERE apartment_id = ?
                ORDER BY reading_date DESC, id DESC
            ");
            $stmt->execute([$apartment_id]);
            echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function getLatestMeterReading($apartment_id) {
        try {
            $stmt = $this->db->prepare("
                SELECT current_reading FROM electricity_meter_readings
                WHERE apartment_id = ?
                ORDER BY reading_date DESC, id DESC LIMIT 1
            ");
            $stmt->execute([$apartment_id]);
            $reading = $stmt->fetchColumn();
            echo json_encode(['latest_reading' => $reading ?: 0]);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function storeMeterReading($apartment_id = null) {
        try {
            // Check if it's form data or json
            $contentType = isset($_SERVER["CONTENT_TYPE"]) ? trim($_SERVER["CONTENT_TYPE"]) : '';
            if (strpos($contentType, 'multipart/form-data') !== false) {
                $data = $_POST;
            } else {
                $data = json_decode(file_get_contents("php://input"), true) ?: $_POST;
            }
            
            $apartment_id = $apartment_id ?? $data['apartment_id'];
            
            // Handle Photo Upload (Optional for admin)
            $photoPath = null;
            if (isset($_FILES['photo']) && $_FILES['photo']['error'] == UPLOAD_ERR_OK) {
                $uploadDir = __DIR__ . '/../../uploads/electricity-meters/';
                if (!is_dir($uploadDir)) mkdir($uploadDir, 0777, true);
                $ext = pathinfo($_FILES['photo']['name'], PATHINFO_EXTENSION);
                $filename = time() . '_' . rand(1000, 9999) . '.' . $ext;
                $photoPath = 'uploads/electricity-meters/' . $filename;
                move_uploaded_file($_FILES['photo']['tmp_name'], $uploadDir . $filename);
            }
            
            $consumption = floatval($data['current_reading']) - floatval($data['previous_reading']);
            $bill_amount = $consumption * floatval($data['price_per_kwh']);
            $userId = $data['user_id'] ?? 1;

            $this->db->beginTransaction();

            $stmt = $this->db->prepare("
                INSERT INTO electricity_meter_readings 
                (apartment_id, meter_number, previous_reading, current_reading, price_per_kwh, consumption, bill_amount, reading_date, photo_path, status, submitted_by)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'Pending Verification', ?)
            ");
            $stmt->execute([
                $apartment_id,
                $data['meter_number'] ?? null,
                $data['previous_reading'],
                $data['current_reading'],
                $data['price_per_kwh'],
                $consumption,
                $bill_amount,
                $data['end_date'],
                $photoPath,
                $userId
            ]);

            // Auto-generate invoice
            $invStmt = $this->db->prepare("
                INSERT INTO electricity_invoices (apartment_id, type, amount, due_date)
                VALUES (?, 'Meter', ?, DATE_ADD(?, INTERVAL 7 DAY))
            ");
            $invStmt->execute([
                $apartment_id,
                $bill_amount,
                $data['end_date']
            ]);

            // Update next_billing_date, start_date, end_date for the subscription
            // Also update last_meter_reading to the new current reading
            $subStmt = $this->db->prepare("
                UPDATE electricity_subscriptions 
                SET start_date = ?, 
                    end_date = DATE_ADD(?, INTERVAL 1 MONTH), 
                    next_billing_date = DATE_ADD(?, INTERVAL 1 MONTH),
                    last_meter_reading = ?
                WHERE apartment_id = ?
            ");
            // The old end_date becomes the new start_date
            $newStartDate = $data['end_date'];
            $subStmt->execute([$newStartDate, $newStartDate, $newStartDate, $data['current_reading'], $apartment_id]);

            $this->db->commit();
            echo json_encode(['message' => 'Meter reading saved and invoice generated', 'consumption' => $consumption, 'bill_amount' => $bill_amount]);
        } catch (PDOException $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function getPendingMeterReadings() {
        try {
            $stmt = $this->db->query("
                SELECT emr.*, a.code as apartment_code, b.name as building_name, u.name as submitter_name
                FROM electricity_meter_readings emr
                JOIN apartments a ON emr.apartment_id = a.id
                JOIN buildings b ON a.building_id = b.id
                LEFT JOIN users u ON emr.submitted_by = u.id
                WHERE emr.status = 'Pending Verification'
                ORDER BY emr.created_at DESC
            ");
            echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function verifyMeterReading($id) {
        try {
            $data = json_decode(file_get_contents("php://input"), true);
            $status = $data['status']; // 'Verified' or 'Rejected'
            $rejectionReason = $data['rejection_reason'] ?? null;
            $adminId = $data['user_id'] ?? 1;

            $stmt = $this->db->prepare("
                UPDATE electricity_meter_readings 
                SET status = ?, approved_by = ?, rejection_reason = ?
                WHERE id = ?
            ");
            $stmt->execute([$status, $adminId, $rejectionReason, $id]);
            
            echo json_encode(['message' => 'Meter reading verification updated.']);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function getSubscriptionInvoices($apartment_id) {
        try {
            $stmt = $this->db->prepare("
                SELECT ei.*, es.amps, es.cost_per_amp, es.monthly_fee
                FROM electricity_invoices ei
                LEFT JOIN electricity_subscriptions es ON ei.apartment_id = es.apartment_id
                WHERE ei.apartment_id = ? AND (ei.type IN ('Subscription', 'Fixed Subscription', 'Meter') OR ei.type = '')
                ORDER BY ei.due_date DESC
            ");
            $stmt->execute([$apartment_id]);
            $invoices = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            foreach ($invoices as &$inv) {
                if ($inv['status'] === 'Paid' && (float)$inv['amount_paid'] == 0) {
                    $inv['amount_paid'] = $inv['amount'];
                }
            }
            
            echo json_encode($invoices);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function getInvoices($apartment_id) {
         try {
            $stmt = $this->db->prepare("
                SELECT ei.*, 
                       emr.previous_reading, 
                       emr.current_reading, 
                       emr.consumption 
                FROM electricity_invoices ei
                LEFT JOIN electricity_meter_readings emr 
                  ON ei.apartment_id = emr.apartment_id 
                 AND ei.type = 'Meter' 
                 AND ei.amount = emr.bill_amount
                 AND DATE(DATE_ADD(emr.reading_date, INTERVAL 7 DAY)) = DATE(ei.due_date)
                WHERE ei.apartment_id = ?
                ORDER BY ei.due_date DESC
            ");
            $stmt->execute([$apartment_id]);
            $invoices = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Fix legacy data where amount_paid is 0 but status is Paid
            foreach ($invoices as &$inv) {
                if ($inv['status'] === 'Paid' && (float)$inv['amount_paid'] == 0) {
                    $inv['amount_paid'] = $inv['amount'];
                }
            }
            
            echo json_encode($invoices);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function payInvoice($invoice_id) {
         try {
            $data = json_decode(file_get_contents("php://input"), true);
            $additionalPaid = isset($data['amount_paid']) ? floatval($data['amount_paid']) : null;

            $stmt = $this->db->prepare("SELECT amount, amount_paid, status FROM electricity_invoices WHERE id = ?");
            $stmt->execute([$invoice_id]);
            $invoice = $stmt->fetch(PDO::FETCH_ASSOC);

            if (!$invoice) {
                http_response_code(404);
                echo json_encode(['error' => 'Invoice not found']);
                return;
            }

            if ($additionalPaid === null) {
                // If no partial amount passed, assume full payment
                $newPaid = floatval($invoice['amount']);
            } else {
                $newPaid = floatval($invoice['amount_paid']) + $additionalPaid;
            }

            $newStatus = ($newPaid >= floatval($invoice['amount'])) ? 'Paid' : 'Partially Paid';

            $updateStmt = $this->db->prepare("
                UPDATE electricity_invoices 
                SET amount_paid = ?, status = ? 
                WHERE id = ?
            ");
            $updateStmt->execute([$newPaid, $newStatus, $invoice_id]);
            echo json_encode(['message' => 'Invoice payment recorded', 'status' => $newStatus, 'amount_paid' => $newPaid]);
         } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
         }
    }

    // --- Smart Apartment Analysis ---
    public function getApartmentAnalysis($apartment_id) {
         try {
            // Get this apartment's latest reading
            $stmt = $this->db->prepare("
                SELECT consumption, reading_date 
                FROM electricity_meter_readings 
                WHERE apartment_id = ? 
                ORDER BY reading_date DESC LIMIT 1
            ");
            $stmt->execute([$apartment_id]);
            $latest = $stmt->fetch(PDO::FETCH_ASSOC);

            if (!$latest) {
                 echo json_encode(['insight' => 'Not enough data for analysis.']);
                 return;
            }

            // Get building average consumption for the same period roughly
            $avgStmt = $this->db->prepare("
                SELECT AVG(consumption) as avg_consumption
                FROM electricity_meter_readings emr
                JOIN apartments a ON emr.apartment_id = a.id
                WHERE a.building_id = (SELECT building_id FROM apartments WHERE id = ?)
            ");
            $avgStmt->execute([$apartment_id]);
            $avg = $avgStmt->fetch(PDO::FETCH_ASSOC);

            $insight = "Consumption is normal.";
            if ($avg && $avg['avg_consumption'] > 0) {
                $ratio = $latest['consumption'] / $avg['avg_consumption'];
                if ($ratio > 1.5) {
                    $percent = round(($ratio - 1) * 100);
                    $insight = "This apartment is consuming {$percent}% more electricity than the building average.";
                } elseif ($ratio < 0.5) {
                    $insight = "This apartment is consuming significantly less than the building average.";
                }
            }

            echo json_encode([
                'latest_consumption' => $latest['consumption'],
                'building_average' => $avg ? round($avg['avg_consumption'], 2) : 0,
                'insight' => $insight
            ]);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }
}
