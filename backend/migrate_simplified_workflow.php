<?php
require_once __DIR__ . '/core/Database.php';

try {
    $db = Database::getInstance()->getConnection();
    
    // Expand `generator_daily_reports` table
    $reportColumns = [
        "actual_fuel_remaining DECIMAL(10,2) NULL",
        "estimated_fuel_remaining DECIMAL(10,2) NULL",
        "estimated_fuel_used DECIMAL(10,2) NULL",
        "actual_fuel_used DECIMAL(10,2) NULL",
        "fuel_difference DECIMAL(10,2) NULL",
        "status ENUM('Pending Verification', 'Verified', 'Flagged') DEFAULT 'Verified'"
    ];

    foreach ($reportColumns as $column) {
        $colName = explode(" ", trim($column))[0];
        try {
            $db->exec("ALTER TABLE generator_daily_reports ADD COLUMN $column");
            echo "Added $colName to generator_daily_reports\n";
        } catch (PDOException $e) {
            if (strpos($e->getMessage(), 'Duplicate column name') === false) {
                echo "Error adding $colName: " . $e->getMessage() . "\n";
            } else {
                echo "$colName already exists.\n";
            }
        }
    }

    echo "Generator simplified workflow migration completed successfully.\n";

} catch (PDOException $e) {
    echo "Migration Error: " . $e->getMessage() . "\n";
}
