<?php
require_once 'd:\xamp\htdocs\Bitar\backend\core\Database.php';
$db = Database::getInstance()->getConnection();
$db->query("UPDATE generator_daily_reports SET efficiency_score = kwh_produced / actual_fuel_used WHERE actual_fuel_used > 0 AND efficiency_score IS NULL");

$stmt = $db->query("SELECT id, date, kwh_produced, actual_fuel_used, efficiency_score FROM generator_daily_reports WHERE generator_id = 12 ORDER BY date DESC LIMIT 5");
print_r($stmt->fetchAll(PDO::FETCH_ASSOC));
