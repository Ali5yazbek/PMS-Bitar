<?php
class BuildingsController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function index() {
        AuthMiddleware::requireLogin();
        
        $stmt = $this->db->query("
            SELECT b.*, 
            COUNT(a.id) as total_apartments
            FROM buildings b 
            LEFT JOIN apartments a ON b.id = a.building_id 
            GROUP BY b.id
            ORDER BY b.id DESC
        ");
        echo json_encode($stmt->fetchAll());
    }

    public function show($id) {
        AuthMiddleware::requireLogin();
        
        $stmt = $this->db->prepare("SELECT * FROM buildings WHERE id = ?");
        $stmt->execute([$id]);
        $building = $stmt->fetch();
        if (!$building) {
            http_response_code(404);
            echo json_encode(['error' => 'Building not found']);
            return;
        }

        // Get expenses for building and its apartments
        $expenseStmt = $this->db->prepare("
            SELECT e.*, u.name as user_name, 
            CASE 
                WHEN e.entity_type = 'Apartment' THEN CONCAT('Apt ', a.code)
                ELSE 'Building Wide'
            END as target_name
            FROM expenses e 
            LEFT JOIN users u ON e.user_id = u.id 
            LEFT JOIN apartments a ON e.entity_type = 'Apartment' AND e.entity_id = a.id
            WHERE (e.entity_type = 'Building' AND e.entity_id = ?)
               OR (e.entity_type = 'Apartment' AND a.building_id = ?)
            ORDER BY e.date DESC, e.id DESC
        ");
        $expenseStmt->execute([$id, $id]);
        $expenses = $expenseStmt->fetchAll();

        // Fetch invoice items for expenses
        foreach ($expenses as &$exp) {
            if ($exp['reference_id'] && strpos($exp['reference_id'], 'INV-') === 0) {
                $invStmt = $this->db->prepare("
                    SELECT i.quantity, i.total_price, p.name as product_name 
                    FROM invoice_items i 
                    JOIN invoices inv ON i.invoice_id = inv.id
                    JOIN products p ON i.product_id = p.id
                    WHERE inv.invoice_number = ?
                ");
                $invStmt->execute([$exp['reference_id']]);
                $exp['items'] = $invStmt->fetchAll();
            } else {
                $exp['items'] = [];
            }
        }
        unset($exp); // Break the reference with the last element

        // Calculate totals based on expenses categories
        $materialCost = 0;
        $laborCost = 0;
        $otherCost = 0;
        $totalSpent = 0;

        foreach ($expenses as $exp) {
            $totalSpent += $exp['amount'];
            if ($exp['category'] === 'Building' || $exp['category'] === 'Apartment' || $exp['category'] === 'Maintenance') {
                $materialCost += $exp['amount']; // Typically from POS
            } elseif ($exp['category'] === 'Labor') {
                $laborCost += $exp['amount'];
            } else {
                $otherCost += $exp['amount'];
            }
        }

        // Fetch apartments and active tenants
        $aptStmt = $this->db->prepare("
            SELECT a.*, 
                   t.id as tenant_id, t.full_name as tenant_name, t.phone as tenant_phone, t.email as tenant_email,
                   c.id as contract_id, c.status as contract_status, c.end_date as contract_end_date, c.monthly_rent,
                   (SELECT COALESCE(SUM(ri.amount - COALESCE((SELECT SUM(p.amount) FROM rent_payments p WHERE p.invoice_id = ri.id), 0)), 0) 
                    FROM rent_invoices ri WHERE ri.contract_id = c.id AND ri.status IN ('Unpaid','Partial','Overdue')) as outstanding_balance,
                   (SELECT MIN(ri.due_date) FROM rent_invoices ri WHERE ri.contract_id = c.id AND ri.status IN ('Unpaid','Partial','Overdue')) as rent_due_date
            FROM apartments a
            LEFT JOIN (
                SELECT c1.* FROM contracts c1 
                JOIN (SELECT apartment_id, MAX(id) as max_id FROM contracts WHERE status IN ('Approved', 'Signed', 'Pending_Signature', 'Renewal_Pending', 'Draft') GROUP BY apartment_id) c2 
                ON c1.id = c2.max_id
            ) c ON a.id = c.apartment_id
            LEFT JOIN tenants t ON c.tenant_id = t.id
            WHERE a.building_id = ?
            ORDER BY a.code ASC
        ");
        $aptStmt->execute([$id]);
        $apartments = $aptStmt->fetchAll();

        echo json_encode([
            'building' => $building,
            'expenses' => $expenses,
            'apartments' => $apartments,
            'ledger' => [
                'total' => $totalSpent,
                'materials' => $materialCost,
                'labor' => $laborCost,
                'other' => $otherCost
            ]
        ]);
    }

    public function store() {
        AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        if (empty($data['name'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Building name is required']);
            return;
        }

        $stmt = $this->db->prepare("INSERT INTO buildings (name) VALUES (?)");
        $stmt->execute([$data['name']]);
        $id = $this->db->lastInsertId();
        
        AuditLogger::log('CREATE', 'Building', $id, "Created building: {$data['name']}");
        
        echo json_encode(['message' => 'Building created successfully', 'id' => $id]);
    }

    public function update($id) {
        AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        if (empty($data['name'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Building name is required']);
            return;
        }

        $stmt = $this->db->prepare("UPDATE buildings SET name = ? WHERE id = ?");
        $stmt->execute([$data['name'], $id]);
        
        AuditLogger::log('UPDATE', 'Building', $id, "Updated building: {$data['name']}");
        
        echo json_encode(['message' => 'Building updated successfully']);
    }

    public function destroy($id) {
        AuthMiddleware::requireLogin();
        
        // Log before delete
        AuditLogger::log('DELETE', 'Building', $id, "Deleted building ID: {$id}");
        
        $stmt = $this->db->prepare("DELETE FROM buildings WHERE id = ?");
        $stmt->execute([$id]);
        echo json_encode(['message' => 'Building deleted successfully']);
    }
}
