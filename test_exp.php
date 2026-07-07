<?php
require 'backend/core/Database.php';
require 'backend/config.php';
$db = Database::getInstance()->getConnection();
$stmt=$db->query("SELECT id, amount, reference_id, category FROM expenses WHERE entity_type='Construction'");
print_r($stmt->fetchAll(PDO::FETCH_ASSOC));
