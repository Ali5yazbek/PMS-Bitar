<?php
require_once __DIR__ . '/core/Database.php';
$db = Database::getInstance()->getConnection();
$stmt = $db->query("DESCRIBE daily_logs");
print_r($stmt->fetchAll(PDO::FETCH_ASSOC));

$stmt2 = $db->query("DESCRIBE generator_daily_reports");
print_r($stmt2->fetchAll(PDO::FETCH_ASSOC));
