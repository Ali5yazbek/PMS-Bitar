<?php
require_once __DIR__ . '/PushSchema.php';
require_once __DIR__ . '/FcmSender.php';

/**
 * Centralised notification service.
 *
 *   event -> notifications row (history) -> notification_queue job -> worker -> FCM -> devices
 *
 * - notifyUser()/notifyRoles(): create history + queue job in one transaction (no network I/O).
 * - sweepOutbox(): transactional-outbox for legacy code that still INSERTs into `notifications`
 *   directly (push_queued = 0). Those rows are picked up and queued automatically.
 * - processQueue(): claims jobs atomically, sends to every active device of the user, logs each
 *   attempt, removes dead tokens, retries temporary failures with back-off.
 * - kickAfterResponse(): after the HTTP response has been flushed, drains a small batch so
 *   the API never waits for Firebase. The cron/CLI worker handles retries and bursts.
 */
class PushNotificationService {
    const MAX_ATTEMPTS = 5;
    private static $backoffSeconds = [60, 300, 1800, 7200];
    /** @var FcmSender|null */
    private static $sender = null;

    public static function db(): PDO {
        return Database::getInstance()->getConnection();
    }

    public static function setSender(?FcmSender $sender): void { self::$sender = $sender; }

    private static function sender(): FcmSender {
        return self::$sender ?? (self::$sender = new FcmSender());
    }

    /** Navigation target inside the Flutter app for a notification type + recipient role. */
    public static function routeFor(?string $type, ?string $role): string {
        $t = strtolower((string)$type);
        $isAdmin = in_array(strtolower((string)$role), ['admin', 'manager', 'super_admin'], true);
        $r = strtolower((string)$role);

        if (strpos($t, 'generator') !== false) return $isAdmin ? '/energy/verification' : '/agent-history';
        if (strpos($t, 'purchase') !== false) return $isAdmin ? '/agent-purchase-review' : '/agent-history';
        if (strpos($t, 'rent') !== false) {
            if ($r === 'agent') return '/agent-rent-collection';
            if ($r === 'tenant') return '/tenant-payments';
            return $isAdmin ? '/rent' : '/notifications';
        }
        if (strpos($t, 'electricity_collection') !== false || strpos($t, 'subscription') !== false) {
            if ($r === 'agent') return '/agent-subscriptions';
            if ($r === 'tenant') return '/tenant-subscriptions';
            return $isAdmin ? '/energy/verification' : '/notifications';
        }
        if (strpos($t, 'meter') !== false) return $isAdmin ? '/energy/verification' : '/agent-history';
        if (strpos($t, 'agent_reading') !== false || strpos($t, 'reading') !== false || $t === 'agent_action_required') {
            return $r === 'agent' ? '/agent-history' : ($isAdmin ? '/energy/verification' : '/notifications');
        }
        if (strpos($t, 'maint') !== false) {
            if ($r === 'maintenance') return '/maintenance-dashboard';
            if ($r === 'tenant') return '/tenant-dashboard';
            return $isAdmin ? '/ac-maintenance' : '/notifications';
        }
        return '/notifications';
    }

    // ── Producing notifications ────────────────────────────────────────────
    public static function notifyUser(int $userId, string $title, string $message, string $type = 'general', ?int $relatedId = null, ?string $route = null): ?int {
        $db = self::db();
        self::kickAfterResponse();
        try {
            return self::notifyUserInner($db, $userId, $title, $message, $type, $relatedId, $route);
        } catch (PDOException $e) {
            if (in_array($e->getCode(), ['42S02', '42S22'], true)) {
                PushSchema::ensure($db);
                return self::notifyUserInner($db, $userId, $title, $message, $type, $relatedId, $route);
            }
            error_log('[push] notifyUser failed: ' . $e->getMessage());
            return null;
        }
    }

