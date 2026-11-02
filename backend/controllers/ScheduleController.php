<?php

require_once __DIR__ . '/../services/ComplianceScheduleService.php';

class ScheduleController {
    private $db;
    private $complianceService;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
        $this->complianceService = new ComplianceScheduleService($this->db);
    }

    public function getSummary() {
        AuthMiddleware::requireLogin();
        date_default_timezone_set('Africa/Bangui');
        $today = date('Y-m-d');

        // Rent Queries
        $rentDueToday = $this->db->query("SELECT COUNT(*) FROM rent_invoices WHERE due_date = CURRENT_DATE() AND status != 'Paid'")->fetchColumn();
        $rentOverdue = $this->db->query("SELECT COUNT(*) FROM rent_invoices WHERE due_date < CURRENT_DATE() AND status != 'Paid'")->fetchColumn();
        $rentUpcoming = $this->db->query("SELECT COUNT(*) FROM rent_invoices WHERE due_date BETWEEN CURRENT_DATE() + INTERVAL 1 DAY AND CURRENT_DATE() + INTERVAL 7 DAY AND status != 'Paid'")->fetchColumn();

        // AC Queries
        $acDueToday = $this->db->query("SELECT COUNT(*) FROM ac_maintenance_tasks WHERE scheduled_date = CURRENT_DATE() AND status = 'Scheduled'")->fetchColumn();
        $acOverdue = $this->db->query("SELECT COUNT(*) FROM ac_maintenance_tasks WHERE scheduled_date < CURRENT_DATE() AND status = 'Scheduled'")->fetchColumn();
        $acPending = $this->db->query("SELECT COUNT(*) FROM ac_maintenance_tasks WHERE status = 'Pending_Approval'")->fetchColumn();
        $acUpcoming = $this->db->query("SELECT COUNT(*) FROM ac_maintenance_tasks WHERE scheduled_date BETWEEN CURRENT_DATE() + INTERVAL 1 DAY AND CURRENT_DATE() + INTERVAL 7 DAY AND status = 'Scheduled'")->fetchColumn();

        // Missing Tasks Queries (from missed_task_exceptions)
        $missingTotal = 0;
        $missingToday = 0;
        try {
            $missingTotal = (int)$this->db->query("SELECT COUNT(*) FROM missed_task_exceptions WHERE status = 'detected'")->fetchColumn();
            $missingToday = (int)$this->db->query("SELECT COUNT(*) FROM missed_task_exceptions WHERE status = 'detected' AND due_date = CURRENT_DATE()")->fetchColumn();
        } catch (Exception $e) {}

        // Get 30-day compliance metrics
        $startRange = date('Y-m-01');
        $endRange = date('Y-m-t');
        $complianceData = $this->complianceService->getCalendarEvents($startRange, $endRange);
        $metrics = $complianceData['metrics'] ?? [];

        $totalUpcoming = $rentUpcoming + $acUpcoming;

        echo json_encode([
            'rent_due_today' => (int)$rentDueToday,
            'rent_overdue' => (int)$rentOverdue,
            'ac_due_today' => (int)$acDueToday,
            'ac_overdue' => (int)$acOverdue,
            'ac_pending' => (int)$acPending,
            'missing_tasks_total' => $missingTotal,
            'missing_tasks_today' => $missingToday,
            'compliance_score' => $metrics['compliance_score'] ?? 100,
            'today_compliance_score' => $metrics['today_compliance_score'] ?? 100,
            'today_required' => $metrics['today_required'] ?? 0,
            'today_completed' => $metrics['today_completed'] ?? 0,
            'today_missing' => $metrics['today_missing'] ?? 0,
            'upcoming_events' => (int)$totalUpcoming,
            'ac_upcoming_week' => (int)$acUpcoming
        ]);
    }

    public function getCalendarEvents() {
        AuthMiddleware::requireLogin();
        date_default_timezone_set('Africa/Bangui');

        $startDate = $_GET['start'] ?? date('Y-m-01', strtotime('-1 month'));
        $endDate = $_GET['end'] ?? date('Y-m-t', strtotime('+2 months'));

        $filters = [
            'category' => $_GET['category'] ?? null,
            'status' => $_GET['status'] ?? null,
            'priority' => $_GET['priority'] ?? null,
            'building_id' => $_GET['building_id'] ?? null,
            'apartment_id' => $_GET['apartment_id'] ?? null,
            'search' => $_GET['search'] ?? null
        ];

        $result = $this->complianceService->getCalendarEvents($startDate, $endDate, $filters);

        // If format=full or with_metrics requested, return full wrapper
        if (isset($_GET['format']) && $_GET['format'] === 'full') {
            echo json_encode($result);
            return;
        }

        // Default: return events array directly for maximum backward compatibility
        echo json_encode($result['events']);
    }

    public function getEventsWithMetrics() {
        AuthMiddleware::requireLogin();
        date_default_timezone_set('Africa/Bangui');

        $startDate = $_GET['start'] ?? date('Y-m-01', strtotime('-1 month'));
        $endDate = $_GET['end'] ?? date('Y-m-t', strtotime('+2 months'));

        $filters = [
            'category' => $_GET['category'] ?? null,
            'status' => $_GET['status'] ?? null,
            'priority' => $_GET['priority'] ?? null,
            'building_id' => $_GET['building_id'] ?? null,
            'apartment_id' => $_GET['apartment_id'] ?? null,
            'search' => $_GET['search'] ?? null
        ];

        $result = $this->complianceService->getCalendarEvents($startDate, $endDate, $filters);
        echo json_encode($result);
    }

    public function generateMissingTask() {
        $user = AuthMiddleware::requireLogin();
        $userId = $user['user_id'] ?? $user['id'] ?? 1;

        $input = json_decode(file_get_contents('php://input'), true) ?? [];
        if (empty($input)) {
            http_response_code(400);
            echo json_encode(['error' => 'Invalid JSON payload.']);
            return;
        }

        try {
            $result = $this->complianceService->generateMissingTask($input, $userId);
            echo json_encode($result);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function recordTaskCompletion() {
        $user = AuthMiddleware::requireLogin();
        $userId = $user['user_id'] ?? $user['id'] ?? 1;

        $input = json_decode(file_get_contents('php://input'), true) ?? [];
        if (empty($input['task_id'])) {
            http_response_code(400);
            echo json_encode(['error' => 'task_id is required.']);
            return;
        }

        try {
            $result = $this->complianceService->recordTaskCompletion($input, $userId);
            echo json_encode($result);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function cancelTask() {
        $user = AuthMiddleware::requireLogin();
        $userId = $user['user_id'] ?? $user['id'] ?? 1;

        // Check if user has permission to cancel tasks (manager or admin)
        $userRole = strtolower($user['role'] ?? '');
        if (!in_array($userRole, ['admin', 'manager', 'super_admin'])) {
            http_response_code(403);
            echo json_encode(['error' => 'Unauthorized: Only Managers and Administrators can cancel scheduled tasks.']);
            return;
        }

        $input = json_decode(file_get_contents('php://input'), true) ?? [];
        $taskId = intval($input['task_id'] ?? 0);
        $reason = trim($input['reason'] ?? '');

        if (!$taskId || empty($reason)) {
            http_response_code(400);
            echo json_encode(['error' => 'task_id and cancellation reason are required.']);
            return;
        }

        try {
            $result = $this->complianceService->cancelTask($taskId, $reason, $userId);
            echo json_encode($result);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function reconcileSchedules() {
        AuthMiddleware::requireLogin();
        try {
            $result = ComplianceScheduleService::runScheduledReconciliation();
            echo json_encode($result);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }


    public function getNotifications() {
        AuthMiddleware::requireLogin();
        $notifications = [];

        // 1. Rent Overdue
        $rentOverdueStmt = $this->db->query("
            SELECT 
                r.id, r.due_date, a.code as apartment_code, b.name as building_name, DATEDIFF(CURRENT_DATE(), r.due_date) as days_overdue
            FROM rent_invoices r
            JOIN contracts c ON r.contract_id = c.id
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE r.due_date < CURRENT_DATE() AND r.status != 'Paid'
            ORDER BY r.due_date ASC
        ");
        foreach ($rentOverdueStmt->fetchAll(PDO::FETCH_ASSOC) as $item) {
            $notifications[] = [
                'type' => 'rent_overdue',
                'building' => $item['building_name'],
                'apartment' => $item['apartment_code'],
                'days' => (int)$item['days_overdue']
            ];
        }

        // 2. Rent Due Today
        $rentTodayStmt = $this->db->query("
            SELECT 
                r.id, a.code as apartment_code, b.name as building_name
            FROM rent_invoices r
            JOIN contracts c ON r.contract_id = c.id
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE r.due_date = CURRENT_DATE() AND r.status != 'Paid'
        ");
        foreach ($rentTodayStmt->fetchAll(PDO::FETCH_ASSOC) as $item) {
            $notifications[] = [
                'type' => 'rent_due_today',
                'building' => $item['building_name'],
                'apartment' => $item['apartment_code']
            ];
        }

        // 3. Rent Due Tomorrow
        $rentTomorrowStmt = $this->db->query("
            SELECT 
                r.id, a.code as apartment_code, b.name as building_name
            FROM rent_invoices r
            JOIN contracts c ON r.contract_id = c.id
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE r.due_date = CURRENT_DATE() + INTERVAL 1 DAY AND r.status != 'Paid'
        ");
        foreach ($rentTomorrowStmt->fetchAll(PDO::FETCH_ASSOC) as $item) {
            $notifications[] = [
                'type' => 'rent_due_tomorrow',
                'building' => $item['building_name'],
                'apartment' => $item['apartment_code']
            ];
        }

        // 4. AC Overdue
        $acOverdueStmt = $this->db->query("
            SELECT 
                t.id, t.scheduled_date, a.code as apartment_code, b.name as building_name, DATEDIFF(CURRENT_DATE(), t.scheduled_date) as days_overdue
            FROM ac_maintenance_tasks t
            JOIN apartments a ON t.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE t.scheduled_date < CURRENT_DATE() AND t.status = 'Scheduled'
            ORDER BY t.scheduled_date ASC
        ");
        foreach ($acOverdueStmt->fetchAll(PDO::FETCH_ASSOC) as $item) {
            $notifications[] = [
                'type' => 'ac_overdue',
                'building' => $item['building_name'],
                'apartment' => $item['apartment_code'],
                'days' => (int)$item['days_overdue']
            ];
        }

        // 5. AC Due Today
        $acTodayStmt = $this->db->query("
            SELECT 
                t.id, a.code as apartment_code, b.name as building_name
            FROM ac_maintenance_tasks t
            JOIN apartments a ON t.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE t.scheduled_date = CURRENT_DATE() AND t.status = 'Scheduled'
        ");
        foreach ($acTodayStmt->fetchAll(PDO::FETCH_ASSOC) as $item) {
            $notifications[] = [
                'type' => 'ac_due_today',
                'building' => $item['building_name'],
                'apartment' => $item['apartment_code']
            ];
        }

        // We can aggregate totals here or let frontend do it.
        // Frontend will aggregate them.
        
        // 6. Contract Expiring Soon (Next 30 days)
        $contractExpiringStmt = $this->db->query("
            SELECT 
                c.id, c.end_date, t.full_name as tenant_name, a.code as apartment_code, b.name as building_name, DATEDIFF(c.end_date, CURRENT_DATE()) as days_left
            FROM contracts c
            JOIN tenants t ON c.tenant_id = t.id
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE c.status = 'Active' 
              AND c.end_date >= CURRENT_DATE() 
              AND c.end_date <= CURRENT_DATE() + INTERVAL 30 DAY
            ORDER BY c.end_date ASC
        ");
        foreach ($contractExpiringStmt->fetchAll(PDO::FETCH_ASSOC) as $item) {
            $notifications[] = [
                'type' => 'contract_expiring',
                'building' => $item['building_name'],
                'apartment' => $item['apartment_code'],
                'tenant' => $item['tenant_name'],
                'days' => (int)$item['days_left'],
                'end_date' => $item['end_date']
            ];
        }

        // 7. Generator Subscriptions Due/Overdue (within 3 days)
        $genStmt = $this->db->query("
            SELECT 
                es.next_billing_date, es.amps, a.code as apartment_code, b.name as building_name, DATEDIFF(es.next_billing_date, CURRENT_DATE()) as days_left
            FROM electricity_subscriptions es
            JOIN apartments a ON es.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE es.status = 'Active' 
              AND es.next_billing_date <= DATE_ADD(CURRENT_DATE(), INTERVAL 7 DAY)
            ORDER BY es.next_billing_date ASC
        ");
        foreach ($genStmt->fetchAll(PDO::FETCH_ASSOC) as $item) {
            $is_metered = floatval($item['amps']) == 0;
            $notifications[] = [
                'type' => $is_metered ? 'generator_meter_reading' : 'generator_subscription_renewal',
                'building' => $item['building_name'],
                'apartment' => $item['apartment_code'],
                'days' => (int)$item['days_left'],
                'date' => $item['next_billing_date']
            ];
        }
        
        // 8. Tenant Rent Requests Pending/Denied
        $reqStmt = $this->db->query("
            SELECT 
                r.id, r.status, r.denial_reason, a.code as apartment_code, b.name as building_name, t.full_name as tenant_name,
                DATEDIFF(CURRENT_DATE(), r.created_at) as days_waiting
            FROM rent_collection_requests r
            JOIN apartments a ON r.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            JOIN tenants t ON r.tenant_id = t.id
            WHERE r.status IN ('PENDING_RESPONSE', 'DENIED')
        ");
        foreach ($reqStmt->fetchAll(PDO::FETCH_ASSOC) as $item) {
            $notifications[] = [
                'type' => $item['status'] === 'DENIED' ? 'tenant_request_denied' : 'tenant_request_pending',
                'building' => $item['building_name'],
                'apartment' => $item['apartment_code'],
                'tenant' => $item['tenant_name'],
                'reason' => $item['denial_reason'],
                'days' => (int)$item['days_waiting']
            ];
        }

        // 9. Missing Required Operations (Alerts for unperformed/uncreated tasks)
        try {
            $missingStmt = $this->db->query("
                SELECT category, title, due_date, target_type, target_id, DATEDIFF(CURRENT_DATE(), due_date) as days_missing
                FROM missed_task_exceptions
                WHERE status = 'detected'
                ORDER BY due_date DESC
                LIMIT 10
            ");
            foreach ($missingStmt->fetchAll(PDO::FETCH_ASSOC) as $mItem) {
                $notifications[] = [
                    'type' => 'missing_required_task',
                    'category' => $mItem['category'],
                    'title' => $mItem['title'],
                    'date' => $mItem['due_date'],
                    'days' => (int)$mItem['days_missing'],
                    'severity' => 'Critical'
                ];
            }
        } catch (Exception $e) {}

        echo json_encode($notifications);
    }

    public function getProDashboard() {
        AuthMiddleware::requireLogin();

        // 1. Maintenance Hub (Live DB Queries)
        $totalMaintenance = (int)$this->db->query("SELECT COUNT(*) FROM ac_maintenance_tasks")->fetchColumn();
        $completedMaintenance = (int)$this->db->query("SELECT COUNT(*) FROM ac_maintenance_tasks WHERE status = 'Completed'")->fetchColumn();
        $openMaintenance = (int)$this->db->query("SELECT COUNT(*) FROM ac_maintenance_tasks WHERE status != 'Completed'")->fetchColumn();

        $criticalTaskStmt = $this->db->query("
            SELECT 
                t.id, t.status, t.scheduled_date, COALESCE(t.notes, 'AC Maintenance & Inspection') as notes, a.code as apartment_code, b.name as building_name
            FROM ac_maintenance_tasks t
            JOIN apartments a ON t.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE t.status != 'Completed'
            ORDER BY t.scheduled_date ASC
            LIMIT 1
        ");
        $criticalTask = $criticalTaskStmt->fetch(PDO::FETCH_ASSOC);

        // 2. Lease Center (Live DB Queries)
        $expiringLeasesCount = (int)$this->db->query("
            SELECT COUNT(*) FROM contracts 
            WHERE status = 'Active' 
        ")->fetchColumn();

        $expiringLeasesStmt = $this->db->query("
            SELECT 
                c.id, c.end_date, t.full_name as tenant_name, a.code as apartment_code, b.name as building_name
            FROM contracts c
            JOIN tenants t ON c.tenant_id = t.id
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE c.status = 'Active'
            ORDER BY c.end_date ASC
            LIMIT 5
        ");
        $expiringLeases = $expiringLeasesStmt->fetchAll(PDO::FETCH_ASSOC);

        // 3. Contract Hub (Live DB Queries)
        $vendorContractsStmt = $this->db->query("
            SELECT 
                c.id, c.start_date, c.end_date, c.status, a.code as apartment_code, b.name as building_name, t.full_name as tenant_name
            FROM contracts c
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            JOIN tenants t ON c.tenant_id = t.id
            ORDER BY c.end_date ASC
            LIMIT 5
        ");
        $vendorContracts = $vendorContractsStmt->fetchAll(PDO::FETCH_ASSOC);

        // 4. Employee Performance (Live DB Queries)
        $employeesStmt = $this->db->query("
            SELECT id, name, role FROM users WHERE role IN ('admin', 'manager', 'agent', 'maintenance') LIMIT 4
        ");
        $employees = $employeesStmt->fetchAll(PDO::FETCH_ASSOC);

        $employeeTasks = [];
        $rank = 1;
        foreach ($employees as $emp) {
            $employeeTasks[] = [
                'rank' => $rank++,
                'id' => $emp['id'],
                'name' => $emp['name'],
                'role' => ucfirst($emp['role']),
                'score' => 100,
                'task_desc' => $emp['role'] === 'agent' ? 'Rent & Meter Collection' : ($emp['role'] === 'maintenance' ? 'AC Maintenance' : 'Operations Oversight'),
                'status' => 'In Progress'
            ];
        }

        // 5. Rent & Compliance Hub (Live DB Queries)
        $unitsComplianceStmt = $this->db->query("
            SELECT 
                a.id, a.code as apartment_code, b.name as building_name,
                (SELECT r.status FROM rent_invoices r JOIN contracts c ON r.contract_id = c.id WHERE c.apartment_id = a.id AND r.status != 'Paid' LIMIT 1) as rent_status,
                (SELECT CASE WHEN COUNT(*) > 0 THEN 'Paid' ELSE 'Pending' END FROM insurance_accounts ia JOIN contracts c2 ON ia.contract_id = c2.id WHERE c2.apartment_id = a.id) as insurance_status
            FROM apartments a
            JOIN buildings b ON a.building_id = b.id
            LIMIT 6
        ");
        $unitsCompliance = [];
        foreach ($unitsComplianceStmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
            $rentSt = $row['rent_status'] ? ($row['rent_status'] === 'Overdue' ? 'Pending' : $row['rent_status']) : 'Paid';
            $insSt = $row['insurance_status'] ? $row['insurance_status'] : 'Paid';
            $nextAction = ($rentSt === 'Pending' || $rentSt === 'Overdue') ? 'Verify' : ($insSt === 'Pending' ? 'Invoice' : 'None');

            $unitsCompliance[] = [
                'unit' => $row['building_name'] . ' - ' . $row['apartment_code'],
                'rent_status' => $rentSt,
                'insurance_status' => $insSt,
                'next_action' => $nextAction
            ];
        }

        // 6. Today's Command Checklist (Live DB Queries)
        $todayTasks = [];
        
        // AC maintenance tasks from DB
        $acTasks = $this->db->query("
            SELECT t.id, t.scheduled_date, t.status, a.code as apartment_code, b.name as building_name
            FROM ac_maintenance_tasks t
            JOIN apartments a ON t.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            LIMIT 4
        ")->fetchAll(PDO::FETCH_ASSOC);

        foreach ($acTasks as $ac) {
            $todayTasks[] = [
                'id' => 'ac_' . $ac['id'],
                'text' => 'AC Cleaning: ' . $ac['building_name'] . ' - Unit ' . $ac['apartment_code'],
                'icon' => '⚙️',
                'assignee' => 'Maintenance',
                'status' => $ac['status'] === 'Completed' ? 'Completed' : 'Scheduled',
                'completed' => $ac['status'] === 'Completed'
            ];
        }

        // Active Lease Renewal Check
        $contractsForTasks = $this->db->query("
            SELECT c.id, t.full_name as tenant_name, a.code as apartment_code, b.name as building_name
            FROM contracts c
            JOIN tenants t ON c.tenant_id = t.id
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            LIMIT 2
        ")->fetchAll(PDO::FETCH_ASSOC);

        foreach ($contractsForTasks as $ct) {
            $todayTasks[] = [
                'id' => 'contract_' . $ct['id'],
                'text' => 'Lease Verification: ' . $ct['building_name'] . ' Unit ' . $ct['apartment_code'] . ' (' . $ct['tenant_name'] . ')',
                'icon' => '📝',
                'assignee' => 'Manager',
                'status' => 'Completed',
                'completed' => true
            ];
        }

        echo json_encode([
            'maintenance' => [
                'total' => $totalMaintenance,
                'open' => $openMaintenance,
                'completed' => $completedMaintenance,
                'critical_alert' => $criticalTask ? [
                    'title' => 'CRITICAL: AC Maintenance Request',
                    'detail' => $criticalTask['building_name'] . ' Unit ' . $criticalTask['apartment_code'] . ' | Scheduled: ' . $criticalTask['scheduled_date']
                ] : null
            ],
            'lease_center' => [
                'expiring_count' => $expiringLeasesCount,
                'leases' => array_map(function($l) {
                    return [
                        'tenant' => $l['tenant_name'],
                        'unit' => $l['building_name'] . ' - ' . $l['apartment_code'],
                        'expiry' => $l['end_date']
                    ];
                }, $expiringLeases)
            ],
            'contract_hub' => [
                'contracts' => array_map(function($vc) {
                    return [
                        'type' => $vc['building_name'] . ' - Apt ' . $vc['apartment_code'],
                        'date' => $vc['end_date'],
                        'status' => $vc['status']
                    ];
                }, $vendorContracts)
            ],
            'employee_performance' => [
                'completed_count' => count($employeeTasks),
                'employees' => $employeeTasks
            ],
            'rent_compliance' => $unitsCompliance,
            'today_command' => $todayTasks
        ]);
    }
}

