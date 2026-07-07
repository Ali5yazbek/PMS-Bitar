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
}
