<?php
/**
 * Migration: Create generator_daily_reports table
 * Run this once on the live server to fix the 500 error.
 *
 * Error fixed:
 *   SQLSTATE[42S02]: Base table or view not found: 1146
 *   Table 'u951921938_bitar_pms.generator_daily_reports' does not exist
 */

require_once __DIR__ . '/core/Database.php';


try {
    $db = Database::getInstance()->getConnection();


    echo "<pre>";
    echo "=== generator_daily_reports Migration ===\n\n";

    // 1. Create the table if it does not already exist
    $sql = "
CREATE TABLE IF NOT EXISTS `generator_daily_reports` (
  `id`                        int(11)         NOT NULL AUTO_INCREMENT,
  `generator_id`              int(11)         NOT NULL,
  `date`                      date            NOT NULL,
  `fuel_added`                decimal(10,2)   NOT NULL DEFAULT 0.00,
  `expected_fuel_used`        decimal(10,2)   DEFAULT 0.00,
  `cost_per_liter`            decimal(10,2)   NOT NULL DEFAULT 0.00,
  `fuel_remaining`            decimal(10,2)   NOT NULL DEFAULT 0.00,
  `spare_remaining`           decimal(10,2)   NOT NULL DEFAULT 0.00,
  `running_hours`             decimal(10,2)   NOT NULL DEFAULT 0.00,
  `meter_hours`               decimal(10,2)   DEFAULT 0.00,
  `kwh_produced`              decimal(10,2)   NOT NULL DEFAULT 0.00,
  `notes`                     text            DEFAULT NULL,
  `discrepancy_reason`        text            DEFAULT NULL,
  `photo_path`                varchar(255)    DEFAULT NULL,
  `submitted_by`              int(11)         DEFAULT NULL,
  `created_at`                timestamp       NOT NULL DEFAULT current_timestamp(),
  `previous_kwh`              decimal(10,2)   DEFAULT NULL,
  `current_kwh`               decimal(10,2)   DEFAULT NULL,
  `efficiency_score`          decimal(10,2)   DEFAULT NULL,
  `alert_level`               enum('Normal','Warning','Critical') DEFAULT 'Normal',
  `load_percentage`           decimal(5,2)    DEFAULT NULL,
  `outages_count`             int(11)         DEFAULT 0,
  `expected_fuel_consumption` decimal(10,2)   DEFAULT NULL,
  `actual_fuel_consumption`   decimal(10,2)   DEFAULT NULL,
  `fuel_consumption_per_hour` decimal(10,2)   DEFAULT NULL,
  `fuel_consumption_per_kwh`  decimal(10,2)   DEFAULT NULL,
  `cost_of_electricity`       decimal(10,2)   DEFAULT NULL,
  `fuel_variance`             decimal(10,2)   DEFAULT NULL,
  `estimated_days_empty`      decimal(10,2)   DEFAULT NULL,
  `photo_meter_path`          varchar(255)    DEFAULT NULL,
  `actual_fuel_remaining`     decimal(10,2)   DEFAULT NULL,
  `estimated_fuel_remaining`  decimal(10,2)   DEFAULT NULL,
  `estimated_fuel_used`       decimal(10,2)   DEFAULT NULL,
  `actual_fuel_used`          decimal(10,2)   DEFAULT NULL,
  `fuel_difference`           decimal(10,2)   DEFAULT NULL,
  `status`                    enum('Pending Verification','Verified','Flagged','Rejected') DEFAULT 'Pending Verification',
  `previous_meter_hours`      decimal(10,2)   DEFAULT 0.00,
  `current_meter_hours`       decimal(10,2)   DEFAULT 0.00,
  `liters_per_hour`           decimal(10,2)   DEFAULT 0.00,
  `liters_per_kwh`            decimal(10,2)   DEFAULT 0.00,
  `rejection_reason`          text            DEFAULT NULL,
  `submitted_at`              datetime        DEFAULT current_timestamp(),
  `approved_at`               datetime        DEFAULT NULL,
  `rejected_at`               datetime        DEFAULT NULL,
  `approved_by`               int(11)         DEFAULT NULL,
  `fuel_photo_path`           varchar(255)    DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_generator_date` (`generator_id`, `date`),
  KEY `submitted_by` (`submitted_by`),
  CONSTRAINT `generator_daily_reports_ibfk_1`
    FOREIGN KEY (`generator_id`) REFERENCES `generators` (`id`) ON DELETE CASCADE,
  CONSTRAINT `generator_daily_reports_ibfk_2`
    FOREIGN KEY (`submitted_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
";

    $db->exec($sql);
    echo "OK Table generator_daily_reports created (or already exists).\n\n";

    // 2. Safety: ensure columns added by later alter scripts exist
    $extraColumns = [
        "ALTER TABLE `generator_daily_reports` ADD COLUMN IF NOT EXISTS `cost_per_liter`            decimal(10,2) NOT NULL DEFAULT 0.00",
        "ALTER TABLE `generator_daily_reports` ADD COLUMN IF NOT EXISTS `meter_hours`               decimal(10,2) DEFAULT 0.00",
        "ALTER TABLE `generator_daily_reports` ADD COLUMN IF NOT EXISTS `expected_fuel_used`        decimal(10,2) DEFAULT 0.00",
        "ALTER TABLE `generator_daily_reports` ADD COLUMN IF NOT EXISTS `discrepancy_reason`        text DEFAULT NULL",
        "ALTER TABLE `generator_daily_reports` ADD COLUMN IF NOT EXISTS `fuel_photo_path`           varchar(255) NULL",
        "ALTER TABLE `generator_daily_reports` ADD COLUMN IF NOT EXISTS `approved_by`               int(11) NULL",
        "ALTER TABLE `generator_daily_reports` ADD COLUMN IF NOT EXISTS `rejection_reason`          text NULL",
        "ALTER TABLE `generator_daily_reports` ADD COLUMN IF NOT EXISTS `submitted_at`              datetime DEFAULT current_timestamp()",
        "ALTER TABLE `generator_daily_reports` ADD COLUMN IF NOT EXISTS `approved_at`               datetime DEFAULT NULL",
        "ALTER TABLE `generator_daily_reports` ADD COLUMN IF NOT EXISTS `rejected_at`               datetime DEFAULT NULL",
        "ALTER TABLE `generator_daily_reports` ADD COLUMN IF NOT EXISTS `previous_meter_hours`      decimal(10,2) DEFAULT 0.00",
        "ALTER TABLE `generator_daily_reports` ADD COLUMN IF NOT EXISTS `current_meter_hours`       decimal(10,2) DEFAULT 0.00",
        "ALTER TABLE `generator_daily_reports` ADD COLUMN IF NOT EXISTS `liters_per_hour`           decimal(10,2) DEFAULT 0.00",
        "ALTER TABLE `generator_daily_reports` ADD COLUMN IF NOT EXISTS `liters_per_kwh`            decimal(10,2) DEFAULT 0.00",
        "ALTER TABLE `generator_daily_reports` ADD COLUMN IF NOT EXISTS `actual_fuel_remaining`     decimal(10,2) DEFAULT NULL",
        "ALTER TABLE `generator_daily_reports` ADD COLUMN IF NOT EXISTS `estimated_fuel_remaining`  decimal(10,2) DEFAULT NULL",
        "ALTER TABLE `generator_daily_reports` ADD COLUMN IF NOT EXISTS `estimated_fuel_used`       decimal(10,2) DEFAULT NULL",
        "ALTER TABLE `generator_daily_reports` ADD COLUMN IF NOT EXISTS `actual_fuel_used`          decimal(10,2) DEFAULT NULL",
        "ALTER TABLE `generator_daily_reports` ADD COLUMN IF NOT EXISTS `fuel_difference`           decimal(10,2) DEFAULT NULL",
    ];

    foreach ($extraColumns as $alter) {
        try {
            $db->exec($alter);
            preg_match('/COLUMN IF NOT EXISTS `(\w+)`/', $alter, $m);
            echo "  Column `" . ($m[1] ?? '?') . "` ensured.\n";
        } catch (PDOException $e) {
            preg_match('/COLUMN IF NOT EXISTS `(\w+)`/', $alter, $m);
            echo "  SKIP `" . ($m[1] ?? '?') . "`: " . $e->getMessage() . "\n";
        }
    }

    // 3. Fix status ENUM
    try {
        $db->exec("ALTER TABLE `generator_daily_reports`
            MODIFY COLUMN `status`
            ENUM('Pending Verification','Verified','Flagged','Rejected')
            DEFAULT 'Pending Verification'");
        echo "\nOK ENUM status column verified.\n";
    } catch (PDOException $e) {
        echo "\nWARN Status ENUM: " . $e->getMessage() . "\n";
    }

    // 4. Row count
    $count = $db->query("SELECT COUNT(*) FROM `generator_daily_reports`")->fetchColumn();
    echo "\nRows in generator_daily_reports: {$count}\n";
    echo "\n=== Migration complete ===\n";
    echo "</pre>";

} catch (PDOException $e) {
    http_response_code(500);
    echo "<pre style='color:red'>FAILED:\n" . $e->getMessage() . "</pre>";
}
