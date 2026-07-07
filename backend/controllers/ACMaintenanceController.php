<?php
class ACMaintenanceController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    // --- Worker Routes ---

    public function workerTasks() {
        AuthMiddleware::requireLogin();
        // Assuming user ID is extracted from token. In this basic system without full JWT payload passing to controller,
        // we might not have it directly if we don't fetch user details. But let's assume workers can see all pending due tasks.
        // Or we could assign them. For now, we list all Scheduled and Rejected tasks for the Maintenance Worker.
        
        $stmt = $this->db->query("
            SELECT t.*, a.code as apartment_code, b.name as building_name
            FROM ac_maintenance_tasks t
            JOIN apartments a ON t.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE t.status IN ('Scheduled', 'Rejected') AND t.scheduled_date <= CURRENT_DATE()
            ORDER BY t.scheduled_date ASC
        ");
        echo json_encode($stmt->fetchAll());
    }

    public function submitTask($id) {
        AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);

        if (empty($data['before_photo']) || empty($data['after_photo']) || empty($data['notes'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Missing required fields: before photo, after photo, and notes are mandatory.']);
            return;
        }

        $stmt = $this->db->prepare("
            UPDATE ac_maintenance_tasks 
            SET status = 'Pending_Approval', before_photo = ?, after_photo = ?, notes = ?, submission_date = NOW(), worker_id = ?
            WHERE id = ? AND status IN ('Scheduled', 'Rejected')
        ");
        
        // In a real app we'd get the actual user_id from auth token. We use null for now if not available in request.
        $worker_id = $data['worker_id'] ?? null; 
        
        try {
            $stmt->execute([$data['before_photo'], $data['after_photo'], $data['notes'], $worker_id, $id]);

            if ($stmt->rowCount() > 0) {
                echo json_encode(['message' => 'Task submitted successfully']);
            } else {
                http_response_code(400);
                echo json_encode(['error' => 'Task not found or not in a submittable state.']);
            }
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
            WHERE t.status = 'Pending_Approval'
            ORDER BY t.submission_date ASC
        ");
        echo json_encode($stmt->fetchAll());
    }

    public function taskHistory() {
        AuthMiddleware::requireLogin();
        
        $stmt = $this->db->query("
            SELECT t.*, a.code as apartment_code, b.name as building_name, u.name as worker_name
            FROM ac_maintenance_tasks t
            JOIN apartments a ON t.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            LEFT JOIN users u ON t.worker_id = u.id
            ORDER BY t.created_at DESC
        ");
        echo json_encode($stmt->fetchAll());
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
        
        $startDate = $_GET['start_date'] ?? date('Y-m-d');
        $endDate = $_GET['end_date'] ?? date('Y-m-d');

        // Find all maintenance workers
        $stmtWorkers = $this->db->prepare("SELECT id, name FROM users WHERE role = 'maintenance'");
        $stmtWorkers->execute();
        $workers = $stmtWorkers->fetchAll(PDO::FETCH_ASSOC);

        $reports = [];

        foreach ($workers as $worker) {
            $query = "
                SELECT t.*, a.code as apartment_code, b.name as building_name
                FROM ac_maintenance_tasks t
                JOIN apartments a ON t.apartment_id = a.id
                JOIN buildings b ON a.building_id = b.id
                WHERE t.worker_id = ? AND DATE(t.submission_date) BETWEEN ? AND ?
            ";
            
            $params = [$worker['id'], $startDate, $endDate];

            $stmtTasks = $this->db->prepare($query);
            $stmtTasks->execute($params);
            $tasks = $stmtTasks->fetchAll(PDO::FETCH_ASSOC);

            $reports[] = [
                'worker_id' => $worker['id'],
                'worker_name' => $worker['name'],
                'tasks_count' => count($tasks),
                'tasks' => $tasks
            ];
        }

        echo json_encode($reports);
    }
}
