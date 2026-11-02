<?php
/**
 * Enterprise Control Center — Complete Database Migration
 * Creates all 15 tables for the permission, approval, security,
 * data integrity, and scheduling systems.
 *
 * Run once: http://localhost/Bitar/backend/migrate_enterprise_permissions.php
 */

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/core/Database.php';

$db = Database::getInstance()->getConnection();
$created = []; $errors = [];

$tables = [

// ── 1. Permission Profiles ─────────────────────────────────────────────────
'permission_profiles' => "
  CREATE TABLE IF NOT EXISTS `permission_profiles` (
    `id`          INT AUTO_INCREMENT PRIMARY KEY,
    `name`        VARCHAR(100) NOT NULL,
    `description` TEXT NULL,
    `base_role`   VARCHAR(50) NOT NULL DEFAULT 'manager' COMMENT 'admin|manager|cashier|agent|maintenance|tenant',
    `is_active`   TINYINT(1)  NOT NULL DEFAULT 1,
    `created_by`  INT NULL,
    `created_at`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci",

// ── 2. Page Permissions ────────────────────────────────────────────────────
'page_permissions' => "
  CREATE TABLE IF NOT EXISTS `page_permissions` (
    `id`          INT AUTO_INCREMENT PRIMARY KEY,
    `role`        VARCHAR(50) NOT NULL,
    `page_key`    VARCHAR(100) NOT NULL COMMENT 'dashboard|tenants|apartments|contracts|...',
    `can_view`    TINYINT(1) NOT NULL DEFAULT 1,
    `can_add`     TINYINT(1) NOT NULL DEFAULT 0,
    `can_edit`    TINYINT(1) NOT NULL DEFAULT 0,
    `can_delete`  TINYINT(1) NOT NULL DEFAULT 0,
    `can_print`   TINYINT(1) NOT NULL DEFAULT 1,
    `can_export`  TINYINT(1) NOT NULL DEFAULT 0,
    `can_approve` TINYINT(1) NOT NULL DEFAULT 0,
    `updated_at`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_role_page` (`role`, `page_key`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci",

// ── 3. Button Permissions ──────────────────────────────────────────────────
'button_permissions' => "
  CREATE TABLE IF NOT EXISTS `button_permissions` (
    `id`          INT AUTO_INCREMENT PRIMARY KEY,
    `role`        VARCHAR(50)  NOT NULL,
    `page_key`    VARCHAR(100) NOT NULL,
    `button_key`  VARCHAR(150) NOT NULL,
    `button_label` VARCHAR(200) NULL,
    `is_visible`  TINYINT(1) NOT NULL DEFAULT 1,
    `is_enabled`  TINYINT(1) NOT NULL DEFAULT 1,
    `updated_at`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_role_page_button` (`role`, `page_key`, `button_key`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci",

// ── 4. Field Permissions ───────────────────────────────────────────────────
'field_permissions' => "
  CREATE TABLE IF NOT EXISTS `field_permissions` (
    `id`          INT AUTO_INCREMENT PRIMARY KEY,
    `role`        VARCHAR(50)  NOT NULL,
    `entity`      VARCHAR(100) NOT NULL COMMENT 'tenants|apartments|contracts|workshops|...',
    `field_name`  VARCHAR(150) NOT NULL,
    `field_label` VARCHAR(200) NULL,
    `is_visible`  TINYINT(1) NOT NULL DEFAULT 1,
    `is_editable` TINYINT(1) NOT NULL DEFAULT 1,
    `updated_at`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_role_entity_field` (`role`, `entity`, `field_name`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci",

// ── 5. Menu Permissions ────────────────────────────────────────────────────
'menu_permissions' => "
  CREATE TABLE IF NOT EXISTS `menu_permissions` (
    `id`          INT AUTO_INCREMENT PRIMARY KEY,
    `role`        VARCHAR(50)  NOT NULL,
    `menu_key`    VARCHAR(100) NOT NULL,
    `menu_label`  VARCHAR(200) NULL,
    `is_visible`  TINYINT(1) NOT NULL DEFAULT 1,
    `sort_order`  INT NOT NULL DEFAULT 0,
    `updated_at`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_role_menu` (`role`, `menu_key`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci",

// ── 6. Building Restrictions ───────────────────────────────────────────────
'building_restrictions' => "
  CREATE TABLE IF NOT EXISTS `building_restrictions` (
    `id`          INT AUTO_INCREMENT PRIMARY KEY,
    `user_id`     INT NOT NULL,
    `building_id` INT NOT NULL,
    `can_access`  TINYINT(1) NOT NULL DEFAULT 1,
    `granted_by`  INT NULL,
    `granted_at`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_user_building` (`user_id`, `building_id`),
    INDEX `idx_user` (`user_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci",

// ── 7. Department Restrictions ─────────────────────────────────────────────
'department_restrictions' => "
  CREATE TABLE IF NOT EXISTS `department_restrictions` (
    `id`                INT AUTO_INCREMENT PRIMARY KEY,
    `role`              VARCHAR(50)  NOT NULL,
    `department`        VARCHAR(100) NOT NULL,
    `restricted_module` VARCHAR(100) NOT NULL COMMENT 'workshop|maintenance|warehouse|invoices|...',
    `is_restricted`     TINYINT(1) NOT NULL DEFAULT 0,
    `updated_at`        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_role_dept_module` (`role`, `department`, `restricted_module`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci",

// ── 8. Temporary Permissions ───────────────────────────────────────────────
'temp_permissions' => "
  CREATE TABLE IF NOT EXISTS `temp_permissions` (
    `id`              INT AUTO_INCREMENT PRIMARY KEY,
    `user_id`         INT NOT NULL,
    `granted_by`      INT NOT NULL,
    `permission_type` VARCHAR(100) NOT NULL COMMENT 'edit_contracts|delete_records|view_financial|...',
    `target_table`    VARCHAR(100) NULL,
    `target_id`       INT NULL,
    `expires_at`      DATETIME NOT NULL,
    `reason`          TEXT NULL,
    `is_active`       TINYINT(1) NOT NULL DEFAULT 1,
    `used_at`         DATETIME NULL,
    `created_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_user_active` (`user_id`, `is_active`),
    INDEX `idx_expires` (`expires_at`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci",

// ── 9. Approval Chains ─────────────────────────────────────────────────────
'approval_chains' => "
  CREATE TABLE IF NOT EXISTS `approval_chains` (
    `id`          INT AUTO_INCREMENT PRIMARY KEY,
    `name`        VARCHAR(200) NOT NULL,
    `action_type` VARCHAR(100) NOT NULL COMMENT 'delete_tenant|update_contract|export_financial|...',
    `description` TEXT NULL,
    `is_active`   TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`  INT NULL,
    `created_at`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci",

// ── 10. Approval Chain Steps ───────────────────────────────────────────────
'approval_chain_steps' => "
  CREATE TABLE IF NOT EXISTS `approval_chain_steps` (
    `id`           INT AUTO_INCREMENT PRIMARY KEY,
    `chain_id`     INT NOT NULL,
    `step_order`   INT NOT NULL DEFAULT 1,
    `step_label`   VARCHAR(200) NOT NULL COMMENT 'e.g. Manager Approval',
    `approver_role` VARCHAR(50) NULL,
    `approver_user_id` INT NULL,
    `can_reject`   TINYINT(1) NOT NULL DEFAULT 1,
    `can_delegate` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at`   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_chain` (`chain_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci",

// ── 11. Approval Requests ──────────────────────────────────────────────────
'approval_requests' => "
  CREATE TABLE IF NOT EXISTS `approval_requests` (
    `id`            INT AUTO_INCREMENT PRIMARY KEY,
    `chain_id`      INT NOT NULL,
    `requester_id`  INT NOT NULL,
    `current_step`  INT NOT NULL DEFAULT 1,
    `status`        ENUM('pending','approved','rejected','cancelled') NOT NULL DEFAULT 'pending',
    `record_type`   VARCHAR(100) NULL,
    `record_id`     INT NULL,
    `title`         VARCHAR(300) NOT NULL,
    `reason`        TEXT NULL,
    `data_payload`  JSON NULL COMMENT 'What they want to change',
    `created_at`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `resolved_at`   DATETIME NULL,
    INDEX `idx_status` (`status`),
    INDEX `idx_requester` (`requester_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci",

// ── 12. Approval Request Steps ─────────────────────────────────────────────
'approval_request_steps' => "
  CREATE TABLE IF NOT EXISTS `approval_request_steps` (
    `id`          INT AUTO_INCREMENT PRIMARY KEY,
    `request_id`  INT NOT NULL,
    `chain_step_id` INT NOT NULL,
    `approver_id` INT NULL,
    `status`      ENUM('pending','approved','rejected','skipped') NOT NULL DEFAULT 'pending',
    `comment`     TEXT NULL,
    `acted_at`    DATETIME NULL,
    INDEX `idx_request` (`request_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci",

// ── 13. Security Events ────────────────────────────────────────────────────
'security_events' => "
  CREATE TABLE IF NOT EXISTS `security_events` (
    `id`          INT AUTO_INCREMENT PRIMARY KEY,
    `user_id`     INT NULL,
    `user_name`   VARCHAR(200) NULL,
    `event_type`  VARCHAR(100) NOT NULL COMMENT 'failed_login|bulk_delete|permission_escalation|data_export|...',
    `severity`    ENUM('info','warning','critical') NOT NULL DEFAULT 'info',
    `description` TEXT NOT NULL,
    `ip_address`  VARCHAR(45) NULL,
    `user_agent`  TEXT NULL,
    `metadata`    JSON NULL,
    `created_at`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_event_type` (`event_type`),
    INDEX `idx_severity` (`severity`),
    INDEX `idx_user` (`user_id`),
    INDEX `idx_created` (`created_at`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci",

// ── 14. Data Integrity Issues ──────────────────────────────────────────────
'integrity_issues' => "
  CREATE TABLE IF NOT EXISTS `integrity_issues` (
    `id`            INT AUTO_INCREMENT PRIMARY KEY,
    `issue_type`    VARCHAR(100) NOT NULL COMMENT 'duplicate_national_id|duplicate_phone|orphan_record|broken_relationship|...',
    `severity`      ENUM('critical','warning','info') NOT NULL DEFAULT 'warning',
    `table_name`    VARCHAR(100) NOT NULL,
    `record_id`     INT NOT NULL,
    `duplicate_id`  INT NULL COMMENT 'The other record in a duplicate pair',
    `description`   TEXT NOT NULL,
    `status`        ENUM('open','ignored','merged','resolved') NOT NULL DEFAULT 'open',
    `resolved_by`   INT NULL,
    `created_at`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_issue_type` (`issue_type`),
    INDEX `idx_status` (`status`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci",

// ── 15. Financial Audit Issues ─────────────────────────────────────────────
'financial_audit_issues' => "
  CREATE TABLE IF NOT EXISTS `financial_audit_issues` (
    `id`             INT AUTO_INCREMENT PRIMARY KEY,
    `table_name`     VARCHAR(100) NOT NULL,
    `record_id`      INT NOT NULL,
    `issue_type`     VARCHAR(100) NOT NULL COMMENT 'negative_payment|paid_exceeds_invoice|duplicate_payment|missing_transaction|...',
    `severity`       ENUM('critical','warning','info') NOT NULL DEFAULT 'critical',
    `expected_value` DECIMAL(15,2) NULL,
    `actual_value`   DECIMAL(15,2) NULL,
    `description`    TEXT NOT NULL,
    `status`         ENUM('open','investigating','resolved','false_positive') NOT NULL DEFAULT 'open',
    `created_at`     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_issue_type` (`issue_type`),
    INDEX `idx_status` (`status`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci",

// ── 16. Enterprise Settings ────────────────────────────────────────────────
'enterprise_settings' => "
  CREATE TABLE IF NOT EXISTS `enterprise_settings` (
    `id`          INT AUTO_INCREMENT PRIMARY KEY,
    `setting_key` VARCHAR(100) NOT NULL UNIQUE,
    `value`       TEXT NULL,
    `label`       VARCHAR(200) NULL,
    `category`    VARCHAR(100) NOT NULL DEFAULT 'general',
    `updated_at`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci",

];

foreach ($tables as $name => $sql) {
    try {
        $db->exec($sql);
        $created[] = $name;
    } catch (Exception $e) {
        $errors[] = "$name: " . $e->getMessage();
    }
}

// ── Seed default enterprise settings ──────────────────────────────────────────
$defaults = [
    ['daily_scan_enabled',    '1',     'Enable Daily Audit Scan',      'scheduler'],
    ['daily_scan_time',       '02:00', 'Daily Scan Time',              'scheduler'],
    ['weekly_scan_day',       '0',     'Weekly Scan Day (0=Sunday)',    'scheduler'],
    ['notify_critical_count', '3',     'Notify when critical >= N',    'notifications'],
    ['notify_unresolved_days','30',    'Alert if unresolved > N days', 'notifications'],
    ['sla_critical_hours',    '24',    'SLA hours for critical issues', 'sla'],
    ['sla_warning_hours',     '72',    'SLA hours for warning issues',  'sla'],
    ['auto_fix_enabled',      '0',     'Enable Auto-Fix Suggestions',  'autofix'],
    ['duplicate_scan_enabled','1',     'Enable Duplicate Detection',   'integrity'],
    ['financial_scan_enabled','1',     'Enable Financial Audit',       'integrity'],
];
$settingStmt = $db->prepare("INSERT IGNORE INTO enterprise_settings (setting_key, value, label, category) VALUES (?, ?, ?, ?)");
foreach ($defaults as $d) { $settingStmt->execute($d); }

// ── Seed default page permissions for all roles ────────────────────────────────
$pages = ['dashboard','buildings','apartments','tenants','contracts','rent','insurance','workshop',
          'constructions','suppliers','purchase_orders','sales','energy','generators','fuel_reserve',
          'warehouse','pos','expenses','reports','users','settings','maintenance','action_control'];

$adminPerms    = [1,1,1,1,1,1,1];
$managerPerms  = [1,1,1,1,0,1,0];
$cashierPerms  = [1,1,0,0,0,1,0];

$roleDefaults = [
    'admin'       => $adminPerms,
    'manager'     => $managerPerms,
    'cashier'     => $cashierPerms,
    'agent'       => [1,0,0,0,0,1,0],
    'maintenance' => [1,0,0,0,0,0,0],
    'tenant'      => [1,0,0,0,0,0,0],
];

$pageStmt = $db->prepare("
    INSERT IGNORE INTO page_permissions
    (role, page_key, can_view, can_add, can_edit, can_delete, can_print, can_export, can_approve)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
");
foreach ($roleDefaults as $role => $perms) {
    foreach ($pages as $page) {
        $pageStmt->execute([$role, $page, ...$perms]);
    }
}

// ── Output ────────────────────────────────────────────────────────────────────
header('Content-Type: text/html; charset=utf-8');
?>
<!DOCTYPE html><html>
<head><style>
body{font-family:monospace;padding:24px;background:#0f172a;color:#e2e8f0;max-width:800px;margin:0 auto}
h2{color:#818cf8}.ok{color:#4ade80}.err{color:#f87171}.info{color:#a3e635}
.badge{display:inline-block;padding:2px 8px;border-radius:6px;font-size:12px;margin:2px;background:#1e293b}
</style></head><body>
<h2>🛡️ Enterprise Control Center — Migration</h2>
<?php if ($created): ?>
<p class="ok">✅ Tables created/verified (<?= count($created) ?>):</p>
<div><?php foreach($created as $t) echo "<span class='badge'>$t</span>"; ?></div>
<?php endif; ?>
<?php if ($errors): ?>
<p class="err">❌ Errors:</p>
<?php foreach($errors as $e) echo "<p class='err'>• $e</p>"; ?>
<?php else: ?>
<p class="info">🎉 Migration complete! All <?= count($created) ?> tables ready. Default settings seeded.</p>
<?php endif; ?>
</body></html>
