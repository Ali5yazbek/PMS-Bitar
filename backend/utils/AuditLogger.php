<?php
class AuditLogger {
    public static function log($action, $entity_type, $entity_id, $details = null) {
        try {
            $db = Database::getInstance()->getConnection();
            $user_id = AuthMiddleware::requireLogin()['user_id'];
            
            $stmt = $db->prepare("INSERT INTO audit_logs (user_id, action, entity_type, entity_id, details) VALUES (?, ?, ?, ?, ?)");
            $stmt->execute([$user_id, $action, $entity_type, $entity_id, $details]);
        } catch (Exception $e) {
            // Silently fail or handle error. We don't want audit failure to break the main transaction usually, 
            // but it's best effort.
            error_log("Audit Logger Error: " . $e->getMessage());
        }
    }
}
