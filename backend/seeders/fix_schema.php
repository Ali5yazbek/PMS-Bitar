<?php
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../core/Database.php';

try {
    $db = Database::getInstance()->getConnection();
    
    // Drop the unique index on apartment_id if it exists
    try {
        $db->query("ALTER TABLE electricity_subscriptions DROP INDEX apartment_id");
        echo "Dropped apartment_id index.\n";
    } catch(Exception $e) {
        echo "Index apartment_id might not exist: " . $e->getMessage() . "\n";
    }

    // Drop other index if needed
    try {
        $db->query("ALTER TABLE electricity_subscriptions DROP INDEX idx_electricity_subs_apartment_id");
        echo "Dropped idx_electricity_subs_apartment_id index.\n";
    } catch(Exception $e) {
        echo "Index idx_electricity_subs_apartment_id might not exist: " . $e->getMessage() . "\n";
    }

    // Add unique composite index
    $db->query("ALTER TABLE electricity_subscriptions ADD UNIQUE INDEX idx_apartment_type (apartment_id, type)");
    echo "Added unique index idx_apartment_type (apartment_id, type).\n";

} catch(Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
