<?php
require 'config.php';
require 'core/Database.php';
$db = Database::getInstance()->getConnection();
$stmt = $db->query("SELECT id, monthly_rent, start_date, end_date, status FROM contracts ORDER BY id DESC LIMIT 5");
print_r($stmt->fetchAll(PDO::FETCH_ASSOC));
