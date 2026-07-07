<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/core/Database.php';
$db = Database::getInstance()->getConnection();

// Check electricity_subscriptions columns
$r = $db->query('SHOW COLUMNS FROM electricity_subscriptions');
echo "electricity_subscriptions columns:\n";
foreach($r->fetchAll(PDO::FETCH_ASSOC) as $c) {
    echo $c['Field'] . " - " . $c['Type'] . "\n";
}

// Add last_meter_reading if not exists
try {
    $db->exec("ALTER TABLE electricity_subscriptions ADD COLUMN IF NOT EXISTS last_meter_reading DECIMAL(12,2) DEFAULT NULL");
    echo "\n✅ last_meter_reading column ensured\n";
} catch(Exception $e) {
    echo "\n⚠️ " . $e->getMessage() . "\n";
}
