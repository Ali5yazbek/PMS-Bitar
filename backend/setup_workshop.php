<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/core/Database.php';

$db = Database::getInstance()->getConnection();

try {

    // Inventory Items (Depot)
    $db->exec("CREATE TABLE IF NOT EXISTS inventory_items (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        category VARCHAR(50) NOT NULL,
        unit VARCHAR(20) NOT NULL,
        current_stock DECIMAL(10,2) DEFAULT 0.00,
        min_stock DECIMAL(10,2) DEFAULT 0.00,
        unit_cost DECIMAL(10,2) DEFAULT 0.00,
        supplier VARCHAR(100),
        warehouse_location VARCHAR(100),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )");

    // Inventory Transactions
    $db->exec("CREATE TABLE IF NOT EXISTS inventory_transactions (
        id INT AUTO_INCREMENT PRIMARY KEY,
        item_id INT NOT NULL,
        type ENUM('IN', 'OUT') NOT NULL,
        quantity DECIMAL(10,2) NOT NULL,
        project_id INT NULL,
        user_id INT NOT NULL,
        notes TEXT,
        date DATE NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (item_id) REFERENCES inventory_items(id)
    )");

    // Workshop Projects
    $db->exec("CREATE TABLE IF NOT EXISTS workshop_projects (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        land_area DECIMAL(10,2) NOT NULL,
        floors INT NOT NULL,
        apartments_per_floor INT NOT NULL,
        total_apartments INT NOT NULL,
        status VARCHAR(50) DEFAULT 'Planning',
        progress INT DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )");

    // Project Specifications (Apartment Design)
    $db->exec("CREATE TABLE IF NOT EXISTS workshop_specifications (
        id INT AUTO_INCREMENT PRIMARY KEY,
        project_id INT NOT NULL UNIQUE,
        bedrooms INT NOT NULL,
        bathrooms INT NOT NULL,
        kitchens INT NOT NULL,
        living_rooms INT NOT NULL,
        balconies INT NOT NULL,
        windows INT NOT NULL,
        doors INT NOT NULL,
        parking_spaces INT NOT NULL,
        elevators INT NOT NULL,
        roof_area DECIMAL(10,2) NOT NULL,
        garden_area DECIMAL(10,2) NOT NULL,
        FOREIGN KEY (project_id) REFERENCES workshop_projects(id) ON DELETE CASCADE
    )");

    // Project Material Estimates (The output of the engine)
    $db->exec("CREATE TABLE IF NOT EXISTS workshop_estimates (
        id INT AUTO_INCREMENT PRIMARY KEY,
        project_id INT NOT NULL,
        item_name VARCHAR(100) NOT NULL,
        category VARCHAR(50) NOT NULL, -- Material, Labor, Equipment, etc
        quantity DECIMAL(10,2) NOT NULL,
        unit VARCHAR(20),
        unit_price DECIMAL(10,2) NOT NULL,
        total_price DECIMAL(10,2) NOT NULL,
        is_reserved BOOLEAN DEFAULT FALSE,
        FOREIGN KEY (project_id) REFERENCES workshop_projects(id) ON DELETE CASCADE
    )");

    // Purchase Requests
    $db->exec("CREATE TABLE IF NOT EXISTS purchase_requests (
        id INT AUTO_INCREMENT PRIMARY KEY,
        project_id INT,
        item_id INT,
        quantity_needed DECIMAL(10,2) NOT NULL,
        estimated_cost DECIMAL(10,2) NOT NULL,
        status VARCHAR(50) DEFAULT 'Pending',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (project_id) REFERENCES workshop_projects(id) ON DELETE CASCADE,
        FOREIGN KEY (item_id) REFERENCES inventory_items(id) ON DELETE CASCADE
    )");

    echo "Workshop and Inventory tables created successfully.\n";
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
