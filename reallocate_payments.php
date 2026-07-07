<?php
require_once __DIR__ . '/backend/core/Database.php';

$db = Database::getInstance()->getConnection();

$payments = $db->query("SELECT * FROM supplier_payments")->fetchAll();

foreach ($payments as $pay) {
    $payId = $pay['id'];
    $amount = floatval($pay['amount']);
    $supplierId = $pay['supplier_id'];
    
    // How much is already allocated?
    $stmtAlloc = $db->prepare("SELECT SUM(amount) FROM supplier_payment_allocations WHERE payment_id = ?");
    $stmtAlloc->execute([$payId]);
    $allocated = floatval($stmtAlloc->fetchColumn());
    
    $remaining = $amount - $allocated;
    
    if ($remaining > 0) {
        $stmtUnpaid = $db->prepare("SELECT id, remaining_balance FROM purchase_orders WHERE supplier_id = ? AND remaining_balance > 0 ORDER BY due_date ASC, created_at ASC");
        $stmtUnpaid->execute([$supplierId]);
        $unpaidPOs = $stmtUnpaid->fetchAll();
        
        foreach ($unpaidPOs as $po) {
            if ($remaining <= 0) break;
            
            $payAmt = min($remaining, floatval($po['remaining_balance']));
            
            $insAlloc = $db->prepare("INSERT INTO supplier_payment_allocations (payment_id, purchase_order_id, amount) VALUES (?, ?, ?)");
            $insAlloc->execute([$payId, $po['id'], $payAmt]);
            
            $updPO = $db->prepare("UPDATE purchase_orders SET amount_paid = amount_paid + ?, remaining_balance = remaining_balance - ? WHERE id = ?");
            $updPO->execute([$payAmt, $payAmt, $po['id']]);
            
            $db->exec("UPDATE purchase_orders SET payment_status = CASE WHEN remaining_balance <= 0 THEN 'Paid' ELSE 'Partially Paid' END WHERE id = " . intval($po['id']));
            
            $remaining -= $payAmt;
        }
    }
}
echo "Reallocation complete.\n";
