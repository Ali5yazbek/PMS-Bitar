<?php
require 'config.php';
require 'core/Database.php';
try {
    $db = Database::getInstance()->getConnection();
    $db->exec("ALTER TABLE contracts ADD COLUMN contract_file VARCHAR(255) NULL");
    echo "Column added successfully.\n";
} catch (PDOException $e) {
    if (strpos($e->getMessage(), 'Duplicate column name') !== false) {
        echo "Column already exists.\n";
    } else {
        echo "Error: " . $e->getMessage() . "\n";
    }
}
