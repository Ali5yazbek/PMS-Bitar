<?php
require 'config.php';
require 'core/Database.php';

$db = Database::getInstance()->getConnection();
$stmt = $db->prepare("SELECT c.*, a.code as apartment_code, b.name as building_name 
            FROM contracts c 
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE c.tenant_id = ? AND c.status IN ('Active', 'Pending_Signature', 'Signed', 'Approved', 'Renewal_Pending')
            ORDER BY c.id DESC LIMIT 1");
$stmt->execute([5]);
print_r($stmt->fetch(PDO::FETCH_ASSOC));
