<?php
// Action Control Report — Database Migration
// Run once: http://localhost/Bitar/backend/migrate_audit_reports.php

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/core/Database.php';

$db = Database::getInstance()->getConnection();
$errors = [];
$created = [];

// ── 1. audit_reports ──────────────────────────────────────────────────────────
try {
    $db->exec("
        CREATE TABLE IF NOT EXISTS `audit_reports` (
            `id`            INT AUTO_INCREMENT PRIMARY KEY,
            `employee_id`   INT NULL COMMENT 'User who owns or is responsible for the record',
            `department`    VARCHAR(100) NULL,
            `table_name`    VARCHAR(100) NOT NULL COMMENT 'tenants | apartments | contracts | workshops',
            `record_id`     INT NOT NULL COMMENT 'PK of the problematic record',
            `field_name`    VARCHAR(150) NOT NULL,
            `problem_type`  ENUM('Missing','Invalid','Expired','Duplicate','Incomplete') NOT NULL DEFAULT 'Missing',
            `severity`      ENUM('critical','warning','info') NOT NULL DEFAULT 'warning',
            `description`   TEXT NOT NULL,
            `status`        ENUM('open','in_progress','pending_review','resolved','rejected') NOT NULL DEFAULT 'open',
            `is_locked`     TINYINT(1) NOT NULL DEFAULT 1 COMMENT '1=locked (only admin can edit), 0=unlocked',
            `assigned_to`   INT NULL COMMENT 'user_id of the assigned manager',
            `unlock_until`  DATETIME NULL,
            `unlock_reason` TEXT NULL,
            `unlocked_by`   INT NULL,
            `created_at`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX `idx_employee` (`employee_id`),
            INDEX `idx_table_record` (`table_name`, `record_id`),
            INDEX `idx_status` (`status`),
            INDEX `idx_severity` (`severity`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ");
    $created[] = 'audit_reports';
} catch (Exception $e) {
    $errors[] = 'audit_reports: ' . $e->getMessage();
}

// ── 2. audit_trail ────────────────────────────────────────────────────────────
try {
    $db->exec("
        CREATE TABLE IF NOT EXISTS `audit_trail` (
            `id`               INT AUTO_INCREMENT PRIMARY KEY,
            `audit_report_id`  INT NOT NULL,
            `user_id`          INT NOT NULL,
            `action`           VARCHAR(100) NOT NULL COMMENT 'detected|unlocked|locked|fixed|submitted|approved|rejected|commented',
            `old_value`        TEXT NULL,
            `new_value`        TEXT NULL,
            `comment`          TEXT NULL,
            `created_at`       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            INDEX `idx_report` (`audit_report_id`),
            INDEX `idx_user` (`user_id`),
            INDEX `idx_created` (`created_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ");
    $created[] = 'audit_trail';
} catch (Exception $e) {
    $errors[] = 'audit_trail: ' . $e->getMessage();
}

// ── 3. audit_scan_runs ────────────────────────────────────────────────────────
try {
    $db->exec("
        CREATE TABLE IF NOT EXISTS `audit_scan_runs` (
            `id`             INT AUTO_INCREMENT PRIMARY KEY,
            `triggered_by`   INT NULL COMMENT 'user_id or NULL for cron',
            `total_found`    INT NOT NULL DEFAULT 0,
            `critical_found` INT NOT NULL DEFAULT 0,
            `warning_found`  INT NOT NULL DEFAULT 0,
            `info_found`     INT NOT NULL DEFAULT 0,
            `duration_ms`    INT NULL,
            `created_at`     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ");
    $created[] = 'audit_scan_runs';
} catch (Exception $e) {
    $errors[] = 'audit_scan_runs: ' . $e->getMessage();
}

// ── Output ────────────────────────────────────────────────────────────────────
header('Content-Type: text/html; charset=utf-8');
echo '<html><body style="font-family:monospace;padding:20px;background:#0f172a;color:#e2e8f0;">';
echo '<h2 style="color:#38bdf8;">🛡️ Action Control Report — Migration</h2>';
if ($created) {
    echo '<p style="color:#4ade80;">✅ Tables created: ' . implode(', ', $created) . '</p>';
}
if ($errors) {
    foreach ($errors as $err) {
        echo '<p style="color:#f87171;">❌ ' . htmlspecialchars($err) . '</p>';
    }
}
if (empty($errors)) {
    echo '<p style="color:#a3e635;">🎉 Migration complete! All tables are ready.</p>';
} else {
    echo '<p style="color:#fb923c;">⚠️ Migration finished with some errors.</p>';
}
echo '</body></html>';
