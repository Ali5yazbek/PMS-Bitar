<?php
class ACMaintenanceController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    // --- Worker Routes ---

    public function workerTasks() {
        AuthMiddleware::requireLogin();
        
        // 1. Fetch active tenant maintenance tickets (Open, Assigned, In Progress, Rejected)
        $tenantTicketsStmt = $this->db->query("
            SELECT 
                tmt.id,
                'tenant_ticket' AS task_type,
                tmt.tenant_id,
                tmt.apartment_id,
                tmt.title,
                tmt.description,
                COALESCE(tmt.category, 'General Maintenance') AS category,
                COALESCE(tmt.priority, 'Medium') AS priority,
                tmt.status,
                tmt.worker_notes,
                tmt.admin_notes,
                tmt.before_photo,
                tmt.after_photo,
                tmt.created_at,
                DATE(tmt.created_at) AS scheduled_date,
                a.code AS apartment_code,
                b.name AS building_name,
                t.full_name AS tenant_name,
                t.phone AS tenant_phone
            FROM tenant_maintenance_tickets tmt
            JOIN tenants t ON tmt.tenant_id = t.id
            LEFT JOIN apartments a ON tmt.apartment_id = a.id
            LEFT JOIN buildings b ON a.building_id = b.id
            WHERE tmt.status IN ('Open', 'Assigned', 'In Progress', 'Rejected')
            ORDER BY 
                CASE tmt.priority
                    WHEN 'Urgent' THEN 1
                    WHEN 'High' THEN 2
                    WHEN 'Medium' THEN 3
                    ELSE 4
                END,
                tmt.created_at DESC
        ");
        $tenantTickets = $tenantTicketsStmt ? $tenantTicketsStmt->fetchAll(PDO::FETCH_ASSOC) : [];

        // 2. Fetch scheduled routine AC maintenance tasks
        $acTasksStmt = $this->db->query("
            SELECT 
                amt.id,
                'routine_ac' AS task_type,
                NULL AS tenant_id,
                amt.apartment_id,
                'Routine AC Filter & Coil Cleaning' AS title,
                COALESCE(amt.notes, 'Routine preventive AC inspection, filter wash and coil maintenance.') AS description,
                'AC / HVAC' AS category,
                'Medium' AS priority,
                amt.status,
                amt.notes AS worker_notes,
                NULL AS admin_notes,
                amt.before_photo,
                amt.after_photo,
                amt.created_at,
                amt.scheduled_date,
                a.code AS apartment_code,
                b.name AS building_name,
                (SELECT t2.full_name FROM contracts c JOIN tenants t2 ON c.tenant_id = t2.id WHERE c.apartment_id = a.id AND c.status IN ('Active', 'Approved') ORDER BY c.id DESC LIMIT 1) AS tenant_name,
                (SELECT t2.phone FROM contracts c JOIN tenants t2 ON c.tenant_id = t2.id WHERE c.apartment_id = a.id AND c.status IN ('Active', 'Approved') ORDER BY c.id DESC LIMIT 1) AS tenant_phone
            FROM ac_maintenance_tasks amt
            JOIN apartments a ON amt.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE amt.status NOT IN ('Completed', 'Approved')
            ORDER BY amt.scheduled_date ASC
        ");
        $acTasks = $acTasksStmt ? $acTasksStmt->fetchAll(PDO::FETCH_ASSOC) : [];

        // Merge both lists: tenant tickets prioritized, followed by routine cleanings
        $allTasks = array_merge($tenantTickets, $acTasks);
        if (class_exists('TenantMaintenanceController')) {
            foreach ($allTasks as &$row) {
                if (!empty($row['before_photo']) && strlen($row['before_photo']) > 45000) {
                    $row['before_photo'] = TenantMaintenanceController::compressBase64Photo($row['before_photo']);
                }
                if (!empty($row['after_photo']) && strlen($row['after_photo']) > 45000) {
                    $row['after_photo'] = TenantMaintenanceController::compressBase64Photo($row['after_photo']);
                }
            }
            unset($row);
        }

        echo json_encode($allTasks);
    }

    public function workerHistory() {
        $user = AuthMiddleware::requireLogin();
        $worker_id = $user['user_id'] ?? $user['id'] ?? null;
        
        // 1. Tenant Tickets resolved by this worker
        $ticketStmt = $this->db->prepare("
            SELECT 
                tmt.id,
                'tenant_ticket' AS task_type,
                tmt.title,
                tmt.description,
                tmt.category,
                tmt.priority,
                tmt.status,
                tmt.before_photo,
                tmt.after_photo,
                tmt.worker_notes AS notes,
                tmt.completion_date AS submission_date,
                tmt.resolved_at AS completion_date,
                tmt.created_at,
                DATE(tmt.created_at) AS scheduled_date,
                a.code AS apartment_code,
                b.name AS building_name,
                t.full_name AS tenant_name
            FROM tenant_maintenance_tickets tmt
            JOIN tenants t ON tmt.tenant_id = t.id
            LEFT JOIN apartments a ON tmt.apartment_id = a.id
            LEFT JOIN buildings b ON a.building_id = b.id
            WHERE (tmt.worker_id = ? OR ? IS NULL) AND tmt.status IN ('Resolved', 'Pending_Approval', 'Closed')
            ORDER BY tmt.resolved_at DESC, tmt.updated_at DESC
        ");
        $ticketStmt->execute([$worker_id, $worker_id]);
        $ticketHistory = $ticketStmt ? $ticketStmt->fetchAll(PDO::FETCH_ASSOC) : [];

        // 2. Routine AC tasks completed by this worker
        $acStmt = $this->db->prepare("
            SELECT 
                amt.id,
                'routine_ac' AS task_type,
                'Routine AC Cleaning' AS title,
                amt.notes AS description,
                'AC / HVAC' AS category,
                'Medium' AS priority,
                amt.status,
                amt.before_photo,
                amt.after_photo,
                amt.notes,
                amt.submission_date,
                amt.completion_date,
                amt.created_at,
                amt.scheduled_date,
                a.code AS apartment_code,
                b.name AS building_name,
                NULL AS tenant_name
            FROM ac_maintenance_tasks amt
            JOIN apartments a ON amt.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE (amt.worker_id = ? OR ? IS NULL) AND amt.status IN ('Pending_Approval', 'Completed', 'Approved')
            ORDER BY amt.submission_date DESC, amt.created_at DESC
        ");
        $acStmt->execute([$worker_id, $worker_id]);
        $acHistory = $acStmt ? $acStmt->fetchAll(PDO::FETCH_ASSOC) : [];

        $allHistory = array_merge($ticketHistory, $acHistory);
        if (class_exists('TenantMaintenanceController')) {
            foreach ($allHistory as &$row) {
                if (!empty($row['before_photo']) && strlen($row['before_photo']) > 45000) {
                    $row['before_photo'] = TenantMaintenanceController::compressBase64Photo($row['before_photo']);
                }
                if (!empty($row['after_photo']) && strlen($row['after_photo']) > 45000) {
                    $row['after_photo'] = TenantMaintenanceController::compressBase64Photo($row['after_photo']);
                }
            }
            unset($row);
        }
        echo json_encode($allHistory);
    }

    public function submitTask($id = null) {
        $user = AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true) ?? [];

        $taskId = $id ?? ($data['task_id'] ?? null);
        if (!$taskId) {
            http_response_code(400);
            echo json_encode(['error' => 'Task ID is required.']);
            return;
        }

        $taskType = $data['task_type'] ?? null;
        $beforePhoto = $data['before_photo'] ?? ($data['before_image'] ?? null);
        $afterPhoto = $data['after_photo'] ?? ($data['after_image'] ?? null);
        if (class_exists('TenantMaintenanceController')) {
            $beforePhoto = TenantMaintenanceController::compressBase64Photo($beforePhoto) ?? $beforePhoto;
            $afterPhoto = TenantMaintenanceController::compressBase64Photo($afterPhoto) ?? $afterPhoto;
        }
        $notes = !empty($data['notes']) ? $data['notes'] : (!empty($data['worker_notes']) ? $data['worker_notes'] : 'Maintenance completed with photo documentation.');

        if (empty($beforePhoto) || empty($afterPhoto)) {
            http_response_code(400);
            echo json_encode(['error' => 'Missing required fields: before photo and after photo are mandatory.']);
            return;
        }

        $worker_id = $user['user_id'] ?? $user['id'] ?? null;

        // Disambiguate if task_type not passed explicitly:
        if (empty($taskType)) {
            $tCheck = $this->db->prepare("SELECT id FROM tenant_maintenance_tickets WHERE id = ?");
            $tCheck->execute([$taskId]);
            if ($tCheck->fetch()) {
                $taskType = 'tenant_ticket';
            } else {
                $taskType = 'routine_ac';
            }
        }

        if ($taskType === 'tenant_ticket') {
            $stmt = $this->db->prepare("
                UPDATE tenant_maintenance_tickets 
                SET status = 'Resolved', 
                    worker_id = ?, 
                    before_photo = ?, 
                    after_photo = ?, 
                    worker_notes = ?, 
                    completion_date = NOW(), 
                    resolved_at = NOW()
                WHERE id = ?
            ");
            try {
                $stmt->execute([$worker_id, $beforePhoto, $afterPhoto, $notes, $taskId]);
                AuditLogger::log('UPDATE', 'MaintenanceTicket', $taskId, "Tenant ticket #{$taskId} resolved by worker #{$worker_id}");
                try {
                    $uStmt = $this->db->prepare("SELECT name FROM users WHERE id = ? LIMIT 1");
                    $uStmt->execute([$worker_id]);
                    $workerName = $uStmt->fetchColumn() ?: 'Maintenance Worker';
                    $adminsStmt = $this->db->query("SELECT id FROM users WHERE role IN ('admin', 'super_admin', 'manager') LIMIT 10");
                    foreach ($adminsStmt->fetchAll(PDO::FETCH_COLUMN) as $adminId) {
                        $notifTitle = "🔧 {$workerName} completed Maintenance Task — waiting for your response";
                        $notifMsg = "{$workerName} has completed maintenance ticket #{$taskId} — waiting for your response.\nWhat is it: Tenant Maintenance Task • Notes: {$notes}";
                        $notifStmt = $this->db->prepare("INSERT INTO notifications (user_id, title, message, type) VALUES (?, ?, ?, 'tenant_maintenance')");
                        $notifStmt->execute([$adminId, $notifTitle, $notifMsg]);
                    }
                } catch (\Throwable $ne) {}
                echo json_encode(['message' => 'Tenant maintenance ticket completed successfully', 'status' => 'Resolved']);
            } catch (Exception $e) {
                http_response_code(500);
                echo json_encode(['error' => 'Database error: ' . $e->getMessage()]);
            }
            return;
        }

        // AC Routine Maintenance Task
        $stmt = $this->db->prepare("
            UPDATE ac_maintenance_tasks 
            SET status = 'Pending_Approval', before_photo = ?, after_photo = ?, notes = ?, submission_date = NOW(), worker_id = ?
            WHERE id = ?
        ");
        
        try {
            $stmt->execute([$beforePhoto, $afterPhoto, $notes, $worker_id, $taskId]);
            AuditLogger::log('UPDATE', 'ACMaintenanceTask', $taskId, "Routine AC task #{$taskId} submitted for approval by worker #{$worker_id}");
            try {
                $uStmt = $this->db->prepare("SELECT name FROM users WHERE id = ? LIMIT 1");
                $uStmt->execute([$worker_id]);
                $workerName = $uStmt->fetchColumn() ?: 'Maintenance Worker';
                $adminsStmt = $this->db->query("SELECT id FROM users WHERE role IN ('admin', 'super_admin', 'manager') LIMIT 10");
                foreach ($adminsStmt->fetchAll(PDO::FETCH_COLUMN) as $adminId) {
                    $notifTitle = "❄️ {$workerName} completed AC Task — waiting for your response";
                    $notifMsg = "{$workerName} has completed AC maintenance task #{$taskId} — waiting for your response.\nWhat is it: AC Maintenance Submission • Notes: {$notes}";
                    $notifStmt = $this->db->prepare("INSERT INTO notifications (user_id, title, message, type) VALUES (?, ?, ?, 'maintenance_ac')");
                    $notifStmt->execute([$adminId, $notifTitle, $notifMsg]);
                }
            } catch (\Throwable $ne) {}
            echo json_encode(['message' => 'Task submitted successfully']);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => 'Database error: ' . $e->getMessage()]);
        }
    }

    // --- Admin Routes ---

    public function pendingTasks() {
        AuthMiddleware::requireLogin();
        
        $stmt = $this->db->query("
            SELECT t.*, a.code as apartment_code, b.name as building_name, u.name as worker_name
            FROM ac_maintenance_tasks t
            JOIN apartments a ON t.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            LEFT JOIN users u ON t.worker_id = u.id
            WHERE t.status IN ('Pending_Approval', 'Pending Approval', 'Pending')
            ORDER BY COALESCE(t.submission_date, t.created_at) DESC
        ");
        $rows = $stmt ? $stmt->fetchAll(PDO::FETCH_ASSOC) : [];
        if (class_exists('TenantMaintenanceController')) {
            foreach ($rows as &$row) {
                $changed = false;
                if (!empty($row['before_photo']) && strlen($row['before_photo']) > 45000) {
                    $c = TenantMaintenanceController::compressBase64Photo($row['before_photo']);
                    if ($c !== null && $c !== $row['before_photo']) {
                        $row['before_photo'] = $c;
                        $changed = true;
                    }
                }
                if (!empty($row['after_photo']) && strlen($row['after_photo']) > 45000) {
                    $c = TenantMaintenanceController::compressBase64Photo($row['after_photo']);
                    if ($c !== null && $c !== $row['after_photo']) {
                        $row['after_photo'] = $c;
                        $changed = true;
                    }
                }
                if ($changed && !empty($row['id'])) {
                    try {
                        $upd = $this->db->prepare("UPDATE ac_maintenance_tasks SET before_photo = ?, after_photo = ? WHERE id = ?");
                        $upd->execute([$row['before_photo'], $row['after_photo'], $row['id']]);
                    } catch (\Throwable $e) {}
                }
            }
            unset($row);
        }
        echo json_encode($rows);
    }

    public function taskHistory() {
        AuthMiddleware::requireLogin();
        
        $stmt = $this->db->query("
            SELECT 
                t.id,
                t.apartment_id,
                t.worker_id,
                t.scheduled_date,
                t.submission_date,
                t.completion_date,
                t.status,
                t.notes,
                t.created_at,
                a.code as apartment_code,
                b.name as building_name,
                u.name as worker_name
            FROM ac_maintenance_tasks t
            JOIN apartments a ON t.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            LEFT JOIN users u ON t.worker_id = u.id
            ORDER BY t.created_at DESC
        ");
        echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
    }

    public function approveTask($id) {
        AuthMiddleware::requireLogin();
        
        $this->db->beginTransaction();
        try {
            // Update current task
            $stmt = $this->db->prepare("UPDATE ac_maintenance_tasks SET status = 'Completed', completion_date = NOW() WHERE id = ?");
            $stmt->execute([$id]);

            // Get apartment_id
            $getStmt = $this->db->prepare("SELECT apartment_id FROM ac_maintenance_tasks WHERE id = ?");
            $getStmt->execute([$id]);
            $task = $getStmt->fetch();

            if ($task) {
                // Create next task +30 days
                $nextDate = date('Y-m-d', strtotime('+30 days'));
                $insertStmt = $this->db->prepare("INSERT INTO ac_maintenance_tasks (apartment_id, scheduled_date, status) VALUES (?, ?, 'Scheduled')");
                $insertStmt->execute([$task['apartment_id'], $nextDate]);
            }

            $this->db->commit();
            echo json_encode(['message' => 'Task approved and next cleaning scheduled.']);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => 'Database error: ' . $e->getMessage()]);
        }
    }

    public function rejectTask($id) {
        AuthMiddleware::requireLogin();
        
        $stmt = $this->db->prepare("UPDATE ac_maintenance_tasks SET status = 'Rejected' WHERE id = ?");
        $stmt->execute([$id]);
        
        echo json_encode(['message' => 'Task rejected. Worker must resubmit.']);
    }

    public function generateSmartSchedules($building_id) {
        AuthMiddleware::requireLogin();
        
        // Count total apartments in building
        $totalStmt = $this->db->prepare("SELECT COUNT(*) as total FROM apartments WHERE building_id = ?");
        $totalStmt->execute([$building_id]);
        $total = $totalStmt->fetch(PDO::FETCH_ASSOC)['total'];

        // Find all apartments in the building that DO NOT have an active maintenance task
        // Active tasks are 'Scheduled', 'Pending_Approval', or 'Rejected'
        $stmt = $this->db->prepare("
            SELECT id FROM apartments 
            WHERE building_id = ? 
            AND id NOT IN (
                SELECT apartment_id FROM ac_maintenance_tasks 
                WHERE status IN ('Scheduled', 'Pending_Approval', 'Rejected')
            )
        ");
        $stmt->execute([$building_id]);
        $apartments = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $count = 0;
        if (!empty($apartments)) {
            $today = date('Y-m-d');
            $insertStmt = $this->db->prepare("INSERT INTO ac_maintenance_tasks (apartment_id, scheduled_date, status) VALUES (?, ?, 'Scheduled')");
            
            $this->db->beginTransaction();
            try {
                foreach ($apartments as $apt) {
                    $insertStmt->execute([$apt['id'], $today]);
                    $count++;
                }
                $this->db->commit();
            } catch (Exception $e) {
                $this->db->rollBack();
                http_response_code(500);
                echo json_encode(['error' => 'Database error while scheduling: ' . $e->getMessage()]);
                return;
            }
        }
        
        $alreadyScheduled = $total - $count;
        echo json_encode(['message' => "Smart generation complete. Created $count new schedules. ($alreadyScheduled apartments were already scheduled)"]);
    }

    public function workerReport() {
        AuthMiddleware::requireLogin();
        
        $startDate = !empty($_GET['start_date']) ? $_GET['start_date'] : null;
        $endDate = !empty($_GET['end_date']) ? $_GET['end_date'] : null;
        $includePhotos = !empty($_GET['include_photos']);

        // Find all maintenance workers + any user who has handled maintenance tasks
        $workers = [];
        try {
            $stmtWorkers = $this->db->query("
                SELECT DISTINCT u.id, u.name
                FROM users u
                WHERE LOWER(TRIM(u.role)) IN ('maintenance', 'technician', 'worker', 'field_tech', 'ac_tech')
                   OR u.id IN (SELECT DISTINCT worker_id FROM ac_maintenance_tasks WHERE worker_id IS NOT NULL)
                   OR u.id IN (SELECT DISTINCT worker_id FROM tenant_maintenance_tickets WHERE worker_id IS NOT NULL)
                ORDER BY u.id ASC
            ");
            $workers = $stmtWorkers ? $stmtWorkers->fetchAll(PDO::FETCH_ASSOC) : [];
        } catch (\Throwable $e) {
            $stmtWorkers = $this->db->prepare("SELECT id, name FROM users WHERE LOWER(TRIM(role)) = 'maintenance'");
            $stmtWorkers->execute();
            $workers = $stmtWorkers->fetchAll(PDO::FETCH_ASSOC);
        }

        $reports = [];
        $acPhotoCols = $includePhotos ? "t.before_photo, t.after_photo," : "NULL AS before_photo, NULL AS after_photo,";
        $tmtPhotoCols = $includePhotos ? "tmt.before_photo, tmt.after_photo," : "NULL AS before_photo, NULL AS after_photo,";

        foreach ($workers as $worker) {
            $workerId = $worker['id'];

            // 1. Routine AC tasks
            $acTasks = [];
            try {
                $acQuery = "
                    SELECT 
                        t.id,
                        'routine_ac' AS task_type,
                        'Routine AC Cleaning' AS title,
                        t.notes,
                        t.status,
                        {$acPhotoCols}
                        COALESCE(t.completion_date, t.submission_date, t.created_at) AS submission_date,
                        t.completion_date,
                        t.created_at,
                        a.code as apartment_code, 
                        b.name as building_name
                    FROM ac_maintenance_tasks t
                    JOIN apartments a ON t.apartment_id = a.id
                    JOIN buildings b ON a.building_id = b.id
                    WHERE t.worker_id = ?
                ";
                $acParams = [$workerId];
                if (!empty($startDate) && !empty($endDate)) {
                    $acQuery .= " AND DATE(COALESCE(t.completion_date, t.submission_date, t.created_at)) BETWEEN ? AND ?";
                    $acParams[] = $startDate;
                    $acParams[] = $endDate;
                }
                $acQuery .= " ORDER BY t.id DESC";
                $acStmt = $this->db->prepare($acQuery);
                $acStmt->execute($acParams);
                $acTasks = $acStmt ? $acStmt->fetchAll(PDO::FETCH_ASSOC) : [];
            } catch (\Throwable $e) {
                $acTasks = [];
            }

            // 2. Tenant maintenance tickets (with schema-safe fallback)
            $ticketTasks = [];
            try {
                $ticketQuery = "
                    SELECT 
                        tmt.id,
                        'tenant_ticket' AS task_type,
                        tmt.title,
                        COALESCE(tmt.worker_notes, tmt.description) AS notes,
                        tmt.status,
                        {$tmtPhotoCols}
                        COALESCE(tmt.completion_date, tmt.resolved_at, tmt.created_at) AS submission_date,
                        tmt.completion_date,
                        tmt.created_at,
                        COALESCE(a.code, 'N/A') as apartment_code, 
                        COALESCE(b.name, 'Building') as building_name
                    FROM tenant_maintenance_tickets tmt
                    LEFT JOIN apartments a ON tmt.apartment_id = a.id
                    LEFT JOIN buildings b ON a.building_id = b.id
                    WHERE tmt.worker_id = ?
                ";
                $ticketParams = [$workerId];
                if (!empty($startDate) && !empty($endDate)) {
                    $ticketQuery .= " AND DATE(COALESCE(tmt.completion_date, tmt.resolved_at, tmt.created_at)) BETWEEN ? AND ?";
                    $ticketParams[] = $startDate;
                    $ticketParams[] = $endDate;
                }
                $ticketQuery .= " ORDER BY tmt.id DESC";
                $ticketStmt = $this->db->prepare($ticketQuery);
                $ticketStmt->execute($ticketParams);
                $ticketTasks = $ticketStmt ? $ticketStmt->fetchAll(PDO::FETCH_ASSOC) : [];
            } catch (\Throwable $e) {
                try {
                    $fallbackStmt = $this->db->prepare("
                        SELECT 
                            tmt.id,
                            'tenant_ticket' AS task_type,
                            tmt.title,
                            tmt.description AS notes,
                            tmt.status,
                            NULL AS before_photo,
                            NULL AS after_photo,
                            COALESCE(tmt.resolved_at, tmt.created_at) AS submission_date,
                            tmt.resolved_at AS completion_date,
                            tmt.created_at,
                            COALESCE(a.code, 'N/A') as apartment_code, 
                            COALESCE(b.name, 'Building') as building_name
                        FROM tenant_maintenance_tickets tmt
                        LEFT JOIN apartments a ON tmt.apartment_id = a.id
                        LEFT JOIN buildings b ON a.building_id = b.id
                        WHERE tmt.worker_id = ?
                        ORDER BY tmt.id DESC
                    ");
                    $fallbackStmt->execute([$workerId]);
                    $ticketTasks = $fallbackStmt ? $fallbackStmt->fetchAll(PDO::FETCH_ASSOC) : [];
                } catch (\Throwable $e2) {
                    $ticketTasks = [];
                }
            }

            $allTasks = array_merge($ticketTasks, $acTasks);
            $completedCount = 0;
            $pendingCount = 0;
            foreach ($allTasks as $tk) {
                $st = strtolower(trim($tk['status'] ?? ''));
                if (in_array($st, ['completed', 'approved', 'resolved', 'closed'], true)) {
                    $completedCount++;
                } else {
                    $pendingCount++;
                }
            }

            $reports[] = [
                'worker_id' => $worker['id'],
                'worker_name' => $worker['name'],
                'tasks_count' => count($allTasks),
                'completed_count' => $completedCount,
                'pending_count' => $pendingCount,
                'tasks' => $allTasks
            ];
        }

        echo json_encode($reports);
    }
}
