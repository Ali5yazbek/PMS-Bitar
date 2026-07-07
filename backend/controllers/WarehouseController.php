<?php
class WarehouseController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function index() {
        AuthMiddleware::requireLogin();
        
        $stmt = $this->db->query("SELECT * FROM products ORDER BY id DESC");
        $products = $stmt->fetchAll();
        
        $stmtDepots = $this->db->prepare("SELECT pd.quantity, d.name as depot_name, d.id as depot_id, d.is_primary FROM product_depots pd JOIN depots d ON pd.depot_id = d.id WHERE pd.product_id = ?");
        foreach ($products as &$product) {
            $stmtDepots->execute([$product['id']]);
            $product['depots'] = $stmtDepots->fetchAll();
        }
        unset($product);
        
        echo json_encode($products);
    }

    public function show($id) {
        AuthMiddleware::requireLogin();
        
        $stmt = $this->db->prepare("SELECT * FROM products WHERE id = ?");
        $stmt->execute([$id]);
        $product = $stmt->fetch();
        
        if (!$product) {
            http_response_code(404);
            echo json_encode(['error' => 'Product not found']);
            return;
        }
        
        $stmtDepots = $this->db->prepare("SELECT pd.quantity, d.name as depot_name, d.id as depot_id, d.is_primary FROM product_depots pd JOIN depots d ON pd.depot_id = d.id WHERE pd.product_id = ?");
        $stmtDepots->execute([$id]);
        $product['depots'] = $stmtDepots->fetchAll();
        
        echo json_encode($product);
    }

    public function store() {
        $user = AuthMiddleware::requireLogin();
        
        $data = json_decode(file_get_contents("php://input"), true);
        
        $name = $data['name'] ?? '';
        $name_fr = $data['name_fr'] ?? null;
        $name_ar = $data['name_ar'] ?? null;
        $code = $data['code'] ?? null;
        $reference = $data['reference'] ?? null;
        $barcode = $data['barcode'] ?? null;
        $category = $data['category'] ?? null;
        $unit = $data['unit'] ?? null;
        $cost_price = $data['cost_price'] ?? 0;
        $tva = $data['tva'] ?? 0;
        $quantity = $data['quantity'] ?? 0;
        $minimum_quantity = $data['minimum_quantity'] ?? 0;
        $description = $data['description'] ?? null;
        
        $selling_price = $cost_price + ($cost_price * ($tva / 100));

        $stmt = $this->db->prepare("
            INSERT INTO products (name, name_fr, name_ar, code, reference, barcode, category, unit, cost_price, tva, selling_price, quantity, minimum_quantity, description)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ");
        
        try {
            $stmt->execute([$name, $name_fr, $name_ar, $code, $reference, $barcode, $category, $unit, $cost_price, $tva, $selling_price, $quantity, $minimum_quantity, $description]);
            $productId = $this->db->lastInsertId();
            
            // Assign initial stock to the selected depot or primary depot
            $targetDepotId = $data['depot_id'] ?? null;
            if (!$targetDepotId) {
                $primaryDepotStmt = $this->db->query("SELECT id FROM depots WHERE is_primary = TRUE LIMIT 1");
                $targetDepotId = $primaryDepotStmt->fetchColumn();
            }
            
            // Create product_depots entries for all depots
            $allDepots = $this->db->query("SELECT id FROM depots")->fetchAll();
            $insertDepot = $this->db->prepare("INSERT INTO product_depots (product_id, depot_id, quantity) VALUES (?, ?, ?)");
            
            foreach ($allDepots as $depot) {
                $qty = ($depot['id'] == $targetDepotId) ? $quantity : 0;
                $insertDepot->execute([$productId, $depot['id'], $qty]);
            }
            
            if ($quantity > 0) {
                $this->db->prepare("INSERT INTO stock_movements (product_id, type, quantity, reference_type, reference_id) VALUES (?, 'IN', ?, 'Manual', ?)")
                         ->execute([$productId, $quantity, null]);
            }
            
            AuditLogger::log($user['user_id'], 'Added Product', 'product', $productId, "Added $name with qty $quantity");
            
            echo json_encode(['id' => $productId, 'message' => 'Product created successfully']);
        } catch (Exception $e) {
            http_response_code(400);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function update($id) {
        $user = AuthMiddleware::requireLogin();
        
        $data = json_decode(file_get_contents("php://input"), true);
        
        $name = $data['name'] ?? '';
        $name_fr = $data['name_fr'] ?? null;
        $name_ar = $data['name_ar'] ?? null;
        $code = $data['code'] ?? null;
        $reference = $data['reference'] ?? null;
        $barcode = $data['barcode'] ?? null;
        $category = $data['category'] ?? null;
        $unit = $data['unit'] ?? null;
        $cost_price = $data['cost_price'] ?? 0;
        $tva = $data['tva'] ?? 0;
        $quantity = $data['quantity'] ?? 0;
        $minimum_quantity = $data['minimum_quantity'] ?? 0;
        $description = $data['description'] ?? null;
        
        $selling_price = $cost_price + ($cost_price * ($tva / 100));

        // Get old quantity to log stock movement if changed
        $stmt = $this->db->prepare("SELECT quantity FROM products WHERE id = ?");
        $stmt->execute([$id]);
        $oldProduct = $stmt->fetch();
        if (!$oldProduct) {
            http_response_code(404);
            echo json_encode(['error' => 'Product not found']);
            return;
        }

        $stmt = $this->db->prepare("
            UPDATE products SET 
                name = ?, name_fr = ?, name_ar = ?, code = ?, reference = ?, barcode = ?, category = ?, unit = ?, 
                cost_price = ?, tva = ?, selling_price = ?, quantity = ?, minimum_quantity = ?, description = ?
            WHERE id = ?
        ");
        
        try {
            $stmt->execute([$name, $name_fr, $name_ar, $code, $reference, $barcode, $category, $unit, $cost_price, $tva, $selling_price, $quantity, $minimum_quantity, $description, $id]);
            
            $diff = $quantity - $oldProduct['quantity'];
            if ($diff != 0) {
                // Adjust stock in the primary depot to match the total difference
                $primaryDepotStmt = $this->db->query("SELECT id FROM depots WHERE is_primary = TRUE LIMIT 1");
                $primaryDepotId = $primaryDepotStmt->fetchColumn();
                
                if ($primaryDepotId) {
                    $this->db->prepare("UPDATE product_depots SET quantity = quantity + ? WHERE product_id = ? AND depot_id = ?")
                             ->execute([$diff, $id, $primaryDepotId]);
                }
                
                if ($diff > 0) {
                    $this->db->prepare("INSERT INTO stock_movements (product_id, type, quantity, reference_type) VALUES (?, 'IN', ?, 'Manual Update')")->execute([$id, $diff]);
                } elseif ($diff < 0) {
                    $this->db->prepare("INSERT INTO stock_movements (product_id, type, quantity, reference_type) VALUES (?, 'OUT', ?, 'Manual Update')")->execute([$id, abs($diff)]);
                }
            }
            
            AuditLogger::log($user['user_id'], 'Updated Product', 'product', $id, "Updated $name");
            
            echo json_encode(['message' => 'Product updated successfully']);
        } catch (Exception $e) {
            http_response_code(400);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function destroy($id) {
        $user = AuthMiddleware::requireLogin();
        
        $stmt = $this->db->prepare("DELETE FROM products WHERE id = ?");
        $stmt->execute([$id]);
        
        AuditLogger::log($user['user_id'], 'Deleted Product', 'product', $id, "Deleted product $id");
        
        echo json_encode(['message' => 'Product deleted successfully']);
    }

    public function stats() {
        AuthMiddleware::requireLogin();
        
        $totalProducts = $this->db->query("SELECT COUNT(*) FROM products")->fetchColumn();
        $totalStockValue = $this->db->query("SELECT SUM(quantity * cost_price) FROM products")->fetchColumn() ?: 0;
        $lowStock = $this->db->query("SELECT COUNT(*) FROM products WHERE quantity <= minimum_quantity AND quantity > 0")->fetchColumn();
        $outOfStock = $this->db->query("SELECT COUNT(*) FROM products WHERE quantity = 0")->fetchColumn();
        
        $todayStr = date('Y-m-d');
        $todaySales = $this->db->query("SELECT SUM(final_amount) FROM invoices WHERE date = '$todayStr' AND customer_type = 'Walk-In'")->fetchColumn() ?: 0;
        $todayMaterialUsage = $this->db->query("SELECT SUM(final_amount) FROM invoices WHERE date = '$todayStr' AND customer_type != 'Walk-In'")->fetchColumn() ?: 0;

        echo json_encode([
            'totalProducts' => $totalProducts,
            'totalStockValue' => $totalStockValue,
            'lowStockProducts' => $lowStock,
            'outOfStockProducts' => $outOfStock,
            'todaysSales' => $todaySales,
            'todaysMaterialUsage' => $todayMaterialUsage
        ]);
    }
}
