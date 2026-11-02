<?php
require 'core/Database.php';
$db = Database::getInstance()->getConnection();
$stmt = $db->query("SHOW COLUMNS FROM rent_invoices");
$cols = $stmt->fetchAll(PDO::FETCH_ASSOC);
foreach($cols as $col) {
    echo $col['Field'] . "\n";
}
