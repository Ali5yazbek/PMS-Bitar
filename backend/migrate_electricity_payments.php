<?php
require_once __DIR__ . '/config.php';

try {
    $db = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASS);
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // 1. Add amount_paid and update status enum in electricity_invoices
    try {
        $db->exec("ALTER TABLE electricity_invoices ADD COLUMN amount_paid DECIMAL(10,2) NOT NULL DEFAULT 0");
        echo "Added amount_paid to electricity_invoices.\n";
    } catch (PDOException $e) {
        echo "Column amount_paid may already exist: " . $e->getMessage() . "\n";
    }

    try {
        $db->exec("ALTER TABLE electricity_invoices MODIFY COLUMN status ENUM('Unpaid', 'Partially Paid', 'Paid') DEFAULT 'Unpaid'");
        echo "Updated status enum in electricity_invoices.\n";
    } catch (PDOException $e) {
        echo "Failed to update status enum: " . $e->getMessage() . "\n";
    }

    // 2. Add next_billing_date to electricity_subscriptions
    try {
        $db->exec("ALTER TABLE electricity_subscriptions ADD COLUMN next_billing_date DATE NULL");
        echo "Added next_billing_date to electricity_subscriptions.\n";
    } catch (PDOException $e) {
        echo "Column next_billing_date may already exist: " . $e->getMessage() . "\n";
    }

    // 3. Initialize next_billing_date for existing subscriptions
    try {
        $db->exec("UPDATE electricity_subscriptions SET next_billing_date = DATE_ADD(start_date, INTERVAL 1 MONTH) WHERE next_billing_date IS NULL AND status = 'Active'");
        echo "Initialized next_billing_date for active subscriptions.\n";
    } catch (PDOException $e) {
        echo "Failed to initialize next_billing_date: " . $e->getMessage() . "\n";
    }

    echo "Migration completed successfully.\n";
} catch (PDOException $e) {
    echo "Database connection error: " . $e->getMessage() . "\n";
}
