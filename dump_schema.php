<?php
require_once __DIR__ . '/backend/core/Database.php';
$db = Database::getInstance()->getConnection();
$tables = ['apartments', 'electricity_subscriptions', 'electricity_invoices', 'tenants', 'users', 'notifications', 'contracts'];
foreach($tables as $t) {
    try {
        $stmt = $db->query("SHOW CREATE TABLE $t");
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        echo $row['Create Table'] . "\n\n";
    } catch (Exception $e) {
        echo "Table $t not found\n\n";
    }
}
