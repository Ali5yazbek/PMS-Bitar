<?php
require 'backend/config.php';
require 'backend/core/Database.php';

$db = Database::getInstance()->getConnection();
$tables = $db->query('SHOW TABLES')->fetchAll(PDO::FETCH_COLUMN);

foreach ($tables as $t) {
    echo "\nTable: $t\n";
    $desc = $db->query("DESCRIBE $t")->fetchAll(PDO::FETCH_ASSOC);
    foreach ($desc as $c) {
        echo $c['Field'].' - '.$c['Type']."\n";
    }
}
