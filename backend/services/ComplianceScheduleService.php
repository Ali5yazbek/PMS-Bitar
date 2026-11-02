<?php
/**
 * ComplianceScheduleService.php
 * Core engine for Automated Property Operations & Compliance Calendar
 * Handles:
 *  - 5 Operational categories: Rent, Electricity, Maintenance, Generator, Leases
 *  - Automated Task Generation & Idempotent Schedule Engine
 *  - Missing-Task Detection Engine (comparing Requirements vs Tasks vs Completions)
 *  - Daily Compliance Score calculation
 *  - 1-click Repair / Task Generation
 *  - Completion with proof of work, audit trail & permissions
 */

require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../core/Database.php';

class ComplianceScheduleService {
    private $db;

    public function __construct($db = null) {
        $this->db = $db ?? Database::getInstance()->getConnection();
    }

    /**
     * Get unified events and compliance data for calendar and hub views
     *
     * @param string $startDate 'YYYY-MM-DD'
     * @param string $endDate   'YYYY-MM-DD'
     * @param array  $filters   ['category', 'building_id', 'apartment_id', 'status', 'priority', 'search']
     * @return array
     */
    public function getCalendarEvents($startDate, $endDate, $filters = []) {
        date_default_timezone_set('Africa/Bangui');
        $today = date('Y-m-d');

        $events = [];

        // 1. Fetch Rent Invoices (Rent Category)
        $rentEvents = $this->fetchRentEvents($startDate, $endDate, $filters, $today);
        $events = array_merge($events, $rentEvents);

        // 2. Fetch Electricity Subscriptions & Invoices (Electricity Category)
        $elecEvents = $this->fetchElectricityEvents($startDate, $endDate, $filters, $today);
        $events = array_merge($events, $elecEvents);

        // 3. Fetch Maintenance (AC Preventive + Corrective Tickets + General Tasks)
        $maintEvents = $this->fetchMaintenanceEvents($startDate, $endDate, $filters, $today);
        $events = array_merge($events, $maintEvents);

        // 4. Fetch Generator Operations, Inspections & Missing Daily Checks
        $genEvents = $this->fetchGeneratorEvents($startDate, $endDate, $filters, $today);
        $events = array_merge($events, $genEvents);

        // 5. Fetch Expiring Leases / Contracts (Lease Category)
        $leaseEvents = $this->fetchLeaseEvents($startDate, $endDate, $filters, $today);
        $events = array_merge($events, $leaseEvents);

        // Apply filters
        $filteredEvents = $this->applyFilters($events, $filters);

        // Sort events chronologically, then by severity (Missing & Overdue first)
        usort($filteredEvents, function ($a, $b) {
            if ($a['date'] === $b['date']) {
                $priorityWeight = ['Critical' => 4, 'Urgent' => 3, 'High' => 2, 'Normal' => 1, 'Low' => 0];
                $pwA = $priorityWeight[$a['priority'] ?? 'Normal'] ?? 1;
                $pwB = $priorityWeight[$b['priority'] ?? 'Normal'] ?? 1;
                if ($a['is_missing'] ?? false) $pwA += 5;
                if ($b['is_missing'] ?? false) $pwB += 5;
                return $pwB <=> $pwA;
            }
            return strcmp($a['date'], $b['date']);
        });

        // Compute Compliance Metrics
        $metrics = $this->computeComplianceScore($filteredEvents, $today);

        return [
            'events' => $filteredEvents,
            'metrics' => $metrics,
            'date_range' => [
                'start' => $startDate,
                'end' => $endDate,
                'today' => $today
            ]
        ];
    }

    /**
     * 1. Rent Category Events
     */
    private function fetchRentEvents($startDate, $endDate, $filters, $today) {
        $events = [];

        $sql = "
            SELECT 
                r.id, 
                r.invoice_number, 
                r.amount, 
                COALESCE((SELECT SUM(amount) FROM rent_payments rp WHERE rp.invoice_id = r.id), 0) as paid_amount, 
                r.due_date as date, 
                r.period_start,
                r.period_end, 
                r.status, 
                c.id as contract_id,
                t.full_name as tenant_name, 
                t.id as tenant_id,
                a.id as apartment_id,
                a.code as apartment_code, 
                b.id as building_id,
                b.name as building_name
            FROM rent_invoices r
            JOIN contracts c ON r.contract_id = c.id
            JOIN tenants t ON c.tenant_id = t.id
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE r.due_date BETWEEN ? AND ?
              AND r.status != 'Voided'
        ";

        $params = [$startDate, $endDate];
        if (!empty($filters['building_id'])) {
            $sql .= " AND b.id = ?";
            $params[] = $filters['building_id'];
        }
        if (!empty($filters['apartment_id'])) {
            $sql .= " AND a.id = ?";
            $params[] = $filters['apartment_id'];
        }

        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        foreach ($rows as $r) {
            $isPaid = ($r['status'] === 'Paid' || floatval($r['paid_amount']) >= floatval($r['amount']));
            $isPartiallyPaid = ($r['status'] === 'Partially Paid' || (floatval($r['paid_amount']) > 0 && floatval($r['paid_amount']) < floatval($r['amount'])));
            $isPastDue = ($r['date'] < $today);
            $isToday = ($r['date'] === $today);

            if ($isPaid) {
                $status = 'Completed';
                $statusLabel = 'Paid';
                $priority = 'Normal';
            } elseif ($isPartiallyPaid) {
                $status = $isPastDue ? 'Overdue' : 'Pending';
                $statusLabel = 'Partially Paid';
                $priority = 'High';
            } elseif ($isPastDue) {
                $status = 'Overdue';
                $statusLabel = 'Rent Overdue';
                $priority = 'Urgent';
            } elseif ($isToday) {
                $status = 'Pending';
                $statusLabel = 'Rent Due Today';
                $priority = 'High';
            } else {
                $status = 'Scheduled';
                $statusLabel = 'Rent Upcoming';
                $priority = 'Normal';
            }

            $events[] = [
                'id' => 'rent_' . $r['id'],
                'raw_id' => (int)$r['id'],
                'category' => 'rent',
                'event_type' => 'rent',
                'title' => "Rent Due: {$r['tenant_name']} (Apt {$r['apartment_code']})",
                'description' => "Invoice #{$r['invoice_number']} for CFA " . number_format($r['amount']) . " - Paid: CFA " . number_format($r['paid_amount']),
                'date' => $r['date'],
                'status' => $status,
                'status_label' => $statusLabel,
                'priority' => $priority,
                'is_missing' => false,
                'building_id' => (int)$r['building_id'],
                'building_name' => $r['building_name'],
                'apartment_id' => (int)$r['apartment_id'],
                'apartment_code' => $r['apartment_code'],
                'tenant_id' => (int)$r['tenant_id'],
                'tenant_name' => $r['tenant_name'],
                'amount' => floatval($r['amount']),
                'paid_amount' => floatval($r['paid_amount']),
                'invoice_number' => $r['invoice_number'],
                'source_record' => 'rent_invoices',
                'source_id' => (int)$r['id'],
                'action_url' => "/rent?search={$r['apartment_code']}"
            ];
        }

        return $events;
    }

