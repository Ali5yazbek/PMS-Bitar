<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/core/Database.php';
$db = Database::getInstance()->getConnection();

// Fix the status enum to include 'Verified'
echo "=== Fixing electricity_meter_readings status enum ===\n";
try {
    $db->exec("ALTER TABLE electricity_meter_readings MODIFY COLUMN status ENUM('Pending','Pending Verification','Approved','Verified','Rejected','Resubmitted') DEFAULT 'Pending'");
    echo "Status enum updated successfully.\n";
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}

// Also ensure submitted_at column exists (used in our insert)
echo "\n=== Ensuring submitted_at column ===\n";
try {
    $db->exec("ALTER TABLE electricity_meter_readings ADD COLUMN IF NOT EXISTS submitted_at DATETIME DEFAULT NULL");
    echo "submitted_at column ensured.\n";
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}

echo "\n=== Current status enum ===\n";
$r = $db->query("SHOW COLUMNS FROM electricity_meter_readings LIKE 'status'");
$col = $r->fetch(PDO::FETCH_ASSOC);
echo $col['Field'] . " - " . $col['Type'] . "\n";
