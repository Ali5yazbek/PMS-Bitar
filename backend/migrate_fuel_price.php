<?php
require_once __DIR__ . '/core/Database.php';

$db = Database::getInstance()->getConnection();

try {
    echo "Adding fuel_price_at_time to daily_logs...\n";
    $db->exec("ALTER TABLE daily_logs ADD COLUMN fuel_price_at_time DECIMAL(10,2) DEFAULT NULL AFTER admin_actual_fuel");
    echo "Success!\n";
} catch (PDOException $e) {
    if (strpos($e->getMessage(), 'Duplicate column name') !== false) {
        echo "Column already exists. Skipping.\n";
    } else {
        echo "Error: " . $e->getMessage() . "\n";
    }
}
