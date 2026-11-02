<?php
// Set up $_ENV before Database.php is required so it connects successfully
$_ENV['DB_HOST'] = '127.0.0.1';
$_ENV['DB_USERNAME'] = 'root';
$_ENV['DB_PASSWORD'] = '';
$_ENV['DB_DATABASE'] = 'bitar'; // WAIT, DB_NAME was bitar? Let me check

// Actually, I can just include config.php which parses .env
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/core/Database.php';

$db = Database::getInstance()->getConnection();

$stmt = $db->prepare("SELECT id FROM apartments WHERE code = 'A1' LIMIT 1");
$stmt->execute();
$apt = $stmt->fetch(PDO::FETCH_ASSOC);
$apartmentId = $apt['id'] ?? 1;

$stmt = $db->prepare("
    SELECT 
        ei.id as invoice_id,
        CONCAT('Elec-', ei.id) as invoice_number,
        'electricity' as invoice_type,
        ei.status
    FROM electricity_invoices ei
    JOIN apartments a ON ei.apartment_id = a.id
    WHERE a.id = ?
");
$stmt->execute([$apartmentId]);
$invoices = $stmt->fetchAll(PDO::FETCH_ASSOC);

print_r($invoices);
