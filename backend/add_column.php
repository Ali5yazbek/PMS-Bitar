<?php
require_once __DIR__ . '/core/Database.php';
$db = Database::getInstance()->getConnection();
try {
    $db->exec('ALTER TABLE generators ADD COLUMN last_maintenance_hours DECIMAL(10,2) DEFAULT 0');
    echo 'Added column successfully';
} catch (PDOException $e) {
    if (strpos($e->getMessage(), 'Duplicate column name') !== false) {
        echo 'Column already exists';
    } else {
        echo 'Error: ' . $e->getMessage();
    }
}
