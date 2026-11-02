<?php
require_once __DIR__ . '/core/Database.php';

try {
    $db = Database::getInstance()->getConnection();
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // 1. Create validation_rules
    $db->exec("CREATE TABLE IF NOT EXISTS `validation_rules` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `module` varchar(100) NOT NULL,
        `field_name` varchar(100) NOT NULL,
        `is_required` tinyint(1) DEFAULT 1,
        `rule_type` varchar(100) DEFAULT NULL,
        `expected_format` varchar(255) DEFAULT NULL,
        `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        UNIQUE KEY `mod_field` (`module`, `field_name`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

    // 2. Alter audit_reports table
    // Change enums to varchar for flexibility
    $db->exec("ALTER TABLE `audit_reports` MODIFY COLUMN `problem_type` VARCHAR(100);");
    $db->exec("ALTER TABLE `audit_reports` MODIFY COLUMN `status` VARCHAR(50) DEFAULT 'Open';");
    
    // Add new columns
    $columnsToAdd = [
        "module_name" => "VARCHAR(100) AFTER department",
        "actual_value" => "TEXT AFTER field_name",
        "expected_value" => "TEXT AFTER actual_value",
        "full_record_json" => "LONGTEXT AFTER description"
    ];

    foreach ($columnsToAdd as $col => $def) {
        try {
            $db->exec("ALTER TABLE `audit_reports` ADD COLUMN `$col` $def");
        } catch (PDOException $e) {
            // Column might already exist
        }
    }

    echo "Data Quality migration completed successfully!\n";
} catch (PDOException $e) {
    echo "Migration Failed: " . $e->getMessage() . "\n";
}
