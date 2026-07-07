<?php
require_once __DIR__ . '/backend/core/Database.php';

try {
    $db = Database::getInstance()->getConnection();
    
    echo "Adding workshop_id to constructions...\n";
    $db->exec("ALTER TABLE constructions ADD COLUMN workshop_id INT NULL DEFAULT NULL;");
    
    echo "Creating construction_materials table...\n";
    $db->exec("
        CREATE TABLE IF NOT EXISTS construction_materials (
            id INT AUTO_INCREMENT PRIMARY KEY,
            construction_id INT NOT NULL,
            item_name VARCHAR(100) NOT NULL,
            category VARCHAR(50),
            estimated_quantity DECIMAL(10,2) NOT NULL,
            used_quantity DECIMAL(10,2) DEFAULT 0.00,
            unit VARCHAR(20),
            unit_price DECIMAL(10,2) NOT NULL,
            total_estimated_cost DECIMAL(10,2) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (construction_id) REFERENCES constructions(id) ON DELETE CASCADE
        );
    ");

    echo "Database migration completed successfully.\n";
} catch (Exception $e) {
    // If column already exists, PDO might throw an exception, catch it and move on
    if (strpos($e->getMessage(), 'Duplicate column name') !== false) {
        echo "Column workshop_id already exists.\n";
    } else {
        echo "Error: " . $e->getMessage() . "\n";
    }
}
