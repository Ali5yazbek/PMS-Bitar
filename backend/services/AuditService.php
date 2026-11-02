<?php
/**
 * AuditService.php
 * Generic activity logging for every module in the system.
 * Writes to activity_log table with full context: user, IP, device, before/after values.
 */
class AuditService {
    private PDO $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Log any action in the system.
     *
     * @param string $module       e.g. 'electricity', 'generator', 'fuel', 'maintenance'
     * @param string $recordType   e.g. 'meter_reading', 'subscription_reading'
     * @param int    $recordId     Primary key of the record
     * @param string $action       e.g. 'submitted', 'approved', 'rejected', 'edited', 'versioned'
     * @param mixed  $oldValue     Scalar or array (will be JSON-encoded if array)
     * @param mixed  $newValue     Scalar or array
     * @param string $reason       Human-readable reason for the action
     * @param string $severity     'info' | 'warning' | 'critical'
     * @param int|null $userId     Override user ID (auto-detected from JWT if null)
     */
    public function log(
        string $module,
        string $recordType,
        int $recordId,
        string $action,
        mixed $oldValue = null,
        mixed $newValue = null,
        string $reason = '',
        string $severity = 'info',
        ?int $userId = null
    ): int {
        $user = $this->resolveUser($userId);

        $oldJson = is_array($oldValue) ? json_encode($oldValue, JSON_UNESCAPED_UNICODE) : (string)($oldValue ?? '');
        $newJson = is_array($newValue) ? json_encode($newValue, JSON_UNESCAPED_UNICODE) : (string)($newValue ?? '');

        $ip  = $_SERVER['HTTP_CLIENT_IP'] ?? $_SERVER['HTTP_X_FORWARDED_FOR'] ?? $_SERVER['REMOTE_ADDR'] ?? 'unknown';
        $ua  = $_SERVER['HTTP_USER_AGENT'] ?? 'unknown';

        $stmt = $this->db->prepare("
            INSERT INTO activity_log
                (module, record_type, record_id, action, old_value, new_value,
                 user_id, user_name, user_role, ip_address, device, reason, severity)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ");
        try {
            $stmt->execute([
                $module, $recordType, $recordId, $action,
                $oldJson ?: null, $newJson ?: null,
                $user['id'], $user['name'], $user['role'],
                $ip, $ua,
                $reason ?: null,
                $severity
            ]);
            return (int)$this->db->lastInsertId();
        } catch (PDOException $e) {
            // Never let audit logging crash the main action
            return 0;
        }
    }

    /**
     * Get full lifecycle timeline for a record.
     * Returns entries ordered oldest-first for display.
     */
    public function getTimeline(string $recordType, int $recordId): array {
        try {
            $stmt = $this->db->prepare("
                SELECT al.*, u.name as user_display_name
                FROM activity_log al
                LEFT JOIN users u ON al.user_id = u.id
                WHERE al.record_type = ? AND al.record_id = ?
                ORDER BY al.created_at ASC
            ");
            $stmt->execute([$recordType, $recordId]);
            return $stmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (PDOException $e) {
            return [];
        }
    }

    /**
     * Get recent admin activity feed (last N actions across all modules).
     */
    public function getRecentActivity(int $limit = 50): array {
        try {
            $stmt = $this->db->prepare("
                SELECT al.*, u.name as user_display_name
                FROM activity_log al
                LEFT JOIN users u ON al.user_id = u.id
                WHERE al.action IN ('approved', 'rejected', 'edited', 'bulk_approved', 'bulk_rejected')
                ORDER BY al.created_at DESC
                LIMIT :limit
            ");
            $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
            $stmt->execute();
            return $stmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (PDOException $e) {
            return [];
        }
    }

    /**
     * Detect and resolve current user from JWT or fallback.
     */
    private function resolveUser(?int $overrideId): array {
        if ($overrideId) {
            try {
                $stmt = $this->db->prepare("SELECT id, name, role FROM users WHERE id = ?");
                $stmt->execute([$overrideId]);
                $u = $stmt->fetch(PDO::FETCH_ASSOC);
                if ($u) return $u;
            } catch (Exception $e) {}
        }

        try {
            $token = JWT::getBearerToken();
            if ($token) {
                $decoded = JWT::decode($token);
                if ($decoded && isset($decoded['user_id'])) {
                    $stmt = $this->db->prepare("SELECT id, name, role FROM users WHERE id = ?");
                    $stmt->execute([$decoded['user_id']]);
                    $u = $stmt->fetch(PDO::FETCH_ASSOC);
                    if ($u) return $u;
                }
            }
        } catch (Exception $e) {}

        return ['id' => null, 'name' => 'System', 'role' => 'system'];
    }
}
