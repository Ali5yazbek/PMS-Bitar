<?php
require_once __DIR__ . '/config.php';

try {
    $dsn = "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4";
    $pdo = new PDO($dsn, DB_USER, DB_PASS, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
    ]);
    
    echo "Connected to DB successfully.\n";

    // 1. global_settings updates
    $newSettings = [
        'company_name' => 'Bitar Group Ltd',
        'business_address' => '123 Construction Blvd, Industry City',
        'phone' => '+1 234 567 8900',
        'email' => 'accounts@bitar.com',
        'website' => 'www.bitar.com',
        'tax_number' => 'TIN-987654321',
        'registration_number' => 'REG-123456',
        'currency' => 'CFA',
        'footer_message' => 'Thank you for your business!',
        'receipt_header' => 'RECEIPT',
        'receipt_footer' => 'No returns after 30 days.'
    ];

    $stmt = $pdo->prepare("INSERT INTO global_settings (setting_key, setting_value) VALUES (?, ?) ON DUPLICATE KEY UPDATE setting_value = setting_value");
    foreach ($newSettings as $key => $val) {
        $stmt->execute([$key, $val]);
    }
    echo "Added new global_settings.\n";

    // 2. invoices table updates
    // Check if customer_type is an ENUM. If yes, alter it.
    try {
        $pdo->exec("ALTER TABLE invoices MODIFY COLUMN customer_type ENUM('Walk In', 'Account', 'Apartment', 'Construction', 'Building', 'Supplier', 'Employee', 'Government', 'Other', 'Walk-In') DEFAULT 'Walk In'");
        echo "Updated customer_type enum in invoices.\n";
    } catch (Exception $e) { echo "Warning on customer_type: " . $e->getMessage() . "\n"; }

    try {
        $pdo->exec("ALTER TABLE invoices MODIFY COLUMN payment_type ENUM('Cash', 'Card', 'Bank', 'Transfer', 'Cheque', 'Account', 'Mixed') DEFAULT 'Cash'");
        echo "Updated payment_type enum in invoices.\n";
    } catch (Exception $e) { echo "Warning on payment_type: " . $e->getMessage() . "\n"; }

    try {
        $pdo->exec("ALTER TABLE invoices MODIFY COLUMN status ENUM('Paid', 'Partial', 'Pending', 'Cancelled', 'Refunded', 'Returned', 'Active') DEFAULT 'Paid'");
        echo "Updated status enum in invoices.\n";
    } catch (Exception $e) { echo "Warning on status: " . $e->getMessage() . "\n"; }

    // Add new columns to invoices
    $invColumns = [
        'invoice_time' => 'TIME NULL',
        'tax' => 'DECIMAL(10,2) DEFAULT 0.00',
        'discount' => 'DECIMAL(10,2) DEFAULT 0.00',
        'notes' => 'TEXT NULL',
        'reason' => 'TEXT NULL'
    ];
    foreach ($invColumns as $col => $def) {
        try {
            $pdo->exec("ALTER TABLE invoices ADD COLUMN $col $def");
            echo "Added $col to invoices.\n";
        } catch (PDOException $e) {
            if (strpos($e->getMessage(), 'Duplicate column name') === false) { echo "Warning: " . $e->getMessage() . "\n"; }
        }
    }

    // 3. returns table updates
    $retColumns = [
        'status' => "ENUM('Pending', 'Approved', 'Rejected', 'Completed') DEFAULT 'Completed'",
        'photo' => "VARCHAR(255) NULL",
        'manager_approval_id' => "INT NULL",
        'refund_method' => "ENUM('Cash', 'Bank', 'Account Credit', 'Store Credit') DEFAULT 'Cash'"
    ];
    foreach ($retColumns as $col => $def) {
        try {
            $pdo->exec("ALTER TABLE returns ADD COLUMN $col $def");
            echo "Added $col to returns.\n";
        } catch (PDOException $e) {
            if (strpos($e->getMessage(), 'Duplicate column name') === false) { echo "Warning: " . $e->getMessage() . "\n"; }
        }
    }

    // 4. return_items table updates
    try {
        $pdo->exec("ALTER TABLE return_items ADD COLUMN return_condition ENUM('Good', 'Damaged', 'Expired', 'Lost Packaging') DEFAULT 'Good'");
        echo "Added return_condition to return_items.\n";
    } catch (PDOException $e) {
        if (strpos($e->getMessage(), 'Duplicate column name') === false) { echo "Warning: " . $e->getMessage() . "\n"; }
    }

    // 5. sales_audits table updates
    try {
        $pdo->exec("ALTER TABLE sales_audits ADD COLUMN ip_address VARCHAR(45) NULL");
        echo "Added ip_address to sales_audits.\n";
    } catch (PDOException $e) {
        if (strpos($e->getMessage(), 'Duplicate column name') === false) { echo "Warning: " . $e->getMessage() . "\n"; }
    }
    try {
        $pdo->exec("ALTER TABLE sales_audits ADD COLUMN device VARCHAR(255) NULL");
        echo "Added device to sales_audits.\n";
    } catch (PDOException $e) {
        if (strpos($e->getMessage(), 'Duplicate column name') === false) { echo "Warning: " . $e->getMessage() . "\n"; }
    }
    try {
        $pdo->exec("ALTER TABLE sales_audits MODIFY COLUMN old_values JSON NULL");
        $pdo->exec("ALTER TABLE sales_audits MODIFY COLUMN new_values JSON NULL");
        echo "Ensured old_values and new_values are JSON in sales_audits.\n";
    } catch (Exception $e) { echo "Warning: " . $e->getMessage() . "\n"; }

    // 6. Create cashier_sessions table
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS cashier_sessions (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL,
            opened_at DATETIME NOT NULL,
            closed_at DATETIME NULL,
            opening_cash DECIMAL(10,2) NOT NULL DEFAULT 0.00,
            closing_cash DECIMAL(10,2) NULL,
            total_sales DECIMAL(10,2) DEFAULT 0.00,
            total_refunds DECIMAL(10,2) DEFAULT 0.00,
            total_expenses DECIMAL(10,2) DEFAULT 0.00,
            status ENUM('Open', 'Closed') DEFAULT 'Open',
            notes TEXT NULL,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ");
    echo "Created cashier_sessions table.\n";

    echo "Phase 2 Migration completed successfully!\n";
} catch (PDOException $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
