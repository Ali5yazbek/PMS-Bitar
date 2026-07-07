<?php
class ApartmentsController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function index() {
        AuthMiddleware::requireLogin();
        $building_id = $_GET['building_id'] ?? null;
        
        if ($building_id) {
            $stmt = $this->db->prepare("
                SELECT a.*, 
                       t.full_name as tenant_name,
                       c.id as active_contract_id
                FROM apartments a
                LEFT JOIN contracts c ON a.id = c.apartment_id AND c.status = 'Active'
                LEFT JOIN tenants t ON c.tenant_id = t.id
                WHERE a.building_id = ?
            ");
            $stmt->execute([$building_id]);
        } else {
            $stmt = $this->db->query("
                SELECT a.*, b.name as building_name,
                       t.full_name as tenant_name,
                       c.id as active_contract_id
                FROM apartments a 
                JOIN buildings b ON a.building_id = b.id
                LEFT JOIN contracts c ON a.id = c.apartment_id AND c.status = 'Active'
                LEFT JOIN tenants t ON c.tenant_id = t.id
            ");
        }
        echo json_encode($stmt->fetchAll());
    }

    public function show($id) {
        AuthMiddleware::requireLogin();
        $stmt = $this->db->prepare("SELECT * FROM apartments WHERE id = ?");
        $stmt->execute([$id]);
        $apartment = $stmt->fetch();
        if ($apartment) {
            echo json_encode($apartment);
        } else {
            http_response_code(404);
            echo json_encode(['error' => 'Apartment not found']);
        }
    }

    public function store() {
        AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        if (empty($data['building_id']) || empty($data['code']) || empty($data['monthly_rent']) || empty($data['monthly_insurance'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Missing required fields']);
            return;
        }

        $stmt = $this->db->prepare("INSERT INTO apartments (building_id, code, monthly_rent, monthly_insurance, status) VALUES (?, ?, ?, ?, ?)");
        $status = $data['status'] ?? 'Vacant';
        $stmt->execute([$data['building_id'], $data['code'], $data['monthly_rent'], $data['monthly_insurance'], $status]);
        $id = $this->db->lastInsertId();
        
        AuditLogger::log('CREATE', 'Apartment', $id, "Created apartment: {$data['code']}");

        // Auto-schedule initial AC maintenance task
        $today = date('Y-m-d');
        $maintenanceStmt = $this->db->prepare("INSERT INTO ac_maintenance_tasks (apartment_id, scheduled_date, status) VALUES (?, ?, 'Scheduled')");
        $maintenanceStmt->execute([$id, $today]);
        
        echo json_encode(['message' => 'Apartment created successfully', 'id' => $id]);
    }

    public function update($id) {
        AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        $stmt = $this->db->prepare("UPDATE apartments SET code = ?, monthly_rent = ?, monthly_insurance = ?, status = ? WHERE id = ?");
        $stmt->execute([$data['code'], $data['monthly_rent'], $data['monthly_insurance'], $data['status'], $id]);
        
        // Update active contract's rent as well so future invoices use the new rate
        $stmtContract = $this->db->prepare("UPDATE contracts SET monthly_rent = ?, monthly_insurance = ? WHERE apartment_id = ? AND status IN ('Active', 'Approved')");
        $stmtContract->execute([$data['monthly_rent'], $data['monthly_insurance'], $id]);

        // Update any future Unpaid invoices for active contracts to reflect new rent
        $stmtInvoices = $this->db->prepare("
            UPDATE rent_invoices ri
            JOIN contracts c ON ri.contract_id = c.id
            SET ri.amount = ?
            WHERE c.apartment_id = ? AND c.status IN ('Active', 'Approved') AND ri.status = 'Unpaid' AND ri.due_date >= CURRENT_DATE
        ");
        $stmtInvoices->execute([$data['monthly_rent'], $id]);

        AuditLogger::log('UPDATE', 'Apartment', $id, "Updated apartment: {$data['code']} and applied new rent to active contract/invoices");
        
        echo json_encode(['message' => 'Apartment and related active contracts updated successfully']);
    }

    public function destroy($id) {
        AuthMiddleware::requireLogin();
        
        AuditLogger::log('DELETE', 'Apartment', $id, "Deleted apartment ID: {$id}");
        
        $stmt = $this->db->prepare("DELETE FROM apartments WHERE id = ?");
        $stmt->execute([$id]);
        echo json_encode(['message' => 'Apartment deleted successfully']);
    }

    public function financials() {
        AuthMiddleware::requireLogin();
        
        $period = $_GET['period'] ?? 'all';
        
        $paymentDateCondition = "1=1";
        $invoiceDateCondition = "1=1";
        
        if ($period === 'daily') {
            $paymentDateCondition = "rp.date = CURRENT_DATE";
            $invoiceDateCondition = "ri.due_date = CURRENT_DATE";
        } elseif ($period === 'monthly') {
            $paymentDateCondition = "MONTH(rp.date) = MONTH(CURRENT_DATE) AND YEAR(rp.date) = YEAR(CURRENT_DATE)";
            $invoiceDateCondition = "MONTH(ri.due_date) = MONTH(CURRENT_DATE) AND YEAR(ri.due_date) = YEAR(CURRENT_DATE)";
        } elseif ($period === 'yearly') {
            $paymentDateCondition = "YEAR(rp.date) = YEAR(CURRENT_DATE)";
            $invoiceDateCondition = "YEAR(ri.due_date) = YEAR(CURRENT_DATE)";
        }
        
        $stmt = $this->db->query("
            SELECT a.id, a.code, b.name as building_name, a.building_id, a.status, a.monthly_rent, a.monthly_insurance,
                   t.full_name as tenant_name,
                   COALESCE(SUM(ri.amount), 0) as total_expected_rent,
                   COALESCE(SUM((SELECT SUM(amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id AND $paymentDateCondition)), 0) as total_paid_rent,
                   COALESCE(SUM(ri.amount), 0) - COALESCE(SUM((SELECT SUM(amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id AND $paymentDateCondition)), 0) as total_unpaid_rent,
                   COUNT(CASE WHEN (ri.status = 'Unpaid' OR ri.status = 'Partial') AND ri.due_date < CURRENT_DATE THEN 1 END) as overdue_months
            FROM apartments a
            JOIN buildings b ON a.building_id = b.id
            LEFT JOIN contracts c ON a.id = c.apartment_id AND (c.status = 'Active' OR c.status = 'Approved')
            LEFT JOIN tenants t ON c.tenant_id = t.id
            LEFT JOIN rent_invoices ri ON c.id = ri.contract_id AND $invoiceDateCondition
            WHERE a.status = 'Rented'
            GROUP BY a.id, b.name, t.full_name
        ");
        echo json_encode($stmt->fetchAll());
    }

    public function financialOverview($id) {
        AuthMiddleware::requireLogin();
        $month = $_GET['month'] ?? date('Y-m');
        
        // Fetch rent income
        $rentStmt = $this->db->prepare("SELECT COALESCE(SUM(amount_paid), 0) as paid, COALESCE(SUM(amount - amount_paid), 0) as remaining FROM rent_invoices WHERE contract_id IN (SELECT id FROM contracts WHERE apartment_id = ?) AND DATE_FORMAT(due_date, '%Y-%m') = ?");
        $rentStmt->execute([$id, $month]);
        $rentData = $rentStmt->fetch(PDO::FETCH_ASSOC);

        // Fetch electricity (assuming it's an expense or tracked separately in expenses table, but let's query the expenses table directly for all costs)
        $expStmt = $this->db->prepare("SELECT category, SUM(amount) as total FROM expenses WHERE entity_type = 'Apartment' AND entity_id = ? AND DATE_FORMAT(date, '%Y-%m') = ? GROUP BY category");
        $expStmt->execute([$id, $month]);
        $expensesRows = $expStmt->fetchAll(PDO::FETCH_ASSOC);
        
        $expenses = [];
        $totalExpenses = 0;
        foreach ($expensesRows as $row) {
            $expenses[$row['category']] = (float)$row['total'];
            $totalExpenses += (float)$row['total'];
        }

        // History data for the last 6 months
        $historyStmt = $this->db->prepare("
            SELECT 
                m.month_label,
                COALESCE(r.rent_income, 0) as rent_income,
                COALESCE(e.expenses, 0) as total_expenses
            FROM (
                SELECT DATE_FORMAT(DATE_SUB(CURRENT_DATE, INTERVAL n MONTH), '%Y-%m') as month_label
                FROM (SELECT 0 as n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) numbers
            ) m
            LEFT JOIN (
                SELECT DATE_FORMAT(due_date, '%Y-%m') as month_label, SUM(amount_paid) as rent_income
                FROM rent_invoices WHERE contract_id IN (SELECT id FROM contracts WHERE apartment_id = ?)
                GROUP BY DATE_FORMAT(due_date, '%Y-%m')
            ) r ON m.month_label = r.month_label
            LEFT JOIN (
                SELECT DATE_FORMAT(date, '%Y-%m') as month_label, SUM(amount) as expenses
                FROM expenses WHERE entity_type = 'Apartment' AND entity_id = ?
                GROUP BY DATE_FORMAT(date, '%Y-%m')
            ) e ON m.month_label = e.month_label
            ORDER BY m.month_label ASC
        ");
        $historyStmt->execute([$id, $id]);
        $history = $historyStmt->fetchAll(PDO::FETCH_ASSOC);

        echo json_encode([
            'rent' => $rentData,
            'expenses' => $expenses,
            'total_expenses' => $totalExpenses,
            'history' => $history
        ]);
    }

    public function addExpense($id) {
        AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        $stmt = $this->db->prepare("INSERT INTO expenses (category, entity_type, entity_id, amount, date, notes, user_id) VALUES (?, 'Apartment', ?, ?, ?, ?, ?)");
        $stmt->execute([
            $data['category'], 
            $id, 
            $data['amount'], 
            $data['date'], 
            $data['notes'] ?? '', 
            null
        ]);
        
        echo json_encode(['message' => 'Expense recorded successfully']);
    }

    public function getInvoices($id) {
        AuthMiddleware::requireLogin();
        $start = $_GET['start_date'] ?? date('Y-m-01');
        $end = $_GET['end_date'] ?? date('Y-m-t');

        $sql = "
            SELECT ri.id as invoice_id, ri.invoice_number, ri.amount, ri.due_date, ri.status,
                   COALESCE((SELECT SUM(amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0) as paid_amount
            FROM rent_invoices ri
            JOIN contracts c ON ri.contract_id = c.id
            WHERE c.apartment_id = ? AND ri.due_date >= ? AND ri.due_date <= ?
            ORDER BY ri.due_date DESC
        ";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$id, $start, $end]);
        echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
    }
}
