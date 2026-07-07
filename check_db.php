<?php
require_once __DIR__ . '/backend/core/Database.php';
$db = Database::getInstance()->getConnection();
$stmt = $db->query("SELECT c.id as contract_id, c.status as c_status, t.id as tenant_id, t.user_id FROM contracts c LEFT JOIN tenants t ON c.tenant_id = t.id WHERE c.apartment_id = 1");
print_r($stmt->fetchAll(PDO::FETCH_ASSOC));
