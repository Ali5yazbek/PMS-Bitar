<?php
require_once __DIR__ . '/core/Database.php';

try {
    $db = Database::getInstance()->getConnection();
    
    // The generators table probably already exists since they just registered one successfully,
    // but we'll run it anyway with IF NOT EXISTS just in case.
    // However, since EnergyController expects certain columns, we should make sure we don't break it.
    // Wait, let's just create the daily_logs table since that's what's missing for the AI!
    
    $sql = "
    CREATE TABLE IF NOT EXISTS daily_logs (
        id INT AUTO_INCREMENT PRIMARY KEY,
        generator_id INT NOT NULL,
        date DATE NOT NULL,
        submitted_hours FLOAT NOT NULL,
        calculated_hours_worked FLOAT NOT NULL,
        expected_factory_fuel_burn FLOAT NOT NULL,
        ml_predicted_fuel_burn FLOAT,
        predicted_fuel_remaining FLOAT,
        admin_actual_fuel FLOAT NULL,
        status_flag VARCHAR(50) DEFAULT 'Normal',
        ai_report TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );";
    
    $db->exec($sql);
    echo "Successfully created daily_logs table!";
} catch (PDOException $e) {
    echo "Error: " . $e->getMessage();
}
