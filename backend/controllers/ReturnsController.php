<?php
class ReturnsController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function processReturn() {
        AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        $userId = $_SESSION['user_id'] ?? null;
        
        $invoiceId = $data['invoice_id'] ?? null;
        $items = $data['items'] ?? []; // Array of ['product_id' => X, 'quantity' => Y, 'price' => Z, 'condition' => 'Good']
        $reason = $data['reason'] ?? '';
        $refundMethod = $data['refund_method'] ?? 'Cash';
        $status = $data['status'] ?? 'Completed';
        $photo = $data['photo'] ?? null;
        $managerApprovalId = $data['manager_approval_id'] ?? null;
        
        if (!$invoiceId || empty($items)) {
            http_response_code(400);
            echo json_encode(['error' => 'Invoice ID and return items are required.']);
            return;
        }
        
        // Handle Base64 Photo Upload
        $photoPath = null;
        if (!empty($photo) && preg_match('/^data:image\/(\w+);base64,/', $photo, $type)) {
            $photoData = substr($photo, strpos($photo, ',') + 1);
            $type = strtolower($type[1]); // jpg, png, gif
            if (in_array($type, ['jpg', 'jpeg', 'png'])) {
                $photoData = base64_decode($photoData);
                if ($photoData !== false) {
                    $uploadDir = __DIR__ . '/../uploads/returns/';
                    if (!is_dir($uploadDir)) mkdir($uploadDir, 0777, true);
                    $filename = 'return_' . time() . '_' . uniqid() . '.' . $type;
                    file_put_contents($uploadDir . $filename, $photoData);
                    $photoPath = '/uploads/returns/' . $filename;
                }
            }
        }
        
