<?php
require 'core/Database.php';
$db = Database::getInstance()->getConnection();
$stmt = $db->query('SELECT id, name FROM generators');
print_r($stmt->fetchAll(PDO::FETCH_ASSOC));
