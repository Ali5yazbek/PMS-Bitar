<?php
require_once __DIR__ . '/core/Database.php';

try {
    $db = Database::getInstance()->getConnection();
    
    $sql = "
    ALTER TABLE daily_logs 
    ADD COLUMN actual_fuel_spent FLOAT NULL,
    ADD COLUMN actual_consumption_rate FLOAT NULL,
    ADD COLUMN missing_fuel_variance FLOAT NULL,
    ADD COLUMN financial_loss_cfa FLOAT NULL;
    ";
    
    $db->exec($sql);
    echo "Successfully added metrics columns to daily_logs table!";
} catch (PDOException $e) {
    echo "Error: " . $e->getMessage();
}
