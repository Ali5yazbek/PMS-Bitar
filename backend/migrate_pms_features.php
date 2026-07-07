<?php
require_once 'core/Database.php';

try {
    $db = Database::getInstance()->getConnection();
    
    // 1. Modify users table
    try {
        $db->exec("ALTER TABLE users MODIFY COLUMN role ENUM('admin', 'manager', 'tenant', 'maintenance', 'cashier') DEFAULT 'manager'");
        echo "users.role modified successfully.\n";
    } catch(Exception $e) { echo "Warning users: " . $e->getMessage() . "\n"; }

    // 2. Modify tenants table
    try {
        // Add columns if they don't exist
        $db->exec("ALTER TABLE tenants 
            ADD COLUMN user_id INT NULL AFTER id,
            ADD COLUMN address TEXT NULL,
            ADD COLUMN emergency_contact VARCHAR(255) NULL,
            ADD COLUMN passport_url VARCHAR(255) NULL,
            ADD COLUMN id_url VARCHAR(255) NULL,
            ADD COLUMN status ENUM('Active', 'Inactive') DEFAULT 'Active',
            ADD FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL");
        echo "tenants table altered successfully.\n";
    } catch(Exception $e) { echo "Warning tenants: " . $e->getMessage() . "\n"; }

    // 3. Modify contracts table
    try {
        $db->exec("ALTER TABLE contracts 
            ADD COLUMN monthly_rent DECIMAL(10,2) DEFAULT 0.00,
            ADD COLUMN monthly_insurance DECIMAL(10,2) DEFAULT 0.00,
            ADD COLUMN payment_terms TEXT NULL,
            ADD COLUMN contract_document_url VARCHAR(255) NULL,
            ADD COLUMN signed_document_url VARCHAR(255) NULL,
            ADD COLUMN manager_approval_date DATETIME NULL,
            MODIFY COLUMN status ENUM('Active', 'Terminated', 'Expired', 'Draft', 'Pending_Signature', 'Signed', 'Approved', 'Rejected', 'Renewal_Pending') DEFAULT 'Draft'");
        echo "contracts table altered successfully.\n";
    } catch(Exception $e) { echo "Warning contracts: " . $e->getMessage() . "\n"; }

    // 4. Create renewal_requests table
    try {
        $db->exec("CREATE TABLE IF NOT EXISTS renewal_requests (
            id INT AUTO_INCREMENT PRIMARY KEY,
            contract_id INT NOT NULL,
            status ENUM('Requested', 'Declined', 'Approved', 'Pending') DEFAULT 'Pending',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (contract_id) REFERENCES contracts(id) ON DELETE CASCADE
        )");
        echo "renewal_requests table created successfully.\n";
    } catch(Exception $e) { echo "Warning renewal_requests: " . $e->getMessage() . "\n"; }

    // 5. Create apartment_expenses table
    try {
        $db->exec("CREATE TABLE IF NOT EXISTS apartment_expenses (
            id INT AUTO_INCREMENT PRIMARY KEY,
            apartment_id INT NOT NULL,
            product_id INT NOT NULL,
            quantity INT NOT NULL,
            cost DECIMAL(10,2) NOT NULL,
            total DECIMAL(10,2) NOT NULL,
            date DATE NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (apartment_id) REFERENCES apartments(id) ON DELETE CASCADE,
            FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT
        )");
        echo "apartment_expenses table created successfully.\n";
    } catch(Exception $e) { echo "Warning apartment_expenses: " . $e->getMessage() . "\n"; }

    echo "Migration completed successfully.\n";
} catch(Exception $e) {
    echo "Fatal Error: " . $e->getMessage();
}
