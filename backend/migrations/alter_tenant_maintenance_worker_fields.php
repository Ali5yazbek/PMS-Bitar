<?php
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../core/Database.php';

$db = Database::getInstance()->getConnection();

echo "Running migration for tenant_maintenance_tickets worker fields...\n";

// 1. Add worker_id
try {
    $db->exec("ALTER TABLE tenant_maintenance_tickets ADD COLUMN `worker_id` INT(11) DEFAULT NULL AFTER `submitted_by`");
    echo "Added worker_id\n";
} catch (Exception $e) {
    echo "worker_id: " . $e->getMessage() . "\n";
}

// 2. Add before_photo
try {
    $db->exec("ALTER TABLE tenant_maintenance_tickets ADD COLUMN `before_photo` LONGTEXT DEFAULT NULL AFTER `worker_id`");
    echo "Added before_photo\n";
} catch (Exception $e) {
    echo "before_photo: " . $e->getMessage() . "\n";
}

// 3. Add after_photo
try {
    $db->exec("ALTER TABLE tenant_maintenance_tickets ADD COLUMN `after_photo` LONGTEXT DEFAULT NULL AFTER `before_photo`");
    echo "Added after_photo\n";
} catch (Exception $e) {
    echo "after_photo: " . $e->getMessage() . "\n";
}

// 4. Add worker_notes
try {
    $db->exec("ALTER TABLE tenant_maintenance_tickets ADD COLUMN `worker_notes` TEXT DEFAULT NULL AFTER `after_photo`");
    echo "Added worker_notes\n";
} catch (Exception $e) {
    echo "worker_notes: " . $e->getMessage() . "\n";
}

// 5. Add completion_date
try {
    $db->exec("ALTER TABLE tenant_maintenance_tickets ADD COLUMN `completion_date` DATETIME DEFAULT NULL AFTER `worker_notes`");
    echo "Added completion_date\n";
} catch (Exception $e) {
    echo "completion_date: " . $e->getMessage() . "\n";
}

// 6. Update status ENUM to include Assigned and Pending_Approval
try {
    $db->exec("ALTER TABLE tenant_maintenance_tickets MODIFY COLUMN `status` ENUM('Open','Assigned','In Progress','Pending_Approval','Resolved','Rejected','Closed') NOT NULL DEFAULT 'Open'");
    echo "Updated status ENUM\n";
} catch (Exception $e) {
    echo "status enum: " . $e->getMessage() . "\n";
}

echo "Migration complete.\n";

