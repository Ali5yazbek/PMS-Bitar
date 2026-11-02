<?php
require_once 'd:\xamp\htdocs\Bitar\backend\core\Database.php';
$db = Database::getInstance()->getConnection();
$stmt = $db->query("DESCRIBE generator_daily_reports");
print_r($stmt->fetchAll(PDO::FETCH_ASSOC));
