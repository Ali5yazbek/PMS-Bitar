<?php
require_once __DIR__ . '/config.php';

try {
    $dsn = "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4";
    $pdo = new PDO($dsn, DB_USER, DB_PASS, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
    ]);
    
    echo "Connected to DB successfully.\n";

    // 1. Ensure global_settings table has company_logo
    $stmt = $pdo->query("SELECT COUNT(*) FROM global_settings WHERE setting_key = 'company_logo'");
    if ($stmt->fetchColumn() == 0) {
        $pdo->exec("INSERT INTO global_settings (setting_key, setting_value) VALUES ('company_logo', '')");
        echo "Added company_logo to global_settings.\n";
    }

    // 2. Alter invoices table
    try {
        $pdo->exec("ALTER TABLE invoices ADD COLUMN payment_type ENUM('Cash', 'Card', 'Bank', 'Transfer', 'Mixed', 'Account') DEFAULT 'Cash'");
        echo "Added payment_type to invoices.\n";
    } catch (PDOException $e) {
        if (strpos($e->getMessage(), 'Duplicate column name') === false) {
            throw $e;
        }
    }
    
    try {
        $pdo->exec("ALTER TABLE invoices ADD COLUMN status ENUM('Active', 'Returned', 'Refunded', 'Cancelled') DEFAULT 'Active'");
        echo "Added status to invoices.\n";
    } catch (PDOException $e) {
        if (strpos($e->getMessage(), 'Duplicate column name') === false) {
            throw $e;
        }
    }
    
    try {
        $pdo->exec("ALTER TABLE invoices ADD COLUMN returned_amount DECIMAL(10,2) DEFAULT 0.00");
        echo "Added returned_amount to invoices.\n";
    } catch (PDOException $e) {
        if (strpos($e->getMessage(), 'Duplicate column name') === false) {
            throw $e;
        }
    }

    // 3. Create returns table
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS returns (
            id INT AUTO_INCREMENT PRIMARY KEY,
            original_invoice_id INT NOT NULL,
            return_invoice_number VARCHAR(100) NOT NULL UNIQUE,
            date DATE NOT NULL,
            total_refunded DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            reason TEXT NULL,
            created_by INT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ");
    echo "Created returns table.\n";

    // 4. Create return_items table
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS return_items (
            id INT AUTO_INCREMENT PRIMARY KEY,
            return_id INT NOT NULL,
            product_id INT NOT NULL,
            quantity INT NOT NULL,
            price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (return_id) REFERENCES returns(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ");
    echo "Created return_items table.\n";

    // 5. Create sales_audits table
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS sales_audits (
            id INT AUTO_INCREMENT PRIMARY KEY,
            invoice_id INT NOT NULL,
            user_id INT NULL,
            action VARCHAR(50) NOT NULL,
            old_values JSON NULL,
            new_values JSON NULL,
            reason TEXT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ");
    echo "Created sales_audits table.\n";

    echo "Migration completed successfully!\n";
} catch (PDOException $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
