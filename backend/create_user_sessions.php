<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/core/Database.php';

try {
    $db = Database::getInstance()->getConnection();
    
    $sql = "CREATE TABLE IF NOT EXISTS user_sessions (
        user_id INT PRIMARY KEY,
        session_token VARCHAR(255),
        ip_address VARCHAR(45),
        user_agent TEXT,
        current_page VARCHAR(255),
        current_action VARCHAR(255),
        current_record_id INT,
        edit_mode VARCHAR(50),
        changed_fields TEXT,
        unsaved_changes TINYINT(1) DEFAULT 0,
        status VARCHAR(50) DEFAULT 'online',
        last_activity DATETIME
    )";
    
    $db->exec($sql);
    echo "Table user_sessions created successfully or already exists.\n";
    
    // Let's also check enterprise_activity_log
    $sql_eal = "CREATE TABLE IF NOT EXISTS enterprise_activity_log (
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
    
    $db->exec($sql_eal);
    echo "Table enterprise_activity_log created successfully or already exists.\n";
    
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
