<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/core/Database.php';

$db = Database::getInstance()->getConnection();

try {
    $db->exec("CREATE TABLE IF NOT EXISTS estimation_rates (
        id INT AUTO_INCREMENT PRIMARY KEY,
        item_name VARCHAR(100) NOT NULL UNIQUE,
        category VARCHAR(50) NOT NULL,
        unit VARCHAR(20) NOT NULL,
        default_price DECIMAL(10,2) NOT NULL DEFAULT 0.00
    )");

    // Seed defaults
    $defaults = [
        ['Concrete', 'Material', 'm3', 120.00],
        ['Steel', 'Material', 'Ton', 800.00],
        ['Cement', 'Material', 'Bag', 12.00],
        ['Blocks', 'Material', 'Piece', 0.50],
        ['Sand', 'Material', 'Ton', 30.00],
        ['Tiles', 'Material', 'm2', 15.00],
        ['Paint', 'Material', 'Liter', 4.00],
        ['Electrical Cables', 'Material', 'Meter', 1.50],
        ['Water Pipes', 'Material', 'Meter', 3.00],
        ['Doors', 'Material', 'Piece', 150.00],
        ['Windows', 'Material', 'Piece', 200.00],
        
        ['Mason', 'Labor', 'Mandays', 25.00],
        ['Electrician', 'Labor', 'Mandays', 35.00],
        ['Plumber', 'Labor', 'Mandays', 35.00],
        ['Painter', 'Labor', 'Mandays', 20.00],
        ['Supervisor', 'Labor', 'Mandays', 50.00],
        
        ['Excavator', 'Equipment', 'Days', 200.00],
        ['Crane', 'Equipment', 'Days', 150.00],
        ['Concrete Mixer', 'Equipment', 'Days', 100.00],
        ['Generator', 'Equipment', 'Days', 50.00],
        
        ['Permits & Fees', 'Other', 'Lump Sum', 15000.00]
    ];

    $stmt = $db->prepare("INSERT IGNORE INTO estimation_rates (item_name, category, unit, default_price) VALUES (?, ?, ?, ?)");
    foreach ($defaults as $d) {
        $stmt->execute($d);
    }

    echo "Market rates seeded successfully.\n";
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
