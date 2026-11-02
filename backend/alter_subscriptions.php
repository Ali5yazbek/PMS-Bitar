<?php
require_once __DIR__ . '/config.php';

try {
    $db = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASS);
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    echo "Starting migration...\n";

    // 1. Alter electricity_subscriptions table
    echo "Altering electricity_subscriptions table...\n";
    
    // Check if `type` column exists, if not add it
    $colCheck = $db->query("SHOW COLUMNS FROM electricity_subscriptions LIKE 'type'")->fetch();
    if (!$colCheck) {
        $db->exec("ALTER TABLE electricity_subscriptions ADD COLUMN type ENUM('Meter', 'Fixed Monthly', 'Fixed Amp') DEFAULT 'Meter' AFTER apartment_id");
        echo "- Added `type` column\n";
    }

    // Update status enum
    $db->exec("ALTER TABLE electricity_subscriptions MODIFY COLUMN status ENUM('Active', 'Inactive', 'Paused', 'Suspended', 'Cancelled') DEFAULT 'Active'");
    echo "- Modified `status` column enum values\n";
    
    // Set default types based on existing data
    $db->exec("UPDATE electricity_subscriptions SET type = 'Fixed Monthly' WHERE monthly_fee > 0 AND (amps IS NULL OR amps = 0)");
    $db->exec("UPDATE electricity_subscriptions SET type = 'Fixed Amp' WHERE amps > 0");
    echo "- Migrated existing subscription types\n";

    // 2. Create subscription_history table
    echo "Creating subscription_history table...\n";
    $db->exec("
        CREATE TABLE IF NOT EXISTS subscription_history (
            id INT(11) AUTO_INCREMENT PRIMARY KEY,
            subscription_id INT(11) NOT NULL,
            action VARCHAR(255) NOT NULL,
            previous_value TEXT,
            new_value TEXT,
            reason TEXT,
            performed_by INT(11),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (subscription_id) REFERENCES electricity_subscriptions(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ");
    echo "- subscription_history table created\n";

    echo "Migration completed successfully!\n";

} catch (PDOException $e) {
    echo "Migration failed: " . $e->getMessage() . "\n";
}
