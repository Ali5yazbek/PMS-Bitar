<?php
class AuditLogger {
    public static function log($action, $entity_type, $entity_id, $details = null) {
        try {
            $db = Database::getInstance()->getConnection();
            $user_id = null;
            $user_name = null;
            $role = null;
            $department = null;

            // Try to get user from auth middleware if running in web context
            if (class_exists('JWT')) {
                try {
                    $token = JWT::getBearerToken();
                    if ($token) {
                        $user = JWT::decode($token);
                        if ($user && isset($user['user_id'])) {
                            $user_id = $user['user_id'];
                        } elseif (is_object($user) && isset($user->id)) {
                            $user_id = $user->id;
                        }
                    }
                } catch (Exception $e) {}
            }
                        // Fetch full details
                        if ($user_id) {
                            $stmt = $db->prepare("SELECT full_name, role, department FROM users WHERE id = ?");
                            $stmt->execute([$user_id]);
                            $u = $stmt->fetch(PDO::FETCH_ASSOC);
                            if ($u) {
                                $user_name = $u['full_name'];
                                $role = $u['role'];
                                $department = $u['department'];
                            }
                        }

            // Fallback for cron/system
            if (!$user_id) {
                $user_name = 'System';
                $role = 'system';
            }

            // 1. Log to unified activity_logs
            $stmt = $db->prepare("INSERT INTO activity_logs (user_id, action, entity_type, entity_id, details) VALUES (?, ?, ?, ?, ?)");
            $stmt->execute([$user_id, $action, $entity_type, $entity_id, $details]);

            // 2. Log to new enterprise_activity_log
            $ip = $_SERVER['HTTP_CLIENT_IP'] ?? $_SERVER['HTTP_X_FORWARDED_FOR'] ?? $_SERVER['REMOTE_ADDR'] ?? 'Unknown';
            $ua = $_SERVER['HTTP_USER_AGENT'] ?? 'Unknown';

            $stmt2 = $db->prepare("
                INSERT INTO enterprise_activity_log 
                (user_id, user_name, role, department, action, module, record_id, description, ip_address, device_info)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ");
            $stmt2->execute([
                $user_id, $user_name, $role, $department, 
                $action, $entity_type, $entity_id, $details, 
                $ip, $ua
            ]);

        } catch (Exception $e) {
            error_log("Audit Logger Error: " . $e->getMessage());
        }
    }
}
