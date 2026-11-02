<?php
require_once __DIR__ . '/config.php';
try {
    $db = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASS);
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $db->exec("ALTER TABLE agent_subscription_readings ADD COLUMN latitude DECIMAL(10,8) NULL, ADD COLUMN longitude DECIMAL(11,8) NULL");
    echo "Added GPS columns successfully.\n";
} catch (PDOException $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
