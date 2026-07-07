<?php
require_once __DIR__ . '/backend/core/Database.php';

$db = Database::getInstance()->getConnection();

try {
    $db->exec("
        ALTER TABLE suppliers 
        ADD COLUMN credit_limit DECIMAL(15,2) DEFAULT 0.00,
        ADD COLUMN payment_terms_days INT DEFAULT 30,
        ADD COLUMN opening_balance DECIMAL(15,2) DEFAULT 0.00,
        ADD COLUMN opening_balance_date DATE DEFAULT NULL
    ");
    echo "Added supplier fields.\n";
} catch (Exception $e) {
    echo "Supplier fields already exist or error: " . $e->getMessage() . "\n";
}

try {
    $db->exec("
        ALTER TABLE purchase_orders
        ADD COLUMN invoice_date DATE DEFAULT NULL,
        ADD COLUMN due_date DATE DEFAULT NULL
    ");
    echo "Added purchase_orders fields.\n";
} catch (Exception $e) {
    echo "purchase_orders fields already exist or error: " . $e->getMessage() . "\n";
}

try {
    $db->exec("
        CREATE TABLE IF NOT EXISTS supplier_payments (
            id INT AUTO_INCREMENT PRIMARY KEY,
            supplier_id INT NOT NULL,
            amount DECIMAL(15,2) NOT NULL,
            payment_date DATE NOT NULL,
            payment_method VARCHAR(50),
            reference_number VARCHAR(100),
            bank_name VARCHAR(100),
            notes TEXT,
            attachment_url VARCHAR(255),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            created_by INT
        )
    ");
    echo "Created supplier_payments.\n";
} catch (Exception $e) {
    echo "Error creating supplier_payments: " . $e->getMessage() . "\n";
}

try {
    $db->exec("
        CREATE TABLE IF NOT EXISTS supplier_payment_allocations (
            id INT AUTO_INCREMENT PRIMARY KEY,
            payment_id INT NOT NULL,
            purchase_order_id INT NOT NULL,
            amount DECIMAL(15,2) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ");
    echo "Created supplier_payment_allocations.\n";
} catch (Exception $e) {
    echo "Error creating supplier_payment_allocations: " . $e->getMessage() . "\n";
}

try {
    $db->exec("
        CREATE TABLE IF NOT EXISTS supplier_transactions (
            id INT AUTO_INCREMENT PRIMARY KEY,
            supplier_id INT NOT NULL,
            type ENUM('Purchase', 'Payment', 'Return', 'Opening Balance', 'Adjustment') NOT NULL,
            reference_id VARCHAR(100) NOT NULL,
            amount DECIMAL(15,2) NOT NULL,
            balance_after DECIMAL(15,2) DEFAULT 0.00,
            transaction_date DATE NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ");
    echo "Created supplier_transactions.\n";
} catch (Exception $e) {
    echo "Error creating supplier_transactions: " . $e->getMessage() . "\n";
}

echo "Migration Complete.\n";
