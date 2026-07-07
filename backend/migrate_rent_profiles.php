<?php
require_once 'config.php';
require_once 'core/Database.php';

try {
    $db = Database::getInstance()->getConnection();
    echo "Connected to database.\n";
    
    $db->beginTransaction();

    // 1. Create rent_profiles table
    $db->exec("DROP TABLE IF EXISTS rent_profile_history");
    $db->exec("DROP TABLE IF EXISTS rent_profiles");

    $sql = "
    CREATE TABLE IF NOT EXISTS rent_profiles (
        id INT AUTO_INCREMENT PRIMARY KEY,
        tenant_id INT NOT NULL,
        apartment_id INT NOT NULL,
        contract_id INT NULL,
        rent_start_date DATE NOT NULL,
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
    $db->exec($sql);
    echo "rent_profiles table created.\n";

    // 2. Create rent_profile_history table
    $sqlHistory = "
    CREATE TABLE IF NOT EXISTS rent_profile_history (
        id INT AUTO_INCREMENT PRIMARY KEY,
        rent_profile_id INT NOT NULL,
        action VARCHAR(100) NOT NULL,
        previous_value VARCHAR(255),
        new_value VARCHAR(255),
        notes TEXT,
        user_id INT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (rent_profile_id) REFERENCES rent_profiles(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
    );";
    $db->exec($sqlHistory);
    echo "rent_profile_history table created.\n";

    // 3. Identify and DELETE future unpaid auto-generated invoices (just to be completely safe based on logic)
    $stmt = $db->query("
        SELECT ri.id
        FROM rent_invoices ri
        WHERE ri.status = 'Unpaid' 
        AND ri.period_start > CURRENT_DATE()
        AND NOT EXISTS (SELECT 1 FROM rent_payments rp WHERE rp.invoice_id = ri.id)
    ");
    $futureInvoices = $stmt->fetchAll(PDO::FETCH_COLUMN);

    if (count($futureInvoices) > 0) {
        $inParams = implode(',', array_fill(0, count($futureInvoices), '?'));
        $deleteStmt = $db->prepare("DELETE FROM rent_invoices WHERE id IN ($inParams)");
        $deleteStmt->execute($futureInvoices);
        echo "Deleted " . count($futureInvoices) . " future unpaid invoices.\n";
    } else {
        echo "0 future unpaid invoices to delete.\n";
    }

    // 4. Migrate Active Contracts to Rent Profiles
    $stmt = $db->query("
        SELECT id, tenant_id, apartment_id, start_date, monthly_rent
        FROM contracts
        WHERE status = 'Active'
    ");
    $activeContracts = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo "Found " . count($activeContracts) . " active contracts to migrate.\n";

    $insertProfileStmt = $db->prepare("
        INSERT INTO rent_profiles (tenant_id, apartment_id, contract_id, rent_start_date, monthly_amount, next_billing_date, auto_renewal, notes)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ");
    
    $insertHistoryStmt = $db->prepare("
        INSERT INTO rent_profile_history (rent_profile_id, action, notes)
        VALUES (?, 'Migration', 'Profile created from active contract during migration')
    ");

    $migratedCount = 0;

    foreach ($activeContracts as $contract) {
        $stmtLatest = $db->prepare("
            SELECT period_end 
            FROM rent_invoices 
            WHERE contract_id = ? 
            ORDER BY period_end DESC 
            LIMIT 1
        ");
        $stmtLatest->execute([$contract['id']]);
        $latestInvoice = $stmtLatest->fetch(PDO::FETCH_ASSOC);

        if ($latestInvoice && $latestInvoice['period_end']) {
            $nextBillingDate = date('Y-m-d', strtotime($latestInvoice['period_end'] . ' + 1 day'));
        } else {
            $nextBillingDate = $contract['start_date'];
        }

        // Default Auto Renewal to FALSE (0) based on user instructions
        $insertProfileStmt->execute([
            $contract['tenant_id'],
            $contract['apartment_id'],
            $contract['id'],
            $contract['start_date'],
            $contract['monthly_rent'],
            $nextBillingDate,
            0, // auto_renewal = FALSE
            'Migrated from contract #' . $contract['id']
        ]);
        
        $profileId = $db->lastInsertId();
        
        // Log history
        $insertHistoryStmt->execute([$profileId]);
        
        $migratedCount++;
        echo "Migrated Profile #$profileId for Tenant {$contract['tenant_id']}.\n";
    }

    $db->commit();
    echo "\n------------------------------------------------\n";
    echo "SUCCESS: Migration completed and committed to the database.\n";
    echo "Total Profiles Created: $migratedCount\n";

} catch (Exception $e) {
    echo "Error during migration: " . $e->getMessage() . "\n";
}
