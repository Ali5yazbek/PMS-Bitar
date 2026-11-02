<?php
require_once 'd:\xamp\htdocs\Bitar\backend\core\Database.php';
$db = Database::getInstance()->getConnection();
$stmt = $db->query("SELECT * FROM daily_logs WHERE calculated_hours_worked > 24 ORDER BY id DESC LIMIT 20");
$logs = $stmt->fetchAll(PDO::FETCH_ASSOC);
print_r($logs);
