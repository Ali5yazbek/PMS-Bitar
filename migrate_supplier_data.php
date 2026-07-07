<?php
require_once __DIR__ . '/backend/core/Database.php';

$db = Database::getInstance()->getConnection();

// 1. Add columns to purchase_orders if they don't exist
try {
    $db->exec("ALTER TABLE purchase_orders ADD COLUMN amount_paid DECIMAL(15,2) DEFAULT 0.00");
} catch (Exception $e) {}
try {
    $db->exec("ALTER TABLE purchase_orders ADD COLUMN remaining_balance DECIMAL(15,2) DEFAULT 0.00");
} catch (Exception $e) {}
try {
    $db->exec("ALTER TABLE purchase_orders ADD COLUMN payment_status VARCHAR(50) DEFAULT 'Unpaid'");
} catch (Exception $e) {}

// 2. Initialize remaining_balance for old POs
$stmt = $db->query("SELECT id, total_price, amount_paid FROM purchase_orders WHERE remaining_balance = 0 AND payment_status = 'Unpaid'");
$uninitialized = $stmt->fetchAll();
foreach ($uninitialized as $po) {
    $remaining = floatval($po['total_price']) - floatval($po['amount_paid']);
    $status = $remaining <= 0 ? 'Paid' : ($po['amount_paid'] > 0 ? 'Partially Paid' : 'Unpaid');
    $upd = $db->prepare("UPDATE purchase_orders SET remaining_balance = ?, payment_status = ? WHERE id = ?");
    $upd->execute([$remaining, $status, $po['id']]);
}

// 3. Clear existing supplier_transactions to rebuild them properly from purchases and payments
$db->exec("TRUNCATE TABLE supplier_transactions");

// 4. Rebuild ledger for each supplier
$suppliers = $db->query("SELECT id, opening_balance, opening_balance_date FROM suppliers")->fetchAll();

foreach ($suppliers as $s) {
    $supplier_id = $s['id'];
    $balance = 0;
    
    // Opening Balance
    if (floatval($s['opening_balance']) > 0) {
        $date = $s['opening_balance_date'] ?: date('Y-m-d');
        $balance += floatval($s['opening_balance']);
        $ins = $db->prepare("INSERT INTO supplier_transactions (supplier_id, type, reference_id, amount, balance_after, transaction_date) VALUES (?, 'Opening Balance', 'OPENING', ?, ?, ?)");
        $ins->execute([$supplier_id, $s['opening_balance'], $balance, $date]);
    }
    
    // Purchases
    $pos = $db->prepare("SELECT id, po_number, total_price, invoice_date, created_at FROM purchase_orders WHERE supplier_id = ? ORDER BY created_at ASC");
    $pos->execute([$supplier_id]);
    $purchases = $pos->fetchAll();
    
    foreach ($purchases as $po) {
        $amount = floatval($po['total_price']);
        if ($amount > 0) {
            $balance += $amount; // Purchase increases debt
            $date = $po['invoice_date'] ?: substr($po['created_at'], 0, 10);
            $ins = $db->prepare("INSERT INTO supplier_transactions (supplier_id, type, reference_id, amount, balance_after, transaction_date) VALUES (?, 'Purchase', ?, ?, ?, ?)");
            $ins->execute([$supplier_id, $po['po_number'], $amount, $balance, $date]);
        }
    }
    
    // Payments
    $pays = $db->prepare("SELECT id, amount, payment_date FROM supplier_payments WHERE supplier_id = ? ORDER BY payment_date ASC, id ASC");
    $pays->execute([$supplier_id]);
    $payments = $pays->fetchAll();
    
    foreach ($payments as $pay) {
        $amount = floatval($pay['amount']);
        if ($amount > 0) {
            $balance -= $amount; // Payment decreases debt
            $ins = $db->prepare("INSERT INTO supplier_transactions (supplier_id, type, reference_id, amount, balance_after, transaction_date) VALUES (?, 'Payment', ?, ?, ?, ?)");
            $ins->execute([$supplier_id, 'PAY-'.$pay['id'], -$amount, $balance, $pay['payment_date']]);
        }
    }
}

echo "Data migration complete.\n";
