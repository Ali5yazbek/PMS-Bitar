<?php
require 'config.php';
require 'core/Database.php';
$db = Database::getInstance()->getConnection();
$stmt = $db->query("SELECT id, type, amount, amount_paid, status, due_date FROM electricity_invoices WHERE apartment_id = 1");
$results = $stmt->fetchAll(PDO::FETCH_ASSOC);
echo json_encode($results, JSON_PRETTY_PRINT);
