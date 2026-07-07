<?php
require_once 'core/Database.php';
$db = Database::getInstance()->getConnection();

try {
    $db->exec("ALTER TABLE generator_daily_reports ADD COLUMN previous_kwh DECIMAL(10,2) DEFAULT NULL");
    $db->exec("ALTER TABLE generator_daily_reports ADD COLUMN current_kwh DECIMAL(10,2) DEFAULT NULL");
    $db->exec("ALTER TABLE generator_daily_reports ADD COLUMN efficiency_score DECIMAL(10,2) DEFAULT NULL");
    $db->exec("ALTER TABLE generator_daily_reports ADD COLUMN alert_level ENUM('Normal', 'Warning', 'Critical') DEFAULT 'Normal'");
    echo "generator_daily_reports updated successfully.\n";
} catch(Exception $e) {
    echo "Error updating generator_daily_reports: " . $e->getMessage() . "\n";
}

try {
    $db->exec("
        CREATE TABLE IF NOT EXISTS generator_alerts (
            id INT AUTO_INCREMENT PRIMARY KEY,
            generator_id INT NOT NULL,
            report_id INT DEFAULT NULL,
            alert_type VARCHAR(100) NOT NULL,
            message TEXT NOT NULL,
            severity ENUM('Warning', 'Critical', 'Info') NOT NULL DEFAULT 'Warning',
            status ENUM('Unread', 'Read', 'Resolved') DEFAULT 'Unread',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (generator_id) REFERENCES generators(id) ON DELETE CASCADE,
            FOREIGN KEY (report_id) REFERENCES generator_daily_reports(id) ON DELETE SET NULL
        )
    ");
    echo "generator_alerts created successfully.\n";
} catch(Exception $e) {
    echo "Error creating generator_alerts: " . $e->getMessage() . "\n";
}
