<?php
require_once __DIR__ . '/../core/DataQualityEngine.php';

class DataQualityController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }
    private function getCurrentUser() {
        $token = JWT::getBearerToken();
        if ($token) {
            $decoded = JWT::decode($token);
            if ($decoded && isset($decoded['user_id'])) {
                return [
                    'id' => (int)$decoded['user_id'],
                    'role' => $decoded['role'] ?? 'manager'
                ];
            }
        }
        return ['id' => 1, 'role' => 'admin'];
    }

    public function employees() {
        AuthMiddleware::requireLogin();
        
        $date = $_GET['date'] ?? date('Y-m-d');
        $user = $this->getCurrentUser();

        $query = "
            SELECT 
                u.id as employee_id,
                u.name,
                u.role,
                (SELECT name FROM buildings LIMIT 1) as department,
                (SELECT MAX(created_at) FROM activity_logs WHERE user_id = u.id AND DATE(created_at) = :date) as last_submission,
                COUNT(a.id) as total_errors,
                SUM(CASE WHEN a.status = 'Open' THEN 1 ELSE 0 END) as open_errors,
                (SELECT COUNT(*) FROM activity_logs al WHERE al.user_id = u.id AND DATE(al.created_at) = :date) as total_submitted
            FROM users u
            LEFT JOIN audit_reports a ON u.id = a.employee_id AND DATE(a.created_at) = :date
            WHERE u.role IN ('admin', 'manager', 'cashier', 'agent')
        ";
        
        $params = ['date' => $date];

        if ($user['role'] !== 'admin' && $user['role'] !== 'manager') {
            $query .= " AND u.id = :user_id";
            $params['user_id'] = $user['user_id'] ?? $user['id'];
        }

        $query .= " GROUP BY u.id";

        $stmt = $this->db->prepare($query);
        $stmt->execute($params);
        $employees = $stmt->fetchAll(PDO::FETCH_ASSOC);

        foreach ($employees as &$emp) {
            $submitted = intval($emp['total_submitted']);
            if ($submitted == 0) $submitted = 1; // avoid division by zero
            $correct = $submitted - intval($emp['total_errors']);
            if ($correct < 0) $correct = 0;
            $emp['accuracy'] = round(($correct / $submitted) * 100);
            $emp['correct_records'] = $correct;
        }

        echo json_encode($employees);
    }

    public function errors() {
        AuthMiddleware::requireLogin();
        
        $user = $this->getCurrentUser();
        $employee_id = $_GET['employee_id'] ?? null;
        $status = $_GET['status'] ?? null;
        $date = $_GET['date'] ?? date('Y-m-d');
        
        $query = "
            SELECT a.*, u.name as submitter_name, u.role as submitter_role 
            FROM audit_reports a
            JOIN users u ON a.employee_id = u.id
            WHERE DATE(a.created_at) = ?
        ";
        $params = [$date];

        if ($user['role'] !== 'admin' && $user['role'] !== 'manager') {
            $query .= " AND a.employee_id = ?";
            $params[] = $user['user_id'] ?? $user['id'];
        } else if ($employee_id) {
            $query .= " AND a.employee_id = ?";
            $params[] = $employee_id;
        }

        if ($status) {
            $query .= " AND a.status = ?";
            $params[] = $status;
        }

        $query .= " ORDER BY a.created_at DESC";

        $stmt = $this->db->prepare($query);
        $stmt->execute($params);
        $errors = $stmt->fetchAll(PDO::FETCH_ASSOC);

        echo json_encode($errors);
    }

    public function activities() {
        AuthMiddleware::requireLogin();
        
        $employee_id = $_GET['employee_id'] ?? null;
        $date = $_GET['date'] ?? date('Y-m-d');
        
        if (!$employee_id) {
            echo json_encode([]);
            return;
        }

        $stmt = $this->db->prepare("
            SELECT * FROM activity_logs 
            WHERE user_id = ? AND DATE(created_at) = ?
            ORDER BY created_at DESC
        ");
        $stmt->execute([$employee_id, $date]);
        
        echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
    }

    public function errorHistory($id) {
        AuthMiddleware::requireLogin();
        $stmt = $this->db->prepare("SELECT t.*, u.name as user_name FROM audit_trail t JOIN users u ON t.user_id = u.id WHERE t.audit_report_id = ? ORDER BY t.created_at ASC");
        $stmt->execute([$id]);
        echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
    }

    public function fixError($id) {
        AuthMiddleware::requireLogin();

        $newValue = '';
        $comment = 'Fixed missing value.';
        $applyToRecord = true;

        if (isset($_SERVER["CONTENT_TYPE"]) && strpos($_SERVER["CONTENT_TYPE"], "multipart/form-data") !== false) {
            $newValue = $_POST['new_value'] ?? '';
            $comment = $_POST['comment'] ?? 'Fixed missing value.';
            $applyToRecord = isset($_POST['apply_to_record']) ? filter_var($_POST['apply_to_record'], FILTER_VALIDATE_BOOLEAN) : true;

            if (isset($_FILES['file']) && $_FILES['file']['error'] === UPLOAD_ERR_OK) {
                $uploadDir = __DIR__ . '/../uploads/quality/';
                if (!is_dir($uploadDir)) {
                    mkdir($uploadDir, 0777, true);
                }
                $fileName = time() . '_' . basename($_FILES['file']['name']);
                if (move_uploaded_file($_FILES['file']['tmp_name'], $uploadDir . $fileName)) {
                    $newValue = 'uploads/quality/' . $fileName;
                }
            }
        } else {
            $data = json_decode(file_get_contents("php://input"), true);
            $newValue = $data['new_value'] ?? '';
            $comment = $data['comment'] ?? 'Fixed missing value.';
            $applyToRecord = $data['apply_to_record'] ?? true;
        }

        $stmt = $this->db->prepare("SELECT * FROM audit_reports WHERE id = ?");
        $stmt->execute([$id]);
        $report = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$report) {
            http_response_code(404);
            echo json_encode(['error' => 'Report not found']);
            return;
        }

        $stmtUpdate = $this->db->prepare("UPDATE audit_reports SET status = 'Pending Review', updated_at = NOW() WHERE id = ?");
        $stmtUpdate->execute([$id]);

        $engine = new DataQualityEngine();
        $engine->logTrail($id, $_SESSION['user_id'], 'Submit Fix', $report['actual_value'], $newValue, $comment);

        // Normally, here you would also update the actual table value, but since the engine is abstract,
        // we assume the user already updated the real record via the actual module UI, OR we apply it here:
        if ($applyToRecord) {
            $stmtTable = $this->db->prepare("UPDATE `{$report['table_name']}` SET `{$report['field_name']}` = ? WHERE id = ?");
            $stmtTable->execute([$newValue, $report['record_id']]);
            
            // Fetch updated record and update json
            $stmtRec = $this->db->prepare("SELECT * FROM `{$report['table_name']}` WHERE id = ?");
            $stmtRec->execute([$report['record_id']]);
            $recData = $stmtRec->fetch(PDO::FETCH_ASSOC);
            
            $stmtUpdateJson = $this->db->prepare("UPDATE audit_reports SET actual_value = ?, full_record_json = ? WHERE id = ?");
            $stmtUpdateJson->execute([$newValue, json_encode($recData), $id]);
        }

        echo json_encode(['message' => 'Fix submitted for review.']);
    }

    public function action($id) {
        AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        $action = $data['action'] ?? null;
        $comment = $data['comment'] ?? '';

        if (!$action) {
            http_response_code(400);
            echo json_encode(['error' => 'Action required']);
            return;
        }

        $validStatuses = [
            'approve' => 'Resolved',
            'reject' => 'Open',
            'assign' => 'Assigned',
            'notify' => 'Open' // Keeps open but logs notification
        ];

        if (!isset($validStatuses[$action])) {
            http_response_code(400);
            echo json_encode(['error' => 'Invalid action']);
            return;
        }

        $newStatus = $validStatuses[$action];

        $stmtUpdate = $this->db->prepare("UPDATE audit_reports SET status = ?, updated_at = NOW() WHERE id = ?");
        $stmtUpdate->execute([$newStatus, $id]);

        $engine = new DataQualityEngine();
        $engine->logTrail($id, $_SESSION['user_id'], ucfirst($action), '', '', $comment);

        echo json_encode(['message' => "Action $action completed. Status is now $newStatus."]);
    }

    public function analytics() {
        AuthMiddleware::requireLogin();
        
        $user = $this->getCurrentUser();
        $date = $_GET['date'] ?? date('Y-m-d');
        
        $baseWhere = "WHERE DATE(created_at) = :date";
        $params = ['date' => $date];

        if ($user['role'] !== 'admin' && $user['role'] !== 'manager') {
            $baseWhere .= " AND employee_id = :user_id";
            $params['user_id'] = $user['user_id'] ?? $user['id'];
        }

        $stmtTotal = $this->db->prepare("SELECT COUNT(*) FROM audit_reports $baseWhere");
        $stmtTotal->execute($params);
        $totalErrors = $stmtTotal->fetchColumn();

        $stmtOpen = $this->db->prepare("SELECT COUNT(*) FROM audit_reports $baseWhere AND status = 'Open'");
        $stmtOpen->execute($params);
        $openErrors = $stmtOpen->fetchColumn();

        $stmtResolved = $this->db->prepare("SELECT COUNT(*) FROM audit_reports $baseWhere AND status = 'Resolved'");
        $stmtResolved->execute($params);
        $resolvedErrors = $stmtResolved->fetchColumn();

        $stats = [
            'total_errors' => $totalErrors,
            'open_errors' => $openErrors,
            'resolved_errors' => $resolvedErrors,
        ];

        $stmtTopModules = $this->db->prepare("SELECT module_name, COUNT(*) as count FROM audit_reports $baseWhere GROUP BY module_name ORDER BY count DESC LIMIT 5");
        $stmtTopModules->execute($params);
        $stats['top_modules'] = $stmtTopModules->fetchAll(PDO::FETCH_ASSOC);

        $stmtTopProblems = $this->db->prepare("SELECT problem_type, COUNT(*) as count FROM audit_reports $baseWhere GROUP BY problem_type ORDER BY count DESC");
        $stmtTopProblems->execute($params);
        $stats['top_problems'] = $stmtTopProblems->fetchAll(PDO::FETCH_ASSOC);

        $stmtTopFields = $this->db->prepare("SELECT field_name, COUNT(*) as count FROM audit_reports $baseWhere GROUP BY field_name ORDER BY count DESC LIMIT 5");
        $stmtTopFields->execute($params);
        $stats['top_fields'] = $stmtTopFields->fetchAll(PDO::FETCH_ASSOC);

        echo json_encode($stats);
    }
    public function scan() {
        AuthMiddleware::requireLogin();
        $engine = new DataQualityEngine();
        $result = $engine->runScheduledScan();
        echo json_encode(['message' => 'Scan completed', 'details' => $result]);
    }
}
