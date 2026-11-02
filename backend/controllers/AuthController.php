<?php
class AuthController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function login() {
        $data = json_decode(file_get_contents("php://input"), true);
        $identifier = $data['loginIdentifier'] ?? $data['email'] ?? null;
        if (!$identifier || !isset($data['password'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Email/Username and password are required']);
            return;
        }

        $stmt = $this->db->prepare("SELECT * FROM users WHERE email = ? OR username = ?");
        $stmt->execute([$identifier, $identifier]);
        $user = $stmt->fetch();

        if ($user && password_verify($data['password'], $user['password'])) {
            $payload = [
                'user_id' => $user['id'],
                'role' => $user['role'],
                'name' => $user['name']
            ];
            $token = JWT::encode($payload);
            unset($user['password']);

            // Fetch global settings like exchange rate
            $settingsStmt = $this->db->query("SELECT setting_value FROM global_settings WHERE setting_key = 'usd_to_cfa'");
            $usdToCfa = 600; // default fallback
            if ($row = $settingsStmt->fetch()) {
                $usdToCfa = (float)$row['setting_value'];
            }

            echo json_encode([
                'success' => true, 
                'token' => $token, 
                'user' => $user,
                'settings' => [
                    'exchange_rate' => $usdToCfa
                ]
            ]);
        } else {
            http_response_code(401);
            echo json_encode(['error' => 'Invalid username, email, or password']);
        }
    }

    public function me() {
        $token = JWT::getBearerToken();
        if (!$token) {
            http_response_code(401);
            echo json_encode(['error' => 'No token provided']);
            return;
        }

        $decoded = JWT::decode($token);
        if (!$decoded) {
            http_response_code(401);
            echo json_encode(['error' => 'Invalid or expired token']);
            return;
        }

        $stmt = $this->db->prepare("SELECT id, name, email, role FROM users WHERE id = ?");
        $stmt->execute([$decoded['user_id']]);
        $user = $stmt->fetch();

        if ($user) {
            // Fetch global settings like exchange rate
            $settingsStmt = $this->db->query("SELECT setting_value FROM global_settings WHERE setting_key = 'usd_to_cfa'");
            $usdToCfa = 600; // default fallback
            if ($row = $settingsStmt->fetch()) {
                $usdToCfa = (float)$row['setting_value'];
            }

            echo json_encode([
                'user' => $user,
                'settings' => [
                    'exchange_rate' => $usdToCfa
                ]
            ]);
        } else {
            http_response_code(404);
            echo json_encode(['error' => 'User not found']);
        }
    }
}
