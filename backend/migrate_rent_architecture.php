<?php
require 'config.php';
require 'core/Database.php';

try {
    $db = Database::getInstance()->getConnection();
    
    // 1. Update rent_profiles
    $db->exec("UPDATE rent_profiles SET status = 'Closed' WHERE status = 'Ended'");
    $db->exec("ALTER TABLE rent_profiles MODIFY COLUMN status ENUM('Active', 'Paused', 'Closed') DEFAULT 'Active'");
    
    // 2. Update contracts
    $db->exec("UPDATE contracts SET rent_status = 'Closed' WHERE rent_status = 'Ended'");
    $db->exec("ALTER TABLE contracts MODIFY COLUMN rent_status ENUM('Active', 'Paused', 'Closed') DEFAULT 'Active'");
    
    // 3. Add rent_profile_id to rent_invoices
    try {
        $db->exec("ALTER TABLE rent_invoices ADD COLUMN rent_profile_id INT(11) NULL DEFAULT NULL AFTER contract_id");
    } catch (PDOException $e) {
        // Might already exist, ignore
    }
    
    // 4. Update rent_invoices to populate rent_profile_id based on contract_id
    // A rent profile has a contract_id, so we can join them.
    $db->exec("
        UPDATE rent_invoices ri
        JOIN rent_profiles rp ON ri.contract_id = rp.contract_id
        SET ri.rent_profile_id = rp.id
        WHERE ri.rent_profile_id IS NULL
    ");

    echo "Migration completed successfully.\n";
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
