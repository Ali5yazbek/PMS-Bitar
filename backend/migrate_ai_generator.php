<?php
require_once __DIR__ . '/core/Database.php';

try {
    $db = Database::getInstance()->getConnection();
    
    $db->exec("CREATE TABLE IF NOT EXISTS generator_ai_summaries (
        id INT AUTO_INCREMENT PRIMARY KEY,
        date DATE NOT NULL UNIQUE,
        daily_summary TEXT NOT NULL,
        weekly_summary TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )");
    echo "Table 'generator_ai_summaries' created or already exists.\n";
    
    // Add columns to generator_daily_reports if they don't exist
    $columns = [
        "previous_meter_hours DECIMAL(10,2) DEFAULT 0",
        "current_meter_hours DECIMAL(10,2) DEFAULT 0",
        "previous_kwh DECIMAL(12,2) DEFAULT 0",
        "current_kwh DECIMAL(12,2) DEFAULT 0",
        "liters_per_hour DECIMAL(10,2) DEFAULT 0",
        "liters_per_kwh DECIMAL(10,2) DEFAULT 0"
    ];

    foreach ($columns as $column) {
        $colName = explode(" ", trim($column))[0];
        try {
            $db->exec("ALTER TABLE generator_daily_reports ADD COLUMN $column");
            echo "Added $colName to generator_daily_reports\n";
        } catch (PDOException $e) {
            // Ignore if exists
        }
    }

    echo "AI Generator migration completed successfully.\n";

} catch (PDOException $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
