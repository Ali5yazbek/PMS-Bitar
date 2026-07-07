<?php
class InsuranceController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function index() {
        AuthMiddleware::requireLogin();
        
        $month = isset($_GET['month']) ? $_GET['month'] : date('m');
        $year = isset($_GET['year']) ? $_GET['year'] : date('Y');

        $stmt = $this->db->prepare("
            SELECT ia.*, b.id as building_id,
                   a.code as apartment_code, b.name as building_name,
                   t.full_name as tenant_name, a.monthly_insurance as base_insurance,
                   c.monthly_insurance,
                   (SELECT SUM(amount) FROM insurance_transactions it 
                    WHERE it.account_id = ia.id AND it.type = 'Deposit' AND MONTH(it.date) = ? AND YEAR(it.date) = ?) as collected_this_month
            FROM insurance_accounts ia
            JOIN contracts c ON ia.contract_id = c.id
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            JOIN tenants t ON c.tenant_id = t.id
        ");
        $stmt->execute([$month, $year]);
        echo json_encode($stmt->fetchAll());
    }

    public function show($id) {
        AuthMiddleware::requireLogin();
        
        // id is account_id
        $stmt = $this->db->prepare("SELECT * FROM insurance_transactions WHERE account_id = ? ORDER BY date DESC");
        $stmt->execute([$id]);
        $transactions = $stmt->fetchAll();

        echo json_encode(['transactions' => $transactions]);
    }

    public function addTransaction() {
        $user = AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);

