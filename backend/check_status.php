<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/core/Database.php';
$db = Database::getInstance()->getConnection();
$r = $db->query("SELECT id, apartment_id, current_reading, status FROM agent_subscription_readings ORDER BY id DESC LIMIT 5");
print_r($r->fetchAll(PDO::FETCH_ASSOC));
