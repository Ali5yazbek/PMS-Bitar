<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/core/Database.php';

try {
    $db = Database::getInstance()->getConnection();
    
    $query = "
    CREATE TABLE IF NOT EXISTS `apartment_cost_deployments` (
      `id` int(11) NOT NULL AUTO_INCREMENT,
      `apartment_id` int(11) NOT NULL,
      `supplier_name` varchar(255) DEFAULT NULL,
      `amount` decimal(10,2) NOT NULL,
      `receipt_image` varchar(255) DEFAULT NULL,
      `notes` text DEFAULT NULL,
      `date` date NOT NULL,
      `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
      PRIMARY KEY (`id`),
      FOREIGN KEY (`apartment_id`) REFERENCES `apartments`(`id`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ";
    
    $db->exec($query);
    echo "Migration successful.\n";
} catch (Exception $e) {
    echo "Migration failed: " . $e->getMessage() . "\n";
}
