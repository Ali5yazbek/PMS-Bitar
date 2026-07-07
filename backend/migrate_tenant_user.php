<?php
require 'config.php';
require 'core/Database.php';

try {
    $db = Database::getInstance()->getConnection();
    
    $db->exec("ALTER TABLE users MODIFY COLUMN role ENUM('admin', 'manager', 'cashier', 'tenant') DEFAULT 'cashier'");
    
    try {
        $db->exec("ALTER TABLE users ADD COLUMN phone VARCHAR(50) NULL");
        $db->exec("ALTER TABLE users ADD COLUMN national_id VARCHAR(100) NULL");
    } catch(Exception $e) {}
    
    try {
        $db->exec("ALTER TABLE tenants ADD COLUMN user_id INT NULL");
        $db->exec("ALTER TABLE tenants ADD FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL");
    } catch(Exception $e) {}
    
    try {
        $db->exec("ALTER TABLE contracts ADD COLUMN contract_file VARCHAR(255) NULL");
    } catch(Exception $e) {}
    
    echo "Migrations successful.\n";
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
