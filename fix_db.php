<?php
require 'backend/config.php';
require 'backend/core/Database.php';
$db = Database::getInstance()->getConnection();

$stmt = $db->prepare("SELECT id FROM users WHERE name = 'Mohamad'");
$stmt->execute();
if (!$stmt->fetch()) {
    $db->query("INSERT INTO users (name, email, password, role) VALUES ('Mohamad', 'mohamad@example.com', '12345', 'maintenance')");
    echo "Created Mohamad.\n";
} else {
    echo "Mohamad already exists.\n";
}
