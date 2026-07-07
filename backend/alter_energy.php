<?php
require_once __DIR__ . '/core/Database.php';
try {
    $db = Database::getInstance()->getConnection();
    // Add cost_per_liter to daily reports if it doesn't exist
    $db->exec("ALTER TABLE generator_daily_reports ADD COLUMN cost_per_liter DECIMAL(10,2) NOT NULL DEFAULT 0 AFTER fuel_added");
    echo "Added cost_per_liter column.";
} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}
