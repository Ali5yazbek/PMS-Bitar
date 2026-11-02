<?php
class GlobalSettingsController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function index() {
        AuthMiddleware::requireLogin();
        $stmt = $this->db->query("SELECT setting_key, setting_value FROM global_settings");
        $settings = [];
        while ($row = $stmt->fetch()) {
            $settings[$row['setting_key']] = $row['setting_value'];
        }
        echo json_encode($settings);
    }

    public function update($key) {
        AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        if (!isset($data['value'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Value is required']);
            return;
        }
        
        try {
            $stmt = $this->db->prepare("INSERT INTO global_settings (setting_key, setting_value) VALUES (?, ?) ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value)");
            $stmt->execute([$key, $data['value']]);
            echo json_encode(['message' => 'Setting updated successfully']);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function updateBulk() {
        AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        if (!is_array($data) || empty($data)) {
            http_response_code(400);
            echo json_encode(['error' => 'Valid payload required']);
            return;
        }
        
        try {
            $this->db->beginTransaction();
            $stmt = $this->db->prepare("INSERT INTO global_settings (setting_key, setting_value) VALUES (?, ?) ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value)");
            foreach ($data as $key => $value) {
                // Ensure value is a string or castable to string
                $stmt->execute([$key, (string)$value]);
            }
            $this->db->commit();
            echo json_encode(['message' => 'Settings updated successfully']);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function uploadLogo() {
        AuthMiddleware::requireLogin();
        
        if (!isset($_FILES['logo']) || $_FILES['logo']['error'] !== UPLOAD_ERR_OK) {
            http_response_code(400);
            echo json_encode(['error' => 'No file uploaded or upload error']);
            return;
        }
        
        $file = $_FILES['logo'];
        $allowedTypes = ['image/jpeg', 'image/png', 'image/svg+xml'];
        
        if (!in_array($file['type'], $allowedTypes)) {
            http_response_code(400);
            echo json_encode(['error' => 'Invalid file type. Only JPG, PNG, and SVG are allowed.']);
            return;
        }
        
        $maxSize = 5 * 1024 * 1024; // 5MB
        if ($file['size'] > $maxSize) {
            http_response_code(400);
            echo json_encode(['error' => 'File is too large. Maximum size is 5MB.']);
            return;
        }
        
        $uploadDir = __DIR__ . '/../uploads/branding/';
        if (!is_dir($uploadDir)) {
            mkdir($uploadDir, 0777, true);
        }
        
        $extension = pathinfo($file['name'], PATHINFO_EXTENSION);
        $filename = 'company_logo_' . time() . '.' . $extension;
        $destination = $uploadDir . $filename;
        
        if (move_uploaded_file($file['tmp_name'], $destination)) {
            $logoUrl = '/uploads/branding/' . $filename;
            
            try {
                $stmt = $this->db->prepare("INSERT INTO global_settings (setting_key, setting_value) VALUES ('company_logo', ?) ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value)");
                $stmt->execute([$logoUrl]);
                echo json_encode(['message' => 'Logo uploaded successfully', 'logo_url' => $logoUrl]);
            } catch (Exception $e) {
                http_response_code(500);
                echo json_encode(['error' => 'Database error: ' . $e->getMessage()]);
            }
        } else {
            http_response_code(500);
            echo json_encode(['error' => 'Failed to save uploaded file']);
        }
    }
}
