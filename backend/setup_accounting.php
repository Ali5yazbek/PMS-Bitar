<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/core/Database.php';

$db = Database::getInstance()->getConnection();

try {
    // Constructions Table
    $db->exec("CREATE TABLE IF NOT EXISTS constructions (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        owner VARCHAR(255),
        location VARCHAR(255),
        start_date DATE,
        end_date DATE,
        status VARCHAR(50) DEFAULT 'Planning',
        budget DECIMAL(10,2) DEFAULT 0.00,
        estimated_cost DECIMAL(10,2) DEFAULT 0.00,
        actual_cost DECIMAL(10,2) DEFAULT 0.00,
        manager VARCHAR(255),
        notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )");

    // Expenses Table
    $db->exec("CREATE TABLE IF NOT EXISTS expenses (
        id INT AUTO_INCREMENT PRIMARY KEY,
        category VARCHAR(50) NOT NULL, -- Construction, Apartment, Building, Warehouse, Office, Transport, Maintenance, Labor, Utilities, Other
        entity_type VARCHAR(50), -- Construction, Apartment, Building
        entity_id INT,
        amount DECIMAL(10,2) NOT NULL,
        date DATE NOT NULL,
        notes TEXT,
        reference_id VARCHAR(100), -- E.g. Invoice Number
        user_id INT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
    )");

    // Modify Invoices Table Customer Type
    $db->exec("ALTER TABLE invoices MODIFY COLUMN customer_type ENUM('Walk-In', 'Building', 'Apartment', 'Construction') DEFAULT 'Walk-In'");

    echo "Accounting and Construction tables created successfully.\n";
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
