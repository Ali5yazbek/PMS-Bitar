<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/core/Database.php';

$db = Database::getInstance()->getConnection();

$migrations = [];
$errors = [];

// 1. Add 'status' column to apartment_cost_deployments
try {
    $check = $db->query("SHOW COLUMNS FROM apartment_cost_deployments LIKE 'status'");
    if (!$check->fetch()) {
        $db->exec("ALTER TABLE apartment_cost_deployments ADD COLUMN status VARCHAR(30) NOT NULL DEFAULT 'Accepted' AFTER notes");
        $migrations[] = "Added 'status' column to apartment_cost_deployments";
    } else {
        $migrations[] = "'status' column already exists — skipped";
    }
} catch (Exception $e) {
    $errors[] = "status column: " . $e->getMessage();
}

// 2. Add 'submitted_by' column to apartment_cost_deployments
try {
    $check = $db->query("SHOW COLUMNS FROM apartment_cost_deployments LIKE 'submitted_by'");
    if (!$check->fetch()) {
        $db->exec("ALTER TABLE apartment_cost_deployments ADD COLUMN submitted_by INT NULL AFTER status");
        $migrations[] = "Added 'submitted_by' column to apartment_cost_deployments";
    } else {
        $migrations[] = "'submitted_by' column already exists — skipped";
    }
} catch (Exception $e) {
    $errors[] = "submitted_by column: " . $e->getMessage();
}

// 3. Add 'rejection_reason' column to apartment_cost_deployments
try {
    $check = $db->query("SHOW COLUMNS FROM apartment_cost_deployments LIKE 'rejection_reason'");
    if (!$check->fetch()) {
        $db->exec("ALTER TABLE apartment_cost_deployments ADD COLUMN rejection_reason TEXT NULL AFTER submitted_by");
        $migrations[] = "Added 'rejection_reason' column to apartment_cost_deployments";
    } else {
        $migrations[] = "'rejection_reason' column already exists — skipped";
    }
} catch (Exception $e) {
    $errors[] = "rejection_reason column: " . $e->getMessage();
}

// 4. Add 'reviewed_by' column
try {
    $check = $db->query("SHOW COLUMNS FROM apartment_cost_deployments LIKE 'reviewed_by'");
    if (!$check->fetch()) {
        $db->exec("ALTER TABLE apartment_cost_deployments ADD COLUMN reviewed_by INT NULL AFTER rejection_reason");
        $migrations[] = "Added 'reviewed_by' column to apartment_cost_deployments";
    } else {
        $migrations[] = "'reviewed_by' column already exists — skipped";
    }
} catch (Exception $e) {
    $errors[] = "reviewed_by column: " . $e->getMessage();
}

// 5. Add 'reviewed_at' column
try {
    $check = $db->query("SHOW COLUMNS FROM apartment_cost_deployments LIKE 'reviewed_at'");
    if (!$check->fetch()) {
        $db->exec("ALTER TABLE apartment_cost_deployments ADD COLUMN reviewed_at DATETIME NULL AFTER reviewed_by");
        $migrations[] = "Added 'reviewed_at' column to apartment_cost_deployments";
    } else {
        $migrations[] = "'reviewed_at' column already exists — skipped";
    }
} catch (Exception $e) {
    $errors[] = "reviewed_at column: " . $e->getMessage();
}

// 6. Add 'created_at' column if it doesn't exist
try {
    $check = $db->query("SHOW COLUMNS FROM apartment_cost_deployments LIKE 'created_at'");
    if (!$check->fetch()) {
        $db->exec("ALTER TABLE apartment_cost_deployments ADD COLUMN created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP");
        $migrations[] = "Added 'created_at' column to apartment_cost_deployments";
    } else {
        $migrations[] = "'created_at' column already exists — skipped";
    }
} catch (Exception $e) {
    $errors[] = "created_at column: " . $e->getMessage();
}

echo "<pre>";
echo "=== Migration: Agent Apartment Costs ===\n\n";
echo "Completed:\n";
foreach ($migrations as $m) echo "  ✓ $m\n";
if ($errors) {
    echo "\nErrors:\n";
    foreach ($errors as $e) echo "  ✗ $e\n";
}
echo "\nDone.";
echo "</pre>";
