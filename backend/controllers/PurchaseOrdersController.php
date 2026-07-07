<?php
class PurchaseOrdersController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function index() {
        AuthMiddleware::requireLogin();
        $stmt = $this->db->query("
            SELECT po.*, s.name as supplier_name, c.name as construction_name 
            FROM purchase_orders po 
            LEFT JOIN suppliers s ON po.supplier_id = s.id 
            LEFT JOIN constructions c ON po.construction_id = c.id
            ORDER BY po.created_at DESC
        ");
        echo json_encode($stmt->fetchAll());
    }

    public function store() {
        $user = AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        $po_number = 'PO-' . date('Ymd') . '-' . rand(1000, 9999);
        $total_price = $data['quantity'] * $data['unit_price'];
        $total_price += $total_price * ($data['tva'] / 100);

        $status = $data['status'] ?? 'Approved';
        
        $invoice_date = $data['invoice_date'] ?? date('Y-m-d');
        
        // Get supplier terms
        $stmtSup = $this->db->prepare("SELECT payment_terms_days FROM suppliers WHERE id = ?");
        $stmtSup->execute([$data['supplier_id']]);
        $terms = $stmtSup->fetchColumn() ?: 30;
        
        $due_date = date('Y-m-d', strtotime($invoice_date . " + {$terms} days"));

        $this->db->beginTransaction();
        try {
            $stmt = $this->db->prepare("
                INSERT INTO purchase_orders (po_number, supplier_id, construction_id, item_name, quantity_ordered, quantity_remaining, unit_price, tva, total_price, remaining_balance, expected_delivery_date, status, invoice_date, due_date, created_by) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ");
            $stmt->execute([
                $po_number, $data['supplier_id'], $data['construction_id'], $data['item_name'], 
                $data['quantity'], $data['quantity'], $data['unit_price'], $data['tva'] ?? 0, 
                $total_price, $total_price, $data['expected_delivery_date'], $status, $invoice_date, $due_date, $user['user_id']
            ]);
            
            $new_id = $this->db->lastInsertId();

            // Record Debt
            $stmtBal = $this->db->prepare("SELECT balance_after FROM supplier_transactions WHERE supplier_id = ? ORDER BY transaction_date DESC, id DESC LIMIT 1");
            $stmtBal->execute([$data['supplier_id']]);
            $lastBal = $stmtBal->fetchColumn();
            $newBal = floatval($lastBal) + $total_price;

            $stmtTx = $this->db->prepare("INSERT INTO supplier_transactions (supplier_id, type, reference_id, amount, balance_after, transaction_date) VALUES (?, 'Purchase', ?, ?, ?, ?)");
            $stmtTx->execute([$data['supplier_id'], $po_number, $total_price, $newBal, $invoice_date]);
            
            $this->db->commit();
            echo json_encode(['message' => 'Purchase Order created', 'po_number' => $po_number, 'id' => $new_id]);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function delete($id) {
        AuthMiddleware::requireLogin();
        $stmt = $this->db->prepare("SELECT quantity_delivered FROM purchase_orders WHERE id = ?");
        $stmt->execute([$id]);
        $po = $stmt->fetch();
        if ($po && $po['quantity_delivered'] > 0) {
            http_response_code(400);
            echo json_encode(['error' => 'Cannot delete PO that has already been partially or fully delivered.']);
            return;
        }
        $stmt = $this->db->prepare("DELETE FROM purchase_orders WHERE id = ?");
        $stmt->execute([$id]);
        echo json_encode(['message' => 'Purchase Order deleted successfully']);
    }

    public function updateStatus($id) {
        $user = AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        $stmt = $this->db->prepare("UPDATE purchase_orders SET status = ? WHERE id = ?");
        $stmt->execute([$data['status'], $id]);
        
        echo json_encode(['message' => 'Status updated']);
    }

    public function recordDelivery($id) {
        $user = AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        $delivered = floatval($data['quantity']);

        $this->db->beginTransaction();
        try {
            $stmt = $this->db->prepare("SELECT * FROM purchase_orders WHERE id = ?");
            $stmt->execute([$id]);
            $po = $stmt->fetch();
            
            if (!$po) throw new Exception("PO not found");
            
            $new_delivered = $po['quantity_delivered'] + $delivered;
            $new_remaining = $po['quantity_ordered'] - $new_delivered;
            $status = $new_remaining <= 0 ? 'Delivered' : 'Partially Delivered';
            
            $upd = $this->db->prepare("UPDATE purchase_orders SET quantity_delivered = ?, quantity_remaining = ?, status = ? WHERE id = ?");
            $upd->execute([$new_delivered, $new_remaining, $status, $id]);
            
            // Add to construction_site_stock
            $checkStock = $this->db->prepare("SELECT id FROM construction_site_stock WHERE construction_id = ? AND item_name = ?");
            $checkStock->execute([$po['construction_id'], $po['item_name']]);
            $stock = $checkStock->fetch();
            
            if ($stock) {
                $updStock = $this->db->prepare("UPDATE construction_site_stock SET quantity = quantity + ? WHERE id = ?");
                $updStock->execute([$delivered, $stock['id']]);
            } else {
                $insStock = $this->db->prepare("INSERT INTO construction_site_stock (construction_id, item_name, quantity) VALUES (?, ?, ?)");
                $insStock->execute([$po['construction_id'], $po['item_name'], $delivered]);
            }
            
            // Log Movement
            $insMov = $this->db->prepare("INSERT INTO construction_material_movements (construction_id, item_name, type, quantity, reference_id, user_id) VALUES (?, ?, 'Supplier_To_Site', ?, ?, ?)");
            $insMov->execute([$po['construction_id'], $po['item_name'], $delivered, $id, $user['user_id']]);
            
            // Add Expense
            $expense_amount = $delivered * $po['unit_price'];
            $insExp = $this->db->prepare("INSERT INTO expenses (category, entity_type, entity_id, amount, date, reference_id, user_id, expense_type) VALUES ('Construction Materials', 'construction', ?, ?, CURRENT_DATE(), ?, ?, 'Materials')");
            $insExp->execute([$po['construction_id'], $expense_amount, $po['po_number'], $user['user_id']]);
            
            // Update Actual Cost on Construction
            $updConst = $this->db->prepare("UPDATE constructions SET actual_cost = actual_cost + ? WHERE id = ?");
            $updConst->execute([$expense_amount, $po['construction_id']]);
            
            $this->db->commit();
            echo json_encode(['message' => 'Delivery recorded and stock updated']);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function returnDelivery($id) {
        $user = AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        $returned = floatval($data['quantity']);

        $this->db->beginTransaction();
        try {
            $stmt = $this->db->prepare("SELECT * FROM purchase_orders WHERE id = ?");
            $stmt->execute([$id]);
            $po = $stmt->fetch();
            
            if (!$po) throw new Exception("PO not found");
            if ($returned > $po['quantity_delivered']) throw new Exception("Cannot return more than delivered");
            
            // Check Stock
            $checkStock = $this->db->prepare("SELECT id, quantity FROM construction_site_stock WHERE construction_id = ? AND item_name = ?");
            $checkStock->execute([$po['construction_id'], $po['item_name']]);
            $stock = $checkStock->fetch();
            
            if (!$stock || $stock['quantity'] < $returned) {
                throw new Exception("Not enough materials in Site Stock to return. Some materials may have been used or wasted.");
            }
            
            // Update PO
            $new_delivered = $po['quantity_delivered'] - $returned;
            $new_remaining = $po['quantity_ordered'] - $new_delivered;
            $status = $new_delivered == 0 ? 'Approved' : 'Partially Delivered';
            
            $refund_amount = $returned * $po['unit_price'];
            $refund_amount += $refund_amount * ($po['tva'] / 100);

            $upd = $this->db->prepare("UPDATE purchase_orders SET quantity_delivered = ?, quantity_remaining = ?, remaining_balance = remaining_balance - ?, status = ? WHERE id = ?");
            $upd->execute([$new_delivered, $new_remaining, $refund_amount, $status, $id]);
            
            // Update Stock
            $updStock = $this->db->prepare("UPDATE construction_site_stock SET quantity = quantity - ? WHERE id = ?");
            $updStock->execute([$returned, $stock['id']]);
            
            // Log Movement
            $insMov = $this->db->prepare("INSERT INTO construction_material_movements (construction_id, item_name, type, quantity, reference_id, user_id) VALUES (?, ?, 'Return_To_Supplier', ?, ?, ?)");
            $insMov->execute([$po['construction_id'], $po['item_name'], $returned, $id, $user['user_id']]);
            
            // Negative Expense
            $expense_amount = -($returned * $po['unit_price']);
            $insExp = $this->db->prepare("INSERT INTO expenses (category, entity_type, entity_id, amount, date, reference_id, user_id, expense_type) VALUES ('Construction Materials', 'construction', ?, ?, CURRENT_DATE(), ?, ?, 'Return')");
            $insExp->execute([$po['construction_id'], $expense_amount, 'RET-'.$po['po_number'], $user['user_id']]);
            
            // Update Actual Cost on Construction
            $updConst = $this->db->prepare("UPDATE constructions SET actual_cost = actual_cost + ? WHERE id = ?");
            $updConst->execute([$expense_amount, $po['construction_id']]);

            // Record Supplier Transaction Return
            $stmtBal = $this->db->prepare("SELECT balance_after FROM supplier_transactions WHERE supplier_id = ? ORDER BY transaction_date DESC, id DESC LIMIT 1");
            $stmtBal->execute([$po['supplier_id']]);
            $lastBal = $stmtBal->fetchColumn();
            $newBal = floatval($lastBal) - $refund_amount; // Debt decreases

            $stmtTx = $this->db->prepare("INSERT INTO supplier_transactions (supplier_id, type, reference_id, amount, balance_after, transaction_date) VALUES (?, 'Return', ?, ?, ?, ?)");
            $stmtTx->execute([$po['supplier_id'], 'RET-'.$po['po_number'], -$refund_amount, $newBal, date('Y-m-d')]);
            
            $this->db->commit();
            echo json_encode(['message' => 'Materials returned successfully']);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(400);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }
}
