<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/core/Database.php';

try {
    $db = Database::getInstance()->getConnection();
    
    $sql = "CREATE TABLE IF NOT EXISTS rent_collection_requests (
        id INT(11) AUTO_INCREMENT PRIMARY KEY,
        tenant_id INT(11) NOT NULL,
        contract_id INT(11) NOT NULL,
        apartment_id INT(11) NOT NULL,
        rent_period_id INT(11) NOT NULL,
        amount DECIMAL(10,2) NOT NULL,
        status ENUM('PENDING_RESPONSE', 'DENIED', 'SCHEDULED', 'COLLECTED', 'COMPLETED', 'CANCELLED', 'EXPIRED') DEFAULT 'PENDING_RESPONSE',
        denial_reason TEXT DEFAULT NULL,
        requested_collection_date DATE DEFAULT NULL,
        assigned_agent_id INT(11) DEFAULT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        confirmed_at DATETIME DEFAULT NULL,
        denied_at DATETIME DEFAULT NULL,
        collected_at DATETIME DEFAULT NULL,
        completed_at DATETIME DEFAULT NULL,
        UNIQUE KEY unique_request (contract_id, rent_period_id),
        FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
        FOREIGN KEY (contract_id) REFERENCES contracts(id) ON DELETE CASCADE,
        FOREIGN KEY (apartment_id) REFERENCES apartments(id) ON DELETE CASCADE,
        FOREIGN KEY (assigned_agent_id) REFERENCES users(id) ON DELETE SET NULL
    )";
    
    $db->exec($sql);
    echo "Table rent_collection_requests created successfully.\n";
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
