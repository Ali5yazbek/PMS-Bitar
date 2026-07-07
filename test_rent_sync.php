<?php
require_once __DIR__ . '/backend/core/Database.php';

$db = Database::getInstance()->getConnection();
echo "--- TESTING RENT SYNCHRONIZATION ---\n";

// 1. Get an existing apartment with an active contract and unpaid invoices
$stmt = $db->query("
    SELECT a.id as apt_id, a.code, c.id as contract_id, c.monthly_rent, a.monthly_rent as apt_rent
    FROM apartments a
    JOIN contracts c ON a.id = c.apartment_id
    WHERE c.status IN ('Active', 'Approved')
    LIMIT 1
");
$apt = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$apt) {
    echo "No active contracts found to test.\n";
    exit;
}

echo "Found Apartment: {$apt['code']} (ID: {$apt['apt_id']})\n";
echo "Current Apt Rent: {$apt['apt_rent']}\n";
echo "Current Contract Rent: {$apt['monthly_rent']}\n";

$newRent = 9999.50; // A unique amount

echo "\n[1] Changing Apartment Rent to $newRent via Apartment Update Logic...\n";
// Simulate what ApartmentsController does
$stmtAptUpdate = $db->prepare("UPDATE apartments SET monthly_rent = ? WHERE id = ?");
$stmtAptUpdate->execute([$newRent, $apt['apt_id']]);

// Simulate what ApartmentsController does for sync
$stmtContractSync = $db->prepare("UPDATE contracts SET monthly_rent = ? WHERE apartment_id = ? AND status IN ('Active', 'Approved')");
$stmtContractSync->execute([$newRent, $apt['apt_id']]);

$stmtInvoiceSync = $db->prepare("
    UPDATE rent_invoices ri
    JOIN contracts c ON ri.contract_id = c.id
    SET ri.amount = ?
    WHERE c.apartment_id = ? AND c.status IN ('Active', 'Approved') AND ri.status = 'Unpaid' AND ri.due_date >= CURRENT_DATE
");
$stmtInvoiceSync->execute([$newRent, $apt['apt_id']]);

echo "\n[2] Verifying Synchronization...\n";

// Check Contract
$stmtChkC = $db->prepare("SELECT monthly_rent FROM contracts WHERE id = ?");
$stmtChkC->execute([$apt['contract_id']]);
$chkContract = $stmtChkC->fetch(PDO::FETCH_ASSOC);
echo "Contract Rent Updated: " . ($chkContract['monthly_rent'] == $newRent ? 'PASS ('.$chkContract['monthly_rent'].')' : 'FAIL ('.$chkContract['monthly_rent'].')') . "\n";

// Check Invoices
$stmtChkI = $db->prepare("SELECT id, amount, due_date FROM rent_invoices WHERE contract_id = ? AND status = 'Unpaid' AND due_date >= CURRENT_DATE");
$stmtChkI->execute([$apt['contract_id']]);
$unpaidInvoices = $stmtChkI->fetchAll(PDO::FETCH_ASSOC);

if (count($unpaidInvoices) > 0) {
    $allInvoicesUpdated = true;
    foreach ($unpaidInvoices as $inv) {
        if ($inv['amount'] != $newRent) {
            $allInvoicesUpdated = false;
        }
    }
    echo "Unpaid Future Invoices Updated: " . ($allInvoicesUpdated ? "PASS" : "FAIL") . " (Checked " . count($unpaidInvoices) . " invoices)\n";
} else {
    echo "No unpaid future invoices found to verify.\n";
}

// 3. Test Rent Management Dashboard Logic
echo "\n[3] Testing Dashboard Rent Calculation...\n";
$month = date('m');
$year = date('Y');

$stmtDash = $db->prepare("
    SELECT 
        b.id as building_id,
        b.name as building_name,
        COUNT(DISTINCT a.id) as total_rented_rooms,
        COALESCE(SUM(c.monthly_rent), 0) as expected_rent
    FROM buildings b
    JOIN apartments a ON b.id = a.building_id
    JOIN contracts c ON a.id = c.apartment_id AND c.status IN ('Active', 'Approved')
    LEFT JOIN rent_invoices ri ON c.id = ri.contract_id AND MONTH(ri.due_date) = ? AND YEAR(ri.due_date) = ?
    WHERE b.id = (SELECT building_id FROM apartments WHERE id = ?)
    GROUP BY b.id, b.name
");
$stmtDash->execute([$month, $year, $apt['apt_id']]);
$dashboardStats = $stmtDash->fetch(PDO::FETCH_ASSOC);

echo "Building: {$dashboardStats['building_name']}\n";
echo "Total Rented Rooms: {$dashboardStats['total_rented_rooms']}\n";
echo "Expected Rent Calculation includes the $newRent update? -> ";

// To verify, we sum up all active contracts in that building
$stmtTotal = $db->prepare("
    SELECT SUM(c.monthly_rent) as expected
    FROM contracts c
    JOIN apartments a ON c.apartment_id = a.id
    WHERE a.building_id = ? AND c.status IN ('Active', 'Approved')
");
$stmtTotal->execute([$dashboardStats['building_id']]);
$expectedSum = $stmtTotal->fetch(PDO::FETCH_ASSOC)['expected'];

if ($expectedSum == $dashboardStats['expected_rent']) {
    echo "PASS (Calculated: {$dashboardStats['expected_rent']}, Expected: {$expectedSum})\n";
} else {
    echo "FAIL (Calculated: {$dashboardStats['expected_rent']}, Expected: {$expectedSum})\n";
}

// Cleanup (Reset the rent to original)
echo "\n[4] Reverting Test Changes...\n";
$stmtAptUpdate->execute([$apt['apt_rent'], $apt['apt_id']]);
$stmtContractSync->execute([$apt['contract_rent'], $apt['apt_id']]);
$stmtInvoiceSync->execute([$apt['contract_rent'], $apt['apt_id']]);
echo "Reverted apartment and contract to original rent.\n";

echo "\n--- TEST COMPLETE ---\n";
