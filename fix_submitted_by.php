<?php
require 'backend/config.php';
require 'backend/core/Database.php';
$db = Database::getInstance()->getConnection();

$db->query("UPDATE generator_daily_reports SET submitted_by = 5 WHERE submitted_by IS NULL OR submitted_by = 1");
$db->query("UPDATE electricity_meter_readings SET submitted_by = 5 WHERE submitted_by IS NULL OR submitted_by = 1");
$db->query("UPDATE agent_subscription_readings SET submitted_by = 5 WHERE submitted_by IS NULL OR submitted_by = 1");
echo "Updated submitted_by for hassan haded\n";
