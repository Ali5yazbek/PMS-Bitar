<?php
/**
 * Migration: Tenant Offboarding Schema Updates
 *
 * Adds:
 *  - 'Voided' to rent_invoices.status ENUM
 *  - move_out_date column to tenants
 *  - 'Terminated' value to tenants.status ENUM
 *
 * Run ONCE from browser or CLI.
 */

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/core/Database.php';

$db = Database::getInstance()->getConnection();

$steps = [];

try {
    // 1. Add 'Voided' to rent_invoices.status
    $db->exec("
        ALTER TABLE rent_invoices
        MODIFY COLUMN status ENUM('Unpaid','Partial','Paid','Overdue','Voided') DEFAULT 'Unpaid'
    ");
    $steps[] = "✅ rent_invoices.status: Added 'Voided'";
} catch (PDOException $e) {
    $steps[] = "⚠️  rent_invoices.status: " . $e->getMessage();
}

try {
    // 2. Add 'Terminated' to tenants.status ENUM
    $db->exec("
        ALTER TABLE tenants
        MODIFY COLUMN status ENUM('Active','Inactive','Terminated') DEFAULT 'Active'
    ");
    $steps[] = "✅ tenants.status: Added 'Terminated'";
} catch (PDOException $e) {
    $steps[] = "⚠️  tenants.status: " . $e->getMessage();
}

try {
    // 3. Add move_out_date column to tenants
    $check = $db->query("SHOW COLUMNS FROM tenants LIKE 'move_out_date'");
    if ($check->rowCount() === 0) {
        $db->exec("ALTER TABLE tenants ADD COLUMN move_out_date DATE NULL DEFAULT NULL");
        $steps[] = "✅ tenants.move_out_date: Column added";
    } else {
        $steps[] = "ℹ️  tenants.move_out_date: Already exists, skipped";
    }
} catch (PDOException $e) {
    $steps[] = "⚠️  tenants.move_out_date: " . $e->getMessage();
}

try {
    // 4. Add rent_status column to contracts if missing
    $check = $db->query("SHOW COLUMNS FROM contracts LIKE 'rent_status'");
    if ($check->rowCount() === 0) {
        $db->exec("ALTER TABLE contracts ADD COLUMN rent_status ENUM('Active','Paused','Ended') DEFAULT 'Active'");
        $steps[] = "✅ contracts.rent_status: Column added";
    } else {
        $steps[] = "ℹ️  contracts.rent_status: Already exists, skipped";
    }
} catch (PDOException $e) {
    $steps[] = "⚠️  contracts.rent_status: " . $e->getMessage();
}

echo "<pre>";
echo "=== Tenant Offboarding Migration ===\n\n";
foreach ($steps as $step) {
    echo $step . "\n";
}
echo "\n✔ Migration complete.\n";
echo "</pre>";
