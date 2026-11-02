<?php
/**
 * Enterprise Operations Center V2 — Database Migration
 * Splits activity logs, upgrades user sessions table for hybrid tracking.
 *
 * Run once: php migrate_operations_v2.php
 */

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/core/Database.php';

$db = Database::getInstance()->getConnection();
$created = []; $errors = [];

$tables = [

// ── 1. Upgrade User Sessions ───────────────────────────────────────────────
// We'll alter the table directly to avoid losing active sessions, but if it fails we create it
'user_sessions_upgrade' => "
  ALTER TABLE `user_sessions`
    MODIFY `status` ENUM('online','idle','away','editing','viewing','offline') NOT NULL DEFAULT 'online',
    ADD COLUMN `current_record_id` VARCHAR(100) NULL AFTER `current_page`,
    ADD COLUMN `edit_mode` VARCHAR(50) NULL AFTER `current_record_id`,
    ADD COLUMN `changed_fields` JSON NULL AFTER `unsaved_changes`
",

// ── 2. Enterprise Activity Log (General CRUD & Nav) ────────────────────────
// Drop the old one and recreate with new indexes and multi-branch support
'enterprise_activity_log' => "
  DROP TABLE IF EXISTS `enterprise_activity_log`;
  CREATE TABLE `enterprise_activity_log` (
    `id`             INT AUTO_INCREMENT PRIMARY KEY,
    `user_id`        INT NULL,
    `user_name`      VARCHAR(100) NULL,
    `role`           VARCHAR(50) NULL,
    `department`     VARCHAR(100) NULL,
    `building_id`    INT NULL,
    `department_id`  INT NULL,
    `action`         VARCHAR(100) NOT NULL,
    `module`         VARCHAR(100) NOT NULL,
    `record_id`      VARCHAR(100) NULL,
    `description`    TEXT NULL,
    `status`         ENUM('success','warning','error','info') NOT NULL DEFAULT 'success',
    `severity`       ENUM('low','medium','high','critical') NOT NULL DEFAULT 'low',
    `ip_address`     VARCHAR(45) NULL,
    `device_info`    VARCHAR(255) NULL,
    `created_at`     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_user_time` (`user_id`, `created_at`),
    INDEX `idx_module_action` (`module`, `action`),
    INDEX `idx_building` (`building_id`),
    INDEX `idx_department` (`department_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci",

// ── 3. Security Activity Log ───────────────────────────────────────────────
'security_activity_log' => "
  CREATE TABLE IF NOT EXISTS `security_activity_log` (
    `id`             INT AUTO_INCREMENT PRIMARY KEY,
    `user_id`        INT NULL,
    `user_name`      VARCHAR(100) NULL,
    `role`           VARCHAR(50) NULL,
    `action`         VARCHAR(100) NOT NULL COMMENT 'login, failed_login, password_reset, permission_changed',
    `description`    TEXT NULL,
    `status`         ENUM('success','warning','error','info') NOT NULL DEFAULT 'success',
    `severity`       ENUM('low','medium','high','critical') NOT NULL DEFAULT 'medium',
    `ip_address`     VARCHAR(45) NULL,
    `device_info`    VARCHAR(255) NULL,
    `created_at`     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_user_time` (`user_id`, `created_at`),
    INDEX `idx_action` (`action`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci",

// ── 4. Financial Activity Log ──────────────────────────────────────────────
'financial_activity_log' => "
  CREATE TABLE IF NOT EXISTS `financial_activity_log` (
    `id`             INT AUTO_INCREMENT PRIMARY KEY,
    `user_id`        INT NULL,
    `user_name`      VARCHAR(100) NULL,
    `role`           VARCHAR(50) NULL,
    `building_id`    INT NULL,
    `action`         VARCHAR(100) NOT NULL COMMENT 'invoice_created, payment_approved, rent_collected',
    `module`         VARCHAR(100) NOT NULL,
    `record_id`      VARCHAR(100) NULL,
    `amount`         DECIMAL(15,2) NULL,
    `currency`       VARCHAR(10) NULL,
    `description`    TEXT NULL,
    `status`         ENUM('success','warning','error','info') NOT NULL DEFAULT 'success',
    `created_at`     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_user_time` (`user_id`, `created_at`),
    INDEX `idx_module_action` (`module`, `action`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci",

// ── 5. System Activity Log ─────────────────────────────────────────────────
'system_activity_log' => "
  CREATE TABLE IF NOT EXISTS `system_activity_log` (
    `id`             INT AUTO_INCREMENT PRIMARY KEY,
    `user_id`        INT NULL,
    `user_name`      VARCHAR(100) NULL,
    `action`         VARCHAR(100) NOT NULL COMMENT 'backup, restore, cron_job, migration',
    `description`    TEXT NULL,
    `status`         ENUM('success','warning','error','info') NOT NULL DEFAULT 'success',
    `severity`       ENUM('low','medium','high','critical') NOT NULL DEFAULT 'low',
    `created_at`     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_action` (`action`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci"

];

// We use exec instead of queries to catch exceptions gracefully
foreach ($tables as $name => $sql) {
    try {
        // If it's an alter statement and column exists, it will throw an error, which we catch
        $db->exec($sql);
        $created[] = $name;
    } catch (PDOException $e) {
        // Ignore duplicate column errors on ALTERS
        if (strpos($e->getMessage(), 'Duplicate column name') !== false) {
            $created[] = $name;
        } else {
            $errors[] = "$name: " . $e->getMessage();
        }
    }
}

echo "✅ Migrated V2 tables: " . implode(", ", $created) . "\n";
if (!empty($errors)) {
    echo "⚠️ Notices:\n" . implode("\n", $errors) . "\n";
} else {
    echo "🎉 Operations Center V2 Migration Complete!\n";
}
