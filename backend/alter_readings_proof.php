<?php
require_once __DIR__ . '/core/Database.php';
$db = Database::getInstance()->getConnection();

function alterTable($db, $sql) {
    try {
        $db->exec($sql);
        echo "Success: $sql\n";
    } catch (Exception $e) {
        echo "Error: " . $e->getMessage() . "\n";
    }
}

// electricity_meter_readings
alterTable($db, "ALTER TABLE electricity_meter_readings ADD COLUMN photo_path VARCHAR(255) NULL");
alterTable($db, "ALTER TABLE electricity_meter_readings ADD COLUMN status ENUM('Pending Verification', 'Verified', 'Rejected') DEFAULT 'Pending Verification'");
alterTable($db, "ALTER TABLE electricity_meter_readings ADD COLUMN submitted_by INT(11) NULL");
alterTable($db, "ALTER TABLE electricity_meter_readings ADD COLUMN approved_by INT(11) NULL");
alterTable($db, "ALTER TABLE electricity_meter_readings ADD COLUMN rejection_reason TEXT NULL");

// generator_daily_reports
alterTable($db, "ALTER TABLE generator_daily_reports MODIFY COLUMN status ENUM('Pending Verification', 'Verified', 'Flagged', 'Rejected') DEFAULT 'Pending Verification'");
alterTable($db, "ALTER TABLE generator_daily_reports ADD COLUMN fuel_photo_path VARCHAR(255) NULL");
alterTable($db, "ALTER TABLE generator_daily_reports ADD COLUMN approved_by INT(11) NULL");
alterTable($db, "ALTER TABLE generator_daily_reports ADD COLUMN rejection_reason TEXT NULL");

echo "Done.\n";
