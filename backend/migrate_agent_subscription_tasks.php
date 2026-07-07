<?php
// Migration: Create agent_subscription_readings table
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/core/Database.php';

$db = Database::getInstance()->getConnection();

$sql = "
CREATE TABLE IF NOT EXISTS agent_subscription_readings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    apartment_id INT NOT NULL,
    subscription_id INT NOT NULL,
    building_name VARCHAR(255),
    apartment_code VARCHAR(50),
    tenant_name VARCHAR(255),
    previous_reading DECIMAL(12,2) DEFAULT 0,
    current_reading DECIMAL(12,2) DEFAULT NULL,
    consumption DECIMAL(12,2) DEFAULT NULL,
    notes TEXT,
    photo_path VARCHAR(500),
    status ENUM('Pending','Accepted','Rejected') DEFAULT 'Pending',
    rejection_reason TEXT,
    submitted_by INT,
    reviewed_by INT,
    reviewed_at DATETIME,
    billing_month INT,
    billing_year INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (apartment_id) REFERENCES apartments(id) ON DELETE CASCADE,
    FOREIGN KEY (subscription_id) REFERENCES electricity_subscriptions(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
";

try {
    $db->exec($sql);
    echo "✅ Table agent_subscription_readings created successfully.\n";

    // Also add a 'seen_by_agent' column to notifications if it doesn't exist
    $db->exec("ALTER TABLE notifications ADD COLUMN IF NOT EXISTS seen_by_agent TINYINT(1) DEFAULT 0");
    echo "✅ notifications.seen_by_agent column ensured.\n";

} catch (PDOException $e) {
    echo "❌ Migration failed: " . $e->getMessage() . "\n";
}
