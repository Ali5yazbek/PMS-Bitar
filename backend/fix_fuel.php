<?php
require 'core/Database.php';
$db = Database::getInstance()->getConnection();
$db->exec("UPDATE generators SET current_fuel = 1163.32 WHERE id = 13");
echo "Fixed generator fuel\n";