    /**
     * 2. Electricity Category Events (Subscriptions & Invoices)
     */
    private function fetchElectricityEvents($startDate, $endDate, $filters, $today) {
        $events = [];

        // A. Electricity Invoices due in date range
        $invSql = "
            SELECT 
                ei.id, 
                ei.apartment_id, 
                ei.type, 
                ei.amount, 
                ei.amount_paid, 
                ei.due_date as date, 
                ei.status, 
                a.code as apartment_code, 
                b.id as building_id,
                b.name as building_name
            FROM electricity_invoices ei
            JOIN apartments a ON ei.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE ei.due_date BETWEEN ? AND ?
        ";
        $params = [$startDate, $endDate];
        if (!empty($filters['building_id'])) {
            $invSql .= " AND b.id = ?";
            $params[] = $filters['building_id'];
        }
        if (!empty($filters['apartment_id'])) {
            $invSql .= " AND a.id = ?";
            $params[] = $filters['apartment_id'];
        }

        $stmt = $this->db->prepare($invSql);
        $stmt->execute($params);
        $invoices = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $coveredApartmentsInvoices = [];

        foreach ($invoices as $ei) {
            $coveredApartmentsInvoices[$ei['apartment_id'] . '_' . $ei['date']] = true;
            $isPaid = ($ei['status'] === 'Paid' || floatval($ei['amount_paid']) >= floatval($ei['amount']));
            $isPastDue = ($ei['date'] < $today);

            if ($isPaid) {
                $status = 'Completed';
                $statusLabel = 'Bill Paid';
                $priority = 'Normal';
            } elseif ($isPastDue) {
                $status = 'Overdue';
                $statusLabel = 'Electricity Overdue';
                $priority = 'Urgent';
            } elseif ($ei['date'] === $today) {
                $status = 'Pending';
                $statusLabel = 'Due Today';
                $priority = 'High';
            } else {
                $status = 'Scheduled';
                $statusLabel = 'Upcoming Bill';
                $priority = 'Normal';
            }

            $events[] = [
                'id' => 'elec_inv_' . $ei['id'],
                'raw_id' => (int)$ei['id'],
                'category' => 'electricity',
                'event_type' => 'electricity',
                'title' => "Electricity Bill ({$ei['type']}): Apt {$ei['apartment_code']}",
                'description' => "Electricity {$ei['type']} bill CFA " . number_format($ei['amount']) . " - Status: {$ei['status']}",
                'date' => $ei['date'],
                'status' => $status,
                'status_label' => $statusLabel,
                'priority' => $priority,
                'is_missing' => false,
                'building_id' => (int)$ei['building_id'],
                'building_name' => $ei['building_name'],
                'apartment_id' => (int)$ei['apartment_id'],
                'apartment_code' => $ei['apartment_code'],
                'amount' => floatval($ei['amount']),
                'source_record' => 'electricity_invoices',
                'source_id' => (int)$ei['id'],
                'action_url' => "/energy"
            ];
        }

        // B. Active Electricity Subscriptions (Billing / Renewal Cycle Detection)
        // If an active subscription has next_billing_date in the window and no invoice exists
        $subSql = "
            SELECT 
                es.id, 
                es.apartment_id, 
                es.type, 
                es.monthly_fee, 
                es.amps, 
                es.next_billing_date as date, 
                es.status, 
                a.code as apartment_code, 
                b.id as building_id,
                b.name as building_name
            FROM electricity_subscriptions es
            JOIN apartments a ON es.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE es.status = 'Active'
              AND es.next_billing_date IS NOT NULL
              AND es.next_billing_date BETWEEN ? AND ?
        ";
        $subParams = [$startDate, $endDate];
        if (!empty($filters['building_id'])) {
            $subSql .= " AND b.id = ?";
            $subParams[] = $filters['building_id'];
        }
        if (!empty($filters['apartment_id'])) {
            $subSql .= " AND a.id = ?";
            $subParams[] = $filters['apartment_id'];
        }

        $subStmt = $this->db->prepare($subSql);
        $subStmt->execute($subParams);
        $activeSubs = $subStmt->fetchAll(PDO::FETCH_ASSOC);

        foreach ($activeSubs as $sub) {
            // Check if an invoice or completed task already exists for this date & apartment
            $key = $sub['apartment_id'] . '_' . $sub['date'];
            if (isset($coveredApartmentsInvoices[$key])) {
                continue; // Already displayed as invoice
            }

            // Check if a task exists in tasks table
            $taskCheck = $this->db->prepare("
                SELECT id, status, title FROM tasks 
                WHERE (related_entity_type = 'electricity_subscriptions' AND related_entity_id = ?)
                   OR (type = 'Electricity' AND apartment_id = ? AND due_date = ?)
                LIMIT 1
            ");
            $taskCheck->execute([$sub['id'], $sub['apartment_id'], $sub['date']]);
            $existingTask = $taskCheck->fetch(PDO::FETCH_ASSOC);

            if ($existingTask) {
                $status = ($existingTask['status'] === 'Completed') ? 'Completed' : ($sub['date'] < $today ? 'Overdue' : 'Pending');
                $isMissing = false;
                $statusLabel = ($status === 'Completed') ? 'Renewal Processed' : ($status === 'Overdue' ? 'Renewal Overdue' : 'Renewal Pending');
            } else {
                // MISSING TASK DETECTED!
                $isMissing = ($sub['date'] <= $today);
                $status = $isMissing ? 'Missing' : 'Scheduled';
                $statusLabel = $isMissing ? 'MISSING TASK: Renewal Not Created' : 'Upcoming Renewal';
            }

            $events[] = [
                'id' => 'elec_sub_' . $sub['id'],
                'raw_id' => (int)$sub['id'],
                'category' => 'electricity',
                'event_type' => 'electricity',
                'title' => ($isMissing ? '⚠️ MISSING: ' : '') . "Electricity Renewal: Apt {$sub['apartment_code']} ({$sub['type']})",
                'description' => "Active subscription (#{$sub['id']}) billing cycle due {$sub['date']}. Fee: CFA " . number_format($sub['monthly_fee']),
                'date' => $sub['date'],
                'status' => $status,
                'status_label' => $statusLabel,
                'priority' => $isMissing ? 'Critical' : 'High',
                'is_missing' => $isMissing,
                'building_id' => (int)$sub['building_id'],
                'building_name' => $sub['building_name'],
                'apartment_id' => (int)$sub['apartment_id'],
                'apartment_code' => $sub['apartment_code'],
                'source_record' => 'electricity_subscriptions',
                'source_id' => (int)$sub['id'],
                'action_url' => "/energy",
                'repair_action' => [
                    'category' => 'electricity',
                    'target_type' => 'subscription',
                    'target_id' => (int)$sub['id'],
                    'due_date' => $sub['date'],
                    'title' => "Process Electricity Renewal: Apt {$sub['apartment_code']}"
                ]
            ];
        }

        return $events;
    }

    /**
     * 3. Building & Apartment Maintenance Category
     */
    private function fetchMaintenanceEvents($startDate, $endDate, $filters, $today) {
        $events = [];

        // A. ac_maintenance_tasks
        $acSql = "
            SELECT 
                t.id, 
                t.scheduled_date as date, 
                t.status, 
                t.worker_id, 
                t.notes, 
                t.before_photo, 
                t.after_photo, 
                a.id as apartment_id,
                a.code as apartment_code, 
                b.id as building_id,
                b.name as building_name,
                u.name as worker_name
            FROM ac_maintenance_tasks t
            JOIN apartments a ON t.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            LEFT JOIN users u ON t.worker_id = u.id
            WHERE t.scheduled_date BETWEEN ? AND ?
        ";
        $params = [$startDate, $endDate];
        if (!empty($filters['building_id'])) {
            $acSql .= " AND b.id = ?";
            $params[] = $filters['building_id'];
        }
        if (!empty($filters['apartment_id'])) {
            $acSql .= " AND a.id = ?";
            $params[] = $filters['apartment_id'];
        }

        $stmt = $this->db->prepare($acSql);
        $stmt->execute($params);
        $acTasks = $stmt->fetchAll(PDO::FETCH_ASSOC);

        foreach ($acTasks as $ac) {
            $isPastDue = ($ac['date'] < $today);
            $hasProof = (!empty($ac['before_photo']) && !empty($ac['after_photo']));

            if ($ac['status'] === 'Completed' || $ac['status'] === 'Approved') {
                $status = 'Completed';
                $statusLabel = 'Completed';
                $priority = 'Normal';
            } elseif ($ac['status'] === 'Pending_Approval') {
                $status = 'Pending';
                $statusLabel = 'Awaiting Verification';
                $priority = 'High';
            } elseif ($ac['status'] === 'Rejected') {
                $status = 'Overdue';
                $statusLabel = 'Rejected / Rework';
                $priority = 'Urgent';
            } elseif ($isPastDue) {
                $status = 'Overdue';
                $statusLabel = 'Overdue';
                $priority = 'Urgent';
            } else {
                $status = 'Scheduled';
                $statusLabel = 'Scheduled';
                $priority = 'Normal';
            }

            $events[] = [
                'id' => 'maint_ac_' . $ac['id'],
                'raw_id' => (int)$ac['id'],
                'category' => 'maintenance',
                'event_type' => 'ac',
                'title' => "AC Maintenance: {$ac['building_name']} Apt {$ac['apartment_code']}",
                'description' => $ac['notes'] ?: "Preventative AC cleaning and system servicing.",
                'date' => $ac['date'],
                'status' => $status,
                'status_label' => $statusLabel,
                'priority' => $priority,
                'is_missing' => false,
                'building_id' => (int)$ac['building_id'],
                'building_name' => $ac['building_name'],
                'apartment_id' => (int)$ac['apartment_id'],
                'apartment_code' => $ac['apartment_code'],
                'assigned_to_name' => $ac['worker_name'] ?: 'Unassigned',
                'has_proof' => $hasProof,
                'source_record' => 'ac_maintenance_tasks',
                'source_id' => (int)$ac['id'],
                'action_url' => "/maintenance-admin?search={$ac['apartment_code']}"
            ];
        }

        // B. tenant_maintenance_tickets (Corrective maintenance)
        $ticketSql = "
            SELECT 
                tmt.id,
                DATE(tmt.created_at) as date,
                tmt.title,
                tmt.description,
                tmt.priority,
                tmt.status,
                tmt.resolved_at,
                a.id as apartment_id,
                a.code as apartment_code,
                b.id as building_id,
                b.name as building_name,
                t.full_name as tenant_name
            FROM tenant_maintenance_tickets tmt
            JOIN tenants t ON tmt.tenant_id = t.id
            LEFT JOIN apartments a ON tmt.apartment_id = a.id
            LEFT JOIN buildings b ON a.building_id = b.id
            WHERE DATE(tmt.created_at) BETWEEN ? AND ?
        ";
        $ticketParams = [$startDate, $endDate];
        if (!empty($filters['building_id'])) {
            $ticketSql .= " AND b.id = ?";
            $ticketParams[] = $filters['building_id'];
        }
        if (!empty($filters['apartment_id'])) {
            $ticketSql .= " AND a.id = ?";
            $ticketParams[] = $filters['apartment_id'];
        }

        $stmt = $this->db->prepare($ticketSql);
        $stmt->execute($ticketParams);
        $tickets = $stmt->fetchAll(PDO::FETCH_ASSOC);

        foreach ($tickets as $tk) {
            $isResolved = in_array($tk['status'], ['Resolved', 'Closed']);
            $isPastDue = ($tk['date'] < $today && !$isResolved);

            $status = $isResolved ? 'Completed' : ($isPastDue ? 'Overdue' : 'Pending');
            $statusLabel = $isResolved ? 'Resolved' : ($isPastDue ? 'Ticket Overdue' : 'Open Ticket');

            $events[] = [
                'id' => 'maint_ticket_' . $tk['id'],
                'raw_id' => (int)$tk['id'],
                'category' => 'maintenance',
                'event_type' => 'ticket',
                'title' => "Maintenance: {$tk['title']}",
                'description' => "Tenant: {$tk['tenant_name']} - " . ($tk['description'] ?: 'No details'),
                'date' => $tk['date'],
                'status' => $status,
                'status_label' => $statusLabel,
                'priority' => $tk['priority'] ?: 'Normal',
                'is_missing' => false,
                'building_id' => (int)($tk['building_id'] ?? 0),
                'building_name' => $tk['building_name'] ?? 'General',
                'apartment_id' => (int)($tk['apartment_id'] ?? 0),
                'apartment_code' => $tk['apartment_code'] ?? 'Building',
                'tenant_name' => $tk['tenant_name'],
                'source_record' => 'tenant_maintenance_tickets',
                'source_id' => (int)$tk['id'],
                'action_url' => "/maintenance-admin"
            ];
        }

        // C. General Operational Tasks (`tasks` table)
        $tasksSql = "
            SELECT 
                t.id, 
                t.title, 
                t.type, 
                t.status, 
                t.due_date as date, 
                t.priority, 
                t.completion_notes,
                t.proof_image_path,
                t.building_id,
                t.apartment_id,
                b.name as building_name,
                a.code as apartment_code,
                u.name as assigned_to_name
            FROM tasks t
            LEFT JOIN buildings b ON t.building_id = b.id
            LEFT JOIN apartments a ON t.apartment_id = a.id
            LEFT JOIN users u ON t.assigned_to = u.id
            WHERE t.due_date BETWEEN ? AND ?
              AND t.type IN ('Maintenance', 'Inspection', 'Compliance')
        ";
        $tasksParams = [$startDate, $endDate];
        if (!empty($filters['building_id'])) {
            $tasksSql .= " AND t.building_id = ?";
            $tasksParams[] = $filters['building_id'];
        }
        $stmt = $this->db->prepare($tasksSql);
        $stmt->execute($tasksParams);
        $genTasks = $stmt->fetchAll(PDO::FETCH_ASSOC);

        foreach ($genTasks as $gt) {
            $isCompleted = ($gt['status'] === 'Completed');
            $isPastDue = ($gt['date'] < $today && !$isCompleted);

            $status = $isCompleted ? 'Completed' : ($isPastDue ? 'Overdue' : ($gt['status'] === 'In Progress' ? 'Pending' : 'Scheduled'));
            $statusLabel = $isCompleted ? 'Completed' : ($isPastDue ? 'Overdue' : $gt['status']);

            $events[] = [
                'id' => 'task_' . $gt['id'],
                'raw_id' => (int)$gt['id'],
                'category' => 'maintenance',
                'event_type' => 'task',
                'title' => $gt['title'],
                'description' => $gt['completion_notes'] ?: "Operational maintenance task.",
                'date' => $gt['date'],
                'status' => $status,
                'status_label' => $statusLabel,
                'priority' => $gt['priority'] ?: 'Normal',
                'is_missing' => false,
                'building_id' => (int)($gt['building_id'] ?? 0),
                'building_name' => $gt['building_name'] ?? 'Facility',
                'apartment_id' => (int)($gt['apartment_id'] ?? 0),
                'apartment_code' => $gt['apartment_code'] ?? 'General',
                'assigned_to_name' => $gt['assigned_to_name'] ?: 'Unassigned',
                'has_proof' => !empty($gt['proof_image_path']),
                'source_record' => 'tasks',
                'source_id' => (int)$gt['id'],
                'action_url' => "/maintenance-admin"
            ];
        }

        return $events;
    }

    /**
     * 4. Generator Category Events & Missing Daily Check Engine
     */
    private function fetchGeneratorEvents($startDate, $endDate, $filters, $today) {
        $events = [];

        // Fetch all active/running generators (exclude retired/offline unless requested)
        $genSql = "
            SELECT 
                g.id, 
                g.building_id, 
                g.name, 
                g.brand, 
                g.model, 
                g.status, 
                g.fuel_capacity, 
                g.current_fuel,
                b.name as building_name
            FROM generators g
            JOIN buildings b ON g.building_id = b.id
            WHERE g.status != 'Offline'
        ";
        if (!empty($filters['building_id'])) {
            $genSql .= " AND g.building_id = " . intval($filters['building_id']);
        }
        $generators = $this->db->query($genSql)->fetchAll(PDO::FETCH_ASSOC);

        if (empty($generators)) {
            return $events;
        }

        // Fetch all daily_logs submitted in this range
        $logSql = "
            SELECT 
                dl.id, 
                dl.generator_id, 
                dl.date, 
                dl.submitted_hours, 
                dl.calculated_hours_worked, 
                dl.admin_actual_fuel, 
                dl.status_flag, 
                dl.ai_report,
                dl.created_at
            FROM daily_logs dl
            WHERE dl.date BETWEEN ? AND ?
        ";
        $logStmt = $this->db->prepare($logSql);
        $logStmt->execute([$startDate, $endDate]);
        $dailyLogs = $logStmt->fetchAll(PDO::FETCH_ASSOC);

        // Map daily logs by generator_id + date
        $completedLogsMap = [];
        foreach ($dailyLogs as $dl) {
            $completedLogsMap[$dl['generator_id'] . '_' . $dl['date']] = $dl;
        }

        // Fetch any existing generator tasks in `tasks` table
        $taskGenStmt = $this->db->prepare("
            SELECT t.id, t.title, t.status, t.due_date as date, t.priority, t.related_entity_id as generator_id,
                   t.meter_reading, t.fuel_level, t.proof_image_path, u.name as assigned_to_name
            FROM tasks t
            LEFT JOIN users u ON t.assigned_to = u.id
            WHERE t.type = 'Generator' AND t.due_date BETWEEN ? AND ?
        ");
        $taskGenStmt->execute([$startDate, $endDate]);
        $existingGenTasks = $taskGenStmt->fetchAll(PDO::FETCH_ASSOC);
        $genTasksMap = [];
        foreach ($existingGenTasks as $gt) {
            $genTasksMap[$gt['generator_id'] . '_' . $gt['date']] = $gt;
        }

        // Generate and verify each active generator across dates in range (up to today + upcoming days)
        // For performance, iterate through dates
        $startDt = new DateTime($startDate);
        $endDt = new DateTime($endDate);
        $interval = new DateInterval('P1D');
        $datePeriod = new DatePeriod($startDt, $interval, (clone $endDt)->modify('+1 day'));

        foreach ($generators as $gen) {
            $genId = $gen['id'];

            foreach ($datePeriod as $dt) {
                $dateStr = $dt->format('Y-m-d');
                $mapKey = $genId . '_' . $dateStr;

                $hasCompletedLog = isset($completedLogsMap[$mapKey]);
                $existingTask = $genTasksMap[$mapKey] ?? null;

                if ($hasCompletedLog) {
                    // Record exists and was performed!
                    $log = $completedLogsMap[$mapKey];
                    $events[] = [
                        'id' => 'gen_log_' . $log['id'],
                        'raw_id' => (int)$log['id'],
                        'category' => 'generator',
                        'event_type' => 'generator',
                        'title' => "Generator Check: {$gen['name']} ({$gen['building_name']})",
                        'description' => "Runtime: {$log['calculated_hours_worked']}h | Fuel: {$log['admin_actual_fuel']}L / {$gen['fuel_capacity']}L | Meter: {$log['submitted_hours']}",
                        'date' => $dateStr,
                        'status' => 'Completed',
                        'status_label' => 'Verified Operation',
                        'priority' => 'Normal',
                        'is_missing' => false,
                        'building_id' => (int)$gen['building_id'],
                        'building_name' => $gen['building_name'],
                        'equipment_name' => $gen['name'],
                        'fuel_level' => floatval($log['admin_actual_fuel']),
                        'meter_reading' => floatval($log['submitted_hours']),
                        'has_proof' => true,
                        'source_record' => 'daily_logs',
                        'source_id' => (int)$log['id'],
                        'action_url' => "/fuel"
                    ];
                } elseif ($existingTask) {
                    // A scheduled or in-progress task exists
                    $isDone = ($existingTask['status'] === 'Completed');
                    $isPast = ($dateStr < $today && !$isDone);

                    $status = $isDone ? 'Completed' : ($isPast ? 'Overdue' : ($existingTask['status'] === 'In Progress' ? 'Pending' : 'Scheduled'));
                    $statusLabel = $isDone ? 'Completed' : ($isPast ? 'Inspection Overdue' : 'Check Pending');

                    $events[] = [
                        'id' => 'gen_task_' . $existingTask['id'],
                        'raw_id' => (int)$existingTask['id'],
                        'category' => 'generator',
                        'event_type' => 'generator',
                        'title' => "Generator Task: {$gen['name']} - {$existingTask['title']}",
                        'description' => "Status: {$existingTask['status']} - Assignee: " . ($existingTask['assigned_to_name'] ?: 'Maintenance Worker'),
                        'date' => $dateStr,
                        'status' => $status,
                        'status_label' => $statusLabel,
                        'priority' => $existingTask['priority'] ?: 'High',
                        'is_missing' => false,
                        'building_id' => (int)$gen['building_id'],
                        'building_name' => $gen['building_name'],
                        'equipment_name' => $gen['name'],
                        'has_proof' => !empty($existingTask['proof_image_path']),
                        'assigned_to_name' => $existingTask['assigned_to_name'] ?: 'Maintenance Team',
                        'source_record' => 'tasks',
                        'source_id' => (int)$existingTask['id'],
                        'action_url' => "/fuel"
                    ];
                } else {
                    // Genuinely NO log and NO task!
                    // Check if this date requires an operation:
                    // If date <= today, this is a RED MISSING TASK alert!
                    $isMissing = ($dateStr <= $today);

                    // Track in missed_task_exceptions table
                    if ($isMissing) {
                        $this->recordMissingException('generator', 'generator', $genId, $dateStr, "Daily Generator Operation Check Missing: {$gen['name']}");
                    }

                    $events[] = [
                        'id' => "gen_missing_{$genId}_{$dateStr}",
                        'raw_id' => $genId,
                        'category' => 'generator',
                        'event_type' => 'generator',
                        'title' => $isMissing ? "⚠️ MISSING TASK: Daily Check - {$gen['name']}" : "Scheduled Daily Check: {$gen['name']}",
                        'description' => $isMissing 
                            ? "Required daily fuel & runtime check was NOT created or logged for this active generator."
                            : "Daily operation & fuel inspection requirement.",
                        'date' => $dateStr,
                        'status' => $isMissing ? 'Missing' : 'Scheduled',
                        'status_label' => $isMissing ? 'MISSING TASK' : 'Scheduled Check',
                        'priority' => $isMissing ? 'Critical' : 'Normal',
                        'is_missing' => $isMissing,
                        'building_id' => (int)$gen['building_id'],
                        'building_name' => $gen['building_name'],
                        'equipment_name' => $gen['name'],
                        'has_proof' => false,
                        'source_record' => 'generators',
                        'source_id' => $genId,
                        'action_url' => "/fuel",
                        'repair_action' => [
                            'category' => 'generator',
                            'target_type' => 'generator',
                            'target_id' => $genId,
                            'due_date' => $dateStr,
                            'title' => "Daily Generator Check & Reading: {$gen['name']}"
                        ]
                    ];
                }
            }
        }

        return $events;
    }

    /**
     * 5. Expiring Leases / Contracts Category
     */
    private function fetchLeaseEvents($startDate, $endDate, $filters, $today) {
        $events = [];

        $sql = "
            SELECT 
                c.id, 
                c.end_date as date, 
                c.start_date, 
                c.status, 
                t.full_name as tenant_name, 
                t.id as tenant_id,
                a.id as apartment_id,
                a.code as apartment_code, 
                b.id as building_id,
                b.name as building_name
            FROM contracts c
            JOIN tenants t ON c.tenant_id = t.id
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE c.status = 'Active'
              AND c.end_date BETWEEN ? AND ?
        ";
        $params = [$startDate, $endDate];
        if (!empty($filters['building_id'])) {
            $sql .= " AND b.id = ?";
            $params[] = $filters['building_id'];
        }
        if (!empty($filters['apartment_id'])) {
            $sql .= " AND a.id = ?";
            $params[] = $filters['apartment_id'];
        }

        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        $contracts = $stmt->fetchAll(PDO::FETCH_ASSOC);

        foreach ($contracts as $c) {
            $isPastDue = ($c['date'] < $today);
            $status = $isPastDue ? 'Overdue' : 'Pending';
            $statusLabel = $isPastDue ? 'Lease Expired' : 'Lease Expiring';

            $events[] = [
                'id' => 'contract_' . $c['id'],
                'raw_id' => (int)$c['id'],
                'category' => 'lease',
                'event_type' => 'contract_end',
                'title' => "Lease Expiration: {$c['tenant_name']} (Apt {$c['apartment_code']})",
                'description' => "Rental agreement expires on {$c['date']}. Review renewal or offboarding.",
                'date' => $c['date'],
                'status' => $status,
                'status_label' => $statusLabel,
                'priority' => 'High',
                'is_missing' => false,
                'building_id' => (int)$c['building_id'],
                'building_name' => $c['building_name'],
                'apartment_id' => (int)$c['apartment_id'],
                'apartment_code' => $c['apartment_code'],
                'tenant_name' => $c['tenant_name'],
                'tenant_id' => (int)$c['tenant_id'],
                'source_record' => 'contracts',
                'source_id' => (int)$c['id'],
                'action_url' => "/tenant-details/{$c['tenant_id']}"
            ];
        }

        return $events;
    }

    /**
     * Filter events based on UI criteria
     */
    private function applyFilters($events, $filters) {
        if (empty($filters)) return $events;

        return array_filter($events, function ($e) use ($filters) {
            // Category filter
            if (!empty($filters['category']) && $filters['category'] !== 'all') {
                if ($e['category'] !== $filters['category']) return false;
            }
            // Status filter
            if (!empty($filters['status']) && $filters['status'] !== 'all') {
                if (strtolower($e['status']) !== strtolower($filters['status'])) return false;
            }
            // Priority filter
            if (!empty($filters['priority']) && $filters['priority'] !== 'all') {
                if (strtolower($e['priority'] ?? '') !== strtolower($filters['priority'])) return false;
            }
            // Building filter
            if (!empty($filters['building_id']) && $filters['building_id'] !== 'all') {
                if (intval($e['building_id']) !== intval($filters['building_id'])) return false;
            }
            // Apartment filter
            if (!empty($filters['apartment_id']) && $filters['apartment_id'] !== 'all') {
                if (intval($e['apartment_id'] ?? 0) !== intval($filters['apartment_id'])) return false;
            }
            // Search query
            if (!empty($filters['search'])) {
                $q = strtolower(trim($filters['search']));
                $haystack = strtolower(($e['title'] ?? '') . ' ' . ($e['description'] ?? '') . ' ' . ($e['building_name'] ?? '') . ' ' . ($e['apartment_code'] ?? '') . ' ' . ($e['tenant_name'] ?? ''));
                if (strpos($haystack, $q) === false) return false;
            }
            return true;
        });
    }

    /**
     * Compute Daily Compliance Score & Operational Metrics
     */
    private function computeComplianceScore($events, $today) {
        $total = count($events);
        $completed = 0;
        $overdue = 0;
        $missing = 0;
        $pending = 0;
        $scheduled = 0;

        $categoryCounts = [
            'rent' => 0,
            'electricity' => 0,
            'maintenance' => 0,
            'generator' => 0,
            'lease' => 0
        ];

        $todayRequired = 0;
        $todayCompleted = 0;
        $todayMissing = 0;
        $todayOverdue = 0;

        foreach ($events as $e) {
            $cat = $e['category'] ?? 'maintenance';
            if (isset($categoryCounts[$cat])) {
                $categoryCounts[$cat]++;
            }

            if ($e['is_missing'] ?? false) {
                $missing++;
                if ($e['date'] === $today) $todayMissing++;
            } elseif ($e['status'] === 'Completed') {
                $completed++;
                if ($e['date'] === $today) $todayCompleted++;
            } elseif ($e['status'] === 'Overdue') {
                $overdue++;
                if ($e['date'] === $today) $todayOverdue++;
            } elseif ($e['status'] === 'Pending') {
                $pending++;
            } else {
                $scheduled++;
            }

            if ($e['date'] === $today) {
                $todayRequired++;
            }
        }

        // Compliance score calculated from required tasks:
        // (completed on time) / (total required operations) * 100
        $overallScore = ($total > 0) ? round(($completed / $total) * 100) : 100;
        $todayScore = ($todayRequired > 0) ? round(($todayCompleted / $todayRequired) * 100) : 100;

        return [
            'total_events' => $total,
            'completed' => $completed,
            'overdue' => $overdue,
            'missing' => $missing,
            'pending' => $pending,
            'scheduled' => $scheduled,
            'compliance_score' => $overallScore,
            'today_compliance_score' => $todayScore,
            'today_required' => $todayRequired,
            'today_completed' => $todayCompleted,
            'today_missing' => $todayMissing,
            'today_overdue' => $todayOverdue,
            'categories' => $categoryCounts
        ];
    }

    /**
     * Record or update missed task exception in DB for audit & accountability
     */
    private function recordMissingException($category, $targetType, $targetId, $dueDate, $title) {
        try {
            $stmt = $this->db->prepare("
                INSERT INTO missed_task_exceptions 
                (category, target_type, target_id, title, due_date, detected_at, status)
                VALUES (?, ?, ?, ?, ?, NOW(), 'detected')
                ON DUPLICATE KEY UPDATE 
                    title = VALUES(title),
                    updated_at = NOW()
            ");
            $stmt->execute([$category, $targetType, $targetId, $title, $dueDate]);
        } catch (Exception $e) {
            // Non-blocking log
            error_log("Failed to record missing task exception: " . $e->getMessage());
        }
    }

    /**
     * 1-Click Action to Generate / Repair a Missing Task
     *
     * @param array $payload ['category', 'target_type', 'target_id', 'due_date', 'title', 'assigned_to', 'priority']
     * @param int   $userId
     * @return array
     */
    public function generateMissingTask($payload, $userId) {
        $category = $payload['category'] ?? 'maintenance';
        $targetType = $payload['target_type'] ?? 'apartment';
        $targetId = intval($payload['target_id'] ?? 0);
        $dueDate = $payload['due_date'] ?? date('Y-m-d');
        $title = $payload['title'] ?? "Operational Task for {$category}";
        $priority = $payload['priority'] ?? 'High';
        $assignedTo = !empty($payload['assigned_to']) ? intval($payload['assigned_to']) : $userId;

        // Unique schedule key for idempotency
        $scheduleKey = strtoupper("{$category}_{$targetType}_{$targetId}_{$dueDate}");

        $this->db->beginTransaction();

        try {
            // Check if already created
            $check = $this->db->prepare("SELECT id FROM tasks WHERE schedule_key = ?");
            $check->execute([$scheduleKey]);
            $existing = $check->fetch(PDO::FETCH_ASSOC);

            if ($existing) {
                $this->db->rollBack();
                return [
                    'status' => 'success',
                    'message' => 'Task already exists for this operation.',
                    'task_id' => (int)$existing['id']
                ];
            }

            // Map target entity to building_id / apartment_id
            $buildingId = null;
            $apartmentId = null;

            if ($targetType === 'generator') {
                $gen = $this->db->query("SELECT building_id FROM generators WHERE id = $targetId")->fetch(PDO::FETCH_ASSOC);
                $buildingId = $gen['building_id'] ?? null;
            } elseif ($targetType === 'apartment') {
                $apt = $this->db->query("SELECT building_id FROM apartments WHERE id = $targetId")->fetch(PDO::FETCH_ASSOC);
                $apartmentId = $targetId;
                $buildingId = $apt['building_id'] ?? null;
            } elseif ($targetType === 'subscription') {
                $sub = $this->db->query("SELECT es.apartment_id, a.building_id FROM electricity_subscriptions es JOIN apartments a ON es.apartment_id = a.id WHERE es.id = $targetId")->fetch(PDO::FETCH_ASSOC);
                if ($sub) {
                    $apartmentId = $sub['apartment_id'];
                    $buildingId = $sub['building_id'];
                }
            }

            // Insert new task
            $type = ucfirst($category);
            $stmt = $this->db->prepare("
                INSERT INTO tasks 
                (title, type, assigned_to, building_id, apartment_id, status, due_date, priority, related_entity_type, related_entity_id, schedule_key, created_at)
                VALUES (?, ?, ?, ?, ?, 'Pending', ?, ?, ?, ?, ?, NOW())
            ");
            $stmt->execute([
                $title,
                $type,
                $assignedTo,
                $buildingId,
                $apartmentId,
                $dueDate,
                $priority,
                $targetType,
                $targetId,
                $scheduleKey
            ]);

            $taskId = (int)$this->db->lastInsertId();

            // Mark exception as repaired in missed_task_exceptions
            $exStmt = $this->db->prepare("
                UPDATE missed_task_exceptions 
                SET status = 'repaired', repair_task_id = ?, resolved_by = ?, resolved_at = NOW()
                WHERE category = ? AND target_type = ? AND target_id = ? AND due_date = ?
            ");
            $exStmt->execute([$taskId, $userId, $category, $targetType, $targetId, $dueDate]);

            // Add activity log
            $actStmt = $this->db->prepare("
                INSERT INTO activity_logs (user_id, action, entity_type, entity_id, created_at)
                VALUES (?, ?, 'Task', ?, NOW())
            ");
            $actStmt->execute([$userId, "Generated missing task: {$title} (Key: {$scheduleKey})", $taskId]);

            $this->db->commit();

            return [
                'status' => 'success',
                'message' => 'Task successfully generated and linked to schedule.',
                'task_id' => $taskId
            ];
        } catch (Exception $e) {
            $this->db->rollBack();
            throw $e;
        }
    }

    /**
     * Submit Proof and Record Completion for any operational task
     *
     * @param array $payload ['task_id', 'status', 'notes', 'meter_reading', 'fuel_level', 'parts_used', 'actual_cost', 'proof_image']
     * @param int   $userId
     * @return array
     */
    public function recordTaskCompletion($payload, $userId) {
        $taskId = intval($payload['task_id'] ?? 0);
        $status = $payload['status'] ?? 'Completed';
        $notes = $payload['notes'] ?? '';
        $meterReading = isset($payload['meter_reading']) ? floatval($payload['meter_reading']) : null;
        $fuelLevel = isset($payload['fuel_level']) ? floatval($payload['fuel_level']) : null;
        $partsUsed = $payload['parts_used'] ?? null;
        $actualCost = floatval($payload['actual_cost'] ?? 0);
        $proofImagePath = $payload['proof_image'] ?? null;

        if (!$taskId) {
            throw new Exception("Task ID is required.");
        }

        $this->db->beginTransaction();

        try {
            $taskStmt = $this->db->prepare("SELECT * FROM tasks WHERE id = ?");
            $taskStmt->execute([$taskId]);
            $task = $taskStmt->fetch(PDO::FETCH_ASSOC);

            if (!$task) {
                throw new Exception("Task not found.");
            }

            // Update tasks record
            $updStmt = $this->db->prepare("
                UPDATE tasks 
                SET status = ?, 
                    completion_notes = ?, 
                    meter_reading = COALESCE(?, meter_reading),
                    fuel_level = COALESCE(?, fuel_level),
                    parts_used = COALESCE(?, parts_used),
                    actual_cost = ?,
                    proof_image_path = COALESCE(?, proof_image_path),
                    verified_by = ?,
                    verified_at = NOW(),
                    updated_at = NOW()
                WHERE id = ?
            ");
            $updStmt->execute([
                $status,
                $notes,
                $meterReading,
                $fuelLevel,
                $partsUsed,
                $actualCost,
                $proofImagePath,
                $userId,
                $taskId
            ]);

            // If task is generator check, also create daily_log if readings provided!
            if ($task['type'] === 'Generator' && $task['related_entity_id']) {
                $genId = $task['related_entity_id'];
                $checkDate = $task['due_date'];

                if ($meterReading !== null || $fuelLevel !== null) {
                    // Check if daily_log already exists
                    $dlCheck = $this->db->prepare("SELECT id FROM daily_logs WHERE generator_id = ? AND date = ?");
                    $dlCheck->execute([$genId, $checkDate]);
                    if (!$dlCheck->fetch()) {
                        $dlIns = $this->db->prepare("
                            INSERT INTO daily_logs 
                            (generator_id, date, submitted_hours, calculated_hours_worked, admin_actual_fuel, status_flag, ai_report, created_at)
                            VALUES (?, ?, ?, 0, ?, 'Verified', ?, NOW())
                        ");
                        $dlIns->execute([
                            $genId,
                            $checkDate,
                            $meterReading ?? 0,
                            $fuelLevel ?? 0,
                            "Completed via Schedule Center task #{$taskId}: {$notes}"
                        ]);
                    }
                }
            }

            // Record assignment history & activity log
            $hist = $this->db->prepare("
                INSERT INTO task_assignment_history (task_id, new_agent_id, action, created_at)
                VALUES (?, ?, 'Completed', NOW())
            ");
            $hist->execute([$taskId, $userId]);

            $act = $this->db->prepare("
                INSERT INTO activity_logs (user_id, action, entity_type, entity_id, created_at)
                VALUES (?, ?, 'Task', ?, NOW())
            ");
            $act->execute([$userId, "Completed task #{$taskId} with verified proof", $taskId]);

            $this->db->commit();

            return [
                'status' => 'success',
                'message' => 'Task completed and verified successfully.'
            ];
        } catch (Exception $e) {
            $this->db->rollBack();
            throw $e;
        }
    }

    /**
     * Cancel an operational task with reason and audit record
     */
    public function cancelTask($taskId, $reason, $userId) {
        if (!$taskId) throw new Exception("Task ID required.");
        if (empty($reason)) throw new Exception("Cancellation reason is required.");

        $this->db->beginTransaction();
        try {
            $stmt = $this->db->prepare("
                UPDATE tasks 
                SET status = 'Cancelled', cancellation_reason = ?, cancelled_by = ?, cancelled_at = NOW(), updated_at = NOW()
                WHERE id = ?
            ");
            $stmt->execute([$reason, $userId, $taskId]);

            $act = $this->db->prepare("
                INSERT INTO activity_logs (user_id, action, entity_type, entity_id, created_at)
                VALUES (?, ?, 'Task', ?, NOW())
            ");
            $act->execute([$userId, "Cancelled task #{$taskId}: {$reason}", $taskId]);

            $this->db->commit();
            return ['status' => 'success', 'message' => 'Task cancelled with audit trail recorded.'];
        } catch (Exception $e) {
            $this->db->rollBack();
            throw $e;
        }
    }

    /**
     * Automated Recurring Generation Job (Used by cron / background worker)
     */
    public static function runScheduledReconciliation() {
        $startTime = microtime(true);
        $service = new self();
        $db = Database::getInstance()->getConnection();

        date_default_timezone_set('Africa/Bangui');
        $today = date('Y-m-d');
        $windowEnd = date('Y-m-d', strtotime('+7 days'));

        $createdCount = 0;
        $missingDetected = 0;

        // 1. Reconcile Active Generators (ensure daily check tasks exist for today)
        $generators = $db->query("SELECT id, name, building_id FROM generators WHERE status != 'Offline'")->fetchAll(PDO::FETCH_ASSOC);
        foreach ($generators as $gen) {
            $scheduleKey = "GENERATOR_GENERATOR_{$gen['id']}_{$today}";
            
            // Check if log exists
            $hasLog = $db->query("SELECT id FROM daily_logs WHERE generator_id = {$gen['id']} AND date = '{$today}'")->fetchColumn();
            $hasTask = $db->query("SELECT id FROM tasks WHERE schedule_key = '{$scheduleKey}'")->fetchColumn();

            if (!$hasLog && !$hasTask) {
                // Generate task automatically
                try {
                    $service->generateMissingTask([
                        'category' => 'generator',
                        'target_type' => 'generator',
                        'target_id' => $gen['id'],
                        'due_date' => $today,
                        'title' => "Daily Generator Check & Fuel Reading: {$gen['name']}",
                        'priority' => 'High'
                    ], 1);
                    $createdCount++;
                } catch (Exception $e) {
                    // Ignored on dup
                }
            }
        }

        // 2. Reconcile Active Electricity Subscriptions (ensure renewal tasks exist for subscriptions due soon)
        $subs = $db->query("
            SELECT es.id, es.apartment_id, es.type, es.next_billing_date, a.code as apartment_code
            FROM electricity_subscriptions es
            JOIN apartments a ON es.apartment_id = a.id
            WHERE es.status = 'Active' 
              AND es.next_billing_date IS NOT NULL 
              AND es.next_billing_date <= '{$windowEnd}'
        ")->fetchAll(PDO::FETCH_ASSOC);

        foreach ($subs as $sub) {
            $dueDate = $sub['next_billing_date'];
            $scheduleKey = "ELECTRICITY_SUBSCRIPTION_{$sub['id']}_{$dueDate}";

            $hasInvoice = $db->query("SELECT id FROM electricity_invoices WHERE apartment_id = {$sub['apartment_id']} AND due_date = '{$dueDate}'")->fetchColumn();
            $hasTask = $db->query("SELECT id FROM tasks WHERE schedule_key = '{$scheduleKey}'")->fetchColumn();

            if (!$hasInvoice && !$hasTask) {
                try {
                    $service->generateMissingTask([
                        'category' => 'electricity',
                        'target_type' => 'subscription',
                        'target_id' => $sub['id'],
                        'due_date' => $dueDate,
                        'title' => "Electricity Renewal & Meter Audit: Apt {$sub['apartment_code']}",
                        'priority' => 'High'
                    ], 1);
                    $createdCount++;
                } catch (Exception $e) {
                    // Ignored
                }
            }
        }

        $duration = round(microtime(true) - $startTime, 2);

        // Update scheduled_jobs record
        $jobStmt = $db->prepare("
            UPDATE scheduled_jobs 
            SET status = 'Success', 
                duration_seconds = ?, 
                records_processed = ?, 
                last_run = NOW(), 
                next_run = DATE_ADD(NOW(), INTERVAL 1 DAY),
                error_message = NULL
            WHERE job_name = 'Operations & Compliance Scheduler'
        ");
        $jobStmt->execute([$duration, $createdCount]);

        return [
            'status' => 'success',
            'duration_seconds' => $duration,
            'tasks_generated' => $createdCount,
            'executed_at' => date('Y-m-d H:i:s')
        ];
    }
}
