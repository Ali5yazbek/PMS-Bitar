<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/core/Database.php';
$db = Database::getInstance()->getConnection();
$r = $db->query('SHOW TABLES');
print_r($r->fetchAll(PDO::FETCH_COLUMN));
