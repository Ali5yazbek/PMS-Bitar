<?php
require_once 'd:\xamp\htdocs\Bitar\backend\core\Database.php';
$db = Database::getInstance()->getConnection();
$stmt = $db->query("SELECT id, date, kwh_produced, estimated_fuel_used, actual_fuel_used, efficiency_score FROM generator_daily_reports WHERE generator_id = 12 ORDER BY date DESC LIMIT 5");
print_r($stmt->fetchAll(PDO::FETCH_ASSOC));
