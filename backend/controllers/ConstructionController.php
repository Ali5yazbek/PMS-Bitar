<?php
class ConstructionController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function index() {
        AuthMiddleware::requireLogin();
        $stmt = $this->db->query("SELECT * FROM constructions ORDER BY id DESC");
        echo json_encode($stmt->fetchAll());
    }

    public function getGlobalMaterials() {
        AuthMiddleware::requireLogin();
        $stmt = $this->db->query("SELECT DISTINCT item_name, unit FROM construction_materials ORDER BY item_name ASC");
        $result = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode($result);
    }

    public function show($id) {
        AuthMiddleware::requireLogin();
        
        $stmt = $this->db->prepare("SELECT * FROM constructions WHERE id = ?");
        $stmt->execute([$id]);
        $project = $stmt->fetch();
        
        if (!$project) {
            http_response_code(404);
            echo json_encode(['error' => 'Project not found']);
            return;
        }
        
        // Get Expenses Ledger for this project
        $expenseStmt = $this->db->prepare("
            SELECT e.*, u.name as user_name 
            FROM expenses e 
            LEFT JOIN users u ON e.user_id = u.id 
            WHERE e.entity_type = 'Construction' AND e.entity_id = ?
            ORDER BY e.date DESC, e.id DESC
        ");
        $expenseStmt->execute([$id]);
        $expenses = $expenseStmt->fetchAll();

        // Fetch invoice items for expenses that came from the warehouse
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
            if ($exp['category'] === 'Material' || $exp['category'] === 'Warehouse') {
                $materialCost += $exp['amount'];
            } elseif ($exp['category'] === 'Labor') {
                $laborCost += $exp['amount'];
            } else {
                $otherCost += $exp['amount'];
            }
        }
        
        // Update actual_cost in database
        $upd = $this->db->prepare("UPDATE constructions SET actual_cost = ? WHERE id = ?");
        $upd->execute([$totalSpent, $id]);
        $project['actual_cost'] = $totalSpent;
        
        // Fetch construction materials
        $matStmt = $this->db->prepare("SELECT * FROM construction_materials WHERE construction_id = ?");
        $matStmt->execute([$id]);
        $materials = $matStmt->fetchAll();

        // Fetch site stock
        $stockStmt = $this->db->prepare("SELECT * FROM construction_site_stock WHERE construction_id = ?");
        $stockStmt->execute([$id]);
        $site_stock = $stockStmt->fetchAll();
        
        echo json_encode([
            'project' => $project,
            'expenses' => $expenses,
            'materials' => $materials,
            'site_stock' => $site_stock,
            'ledger' => [
                'total' => $totalSpent,
                'materials' => $materialCost,
                'labor' => $laborCost,
                'other' => $otherCost
            ]
        ]);
    }

    public function store() {
        $user = AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        $stmt = $this->db->prepare("
            INSERT INTO constructions (name, owner, location, start_date, end_date, status, budget, estimated_cost, manager, notes)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ");
        
        try {
            $stmt->execute([
                $data['name'], $data['owner'] ?? null, $data['location'] ?? null, 
                $data['start_date'] ?? null, $data['end_date'] ?? null, 
                $data['status'] ?? 'Planning', $data['budget'] ?? 0, 
                $data['estimated_cost'] ?? 0, $data['manager'] ?? null, 
                $data['notes'] ?? null
            ]);
            $id = $this->db->lastInsertId();
            AuditLogger::log($user['user_id'], 'Create', 'construction', $id, "Created construction project: {$data['name']}");
            echo json_encode(['id' => $id, 'message' => 'Project created successfully']);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function update($id) {
        $user = AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        $stmt = $this->db->prepare("
            UPDATE constructions SET 
                name = ?, owner = ?, location = ?, start_date = ?, end_date = ?, 
                status = ?, budget = ?, estimated_cost = ?, manager = ?, notes = ?
            WHERE id = ?
        ");
        
        try {
            $stmt->execute([
                $data['name'], $data['owner'], $data['location'], 
                $data['start_date'], $data['end_date'], 
                $data['status'], $data['budget'], 
                $data['estimated_cost'], $data['manager'], 
                $data['notes'], $id
            ]);
            AuditLogger::log($user['user_id'], 'Update', 'construction', $id, "Updated project details");
            echo json_encode(['message' => 'Project updated successfully']);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function destroy($id) {
        $user = AuthMiddleware::requireLogin();
        
        try {
            $stmt = $this->db->prepare("DELETE FROM constructions WHERE id = ?");
            $stmt->execute([$id]);
            AuditLogger::log($user['user_id'], 'Delete', 'construction', $id, "Deleted project");
            echo json_encode(['message' => 'Project deleted successfully']);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }
}
