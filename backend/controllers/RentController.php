<?php
class RentController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function index() {
        AuthMiddleware::requireLogin();
        
        $stmt = $this->db->query("
            SELECT ri.*, 
                   a.code as apartment_code, b.name as building_name, b.id as building_id,
                   t.full_name as tenant_name, t.phone as tenant_phone,
                   ia.id as insurance_account_id, ia.total_saved as insurance_balance,
                   (ri.amount - COALESCE((SELECT SUM(amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0)) as outstanding_debt
            FROM rent_invoices ri
            JOIN contracts c ON ri.contract_id = c.id
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            JOIN tenants t ON c.tenant_id = t.id
            LEFT JOIN insurance_accounts ia ON ia.contract_id = c.id
            ORDER BY ri.due_date DESC
        ");
        echo json_encode($stmt->fetchAll());
    }

    public function pay() {
        $user = AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);

        if (empty($data['invoice_id']) || empty($data['amount'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Invoice ID and amount are required']);
            return;
        }

        try {
            $this->db->beginTransaction();

            $stmt = $this->db->prepare("INSERT INTO rent_payments (invoice_id, amount, date, user_id, notes) VALUES (?, ?, CURRENT_DATE(), ?, ?)");
            $stmt->execute([$data['invoice_id'], $data['amount'], $user['user_id'], $data['notes'] ?? null]);

            // Save payment method details on the invoice
            $payment_method = $data['payment_method'] ?? 'Cash';
            $reference_number = $data['reference_number'] ?? null;
            $bank_name = $data['bank_name'] ?? null;
            $account_number = $data['account_number'] ?? null;
            $proof_of_payment = $data['proof_of_payment'] ?? null;

            $stmtInvoice = $this->db->prepare("
                UPDATE rent_invoices 
                SET payment_method = ?, payment_date = CURRENT_DATE(), reference_number = ?, bank_name = ?, account_number = ?, proof_of_payment = ?
                WHERE id = ?
            ");
            $stmtInvoice->execute([$payment_method, $reference_number, $bank_name, $account_number, $proof_of_payment, $data['invoice_id']]);

            // Recalculate status
            $this->updateInvoiceStatus($data['invoice_id']);

            $this->db->commit();
            
            AuditLogger::log('CREATE', 'RentPayment', $data['invoice_id'], "Recorded payment of {$data['amount']} for invoice #{$data['invoice_id']}");
            
            echo json_encode(['message' => 'Payment recorded successfully']);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    private function updateInvoiceStatus($invoice_id) {
        $stmt = $this->db->prepare("
            SELECT ri.amount as total_amount, COALESCE(SUM(rp.amount), 0) as paid_amount 
            FROM rent_invoices ri
            LEFT JOIN rent_payments rp ON ri.id = rp.invoice_id
            WHERE ri.id = ?
            GROUP BY ri.id
        ");
        $stmt->execute([$invoice_id]);
        $row = $stmt->fetch();

        if ($row) {
            if ($row['paid_amount'] >= $row['total_amount']) {
                $status = 'Paid';
            } elseif ($row['paid_amount'] > 0) {
                $status = 'Partial';
            } else {
                $status = 'Unpaid'; // Check overdue in a cron or separate logic
            }
            $stmt = $this->db->prepare("UPDATE rent_invoices SET status = ? WHERE id = ?");
            $stmt->execute([$status, $invoice_id]);
        }
    }

    // Call this manually or via a cron job
    public function generateInvoices() {
        AuthMiddleware::requireLogin();
        
        // Only generate for active contracts where rent is active
        $stmt = $this->db->query("
            SELECT c.id as contract_id, a.monthly_rent, c.start_date, c.end_date
            FROM contracts c
            JOIN apartments a ON c.apartment_id = a.id
            WHERE c.status IN ('Active', 'Approved') AND c.rent_status = 'Active'
        ");
        $contracts = $stmt->fetchAll();

        $generated = 0;
        $today = new DateTime();
        $targetDate = clone $today;
        $targetDate->modify('+7 days'); // Generate if within 7 days of period end

        foreach ($contracts as $contract) {
            if (!$contract['start_date']) continue;

            // Find the latest invoice for this contract
            $invStmt = $this->db->prepare("SELECT * FROM rent_invoices WHERE contract_id = ? ORDER BY period_end DESC LIMIT 1");
            $invStmt->execute([$contract['contract_id']]);
            $lastInvoice = $invStmt->fetch();

            $newStart = null;
            if ($lastInvoice && $lastInvoice['period_end']) {
                $newStart = new DateTime($lastInvoice['period_end']);
                $newStart->modify('+1 day');
            } else {
                $newStart = new DateTime($contract['start_date']);
            }

            $endDate = new DateTime($contract['end_date']);

            // Generate invoices month by month up to the target date, but don't exceed contract end date
            while ($newStart < $endDate && $newStart <= $targetDate) {
                $cycleEnd = clone $newStart;
                $cycleEnd->modify('+1 month');
                $cycleEnd->modify('-1 day');

                if ($cycleEnd > $endDate) {
                    $cycleEnd = clone $endDate;
                }

                $month = $newStart->format('m');
                $year = $newStart->format('Y');
                $due_date = $newStart->format('Y-m-d'); // Due at start of period
                
                $invoice_num = 'INV-' . $year . $month . '-' . $contract['contract_id'];
                
                // Check if this specific period already exists just to be safe
                $check = $this->db->prepare("SELECT COUNT(*) FROM rent_invoices WHERE contract_id = ? AND period_start = ?");
                $check->execute([$contract['contract_id'], $newStart->format('Y-m-d')]);
                
                if ($check->fetchColumn() == 0) {
                    $insertInvoice = $this->db->prepare("
                        INSERT INTO rent_invoices (contract_id, invoice_number, amount, due_date, status, period_start, period_end) 
                        VALUES (?, ?, ?, ?, 'Unpaid', ?, ?)
                    ");
                    $insertInvoice->execute([$contract['contract_id'], $invoice_num, $contract['monthly_rent'], $due_date, $newStart->format('Y-m-d'), $cycleEnd->format('Y-m-d')]);
                    $generated++;
                }

                $newStart->modify('+1 month');
            }
        }

        echo json_encode(['message' => "$generated invoices generated successfully."]);
        if ($generated > 0) {
            AuditLogger::log('CREATE', 'RentInvoice', null, "Auto-generated $generated missing invoices");
        }
    }

    public function addHistorical() {
        $user = AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);

        if (empty($data['contract_id']) || empty($data['amount']) || empty($data['due_date'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Missing required fields']);
            return;
        }

        try {
            $this->db->beginTransaction();
            
            $month = date('m', strtotime($data['due_date']));
            $year = date('Y', strtotime($data['due_date']));
            $invoice_num = 'INV-' . $year . $month . '-' . $data['contract_id'] . '-H';

            $stmt = $this->db->prepare("INSERT INTO rent_invoices (contract_id, invoice_number, amount, due_date, status) VALUES (?, ?, ?, ?, 'Unpaid')");
            $stmt->execute([$data['contract_id'], $invoice_num, $data['amount'], $data['due_date']]);
            $invoice_id = $this->db->lastInsertId();

            if (!empty($data['is_paid'])) {
                $stmt = $this->db->prepare("INSERT INTO rent_payments (invoice_id, amount, date, user_id, notes) VALUES (?, ?, CURRENT_DATE(), ?, ?)");
                $stmt->execute([$invoice_id, $data['amount'], $user['user_id'], 'Historical Payment Record']);
                
                $stmt = $this->db->prepare("UPDATE rent_invoices SET status = 'Paid' WHERE id = ?");
                $stmt->execute([$invoice_id]);
            }

            $this->db->commit();
            
            AuditLogger::log('CREATE', 'RentInvoice', $invoice_id, "Added historical rent record of {$data['amount']} for {$data['due_date']}");
            
            echo json_encode(['message' => 'Historical rent record added successfully']);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function rentManagementDashboard() {
        AuthMiddleware::requireLogin();
        
        $start_date = !empty($_GET['start_date']) ? $_GET['start_date'] : date('Y-m-01');
        $end_date = !empty($_GET['end_date']) ? $_GET['end_date'] : date('Y-m-t');
        
        // Group by building
        $stmt = $this->db->prepare("
            SELECT 
                b.id as building_id,
                b.name as building_name,
                COUNT(DISTINCT CASE WHEN c.status IN ('Active', 'Approved') THEN a.id END) as total_rented_rooms,
                
                COALESCE(SUM(CASE WHEN ri.due_date BETWEEN ? AND ? THEN ri.amount ELSE 0 END), 0) as expected_rent,
                
                COALESCE(SUM(
                    (SELECT SUM(rp.amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id AND rp.date BETWEEN ? AND ?)
                ), 0) as total_collected,
                
                (COALESCE(SUM(ri.amount), 0) - COALESCE(SUM(
                    (SELECT SUM(rp.amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id)
                ), 0)) as outstanding_balance
                
            FROM buildings b
            LEFT JOIN apartments a ON b.id = a.building_id
            LEFT JOIN contracts c ON a.id = c.apartment_id
            LEFT JOIN rent_invoices ri ON c.id = ri.contract_id
            GROUP BY b.id, b.name
        ");
        $stmt->execute([$start_date, $end_date, $start_date, $end_date]);
        $stats = $stmt->fetchAll();

        echo json_encode($stats);
    }
}
