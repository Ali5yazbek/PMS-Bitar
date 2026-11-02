<?php
/**
 * Enterprise Operations Center — Database Migration
 * Creates tables for user sessions and global activity logging.
 *
 * Run once: php migrate_operations_center.php
 */

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/core/Database.php';

$db = Database::getInstance()->getConnection();
$created = []; $errors = [];

$tables = [

// ── 1. User Sessions ───────────────────────────────────────────────────────
'user_sessions' => "
  CREATE TABLE IF NOT EXISTS `user_sessions` (
    `id`             INT AUTO_INCREMENT PRIMARY KEY,
    `user_id`        INT NOT NULL,
    `session_token`  VARCHAR(255) NOT NULL,
    `ip_address`     VARCHAR(45) NULL,
    `user_agent`     VARCHAR(255) NULL,
    `login_time`     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `last_activity`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `current_page`   VARCHAR(150) NULL,
    `current_action` VARCHAR(255) NULL,
    `unsaved_changes` TINYINT(1) NOT NULL DEFAULT 0,
    `status`         ENUM('online','idle','offline') NOT NULL DEFAULT 'online',
    UNIQUE KEY `uq_user_session` (`user_id`, `session_token`),
    INDEX `idx_last_activity` (`last_activity`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci",

// ── 2. Enterprise Activity Log ─────────────────────────────────────────────
'enterprise_activity_log' => "
  CREATE TABLE IF NOT EXISTS `enterprise_activity_log` (
    `id`             INT AUTO_INCREMENT PRIMARY KEY,
    `user_id`        INT NULL,
    `user_name`      VARCHAR(100) NULL,
    `role`           VARCHAR(50) NULL,
    `department`     VARCHAR(100) NULL,
    `action`         VARCHAR(100) NOT NULL COMMENT 'created, edited, deleted, approved, exported, logged_in, etc',
    `module`         VARCHAR(100) NOT NULL COMMENT 'tenants, contracts, generators, auth, etc',
    `record_id`      VARCHAR(100) NULL,
    `description`    TEXT NULL,
    `status`         ENUM('success','warning','error') NOT NULL DEFAULT 'success',
    `ip_address`     VARCHAR(45) NULL,
    `device_info`    VARCHAR(255) NULL,
    `created_at`     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_user_module` (`user_id`, `module`),
    INDEX `idx_created_at` (`created_at`),
    INDEX `idx_action` (`action`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci"

];

foreach ($tables as $name => $sql) {
    try {
        $db->exec($sql);
        $created[] = $name;
    } catch (PDOException $e) {
        $errors[] = "$name: " . $e->getMessage();
    }
}

// Ensure the tables actually exist
foreach (array_keys($tables) as $name) {
    try {
        $db->query("SELECT 1 FROM `$name` LIMIT 1");
    } catch (Exception $e) {
        if (!in_array($name, $errors)) {
            $errors[] = "$name check failed: " . $e->getMessage();
            $created = array_diff($created, [$name]);
        }
    }
}

echo "✅ Created/verified tables: " . implode(", ", $created) . "\n";
if (!empty($errors)) {
    echo "❌ Errors:\n" . implode("\n", $errors) . "\n";
} else {
    echo "🎉 Operations Center Migration Complete!\n";
}
