<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/core/Database.php';

try {
    $db = Database::getInstance()->getConnection();
    
    // 1. Update users.role ENUM
    echo "Updating users.role ENUM...\n";
    $db->exec("ALTER TABLE users MODIFY COLUMN role ENUM('admin', 'manager', 'cashier', 'maintenance') DEFAULT 'manager'");
    echo "Done.\n";

    // 2. Create ac_maintenance_tasks table
    echo "Creating ac_maintenance_tasks table...\n";
    $db->exec("CREATE TABLE IF NOT EXISTS ac_maintenance_tasks (
        id INT AUTO_INCREMENT PRIMARY KEY,
        apartment_id INT NOT NULL,
        worker_id INT NULL,
        scheduled_date DATE NOT NULL,
        status ENUM('Scheduled', 'Pending_Approval', 'Completed', 'Rejected') DEFAULT 'Scheduled',
        before_photo LONGTEXT NULL,
        after_photo LONGTEXT NULL,
        notes TEXT NULL,
        submission_date DATETIME NULL,
        completion_date DATETIME NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (apartment_id) REFERENCES apartments(id) ON DELETE CASCADE,
        FOREIGN KEY (worker_id) REFERENCES users(id) ON DELETE SET NULL
    )");
    echo "Done.\n";

    // 3. Auto-schedule for existing apartments
    echo "Auto-scheduling AC maintenance for existing apartments...\n";
    $stmt = $db->query("SELECT id FROM apartments WHERE id NOT IN (SELECT apartment_id FROM ac_maintenance_tasks)");
    $apartments = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    $today = date('Y-m-d');
    $insertStmt = $db->prepare("INSERT INTO ac_maintenance_tasks (apartment_id, scheduled_date, status) VALUES (?, ?, 'Scheduled')");
    
    $count = 0;
    foreach ($apartments as $apt) {
        $insertStmt->execute([$apt['id'], $today]);
        $count++;
    }
    echo "Scheduled $count initial AC maintenance tasks.\n";
    
    echo "Migration completed successfully.\n";

} catch (Exception $e) {
    echo "Error during migration: " . $e->getMessage() . "\n";
}
