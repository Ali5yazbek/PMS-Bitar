<?php
require_once __DIR__ . '/backend/core/Database.php';
$db = Database::getInstance()->getConnection();
$stmt = $db->prepare("
    SELECT 
        b.id as building_id,
        b.name as building_name,
        COALESCE(SUM(CASE WHEN ri.due_date BETWEEN ? AND ? THEN ri.amount ELSE 0 END), 0) as expected_rent
    FROM buildings b
    LEFT JOIN apartments a ON b.id = a.building_id
    LEFT JOIN contracts c ON a.id = c.apartment_id
    LEFT JOIN rent_invoices ri ON c.id = ri.contract_id
    WHERE b.name = 'galaxy'
    GROUP BY b.id, b.name
");
$stmt->execute(['2026-01-01', '2026-06-30']);
print_r($stmt->fetchAll(PDO::FETCH_ASSOC));
