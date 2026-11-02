<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/core/Database.php';
$db = Database::getInstance()->getConnection();

$tables = ['insurance_transactions'];
foreach($tables as $t) {
  try {
    $r = $db->query("DESCRIBE $t");
    echo "$t: " . implode(', ', array_column($r->fetchAll(PDO::FETCH_ASSOC), 'Field')) . PHP_EOL;
  } catch(Exception $e) {
    echo "$t error: " . $e->getMessage() . PHP_EOL;
  }
}
