<?php
require_once __DIR__ . '/core/Database.php';
try {
    $db = Database::getInstance()->getConnection();
    
    // update generator_daily_reports
    $db->exec("ALTER TABLE generator_daily_reports ADD COLUMN meter_hours DECIMAL(10,2) DEFAULT 0 AFTER running_hours");
    $db->exec("ALTER TABLE generator_daily_reports ADD COLUMN expected_fuel_used DECIMAL(10,2) DEFAULT 0 AFTER fuel_added");
    $db->exec("ALTER TABLE generator_daily_reports ADD COLUMN discrepancy_reason TEXT AFTER notes");
    
    // update electricity_subscriptions
    $db->exec("ALTER TABLE electricity_subscriptions ADD COLUMN amps DECIMAL(10,2) DEFAULT 0 AFTER monthly_fee");
    $db->exec("ALTER TABLE electricity_subscriptions ADD COLUMN cost_per_amp DECIMAL(10,2) DEFAULT 0 AFTER amps");

    // update generators
    $db->exec("ALTER TABLE generators ADD COLUMN baseline_fuel_per_hour DECIMAL(10,2) DEFAULT 0 AFTER current_fuel");

    echo "Database schema updated successfully.";
} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}
