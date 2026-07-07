<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/core/Database.php';
$db = Database::getInstance()->getConnection();

echo "=== electricity_meter_readings columns ===\n";
$r = $db->query('SHOW COLUMNS FROM electricity_meter_readings');
foreach ($r->fetchAll(PDO::FETCH_ASSOC) as $c) {
    echo $c['Field'] . " - " . $c['Type'] . "\n";
}

echo "\n=== Sample data in electricity_meter_readings ===\n";
$r = $db->query('SELECT id, apartment_id, current_reading, reading_date, status FROM electricity_meter_readings ORDER BY id DESC LIMIT 5');
foreach ($r->fetchAll(PDO::FETCH_ASSOC) as $row) {
    print_r($row);
}

echo "\n=== Sample data in electricity_subscriptions (with apartment/building) ===\n";
$r = $db->query('
    SELECT es.id, es.apartment_id, es.start_date, es.end_date, es.status,
           a.code as apt_code, b.name as building_name
    FROM electricity_subscriptions es
    JOIN apartments a ON es.apartment_id = a.id
    JOIN buildings b ON a.building_id = b.id
    LIMIT 5
');
foreach ($r->fetchAll(PDO::FETCH_ASSOC) as $row) {
    print_r($row);
}

echo "\n=== Previous readings for subscribed apartments ===\n";
$r = $db->query('
    SELECT 
        es.id as sub_id, es.apartment_id, es.end_date,
        a.code as apt_code, b.name as building_name,
        (SELECT current_reading FROM electricity_meter_readings 
         WHERE apartment_id = a.id ORDER BY reading_date DESC, id DESC LIMIT 1) as prev_reading,
        (SELECT reading_date FROM electricity_meter_readings 
         WHERE apartment_id = a.id ORDER BY reading_date DESC, id DESC LIMIT 1) as prev_date
    FROM electricity_subscriptions es
    JOIN apartments a ON es.apartment_id = a.id
    JOIN buildings b ON a.building_id = b.id
    WHERE es.status = "Active"
    LIMIT 5
');
foreach ($r->fetchAll(PDO::FETCH_ASSOC) as $row) {
    print_r($row);
}

// Check if billing_month/year exist
echo "\n=== Adding billing_month/billing_year if missing ===\n";
try {
    $db->exec("ALTER TABLE electricity_meter_readings ADD COLUMN IF NOT EXISTS billing_month TINYINT DEFAULT NULL");
    $db->exec("ALTER TABLE electricity_meter_readings ADD COLUMN IF NOT EXISTS billing_year SMALLINT DEFAULT NULL");
    echo "Columns ensured.\n";
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
