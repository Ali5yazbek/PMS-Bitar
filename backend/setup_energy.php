<?php
require_once __DIR__ . '/core/Database.php';

try {
    $db = Database::getInstance()->getConnection();
    
    // Create generators table
    $db->exec("CREATE TABLE IF NOT EXISTS generators (
        id INT AUTO_INCREMENT PRIMARY KEY,
        building_id INT NOT NULL,
        name VARCHAR(255) NOT NULL,
        brand VARCHAR(255),
        model VARCHAR(255),
        serial_number VARCHAR(255),
        capacity_kva DECIMAL(10,2),
        fuel_capacity DECIMAL(10,2) NOT NULL DEFAULT 0,
        current_fuel DECIMAL(10,2) NOT NULL DEFAULT 0,
        spare_fuel DECIMAL(10,2) NOT NULL DEFAULT 0,
        purchase_date DATE,
        status ENUM('Running', 'Maintenance', 'Offline') DEFAULT 'Offline',
        notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (building_id) REFERENCES buildings(id) ON DELETE CASCADE
    )");
    echo "Table 'generators' created or already exists.\n";

    // Create generator_daily_reports table
    $db->exec("CREATE TABLE IF NOT EXISTS generator_daily_reports (
        id INT AUTO_INCREMENT PRIMARY KEY,
        generator_id INT NOT NULL,
        date DATE NOT NULL,
        fuel_added DECIMAL(10,2) NOT NULL DEFAULT 0,
        fuel_remaining DECIMAL(10,2) NOT NULL DEFAULT 0,
        spare_remaining DECIMAL(10,2) NOT NULL DEFAULT 0,
        running_hours DECIMAL(10,2) NOT NULL DEFAULT 0,
        kwh_produced DECIMAL(10,2) NOT NULL DEFAULT 0,
        notes TEXT,
        photo_path VARCHAR(255),
        submitted_by INT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (generator_id) REFERENCES generators(id) ON DELETE CASCADE,
        FOREIGN KEY (submitted_by) REFERENCES users(id) ON DELETE SET NULL
    )");
    echo "Table 'generator_daily_reports' created or already exists.\n";

    // Create electricity_subscriptions table
    $db->exec("CREATE TABLE IF NOT EXISTS electricity_subscriptions (
        id INT AUTO_INCREMENT PRIMARY KEY,
        apartment_id INT NOT NULL UNIQUE,
        monthly_fee DECIMAL(10,2) NOT NULL DEFAULT 0,
        start_date DATE NOT NULL,
        next_billing_date DATE NULL,
        status ENUM('Active', 'Inactive') DEFAULT 'Active',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (apartment_id) REFERENCES apartments(id) ON DELETE CASCADE
    )");
    echo "Table 'electricity_subscriptions' created or already exists.\n";

    // Create electricity_meter_readings table
    $db->exec("CREATE TABLE IF NOT EXISTS electricity_meter_readings (
        id INT AUTO_INCREMENT PRIMARY KEY,
        apartment_id INT NOT NULL,
        meter_number VARCHAR(100),
        previous_reading DECIMAL(12,2) NOT NULL DEFAULT 0,
        current_reading DECIMAL(12,2) NOT NULL DEFAULT 0,
        price_per_kwh DECIMAL(10,2) NOT NULL DEFAULT 0,
        consumption DECIMAL(12,2) NOT NULL DEFAULT 0,
        bill_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
        reading_date DATE NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (apartment_id) REFERENCES apartments(id) ON DELETE CASCADE
    )");
    echo "Table 'electricity_meter_readings' created or already exists.\n";

    // Create electricity_invoices table
    $db->exec("CREATE TABLE IF NOT EXISTS electricity_invoices (
        id INT AUTO_INCREMENT PRIMARY KEY,
        apartment_id INT NOT NULL,
        type ENUM('Subscription', 'Meter') NOT NULL,
        amount DECIMAL(10,2) NOT NULL,
        amount_paid DECIMAL(10,2) NOT NULL DEFAULT 0,
        due_date DATE NOT NULL,
        status ENUM('Unpaid', 'Partially Paid', 'Paid') DEFAULT 'Unpaid',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (apartment_id) REFERENCES apartments(id) ON DELETE CASCADE
    )");
    echo "Table 'electricity_invoices' created or already exists.\n";

    // Create energy_alerts table
    $db->exec("CREATE TABLE IF NOT EXISTS energy_alerts (
        id INT AUTO_INCREMENT PRIMARY KEY,
        type ENUM('Warning', 'Info', 'Danger') NOT NULL,
        message TEXT NOT NULL,
        is_read BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )");
    echo "Table 'energy_alerts' created or already exists.\n";

    echo "Energy module database setup completed successfully.\n";
} catch (PDOException $e) {
    echo "Error setting up energy database tables: " . $e->getMessage() . "\n";
}
