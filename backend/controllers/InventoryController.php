<?php
class InventoryController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function index() {
        AuthMiddleware::requireLogin();
        $stmt = $this->db->query("SELECT * FROM inventory_items ORDER BY name ASC");
        echo json_encode($stmt->fetchAll());
    }

    public function store() {
        AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        $stmt = $this->db->prepare("INSERT INTO inventory_items (name, category, unit, current_stock, min_stock, unit_cost, supplier, warehouse_location) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
        $stmt->execute([
            $data['name'], $data['category'], $data['unit'], 
            $data['current_stock'] ?? 0, $data['min_stock'] ?? 0, 
            $data['unit_cost'] ?? 0, $data['supplier'] ?? null, 
            $data['warehouse_location'] ?? null
        ]);
        
        $id = $this->db->lastInsertId();
        AuditLogger::log('CREATE', 'InventoryItem', $id, "Added inventory item: {$data['name']}");
        
        echo json_encode(['message' => 'Inventory item created successfully', 'id' => $id]);
    }

    public function transaction() {
        $user = AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        $this->db->beginTransaction();
        try {
            $stmt = $this->db->prepare("INSERT INTO inventory_transactions (item_id, type, quantity, project_id, user_id, notes, date) VALUES (?, ?, ?, ?, ?, ?, CURRENT_DATE())");
            $stmt->execute([$data['item_id'], $data['type'], $data['quantity'], $data['project_id'] ?? null, $user['user_id'], $data['notes'] ?? null]);
            
            $multiplier = ($data['type'] === 'IN') ? 1 : -1;
            $stmt = $this->db->prepare("UPDATE inventory_items SET current_stock = current_stock + (?) WHERE id = ?");
            $stmt->execute([$data['quantity'] * $multiplier, $data['item_id']]);
            
            if ($data['type'] === 'OUT' && !empty($data['project_id'])) {
                $stmtMatch = $this->db->prepare("
                    UPDATE construction_materials 
                    SET used_quantity = used_quantity + ? 
                    WHERE construction_id = ? AND item_name = (SELECT name FROM inventory_items WHERE id = ?)
                ");
                $stmtMatch->execute([$data['quantity'], $data['project_id'], $data['item_id']]);
                
                // Track expense
                $stmtItem = $this->db->prepare("SELECT name, unit_cost FROM inventory_items WHERE id = ?");
                $stmtItem->execute([$data['item_id']]);
                $item = $stmtItem->fetch();
                
                if ($item) {
                    $totalCost = $item['unit_cost'] * $data['quantity'];
                    $expStmt = $this->db->prepare("INSERT INTO expenses (category, entity_type, entity_id, amount, date, notes, user_id) VALUES ('Warehouse', 'Construction', ?, ?, CURRENT_DATE(), ?, ?)");
                    $expStmt->execute([$data['project_id'], $totalCost, "Warehouse OUT: " . $data['quantity'] . " " . $item['name'], $user['user_id']]);
                }
            }

            $this->db->commit();
            AuditLogger::log('CREATE', 'InventoryTransaction', $data['item_id'], "Recorded {$data['type']} transaction of {$data['quantity']} for item #{$data['item_id']}");
            echo json_encode(['message' => 'Transaction successful']);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function purchaseRequests() {
        AuthMiddleware::requireLogin();
        $stmt = $this->db->query("
            SELECT pr.*, i.name as item_name, i.unit, p.name as project_name 
            FROM purchase_requests pr 
            JOIN inventory_items i ON pr.item_id = i.id 
            LEFT JOIN workshop_projects p ON pr.project_id = p.id
            ORDER BY pr.created_at DESC
        ");
        echo json_encode($stmt->fetchAll());
    }
}
