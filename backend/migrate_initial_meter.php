<?php
require 'core/Database.php';
$db = Database::getInstance()->getConnection();
$db->exec("ALTER TABLE generators ADD COLUMN initial_meter_reading DECIMAL(10,2) DEFAULT 0 AFTER current_fuel");
// Set Cornishe to 1917.69
$db->exec("UPDATE generators SET initial_meter_reading = 1917.69 WHERE id = 13");
echo "Column added and updated successfully\n";
