<?php
class SettingsController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function getRates() {
        AuthMiddleware::requireLogin();
        $stmt = $this->db->query("SELECT * FROM estimation_rates ORDER BY category, item_name");
        echo json_encode($stmt->fetchAll());
    }

    public function updateRate($id) {
        AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        try {
            $stmt = $this->db->prepare("UPDATE estimation_rates SET item_name = ?, unit = ?, default_price = ? WHERE id = ?");
            $stmt->execute([$data['item_name'], $data['unit'], $data['default_price'], $id]);
            echo json_encode(['message' => 'Rate updated successfully']);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function addRate() {
        AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        try {
            $stmt = $this->db->prepare("INSERT INTO estimation_rates (item_name, category, unit, default_price) VALUES (?, ?, ?, ?)");
            $stmt->execute([$data['item_name'], $data['category'], $data['unit'], $data['default_price']]);
            echo json_encode(['id' => $this->db->lastInsertId(), 'message' => 'Rate added successfully']);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function deleteRate($id) {
        AuthMiddleware::requireLogin();
        try {
            $stmt = $this->db->prepare("DELETE FROM estimation_rates WHERE id = ?");
            $stmt->execute([$id]);
            echo json_encode(['message' => 'Rate deleted successfully']);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }
}
