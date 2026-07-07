<?php
require 'backend/core/Database.php';
require 'backend/config.php';
$db = Database::getInstance()->getConnection();
$stmt = $db->query("SELECT id, status, worker_id, length(before_photo) as b_len, length(after_photo) as a_len FROM ac_maintenance_tasks WHERE status != 'Scheduled'");
$tasks = $stmt->fetchAll(PDO::FETCH_ASSOC);
print_r($tasks);

// also print all scheduled
$stmt2 = $db->query("SELECT count(*) as c FROM ac_maintenance_tasks WHERE status = 'Scheduled'");
print_r($stmt2->fetchAll(PDO::FETCH_ASSOC));
