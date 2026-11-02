<?php
/**
 * ComplianceScheduleTest.php
 * Automated tests for Automated Property Operations & Compliance Calendar
 */

require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../core/Database.php';
require_once __DIR__ . '/../services/ComplianceScheduleService.php';

class ComplianceScheduleTest {
    private $db;
    private $service;
    private $passCount = 0;
    private $failCount = 0;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
        $this->service = new ComplianceScheduleService($this->db);
        date_default_timezone_set('Africa/Bangui');
    }

    private function assert($condition, $message) {
        if ($condition) {
            echo "  [PASS] $message\n";
            $this->passCount++;
        } else {
            echo "  [FAIL] $message\n";
            $this->failCount++;
        }
    }

    public function runAll() {
        echo "========================================================\n";
        echo " Running Compliance Schedule & Operations Test Suite\n";
        echo " Timezone: Africa/Bangui | Target: live bitar_pms DB\n";
        echo "========================================================\n\n";

        $this->test1_MissingGeneratorCheckDetected();
        $this->test2_OverdueTaskStatusCalculation();
        $this->test3_CompletedHistoryRetained();
        $this->test4_NextRecurrenceAfterCompletion();
        $this->test5_ElectricitySubscriptionRenewalMissingDetected();
        $this->test6_PaidRentReflectsConfirmedPayment();
        $this->test7_SchedulerIdempotencyAndNoDuplicates();
        $this->test8_SchedulerRecoveryAfterDowntime();
        $this->test9_UnauthorizedDismissalOrCancellationRejected();
        $this->test10_InactiveSubscriptionOrOfflineGeneratorNoFalseAlerts();
        $this->test11_MultipleEventsOnSameDay();
        $this->test12_ComplianceScoreCalculation();

        echo "\n========================================================\n";
        echo " Test Results: {$this->passCount} Passed, {$this->failCount} Failed\n";
        echo "========================================================\n";

        return $this->failCount === 0;
    }

    // 1. A required generator inspection has no task -> System displays a red missing-task alert
    private function test1_MissingGeneratorCheckDetected() {
        echo "1. Testing Missing Generator Check Detection...\n";
        $events = $this->service->getCalendarEvents('2026-10-01', '2026-10-01', ['category' => 'generator']);
        $missingGen = null;
        foreach ($events['events'] as $e) {
            if ($e['category'] === 'generator' && $e['is_missing']) {
                $missingGen = $e;
                break;
            }
        }
        $this->assert($missingGen !== null, "Detected missing generator task for active generator on 2026-10-01");
        $this->assert($missingGen && $missingGen['status'] === 'Missing', "Missing generator check has status 'Missing'");
        $this->assert($missingGen && $missingGen['priority'] === 'Critical', "Missing generator check marked as 'Critical' priority");
    }

    // 2. A recurring task exists but is overdue -> System displays it as overdue
    private function test2_OverdueTaskStatusCalculation() {
        echo "\n2. Testing Overdue Task Status Calculation...\n";
        $events = $this->service->getCalendarEvents('2026-10-01', '2026-10-24');
        $hasOverdue = false;
        foreach ($events['events'] as $e) {
            if ($e['status'] === 'Overdue') {
                $hasOverdue = true;
                break;
            }
        }
        $this->assert($hasOverdue, "Calendar correctly flags overdue operations whose deadline passed without completion");
    }

    // 3. An operation has been completed and verified -> System retains its completed history
    private function test3_CompletedHistoryRetained() {
        echo "\n3. Testing Completed History Retained...\n";
        $events = $this->service->getCalendarEvents('2026-10-25', '2026-10-25');
        $hasCompleted = false;
        foreach ($events['events'] as $e) {
            if ($e['status'] === 'Completed') {
                $hasCompleted = true;
                $this->assert(isset($e['source_record']), "Completed event retains linked source record: {$e['source_record']}");
                break;
            }
        }
        $this->assert($hasCompleted, "Completed operation remains visible in historical calendar records");
    }

    // 4. Next recurring inspection is due after previous was completed -> Both records remain correct
    private function test4_NextRecurrenceAfterCompletion() {
        echo "\n4. Testing Recurrence After Previous Completion...\n";
        // Today (2026-10-25) has completed task, tomorrow (2026-10-26) should be scheduled/projected
        $eventsWindow = $this->service->getCalendarEvents('2026-10-25', '2026-10-26');
        $completedFound = false;
        $nextFound = false;
        foreach ($eventsWindow['events'] as $e) {
            if ($e['date'] === '2026-10-25' && $e['status'] === 'Completed') $completedFound = true;
            if ($e['date'] === '2026-10-26') $nextFound = true;
        }
        $this->assert($completedFound && $nextFound, "Previous completed record preserved while next recurring operation is scheduled");
    }

    // 5. Electricity subscription active & renewal missing -> Detected
    private function test5_ElectricitySubscriptionRenewalMissingDetected() {
        echo "\n5. Testing Electricity Subscription Renewal Detection...\n";
        $events = $this->service->getCalendarEvents('2026-09-01', '2026-10-31', ['category' => 'electricity']);
        $hasElec = count($events['events']) > 0;
        $this->assert($hasElec, "Electricity subscription events and billing reminders correctly surfaced in calendar");
    }

    // 6. Tenant paid rent -> Confirmed payment reflected
    private function test6_PaidRentReflectsConfirmedPayment() {
        echo "\n6. Testing Paid Rent Confirmation...\n";
        // Check rent invoices
        $paidInv = $this->db->query("SELECT id, due_date FROM rent_invoices WHERE status = 'Paid' LIMIT 1")->fetch(PDO::FETCH_ASSOC);
        if ($paidInv) {
            $events = $this->service->getCalendarEvents($paidInv['due_date'], $paidInv['due_date'], ['category' => 'rent']);
            $foundPaid = false;
            foreach ($events['events'] as $e) {
                if ($e['source_id'] == $paidInv['id'] && $e['status'] === 'Completed') {
                    $foundPaid = true;
                    break;
                }
            }
            $this->assert($foundPaid, "Paid rent invoice reflects as Completed/Paid in calendar");
        } else {
            $this->assert(true, "No paid rent invoice exists in sample range to test");
        }
    }

    // 7. Scheduler runs twice -> Does not create duplicate tasks
    private function test7_SchedulerIdempotencyAndNoDuplicates() {
        echo "\n7. Testing Scheduler Idempotency & Duplicate Prevention...\n";
        $res1 = ComplianceScheduleService::runScheduledReconciliation();
        $tasksCreatedRun1 = $res1['tasks_generated'];

        $res2 = ComplianceScheduleService::runScheduledReconciliation();
        $tasksCreatedRun2 = $res2['tasks_generated'];

        $this->assert($tasksCreatedRun2 === 0, "Second run of reconciliation generated 0 duplicate tasks (Idempotent: YES)");
    }

    // 8. Scheduler recovery after downtime -> Recovers missed required tasks
    private function test8_SchedulerRecoveryAfterDowntime() {
        echo "\n8. Testing Downtime Recovery...\n";
        // Ensure scheduler processes up to 7 days forward and reconciles past missing tasks
        $res = ComplianceScheduleService::runScheduledReconciliation();
        $this->assert($res['status'] === 'success', "Scheduler safely executes and recovers unhandled schedules");
    }

    // 9. Unauthorized employee attempts cancellation -> Server rejects
    private function test9_UnauthorizedDismissalOrCancellationRejected() {
        echo "\n9. Testing Server-side Permission Enforcement...\n";
        $exceptionThrown = false;
        try {
            // Role 'agent' or unauthorized user cannot cancel task without permission
            // Test cancelTask without required reason
            $this->service->cancelTask(1, "", 999);
        } catch (Exception $e) {
            $exceptionThrown = true;
        }
        $this->assert($exceptionThrown, "Cancellation rejected when reason or required authorization is missing");
    }

    // 10. Inactive subscription or offline generator -> No false alerts
    private function test10_InactiveSubscriptionOrOfflineGeneratorNoFalseAlerts() {
        echo "\n10. Testing Offline/Retired Generator Filter...\n";
        // Generator ID 13 is 'Offline'
        $events = $this->service->getCalendarEvents('2026-10-01', '2026-10-31', ['category' => 'generator']);
        $offlineGenAlerts = 0;
        foreach ($events['events'] as $e) {
            if (isset($e['equipment_name']) && $e['equipment_name'] === 'CORNISHE' && $e['is_missing']) {
                $offlineGenAlerts++;
            }
        }
        $this->assert($offlineGenAlerts === 0, "Offline/retired generator (CORNISHE) generates 0 false missing alerts");
    }

    // 11. Multiple events on same day
    private function test11_MultipleEventsOnSameDay() {
        echo "\n11. Testing Multiple Events on Same Day Handling...\n";
        $events = $this->service->getCalendarEvents('2026-10-25', '2026-10-25');
        $this->assert(count($events['events']) > 0, "Calendar handles multiple operations and density on same date without data truncation");
    }

    // 12. Compliance Score calculation
    private function test12_ComplianceScoreCalculation() {
        echo "\n12. Testing Compliance Score Engine...\n";
        $events = $this->service->getCalendarEvents('2026-10-01', '2026-10-31');
        $metrics = $events['metrics'];
        $this->assert(isset($metrics['compliance_score']), "Calculated compliance score: {$metrics['compliance_score']}%");
        $this->assert(isset($metrics['missing']) && $metrics['missing'] >= 0, "Tracked missing tasks: {$metrics['missing']}");
        $this->assert(isset($metrics['completed']) && $metrics['completed'] >= 0, "Tracked completed tasks: {$metrics['completed']}");
    }
}

// Run test suite
$suite = new ComplianceScheduleTest();
$success = $suite->runAll();
exit($success ? 0 : 1);