    private static function notifyUserInner(PDO $db, int $userId, string $title, string $message, string $type, ?int $relatedId, ?string $route): ?int {
        if ($route === null) {
            $s = $db->prepare("SELECT role FROM users WHERE id = ?");
            $s->execute([$userId]);
            $route = self::routeFor($type, (string)$s->fetchColumn());
        }
        $own = !$db->inTransaction();
        if ($own) $db->beginTransaction();
        try {
            $ins = $db->prepare("INSERT INTO notifications (user_id, title, message, type, related_id, route, is_read, push_queued)
                                 VALUES (?, ?, ?, ?, ?, ?, 0, 1)");
            $ins->execute([$userId, $title, $message, $type, $relatedId, $route]);
            $nid = (int)$db->lastInsertId();
            self::enqueue($db, $nid, $userId, $title, $message, $type, $relatedId, $route);
            if ($own) $db->commit();
            return $nid;
        } catch (Throwable $e) {
            if ($own && $db->inTransaction()) $db->rollBack();
            throw $e;
        }
    }

    public static function notifyRoles(array $roles, string $title, string $message, string $type = 'general', ?int $relatedId = null): int {
        if (empty($roles)) return 0;
        $db = self::db();
        $normalizedRoles = array_values(array_map(function ($r) { return strtolower(trim((string)$r)); }, $roles));
        $in = implode(',', array_fill(0, count($normalizedRoles), '?'));
        $s = $db->prepare("SELECT id FROM users WHERE LOWER(TRIM(role)) IN ($in)");
        $s->execute($normalizedRoles);
        $n = 0;
        foreach ($s->fetchAll(PDO::FETCH_COLUMN) as $uid) {
            if (self::notifyUser((int)$uid, $title, $message, $type, $relatedId) !== null) $n++;
        }
        return $n;
    }

    private static function enqueue(PDO $db, int $notificationId, int $userId, string $title, string $body, ?string $type, ?int $relatedId, ?string $route): void {
        $q = $db->prepare("INSERT INTO notification_queue (notification_id, user_id, title, body, type, related_id, route, status, attempts, next_attempt_at)
                           VALUES (?, ?, ?, ?, ?, ?, ?, 'pending', 0, NOW())");
        $q->execute([$notificationId, $userId, mb_substr($title, 0, 255), mb_substr($body, 0, 1500), $type, $relatedId, $route]);
    }

    /** Queue legacy rows (inserted straight into `notifications`) exactly once. */
    public static function sweepOutbox(int $limit = 50): int {
        $db = self::db();
        try {
            $rows = $db->query("SELECT n.id, n.user_id, n.title, n.message, n.type, COALESCE(n.related_id, n.reference_id) AS rel, u.role
                                FROM notifications n LEFT JOIN users u ON u.id = n.user_id
                                WHERE n.push_queued = 0 ORDER BY n.id LIMIT " . (int)$limit)->fetchAll(PDO::FETCH_ASSOC);
        } catch (PDOException $e) {
            if (in_array($e->getCode(), ['42S02', '42S22'], true)) { PushSchema::ensure($db); }
            return 0;
        }
        $claim = $db->prepare("UPDATE notifications SET push_queued = 1, route = ?, related_id = ? WHERE id = ? AND push_queued = 0");
        $count = 0;
        foreach ($rows as $r) {
            $route = self::routeFor($r['type'], $r['role']);
            $rel = $r['rel'] !== null ? (int)$r['rel'] : null;
            $claim->execute([$route, $rel, $r['id']]);
            if ($claim->rowCount() !== 1) continue; // another worker got it
            self::enqueue($db, (int)$r['id'], (int)$r['user_id'], (string)$r['title'], (string)$r['message'], $r['type'], $rel, $route);
            $count++;
        }
        return $count;
    }

    // ── Consuming the queue ────────────────────────────────────────────────
    public static function processQueue(int $limit = 20): array {
        $stats = ['claimed' => 0, 'sent' => 0, 'retry' => 0, 'failed' => 0, 'no_devices' => 0, 'invalid_tokens' => 0, 'skipped' => ''];
        $sender = self::sender();
        if (!$sender->isConfigured()) { $stats['skipped'] = 'firebase credentials not configured'; return $stats; }
        $db = self::db();

        // Jobs stuck in "processing" (worker crashed) become eligible again.
        $db->exec("UPDATE notification_queue SET status = 'pending' WHERE status = 'processing' AND locked_at < (NOW() - INTERVAL 5 MINUTE)");

        $jobs = $db->query("SELECT * FROM notification_queue WHERE status = 'pending' AND next_attempt_at <= NOW()
                            ORDER BY id LIMIT " . (int)$limit)->fetchAll(PDO::FETCH_ASSOC);
        $claim = $db->prepare("UPDATE notification_queue SET status = 'processing', locked_at = NOW() WHERE id = ? AND status = 'pending'");
        $devStmt = $db->prepare("SELECT id, fcm_token FROM user_devices WHERE user_id = ? AND status = 'active'");
        $logStmt = $db->prepare("INSERT INTO notification_delivery_logs (queue_id, notification_id, user_id, device_row_id, status, fcm_message_id, error_code, error_message)
                                 VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
        $killDevice = $db->prepare("DELETE FROM user_devices WHERE id = ?");

        foreach ($jobs as $job) {
            $claim->execute([$job['id']]);
            if ($claim->rowCount() !== 1) continue;
            $stats['claimed']++;

            $devStmt->execute([$job['user_id']]);
            $devices = $devStmt->fetchAll(PDO::FETCH_ASSOC);
            if (!$devices) {
                self::finish($db, $job, 'sent', 'no_active_devices');
                $stats['no_devices']++;
                continue;
            }

            $data = [
                'notification_id' => $job['notification_id'], 'type' => $job['type'], 'route' => $job['route'],
                'related_id' => $job['related_id'], 'title' => $job['title'], 'body' => $job['body'],
            ];
            $anyOk = false; $needsRetry = false; $lastErr = null;
            foreach ($devices as $d) {
                $res = $sender->send($d['fcm_token'], $job['title'], $job['body'], $data);
                $status = $res['ok'] ? 'sent' : ($res['invalid'] ? 'invalid_token' : 'failed');
                $logStmt->execute([$job['id'], $job['notification_id'], $job['user_id'], $d['id'], $status, $res['message_id'], $res['error_code'], $res['error']]);
                if ($res['ok']) { $anyOk = true; continue; }
                $lastErr = ($res['error_code'] ?? '') . ': ' . ($res['error'] ?? '');
                if ($res['invalid']) { $killDevice->execute([$d['id']]); $stats['invalid_tokens']++; }
                elseif ($res['retry']) { $needsRetry = true; }
            }

            if ($anyOk) { self::finish($db, $job, 'sent', null); $stats['sent']++; continue; }
            if ($needsRetry) {
                $attempts = (int)$job['attempts'] + 1;
                if ($attempts >= self::MAX_ATTEMPTS) { self::finish($db, $job, 'failed', 'max attempts: ' . $lastErr, $attempts); $stats['failed']++; continue; }
                $delay = self::$backoffSeconds[min($attempts - 1, count(self::$backoffSeconds) - 1)];
                $db->prepare("UPDATE notification_queue SET status = 'pending', attempts = ?, last_error = ?, locked_at = NULL,
                              next_attempt_at = DATE_ADD(NOW(), INTERVAL $delay SECOND) WHERE id = ?")
                   ->execute([$attempts, mb_substr((string)$lastErr, 0, 500), $job['id']]);
                $stats['retry']++;
                continue;
            }
            self::finish($db, $job, 'failed', $lastErr, (int)$job['attempts'] + 1);
            $stats['failed']++;
        }
        return $stats;
    }

    private static function finish(PDO $db, array $job, string $status, ?string $error, ?int $attempts = null): void {
        $db->prepare("UPDATE notification_queue SET status = ?, last_error = ?, locked_at = NULL, attempts = ?, sent_at = IF(? = 'sent', NOW(), sent_at) WHERE id = ?")
           ->execute([$status, $error !== null ? mb_substr($error, 0, 500) : null, $attempts ?? (int)$job['attempts'], $status, $job['id']]);
        if (!empty($job['notification_id'])) {
            try {
                $db->prepare("UPDATE notifications SET delivery_status = ? WHERE id = ?")
                   ->execute([$status === 'sent' ? 'Sent' : 'Failed', $job['notification_id']]);
            } catch (Throwable $e) { /* delivery_status column is optional */ }
        }
    }

    /** Housekeeping: old logs/jobs and long-dead devices. */
    public static function purgeOld(): void {
        $db = self::db();
        $db->exec("DELETE FROM notification_delivery_logs WHERE created_at < (NOW() - INTERVAL 30 DAY)");
        $db->exec("DELETE FROM notification_queue WHERE status IN ('sent','failed') AND created_at < (NOW() - INTERVAL 14 DAY)");
        $db->exec("DELETE FROM user_devices WHERE status = 'inactive' AND updated_at < (NOW() - INTERVAL 60 DAY)");
        $db->exec("DELETE FROM idempotency_keys WHERE created_at < (NOW() - INTERVAL 5 MINUTE)");
    }

    /**
     * Drain a small batch AFTER the response is on the wire. Works on php-fpm, LiteSpeed,
     * and Apache mod_php / CGI so queued notifications are immediately dispatched to FCM
     * without waiting for a separate cron job.
     */
    public static function kickAfterResponse(): void {
        static $registered = false;
        if ($registered) return;
        $registered = true;
        register_shutdown_function(function () {
            try {
                $finish = function_exists('fastcgi_finish_request') ? 'fastcgi_finish_request'
                        : (function_exists('litespeed_finish_request') ? 'litespeed_finish_request' : null);
                if ($finish !== null) {
                    while (ob_get_level() > 0) { @ob_end_flush(); }
                    @$finish();
                } else {
                    while (ob_get_level() > 0) { @ob_end_flush(); }
                    @flush();
                }
                @ignore_user_abort(true);
                @set_time_limit(25);
                self::sweepOutbox(50);
                self::processQueue(15);
            } catch (Throwable $e) {
                error_log('[push] post-response drain failed: ' . $e->getMessage());
            }
        });
    }
}

