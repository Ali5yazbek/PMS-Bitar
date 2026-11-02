<?php
class NotificationsController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function getUnread() {
        $user = AuthMiddleware::requireLogin();
        $user_id = $user['user_id'] ?? $user['id'] ?? null;

        if (!$user_id) {
            echo json_encode([]);
            return;
        }

        try {
            $stmt = $this->db->prepare("
                SELECT * FROM notifications 
                WHERE user_id = ? AND (is_read = 0 OR is_read IS NULL)
                ORDER BY created_at DESC
            ");
            $stmt->execute([$user_id]);
            echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function markAsRead($id) {
        $user = AuthMiddleware::requireLogin();
        $user_id = $user['user_id'] ?? $user['id'] ?? null;

        if (!$user_id) {
            http_response_code(400);
            echo json_encode(['error' => 'Invalid user session']);
            return;
        }

        try {
            $stmt = $this->db->prepare("UPDATE notifications SET is_read = 1 WHERE id = ? AND user_id = ?");
            $stmt->execute([$id, $user_id]);
            echo json_encode(['message' => 'Notification marked as read.']);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }
}