        if (empty($data['account_id']) || empty($data['type']) || empty($data['amount'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Missing required fields']);
            return;
        }

        try {
            $this->db->beginTransaction();

            $stmt = $this->db->prepare("INSERT INTO insurance_transactions (account_id, type, amount, date, user_id, notes) VALUES (?, ?, ?, CURRENT_DATE(), ?, ?)");
            $stmt->execute([$data['account_id'], $data['type'], $data['amount'], $user['user_id'], $data['notes'] ?? null]);
            $transaction_id = $this->db->lastInsertId();

            if ($data['type'] === 'Deduct' && !empty($data['damage_reason'])) {
                $stmt = $this->db->prepare("INSERT INTO damage_reports (transaction_id, reason) VALUES (?, ?)");
                $stmt->execute([$transaction_id, $data['damage_reason']]);
            }

            // Update total saved
            $multiplier = ($data['type'] === 'Deposit') ? 1 : -1;
            $stmt = $this->db->prepare("UPDATE insurance_accounts SET total_saved = total_saved + (?) WHERE id = ?");
            $stmt->execute([$data['amount'] * $multiplier, $data['account_id']]);

            // If Apply_To_Rent, we should create a rent_payment
            if ($data['type'] === 'Apply_To_Rent' && !empty($data['invoice_id'])) {
                $stmt = $this->db->prepare("INSERT INTO rent_payments (invoice_id, amount, date, user_id, notes) VALUES (?, ?, CURRENT_DATE(), ?, ?)");
                $stmt->execute([$data['invoice_id'], $data['amount'], $user['user_id'], 'Applied from Insurance']);
                
                // Recalculate invoice status
                $stmt = $this->db->prepare("
                    SELECT amount as total_amount, COALESCE((SELECT SUM(amount) FROM rent_payments WHERE invoice_id = ?), 0) as paid_amount 
                    FROM rent_invoices WHERE id = ?
                ");
                $stmt->execute([$data['invoice_id'], $data['invoice_id']]);
                $row = $stmt->fetch();
                if ($row) {
                    $status = ($row['paid_amount'] >= $row['total_amount']) ? 'Paid' : (($row['paid_amount'] > 0) ? 'Partial' : 'Unpaid');
                    $stmt = $this->db->prepare("UPDATE rent_invoices SET status = ? WHERE id = ?");
                    $stmt->execute([$status, $data['invoice_id']]);
                }
            }

            // Recalculate contract insurance status
            $stmtCheck = $this->db->prepare("
                SELECT ia.total_saved, c.monthly_insurance, c.id as contract_id 
                FROM insurance_accounts ia
                JOIN contracts c ON ia.contract_id = c.id
                WHERE ia.id = ?
            ");
            $stmtCheck->execute([$data['account_id']]);
            $acc = $stmtCheck->fetch();
            if ($acc) {
                $status = ($acc['total_saved'] >= $acc['monthly_insurance']) ? 'Paid' : 'Pending Payment';
                $this->db->prepare("UPDATE contracts SET insurance_status = ? WHERE id = ?")->execute([$status, $acc['contract_id']]);
            }

            $this->db->commit();
            
            AuditLogger::log('CREATE', 'InsuranceTransaction', $data['account_id'], "Recorded insurance transaction: {$data['type']} of {$data['amount']}");
            
            echo json_encode(['message' => 'Insurance transaction recorded successfully']);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function dashboard() {
        AuthMiddleware::requireLogin();
        
        $month = isset($_GET['month']) ? $_GET['month'] : date('m');
        $year = isset($_GET['year']) ? $_GET['year'] : date('Y');

        $stmt = $this->db->prepare("
            SELECT 
                SUM(CASE WHEN type = 'Deposit' THEN amount ELSE -amount END) as net_insurance_this_month,
                SUM(CASE WHEN type = 'Deposit' THEN amount ELSE 0 END) as total_deposit_this_month,
                SUM(CASE WHEN type = 'Refund' THEN amount ELSE 0 END) as total_refund_this_month,
                SUM(CASE WHEN type = 'Deduct' THEN amount ELSE 0 END) as total_deduct_this_month,
                SUM(CASE WHEN type = 'Apply_To_Rent' THEN amount ELSE 0 END) as total_applied_to_rent_this_month
            FROM insurance_transactions 
            WHERE MONTH(date) = ? AND YEAR(date) = ?
        ");
        $stmt->execute([$month, $year]);
        $monthly_stats = $stmt->fetch();

        $stmtGlobal = $this->db->query("SELECT SUM(total_saved) as current_held_balance FROM insurance_accounts");
        $global_stats = $stmtGlobal->fetch();

        echo json_encode([
            'net_insurance' => $monthly_stats['net_insurance_this_month'] ?? 0,
            'total_deposits' => $monthly_stats['total_deposit_this_month'] ?? 0,
            'total_refunds' => $monthly_stats['total_refund_this_month'] ?? 0,
            'total_deducts' => $monthly_stats['total_deduct_this_month'] ?? 0,
            'total_applied_to_rent' => $monthly_stats['total_applied_to_rent_this_month'] ?? 0,
            'current_balance' => $global_stats['current_held_balance'] ?? 0
        ]);
    }

    public function updateDeposit($id) {
        AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        if (!isset($data['amount'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Amount is required']);
            return;
        }

        try {
            $this->db->beginTransaction();

            // Find the contract and apartment tied to this insurance account
            $stmt = $this->db->prepare("SELECT contract_id FROM insurance_accounts WHERE id = ?");
            $stmt->execute([$id]);
            $account = $stmt->fetch();

            if (!$account) {
                throw new Exception("Insurance account not found");
            }

            $stmt = $this->db->prepare("SELECT apartment_id FROM contracts WHERE id = ?");
            $stmt->execute([$account['contract_id']]);
            $contract = $stmt->fetch();

            // Update apartment base deposit
            if ($contract && $contract['apartment_id']) {
                $updApt = $this->db->prepare("UPDATE apartments SET monthly_insurance = ? WHERE id = ?");
                $updApt->execute([$data['amount'], $contract['apartment_id']]);
            }

            // Update contract deposit (for this and future)
            $updContract = $this->db->prepare("UPDATE contracts SET monthly_insurance = ? WHERE id = ?");
            $updContract->execute([$data['amount'], $account['contract_id']]);

            // Recalculate contract insurance status
            $stmtCheck = $this->db->prepare("
                SELECT ia.total_saved, c.monthly_insurance, c.id as contract_id 
                FROM insurance_accounts ia
                JOIN contracts c ON ia.contract_id = c.id
                WHERE ia.id = ?
            ");
            $stmtCheck->execute([$id]);
            $acc = $stmtCheck->fetch();
            if ($acc) {
                $status = ($acc['total_saved'] >= $acc['monthly_insurance']) ? 'Paid' : 'Pending Payment';
                $this->db->prepare("UPDATE contracts SET insurance_status = ? WHERE id = ?")->execute([$status, $acc['contract_id']]);
            }

            $this->db->commit();
            echo json_encode(['message' => 'Required deposit updated successfully']);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function getByTenant($tenantId) {
        AuthMiddleware::requireLogin();
        
        // Get all insurance accounts linked to this tenant's contracts
        $stmt = $this->db->prepare("
            SELECT ia.*, 
                   c.id as contract_id, c.start_date, c.end_date, c.status as contract_status,
                   c.monthly_insurance as required_deposit, c.insurance_status,
                   a.id as apartment_id, a.code as apartment_code, b.name as building_name, b.id as building_id
            FROM insurance_accounts ia
            JOIN contracts c ON ia.contract_id = c.id
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE c.tenant_id = ?
            ORDER BY c.start_date DESC
        ");
        $stmt->execute([$tenantId]);
        $accounts = $stmt->fetchAll();

        // For each account, get its transactions
        foreach ($accounts as &$account) {
            $tStmt = $this->db->prepare("
                SELECT it.*, u.name as created_by
                FROM insurance_transactions it
                LEFT JOIN users u ON it.user_id = u.id
                WHERE it.account_id = ?
                ORDER BY it.date DESC
            ");
            $tStmt->execute([$account['id']]);
            $account['transactions'] = $tStmt->fetchAll();
        }

        echo json_encode($accounts);
    }
}
