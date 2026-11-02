<?php
require_once 'core/Database.php';

$db = Database::getInstance()->getConnection();
$stmt = $db->query("SELECT * FROM activity_logs ORDER BY created_at DESC LIMIT 10");
$logs = $stmt->fetchAll(PDO::FETCH_ASSOC);

print_r($logs);
