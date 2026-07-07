<?php
class DepotController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function index() {
        AuthMiddleware::requireLogin();
        $stmt = $this->db->query("SELECT * FROM depots ORDER BY id ASC");
        echo json_encode($stmt->fetchAll());
    }

    public function store() {
        $user = AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        $name = $data['name'] ?? 'New Depot';
        $isPrimary = $data['is_primary'] ?? false;
        
        try {
            $this->db->beginTransaction();
            
            if ($isPrimary) {
                // Remove primary flag from others
                $this->db->query("UPDATE depots SET is_primary = FALSE");
            }
            
            // If it's the first depot, make it primary automatically
            $count = $this->db->query("SELECT COUNT(*) FROM depots")->fetchColumn();
            if ($count == 0) {
                $isPrimary = true;
            }

            $stmt = $this->db->prepare("INSERT INTO depots (name, is_primary) VALUES (?, ?)");
            $stmt->execute([$name, $isPrimary ? 1 : 0]);
            $id = $this->db->lastInsertId();
            
            // For all existing products, if we want them to be available in this depot with 0 qty?
            // Yes, let's insert 0 qty for all products in this new depot
            $products = $this->db->query("SELECT id FROM products")->fetchAll();
            $stmtInsert = $this->db->prepare("INSERT INTO product_depots (product_id, depot_id, quantity) VALUES (?, ?, 0)");
            foreach ($products as $p) {
                $stmtInsert->execute([$p['id'], $id]);
            }
            
            $this->db->commit();
            AuditLogger::log($user['user_id'], 'CREATE', 'depot', $id, "Created depot: $name");
            echo json_encode(['message' => 'Depot created successfully', 'id' => $id]);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function update($id) {
        $user = AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        $name = $data['name'] ?? null;
        $isPrimary = $data['is_primary'] ?? null;
        
        try {
            $this->db->beginTransaction();
            
            if ($isPrimary === true || $isPrimary === 1 || $isPrimary === 'true') {
                $this->db->query("UPDATE depots SET is_primary = FALSE");
            }
            
            $stmt = $this->db->prepare("UPDATE depots SET name = IFNULL(?, name), is_primary = IFNULL(?, is_primary) WHERE id = ?");
            $stmt->execute([$name, $isPrimary !== null ? ($isPrimary ? 1 : 0) : null, $id]);
            
            $this->db->commit();
            AuditLogger::log($user['user_id'], 'UPDATE', 'depot', $id, "Updated depot $id");
            echo json_encode(['message' => 'Depot updated successfully']);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function destroy($id) {
        $user = AuthMiddleware::requireLogin();
        
        try {
            $stmtCheck = $this->db->prepare("SELECT is_primary FROM depots WHERE id = ?");
            $stmtCheck->execute([$id]);
            $depot = $stmtCheck->fetch();
            
            if (!$depot) {
                throw new Exception("Depot not found.");
            }
            if ($depot['is_primary']) {
                throw new Exception("Cannot delete the primary depot.");
            }
            
            // Check if any stock exists
            $stmtStock = $this->db->prepare("SELECT SUM(quantity) as total_stock FROM product_depots WHERE depot_id = ?");
            $stmtStock->execute([$id]);
            $stock = $stmtStock->fetchColumn();
            if ($stock > 0) {
                throw new Exception("Cannot delete depot with stock. Please transfer stock first.");
            }
            
            $stmt = $this->db->prepare("DELETE FROM depots WHERE id = ?");
            $stmt->execute([$id]);
            
            AuditLogger::log($user['user_id'], 'DELETE', 'depot', $id, "Deleted depot $id");
            echo json_encode(['message' => 'Depot deleted successfully']);
        } catch (Exception $e) {
            http_response_code(400);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }
}
