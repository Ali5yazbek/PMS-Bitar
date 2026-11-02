<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/core/Database.php';

try {
    $db = Database::getInstance()->getConnection();
    
    $logs = ['security_activity_log', 'financial_activity_log', 'system_activity_log'];
    
    foreach ($logs as $table) {
        $sql = "CREATE TABLE IF NOT EXISTS $table (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT,
            user_name VARCHAR(255),
            role VARCHAR(50),
            department VARCHAR(100),
            action VARCHAR(50),
            module VARCHAR(100),
            record_id INT,
            description TEXT,
            status VARCHAR(50) DEFAULT 'success',
            severity VARCHAR(50) DEFAULT 'info',
            ip_address VARCHAR(45),
            device_info TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )";
        $db->exec($sql);
        echo "Table $table created or already exists.\n";
    }
    
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
