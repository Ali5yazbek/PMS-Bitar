<?php
require 'backend/config.php';
require 'backend/core/Database.php';
$db = Database::getInstance()->getConnection();
$tables = ['generator_daily_reports', 'electricity_meter_readings', 'agent_subscription_readings'];
foreach($tables as $t) {
    $stmt = $db->query("SHOW COLUMNS FROM $t LIKE 'submitted_by'");
    $res = $stmt->fetch(PDO::FETCH_ASSOC);
    echo "$t has submitted_by: " . ($res ? 'YES' : 'NO') . "\n";
}
