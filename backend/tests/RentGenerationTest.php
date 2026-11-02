<?php
/**
 * RentGenerationTest.php
 * Automated test suite for PMS Automatic Monthly Rent Generation
 * Run via CLI: php backend/tests/RentGenerationTest.php
 */

require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../core/Database.php';
require_once __DIR__ . '/../services/RentGenerationService.php';

echo "====================================================\n";
echo "   PMS AUTOMATIC RENT GENERATION - TEST SUITE       \n";
echo "====================================================\n\n";

$db = Database::getInstance()->getConnection();
$passed = 0;
$failed = 0;

function assertTest(string $description, bool $condition, string $detail = '') {
    global $passed, $failed;
    if ($condition) {
        echo "  [PASS] {$description}\n";
        $passed++;
    } else {
        echo "  [FAIL] {$description} " . ($detail ? "({$detail})" : "") . "\n";
        $failed++;
    }
}

// =========================================================================
// TEST SUITE 1: Calendar Arithmetic, Month-End Dates & Leap Years
// =========================================================================
echo "Test Suite 1: Calendar Arithmetic, Month-End Dates & Leap Years\n";

// Jan 31 -> Feb 28 in non-leap year (e.g. 2027)
$nextFeb = RentGenerationService::calculateNextBillingDate('2027-01-31', 'Monthly', 31);
assertTest("Jan 31 advances to Feb 28 in non-leap year (2027)", $nextFeb === '2027-02-28', "Got {$nextFeb}");

// Feb 28 -> Mar 31 (retains anchor day 31)
$nextMar = RentGenerationService::calculateNextBillingDate('2027-02-28', 'Monthly', 31);
assertTest("Feb 28 preserves anchor day 31 and advances to Mar 31", $nextMar === '2027-03-31', "Got {$nextMar}");

// Mar 31 -> Apr 30
$nextApr = RentGenerationService::calculateNextBillingDate('2027-03-31', 'Monthly', 31);
assertTest("Mar 31 advances to Apr 30 (clamped)", $nextApr === '2027-04-30', "Got {$nextApr}");

// Apr 30 -> May 31
$nextMay = RentGenerationService::calculateNextBillingDate('2027-04-30', 'Monthly', 31);
assertTest("Apr 30 advances to May 31 (retains anchor day 31)", $nextMay === '2027-05-31', "Got {$nextMay}");

// Leap Year: Jan 29, 2028 -> Feb 29, 2028
$nextLeapFeb = RentGenerationService::calculateNextBillingDate('2028-01-29', 'Monthly', 29);
assertTest("Jan 29 advances to Feb 29 in leap year (2028)", $nextLeapFeb === '2028-02-29', "Got {$nextLeapFeb}");

// Non-Leap Year: Jan 29, 2027 -> Feb 28, 2027
$nextNonLeapFeb = RentGenerationService::calculateNextBillingDate('2027-01-29', 'Monthly', 29);
assertTest("Jan 29 advances to Feb 28 in non-leap year (2027)", $nextNonLeapFeb === '2027-02-28', "Got {$nextNonLeapFeb}");

// Billing Frequencies: Weekly, Quarterly, Yearly
$nextWeek = RentGenerationService::calculateNextBillingDate('2026-10-21', 'Weekly');
assertTest("Weekly frequency advances 7 days to 2026-10-28", $nextWeek === '2026-10-28', "Got {$nextWeek}");

$nextQuarter = RentGenerationService::calculateNextBillingDate('2026-10-21', 'Quarterly', 21);
assertTest("Quarterly frequency advances 3 months to 2027-01-21", $nextQuarter === '2027-01-21', "Got {$nextQuarter}");

$nextYear = RentGenerationService::calculateNextBillingDate('2026-10-21', 'Yearly', 21);
assertTest("Yearly frequency advances 1 year to 2027-10-21", $nextYear === '2027-10-21', "Got {$nextYear}");


