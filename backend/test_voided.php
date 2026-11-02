<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/core/Database.php';
$db = Database::getInstance()->getConnection();

$sql = "
    SELECT ri.id, ri.invoice_number, ri.amount, ri.due_date, ri.status, c.end_date,
           (SELECT COALESCE(SUM(amount), 0) FROM rent_payments WHERE invoice_id = ri.id) as paid_amount
    FROM rent_invoices ri
    JOIN contracts c ON ri.contract_id = c.id
    WHERE ri.status = 'Voided'
";
$stmt = $db->query($sql);
$voided = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo "Found " . count($voided) . " Voided invoices.\n";
foreach ($voided as $inv) {
    if ($inv['due_date'] <= $inv['end_date']) {
        echo "SHOULD UN-VOID: Invoice {$inv['invoice_number']} (Due: {$inv['due_date']}, End: {$inv['end_date']}), Paid: {$inv['paid_amount']}/{$inv['amount']}\n";
    }
}
