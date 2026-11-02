<?php
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../core/Database.php';

try {
    $db = Database::getInstance()->getConnection();
    
    $stmt = $db->query("
        SELECT * FROM electricity_meter_readings 
        WHERE apartment_id IN (SELECT id FROM apartments WHERE code = '101') 
        ORDER BY id DESC LIMIT 5
    ");
    print_r($stmt->fetchAll(PDO::FETCH_ASSOC));

} catch(Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
