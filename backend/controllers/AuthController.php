<?php
class AuthController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    private function resolveUserRole(array $user): string {
        $r = strtolower(trim($user['role'] ?? ''));
        if ($r !== '' && $r !== '0') {
            return $r;
        }

        $id = (int)($user['id'] ?? 0);
        $username = strtolower(trim($user['username'] ?? ''));
        $email = strtolower(trim($user['email'] ?? ''));

        if ($id === 1 || $username === 'admin' || strpos($email, 'admin@') !== false) {
            $resolved = 'admin';
        } elseif ($id === 5 || strpos($username, 'hassan') !== false || strpos($email, 'hassan') !== false || strpos($email, 'agent') !== false) {
            $resolved = 'agent';
        } elseif (in_array($id, [2, 6], true) || strpos($username, 'milad') !== false || strpos($username, 'mohamad') !== false) {
            $resolved = 'maintenance';
        } elseif ($id === 3 || strpos($username, 'cashier') !== false || strpos($username, 'dwdw') !== false) {
            $resolved = 'cashier';
        } else {
            $resolved = 'tenant';
        }

        try {
            $this->db->prepare("UPDATE users SET role = ? WHERE id = ?")->execute([$resolved, $id]);
        } catch (Throwable $e) {}

        return $resolved;
    }

    private function ensureRefreshTable(): void {
        try {
            if (class_exists('PushSchema')) {
                PushSchema::ensure($this->db);
            }
            $this->db->exec("CREATE TABLE IF NOT EXISTS user_refresh_tokens (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_id INT NOT NULL,
                token_hash VARCHAR(64) NOT NULL,
                device_id VARCHAR(80) NULL,
                platform VARCHAR(20) NULL,
                expires_at DATETIME NOT NULL,
                revoked TINYINT(1) NOT NULL DEFAULT 0,
                last_used_at DATETIME NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                UNIQUE KEY uq_refresh_hash (token_hash),
                KEY idx_refresh_user (user_id, revoked)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
        } catch (Throwable $e) {}
    }

    private function issueRefreshToken(int $userId, ?string $deviceId = null, ?string $platform = null): string {
        $this->ensureRefreshTable();
        $rawToken = JWT::generateRefreshToken();
        $hash = hash('sha256', $rawToken);
        $ttl = defined('JWT_REFRESH_EXPIRES_IN') ? (int)JWT_REFRESH_EXPIRES_IN : 315360000;
        $expiresAt = date('Y-m-d H:i:s', time() + $ttl);

        try {
            $stmt = $this->db->prepare("
                INSERT INTO user_refresh_tokens (user_id, token_hash, device_id, platform, expires_at, revoked, last_used_at)
                VALUES (?, ?, ?, ?, ?, 0, NOW())
            ");
            $stmt->execute([$userId, $hash, $deviceId, $platform, $expiresAt]);
        } catch (Throwable $e) {}

        return $rawToken;
    }

    private function getExchangeRate(): float {
        try {
            $settingsStmt = $this->db->query("SELECT setting_value FROM global_settings WHERE setting_key = 'usd_to_cfa'");
            if ($settingsStmt && ($row = $settingsStmt->fetch())) {
                return (float)$row['setting_value'];
            }
        } catch (Throwable $e) {}
        return 600.0;
    }

    public function login() {
        $data = json_decode(file_get_contents("php://input"), true) ?: [];
        $identifier = $data['loginIdentifier'] ?? $data['email'] ?? null;
        if (!$identifier || !isset($data['password'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Email/Username and password are required']);
            return;
        }

        $stmt = $this->db->prepare("SELECT * FROM users WHERE email = ? OR username = ? OR phone = ?");
        $stmt->execute([$identifier, $identifier, $identifier]);
        $user = $stmt->fetch();

        if ($user && password_verify($data['password'], $user['password'])) {
            $user['role'] = $this->resolveUserRole($user);
            $payload = [
                'user_id' => $user['id'],
                'role' => $user['role'],
                'name' => $user['name']
            ];
            $token = JWT::encode($payload);
            $refreshToken = $this->issueRefreshToken(
                (int)$user['id'],
                isset($data['device_id']) ? substr(trim((string)$data['device_id']), 0, 80) : null,
                isset($data['platform']) ? substr(trim((string)$data['platform']), 0, 20) : null
            );
            unset($user['password']);

            $usdToCfa = $this->getExchangeRate();

            echo json_encode([
                'success' => true,
                'token' => $token,
                'refresh_token' => $refreshToken,
                'user' => $user,
                'settings' => [
                    'exchange_rate' => $usdToCfa
                ]
            ]);
        } else {
            http_response_code(401);
            echo json_encode(['error' => 'Invalid username, email, or password']);
        }
    }

    /**
     * POST /api/auth/refresh
     * Exchanges a valid refresh_token (or a cryptographically valid signed JWT during seamless upgrade)
     * for a fresh access token and sliding refresh token without requiring the user to re-enter credentials.
     */
    public function refresh() {
        $this->ensureRefreshTable();
        $data = json_decode(file_get_contents("php://input"), true) ?: [];
        $refreshToken = trim((string)($data['refresh_token'] ?? ''));
        $bearerToken = JWT::getBearerToken();
        $accessToken = trim((string)($data['token'] ?? $bearerToken ?? ''));
        $deviceId = isset($data['device_id']) ? substr(trim((string)$data['device_id']), 0, 80) : null;
        $platform = isset($data['platform']) ? substr(trim((string)$data['platform']), 0, 20) : null;

        $userId = 0;
        $ttl = defined('JWT_REFRESH_EXPIRES_IN') ? (int)JWT_REFRESH_EXPIRES_IN : 315360000;
        $newExpiresAt = date('Y-m-d H:i:s', time() + $ttl);

        if ($refreshToken !== '') {
            $hash = hash('sha256', $refreshToken);
            try {
                $stmt = $this->db->prepare("SELECT id, user_id, revoked, expires_at FROM user_refresh_tokens WHERE token_hash = ? LIMIT 1");
                $stmt->execute([$hash]);
                $row = $stmt->fetch(PDO::FETCH_ASSOC);
                if ($row) {
                    if ((int)$row['revoked'] === 1) {
                        http_response_code(401);
                        echo json_encode(['error' => 'Session has been logged out or revoked', 'revoked' => true]);
                        return;
                    }
                    if (strtotime($row['expires_at']) > time()) {
                        $userId = (int)$row['user_id'];
                        $this->db->prepare("UPDATE user_refresh_tokens SET expires_at = ?, last_used_at = NOW(), device_id = COALESCE(?, device_id), platform = COALESCE(?, platform) WHERE id = ?")
                                 ->execute([$newExpiresAt, $deviceId, $platform, $row['id']]);
                    } else {
                        http_response_code(401);
                        echo json_encode(['error' => 'Refresh token expired', 'revoked' => true]);
                        return;
                    }
                }
            } catch (Throwable $e) {}
        }

        // Seamless migration fallback for sessions created before refresh_token was introduced:
        // Verify HMAC-SHA256 signature of the access JWT (even if its 24h exp passed) and check it was not revoked.
        if ($userId <= 0) {
            $candidateJwt = $accessToken !== '' ? $accessToken : $refreshToken;
            if ($candidateJwt !== '') {
                $jwtHash = hash('sha256', $candidateJwt);
                try {
                    $revStmt = $this->db->prepare("SELECT revoked FROM user_refresh_tokens WHERE token_hash = ? LIMIT 1");
                    $revStmt->execute([$jwtHash]);
                    $revRow = $revStmt->fetch(PDO::FETCH_ASSOC);
                    if ($revRow && (int)$revRow['revoked'] === 1) {
                        http_response_code(401);
                        echo json_encode(['error' => 'Session has been logged out', 'revoked' => true]);
                        return;
                    }
                } catch (Throwable $e) {}

                $decoded = JWT::decodeIgnoreExpiry($candidateJwt);
                if (is_array($decoded) && !empty($decoded['user_id'])) {
                    $userId = (int)$decoded['user_id'];
                    $refreshToken = $this->issueRefreshToken($userId, $deviceId, $platform);
                }
            }
        }

        if ($userId <= 0) {
            http_response_code(401);
            echo json_encode(['error' => 'Invalid refresh token', 'revoked' => true]);
            return;
        }

        $stmt = $this->db->prepare("SELECT * FROM users WHERE id = ? LIMIT 1");
        $stmt->execute([$userId]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$user) {
            http_response_code(401);
            echo json_encode(['error' => 'User account not found', 'revoked' => true]);
            return;
        }

        $user['role'] = $this->resolveUserRole($user);
        unset($user['password']);

        $payload = [
            'user_id' => $user['id'],
            'role' => $user['role'],
            'name' => $user['name']
        ];
        $newAccessToken = JWT::encode($payload);
        if ($refreshToken === '') {
            $refreshToken = $this->issueRefreshToken($userId, $deviceId, $platform);
        }

        echo json_encode([
            'success' => true,
            'token' => $newAccessToken,
            'refresh_token' => $refreshToken,
            'user' => $user,
            'settings' => [
                'exchange_rate' => $this->getExchangeRate()
            ]
        ]);
    }

    /**
     * POST /api/auth/logout
     * Explicitly revokes the user's refresh token (and access token hash) on manual logout.
     */
    public function logout() {
        $this->ensureRefreshTable();
        $data = json_decode(file_get_contents("php://input"), true) ?: [];
        $refreshToken = trim((string)($data['refresh_token'] ?? ''));
        $bearerToken = JWT::getBearerToken();
        $deviceId = trim((string)($data['device_id'] ?? ''));
        $fcmToken = trim((string)($data['fcm_token'] ?? ''));

        $userId = 0;
        if ($bearerToken) {
            $decoded = JWT::decodeIgnoreExpiry($bearerToken);
            if (is_array($decoded) && !empty($decoded['user_id'])) {
                $userId = (int)$decoded['user_id'];
            }
        }

        try {
            if ($refreshToken !== '') {
                $hash = hash('sha256', $refreshToken);
                $this->db->prepare("UPDATE user_refresh_tokens SET revoked = 1, last_used_at = NOW() WHERE token_hash = ?")
                         ->execute([$hash]);
            }
            if ($bearerToken) {
                $jwtHash = hash('sha256', $bearerToken);
                $this->db->prepare("
                    INSERT INTO user_refresh_tokens (user_id, token_hash, expires_at, revoked, last_used_at)
                    VALUES (?, ?, NOW(), 1, NOW())
                    ON DUPLICATE KEY UPDATE revoked = 1, last_used_at = NOW()
                ")->execute([$userId, $jwtHash]);
            }
            if ($deviceId !== '' && $userId > 0) {
                $this->db->prepare("UPDATE user_devices SET status = 'inactive' WHERE user_id = ? AND device_id = ?")
                         ->execute([$userId, $deviceId]);
            } elseif ($fcmToken !== '') {
                $this->db->prepare("UPDATE user_devices SET status = 'inactive' WHERE fcm_token = ?")
                         ->execute([$fcmToken]);
            }
        } catch (Throwable $e) {}

        echo json_encode(['success' => true]);
    }

    public function me() {
        $token = JWT::getBearerToken();
        if (!$token) {
            http_response_code(401);
            echo json_encode(['error' => 'No token provided']);
            return;
        }

        $decoded = JWT::decode($token);
        if (!$decoded) {
            http_response_code(401);
            echo json_encode(['error' => 'Invalid or expired token']);
            return;
        }

        $stmt = $this->db->prepare("SELECT id, name, email, role FROM users WHERE id = ?");
        $stmt->execute([$decoded['user_id']]);
        $user = $stmt->fetch();

        if ($user) {
            $user['role'] = $this->resolveUserRole($user);
            $settingsStmt = $this->db->query("SELECT setting_value FROM global_settings WHERE setting_key = 'usd_to_cfa'");
            $usdToCfa = 600;
            if ($row = $settingsStmt->fetch()) {
                $usdToCfa = (float)$row['setting_value'];
            }

            echo json_encode([
                'user' => $user,
                'settings' => [
                    'exchange_rate' => $usdToCfa
                ]
            ]);
        } else {
            http_response_code(404);
            echo json_encode(['error' => 'User not found']);
        }
    }

    /** Legacy endpoint (older app builds). Delegates to the per-device registry. */
    public function saveFcmToken() {
        $user = AuthMiddleware::requireLogin();
        $userId = (int)($user['user_id'] ?? $user['id'] ?? 0);
        $data = json_decode(file_get_contents("php://input"), true);
        $fcmToken = trim($data['token'] ?? '');

        if (!$userId || $fcmToken === '') {
            echo json_encode(['success' => false]);
            return;
        }
        $deviceId = 'legacy-' . substr(md5($fcmToken), 0, 24);
        try {
            $this->db->beginTransaction();
            $this->db->prepare("UPDATE user_devices SET status = 'inactive' WHERE fcm_token = ? AND NOT (user_id = ? AND device_id = ?)")
                     ->execute([$fcmToken, $userId, $deviceId]);
            $this->db->prepare("INSERT INTO user_devices (user_id, device_id, fcm_token, platform, status, last_active_at)
                                VALUES (?, ?, ?, 'android', 'active', NOW())
                                ON DUPLICATE KEY UPDATE fcm_token = VALUES(fcm_token), status = 'active', last_active_at = NOW()")
                     ->execute([$userId, $deviceId, $fcmToken]);
            $this->db->commit();
            echo json_encode(['success' => true]);
        } catch (\Throwable $e) {
            if ($this->db->inTransaction()) $this->db->rollBack();
            echo json_encode(['success' => false]);
        }
    }
}