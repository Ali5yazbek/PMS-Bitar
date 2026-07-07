<?php
class NotificationsController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function getUnread() {
        AuthMiddleware::requireLogin();
        
        $headers = getallheaders();
        $token = str_replace('Bearer ', '', $headers['Authorization'] ?? '');
        $user = JWT::decode($token);
        $user_id = $user['user_id'];
        
        $stmt = $this->db->prepare("
            SELECT * FROM notifications 
            WHERE user_id = ? AND is_read = 0
            ORDER BY created_at DESC
        ");
        $stmt->execute([$user_id]);
        
        echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
    }
    
    public function markAsRead($id) {
        AuthMiddleware::requireLogin();
        
        $headers = getallheaders();
        $token = str_replace('Bearer ', '', $headers['Authorization'] ?? '');
        $user = JWT::decode($token);
        $user_id = $user['user_id'];
        
        $stmt = $this->db->prepare("UPDATE notifications SET is_read = 1 WHERE id = ? AND user_id = ?");
        $stmt->execute([$id, $user_id]);
        
        echo json_encode(['message' => 'Notification marked as read.']);
    }
}
