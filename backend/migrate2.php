<?php
require 'config.php';
require 'core/Database.php';

try {
    $db = Database::getInstance()->getConnection();
    
    try {
        $db->exec("ALTER TABLE contracts ADD COLUMN monthly_rent DECIMAL(10,2) NULL, ADD COLUMN monthly_insurance DECIMAL(10,2) NULL");
    } catch(Exception $e) {}
    
    echo "Migrations successful.\n";
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
