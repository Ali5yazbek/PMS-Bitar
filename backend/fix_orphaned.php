<?php
require 'config.php';
require 'core/Database.php';

try {
    $db = Database::getInstance()->getConnection();
    
    // Find apartments that are 'Rented' but have no 'Active' contract
    $stmt = $db->query("SELECT id FROM apartments WHERE status = 'Rented' AND id NOT IN (SELECT apartment_id FROM contracts WHERE status = 'Active')");
    $orphaned = $stmt->fetchAll(PDO::FETCH_ASSOC);

    if (count($orphaned) > 0) {
        $updateStmt = $db->prepare("UPDATE apartments SET status = 'Vacant' WHERE id = ?");
        foreach ($orphaned as $apt) {
            $updateStmt->execute([$apt['id']]);
            echo "Fixed apartment ID: " . $apt['id'] . "\n";
        }
    } else {
        echo "No orphaned apartments found.\n";
    }

} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
