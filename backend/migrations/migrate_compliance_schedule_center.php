<?php
/**
 * migrate_compliance_schedule_center.php
 * Database migration for Automated Property Operations & Compliance Calendar
 */

require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../core/Database.php';

try {
    $db = Database::getInstance()->getConnection();
    echo "Connected to database: " . DB_NAME . "\n";
    echo "Starting migration for Automated Compliance Calendar...\n\n";

    // 1. Update `tasks` table columns
    echo "1. Checking and enhancing `tasks` table...\n";
    
    // Modify `type` enum to varchar(50) or expand enum so it supports all operational categories
    $db->exec("ALTER TABLE `tasks` MODIFY COLUMN `type` VARCHAR(50) NOT NULL DEFAULT 'Maintenance'");
    echo "  [OK] Modified tasks.type to VARCHAR(50).\n";

    // Check existing columns in tasks
    $colsStmt = $db->query("SHOW COLUMNS FROM `tasks`");
    $existingCols = [];
    while ($col = $colsStmt->fetch(PDO::FETCH_ASSOC)) {
        $existingCols[] = $col['Field'];
    }

    $newCols = [
        'building_id' => "INT(11) NULL AFTER `assigned_to`",
        'apartment_id' => "INT(11) NULL AFTER `building_id`",
        'is_recurring' => "TINYINT(1) DEFAULT 0 AFTER `apartment_id`",
        'recurrence_rule' => "VARCHAR(50) NULL AFTER `is_recurring`",
        'completion_notes' => "TEXT NULL AFTER `priority`",
        'meter_reading' => "DECIMAL(10,2) NULL AFTER `completion_notes`",
        'fuel_level' => "DECIMAL(10,2) NULL AFTER `meter_reading`",
        'proof_image_path' => "VARCHAR(255) NULL AFTER `fuel_level`",
        'parts_used' => "TEXT NULL AFTER `proof_image_path`",
        'estimated_cost' => "DECIMAL(10,2) DEFAULT 0.00 AFTER `parts_used`",
        'actual_cost' => "DECIMAL(10,2) DEFAULT 0.00 AFTER `estimated_cost`",
        'verified_by' => "INT(11) NULL AFTER `actual_cost`",
        'verified_at' => "DATETIME NULL AFTER `verified_by`",
        'cancellation_reason' => "TEXT NULL AFTER `verified_at`",
        'cancelled_by' => "INT(11) NULL AFTER `cancellation_reason`",
        'cancelled_at' => "DATETIME NULL AFTER `cancelled_by`",
        'schedule_key' => "VARCHAR(120) NULL AFTER `cancelled_at`"
    ];

    foreach ($newCols as $colName => $colDef) {
        if (!in_array($colName, $existingCols)) {
            $db->exec("ALTER TABLE `tasks` ADD COLUMN `$colName` $colDef");
            echo "  [OK] Added column tasks.$colName.\n";
        } else {
            echo "  [SKIP] Column tasks.$colName already exists.\n";
        }
    }

    // Add unique key on schedule_key if not exists
    $idxStmt = $db->query("SHOW INDEX FROM `tasks` WHERE Key_name = 'uq_tasks_schedule_key'")->fetchAll();
    if (empty($idxStmt)) {
        $db->exec("ALTER TABLE `tasks` ADD UNIQUE KEY `uq_tasks_schedule_key` (`schedule_key`)");
        echo "  [OK] Added UNIQUE KEY uq_tasks_schedule_key.\n";
    }

    // 2. Create `recurring_operation_schedules` table
    echo "\n2. Creating `recurring_operation_schedules` table...\n";
    $db->exec("
        CREATE TABLE IF NOT EXISTS `recurring_operation_schedules` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `name` VARCHAR(150) NOT NULL,
            `category` ENUM('rent', 'electricity', 'maintenance', 'generator', 'inspection') NOT NULL,
            `target_type` ENUM('all_generators', 'generator', 'all_active_subscriptions', 'subscription', 'all_apartments', 'apartment', 'all_buildings', 'building') NOT NULL,
            `target_id` INT(11) NULL,
            `frequency` ENUM('daily', 'weekly', 'monthly', 'quarterly', 'yearly', 'on_billing_date') NOT NULL DEFAULT 'daily',
            `day_of_month` INT(11) NULL,
            `day_of_week` INT(11) NULL,
            `default_assigned_to` INT(11) NULL,
            `priority` ENUM('Low', 'Normal', 'High', 'Urgent') DEFAULT 'Normal',
            `requires_proof` TINYINT(1) DEFAULT 1,
            `is_active` TINYINT(1) DEFAULT 1,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_cat_target` (`category`, `target_type`, `is_active`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ");
    echo "  [OK] `recurring_operation_schedules` table verified.\n";

    // Seed default recurring schedules if empty
    $schedCount = $db->query("SELECT COUNT(*) FROM `recurring_operation_schedules`")->fetchColumn();
    if ($schedCount == 0) {
        $db->exec("
            INSERT INTO `recurring_operation_schedules` 
            (`name`, `category`, `target_type`, `frequency`, `priority`, `requires_proof`, `is_active`)
            VALUES
            ('Daily Generator Fuel & Run Check', 'generator', 'all_generators', 'daily', 'High', 1, 1),
            ('Monthly Generator Preventative Servicing', 'generator', 'all_generators', 'monthly', 'Urgent', 1, 1),
            ('Electricity Subscription Renewal & Meter Audit', 'electricity', 'all_active_subscriptions', 'on_billing_date', 'High', 1, 1),
            ('Quarterly Preventative AC Maintenance', 'maintenance', 'all_apartments', 'quarterly', 'Normal', 1, 1),
            ('Building Fire & Life Safety Inspection', 'maintenance', 'all_buildings', 'monthly', 'High', 1, 1)
        ");
        echo "  [OK] Seeded 5 core default recurring schedules.\n";
    }

    // 3. Create `missed_task_exceptions` table for missed-task accountability
    echo "\n3. Creating `missed_task_exceptions` table...\n";
    $db->exec("
        CREATE TABLE IF NOT EXISTS `missed_task_exceptions` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `schedule_id` INT(11) NULL,
            `category` VARCHAR(50) NOT NULL,
            `target_type` VARCHAR(50) NOT NULL,
            `target_id` INT(11) NOT NULL,
            `title` VARCHAR(255) NOT NULL,
            `due_date` DATE NOT NULL,
            `detected_at` DATETIME NOT NULL,
            `responsible_role` VARCHAR(50) DEFAULT 'agent',
            `responsible_user_id` INT(11) NULL,
            `status` ENUM('detected', 'acknowledged', 'escalated', 'repaired', 'exempted') DEFAULT 'detected',
            `repair_task_id` INT(11) NULL,
            `exemption_reason` TEXT NULL,
            `resolved_by` INT(11) NULL,
            `resolved_at` DATETIME NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `uq_exception_target_date` (`category`, `target_type`, `target_id`, `due_date`),
            KEY `idx_status_due` (`status`, `due_date`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ");
    echo "  [OK] `missed_task_exceptions` table verified.\n";

    // 4. Register in `scheduled_jobs`
    echo "\n4. Ensuring `Operations & Compliance Scheduler` job registered...\n";
    $jobCheck = $db->prepare("SELECT id FROM scheduled_jobs WHERE job_name = ?");
    $jobCheck->execute(['Operations & Compliance Scheduler']);
    if (!$jobCheck->fetch()) {
        $ins = $db->prepare("INSERT INTO scheduled_jobs (job_name, status, last_run) VALUES (?, 'Pending', NULL)");
        $ins->execute(['Operations & Compliance Scheduler']);
        echo "  [OK] Registered 'Operations & Compliance Scheduler' job.\n";
    } else {
        echo "  [OK] 'Operations & Compliance Scheduler' job already registered.\n";
    }

    echo "\nMigration completed successfully! All data and existing tables preserved.\n";

} catch (Exception $e) {
    echo "\nMigration error: " . $e->getMessage() . "\n";
    echo $e->getTraceAsString();
    exit(1);
}
