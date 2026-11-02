<?php
require 'config/database.php';
$db = Database::getInstance()->getConnection();
$stmt = $db->query("SELECT ri.id, ri.invoice_number, ri.amount, ri.status, a.code as apt FROM rent_invoices ri JOIN contracts c ON ri.contract_id = c.id JOIN apartments a ON c.apartment_id = a.id WHERE ri.status != 'Paid'");
print_r($stmt->fetchAll(PDO::FETCH_ASSOC));
