<?php
class NotificationsController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    private function uid($user) {
        return (int)($user['user_id'] ?? $user['id'] ?? 0);
    }

    /** GET /api/notifications?limit=30&before_id=123  - paginated history (read + unread), newest first. */
    public function index() {
        $user = AuthMiddleware::requireLogin();
        $userId = $this->uid($user);
        $limit = max(1, min(50, (int)($_GET['limit'] ?? 30)));
        $before = (int)($_GET['before_id'] ?? 0);
        $out = ['items' => [], 'has_more' => false, 'next_before_id' => null, 'unread_count' => 0];
        if (!$userId) { echo json_encode($out); return; }

        try {
            $sql = "SELECT id, title, message, type, related_id, route, is_read, created_at
                    FROM notifications WHERE user_id = ?" . ($before > 0 ? " AND id < " . $before : "") . "
                    ORDER BY id DESC LIMIT " . ($limit + 1);
            $stmt = $this->db->prepare($sql);
            $stmt->execute([$userId]);
            $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
            if (count($rows) > $limit) { $out['has_more'] = true; array_pop($rows); }
            $role = strtolower($user['role'] ?? '');
            foreach ($rows as &$r) {
                if (empty($r['route'])) $r['route'] = PushNotificationService::routeFor($r['type'] ?? '', $role);
                $r['is_read'] = (int)$r['is_read'];
            }
            unset($r);
            $out['items'] = $rows;
            $out['next_before_id'] = $rows ? (int)end($rows)['id'] : null;
            $out['unread_count'] = $this->countUnread($userId);
        } catch (\Throwable $e) {
            // route/related_id columns not migrated yet: fall back to the legacy column set
            try {
                $stmt = $this->db->prepare("SELECT id, title, message, type, is_read, created_at FROM notifications WHERE user_id = ? ORDER BY id DESC LIMIT " . $limit);
                $stmt->execute([$userId]);
                $out['items'] = $stmt->fetchAll(PDO::FETCH_ASSOC);
                $out['unread_count'] = $this->countUnread($userId);
            } catch (\Throwable $e2) {}
        }
        echo json_encode($out);
    }

    private function countUnread(int $userId): int {
        $s = $this->db->prepare("SELECT COUNT(*) FROM notifications WHERE user_id = ? AND is_read = 0");
        $s->execute([$userId]);
        return (int)$s->fetchColumn();
    }

    /** GET /api/notifications/unread-count  - one indexed COUNT; safe to call often. */
    public function unreadCount() {
        $user = AuthMiddleware::requireLogin();
        $userId = $this->uid($user);
        $n = 0;
        if ($userId) { try { $n = $this->countUnread($userId); } catch (\Throwable $e) {} }
        echo json_encode(['unread_count' => $n]);
    }

    /** GET /api/notifications/unread  - legacy: only real unread rows (no live aggregation). */
    public function getUnread() {
        $user = AuthMiddleware::requireLogin();
        $userId = $this->uid($user);
        if (!$userId) { echo json_encode([]); return; }
        try {
            $stmt = $this->db->prepare("SELECT id, title, message, type, is_read, created_at FROM notifications
                                        WHERE user_id = ? AND is_read = 0 ORDER BY id DESC LIMIT 50");
            $stmt->execute([$userId]);
            echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
        } catch (\Throwable $e) { echo json_encode([]); }
    }

    /** POST /api/notifications/read-all */
    public function markAllRead() {
        $user = AuthMiddleware::requireLogin();
        $userId = $this->uid($user);
        if ($userId) {
            try {
                $this->db->prepare("UPDATE notifications SET is_read = 1, read_at = NOW() WHERE user_id = ? AND is_read = 0")->execute([$userId]);
            } catch (\Throwable $e) {
                try { $this->db->prepare("UPDATE notifications SET is_read = 1 WHERE user_id = ? AND is_read = 0")->execute([$userId]); } catch (\Throwable $e2) {}
            }
        }
        echo json_encode(['success' => true, 'unread_count' => 0]);
    }

    /**
     * GET /api/notifications/pending-actions
     * Live "to-do" aggregation per role (open tickets, pending approvals, unpaid invoices...).
     * Heavier than the endpoints above: call it only when the Notification Center is opened, never in a poll loop.
     */
    public function pendingActions() {
        $user = AuthMiddleware::requireLogin();
        $user_id = $this->uid($user);
        $role = strtolower($user['role'] ?? '');

        if (!$user_id) {
            echo json_encode([]);
            return;
        }

        $results = [];
        // 2. Live operational alerts for Admin / Manager (Generator, Maintenance, Purchases, Meter Readings)
        if ($role === 'admin' || $role === 'manager') {
            // 2a. Pending Generator Daily Reports (e.g., "Ali submitted Generator Report — waiting for your response")
            try {
                $stmt = $this->db->query("
                    SELECT r.id, r.date, r.meter_hours, r.current_meter_hours, r.current_kwh, r.running_hours, r.fuel_added, r.notes, r.submitted_at, r.created_at,
                           g.name as generator_name, b.name as building_name, u.name as submitter_name
                    FROM generator_daily_reports r
                    JOIN generators g ON r.generator_id = g.id
                    JOIN buildings b ON g.building_id = b.id
                    LEFT JOIN users u ON r.submitted_by = u.id
                    WHERE r.status = 'Pending Verification'
                    ORDER BY r.date DESC, r.id DESC
                    LIMIT 20
                ");
                foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $gr) {
                    $agName = $gr['submitter_name'] ?: 'Field Agent';
                    $genName = $gr['generator_name'] ?: 'Generator';
                    $bld = $gr['building_name'] ?: 'Building';
                    $meter = $gr['current_meter_hours'] ?: ($gr['meter_hours'] ?: ($gr['current_kwh'] ?: 0));
                    $runHrs = $gr['running_hours'] ?: 0;
                    $fuel = $gr['fuel_added'] ?: 0;
                    $notes = $gr['notes'] ? "\nNotes: {$gr['notes']}" : "";
                    $results[] = [
                        'id' => 'gen_rep_' . $gr['id'],
                        'title' => "{$agName} submitted Generator Report — waiting for your response",
                        'message' => "{$agName} has submitted a generator reading for {$genName} ({$bld}) — waiting for your response.\nWhat is it: Generator Daily Report • Meter: {$meter} hrs (+{$runHrs} hrs) • Fuel Added: {$fuel}L{$notes}",
                        'type' => 'generator_report',
                        'is_read' => 0,
                        'created_at' => $gr['submitted_at'] ?? $gr['created_at'] ?? date('Y-m-d H:i:s'),
                    ];
                }
            } catch (\Throwable $e) {}

            // 2b. Submitted / Pending AC Maintenance Tasks (e.g., "Milad completed AC Task — waiting for your response")
            try {
                $stmt = $this->db->query("
                    SELECT mt.id, mt.status, mt.scheduled_date, mt.submission_date, mt.notes,
                           a.code as apartment_code, b.name as building_name,
                           u.name as worker_name, tn.full_name as tenant_name
                    FROM ac_maintenance_tasks mt
                    LEFT JOIN apartments a ON mt.apartment_id = a.id
                    LEFT JOIN buildings b ON a.building_id = b.id
                    LEFT JOIN users u ON mt.worker_id = u.id
                    LEFT JOIN contracts c ON c.apartment_id = a.id AND c.status IN ('Active', 'Approved')
                    LEFT JOIN tenants tn ON c.tenant_id = tn.id
                    WHERE mt.status IN ('Pending_Approval', 'Pending Approval', 'Submitted', 'Pending')
                    ORDER BY mt.id DESC
                    LIMIT 20
                ");
                foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $ac) {
                    $wName = $ac['worker_name'] ?: 'Maintenance Worker';
                    $bld = $ac['building_name'] ?: 'Building';
                    $apt = $ac['apartment_code'] ?: '';
                    $tName = $ac['tenant_name'] ? " (Tenant: {$ac['tenant_name']})" : "";
                    $isSubmitted = stripos($ac['status'], 'Approval') !== false || stripos($ac['status'], 'Submit') !== false;
                    $results[] = [
                        'id' => 'ac_' . $ac['id'] . '_' . $ac['status'],
                        'title' => $isSubmitted
                            ? "{$wName} completed AC Task — waiting for your response"
                            : "AC Task assigned to {$wName} ({$bld} • Apt {$apt})",
                        'message' => $isSubmitted
                            ? "{$wName} has completed the AC maintenance task for {$bld} • Apt {$apt}{$tName} — waiting for your response.\nWhat is it: AC Maintenance Submission" . ($ac['notes'] ? " — {$ac['notes']}" : "")
                            : "AC maintenance task at {$bld} • Apt {$apt}{$tName} is assigned to {$wName} (Status: {$ac['status']}).",
                        'type' => 'maintenance_ac',
                        'is_read' => 0,
                        'created_at' => $ac['submission_date'] ?? $ac['scheduled_date'] ?? date('Y-m-d H:i:s'),
                    ];
                }
            } catch (\Throwable $e) {}

            // 2c. Open / In-Progress / Submitted / Resolved Tenant Maintenance Tickets (with Tenant Name & Worker Name)
            try {
                $stmt = $this->db->query("
                    SELECT t.id, t.title, t.description, t.worker_notes, t.category, t.priority, t.status, t.created_at, t.resolved_at,
                           a.code as apartment_code, b.name as building_name,
                           tn.full_name as tenant_name, tn.phone as tenant_phone,
                           u.name as worker_name
                    FROM tenant_maintenance_tickets t
                    LEFT JOIN apartments a ON t.apartment_id = a.id
                    LEFT JOIN buildings b ON a.building_id = b.id
                    LEFT JOIN tenants tn ON t.tenant_id = tn.id
                    LEFT JOIN users u ON t.worker_id = u.id
                    WHERE t.status IN ('Open', 'In Progress', 'Submitted', 'Resolved')
                    ORDER BY COALESCE(t.resolved_at, t.created_at) DESC
                    LIMIT 20
                ");
                foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $tk) {
                    $tName = $tk['tenant_name'] ?: 'Tenant';
                    $wName = $tk['worker_name'] ?: '';
                    $bld = $tk['building_name'] ?: 'Building';
                    $apt = $tk['apartment_code'] ?: '';
                    $issue = $tk['title'] ?: ($tk['category'] ?: 'Repair');
                    $desc = $tk['description'] ? " — {$tk['description']}" : "";
                    $st = $tk['status'] ?? 'Open';

                    if ($st === 'Resolved' || $st === 'Submitted') {
                        $actor = $wName ?: 'Maintenance Worker';
                        $wNotes = $tk['worker_notes'] ? " • Worker Notes: {$tk['worker_notes']}" : $desc;
                        $results[] = [
                            'id' => 'ticket_' . $tk['id'] . '_' . str_replace(' ', '', $st),
                            'title' => "{$actor} completed Task ({$bld} Apt {$apt}) — waiting for your response",
                            'message' => "{$actor} has completed the maintenance task for Tenant {$tName} ({$bld} • Apt {$apt}) — waiting for your response.\nWhat is it: {$issue}{$wNotes}",
                            'type' => 'tenant_maintenance',
                            'is_read' => 0,
                            'created_at' => $tk['resolved_at'] ?? $tk['created_at'] ?? date('Y-m-d H:i:s'),
                        ];
                    } else {
                        $assignedStr = $wName ? " (Assigned to {$wName})" : "";
                        $results[] = [
                            'id' => 'ticket_' . $tk['id'] . '_' . str_replace(' ', '', $st),
                            'title' => "{$tName} requested Maintenance — waiting for your response",
                            'message' => "{$tName}" . ($tk['tenant_phone'] ? " ({$tk['tenant_phone']})" : "") . " submitted a maintenance request for {$bld} • Apt {$apt}{$assignedStr} — waiting for your response.\nWhat is it: {$issue}{$desc}",
                            'type' => 'tenant_maintenance',
                            'is_read' => 0,
                            'created_at' => $tk['created_at'] ?? date('Y-m-d H:i:s'),
                        ];
                    }
                }
            } catch (\Throwable $e) {}

            // 2d. Pending Agent Apartment Purchases (e.g., "Ali submitted Purchase — waiting for your response")
            try {
                $stmt = $this->db->query("
                    SELECT c.id, c.supplier_name, c.amount, c.notes, c.date,
                           a.code as apartment_code, b.name as building_name,
                           u.name as agent_name
                    FROM apartment_cost_deployments c
                    JOIN apartments a ON c.apartment_id = a.id
                    JOIN buildings b ON a.building_id = b.id
                    LEFT JOIN users u ON c.submitted_by = u.id
                    WHERE c.status = 'Pending'
                    ORDER BY c.id DESC
                    LIMIT 15
                ");
                foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $p) {
                    $agName = $p['agent_name'] ?: 'Field Agent';
                    $amt = number_format((float)$p['amount']);
                    $bld = $p['building_name'] ?? 'Building';
                    $apt = $p['apartment_code'] ?? '';
                    $sup = $p['supplier_name'] ?? 'Supplier';
                    $results[] = [
                        'id' => 'purch_' . $p['id'],
                        'title' => "{$agName} submitted Purchase (CFA {$amt}) — waiting for your response",
                        'message' => "{$agName} has submitted a purchase of CFA {$amt} from {$sup} for {$bld} • Apt {$apt} — waiting for your response.\nWhat is it: Apartment Purchase" . ($p['notes'] ? " — {$p['notes']}" : ""),
                        'type' => 'task_purchase',
                        'is_read' => 0,
                        'created_at' => ($p['date'] ?? date('Y-m-d')) . ' 12:00:00',
                    ];
                }
            } catch (\Throwable $e) {}

            // 2e. Pending Electricity & Subscription Meter Readings (e.g., "Ali submitted Meter Reading — waiting for your response")
            try {
                $stmt = $this->db->query("
                    SELECT emr.id, emr.previous_reading, emr.current_reading, emr.consumption, emr.bill_amount, emr.created_at,
                           a.code as apartment_code, b.name as building_name,
                           u.name as agent_name, tn.full_name as tenant_name
                    FROM electricity_meter_readings emr
                    JOIN apartments a ON emr.apartment_id = a.id
                    JOIN buildings b ON a.building_id = b.id
                    LEFT JOIN users u ON emr.submitted_by = u.id
                    LEFT JOIN contracts c ON c.apartment_id = a.id AND c.status IN ('Active', 'Approved')
                    LEFT JOIN tenants tn ON c.tenant_id = tn.id
                    WHERE emr.status IN ('Pending', 'Pending Verification')
                    ORDER BY emr.id DESC
                    LIMIT 15
                ");
                foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $mr) {
                    $agName = $mr['agent_name'] ?: 'Field Agent';
                    $bld = $mr['building_name'] ?? 'Building';
                    $apt = $mr['apartment_code'] ?? '';
                    $tName = $mr['tenant_name'] ? " (Tenant: {$mr['tenant_name']})" : "";
                    $bill = number_format((float)$mr['bill_amount']);
                    $results[] = [
                        'id' => 'meter_' . $mr['id'],
                        'title' => "{$agName} submitted Meter Reading — waiting for your response",
                        'message' => "{$agName} has submitted an electricity meter reading for {$bld} • Apt {$apt}{$tName} — waiting for your response.\nWhat is it: Meter Reading ({$mr['previous_reading']} → {$mr['current_reading']} kWh • Consumption: {$mr['consumption']} kWh • Bill: CFA {$bill})",
                        'type' => 'electricity_meter',
                        'is_read' => 0,
                        'created_at' => $mr['created_at'] ?? date('Y-m-d H:i:s'),
                    ];
                }
            } catch (\Throwable $e) {}

            try {
                $stmt = $this->db->query("
                    SELECT asr.id, asr.previous_reading, asr.current_reading, asr.consumption, asr.amount_collected, asr.created_at,
                           a.code as apartment_code, b.name as building_name,
                           t.full_name as tenant_name, u.name as submitter_name
                    FROM agent_subscription_readings asr
                    JOIN apartments a ON asr.apartment_id = a.id
                    JOIN buildings b ON a.building_id = b.id
                    LEFT JOIN contracts c ON a.id = c.apartment_id AND c.status = 'Active'
                    LEFT JOIN tenants t ON c.tenant_id = t.id
                    LEFT JOIN users u ON asr.submitted_by = u.id
                    WHERE asr.status = 'Pending'
                    ORDER BY asr.id DESC
                    LIMIT 15
                ");
                foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $sr) {
                    $agName = $sr['submitter_name'] ?: 'Field Agent';
                    $tName = $sr['tenant_name'] ?: 'Tenant';
                    $bld = $sr['building_name'] ?? 'Building';
                    $apt = $sr['apartment_code'] ?? '';
                    $colStr = ((float)$sr['amount_collected'] > 0) ? " • Collected: CFA " . number_format((float)$sr['amount_collected']) : "";
                    $results[] = [
                        'id' => 'submeter_' . $sr['id'],
                        'title' => "{$agName} submitted Generator/Sub Reading — waiting for your response",
                        'message' => "{$agName} has submitted a subscription reading for {$tName} ({$bld} • Apt {$apt}) — waiting for your response.\nWhat is it: Subscription Reading ({$sr['current_reading']} kWh • Consumption: {$sr['consumption']} kWh{$colStr})",
                        'type' => 'electricity_meter',
                        'is_read' => 0,
                        'created_at' => $sr['created_at'] ?? date('Y-m-d H:i:s'),
                    ];
                }
            } catch (\Throwable $e) {}
        }

        // 3. Live operational alerts for Maintenance Workers (All Assigned Tasks & Tenant Requests with Names)
        if ($role === 'maintenance') {
            try {
                $stmt = $this->db->prepare("
                    SELECT t.id, t.title, t.description, t.category, t.priority, t.status, t.created_at,
                           a.code as apartment_code, b.name as building_name,
                           tn.full_name as tenant_name, tn.phone as tenant_phone
                    FROM tenant_maintenance_tickets t
                    LEFT JOIN apartments a ON t.apartment_id = a.id
                    LEFT JOIN buildings b ON a.building_id = b.id
                    LEFT JOIN tenants tn ON t.tenant_id = tn.id
                    WHERE (t.worker_id = ? OR t.worker_id IS NULL)
                      AND t.status IN ('Open', 'In Progress')
                    ORDER BY t.created_at DESC
                    LIMIT 25
                ");
                $stmt->execute([$user_id]);
                foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $tk) {
                    $tName = $tk['tenant_name'] ?: 'Tenant';
                    $tPhone = $tk['tenant_phone'] ? " ({$tk['tenant_phone']})" : "";
                    $bld = $tk['building_name'] ?? 'Building';
                    $apt = $tk['apartment_code'] ?? '';
                    $issue = $tk['title'] ?? $tk['category'] ?? 'Maintenance';
                    $desc = $tk['description'] ? " — {$tk['description']}" : "";
                    $results[] = [
                        'id' => 'worker_ticket_' . $tk['id'] . '_' . str_replace(' ', '', $tk['status']),
                        'title' => "{$tName} requested Maintenance ({$bld} Apt {$apt}) — waiting for your response",
                        'message' => "{$tName}{$tPhone} at {$bld} • Apt {$apt} has a maintenance request waiting for your response.\nWhat is it: {$issue}{$desc} (Status: {$tk['status']})",
                        'type' => 'maintenance_task',
                        'is_read' => 0,
                        'created_at' => $tk['created_at'] ?? date('Y-m-d H:i:s'),
                    ];
                }
            } catch (\Throwable $e) {}

            try {
                $stmt = $this->db->prepare("
                    SELECT mt.id, mt.scheduled_date, mt.status, mt.notes,
                           a.code as apartment_code, b.name as building_name,
                           tn.full_name as tenant_name, tn.phone as tenant_phone
                    FROM ac_maintenance_tasks mt
                    LEFT JOIN apartments a ON mt.apartment_id = a.id
                    LEFT JOIN buildings b ON a.building_id = b.id
                    LEFT JOIN contracts c ON c.apartment_id = a.id AND c.status IN ('Active', 'Approved')
                    LEFT JOIN tenants tn ON c.tenant_id = tn.id
                    WHERE (mt.worker_id = ? OR mt.worker_id IS NULL)
                      AND mt.status IN ('Scheduled', 'Pending', 'In Progress', 'Overdue')
                    ORDER BY mt.scheduled_date ASC
                    LIMIT 20
                ");
                $stmt->execute([$user_id]);
                foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $ac) {
                    $tName = $ac['tenant_name'] ?: 'Resident';
                    $tPhone = $ac['tenant_phone'] ? " ({$ac['tenant_phone']})" : "";
                    $bld = $ac['building_name'] ?? 'Building';
                    $apt = $ac['apartment_code'] ?? '';
                    $results[] = [
                        'id' => 'worker_ac_' . $ac['id'],
                        'title' => "AC Task for {$tName} ({$bld} Apt {$apt}) — waiting for your response",
                        'message' => "{$tName}{$tPhone} at {$bld} • Apt {$apt} has a scheduled AC maintenance task waiting for your response.\nWhat is it: Routine AC Maintenance • Scheduled: " . ($ac['scheduled_date'] ?? 'Today'),
                        'type' => 'maintenance_task',
                        'is_read' => 0,
                        'created_at' => ($ac['scheduled_date'] ?? date('Y-m-d')) . ' 09:00:00',
                    ];
                }
            } catch (\Throwable $e) {}
        }

        // 4. Live operational alerts for Field Agents (Rent Collections, Subscription Invoices & Meter Tasks with Tenant Names)
        if ($role === 'agent') {
            // Unpaid Rent Invoices to Collect
            try {
                $stmt = $this->db->query("
                    SELECT ri.id, ri.invoice_number, ri.amount, ri.due_date, ri.status,
                           COALESCE((SELECT SUM(rp.amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0) as paid_amount,
                           a.code as apartment_code, b.name as building_name,
                           t.full_name as tenant_name, t.phone as tenant_phone
                    FROM rent_invoices ri
                    JOIN contracts c ON ri.contract_id = c.id
                    JOIN tenants t ON c.tenant_id = t.id
                    JOIN apartments a ON c.apartment_id = a.id
                    JOIN buildings b ON a.building_id = b.id
                    WHERE c.status IN ('Active', 'Approved')
                      AND ri.status IN ('Unpaid', 'Partial', 'Overdue')
                    ORDER BY ri.due_date ASC
                    LIMIT 20
                ");
                foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $inv) {
                    $remaining = max(0, (float)$inv['amount'] - (float)$inv['paid_amount']);
                    if ($remaining <= 0) continue;
                    $tName = $inv['tenant_name'] ?: 'Tenant';
                    $tPhone = $inv['tenant_phone'] ? " ({$inv['tenant_phone']})" : "";
                    $amt = number_format($remaining);
                    $bld = $inv['building_name'] ?? 'Building';
                    $apt = $inv['apartment_code'] ?? '';
                    $results[] = [
                        'id' => 'agent_rent_' . $inv['id'],
                        'title' => "Collect Rent from {$tName} (CFA {$amt}) — waiting for your response",
                        'message' => "{$tName}{$tPhone} at {$bld} • Apt {$apt} has rent of CFA {$amt} waiting for collection.\nWhat is it: Rent Invoice {$inv['invoice_number']} • Due: {$inv['due_date']}",
                        'type' => 'task_rent_collection',
                        'is_read' => 0,
                        'created_at' => ($inv['due_date'] ?? date('Y-m-d')) . ' 08:00:00',
                    ];
                }
            } catch (\Throwable $e) {}

            // Unpaid Electricity / Generator Subscription Invoices to Collect
            try {
                $stmt = $this->db->query("
                    SELECT ei.id, ei.type, ei.amount, ei.amount_paid, ei.due_date,
                           a.code as apartment_code, b.name as building_name,
                           t.full_name as tenant_name, t.phone as tenant_phone
                    FROM electricity_invoices ei
                    JOIN apartments a ON ei.apartment_id = a.id
                    JOIN buildings b ON a.building_id = b.id
                    LEFT JOIN contracts c ON c.apartment_id = a.id AND c.status IN ('Active', 'Approved')
                    LEFT JOIN tenants t ON c.tenant_id = t.id
                    WHERE ei.status != 'Paid'
                    ORDER BY ei.due_date ASC
                    LIMIT 15
                ");
                foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $einv) {
                    $rem = max(0, (float)$einv['amount'] - (float)$einv['amount_paid']);
                    if ($rem <= 0) continue;
                    $tName = $einv['tenant_name'] ?: 'Resident';
                    $tPhone = $einv['tenant_phone'] ? " ({$einv['tenant_phone']})" : "";
                    $amt = number_format($rem);
                    $bld = $einv['building_name'] ?? 'Building';
                    $apt = $einv['apartment_code'] ?? '';
                    $results[] = [
                        'id' => 'agent_elec_' . $einv['id'],
                        'title' => "Collect {$einv['type']} from {$tName} (CFA {$amt}) — waiting for your response",
                        'message' => "{$tName}{$tPhone} at {$bld} • Apt {$apt} has a {$einv['type']} invoice of CFA {$amt} waiting for collection.\nWhat is it: {$einv['type']} Collection • Due: {$einv['due_date']}",
                        'type' => 'electricity_collection',
                        'is_read' => 0,
                        'created_at' => ($einv['due_date'] ?? date('Y-m-d')) . ' 08:30:00',
                    ];
                }
            } catch (\Throwable $e) {}
        }

        foreach ($results as &$__r) { $__r['route'] = PushNotificationService::routeFor($__r['type'] ?? '', $role); }
        unset($__r);
        echo json_encode($results);
    }

    public function markAsRead($id) {
        $user = AuthMiddleware::requireLogin();
        $user_id = $user['user_id'] ?? $user['id'] ?? null;

        if (!$user_id) {
            http_response_code(400);
            echo json_encode(['error' => 'Invalid user session']);
            return;
        }

        if (is_numeric($id)) {
            try {
                try {
                    $stmt = $this->db->prepare("UPDATE notifications SET is_read = 1, read_at = NOW() WHERE id = ? AND user_id = ?");
                    $stmt->execute([$id, $user_id]);
                } catch (\Throwable $e0) {
                    $stmt = $this->db->prepare("UPDATE notifications SET is_read = 1 WHERE id = ? AND user_id = ?");
                    $stmt->execute([$id, $user_id]);
                }
            } catch (\Throwable $e) {}
        }

        echo json_encode(['message' => 'Notification marked as read.']);
    }
}
