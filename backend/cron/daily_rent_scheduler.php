<?php
// backend/cron/daily_rent_scheduler.php
// Production Daily Rent Scheduler Job
// Run via CLI: php backend/cron/daily_rent_scheduler.php
// Or via Windows Task Scheduler / Linux Cron

require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../core/Database.php';
require_once __DIR__ . '/../services/RentGenerationService.php';

class DailyRentScheduler {
    public static function run() {
        echo "[" . date('Y-m-d H:i:s') . "] Starting Daily Rent Scheduler (Africa/Bangui)...\n";
        $result = RentGenerationService::runDaily();
        echo "Status: {$result['status']}\n";
        echo "Duration: {$result['duration_seconds']}s\n";
        echo "Invoices Created: {$result['invoices_created']}\n";
        echo "Statuses Reconciled: {$result['statuses_reconciled']}\n";
        if (!empty($result['details'])) {
            echo "Details:\n";
            foreach ($result['details'] as $d) {
                echo "  + Contract #{$d['contract_id']} ({$d['tenant_name']}): Invoice {$d['invoice_number']} for {$d['due_date']} (CFA {$d['amount']}) -> Next Billing: {$d['next_billing_date']}\n";
            }
        }
        if (!empty($result['errors'])) {
            echo "Errors encountered:\n";
            foreach ($result['errors'] as $err) {
                echo "  - Contract #{$err['contract_id']} (Due: {$err['due_date']}): {$err['error']}\n";
            }
        }
        echo "[" . date('Y-m-d H:i:s') . "] Daily Rent Scheduler completed.\n";
        return $result;
    }
}

// If called directly from CLI or external execution
if (php_sapi_name() === "cli" || !defined('INDEX_INCLUDED')) {
    DailyRentScheduler::run();
}
