<?php
require_once __DIR__ . '/backend/core/Database.php';
$db = Database::getInstance()->getConnection();

echo "Contracts in galaxy building:\n";
$stmt = $db->query("SELECT c.id as contract_id, c.status as contract_status, a.id as apt_id, a.code as apt_code, a.monthly_rent as apt_rent, c.monthly_rent as contract_rent FROM contracts c JOIN apartments a ON a.id = c.apartment_id JOIN buildings b ON b.id = a.building_id WHERE b.name = 'galaxy'");
print_r($stmt->fetchAll(PDO::FETCH_ASSOC));

echo "\nRent Invoices for galaxy building:\n";
$stmt = $db->query("SELECT ri.id as invoice_id, ri.contract_id, ri.amount, ri.due_date, ri.status FROM rent_invoices ri JOIN contracts c ON c.id = ri.contract_id JOIN apartments a ON a.id = c.apartment_id JOIN buildings b ON b.id = a.building_id WHERE b.name = 'galaxy'");
print_r($stmt->fetchAll(PDO::FETCH_ASSOC));
