<?php
class ConstructionStockController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function getSiteStock($construction_id) {
        AuthMiddleware::requireLogin();
        $stmt = $this->db->prepare("SELECT * FROM construction_site_stock WHERE construction_id = ?");
        $stmt->execute([$construction_id]);
        echo json_encode($stmt->fetchAll());
    }

    public function recordMovement() {
        $user = AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        $construction_id = $data['construction_id'];
        $item_name = $data['item_name'];
        $type = $data['type']; // Site_To_Consumption, Site_To_Waste, Site_To_Warehouse
        $qty = floatval($data['quantity']);
        $notes = $data['notes'] ?? '';

        $this->db->beginTransaction();
        try {
            // Check site stock
            $stmt = $this->db->prepare("SELECT * FROM construction_site_stock WHERE construction_id = ? AND item_name = ?");
            $stmt->execute([$construction_id, $item_name]);
            $stock = $stmt->fetch();

            if (!$stock || floatval($stock['quantity']) < $qty) {
                throw new Exception("Insufficient stock on site.");
            }

            // Deduct from site stock
            $updSite = $this->db->prepare("UPDATE construction_site_stock SET quantity = quantity - ? WHERE id = ?");
            $updSite->execute([$qty, $stock['id']]);

            // Movement logic
            if ($type === 'Site_To_Consumption') {
                $updMat = $this->db->prepare("UPDATE construction_materials SET used_quantity = used_quantity + ? WHERE construction_id = ? AND item_name = ?");
                $updMat->execute([$qty, $construction_id, $item_name]);
            } elseif ($type === 'Site_To_Waste') {
                $updMat = $this->db->prepare("UPDATE construction_materials SET wasted_quantity = wasted_quantity + ?, waste_reason = CONCAT(IFNULL(waste_reason,''), ' | ', ?) WHERE construction_id = ? AND item_name = ?");
                $updMat->execute([$qty, $notes, $construction_id, $item_name]);
            } elseif ($type === 'Site_To_Warehouse') {
                // Find inventory item
                $inv = $this->db->prepare("SELECT id FROM inventory_items WHERE name = ?");
                $inv->execute([$item_name]);
                $invItem = $inv->fetch();
                if ($invItem) {
                    $updInv = $this->db->prepare("UPDATE inventory_items SET current_stock = current_stock + ? WHERE id = ?");
                    $updInv->execute([$qty, $invItem['id']]);
                }
            } else {
                throw new Exception("Invalid movement type");
            }

            // Record movement
            $insMov = $this->db->prepare("INSERT INTO construction_material_movements (construction_id, item_name, type, quantity, user_id, notes) VALUES (?, ?, ?, ?, ?, ?)");
            $insMov->execute([$construction_id, $item_name, $type, $qty, $user['user_id'], $notes]);

            $this->db->commit();
            echo json_encode(['message' => 'Movement recorded successfully']);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }
}
