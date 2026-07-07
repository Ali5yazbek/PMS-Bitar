<?php
require_once 'config.php';
require_once 'core/Database.php';

try {
    $db = Database::getInstance()->getConnection();
    echo "Connected to database.\n";

    // 1. Create rent_profiles table if it doesn't exist
    $sql = "
    CREATE TABLE IF NOT EXISTS rent_profiles (
        id INT AUTO_INCREMENT PRIMARY KEY,
        tenant_id INT NOT NULL,
        apartment_id INT NOT NULL,
        contract_id INT NULL,
        start_date DATE NOT NULL,
        monthly_amount DECIMAL(10,2) NOT NULL,
        next_billing_date DATE NULL,
        billing_frequency ENUM('Weekly', 'Monthly', 'Quarterly', 'Yearly') DEFAULT 'Monthly',
        status ENUM('Active', 'Paused', 'Ended') DEFAULT 'Active',
        auto_renewal BOOLEAN DEFAULT FALSE,
        notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
        FOREIGN KEY (apartment_id) REFERENCES apartments(id) ON DELETE CASCADE,
        FOREIGN KEY (contract_id) REFERENCES contracts(id) ON DELETE SET NULL
    );";
    // We execute this so we can do the dry-run queries cleanly, but we don't delete/insert data yet.
    $db->exec($sql);
    echo "rent_profiles table structure ensured.\n";

    // 2. Identify future unpaid invoices to delete
    // We only delete invoices that are purely Unpaid, have no partial payments, 
    // and whose period_start is in the future.
    $stmt = $db->query("
        SELECT ri.id, ri.invoice_number, ri.period_start 
        FROM rent_invoices ri
        WHERE ri.status = 'Unpaid' 
        AND ri.period_start > CURRENT_DATE()
        AND NOT EXISTS (SELECT 1 FROM rent_payments rp WHERE rp.invoice_id = ri.id)
    ");
    $futureInvoices = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo "\n--- INVOICES TO DELETE ---\n";
    echo "Found " . count($futureInvoices) . " future auto-generated unpaid invoices to safely remove.\n";
    foreach ($futureInvoices as $inv) {
        echo " - Will delete Invoice: {$inv['invoice_number']} (Starts: {$inv['period_start']})\n";
    }

    // 3. Draft Rent Profiles for existing active contracts
    $stmt = $db->query("
        SELECT id, tenant_id, apartment_id, start_date, monthly_rent
        FROM contracts
        WHERE status = 'Active'
    ");
    $activeContracts = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo "\n--- RENT PROFILES TO CREATE ---\n";
    echo "Found " . count($activeContracts) . " active contracts to migrate to Rent Profiles.\n";

    $profilesToInsert = [];

    foreach ($activeContracts as $contract) {
        // Find the latest invoice that is NOT going to be deleted
        // This includes Paid, Partial, Overdue, and Unpaid invoices that are currently active or past.
        $stmtLatest = $db->prepare("
            SELECT period_end 
            FROM rent_invoices 
            WHERE contract_id = ? 
            AND id NOT IN (
                SELECT id FROM rent_invoices WHERE status = 'Unpaid' AND period_start > CURRENT_DATE() AND NOT EXISTS (SELECT 1 FROM rent_payments rp WHERE rp.invoice_id = rent_invoices.id)
            )
            ORDER BY period_end DESC 
            LIMIT 1
        ");
        $stmtLatest->execute([$contract['id']]);
        $latestInvoice = $stmtLatest->fetch(PDO::FETCH_ASSOC);

        if ($latestInvoice && $latestInvoice['period_end']) {
            $nextBillingDate = date('Y-m-d', strtotime($latestInvoice['period_end'] . ' + 1 day'));
        } else {
            // No valid kept invoice, so billing should start at the contract start date
            $nextBillingDate = $contract['start_date'];
        }

        $profilesToInsert[] = [
            'tenant_id' => $contract['tenant_id'],
            'apartment_id' => $contract['apartment_id'],
            'contract_id' => $contract['id'],
            'start_date' => $contract['start_date'],
            'monthly_amount' => $contract['monthly_rent'],
            'next_billing_date' => $nextBillingDate
        ];

        echo " - Will create Profile for Tenant ID {$contract['tenant_id']} (Apt {$contract['apartment_id']}) | Next Billing: {$nextBillingDate} | Amount: {$contract['monthly_rent']}\n";
    }

    echo "\n------------------------------------------------\n";
    echo "MIGRATION PLAN PREPARED.\n";
    echo "No data has been modified yet.\n";
    echo "To execute this migration, please approve the plan and run the execution script.\n";

} catch (Exception $e) {
    echo "Error generating migration plan: " . $e->getMessage() . "\n";
}
