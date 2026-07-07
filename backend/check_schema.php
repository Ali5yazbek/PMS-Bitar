<?php
require_once 'core/Database.php';
$db = Database::getInstance()->getConnection();

$stmt = $db->query("DESCRIBE generator_daily_reports");
$reports = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo "generator_daily_reports columns:\n";
foreach($reports as $r) {
    echo $r['Field'] . " - " . $r['Type'] . "\n";
}

$stmt = $db->query("SHOW TABLES LIKE 'generator_alerts'");
$alerts = $stmt->fetchAll();
if(empty($alerts)) {
    echo "generator_alerts does not exist.\n";
} else {
    echo "generator_alerts exists.\n";
}
