<?php
require 'backend/config.php';
require 'backend/core/Database.php';
$db = Database::getInstance()->getConnection();
$stmt = $db->query("SELECT id, name, role FROM users");
print_r($stmt->fetchAll(PDO::FETCH_ASSOC));