        try {
            $this->db->beginTransaction();
            
            // 1. Calculate total refund amount and validate return qty
            $totalRefunded = 0;
            foreach ($items as $item) {
                // Fetch current item details to validate quantity
                $stmtVal = $this->db->prepare("SELECT quantity, returned_qty FROM invoice_items WHERE invoice_id = ? AND product_id = ?");
                $stmtVal->execute([$invoiceId, $item['product_id']]);
                $invItem = $stmtVal->fetch();
                if (!$invItem) {
                    throw new Exception("Product ID " . $item['product_id'] . " not found in this invoice.");
                }
                
                $maxReturnable = $invItem['quantity'] - $invItem['returned_qty'];
                if ($item['quantity'] > $maxReturnable) {
                    throw new Exception("Cannot return more than purchased for product ID " . $item['product_id']);
                }
                
                $totalRefunded += ($item['quantity'] * $item['price']);
            }
            
            // 2. Generate unique return invoice number
            $returnInvoiceNumber = 'RET-' . date('Ymd') . '-' . rand(1000, 9999);
            
            // 3. Insert into returns table
            $stmt = $this->db->prepare("INSERT INTO returns (original_invoice_id, return_invoice_number, date, total_refunded, reason, created_by, status, photo, manager_approval_id, refund_method) VALUES (?, ?, CURDATE(), ?, ?, ?, ?, ?, ?, ?)");
            $stmt->execute([$invoiceId, $returnInvoiceNumber, $totalRefunded, $reason, $userId, $status, $photoPath, $managerApprovalId, $refundMethod]);
            $returnId = $this->db->lastInsertId();
            
            // 4. Process each item: insert to return_items, update product stock ONLY if Good, and update invoice_items returned_qty
            $stmtReturnItem = $this->db->prepare("INSERT INTO return_items (return_id, product_id, quantity, price, return_condition) VALUES (?, ?, ?, ?, ?)");
            $stmtUpdateStock = $this->db->prepare("UPDATE products SET quantity = quantity + ? WHERE id = ?");
            $stmtUpdateInvoiceItem = $this->db->prepare("UPDATE invoice_items SET returned_qty = returned_qty + ? WHERE invoice_id = ? AND product_id = ?");
            
            foreach ($items as $item) {
                $cond = $item['condition'] ?? 'Good';
                $stmtReturnItem->execute([$returnId, $item['product_id'], $item['quantity'], $item['price'], $cond]);
                
                // Only restore stock if condition is Good
                if ($cond === 'Good') {
                    $stmtUpdateStock->execute([$item['quantity'], $item['product_id']]);
                }
                
                // Increment returned_qty in invoice_items
                $stmtUpdateInvoiceItem->execute([$item['quantity'], $invoiceId, $item['product_id']]);
            }
            
            // 5. Update invoice status & returned amount
            $stmtInvoice = $this->db->prepare("SELECT subtotal, total_tva, discount, final_amount, returned_amount FROM invoices WHERE id = ?");
            $stmtInvoice->execute([$invoiceId]);
            $invoice = $stmtInvoice->fetch();
            
            $newReturnedAmount = $invoice['returned_amount'] + $totalRefunded;
            $isFullReturn = ($newReturnedAmount >= ($invoice['final_amount'] - 0.01));
            
            // If the return itself is approved or completed, we update the invoice.
            // If it's pending, maybe we shouldn't mark the invoice as returned yet?
            // Assuming we still record the returned amount.
            $invStatus = $isFullReturn ? 'Returned' : 'Active'; 
            
            $stmtUpdateInvoice = $this->db->prepare("UPDATE invoices SET returned_amount = ?, status = ? WHERE id = ?");
            $stmtUpdateInvoice->execute([$newReturnedAmount, $invStatus, $invoiceId]);
            
            // 6. Log audit with IP and Device
            $ipAddress = $_SERVER['REMOTE_ADDR'] ?? null;
            $device = $_SERVER['HTTP_USER_AGENT'] ?? null;
            
            $oldValues = json_encode(['returned_amount' => $invoice['returned_amount'], 'status' => 'Active']);
            $newValues = json_encode(['returned_amount' => $newReturnedAmount, 'status' => $invStatus, 'return_id' => $returnId, 'return_status' => $status]);
            
            $stmtAudit = $this->db->prepare("INSERT INTO sales_audits (invoice_id, user_id, action, old_values, new_values, reason, ip_address, device) VALUES (?, ?, 'RETURN', ?, ?, ?, ?, ?)");
            $stmtAudit->execute([$invoiceId, $userId, $oldValues, $newValues, $reason, $ipAddress, $device]);
            
            $this->db->commit();
            
            echo json_encode([
                'message' => 'Return processed successfully',
                'return_invoice_number' => $returnInvoiceNumber,
                'total_refunded' => $totalRefunded,
                'status' => $invStatus
            ]);
            
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => 'Failed to process return: ' . $e->getMessage()]);
        }
    }
    
    public function getReturnsHistory($invoiceId) {
        AuthMiddleware::requireLogin();
        try {
            $stmt = $this->db->prepare("
                SELECT r.*, u.username as created_by_name, m.username as manager_name 
                FROM returns r 
                LEFT JOIN users u ON r.created_by = u.id 
                LEFT JOIN users m ON r.manager_approval_id = m.id 
                WHERE r.original_invoice_id = ? 
                ORDER BY r.created_at DESC
            ");
            $stmt->execute([$invoiceId]);
            $returns = $stmt->fetchAll();
            
            foreach ($returns as &$return) {
                $stmtItems = $this->db->prepare("
                    SELECT ri.*, p.name as product_name 
                    FROM return_items ri 
                    LEFT JOIN products p ON ri.product_id = p.id 
                    WHERE ri.return_id = ?
                ");
                $stmtItems->execute([$return['id']]);
                $return['items'] = $stmtItems->fetchAll();
            }
            
            echo json_encode($returns);
            
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => 'Failed to fetch returns: ' . $e->getMessage()]);
        }
    }

    public function updateReturnStatus($returnId) {
        AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        $status = $data['status'] ?? null;
        $managerId = $_SESSION['user_id']; // Assuming manager is doing this

        if (!$status || !in_array($status, ['Approved', 'Rejected', 'Completed'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Invalid status']);
            return;
        }

        try {
            $stmt = $this->db->prepare("UPDATE returns SET status = ?, manager_approval_id = ? WHERE id = ?");
            $stmt->execute([$status, $managerId, $returnId]);
            echo json_encode(['message' => 'Return status updated successfully']);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => 'Update failed: ' . $e->getMessage()]);
        }
    }
}
