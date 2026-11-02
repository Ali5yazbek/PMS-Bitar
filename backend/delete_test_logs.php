<?php
require 'core/Database.php';
$db = Database::getInstance()->getConnection();
$db->exec("DELETE FROM daily_logs WHERE submitted_hours = 2000");
echo "Deleted test logs";
