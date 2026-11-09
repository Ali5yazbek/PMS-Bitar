<?php
/**
 * Device (FCM token) registry. Every request is authenticated; a user can only touch their own devices.
 * Authentication itself stays in PHP/JWT - Firebase is used purely as the delivery channel.
 */
class DevicesController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    private function input(): array {
        $raw = json_decode(file_get_contents('php://input'), true);
        return is_array($raw) ? $raw : $_POST;
    }

    /** POST /api/devices/register  {device_id, fcm_token, platform, app_version?, device_model?} */
    public function register() {
        $user = AuthMiddleware::requireLogin();
        $userId = (int)($user['user_id'] ?? $user['id'] ?? 0);
        $in = $this->input();

        $deviceId = trim((string)($in['device_id'] ?? ''));
        $token = trim((string)($in['fcm_token'] ?? ''));
        $platform = strtolower((string)($in['platform'] ?? 'android'));
        if (!in_array($platform, ['android', 'ios', 'web'], true)) $platform = 'android';

        if (!$userId || strlen($deviceId) < 8 || strlen($deviceId) > 80 || !preg_match('/^[A-Za-z0-9_\-:.]+$/', $deviceId)
            || strlen($token) < 20 || strlen($token) > 512) {
            http_response_code(422);
            echo json_encode(['success' => false, 'error' => 'Invalid device registration payload']);
            return;
        }
        $version = substr((string)($in['app_version'] ?? ''), 0, 30) ?: null;
        $model = substr((string)($in['device_model'] ?? ''), 0, 80) ?: null;

        try {
            $this->upsert($userId, $deviceId, $token, $platform, $version, $model);
        } catch (PDOException $e) {
            if (in_array($e->getCode(), ['42S02', '42S22'], true)) {
                PushSchema::ensure($this->db);
                $this->upsert($userId, $deviceId, $token, $platform, $version, $model);
            } else {
                http_response_code(500);
                echo json_encode(['success' => false, 'error' => 'Could not register device']);
                return;
            }
        }
        echo json_encode(['success' => true]);
    }

    private function upsert(int $userId, string $deviceId, string $token, string $platform, ?string $version, ?string $model): void {
        $this->db->beginTransaction();
        try {
            // A token identifies one physical install: if another account used it before, detach it.
            $this->db->prepare("UPDATE user_devices SET status = 'inactive' WHERE fcm_token = ? AND NOT (user_id = ? AND device_id = ?)")
                     ->execute([$token, $userId, $deviceId]);
            $this->db->prepare("INSERT INTO user_devices (user_id, device_id, fcm_token, platform, app_version, device_model, status, last_active_at)
                                VALUES (?, ?, ?, ?, ?, ?, 'active', NOW())
                                ON DUPLICATE KEY UPDATE fcm_token = VALUES(fcm_token), platform = VALUES(platform),
                                    app_version = VALUES(app_version), device_model = VALUES(device_model),
                                    status = 'active', last_active_at = NOW()")
                     ->execute([$userId, $deviceId, $token, $platform, $version, $model]);
            $this->db->commit();
        } catch (Throwable $e) {
            if ($this->db->inTransaction()) $this->db->rollBack();
            throw $e;
        }
    }

    /** POST /api/devices/unregister  {device_id}  - called on logout; deactivates this device for this user only. */
    public function unregister() {
        $user = AuthMiddleware::requireLogin();
        $userId = (int)($user['user_id'] ?? $user['id'] ?? 0);
        $in = $this->input();
        $deviceId = trim((string)($in['device_id'] ?? ''));
        if (!$userId || $deviceId === '') {
            http_response_code(422);
            echo json_encode(['success' => false, 'error' => 'device_id required']);
            return;
        }
        try {
            $this->db->prepare("UPDATE user_devices SET status = 'inactive' WHERE user_id = ? AND device_id = ?")
                     ->execute([$userId, $deviceId]);
        } catch (PDOException $e) { /* table not migrated yet: nothing to deactivate */ }
        echo json_encode(['success' => true]);
    }
}

