<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/core/Database.php';

try {
    $db = Database::getInstance()->getConnection();
    
    $sql = "
    CREATE TABLE IF NOT EXISTS daily_reports (
        id INT AUTO_INCREMENT PRIMARY KEY,
        agent_id INT NOT NULL,
        building_id INT NOT NULL,
        apartments_visited TEXT,
        tasks_completed INT DEFAULT 0,
        issues_found TEXT,
        notes TEXT,
        start_time TIME,
        end_time TIME,
        status ENUM('Completed', 'Pending', 'Missing Photos') DEFAULT 'Pending',
        photos JSON NULL,
        date DATE NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (agent_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (building_id) REFERENCES buildings(id) ON DELETE CASCADE
    );
    ";
    
    $db->exec($sql);
    echo "Successfully created daily_reports table.\n";
} catch (PDOException $e) {
    die("Database setup failed: " . $e->getMessage() . "\n");
}
