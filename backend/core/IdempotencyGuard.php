<?php
/**
 * Server-side duplicate-submission protection.
 * The mobile app sends `X-Idempotency-Key` (fingerprint of method+path+payload) on every write.
 * An identical write from the same user inside the window is rejected with HTTP 409 while the
 * first one is (or was recently) processed. If the first one FAILED (status >= 400) the key is
 * released so the user can retry immediately.
 */
class IdempotencyGuard {
    const WINDOW_SECONDS = 15;

    public static function guard(): void {
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
        if (!in_array($method, ['POST', 'PUT', 'DELETE'], true)) return;
        $key = (string)($_SERVER['HTTP_X_IDEMPOTENCY_KEY'] ?? '');
        if ($key === '') return;
        $key = substr(preg_replace('/[^A-Za-z0-9_\-]/', '', $key), 0, 64);
        if ($key === '') return;

        $userId = 0;
        try {
            $token = JWT::getBearerToken();
            $decoded = $token ? JWT::decode($token) : null;
            if (is_array($decoded)) $userId = (int)($decoded['user_id'] ?? $decoded['id'] ?? 0);
        } catch (Throwable $e) {}

        try {
            $db = Database::getInstance()->getConnection();
            if (mt_rand(1, 25) === 1) {
                $db->exec("DELETE FROM idempotency_keys WHERE created_at < (NOW() - INTERVAL 5 MINUTE)");
            }
            $ins = $db->prepare("INSERT IGNORE INTO idempotency_keys (key_hash, user_id, created_at) VALUES (?, ?, NOW())");
            $ins->execute([$key, $userId]);
            if ($ins->rowCount() === 0) {
                // Existing key: allow again only if it is older than the window (a deliberate repeat).
                $renew = $db->prepare("UPDATE idempotency_keys SET created_at = NOW()
                                       WHERE key_hash = ? AND user_id = ? AND created_at < (NOW() - INTERVAL " . self::WINDOW_SECONDS . " SECOND)");
                $renew->execute([$key, $userId]);
                if ($renew->rowCount() === 0) {
                    http_response_code(409);
                    echo json_encode(['error' => 'Duplicate request ignored. Your previous submission is already being processed.', 'duplicate' => true]);
                    exit();
                }
            }
            register_shutdown_function(function () use ($key, $userId) {
                if ((int)http_response_code() >= 400) {
                    try {
                        Database::getInstance()->getConnection()
                            ->prepare("DELETE FROM idempotency_keys WHERE key_hash = ? AND user_id = ?")
                            ->execute([$key, $userId]);
                    } catch (Throwable $e) {}
                }
            });
        } catch (PDOException $e) {
            if (in_array($e->getCode(), ['42S02', '42S22'], true)) {
                require_once __DIR__ . '/../services/PushSchema.php';
                PushSchema::ensure(Database::getInstance()->getConnection());
            }
            // Never block a legitimate request because the guard itself failed.
        }
    }
}

