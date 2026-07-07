<?php
class ExpenseController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function index() {
        AuthMiddleware::requireLogin();
        
        $startDate = $_GET['start_date'] ?? date('Y-m-d', strtotime('-30 days'));
        $endDate = $_GET['end_date'] ?? date('Y-m-d');
        $category = $_GET['category'] ?? 'All';
        
        $query = "
            SELECT e.*, u.name as user_name 
            FROM expenses e 
            LEFT JOIN users u ON e.user_id = u.id 
            WHERE e.date >= ? AND e.date <= ?
        ";
        $params = [$startDate, $endDate];
        
        if ($category !== 'All') {
            $query .= " AND e.category = ?";
            $params[] = $category;
        }
        
        $query .= " ORDER BY e.date DESC, e.id DESC";
        
        $stmt = $this->db->prepare($query);
        $stmt->execute($params);
        $expenses = $stmt->fetchAll();
        
        // Enrich with entity names
        foreach ($expenses as &$exp) {
            $exp['entity_name'] = null;
            if ($exp['entity_type'] === 'Construction' && $exp['entity_id']) {
                $q = $this->db->prepare("SELECT name FROM constructions WHERE id = ?");
                $q->execute([$exp['entity_id']]);
                if ($res = $q->fetch()) $exp['entity_name'] = $res['name'];
            } elseif ($exp['entity_type'] === 'Building' && $exp['entity_id']) {
                $q = $this->db->prepare("SELECT name FROM buildings WHERE id = ?");
                $q->execute([$exp['entity_id']]);
                if ($res = $q->fetch()) $exp['entity_name'] = $res['name'];
            } elseif ($exp['entity_type'] === 'Apartment' && $exp['entity_id']) {
                $q = $this->db->prepare("SELECT a.code, b.name as building FROM apartments a JOIN buildings b ON a.building_id = b.id WHERE a.id = ?");
                $q->execute([$exp['entity_id']]);
                if ($res = $q->fetch()) $exp['entity_name'] = "Apt " . $res['code'] . " (" . $res['building'] . ")";
            }
        }
        unset($exp); // Break the reference
        
        echo json_encode($expenses);
    }

    public function dashboard() {
        AuthMiddleware::requireLogin();
        $today = date('Y-m-d');
        
        // Today's total expenses
        $stmt = $this->db->prepare("SELECT SUM(amount) FROM expenses WHERE date = ?");
        $stmt->execute([$today]);
        $todayTotal = $stmt->fetchColumn() ?: 0;
        
        // Today's breakdown by category
        $stmt = $this->db->prepare("
            SELECT category, SUM(amount) as total 
            FROM expenses 
            WHERE date = ? 
            GROUP BY category
        ");
        $stmt->execute([$today]);
        $todayBreakdown = $stmt->fetchAll();
        
        // Today's breakdown by entity
        $stmt = $this->db->prepare("
            SELECT entity_type, entity_id, SUM(amount) as total 
            FROM expenses 
            WHERE date = ? AND entity_type IS NOT NULL
            GROUP BY entity_type, entity_id
        ");
        $stmt->execute([$today]);
        $entityBreakdownRaw = $stmt->fetchAll();
        
        $entityBreakdown = [];
        foreach ($entityBreakdownRaw as $eb) {
            $name = $eb['entity_type'] . " " . $eb['entity_id'];
            if ($eb['entity_type'] === 'Construction') {
                $q = $this->db->prepare("SELECT name FROM constructions WHERE id = ?");
                $q->execute([$eb['entity_id']]);
                if ($res = $q->fetch()) $name = $res['name'];
            } elseif ($eb['entity_type'] === 'Building') {
                $q = $this->db->prepare("SELECT name FROM buildings WHERE id = ?");
                $q->execute([$eb['entity_id']]);
                if ($res = $q->fetch()) $name = $res['name'];
            } elseif ($eb['entity_type'] === 'Apartment') {
                $q = $this->db->prepare("SELECT a.code, b.name as building FROM apartments a JOIN buildings b ON a.building_id = b.id WHERE a.id = ?");
                $q->execute([$eb['entity_id']]);
                if ($res = $q->fetch()) $name = "Apt " . $res['code'] . " (" . $res['building'] . ")";
            }
            
            $entityBreakdown[] = [
                'name' => $name,
                'total' => $eb['total']
            ];
        }

        echo json_encode([
            'todayTotal' => $todayTotal,
            'categoryBreakdown' => $todayBreakdown,
            'entityBreakdown' => $entityBreakdown
        ]);
    }

    public function store() {
        $user = AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        $stmt = $this->db->prepare("
            INSERT INTO expenses (category, entity_type, entity_id, amount, date, notes, user_id)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ");
        
        try {
            $stmt->execute([
                $data['category'], 
                $data['entity_type'] ?? null, 
                $data['entity_id'] ?? null, 
                $data['amount'], 
                $data['date'] ?? date('Y-m-d'), 
                $data['notes'] ?? null,
                $user['user_id']
            ]);
            $id = $this->db->lastInsertId();
            
            // If it's linked to Construction, update actual_cost
            if (($data['entity_type'] ?? '') === 'Construction' && !empty($data['entity_id'])) {
                $this->db->prepare("UPDATE constructions SET actual_cost = actual_cost + ? WHERE id = ?")
                         ->execute([$data['amount'], $data['entity_id']]);
            }
            
            AuditLogger::log($user['user_id'], 'Create', 'expense', $id, "Logged {$data['category']} expense of {$data['amount']}");
            echo json_encode(['id' => $id, 'message' => 'Expense logged successfully']);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function assignApartmentExpense() {
        AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);

        if (empty($data['apartment_id']) || empty($data['product_id']) || empty($data['quantity']) || empty($data['cost'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Missing required fields']);
            return;
        }

        try {
            $this->db->beginTransaction();

            $total = $data['quantity'] * $data['cost'];
            $date = date('Y-m-d');

            $stmt = $this->db->prepare("
                INSERT INTO apartment_expenses (apartment_id, product_id, quantity, cost, total, date)
                VALUES (?, ?, ?, ?, ?, ?)
            ");
            $stmt->execute([
                $data['apartment_id'],
                $data['product_id'],
                $data['quantity'],
                $data['cost'],
                $total,
                $date
            ]);

            // Optionally deduplicate from stock
            $stmtStock = $this->db->prepare("UPDATE products SET quantity = quantity - ? WHERE id = ?");
            $stmtStock->execute([$data['quantity'], $data['product_id']]);

            $this->db->commit();
            
            echo json_encode(['message' => 'Expense assigned successfully']);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function getApartmentExpenses($id) {
        AuthMiddleware::requireLogin();
        
        $stmt = $this->db->prepare("
            SELECT ae.*, p.name as product_name
            FROM apartment_expenses ae
            JOIN products p ON ae.product_id = p.id
            WHERE ae.apartment_id = ?
            ORDER BY ae.date DESC
        ");
        $stmt->execute([$id]);
        
        echo json_encode($stmt->fetchAll());
    }
}
