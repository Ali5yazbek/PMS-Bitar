<?php
require_once __DIR__ . '/core/Database.php';
try {
    $db = Database::getInstance()->getConnection();
    
    // update generators
    $db->exec("ALTER TABLE generators ADD COLUMN price_per_kw DECIMAL(10,2) DEFAULT 0 AFTER baseline_fuel_per_hour");

    echo "Database schema updated successfully.";
} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}
