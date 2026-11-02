<?php
// backend/cron/daily_compliance_scheduler.php
// Production Scheduled Job for Automated Property Operations & Compliance Calendar
// Automatically reconciles active generators, electricity subscriptions, maintenance inspections.
// Detects missing tasks, generates due recurring tasks, updates exception records, and computes compliance.

require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../core/Database.php';
require_once __DIR__ . '/../services/ComplianceScheduleService.php';

class DailyComplianceScheduler {
    public static function run() {
        date_default_timezone_set('Africa/Bangui');
        echo "[" . date('Y-m-d H:i:s') . "] Starting Daily Operations & Compliance Scheduler (Africa/Bangui)...\n";

        try {
            $result = ComplianceScheduleService::runScheduledReconciliation();
            echo "Status: {$result['status']}\n";
            echo "Duration: {$result['duration_seconds']}s\n";
            echo "Tasks Auto-Generated: {$result['tasks_generated']}\n";
            echo "Executed At: {$result['executed_at']}\n";
            echo "[" . date('Y-m-d H:i:s') . "] Daily Operations & Compliance Scheduler completed successfully.\n";
            return $result;
        } catch (Exception $e) {
            echo "Error during compliance scheduler: " . $e->getMessage() . "\n";
            echo $e->getTraceAsString() . "\n";
            return ['status' => 'error', 'error' => $e->getMessage()];
        }
    }
}

// If invoked from CLI or direct execution
if (php_sapi_name() === 'cli' || !defined('INDEX_INCLUDED')) {
    DailyComplianceScheduler::run();
}
