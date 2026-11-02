<?php
class POSController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function index() {
        AuthMiddleware::requireLogin();
        
        $stmt = $this->db->query("SELECT * FROM invoices ORDER BY created_at DESC");
        $invoices = $stmt->fetchAll();
        
        foreach ($invoices as &$invoice) {
            $stmtItems = $this->db->prepare("SELECT i.*, p.name FROM invoice_items i JOIN products p ON i.product_id = p.id WHERE invoice_id = ?");
            $stmtItems->execute([$invoice['id']]);
            $invoice['items'] = $stmtItems->fetchAll();
        }
        unset($invoice); // Break the reference
        
        echo json_encode($invoices);
    }

    public function show($id) {
        AuthMiddleware::requireLogin();
        
        $stmt = $this->db->prepare("SELECT * FROM invoices WHERE id = ?");
        $stmt->execute([$id]);
        $invoice = $stmt->fetch();
        
        if (!$invoice) {
            http_response_code(404);
            echo json_encode(['error' => 'Invoice not found']);
            return;
        }

        $stmtItems = $this->db->prepare("SELECT i.*, p.name FROM invoice_items i JOIN products p ON i.product_id = p.id WHERE invoice_id = ?");
        $stmtItems->execute([$id]);
        $invoice['items'] = $stmtItems->fetchAll();
        
        echo json_encode($invoice);
    }

    public function getByReference($ref) {
        AuthMiddleware::requireLogin();
        
        $stmt = $this->db->prepare("SELECT * FROM invoices WHERE invoice_number = ?");
        $stmt->execute([$ref]);
        $invoice = $stmt->fetch();
        
        if (!$invoice) {
            http_response_code(404);
            echo json_encode(['error' => 'Invoice not found']);
            return;
        }

        $stmtItems = $this->db->prepare("SELECT i.*, p.name FROM invoice_items i JOIN products p ON i.product_id = p.id WHERE invoice_id = ?");
        $stmtItems->execute([$invoice['id']]);
        $invoice['items'] = $stmtItems->fetchAll();
        
        echo json_encode($invoice);
    }

    public function checkout() {
        $user = AuthMiddleware::requireLogin();
        
        $data = json_decode(file_get_contents("php://input"), true);
        
        $customerType = $data['customer_type'] ?? 'Walk-In';
        $customerId = $data['customer_id'] ?? null;
        $customerName = $data['customer_name'] ?? '';
        $items = $data['items'] ?? [];
        $discount = $data['discount'] ?? 0;
        
        if (empty($items)) {
            http_response_code(400);
            echo json_encode(['error' => 'No items in cart']);
            return;
        }

        try {
            $this->db->beginTransaction();

            $subtotal = 0;
            $totalTva = 0;
            $invoiceNumber = 'INV-' . time() . '-' . rand(1000, 9999);
            $date = date('Y-m-d');

            // Pre-calculate totals to insert into invoices table first
            foreach ($items as $item) {
                $subtotal += $item['cost_price'] * $item['quantity'];
                $totalTva += ($item['cost_price'] * ($item['tva'] / 100)) * $item['quantity'];
            }
            $finalAmount = ($subtotal + $totalTva) - $discount;

            $stmtInvoice = $this->db->prepare("
                INSERT INTO invoices (invoice_number, date, customer_type, customer_id, customer_name, subtotal, total_tva, discount, final_amount, created_by)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ");
            $userId = $_SESSION['user_id'] ?? null;
            $stmtInvoice->execute([$invoiceNumber, $date, $customerType, $customerId, $customerName, $subtotal, $totalTva, $discount, $finalAmount, $userId]);
            $invoiceId = $this->db->lastInsertId();

            $stmtItem = $this->db->prepare("
                INSERT INTO invoice_items (invoice_id, product_id, reference, quantity, cost_price, tva, total_price)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ");

            $stmtStockOut = $this->db->prepare("
                INSERT INTO stock_movements (product_id, type, quantity, reference_type, reference_id)
                VALUES (?, 'OUT', ?, 'Invoice', ?)
            ");

            $stmtUpdateStock = $this->db->prepare("
                UPDATE products SET quantity = quantity - ? WHERE id = ?
            ");

            $primaryDepotStmt = $this->db->query("SELECT id FROM depots WHERE is_primary = TRUE LIMIT 1");
            $primaryDepotId = $primaryDepotStmt->fetchColumn();

            if ($primaryDepotId) {
                $stmtUpdateDepotStock = $this->db->prepare("
                    UPDATE product_depots SET quantity = quantity - ? WHERE product_id = ? AND depot_id = ?
                ");
            }

            foreach ($items as $item) {
                $itemTvaAmount = $item['cost_price'] * ($item['tva'] / 100);
                $itemTotalPrice = ($item['cost_price'] + $itemTvaAmount) * $item['quantity'];

                // Insert Item
                $stmtItem->execute([
                    $invoiceId,
                    $item['id'],
                    $item['reference'] ?? null,
                    $item['quantity'],
                    $item['cost_price'],
                    $item['tva'],
                    $itemTotalPrice
                ]);

                // Update Stock
                $stmtUpdateStock->execute([$item['quantity'], $item['id']]);
                if ($primaryDepotId) {
                    $stmtUpdateDepotStock->execute([$item['quantity'], $item['id'], $primaryDepotId]);
                }

                // Log Movement
                $stmtStockOut->execute([$item['id'], $item['quantity'], $invoiceId]);

                // Track Construction Usage
                if ($customerType === 'Construction' && $customerId) {
                    $stmtMatch = $this->db->prepare("
                        UPDATE construction_materials 
                        SET used_quantity = used_quantity + ? 
                        WHERE construction_id = ? AND item_name = (SELECT name FROM products WHERE id = ?)
                    ");
                    $stmtMatch->execute([$item['quantity'], $customerId, $item['id']]);
                }
            }

            $this->db->commit();
            
            // Generate expense if not Walk-In
            if ($customerType !== 'Walk-In' && $customerId) {
                // Determine expense category
                $category = 'Other';
                if ($customerType === 'Construction') $category = 'Construction';
                elseif ($customerType === 'Apartment') $category = 'Apartment';
                elseif ($customerType === 'Building') $category = 'Building';
                
                $expStmt = $this->db->prepare("
                    INSERT INTO expenses (category, entity_type, entity_id, amount, date, notes, reference_id, user_id)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                ");
                $expStmt->execute([
                    $category, $customerType, $customerId, $finalAmount, $date, 
                    "Materials from Warehouse", $invoiceNumber, $user['user_id']
                ]);
                
                // If Construction, also update actual_cost
                if ($customerType === 'Construction') {
                    $this->db->prepare("UPDATE constructions SET actual_cost = actual_cost + ? WHERE id = ?")
                             ->execute([$finalAmount, $customerId]);
                }
            }
            
            AuditLogger::log($user['user_id'], 'Created POS Invoice', 'invoice', $invoiceId, "Generated invoice $invoiceNumber for $customerType");
            
            echo json_encode(['message' => 'Checkout successful', 'invoice_id' => $invoiceId, 'invoice_number' => $invoiceNumber]);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(400);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function update($id) {
        $user = AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        $newItems = $data['items'] ?? [];
        $discount = $data['discount'] ?? 0;

        if (empty($newItems)) {
            http_response_code(400);
            echo json_encode(['error' => 'Cannot have empty invoice. If you want to return everything, please delete the invoice (not implemented yet).']);
            return;
        }

        try {
            $this->db->beginTransaction();

            $stmtInv = $this->db->prepare("SELECT * FROM invoices WHERE id = ?");
            $stmtInv->execute([$id]);
            $invoice = $stmtInv->fetch();
            if (!$invoice) throw new Exception("Invoice not found.");

            $stmtOldItems = $this->db->prepare("SELECT * FROM invoice_items WHERE invoice_id = ?");
            $stmtOldItems->execute([$id]);
            $oldItems = $stmtOldItems->fetchAll();

            $oldItemsMap = [];
            foreach ($oldItems as $oi) {
                $oldItemsMap[$oi['product_id']] = $oi;
            }

            $stmtStockIn = $this->db->prepare("INSERT INTO stock_movements (product_id, type, quantity, reference_type, reference_id) VALUES (?, 'IN', ?, 'Invoice Return', ?)");
            $stmtStockOut = $this->db->prepare("INSERT INTO stock_movements (product_id, type, quantity, reference_type, reference_id) VALUES (?, 'OUT', ?, 'Invoice Edit', ?)");
            $stmtUpdateStock = $this->db->prepare("UPDATE products SET quantity = quantity + ? WHERE id = ?"); 
            
            $primaryDepotStmt = $this->db->query("SELECT id FROM depots WHERE is_primary = TRUE LIMIT 1");
            $primaryDepotId = $primaryDepotStmt->fetchColumn();
            
            if ($primaryDepotId) {
                $stmtUpdateDepotStock = $this->db->prepare("UPDATE product_depots SET quantity = quantity + ? WHERE product_id = ? AND depot_id = ?");
            }

            $this->db->prepare("DELETE FROM invoice_items WHERE invoice_id = ?")->execute([$id]);

            $subtotal = 0;
            $totalTva = 0;

            $stmtInsertItem = $this->db->prepare("
                INSERT INTO invoice_items (invoice_id, product_id, reference, quantity, cost_price, tva, total_price)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ");

            foreach ($newItems as $item) {
                $prodId = $item['product_id'] ?? $item['id'];
                $qty = $item['quantity'];
                
                $oldQty = isset($oldItemsMap[$prodId]) ? $oldItemsMap[$prodId]['quantity'] : 0;
                $deltaQty = $oldQty - $qty; 

                if ($deltaQty > 0) {
                    $stmtUpdateStock->execute([$deltaQty, $prodId]);
                    if ($primaryDepotId) $stmtUpdateDepotStock->execute([$deltaQty, $prodId, $primaryDepotId]);
                    $stmtStockIn->execute([$prodId, $deltaQty, $id]);
                } elseif ($deltaQty < 0) {
                    $taken = abs($deltaQty);
                    $stockCheck = $this->db->prepare("SELECT quantity FROM products WHERE id = ?");
                    $stockCheck->execute([$prodId]);
                    if ($stockCheck->fetchColumn() < $taken) {
                        throw new Exception("Not enough stock for product ID $prodId");
                    }
                    $stmtUpdateStock->execute([$deltaQty, $prodId]); 
                    if ($primaryDepotId) $stmtUpdateDepotStock->execute([$deltaQty, $prodId, $primaryDepotId]);
                    $stmtStockOut->execute([$prodId, $taken, $id]);
                }

                if (isset($oldItemsMap[$prodId])) {
                    unset($oldItemsMap[$prodId]);
                }

                $costPrice = $item['cost_price'] ?? 0;
                $itemTvaAmount = $costPrice * (($item['tva'] ?? 0) / 100);
                $itemTotalPrice = ($costPrice + $itemTvaAmount) * $qty;

                $subtotal += $costPrice * $qty;
                $totalTva += $itemTvaAmount * $qty;

                $stmtInsertItem->execute([
                    $id,
                    $prodId,
                    $item['reference'] ?? null,
                    $qty,
                    $costPrice,
                    $item['tva'] ?? 0,
                    $itemTotalPrice
                ]);
            }

            foreach ($oldItemsMap as $prodId => $oldItem) {
                $stmtUpdateStock->execute([$oldItem['quantity'], $prodId]);
                if ($primaryDepotId) $stmtUpdateDepotStock->execute([$oldItem['quantity'], $prodId, $primaryDepotId]);
                $stmtStockIn->execute([$prodId, $oldItem['quantity'], $id]);
            }

            $finalAmount = ($subtotal + $totalTva) - $discount;
            $oldFinalAmount = $invoice['final_amount'];
            $diffAmount = $finalAmount - $oldFinalAmount;

            $stmtUpdateInv = $this->db->prepare("
                UPDATE invoices 
                SET subtotal = ?, total_tva = ?, discount = ?, final_amount = ? 
                WHERE id = ?
            ");
            $stmtUpdateInv->execute([$subtotal, $totalTva, $discount, $finalAmount, $id]);

            if ($invoice['customer_type'] !== 'Walk-In' && $invoice['customer_id'] && $diffAmount != 0) {
                $this->db->prepare("UPDATE expenses SET amount = amount + ? WHERE reference_id = ?")
                         ->execute([$diffAmount, $invoice['invoice_number']]);

                if ($invoice['customer_type'] === 'Construction') {
                    $this->db->prepare("UPDATE constructions SET actual_cost = actual_cost + ? WHERE id = ?")
                             ->execute([$diffAmount, $invoice['customer_id']]);
                }
            }

            AuditLogger::log($user['user_id'], 'Update POS Invoice', 'invoice', $id, "Updated invoice {$invoice['invoice_number']} (Diff: $diffAmount)");

            $this->db->commit();
            echo json_encode(['message' => 'Invoice updated successfully', 'invoice_id' => $id, 'invoice_number' => $invoice['invoice_number']]);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(400);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }
}
