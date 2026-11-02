<?php
class UsersController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    private function requireAdmin() {
        AuthMiddleware::requireLogin();
        // Check if user is admin
        $headers = getallheaders();
        $authHeader = isset($headers['Authorization']) ? $headers['Authorization'] : '';
        if ($authHeader) {
            $token = str_replace('Bearer ', '', $authHeader);
            $decoded = JWT::decode($token);
            if ($decoded && isset($decoded['role']) && $decoded['role'] !== 'admin') {
                http_response_code(403);
                echo json_encode(['error' => 'Forbidden: Only admins can perform this action.']);
                exit();
            }
        } else {
             // Fallback if no header (AuthMiddleware should have caught it, but just in case)
             http_response_code(401);
             echo json_encode(['error' => 'Unauthorized']);
             exit();
        }
    }

    public function index() {
        $this->requireAdmin();
        
        $stmt = $this->db->query("SELECT id, name, username, email, role, phone, national_id, created_at FROM users ORDER BY created_at DESC");
        echo json_encode($stmt->fetchAll());
    }

    public function store() {
        $this->requireAdmin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        if (empty($data['name']) || empty($data['email']) || empty($data['password']) || empty($data['role'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Missing required fields']);
            return;
        }

        // Check if email exists
        $checkStmt = $this->db->prepare("SELECT id FROM users WHERE email = ?");
        $checkStmt->execute([$data['email']]);
        if ($checkStmt->fetch()) {
            http_response_code(400);
            echo json_encode(['error' => 'Email already exists']);
            return;
        }

        $hashedPassword = password_hash($data['password'], PASSWORD_DEFAULT);

        $phone = isset($data['phone']) ? $data['phone'] : null;
        $national_id = isset($data['national_id']) ? $data['national_id'] : null;
        $username = isset($data['username']) && $data['username'] !== '' ? $data['username'] : null;

        $stmt = $this->db->prepare("INSERT INTO users (name, username, email, password, role, phone, national_id) VALUES (?, ?, ?, ?, ?, ?, ?)");
        
        try {
            $stmt->execute([$data['name'], $username, $data['email'], $hashedPassword, $data['role'], $phone, $national_id]);
            $id = $this->db->lastInsertId();
            
            AuditLogger::log('CREATE', 'User', $id, "Created user account: {$data['email']} with role {$data['role']}");
            
            echo json_encode(['message' => 'User created successfully', 'id' => $id]);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => 'Database error: ' . $e->getMessage()]);
        }
    }

    public function update($id) {
        $this->requireAdmin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        if (empty($data['name']) || empty($data['email']) || empty($data['role'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Missing required fields']);
            return;
        }

        // Check if email exists for other users
        $checkStmt = $this->db->prepare("SELECT id FROM users WHERE email = ? AND id != ?");
        $checkStmt->execute([$data['email'], $id]);
        if ($checkStmt->fetch()) {
            http_response_code(400);
            echo json_encode(['error' => 'Email already exists for another user']);
            return;
        }

        $phone = isset($data['phone']) ? $data['phone'] : null;
        $national_id = isset($data['national_id']) ? $data['national_id'] : null;
        $username = isset($data['username']) && $data['username'] !== '' ? $data['username'] : null;

        try {
            if (!empty($data['password'])) {
                // Update with new password
                $hashedPassword = password_hash($data['password'], PASSWORD_DEFAULT);
                $stmt = $this->db->prepare("UPDATE users SET name = ?, username = ?, email = ?, password = ?, role = ?, phone = ?, national_id = ? WHERE id = ?");
                $stmt->execute([$data['name'], $username, $data['email'], $hashedPassword, $data['role'], $phone, $national_id, $id]);
            } else {
                // Update without changing password
                $stmt = $this->db->prepare("UPDATE users SET name = ?, username = ?, email = ?, role = ?, phone = ?, national_id = ? WHERE id = ?");
                $stmt->execute([$data['name'], $username, $data['email'], $data['role'], $phone, $national_id, $id]);
            }
            
            AuditLogger::log('UPDATE', 'User', $id, "Updated user account: {$data['email']}");
            
            echo json_encode(['message' => 'User updated successfully']);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => 'Database error: ' . $e->getMessage()]);
        }
    }

    public function destroy($id) {
        $this->requireAdmin();
        
        // Prevent deleting oneself or the primary admin to be safe
        // (Assuming admin id 1 is the default primary)
        if ($id == 1) {
             http_response_code(403);
             echo json_encode(['error' => 'Cannot delete the primary admin account']);
             return;
        }

        try {
            $stmt = $this->db->prepare("DELETE FROM users WHERE id = ?");
            $stmt->execute([$id]);
            
            AuditLogger::log('DELETE', 'User', $id, "Deleted user account ID: {$id}");
            
            echo json_encode(['message' => 'User deleted successfully']);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => 'Database error: ' . $e->getMessage()]);
        }
    }
    public function updateLanguage() {
        AuthMiddleware::requireLogin();
        $headers = getallheaders();
        $authHeader = isset($headers['Authorization']) ? $headers['Authorization'] : '';
        if (!$authHeader) {
            http_response_code(401);
            echo json_encode(['error' => 'Unauthorized']);
            exit();
        }
        $token = str_replace('Bearer ', '', $authHeader);
        $decoded = JWT::decode($token);
        $userId = $decoded['id'];

        $data = json_decode(file_get_contents("php://input"), true);
        $lang = $data['preferred_language'] ?? 'en';

        try {
            $stmt = $this->db->prepare("UPDATE users SET preferred_language = ? WHERE id = ?");
            $stmt->execute([$lang, $userId]);
            echo json_encode(['message' => 'Language preference updated']);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => 'Database error: ' . $e->getMessage()]);
        }
    }
}
