<?php
require_once 'd:\xamp\htdocs\Bitar\backend\core\Database.php';
$db = Database::getInstance()->getConnection();
$stmt = $db->query("SELECT * FROM daily_logs ORDER BY id DESC LIMIT 10");
$logs = $stmt->fetchAll(PDO::FETCH_ASSOC);
print_r($logs);
