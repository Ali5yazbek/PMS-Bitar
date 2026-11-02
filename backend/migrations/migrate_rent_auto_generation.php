<?php
/**
 * migrate_rent_auto_generation.php
 * Production migration for PMS Automatic Monthly Rent Generation:
 * 1. Creates unique constraint on rent_invoices(contract_id, due_date) to prevent duplicates at DB level.
 * 2. Reconciles existing invoice statuses (replaces invalid 'Paid' on unpaid invoices with 'Overdue' or 'Unpaid').
 * 3. Ensures scheduled_jobs has 'Daily Rent Scheduler' registered.
 * 4. Ensures all active contracts have an active rent_profile with auto_renewal = 1.
 */

require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../core/Database.php';

try {
    $db = Database::getInstance()->getConnection();
    echo "Connected to database: " . DB_NAME . "\n";
    echo "Timezone: Africa/Bangui\n";

    date_default_timezone_set('Africa/Bangui');
    $today = date('Y-m-d');

    // 1. Add Unique Constraint on rent_invoices (contract_id, due_date) if not already present
    echo "\n1. Checking unique index on rent_invoices(contract_id, due_date)...\n";
    $indexes = $db->query("SHOW INDEX FROM rent_invoices WHERE Key_name = 'uq_contract_due_date'")->fetchAll();
    if (empty($indexes)) {
        // First check if any duplicates exist before adding constraint
        $dups = $db->query("
            SELECT contract_id, due_date, COUNT(*) as cnt 
            FROM rent_invoices 
            GROUP BY contract_id, due_date 
            HAVING cnt > 1
        ")->fetchAll(PDO::FETCH_ASSOC);

        if (!empty($dups)) {
            echo "Warning: Found duplicate invoices for same contract and due date. Deduplicating...\n";
            foreach ($dups as $dup) {
                // Keep the one with payments or the lowest ID
                $dupInvs = $db->prepare("SELECT id FROM rent_invoices WHERE contract_id = ? AND due_date = ? ORDER BY id ASC");
                $dupInvs->execute([$dup['contract_id'], $dup['due_date']]);
                $ids = $dupInvs->fetchAll(PDO::FETCH_COLUMN);
                $keepId = array_shift($ids); // Keep first
                if (!empty($ids)) {
                    $inClause = implode(',', array_map('intval', $ids));
                    $db->exec("DELETE FROM rent_invoices WHERE id IN ($inClause) AND id NOT IN (SELECT invoice_id FROM rent_payments)");
                }
            }
        }

        $db->exec("ALTER TABLE rent_invoices ADD UNIQUE KEY uq_contract_due_date (contract_id, due_date)");
        echo "[OK] Created UNIQUE KEY uq_contract_due_date on rent_invoices(contract_id, due_date).\n";
    } else {
        echo "[OK] UNIQUE KEY uq_contract_due_date already exists.\n";
    }

    // 2. Reconcile existing invoice payment status and financial totals
    echo "\n2. Reconciling inconsistent invoice statuses...\n";
    $invoices = $db->query("
        SELECT ri.id, ri.contract_id, ri.invoice_number, ri.amount, ri.due_date, ri.status,
               COALESCE((SELECT SUM(amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0) as paid_amount
        FROM rent_invoices ri
    ")->fetchAll(PDO::FETCH_ASSOC);

    $reconciledCount = 0;
    $updateStmt = $db->prepare("UPDATE rent_invoices SET status = ? WHERE id = ?");

    foreach ($invoices as $inv) {
        if ($inv['status'] === 'Voided') {
            continue; // Keep voided as voided
        }

        $amount = (float)$inv['amount'];
        $paid = (float)$inv['paid_amount'];
        $balance = $amount - $paid;
        $isOverdue = ($inv['due_date'] < $today);

        $correctStatus = 'Unpaid';
        if ($balance <= 0.001 && $amount > 0) {
            $correctStatus = 'Paid';
        } elseif ($paid > 0 && $balance > 0.001) {
            $correctStatus = 'Partial';
        } else {
            $correctStatus = $isOverdue ? 'Overdue' : 'Unpaid';
        }

        if ($inv['status'] !== $correctStatus) {
            $updateStmt->execute([$correctStatus, $inv['id']]);
            echo "  Invoice #{$inv['id']} ({$inv['invoice_number']}): Status changed from '{$inv['status']}' to '{$correctStatus}' (Amount: {$amount}, Paid: {$paid}, Due: {$inv['due_date']})\n";
            $reconciledCount++;
        }
    }
    echo "[OK] Reconciled {$reconciledCount} invoice(s) to match actual payments and due dates.\n";

    // 3. Register Daily Rent Scheduler in scheduled_jobs if missing
    echo "\n3. Ensuring Daily Rent Scheduler is registered in scheduled_jobs...\n";
    $job = $db->query("SELECT id FROM scheduled_jobs WHERE job_name = 'Daily Rent Scheduler'")->fetch();
    if (!$job) {
        $db->exec("
            INSERT INTO scheduled_jobs (job_name, status, last_run, duration_seconds, records_processed, error_message)
            VALUES ('Daily Rent Scheduler', 'Success', NOW(), 0, 0, NULL)
        ");
        echo "[OK] Inserted 'Daily Rent Scheduler' into scheduled_jobs.\n";
    } else {
        echo "[OK] 'Daily Rent Scheduler' already registered.\n";
    }

    // 4. Ensure all active contracts have an active rent_profile with auto_renewal = 1
    echo "\n4. Ensuring rent profiles for active contracts...\n";
    $activeContracts = $db->query("
        SELECT c.*, rp.id as profile_id, rp.auto_renewal, rp.status as profile_status
        FROM contracts c
        LEFT JOIN rent_profiles rp ON c.id = rp.contract_id
        WHERE c.status IN ('Active', 'Approved') AND c.deleted_at IS NULL
    ")->fetchAll(PDO::FETCH_ASSOC);

    $profilesUpdated = 0;
    foreach ($activeContracts as $c) {
        if (!$c['profile_id']) {
            // Find latest invoice date or contract start date
            $latestInv = $db->prepare("SELECT due_date FROM rent_invoices WHERE contract_id = ? ORDER BY due_date DESC LIMIT 1");
            $latestInv->execute([$c['id']]);
            $lastDueDate = $latestInv->fetchColumn();

            $nextBilling = $lastDueDate ? date('Y-m-d', strtotime('+1 month', strtotime($lastDueDate))) : ($c['rent_start_date'] ?: $c['start_date']);

            $insProf = $db->prepare("
                INSERT INTO rent_profiles (tenant_id, apartment_id, contract_id, rent_start_date, monthly_amount, next_billing_date, billing_frequency, status, auto_renewal)
                VALUES (?, ?, ?, ?, ?, ?, 'Monthly', 'Active', 1)
            ");
            $insProf->execute([
                $c['tenant_id'],
                $c['apartment_id'],
                $c['id'],
                $c['rent_start_date'] ?: $c['start_date'],
                $c['monthly_rent'],
                $nextBilling
            ]);
            $profilesUpdated++;
            echo "  Created rent profile for Contract #{$c['id']} (Tenant #{$c['tenant_id']})\n";
        } else {
            // Ensure auto_renewal is 1 and status is Active
            if ($c['auto_renewal'] != 1 || $c['profile_status'] !== 'Active') {
                $db->prepare("UPDATE rent_profiles SET auto_renewal = 1, status = 'Active' WHERE id = ?")->execute([$c['profile_id']]);
                $profilesUpdated++;
                echo "  Enabled auto_renewal on Profile #{$c['profile_id']} for Contract #{$c['id']}\n";
            }
        }
    }
    echo "[OK] Updated/Created {$profilesUpdated} rent profile(s).\n";

    echo "\n============================================\n";
    echo "Migration completed successfully!\n";
    echo "============================================\n";

} catch (Exception $e) {
    echo "Migration failed: " . $e->getMessage() . "\n";
    exit(1);
}
