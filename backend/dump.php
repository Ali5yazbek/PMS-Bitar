<?php
$db = new PDO('mysql:host=localhost;dbname=bitar_pms', 'root', '');
$tables = ['electricity_subscriptions', 'electricity_meter_readings', 'agent_subscription_readings', 'electricity_invoices', 'notifications'];
foreach ($tables as $table) {
    echo "--- $table ---\n";
    $stmt = $db->query("DESCRIBE $table");
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        echo $row['Field'] . " " . $row['Type'] . "\n";
    }
    echo "\n";
}
?>
