<?php

use Core\Database;
use Core\EventBus;
use Core\Events\PaymentReceivedEvent;

class AgentRentController {
    private $db;

    public function __construct() {
        $this->db = \Database::getInstance()->getConnection();
    }

    /**
     * Get Rent Collection Tasks assigned to the agent
     */
    public function getAssignedTasks() {
        try {
            $user = \AuthMiddleware::requireLogin();
            $agentId = $user['user_id'];
            // In a real scenario, this would filter by assignments and only show "Pending" or "Partial"
            // For now, we simulate fetching tasks that need collection
            $stmt = $this->db->prepare("
                SELECT 
                    t.id as task_id,
                    COALESCE(t.due_date, ri.due_date) as due_date,
                    t.status as task_status,
                    ri.id as invoice_id,
                    ri.invoice_number,
                    ri.amount,
                    ri.status as invoice_status,
                    c.id as contract_id,
                    b.name as building_name,
                    a.code as apartment_number,
                    tn.full_name as tenant_name,
                    rp.start_date,
                    rp.end_date,
                    COALESCE((SELECT SUM(amount) FROM rent_payments WHERE invoice_id = ri.id), 0) as amount_paid
                FROM rent_invoices ri
                JOIN contracts c ON ri.contract_id = c.id
                LEFT JOIN rent_periods rp ON ri.rent_period_id = rp.id
                JOIN apartments a ON c.apartment_id = a.id
                JOIN buildings b ON a.building_id = b.id
                JOIN tenants tn ON c.tenant_id = tn.id
                LEFT JOIN tasks t ON t.related_entity_id = c.id AND t.related_entity_type = 'Contract' AND t.type = 'Rent Collection' AND t.status != 'Completed'
                WHERE ri.status != 'Paid'
                ORDER BY b.name ASC, a.code ASC
            ");
            $stmt->execute();
            $tasks = $stmt->fetchAll(\PDO::FETCH_ASSOC);

            // Structure response by building
            $grouped = [];
            foreach ($tasks as $task) {
                $task['remaining'] = $task['amount'] - $task['amount_paid'];
                $grouped[$task['building_name']][] = $task;
            }

            echo json_encode(['status' => 'success', 'data' => $grouped]);
        } catch (\Exception $e) {
            http_response_code(500);
            echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
        }
    }

    /**
     * Handle Rent Payment Collection
     */
    public function collectPayment() {
        try {
            $user = \AuthMiddleware::requireLogin();
            $agentId = $user['user_id'];
            $data = json_decode(file_get_contents('php://input'), true);

            $this->db->beginTransaction();

            $invoiceId = $data['invoice_id'] ?? null;
            $amountReceived = floatval($data['amount'] ?? 0);
            $paymentMethod = $data['method'] ?? 'Cash';
            $reference = $data['reference'] ?? '';
            $notes = $data['notes'] ?? '';
            $taskId = $data['task_id'] ?? null;
            $requestId = $data['request_id'] ?? null;
            $invoiceType = strtolower($data['type'] ?? 'rent');

            if (!$invoiceId || $amountReceived < 0) {
                throw new \Exception("Invalid payment data");
            }

            if ($invoiceType === 'electricity' || strpos($invoiceType, 'electricity') !== false) {
                $stmt = $this->db->prepare("SELECT amount, amount_paid FROM electricity_invoices WHERE id = ?");
                $stmt->execute([$invoiceId]);
                $invoice = $stmt->fetch(\PDO::FETCH_ASSOC);

                if (!$invoice) throw new \Exception("Electricity invoice not found");

                $totalPaid = floatval($invoice['amount_paid']);
                $remaining = floatval($invoice['amount']) - $totalPaid;

                if ($amountReceived > $remaining + 0.01) {
                    throw new \Exception("Amount exceeds remaining balance");
                }

                $newTotalPaid = $totalPaid + $amountReceived;
                $isFullPayment = ($newTotalPaid >= floatval($invoice['amount']) - 0.01);
                $newStatus = $isFullPayment ? 'Paid' : 'Partially Paid';

                $updStmt = $this->db->prepare("UPDATE electricity_invoices SET amount_paid = ?, status = ? WHERE id = ?");
                $updStmt->execute([$newTotalPaid, $newStatus, $invoiceId]);

                $ftStmt = $this->db->prepare("
                    INSERT INTO financial_transactions (transaction_type, amount, invoice_id, notes, created_by)
                    VALUES ('subscription_invoice', ?, ?, ?, ?)
                ");
                $ftStmt->execute([$amountReceived, $invoiceId, $notes ?: 'Agent collected electricity payment', $agentId]);

                // Mark task and request as completed if applicable
                if ($isFullPayment) {
                    if ($taskId) {
                        $stmtTask = $this->db->prepare("UPDATE tasks SET status = 'Completed', updated_at = NOW() WHERE id = ?");
                        $stmtTask->execute([$taskId]);
                    }
                    if ($requestId) {
                        $stmtReq = $this->db->prepare("UPDATE rent_collection_requests SET status = 'COLLECTED', collected_at = NOW() WHERE id = ?");
                        $stmtReq->execute([$requestId]);
                    }
                }

                // Activity log for electricity payment
                $stmtLog = $this->db->prepare("
                    INSERT INTO activity_logs (user_id, action, entity_type, entity_id, details)
                    VALUES (?, 'Electricity Payment', 'ElectricityInvoice', ?, ?)
                ");
                $stmtLog->execute([$agentId, $invoiceId, "Collected $amountReceived via $paymentMethod"]);

                $this->db->commit();

                echo json_encode([
                    'status' => 'success',
                    'message' => $isFullPayment ? 'Payment fully collected' : 'Partial payment recorded',
                    'remaining' => $isFullPayment ? 0 : floatval($invoice['amount']) - $newTotalPaid
                ]);
                return;
            }

            // Get Invoice Data
            $stmt = $this->db->prepare("SELECT amount, status FROM rent_invoices WHERE id = ?");
            $stmt->execute([$invoiceId]);
            $invoice = $stmt->fetch(\PDO::FETCH_ASSOC);

            if (!$invoice) throw new \Exception("Invoice not found");

            // Get total paid so far
            $stmt = $this->db->prepare("SELECT COALESCE(SUM(amount), 0) FROM rent_payments WHERE invoice_id = ?");
            $stmt->execute([$invoiceId]);
            $totalPaid = floatval($stmt->fetchColumn());

            $remaining = floatval($invoice['amount']) - $totalPaid;

            if ($amountReceived > $remaining + 0.01) { // 0.01 tolerance
                throw new \Exception("Amount exceeds remaining balance");
            }

            // 1. Save Payment
            $stmt = $this->db->prepare("
                INSERT INTO rent_payments (invoice_id, amount, date, user_id, notes) 
                VALUES (?, ?, NOW(), ?, ?)
            ");
            $stmt->execute([$invoiceId, $amountReceived, $agentId, $notes]);
            $paymentId = $this->db->lastInsertId();

            $newTotalPaid = $totalPaid + $amountReceived;
            $isFullPayment = ($newTotalPaid >= floatval($invoice['amount']) - 0.01);

            // 2. Update Invoice Status and Payment Details
            $newStatus = $isFullPayment ? 'Paid' : 'Partial';
            $stmt = $this->db->prepare("UPDATE rent_invoices SET status = ?, payment_method = ?, reference_number = ?, payment_date = NOW() WHERE id = ?");
            $stmt->execute([$newStatus, $paymentMethod, $reference, $invoiceId]);

            // 3. Mark Task Completed if Full
            if ($isFullPayment) {
                if ($taskId) {
                    $stmt = $this->db->prepare("UPDATE tasks SET status = 'Completed', updated_at = NOW() WHERE id = ?");
                    $stmt->execute([$taskId]);
                }
                if ($requestId) {
                    $stmt = $this->db->prepare("UPDATE rent_collection_requests SET status = 'COLLECTED', collected_at = NOW() WHERE id = ?");
                    $stmt->execute([$requestId]);
                }

                // 3b. Auto-resume contract rent cycle so the next invoice generates.
                // If Auto Renewal is OFF, the profile/contract may be 'Paused' — collecting
                // a full payment proves the tenant intends to continue, so we reactivate both.
                $stmtGetContract = $this->db->prepare("
                    SELECT c.id FROM contracts c
                    JOIN rent_invoices ri ON ri.contract_id = c.id
                    WHERE ri.id = ?
                ");
                $stmtGetContract->execute([$invoiceId]);
                $contractIdForResume = $stmtGetContract->fetchColumn();

                if ($contractIdForResume) {
                    $stmtResumeCont = $this->db->prepare(
                        "UPDATE contracts SET rent_status = 'Active' WHERE id = ? AND rent_status != 'Active'"
                    );
                    $stmtResumeCont->execute([$contractIdForResume]);

                    $stmtResumeProf = $this->db->prepare(
                        "UPDATE rent_profiles SET status = 'Active' WHERE contract_id = ? AND status NOT IN ('Active','Ended','Closed')"
                    );
                    $stmtResumeProf->execute([$contractIdForResume]);
                }
            }

            // 4. Trigger EventBus (Accounting, Notifications, etc.)
            try {
                $event = new PaymentReceivedEvent($paymentId, $invoiceId, $amountReceived, $agentId);
                EventBus::dispatch($event);
            } catch (\Exception $eventException) {
                // EventBus failure is non-fatal — payment is already saved
                error_log('[AgentRentController] EventBus dispatch failed: ' . $eventException->getMessage());
            }

            // 5. Add Activity Log
            $stmt = $this->db->prepare("
                INSERT INTO activity_logs (user_id, action, entity_type, entity_id, details) 
                VALUES (?, ?, ?, ?, ?)
            ");
            $stmt->execute([$agentId, 'Rent Collection', 'RentInvoice', $invoiceId, "Collected $amountReceived via $paymentMethod"]);

            $this->db->commit();

            echo json_encode([
                'status' => 'success',
                'message' => $isFullPayment ? 'Payment fully collected' : 'Partial payment recorded',
                'payment_id' => $paymentId,
                'remaining' => $isFullPayment ? 0 : floatval($invoice['amount']) - $newTotalPaid
            ]);

        } catch (\Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
        }
    }

    /**
     * Lookup an invoice by invoice_number or ID — used by QR scan and manual code entry.
     * GET /api/agent/rent/invoice-lookup?code=INV-202610-18
     */
    public function lookupInvoice() {
        try {
            \AuthMiddleware::requireLogin();
            $code = trim($_GET['code'] ?? '');
            if (empty($code)) {
                http_response_code(400);
                echo json_encode(['status' => 'error', 'message' => 'Invoice code is required']);
                return;
            }

            // Try matching by invoice_number OR by numeric ID
            $stmt = $this->db->prepare("
                (
                    SELECT 
                        ri.id as invoice_id,
                        ri.invoice_number,
                        ri.amount,
                        ri.status as invoice_status,
                        COALESCE((SELECT SUM(rp.amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0) as amount_paid,
                        (ri.amount - COALESCE((SELECT SUM(rp.amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0)) as remaining,
                        ri.due_date,
                        ri.period_start,
                        ri.period_end,
                        c.id as contract_id,
                        a.code as apartment_code,
                        a.id as apartment_id,
                        b.name as building_name,
                        b.id as building_id,
                        t.full_name as tenant_name,
                        t.phone as tenant_phone,
                        'rent' as invoice_type
                    FROM rent_invoices ri
                    JOIN contracts c ON ri.contract_id = c.id
                    JOIN apartments a ON c.apartment_id = a.id
                    JOIN buildings b ON a.building_id = b.id
                    JOIN tenants t ON c.tenant_id = t.id
                    WHERE ri.status != 'Paid'
                    AND (ri.invoice_number = ? OR ri.id = ?)
                )
                UNION ALL
                (
                    SELECT 
                        ei.id as invoice_id,
                        CONCAT('Elec-', ei.id) as invoice_number,
                        ei.amount,
                        ei.status as invoice_status,
                        COALESCE(ei.amount_paid, 0) as amount_paid,
                        (ei.amount - COALESCE(ei.amount_paid, 0)) as remaining,
                        ei.due_date,
                        ei.due_date as period_start,
                        ei.due_date as period_end,
                        c.id as contract_id,
                        a.code as apartment_code,
                        a.id as apartment_id,
                        b.name as building_name,
                        b.id as building_id,
                        COALESCE(t.full_name, 'Unknown Tenant') as tenant_name,
                        COALESCE(t.phone, '') as tenant_phone,
                        'electricity' as invoice_type
                    FROM electricity_invoices ei
                    JOIN apartments a ON ei.apartment_id = a.id
                    JOIN buildings b ON a.building_id = b.id
                    LEFT JOIN contracts c ON a.id = c.apartment_id AND c.status = 'Active'
                    LEFT JOIN tenants t ON c.tenant_id = t.id
                    WHERE ei.status != 'Paid'
                    AND (CONCAT('Elec-', ei.id) = ? OR ei.id = ?)
                )
                LIMIT 1
            ");
            $numericId = is_numeric($code) ? intval($code) : 0;
            $stmt->execute([$code, $numericId, $code, $numericId]);
            $invoice = $stmt->fetch(\PDO::FETCH_ASSOC);

            if (!$invoice) {
                http_response_code(404);
                echo json_encode(['status' => 'error', 'message' => 'Invoice not found or already paid']);
                return;
            }

            echo json_encode(['status' => 'success', 'data' => $invoice]);
        } catch (\Exception $e) {
            http_response_code(500);
            echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
        }
    }

    /**
     * Get all UNPAID rent invoices for a specific apartment.
     * GET /api/agent/rent/apartment-invoices?apartment_id=5
     */
    public function getApartmentUnpaidInvoices() {
        try {
            \AuthMiddleware::requireLogin();
            $apartmentId = intval($_GET['apartment_id'] ?? 0);
            if (!$apartmentId) {
                http_response_code(400);
                echo json_encode(['status' => 'error', 'message' => 'apartment_id is required']);
                return;
            }

            $stmt = $this->db->prepare("
                (
                    SELECT 
                        ri.id as invoice_id,
                        ri.invoice_number,
                        ri.amount,
                        ri.due_date,
                        ri.period_start,
                        ri.period_end,
                        ri.status as invoice_status,
                        COALESCE((SELECT SUM(rp.amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0) as amount_paid,
                        (ri.amount - COALESCE((SELECT SUM(rp.amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0)) as remaining,
                        a.code as apartment_code,
                        b.name as building_name,
                        t.full_name as tenant_name,
                        'rent' as invoice_type
                    FROM rent_invoices ri
                    JOIN contracts c ON ri.contract_id = c.id
                    JOIN apartments a ON c.apartment_id = a.id
                    JOIN buildings b ON a.building_id = b.id
                    JOIN tenants t ON c.tenant_id = t.id
                    WHERE a.id = ?
                    AND ri.status != 'Paid'
                )
                UNION ALL
                (
                    SELECT 
                        ei.id as invoice_id,
                        CONCAT('Elec-', ei.id) as invoice_number,
                        ei.amount,
                        ei.due_date,
                        ei.due_date as period_start,
                        ei.due_date as period_end,
                        ei.status as invoice_status,
                        COALESCE(ei.amount_paid, 0) as amount_paid,
                        (ei.amount - COALESCE(ei.amount_paid, 0)) as remaining,
                        a.code as apartment_code,
                        b.name as building_name,
                        COALESCE(t.full_name, 'Unknown Tenant') as tenant_name,
                        'electricity' as invoice_type
                    FROM electricity_invoices ei
                    JOIN apartments a ON ei.apartment_id = a.id
                    JOIN buildings b ON a.building_id = b.id
                    LEFT JOIN contracts c ON a.id = c.apartment_id AND c.status = 'Active'
                    LEFT JOIN tenants t ON c.tenant_id = t.id
                    WHERE a.id = ?
                    AND ei.status != 'Paid'
                )
                ORDER BY due_date ASC
            ");
            $stmt->execute([$apartmentId, $apartmentId]);
            $invoices = $stmt->fetchAll(\PDO::FETCH_ASSOC);

            echo json_encode(['status' => 'success', 'data' => $invoices]);
        } catch (\Exception $e) {
            http_response_code(500);
            echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
        }
    }

    /**
     * Validate that a scanned QR token or invoice code matches a specific invoice.
     * The tenant's QR code contains their invoice_number. We verify it matches what the agent selected.
     * POST /api/agent/rent/validate-qr
     * Body: { invoice_id: 5, qr_code: "INV-202610-18" }
     */
    public function validateQrCode() {
        try {
            \AuthMiddleware::requireLogin();
            $data = json_decode(file_get_contents('php://input'), true);
            $invoiceId = intval($data['invoice_id'] ?? 0);
            $qrCode = trim($data['qr_code'] ?? '');

            if (!$invoiceId || empty($qrCode)) {
                http_response_code(400);
                echo json_encode(['status' => 'error', 'message' => 'invoice_id and qr_code are required']);
                return;
            }

            // Try to parse JSON QR payload (e.g., {"invoiceId": 5, "code": "INV-..."})
            $parsedCode = $qrCode;
            try {
                $decoded = json_decode($qrCode, true);
                if (is_array($decoded)) {
                    $parsedCode = $decoded['invoice_number'] ?? $decoded['code'] ?? $decoded['invoiceId'] ?? $qrCode;
                }
            } catch (\Exception $ignored) {}

            // Validate: the QR code must match the invoice's invoice_number OR id
            $stmt = $this->db->prepare("
                (
                    SELECT id, invoice_number FROM rent_invoices 
                    WHERE id = ? AND (invoice_number = ? OR id = ?)
                    AND status != 'Paid'
                )
                UNION ALL
                (
                    SELECT id, CONCAT('Elec-', id) as invoice_number FROM electricity_invoices 
                    WHERE id = ? AND (CONCAT('Elec-', id) = ? OR id = ?)
                    AND status != 'Paid'
                )
            ");
            $numericParsed = is_numeric($parsedCode) ? intval($parsedCode) : 0;
            $stmt->execute([$invoiceId, $parsedCode, $numericParsed, $invoiceId, $parsedCode, $numericParsed]);
            $match = $stmt->fetch(\PDO::FETCH_ASSOC);

            if ($match) {
                echo json_encode(['status' => 'success', 'valid' => true, 'invoice_number' => $match['invoice_number']]);
            } else {
                echo json_encode(['status' => 'error', 'valid' => false, 'message' => 'QR code does not match the selected invoice. Please ask the tenant to show the correct QR for this invoice.']);
            }
        } catch (\Exception $e) {
            http_response_code(500);
            echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
        }
    }



    /**
     * Request QR Authorization from Tenant (Pings the tenant's computer)
     */
    public function requestQrAuthorization() {
        try {
            \AuthMiddleware::requireLogin();
            $data = json_decode(file_get_contents('php://input'), true);
            $invoiceIds = $data['invoice_ids'] ?? [];

            if (empty($invoiceIds) || !is_array($invoiceIds)) {
                throw new \Exception("Invalid invoice data");
            }

            // Create placeholders for IN clause
            $placeholders = implode(',', array_fill(0, count($invoiceIds), '?'));
            
            $stmt = $this->db->prepare("
                UPDATE rent_invoices 
                SET qr_requested_at = NOW() 
                WHERE id IN ($placeholders)
            ");
            $stmt->execute($invoiceIds);

            echo json_encode(['status' => 'success']);
        } catch (\Exception $e) {
            http_response_code(500);
            echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
        }
    }

    /**
     * Get Collection History for the Agent
     */
    public function getHistory() {
        try {
            $user = \AuthMiddleware::requireLogin();
            $agentId = $user['user_id'];
            $stmt = $this->db->prepare("
                SELECT 
                    rp.id,
                    rp.date,
                    rp.amount,
                    ri.payment_method,
                    ri.reference_number,
                    ri.amount as invoice_total,
                    b.name as building_name,
                    a.code as apartment_number,
                    tn.full_name as tenant_name,
                    (ri.amount - (SELECT COALESCE(SUM(amount), 0) FROM rent_payments WHERE invoice_id = ri.id AND id <= rp.id)) as remaining
                FROM rent_payments rp
                JOIN rent_invoices ri ON rp.invoice_id = ri.id
                LEFT JOIN rent_periods rper ON ri.rent_period_id = rper.id
                JOIN contracts c ON ri.contract_id = c.id
                JOIN apartments a ON c.apartment_id = a.id
                JOIN buildings b ON a.building_id = b.id
                JOIN tenants tn ON c.tenant_id = tn.id
                WHERE rp.user_id = ?
                ORDER BY rp.date DESC
            ");
            $stmt->execute([$agentId]);
            $history = $stmt->fetchAll(\PDO::FETCH_ASSOC);

            echo json_encode(['status' => 'success', 'data' => $history]);
        } catch (\Exception $e) {
            http_response_code(500);
            echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
        }
    }

    /**
     * Get Tenant Rent Collection Requests
     */
    public function getTenantRequests() {
        try {
            $user = \AuthMiddleware::requireLogin();
            $agentId = $user['user_id'];
            
            $stmt = $this->db->prepare("
                SELECT 
                    r.id as request_id,
                    r.amount,
                    r.status,
                    r.requested_collection_date,
                    r.denial_reason,
                    b.name as building_name,
                    a.code as apartment_number,
                    tn.full_name as tenant_name,
                    rp.start_date,
                    rp.end_date,
                    ri.id as invoice_id,
                    (ri.amount - COALESCE((SELECT SUM(amount) FROM rent_payments WHERE invoice_id = ri.id), 0)) as remaining
                FROM rent_collection_requests r
                JOIN apartments a ON r.apartment_id = a.id
                JOIN buildings b ON a.building_id = b.id
                JOIN tenants tn ON r.tenant_id = tn.id
                JOIN rent_periods rp ON r.rent_period_id = rp.id
                LEFT JOIN rent_invoices ri ON ri.rent_period_id = rp.id
                WHERE r.assigned_agent_id = ? AND r.status = 'SCHEDULED'
                ORDER BY r.requested_collection_date ASC
            ");
            $stmt->execute([$agentId]);
            $requests = $stmt->fetchAll(\PDO::FETCH_ASSOC);

            // Group by building similar to tasks
            $grouped = [];
            foreach ($requests as $req) {
                $grouped[$req['building_name']][] = $req;
            }

            echo json_encode(['status' => 'success', 'data' => $grouped]);
        } catch (\Exception $e) {
            http_response_code(500);
            echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
        }
    }
}
