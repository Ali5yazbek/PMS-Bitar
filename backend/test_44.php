<?php
require_once 'd:\xamp\htdocs\Bitar\backend\core\Database.php';
$db = Database::getInstance()->getConnection();
$stmt = $db->query("SELECT * FROM daily_logs WHERE id = 44");
print_r($stmt->fetch(PDO::FETCH_ASSOC));
$stmt2 = $db->query("SELECT * FROM daily_logs ORDER BY id DESC LIMIT 5");
print_r($stmt2->fetchAll(PDO::FETCH_ASSOC));
