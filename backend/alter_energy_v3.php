<?php
require_once __DIR__ . '/core/Database.php';
try {
    $db = Database::getInstance()->getConnection();
    
    // update electricity_subscriptions
    $db->exec("ALTER TABLE electricity_subscriptions ADD COLUMN end_date DATE AFTER start_date");

    echo "Database schema updated successfully.";
} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}
