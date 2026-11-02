<?php
require 'config.php';
require 'core/Database.php';
$db = Database::getInstance()->getConnection();
$stmt = $db->query('DESCRIBE tenants');
print_r($stmt->fetchAll(PDO::FETCH_ASSOC));
