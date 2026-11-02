<?php
require 'core/Database.php';
$db = Database::getInstance()->getConnection();
$stmt = $db->query("SELECT id, invoice_number, status FROM rent_invoices LIMIT 10");
$cols = $stmt->fetchAll(PDO::FETCH_ASSOC);
print_r($cols);
