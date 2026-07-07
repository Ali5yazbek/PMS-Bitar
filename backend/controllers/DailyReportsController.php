<?php

class DailyReportsController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function index() {
        try {
            $stmt = $this->db->query("
                SELECT r.*, u.name as agent_name, b.name as building_name 
                FROM daily_reports r
                JOIN users u ON r.agent_id = u.id
                JOIN buildings b ON r.building_id = b.id
                ORDER BY r.created_at DESC
            ");
            echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function dashboard() {
        try {
            // Get today's reports
            $stmt = $this->db->query("
                SELECT r.*, u.name as agent_name, b.name as building_name 
                FROM daily_reports r
                JOIN users u ON r.agent_id = u.id
                JOIN buildings b ON r.building_id = b.id
                WHERE r.date = CURDATE()
                ORDER BY r.created_at DESC
            ");
            $todayReports = $stmt->fetchAll(PDO::FETCH_ASSOC);

            // Find agents who haven't submitted
            // We consider 'agent' and 'maintenance' roles, or just check 'agent'
            $agentStmt = $this->db->query("SELECT id, name FROM users WHERE role IN ('agent', 'maintenance')");
            $agents = $agentStmt->fetchAll(PDO::FETCH_ASSOC);

            $submittedAgentIds = array_column($todayReports, 'agent_id');
            $missingAgents = [];

            foreach ($agents as $agent) {
                if (!in_array($agent['id'], $submittedAgentIds)) {
                    $missingAgents[] = $agent;
                }
            }

            echo json_encode([
                'reports' => $todayReports,
                'missing_agents' => $missingAgents
            ]);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function store() {
        try {
            $agent_id = $_POST['agent_id'] ?? null;
            $building_id = $_POST['building_id'] ?? null;
            $apartments_visited = $_POST['apartments_visited'] ?? '';
            $tasks_completed = $_POST['tasks_completed'] ?? 0;
            $issues_found = $_POST['issues_found'] ?? '';
            $notes = $_POST['notes'] ?? '';
            $start_time = $_POST['start_time'] ?? null;
            $end_time = $_POST['end_time'] ?? null;
            
            if (!$agent_id || !$building_id || !$tasks_completed) {
                http_response_code(400);
                echo json_encode(['error' => 'Missing required fields']);
                return;
            }

            $uploadDir = __DIR__ . '/../../uploads/daily-reports/';
            if (!is_dir($uploadDir)) {
                mkdir($uploadDir, 0777, true);
            }

            $photoPaths = [];
            
            // Handle multiple file uploads
            if (!empty($_FILES['photos']['name'][0])) {
                $count = count($_FILES['photos']['name']);
                for ($i = 0; $i < $count; $i++) {
                    if ($_FILES['photos']['error'][$i] === UPLOAD_ERR_OK) {
                        $filename = time() . '_' . uniqid() . '_' . basename($_FILES['photos']['name'][$i]);
                        $targetFilePath = $uploadDir . $filename;
                        if (move_uploaded_file($_FILES['photos']['tmp_name'][$i], $targetFilePath)) {
                            $photoPaths[] = 'uploads/daily-reports/' . $filename;
                        }
                    }
                }
            }
            
            $status = (count($photoPaths) > 0) ? 'Completed' : 'Missing Photos';

            $stmt = $this->db->prepare("
                INSERT INTO daily_reports (
                    agent_id, building_id, apartments_visited, tasks_completed, 
                    issues_found, notes, start_time, end_time, status, photos, date
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURDATE())
            ");
            
            $stmt->execute([
                $agent_id,
                $building_id,
                $apartments_visited,
                $tasks_completed,
                $issues_found,
                $notes,
                $start_time,
                $end_time,
                $status,
                json_encode($photoPaths)
            ]);

            echo json_encode(['message' => 'Report submitted successfully']);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }
}
