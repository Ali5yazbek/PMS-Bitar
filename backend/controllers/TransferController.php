<?php
class TransferController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function index() {
        AuthMiddleware::requireLogin();
        // Fetch all transfers
        $stmt = $this->db->query("
            SELECT dt.*, d1.name as from_depot, d2.name as to_depot, u.name as user_name 
            FROM depot_transfers dt
            JOIN depots d1 ON dt.from_depot_id = d1.id
            JOIN depots d2 ON dt.to_depot_id = d2.id
            LEFT JOIN users u ON dt.user_id = u.id
            ORDER BY dt.date DESC
        ");
        $transfers = $stmt->fetchAll();
        
        foreach ($transfers as &$t) {
            $stmtItems = $this->db->prepare("
                SELECT dti.*, p.name 
                FROM depot_transfer_items dti
                JOIN products p ON dti.product_id = p.id
                WHERE dti.transfer_id = ?
            ");
            $stmtItems->execute([$t['id']]);
            $t['items'] = $stmtItems->fetchAll();
        }
        unset($t);
        
        echo json_encode($transfers);
    }

    public function store() {
        $user = AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        $fromDepotId = $data['from_depot_id'] ?? null;
        $toDepotId = $data['to_depot_id'] ?? null;
        $items = $data['items'] ?? [];
        $notes = $data['notes'] ?? '';
        
        if (!$fromDepotId || !$toDepotId || empty($items)) {
            http_response_code(400);
            echo json_encode(['error' => 'Missing required fields or items']);
            return;
        }

        if ($fromDepotId == $toDepotId) {
            http_response_code(400);
            echo json_encode(['error' => 'Cannot transfer to the same depot']);
            return;
        }
        
        try {
            $this->db->beginTransaction();
            
            // Insert transfer record
            $stmtTransfer = $this->db->prepare("INSERT INTO depot_transfers (from_depot_id, to_depot_id, user_id, notes) VALUES (?, ?, ?, ?)");
            $stmtTransfer->execute([$fromDepotId, $toDepotId, $user['user_id'], $notes]);
            $transferId = $this->db->lastInsertId();
            
            $stmtItem = $this->db->prepare("INSERT INTO depot_transfer_items (transfer_id, product_id, quantity) VALUES (?, ?, ?)");
            $stmtCheckStock = $this->db->prepare("SELECT quantity FROM product_depots WHERE product_id = ? AND depot_id = ?");
            $stmtDeduct = $this->db->prepare("UPDATE product_depots SET quantity = quantity - ? WHERE product_id = ? AND depot_id = ?");
            $stmtAdd = $this->db->prepare("UPDATE product_depots SET quantity = quantity + ? WHERE product_id = ? AND depot_id = ?");
            $stmtLog = $this->db->prepare("INSERT INTO stock_movements (product_id, type, quantity, reference_type, reference_id) VALUES (?, ?, ?, ?, ?)");
            
            foreach ($items as $item) {
                $productId = $item['product_id'];
                $qty = $item['quantity'];
                
                if ($qty <= 0) continue;
                
                // Check stock
                $stmtCheckStock->execute([$productId, $fromDepotId]);
                $currentStock = $stmtCheckStock->fetchColumn();
                
                if ($currentStock === false || $currentStock < $qty) {
                    throw new Exception("Insufficient stock for product ID $productId in the source depot.");
                }
                
                // Ensure product_depot exists for destination
                $stmtCheckDest = $this->db->prepare("SELECT 1 FROM product_depots WHERE product_id = ? AND depot_id = ?");
                $stmtCheckDest->execute([$productId, $toDepotId]);
                if (!$stmtCheckDest->fetchColumn()) {
                    $this->db->prepare("INSERT INTO product_depots (product_id, depot_id, quantity) VALUES (?, ?, 0)")->execute([$productId, $toDepotId]);
                }
                
                // Execute movements
                $stmtDeduct->execute([$qty, $productId, $fromDepotId]);
                $stmtAdd->execute([$qty, $productId, $toDepotId]);
                
                $stmtItem->execute([$transferId, $productId, $qty]);
                
                // Log movements
                $stmtLog->execute([$productId, 'OUT', $qty, 'Transfer Out', $transferId]);
                $stmtLog->execute([$productId, 'IN', $qty, 'Transfer In', $transferId]);
            }
            
            $this->db->commit();
            AuditLogger::log($user['user_id'], 'TRANSFER', 'depot_transfer', $transferId, "Transferred stock from Depot $fromDepotId to Depot $toDepotId");
            echo json_encode(['message' => 'Transfer completed successfully', 'id' => $transferId]);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(400);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }
}
