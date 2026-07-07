<?php
require 'config.php';
$pdo = new PDO('mysql:host=' . DB_HOST . ';dbname=' . DB_NAME, DB_USER, DB_PASS);
$pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);

$tables = $pdo->query('SHOW TABLES')->fetchAll(PDO::FETCH_COLUMN);
$refs = [];
foreach($tables as $table) {
    try {
        $cols = $pdo->query("DESCRIBE `$table`")->fetchAll(PDO::FETCH_COLUMN);
        if (in_array('tenant_id', $cols)) {
            $refs[] = $table;
        }
    } catch(Exception $e) {}
}
echo "Tables with tenant_id: \n" . implode("\n", $refs) . "\n";
