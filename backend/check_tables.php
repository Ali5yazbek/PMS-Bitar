<?php
require_once __DIR__ . '/core/Database.php';
$db = Database::getInstance()->getConnection();
print_r($db->query("SELECT * FROM daily_logs LIMIT 1")->fetch(PDO::FETCH_ASSOC));
