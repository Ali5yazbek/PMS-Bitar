<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/core/Database.php';

$db = Database::getInstance()->getConnection();
$stmt = $db->query("SELECT * FROM invoices ORDER BY id DESC LIMIT 1");
$invoice = $stmt->fetch();

$itemStmt = $db->prepare("SELECT i.*, p.name as product_name FROM invoice_items i JOIN products p ON i.product_id = p.id WHERE i.invoice_id = ?");
$itemStmt->execute([$invoice['id']]);
$items = $itemStmt->fetchAll();

echo json_encode(["invoice" => $invoice, "items" => $items]);
