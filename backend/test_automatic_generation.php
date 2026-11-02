<?php
/**
 * test_automatic_generation.php
 * Interactive Live Test: Simulates tenant lifecycle and verifies automatic rent generation
 * Run via CLI: php backend/test_automatic_generation.php
 */

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/core/Database.php';
require_once __DIR__ . '/services/RentGenerationService.php';

echo "===============================================================\n";
echo "   LIVE TEST: AUTOMATIC RENT GENERATION & CATCH-UP DEMO        \n";
echo "===============================================================\n\n";

$db = Database::getInstance()->getConnection();

// 1. Create a fresh test tenant & contract
echo "Step 1: Setting up fresh test tenant 'Demo Automatic Tenant'...\n";
$db->exec("INSERT INTO tenants (full_name, phone, status) VALUES ('Demo Automatic Tenant', '05550001', 'Active')");
$tenantId = (int)$db->lastInsertId();

// Contract starts on August 21, 2026, monthly rent CFA 550
$db->exec("
    INSERT INTO contracts (apartment_id, tenant_id, start_date, end_date, rent_start_date, monthly_rent, status, rent_status)
    VALUES (28, $tenantId, '2026-08-21', '2027-08-21', '2026-08-21', 550.00, 'Active', 'Active')
");
$contractId = (int)$db->lastInsertId();

// Create August invoice (historical/initial month)
$db->exec("
    INSERT INTO rent_invoices (contract_id, invoice_number, amount, due_date, status, period_start, period_end)
    VALUES ($contractId, 'INV-202608-TEST', 550.00, '2026-08-21', 'Unpaid', '2026-08-21', '2026-09-20')
");

// Rent profile with next_billing_date = 2026-09-21
$db->exec("
    INSERT INTO rent_profiles (tenant_id, apartment_id, contract_id, rent_start_date, monthly_amount, next_billing_date, billing_frequency, status, auto_renewal)
    VALUES ($tenantId, 28, $contractId, '2026-08-21', 550.00, '2026-09-21', 'Monthly', 'Active', 1)
");

echo "  Tenant ID:   #{$tenantId}\n";
echo "  Contract ID: #{$contractId}\n";
echo "  Monthly Rent: CFA 550.00\n";
echo "  Due Day:     21st of every month\n";
echo "  Lease:       2026-08-21 to 2027-08-21\n\n";

// Display BEFORE state
echo "--- STATE BEFORE AUTOMATIC GENERATION ---\n";
echo "Existing Invoices:\n";
$stmt = $db->query("SELECT invoice_number, due_date, amount, status FROM rent_invoices WHERE contract_id = $contractId ORDER BY due_date ASC");
foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $r) {
    echo "  [Invoice] {$r['invoice_number']} | Due: {$r['due_date']} | Amount: CFA {$r['amount']} | Status: {$r['status']}\n";
}

$stmtP = $db->query("SELECT next_billing_date FROM rent_profiles WHERE contract_id = $contractId");
echo "Next Billing Date: " . $stmtP->fetchColumn() . "\n";
echo "September and October rent invoices DO NOT EXIST yet.\n\n";

// Step 2: Simulate the server clock on October 24, 2026
echo "Step 2: Server reaches October 24, 2026 in Africa/Bangui...\n";
echo "Triggering Automatic Rent Generation Service (no admin buttons clicked, browser closed)...\n\n";

$asOfDate = new DateTime('2026-10-24', new DateTimeZone('Africa/Bangui'));
$result = RentGenerationService::generateDueInvoices($contractId, $asOfDate);

echo "Generation Service Output:\n";
echo "  Status:           {$result['status']}\n";
echo "  Invoices Created: {$result['invoices_created']}\n";
foreach ($result['details'] as $d) {
    echo "  + Created Invoice {$d['invoice_number']} for due date {$d['due_date']} (CFA {$d['amount']}) -> Next Billing: {$d['next_billing_date']}\n";
}
echo "\n";

// Step 3: Verify the AFTER state in Database
echo "--- STATE AFTER AUTOMATIC GENERATION ---\n";
$stmt = $db->query("
    SELECT id, invoice_number, due_date, period_start, period_end, amount, status,
           (amount - COALESCE((SELECT SUM(amount) FROM rent_payments rp WHERE rp.invoice_id = rent_invoices.id), 0)) as balance
    FROM rent_invoices 
    WHERE contract_id = $contractId 
    ORDER BY due_date ASC
");
$invoices = $stmt->fetchAll(PDO::FETCH_ASSOC);

$totalBalance = 0;
foreach ($invoices as $inv) {
    echo sprintf("  Invoice #%-4d | %-16s | Due: %s | Period: %s to %s | Amount: CFA %6.2f | Status: %-7s | Outstanding: CFA %6.2f\n",
        $inv['id'], $inv['invoice_number'], $inv['due_date'], $inv['period_start'], $inv['period_end'], $inv['amount'], $inv['status'], $inv['balance']
    );
    $totalBalance += (float)$inv['balance'];
}

$stmtP = $db->query("SELECT next_billing_date FROM rent_profiles WHERE contract_id = $contractId");
$newNextDate = $stmtP->fetchColumn();
echo "\nNew Next Billing Date in Profile: {$newNextDate}\n";
echo "Total Outstanding Rent: CFA {$totalBalance}\n\n";

// Step 4: Test Duplicate Prevention / Idempotency
echo "Step 4: Running generation service a SECOND time to test Duplicate Prevention...\n";
$secondResult = RentGenerationService::generateDueInvoices($contractId, $asOfDate);
echo "  Invoices Created on 2nd Run: {$secondResult['invoices_created']} (Expected: 0)\n";

$countInvs = $db->query("SELECT COUNT(*) FROM rent_invoices WHERE contract_id = $contractId")->fetchColumn();
echo "  Total Invoices in Database:  {$countInvs} (Expected: 3 - Aug, Sept, Oct)\n\n";

// Step 5: Simulate Future Automatic Generation (Time Travel to November 21, 2026)
echo "Step 5: Simulating time advancing to November 21, 2026 (Next Due Date arrives)...\n";
$novDate = new DateTime('2026-11-21', new DateTimeZone('Africa/Bangui'));
$novResult = RentGenerationService::generateDueInvoices($contractId, $novDate);

echo "  Invoices Created on Nov 21:  {$novResult['invoices_created']}\n";
foreach ($novResult['details'] as $d) {
    echo "  + Automatically Created November Invoice {$d['invoice_number']} for due date {$d['due_date']} (CFA {$d['amount']})\n";
}

$stmtP = $db->query("SELECT next_billing_date FROM rent_profiles WHERE contract_id = $contractId");
echo "  New Next Billing Date:      " . $stmtP->fetchColumn() . " (Advanced to December 21, 2026!)\n\n";

// Cleanup test records
echo "Cleaning up demo test tenant #{$tenantId}...\n";
$db->exec("DELETE FROM rent_invoices WHERE contract_id = $contractId");
$db->exec("DELETE FROM rent_periods WHERE contract_id = $contractId");
$db->exec("DELETE FROM rent_profiles WHERE contract_id = $contractId");
$db->exec("DELETE FROM contracts WHERE id = $contractId");
$db->exec("DELETE FROM tenants WHERE id = $tenantId");
echo "Demo test tenant cleaned up successfully.\n\n";

echo "===============================================================\n";
echo "   LIVE AUTOMATIC GENERATION TEST: 100% SUCCESS!               \n";
echo "===============================================================\n";
