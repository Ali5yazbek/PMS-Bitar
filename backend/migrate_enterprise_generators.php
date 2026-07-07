<?php
require_once __DIR__ . '/core/Database.php';

try {
    $db = Database::getInstance()->getConnection();
    
    // 1. Expand `generators` table
    $columns = [
        "model VARCHAR(255) NULL",
        "serial_number VARCHAR(255) NULL",
        "expected_fuel_consumption_per_hour DECIMAL(10,2) NULL",
        "expected_fuel_consumption_per_kwh DECIMAL(10,2) NULL",
        "maintenance_interval_hours DECIMAL(10,2) DEFAULT 250.00",
        "min_fuel_level_alert DECIMAL(10,2) DEFAULT 100.00",
        "normal_operating_thresholds JSON NULL",
        "alert_thresholds JSON NULL",
        "efficiency_score INT DEFAULT 100",
        "reliability_score INT DEFAULT 100",
        "maintenance_score INT DEFAULT 100",
        "fuel_accuracy_score INT DEFAULT 100",
        "risk_score INT DEFAULT 0",
        "health_score INT DEFAULT 100"
    ];

    foreach ($columns as $column) {
        $colName = explode(" ", trim($column))[0];
        try {
            $db->exec("ALTER TABLE generators ADD COLUMN $column");
            echo "Added $colName to generators\n";
        } catch (PDOException $e) {
            // Ignore if exists
            if (strpos($e->getMessage(), 'Duplicate column name') === false) {
                echo "Error adding $colName: " . $e->getMessage() . "\n";
            }
        }
    }

    // 2. Expand `generator_daily_reports` table
    $reportColumns = [
        "load_percentage DECIMAL(5,2) NULL",
        "outages_count INT DEFAULT 0",
        "expected_fuel_consumption DECIMAL(10,2) NULL",
        "actual_fuel_consumption DECIMAL(10,2) NULL",
        "fuel_consumption_per_hour DECIMAL(10,2) NULL",
        "fuel_consumption_per_kwh DECIMAL(10,2) NULL",
        "cost_of_electricity DECIMAL(10,2) NULL",
        "fuel_variance DECIMAL(10,2) NULL",
        "estimated_days_empty DECIMAL(10,2) NULL",
        "photo_meter_path VARCHAR(255) NULL"
    ];

    foreach ($reportColumns as $column) {
        $colName = explode(" ", trim($column))[0];
        try {
            $db->exec("ALTER TABLE generator_daily_reports ADD COLUMN $column");
            echo "Added $colName to generator_daily_reports\n";
        } catch (PDOException $e) {
            if (strpos($e->getMessage(), 'Duplicate column name') === false) {
                echo "Error adding $colName: " . $e->getMessage() . "\n";
            }
        }
    }

    // 3. Create `fuel_suppliers`
    $db->exec("CREATE TABLE IF NOT EXISTS fuel_suppliers (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        contact_info TEXT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )");
    echo "Table fuel_suppliers ensured\n";

    // 4. Create `fuel_movements`
    $db->exec("CREATE TABLE IF NOT EXISTS fuel_movements (
        id INT AUTO_INCREMENT PRIMARY KEY,
        generator_id INT NOT NULL,
        type ENUM('Refill', 'Transfer_In', 'Transfer_Out', 'Adjustment', 'Emergency', 'Manual_Correction') NOT NULL,
        amount DECIMAL(10,2) NOT NULL,
        cost_per_liter DECIMAL(10,2) NULL,
        supplier_id INT NULL,
        date DATETIME NOT NULL,
        user_id INT NULL,
        notes TEXT NULL,
        receipt_path VARCHAR(255) NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (generator_id) REFERENCES generators(id) ON DELETE CASCADE,
        FOREIGN KEY (supplier_id) REFERENCES fuel_suppliers(id) ON DELETE SET NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
    )");
    echo "Table fuel_movements ensured\n";

    // 5. Create `generator_ai_profiles`
    $db->exec("CREATE TABLE IF NOT EXISTS generator_ai_profiles (
        id INT AUTO_INCREMENT PRIMARY KEY,
        generator_id INT NOT NULL UNIQUE,
        normal_consumption_pattern JSON NULL,
        seasonal_patterns JSON NULL,
        high_load_periods JSON NULL,
        low_load_periods JSON NULL,
        aging_factor DECIMAL(5,4) DEFAULT 1.0000,
        last_analyzed_at TIMESTAMP NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (generator_id) REFERENCES generators(id) ON DELETE CASCADE
    )");
    echo "Table generator_ai_profiles ensured\n";

    // 6. Expand `generator_alerts` to include severity if it doesn't have it, and probability JSON
    try {
        $db->exec("ALTER TABLE generator_alerts ADD COLUMN probabilities JSON NULL");
        echo "Added probabilities to generator_alerts\n";
    } catch (PDOException $e) {
        // Ignore
    }

    echo "Enterprise Generators migration completed successfully.\n";

} catch (PDOException $e) {
    echo "Migration Error: " . $e->getMessage() . "\n";
}