// =========================================================================
// TEST SUITE 2: Africa/Bangui Timezone
// =========================================================================
echo "\nTest Suite 2: Africa/Bangui Timezone\n";
assertTest("Service timezone is configured to Africa/Bangui", RentGenerationService::TIMEZONE === 'Africa/Bangui');

$tz = new DateTimeZone(RentGenerationService::TIMEZONE);
$dtBangui = RentGenerationService::getNowBangui();
assertTest("Service getNowBangui returns timezone Africa/Bangui", $dtBangui->getTimezone()->getName() === 'Africa/Bangui');


// =========================================================================
// TEST SUITE 3: Payment Status & Financial Totals Reconciliation
// =========================================================================
echo "\nTest Suite 3: Payment Status & Financial Totals Reconciliation\n";

// Create a temporary invoice to test status reconciliation
$db->beginTransaction();
try {
    // Insert test invoice
    $stmtT = $db->prepare("
        INSERT INTO rent_invoices (contract_id, invoice_number, amount, due_date, status, created_at)
        VALUES (37, 'TEST-STATUS-1', 550.00, '2026-09-01', 'Paid', NOW())
    ");
    $stmtT->execute();
    $testInvId = $db->lastInsertId();

    // Reconcile
    RentGenerationService::reconcileInvoiceStatuses(37);

    // Verify it was corrected from 'Paid' to 'Overdue' because paid_amount is 0
    $stmtChk = $db->prepare("SELECT status FROM rent_invoices WHERE id = ?");
    $stmtChk->execute([$testInvId]);
    $recStatus = $stmtChk->fetchColumn();
    assertTest("Reconciler changes invalid 'Paid' (with 0 payments) to 'Overdue'", $recStatus === 'Overdue', "Got {$recStatus}");

    // Add a partial payment of 200
    $stmtPay = $db->prepare("INSERT INTO rent_payments (invoice_id, amount, date, user_id) VALUES (?, ?, ?, 1)");
    $stmtPay->execute([$testInvId, 200.00, '2026-09-05']);
    $testPayId1 = $db->lastInsertId();

    RentGenerationService::reconcileInvoiceStatuses(37);
    $stmtChk->execute([$testInvId]);
    assertTest("Reconciler marks invoice 'Partial' when 0 < paid < amount", $stmtChk->fetchColumn() === 'Partial');

    // Add remaining payment of 350
    $stmtPay->execute([$testInvId, 350.00, '2026-09-06']);
    $testPayId2 = $db->lastInsertId();

    RentGenerationService::reconcileInvoiceStatuses(37);
    $stmtChk->execute([$testInvId]);
    assertTest("Reconciler marks invoice 'Paid' when paid >= amount", $stmtChk->fetchColumn() === 'Paid');

    $db->rollBack();
    assertTest("Status reconciliation test data cleaned up safely", true);
} catch (Exception $e) {
    if ($db->inTransaction()) {
        $db->rollBack();
    }
    assertTest("Status reconciliation test exception: " . $e->getMessage(), false);
}


// =========================================================================
// TEST SUITE 4: Production Karim Scenario (Check 1, Check 2, Check 3, Check 4)
// =========================================================================
echo "\nTest Suite 4: Production Karim Scenario (Checks 1 to 4)\n";

// Karim: tenant_id = 34, contract_id = 37, monthly_rent = 550.00, billing_day = 21
// Reference date: October 24, 2026
$asOfDate = new DateTime('2026-10-24', new DateTimeZone('Africa/Bangui'));

// Run generation as of October 24, 2026
$genResult = RentGenerationService::generateDueInvoices(37, $asOfDate);

// Check 1 — Database: Separate rent invoice for September and October, each for CFA 550
$stmtSept = $db->prepare("SELECT * FROM rent_invoices WHERE contract_id = 37 AND due_date = '2026-09-21'");
$stmtSept->execute();
$septInvoice = $stmtSept->fetch(PDO::FETCH_ASSOC);

$stmtOct = $db->prepare("SELECT * FROM rent_invoices WHERE contract_id = 37 AND due_date = '2026-10-21'");
$stmtOct->execute();
$octInvoice = $stmtOct->fetch(PDO::FETCH_ASSOC);

assertTest("Check 1A: Separate rent invoice exists for September 21, 2026", !empty($septInvoice));
assertTest("Check 1B: September invoice amount is CFA 550.00", !empty($septInvoice) && (float)$septInvoice['amount'] == 550.00, "Got " . ($septInvoice['amount'] ?? 'null'));
assertTest("Check 1C: Separate rent invoice exists for October 21, 2026", !empty($octInvoice));
assertTest("Check 1D: October invoice amount is CFA 550.00", !empty($octInvoice) && (float)$octInvoice['amount'] == 550.00, "Got " . ($octInvoice['amount'] ?? 'null'));

// Check 2 — Schedule: October's invoice is generated even when browser is closed and previous month remains unpaid
assertTest("Check 2A: September invoice status is not Paid (unpaid/overdue)", !empty($septInvoice) && in_array($septInvoice['status'], ['Unpaid', 'Overdue']));
assertTest("Check 2B: October invoice generated independently while September is unpaid", !empty($octInvoice) && $octInvoice['id'] !== $septInvoice['id']);

// Check 3 — Balance: September and October both unpaid -> total outstanding rent is CFA 1,100
$stmtBal = $db->prepare("
    SELECT SUM(amount - COALESCE((SELECT SUM(amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0)) as outstanding
    FROM rent_invoices ri
    WHERE contract_id = 37 AND due_date IN ('2026-09-21', '2026-10-21')
");
$stmtBal->execute();
$totalOutstandingSeptOct = (float)$stmtBal->fetchColumn();
assertTest("Check 3: Total outstanding for Sept + Oct is exactly CFA 1,100", $totalOutstandingSeptOct == 1100.00, "Got CFA {$totalOutstandingSeptOct}");

// Check Next Billing Date: Should be advanced to November 21, 2026
$stmtProfile = $db->prepare("SELECT next_billing_date FROM rent_profiles WHERE contract_id = 37");
$stmtProfile->execute();
$nextBilling = $stmtProfile->fetchColumn();
assertTest("Check Next Billing Date: Advanced to 2026-11-21", $nextBilling === '2026-11-21', "Got {$nextBilling}");

// Check 4 — Duplicate Prevention: Run generation process again. Must not create second October invoice
$secondRun = RentGenerationService::generateDueInvoices(37, $asOfDate);
assertTest("Check 4A: Second generation run creates 0 duplicate invoices", $secondRun['invoices_created'] === 0, "Created: {$secondRun['invoices_created']}");

$stmtCountOct = $db->prepare("SELECT COUNT(*) FROM rent_invoices WHERE contract_id = 37 AND due_date = '2026-10-21'");
$stmtCountOct->execute();
$countOct = (int)$stmtCountOct->fetchColumn();
assertTest("Check 4B: Exactly ONE October invoice exists for Karim", $countOct === 1, "Count: {$countOct}");

// Check DB-level unique constraint enforcement
$dbConstraintTriggered = false;
try {
    $db->prepare("
        INSERT INTO rent_invoices (contract_id, invoice_number, amount, due_date, status)
        VALUES (37, 'INV-DUP-TEST', 550.00, '2026-10-21', 'Unpaid')
    ")->execute();
} catch (PDOException $e) {
    if (strpos($e->getMessage(), 'Duplicate') !== false || $e->getCode() == 23000) {
        $dbConstraintTriggered = true;
    }
}
assertTest("Check 4C: DB-level unique constraint rejects duplicate (contract_id, due_date)", $dbConstraintTriggered);


// =========================================================================
// TEST SUITE 5: Offline Catch-up Over Multiple Months
// =========================================================================
echo "\nTest Suite 5: Offline Catch-up Over Multiple Months\n";

$tempTenantId = null;
$tempContractId = null;
try {
    // Create a temporary tenant & contract starting 3 months prior
    $db->exec("INSERT INTO tenants (full_name, phone, status) VALUES ('Test Catchup Tenant', '99990001', 'Active')");
    $tempTenantId = (int)$db->lastInsertId();

    $db->exec("
        INSERT INTO contracts (apartment_id, tenant_id, start_date, end_date, rent_start_date, monthly_rent, status, rent_status)
        VALUES (28, $tempTenantId, '2026-06-10', '2027-06-10', '2026-06-10', 400.00, 'Active', 'Active')
    ");
    $tempContractId = (int)$db->lastInsertId();

    $db->exec("
        INSERT INTO rent_profiles (tenant_id, apartment_id, contract_id, rent_start_date, monthly_amount, next_billing_date, billing_frequency, status, auto_renewal)
        VALUES ($tempTenantId, 28, $tempContractId, '2026-06-10', 400.00, '2026-06-10', 'Monthly', 'Active', 1)
    ");

    // Catch up as of 2026-09-15 (covers June 10, July 10, August 10, Sept 10 = 4 months)
    $catchupResult = RentGenerationService::generateDueInvoices($tempContractId, new DateTime('2026-09-15', new DateTimeZone('Africa/Bangui')));
    assertTest("Catch-up generated 4 missing monthly invoices", $catchupResult['invoices_created'] === 4, "Created: {$catchupResult['invoices_created']}");

    // Verify invoices
    $stmtCheck = $db->prepare("SELECT due_date FROM rent_invoices WHERE contract_id = ? ORDER BY due_date ASC");
    $stmtCheck->execute([$tempContractId]);
    $dates = $stmtCheck->fetchAll(PDO::FETCH_COLUMN);

    $expectedDates = ['2026-06-10', '2026-07-10', '2026-08-10', '2026-09-10'];
    assertTest("Catch-up generated exact sequential due dates", $dates === $expectedDates, json_encode($dates));

    // Next billing date should be 2026-10-10
    $stmtP = $db->prepare("SELECT next_billing_date FROM rent_profiles WHERE contract_id = ?");
    $stmtP->execute([$tempContractId]);
    assertTest("Next billing date advanced to 2026-10-10", $stmtP->fetchColumn() === '2026-10-10');

} catch (Exception $e) {
    assertTest("Catch-up test exception: " . $e->getMessage(), false);
} finally {
    if ($tempContractId) {
        $db->exec("DELETE FROM rent_invoices WHERE contract_id = $tempContractId");
        $db->exec("DELETE FROM rent_periods WHERE contract_id = $tempContractId");
        $db->exec("DELETE FROM rent_profiles WHERE contract_id = $tempContractId");
        $db->exec("DELETE FROM contracts WHERE id = $tempContractId");
    }
    if ($tempTenantId) {
        $db->exec("DELETE FROM tenants WHERE id = $tempTenantId");
    }
}


// =========================================================================
// TEST SUITE 6: Expired Contracts, Terminated Leases & Inactive Tenants
// =========================================================================
echo "\nTest Suite 6: Expired Contracts, Terminated Leases & Inactive Tenants\n";

$cleanTenants = [];
$cleanContracts = [];

try {
    // 1. Terminated contract
    $db->exec("INSERT INTO tenants (full_name, phone, status) VALUES ('Terminated Tenant', '99990002', 'Active')");
    $termTenant = (int)$db->lastInsertId();
    $cleanTenants[] = $termTenant;
    $db->exec("
        INSERT INTO contracts (apartment_id, tenant_id, start_date, end_date, rent_start_date, monthly_rent, status, rent_status)
        VALUES (28, $termTenant, '2026-01-01', '2026-12-31', '2026-01-01', 300.00, 'Terminated', 'Closed')
    ");
    $termContract = (int)$db->lastInsertId();
    $cleanContracts[] = $termContract;
    $db->exec("
        INSERT INTO rent_profiles (tenant_id, apartment_id, contract_id, rent_start_date, monthly_amount, next_billing_date, status, auto_renewal)
        VALUES ($termTenant, 28, $termContract, '2026-01-01', 300.00, '2026-02-01', 'Closed', 0)
    ");

    $termResult = RentGenerationService::generateDueInvoices($termContract, $asOfDate);
    assertTest("Terminated contract generates 0 invoices", $termResult['invoices_created'] === 0);

    // 2. Inactive tenant
    $db->exec("INSERT INTO tenants (full_name, phone, status) VALUES ('Inactive Tenant', '99990003', 'Inactive')");
    $inactTenant = (int)$db->lastInsertId();
    $cleanTenants[] = $inactTenant;
    $db->exec("
        INSERT INTO contracts (apartment_id, tenant_id, start_date, end_date, rent_start_date, monthly_rent, status, rent_status)
        VALUES (28, $inactTenant, '2026-01-01', '2026-12-31', '2026-01-01', 300.00, 'Active', 'Active')
    ");
    $inactContract = (int)$db->lastInsertId();
    $cleanContracts[] = $inactContract;
    $db->exec("
        INSERT INTO rent_profiles (tenant_id, apartment_id, contract_id, rent_start_date, monthly_amount, next_billing_date, status, auto_renewal)
        VALUES ($inactTenant, 28, $inactContract, '2026-01-01', 300.00, '2026-02-01', 'Active', 1)
    ");

    $inactResult = RentGenerationService::generateDueInvoices($inactContract, $asOfDate);
    assertTest("Inactive tenant generates 0 invoices", $inactResult['invoices_created'] === 0);

    // 3. Expired contract (end_date in past)
    $db->exec("INSERT INTO tenants (full_name, phone, status) VALUES ('Expired Tenant', '99990004', 'Active')");
    $expTenant = (int)$db->lastInsertId();
    $cleanTenants[] = $expTenant;
    $db->exec("
        INSERT INTO contracts (apartment_id, tenant_id, start_date, end_date, rent_start_date, monthly_rent, status, rent_status)
        VALUES (28, $expTenant, '2025-01-01', '2026-01-01', '2025-01-01', 300.00, 'Active', 'Active')
    ");
    $expContract = (int)$db->lastInsertId();
    $cleanContracts[] = $expContract;
    $db->exec("
        INSERT INTO rent_profiles (tenant_id, apartment_id, contract_id, rent_start_date, monthly_amount, next_billing_date, status, auto_renewal)
        VALUES ($expTenant, 28, $expContract, '2025-01-01', 300.00, '2026-02-01', 'Active', 1)
    ");

    $expResult = RentGenerationService::generateDueInvoices($expContract, $asOfDate);
    assertTest("Expired lease (end_date < today) generates 0 invoices", $expResult['invoices_created'] === 0);

} catch (Exception $e) {
    assertTest("Eligibility test exception: " . $e->getMessage(), false);
} finally {
    foreach ($cleanContracts as $cid) {
        $db->exec("DELETE FROM rent_invoices WHERE contract_id = $cid");
        $db->exec("DELETE FROM rent_periods WHERE contract_id = $cid");
        $db->exec("DELETE FROM rent_profiles WHERE contract_id = $cid");
        $db->exec("DELETE FROM contracts WHERE id = $cid");
    }
    foreach ($cleanTenants as $tid) {
        $db->exec("DELETE FROM tenants WHERE id = $tid");
    }
}


// =========================================================================
// TEST SUITE SUMMARY
// =========================================================================
echo "\n====================================================\n";
echo "TEST RESULTS: {$passed} PASSED, {$failed} FAILED\n";
echo "====================================================\n";

if ($failed > 0) {
    exit(1);
}
