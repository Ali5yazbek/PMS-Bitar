<?php
class RentController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function index() {
        AuthMiddleware::requireLogin();
        require_once __DIR__ . '/../services/RentGenerationService.php';
        RentGenerationService::runCatchUpIfDue();
        
        $stmt = $this->db->query("
            SELECT ri.id, ri.contract_id, ri.rent_profile_id, ri.rent_period_id, ri.invoice_number,
                   ri.amount, ri.period_start, ri.period_end, ri.due_date, ri.notes, ri.created_at,
                   ri.payment_method, ri.payment_date, ri.reference_number, ri.bank_name,
                   ri.account_number, ri.proof_of_payment, ri.qr_requested_at,
                   CASE 
                       WHEN ri.status = 'Voided' THEN 'Voided'
                       WHEN (ri.amount - COALESCE((SELECT SUM(amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0)) <= 0.001 AND ri.amount > 0 THEN 'Paid'
                       WHEN COALESCE((SELECT SUM(amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0) > 0 THEN 'Partial'
                       WHEN ri.due_date < CURRENT_DATE() THEN 'Overdue'
                       ELSE 'Unpaid'
                   END as status,
                   a.code as apartment_code, b.name as building_name, b.id as building_id,
                   t.id as tenant_id, t.full_name as tenant_name, t.phone as tenant_phone,
                   ia.id as insurance_account_id, ia.total_saved as insurance_balance,
                   (ri.amount - COALESCE((SELECT SUM(amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0)) as outstanding_debt,
                   COALESCE((SELECT SUM(amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0) as paid_amount
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
            SELECT ri.amount as total_amount, ri.due_date, COALESCE(SUM(rp.amount), 0) as paid_amount 
            FROM rent_invoices ri
            LEFT JOIN rent_payments rp ON ri.id = rp.invoice_id
            WHERE ri.id = ?
            GROUP BY ri.id
        ");
        $stmt->execute([$invoice_id]);
        $row = $stmt->fetch();

        if ($row) {
            $isOverdue = ($row['due_date'] < date('Y-m-d'));
            if ($row['paid_amount'] >= $row['total_amount']) {
                $status = 'Paid';
            } elseif ($row['paid_amount'] > 0) {
                $status = 'Partial';
            } else {
                $status = $isOverdue ? 'Overdue' : 'Unpaid';
            }
            $stmt = $this->db->prepare("UPDATE rent_invoices SET status = ? WHERE id = ?");
            $stmt->execute([$status, $invoice_id]);
            
            $this->syncArchiveLedger($invoice_id);
        }
    }

    private function syncArchiveLedger($invoice_id) {
        $stmt = $this->db->prepare("SELECT c.tenant_id FROM rent_invoices ri JOIN contracts c ON ri.contract_id = c.id WHERE ri.id = ?");
        $stmt->execute([$invoice_id]);
        $tenant_id = $stmt->fetchColumn();

        if ($tenant_id) {
            $archStmt = $this->db->prepare("SELECT id FROM tenant_archive_history WHERE tenant_id = ?");
            $archStmt->execute([$tenant_id]);
            $archiveId = $archStmt->fetchColumn();

            if ($archiveId) {
                $contractStmt = $this->db->prepare("SELECT id FROM contracts WHERE tenant_id = ?");
                $contractStmt->execute([$tenant_id]);
                $contractIds = $contractStmt->fetchAll(PDO::FETCH_COLUMN);

                if (!empty($contractIds)) {
                    $placeholders = implode(',', array_fill(0, count($contractIds), '?'));
                    $rentStmt = $this->db->prepare("SELECT * FROM rent_invoices WHERE contract_id IN ($placeholders)");
                    $rentStmt->execute($contractIds);
                    $rentalLedger = $rentStmt->fetchAll(PDO::FETCH_ASSOC);

                    $update = $this->db->prepare("UPDATE tenant_archive_history SET rental_ledger = ? WHERE id = ?");
                    $update->execute([json_encode($rentalLedger), $archiveId]);
                }
            }
        }
    }

    // Call this manually, via scheduler, or API
    public function generateInvoices() {
        AuthMiddleware::requireLogin();
        require_once __DIR__ . '/../services/RentGenerationService.php';
        $result = RentGenerationService::generateDueInvoices();
        echo json_encode([
            'message' => "{$result['invoices_created']} invoices generated successfully.",
            'invoices_created' => $result['invoices_created'],
            'details' => $result['details'],
            'errors' => $result['errors']
        ]);
    }

    public function processAutoGeneration() {
        AuthMiddleware::requireLogin();
        require_once __DIR__ . '/../services/RentGenerationService.php';
        $result = RentGenerationService::runDaily();
        echo json_encode($result);
    }

    public function reconcileStatuses() {
        AuthMiddleware::requireLogin();
        require_once __DIR__ . '/../services/RentGenerationService.php';
        $result = RentGenerationService::reconcileInvoiceStatuses();
        echo json_encode($result);
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
        require_once __DIR__ . '/../services/RentGenerationService.php';
        RentGenerationService::runCatchUpIfDue();
        
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
