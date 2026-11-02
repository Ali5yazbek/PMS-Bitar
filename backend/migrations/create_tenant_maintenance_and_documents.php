<?php
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../core/Database.php';

$db = Database::getInstance()->getConnection();
$errors = [];
$success = [];

// ── 1. tenant_maintenance_tickets ──────────────────────────────────────────
$sql1 = "
CREATE TABLE IF NOT EXISTS `tenant_maintenance_tickets` (
  `id`           int(11)         NOT NULL AUTO_INCREMENT,
  `tenant_id`    int(11)         NOT NULL,
  `apartment_id` int(11)         DEFAULT NULL,
  `title`        varchar(255)    NOT NULL,
  `description`  text            NOT NULL,
  `category`     varchar(100)    DEFAULT NULL,
  `priority`     enum('Low','Medium','High','Urgent') NOT NULL DEFAULT 'Medium',
  `status`       enum('Open','In Progress','Resolved','Rejected','Closed') NOT NULL DEFAULT 'Open',
  `admin_notes`  text            DEFAULT NULL,
  `submitted_by` int(11)         DEFAULT NULL,
  `resolved_at`  datetime        DEFAULT NULL,
  `created_at`   timestamp       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`   timestamp       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_tenant_id` (`tenant_id`),
  KEY `idx_status`    (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
";

try {
    $db->exec($sql1);
    $success[] = "✅ Created table: tenant_maintenance_tickets";
} catch (PDOException $e) {
    $errors[] = "❌ tenant_maintenance_tickets: " . $e->getMessage();
}

// ── 2. tenant_documents ─────────────────────────────────────────────────────
$sql2 = "
CREATE TABLE IF NOT EXISTS `tenant_documents` (
  `id`                int(11)         NOT NULL AUTO_INCREMENT,
  `tenant_id`         int(11)         NOT NULL,
  `document_type`     enum('passport','national_id','work_contract') NOT NULL,
  `file_url`          varchar(500)    DEFAULT NULL,
  `original_filename` varchar(255)    DEFAULT NULL,
  `status`            enum('Uploaded','Verified','Pending','Missing','Requested') NOT NULL DEFAULT 'Pending',
  `admin_notes`       text            DEFAULT NULL,
  `uploaded_at`       datetime        DEFAULT NULL,
  `verified_at`       datetime        DEFAULT NULL,
  `verified_by`       int(11)         DEFAULT NULL,
  `created_at`        timestamp       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        timestamp       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_tenant_doctype` (`tenant_id`, `document_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
";

try {
    $db->exec($sql2);
    $success[] = "✅ Created table: tenant_documents";
} catch (PDOException $e) {
    $errors[] = "❌ tenant_documents: " . $e->getMessage();
}

// ── Output ──────────────────────────────────────────────────────────────────
header('Content-Type: text/html; charset=utf-8');
echo "<pre style='font-family:monospace;font-size:14px;padding:20px;'>";
echo "<strong>Migration: Tenant Maintenance & Documents</strong>\n\n";
foreach ($success as $msg) echo $msg . "\n";
foreach ($errors as $err) echo $err . "\n";
echo "\nDone.";
echo "</pre>";
