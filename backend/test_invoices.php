<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/core/Database.php';

$db = Database::getInstance()->getConnection();

$apartmentId = 1;

$stmt = $db->prepare("SELECT id FROM apartments WHERE code = 'A1' LIMIT 1");
$stmt->execute();
$apt = $stmt->fetch(PDO::FETCH_ASSOC);
if ($apt) {
    $apartmentId = $apt['id'];
}

echo "Apartment ID: $apartmentId\n";

$stmt = $db->prepare("
    (
        SELECT 
            ri.id as invoice_id,
            ri.invoice_number,
            'rent' as invoice_type
        FROM rent_invoices ri
        JOIN contracts c ON ri.contract_id = c.id
        JOIN apartments a ON c.apartment_id = a.id
        WHERE a.id = ?
        AND ri.status != 'Paid'
    )
    UNION ALL
    (
        SELECT 
            ei.id as invoice_id,
            CONCAT('Elec-', ei.id) as invoice_number,
            'electricity' as invoice_type
        FROM electricity_invoices ei
        JOIN apartments a ON ei.apartment_id = a.id
        WHERE a.id = ?
        AND ei.status != 'Paid'
    )
");
$stmt->execute([$apartmentId, $apartmentId]);
$invoices = $stmt->fetchAll(PDO::FETCH_ASSOC);

print_r($invoices);
