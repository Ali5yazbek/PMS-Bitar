<?php
namespace Core;

use Core\Database;

class NotificationManager {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Send a notification using a database template
     */
    public function sendFromTemplate($templateCode, $userId, $variables = [], $deliveryChannel = 'Database') {
        try {
            $stmt = $this->db->prepare("SELECT title_template, message_template, type FROM notification_templates WHERE code = ?");
            $stmt->execute([$templateCode]);
            $template = $stmt->fetch(\PDO::FETCH_ASSOC);

            if (!$template) {
                error_log("Notification Template Not Found: " . $templateCode);
                return false;
            }

            $title = $this->replaceVariables($template['title_template'], $variables);
            $message = $this->replaceVariables($template['message_template'], $variables);

            $stmt = $this->db->prepare("
                INSERT INTO notifications (user_id, title, message, type, delivery_channel, delivery_status) 
                VALUES (?, ?, ?, ?, ?, 'Pending')
            ");
            $stmt->execute([$userId, $title, $message, $template['type'], $deliveryChannel]);
            $notificationId = $this->db->lastInsertId();

            // Trigger real remote FCM push notification via PushNotificationService
            if (class_exists('\PushNotificationService')) {
                \PushNotificationService::kickAfterResponse();
            }
            $this->updateDeliveryStatus($notificationId, 'Delivered');

            return true;
        } catch (\Exception $e) {
            error_log("Failed to send notification: " . $e->getMessage());
            return false;
        }
    }

    private function replaceVariables($template, $variables) {
        foreach ($variables as $key => $value) {
            $template = str_replace('{{' . $key . '}}', $value, $template);
        }
        return $template;
    }

    private function updateDeliveryStatus($notificationId, $status) {
        $stmt = $this->db->prepare("UPDATE notifications SET delivery_status = ? WHERE id = ?");
        $stmt->execute([$status, $notificationId]);
    }
}
