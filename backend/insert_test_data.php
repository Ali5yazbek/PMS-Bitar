<?php
require 'config.php';

try {
    $db = new PDO(
        "mysql:host=" . DB_HOST . ";port=" . DB_PORT . ";dbname=" . DB_NAME,
        DB_USER,
        DB_PASS,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );

    // Get a user
    $stmt = $db->query("SELECT id FROM users LIMIT 1");
    $user = $stmt->fetch();
    $userId = $user ? $user['id'] : null;
    
    // Check if we have a building
    $stmt = $db->query("SELECT id FROM buildings LIMIT 1");
    $building = $stmt->fetch();
    $buildingId = $building ? $building['id'] : null;

    if (!$buildingId) {
        $db->exec("INSERT INTO buildings (name, address) VALUES ('Tower 2', 'City Center')");
        $buildingId = $db->lastInsertId();
    }

    // Check if we have a generator
    $stmt = $db->query("SELECT id FROM generators LIMIT 1");
    $generator = $stmt->fetch();
    $generatorId = $generator ? $generator['id'] : null;

    if (!$generatorId) {
        $db->exec("INSERT INTO generators (building_id, name, capacity_kva, fuel_capacity_liters, current_fuel) VALUES ($buildingId, 'Main Gen', 500, 1000, 500)");
        $generatorId = $db->lastInsertId();
    }

    // Insert pending reading
    $db->exec("INSERT INTO generator_daily_reports (generator_id, date, running_hours, fuel_added, submitted_by, status) VALUES ($generatorId, CURDATE(), 5, 100, " . ($userId ? $userId : "NULL") . ", 'Pending Verification')");
    
    echo "Test data inserted successfully.\n";
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
