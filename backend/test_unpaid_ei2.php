<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/core/Database.php';

try {
    $db = Database::getInstance()->getConnection();
    
    $apartmentId = 1;

    $stmt = $db->prepare("
        (
            SELECT 
                ri.id as invoice_id,
                ri.invoice_number,
                ri.amount,
                ri.due_date,
                ri.period_start,
                ri.period_end,
                ri.status as invoice_status,
                COALESCE((SELECT SUM(rp.amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0) as amount_paid,
                (ri.amount - COALESCE((SELECT SUM(rp.amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0)) as remaining,
                a.code as apartment_code,
                b.name as building_name,
                t.full_name as tenant_name,
                'rent' as invoice_type
            FROM rent_invoices ri
            JOIN contracts c ON ri.contract_id = c.id
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            JOIN tenants t ON c.tenant_id = t.id
            WHERE a.id = ?
            AND ri.status != 'Paid'
        )
        UNION ALL
        (
            SELECT 
                ei.id as invoice_id,
                CONCAT('Elec-', ei.id) as invoice_number,
                ei.amount,
                ei.due_date,
                ei.due_date as period_start,
                ei.due_date as period_end,
                ei.status as invoice_status,
                COALESCE(ei.amount_paid, 0) as amount_paid,
                (ei.amount - COALESCE(ei.amount_paid, 0)) as remaining,
                a.code as apartment_code,
                b.name as building_name,
                COALESCE(t.full_name, 'Unknown Tenant') as tenant_name,
                'electricity' as invoice_type
            FROM electricity_invoices ei
            JOIN apartments a ON ei.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            LEFT JOIN contracts c ON a.id = c.apartment_id AND c.status = 'Active'
            LEFT JOIN tenants t ON c.tenant_id = t.id
            WHERE a.id = ?
            AND ei.status != 'Paid'
        )
        ORDER BY due_date ASC
    ");
    $stmt->execute([$apartmentId, $apartmentId]);
    $invoices = $stmt->fetchAll(\PDO::FETCH_ASSOC);

    echo json_encode(['status' => 'success', 'data' => $invoices]);
} catch (\Exception $e) {
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
