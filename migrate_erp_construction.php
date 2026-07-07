<?php
require_once __DIR__ . '/backend/core/Database.php';

try {
    $db = Database::getInstance()->getConnection();
    
    // 1. Rename fuel_suppliers to suppliers and add supplier_type
    try {
        $db->exec("RENAME TABLE fuel_suppliers TO suppliers");
    } catch (Exception $e) {}
    try {
        $db->exec("ALTER TABLE suppliers ADD COLUMN supplier_type SET('Fuel', 'Construction', 'Electrical', 'General') DEFAULT 'General'");
    } catch (Exception $e) {}

    // 2. Create purchase_orders
    $db->exec("
        CREATE TABLE IF NOT EXISTS purchase_orders (
            id INT AUTO_INCREMENT PRIMARY KEY,
            po_number VARCHAR(100) NOT NULL,
            supplier_id INT,
            construction_id INT,
            item_name VARCHAR(255),
            quantity_ordered DECIMAL(10,2),
            quantity_delivered DECIMAL(10,2) DEFAULT 0,
            quantity_remaining DECIMAL(10,2),
            unit_price DECIMAL(10,2),
            tva DECIMAL(5,2) DEFAULT 0,
            total_price DECIMAL(10,2),
            expected_delivery_date DATE,
            status ENUM('Draft', 'Pending Approval', 'Approved', 'Rejected', 'Partially Delivered', 'Delivered', 'Cancelled') DEFAULT 'Draft',
            payment_status ENUM('Unpaid', 'Partially Paid', 'Paid') DEFAULT 'Unpaid',
            amount_paid DECIMAL(10,2) DEFAULT 0,
            remaining_balance DECIMAL(10,2),
            payment_due_date DATE,
            attachment_url VARCHAR(255),
            notes TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            created_by INT
        )
    ");

    // 3. Create construction_site_stock
    $db->exec("
        CREATE TABLE IF NOT EXISTS construction_site_stock (
            id INT AUTO_INCREMENT PRIMARY KEY,
            construction_id INT,
            item_name VARCHAR(255),
            quantity DECIMAL(10,2) DEFAULT 0,
            unit VARCHAR(50),
            last_updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    ");

    // 4. Create construction_material_movements
    $db->exec("
        CREATE TABLE IF NOT EXISTS construction_material_movements (
            id INT AUTO_INCREMENT PRIMARY KEY,
            construction_id INT,
            item_name VARCHAR(255),
            type ENUM('Warehouse_To_Site', 'Supplier_To_Site', 'Site_To_Warehouse', 'Site_To_Consumption', 'Site_To_Waste'),
            quantity DECIMAL(10,2),
            reference_id INT,
            user_id INT,
            notes TEXT,
            date DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ");

    // 5. Update construction_materials
    try {
        $db->exec("
            ALTER TABLE construction_materials 
            ADD COLUMN wasted_quantity DECIMAL(10,2) DEFAULT 0 AFTER used_quantity,
            ADD COLUMN waste_reason TEXT AFTER wasted_quantity
        ");
    } catch (Exception $e) {}

    // 6. Product Price History
    $db->exec("
        CREATE TABLE IF NOT EXISTS product_price_history (
            id INT AUTO_INCREMENT PRIMARY KEY,
            product_id INT,
            price DECIMAL(10,2),
            changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            changed_by INT
        )
    ");

    // 7. Update products
    try {
        $db->exec("ALTER TABLE products ADD COLUMN is_construction_material BOOLEAN DEFAULT FALSE");
    } catch (Exception $e) {}

    // 8. Update expenses
    try {
        $db->exec("ALTER TABLE expenses ADD COLUMN expense_type ENUM('Materials', 'Labor', 'Equipment', 'Transport', 'Fuel', 'Miscellaneous', 'General') DEFAULT 'General'");
    } catch (Exception $e) {}

    echo "Migration completed successfully!\n";
} catch (PDOException $e) {
    echo "Fatal Error: " . $e->getMessage() . "\n";
}
