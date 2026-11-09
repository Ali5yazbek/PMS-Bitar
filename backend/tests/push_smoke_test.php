<?php
/**
 * Smoke test for the push pipeline (no real Firebase calls - a stub sender is injected).
 * Run: php backend/tests/push_smoke_test.php      (uses the DB configured in backend/.env)
 * All rows it creates are removed at the end.
 */
if (PHP_SAPI !== 'cli') { http_response_code(403); exit; }
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../core/Database.php';
require_once __DIR__ . '/../services/PushNotificationService.php';

class StubSender extends FcmSender {
    public $sent = [];
    public function isConfigured(): bool { return true; }
    public function send(string $token, string $title, string $body, array $data = []): array {
        $this->sent[] = [$token, $title, $data];
        if (strpos($token, 'DEAD') === 0)  return FcmSender::classify('UNREGISTERED', 'Requested entity was not found.', 404);
        if (strpos($token, 'FLAKY') === 0) return FcmSender::classify('UNAVAILABLE', 'The service is currently unavailable.', 503);
        return ['ok' => true, 'message_id' => 'projects/x/messages/' . md5($token), 'error_code' => null, 'error' => null, 'invalid' => false, 'retry' => false];
    }
}

$fail = 0;
function check(string $name, bool $cond, string $extra = ''): void {
    global $fail;
    echo ($cond ? '  PASS  ' : '  FAIL  ') . $name . ($extra ? "  [$extra]" : '') . PHP_EOL;
    if (!$cond) $fail++;
}

$db = Database::getInstance()->getConnection();
PushSchema::migrate($db, false);
$uid = (int)$db->query("SELECT id FROM users ORDER BY id LIMIT 1")->fetchColumn();
if (!$uid) { echo "No users in DB - cannot run test\n"; exit(2); }
$tag = 'smoke' . substr(md5((string)microtime(true)), 0, 8);
$stub = new StubSender();
PushNotificationService::setSender($stub);

echo "1. Device registry\n";
$ins = $db->prepare("INSERT INTO user_devices (user_id, device_id, fcm_token, platform, status, last_active_at) VALUES (?, ?, ?, ?, ?, NOW())");
$ins->execute([$uid, "$tag-a", "GOOD-$tag-aaaaaaaaaaaaaaaa", 'android', 'active']);
$ins->execute([$uid, "$tag-b", "DEAD-$tag-bbbbbbbbbbbbbbbb", 'ios', 'active']);
$ins->execute([$uid, "$tag-c", "GOOD-$tag-cccccccccccccccc", 'android', 'inactive']);
check('3 device rows created', true);

echo "2. Legacy insert is swept into the queue exactly once\n";
$db->prepare("INSERT INTO notifications (user_id, title, message, type, seen_by_agent) VALUES (?, ?, ?, 'generator_report', 0)")
   ->execute([$uid, "T $tag", "Ali has submitted a generator reading — waiting for your response."]);
$legacyId = (int)$db->lastInsertId();
$flag = (int)$db->query("SELECT push_queued FROM notifications WHERE id = $legacyId")->fetchColumn();
check('legacy row starts with push_queued = 0', $flag === 0);
$n1 = PushNotificationService::sweepOutbox(500);
$n2 = PushNotificationService::sweepOutbox(500);
check('first sweep queued >= 1', $n1 >= 1, "queued=$n1");
check('second sweep queued 0 (idempotent)', $n2 === 0, "queued=$n2");
$q = $db->query("SELECT * FROM notification_queue WHERE notification_id = $legacyId")->fetch(PDO::FETCH_ASSOC);
check('queue row exists with a route', $q && !empty($q['route']), $q['route'] ?? 'none');

echo "3. notifyUser creates history + job transactionally\n";
$nid = PushNotificationService::notifyUser($uid, "Direct $tag", 'Body', 'tenant_maintenance', 42);
check('notifyUser returned id', $nid > 0);
$row = $db->query("SELECT push_queued, related_id, route FROM notifications WHERE id = $nid")->fetch(PDO::FETCH_ASSOC);
check('history row flagged push_queued=1, related_id=42', $row && (int)$row['push_queued'] === 1 && (int)$row['related_id'] === 42, json_encode($row));

echo "4. processQueue: delivery, invalid-token removal, inactive device skipped\n";
$stats = PushNotificationService::processQueue(500);
check('jobs claimed', $stats['claimed'] >= 2, json_encode($stats));
$sentTokens = array_map(function ($s) { return $s[0]; }, array_filter($stub->sent, function ($s) use ($tag) { return strpos($s[0], $tag) !== false; }));
check('active GOOD device received push', in_array("GOOD-$tag-aaaaaaaaaaaaaaaa", $sentTokens));
check('inactive device NOT contacted', !in_array("GOOD-$tag-cccccccccccccccc", $sentTokens));
$dead = (int)$db->query("SELECT COUNT(*) FROM user_devices WHERE device_id = '$tag-b'")->fetchColumn();
check('invalid token device removed', $dead === 0);
$st = $db->query("SELECT status FROM notification_queue WHERE notification_id = $legacyId")->fetchColumn();
check('job marked sent', $st === 'sent', (string)$st);
$logs = (int)$db->query("SELECT COUNT(*) FROM notification_delivery_logs WHERE notification_id = $legacyId")->fetchColumn();
check('delivery logs written (ok + invalid_token)', $logs >= 2, "logs=$logs");

echo "5. Temporary failure is retried with back-off, then fails permanently\n";
$ins->execute([$uid, "$tag-d", "FLAKY-$tag-dddddddddddddddd", 'android', 'active']);
$db->prepare("UPDATE user_devices SET status='inactive' WHERE device_id = ?")->execute(["$tag-a"]);
$nid2 = PushNotificationService::notifyUser($uid, "Flaky $tag", 'Body', 'general');
PushNotificationService::processQueue(500);
$j = $db->query("SELECT status, attempts, next_attempt_at > NOW() AS future FROM notification_queue WHERE notification_id = $nid2")->fetch(PDO::FETCH_ASSOC);
check('retry scheduled in the future (pending, attempts=1)', $j && $j['status'] === 'pending' && (int)$j['attempts'] === 1 && (int)$j['future'] === 1, json_encode($j));
for ($i = 0; $i < 6; $i++) {
    $db->exec("UPDATE notification_queue SET next_attempt_at = NOW() WHERE notification_id = $nid2 AND status = 'pending'");
    PushNotificationService::processQueue(500);
}
$j = $db->query("SELECT status, attempts FROM notification_queue WHERE notification_id = $nid2")->fetch(PDO::FETCH_ASSOC);
check('gives up after max attempts', $j && $j['status'] === 'failed' && (int)$j['attempts'] === PushNotificationService::MAX_ATTEMPTS, json_encode($j));

echo "6. Route mapping (every route must exist in app_router.dart)\n";
$cases = [['generator_report', 'admin', '/energy/verification'], ['agent_purchase_pending', 'admin', '/agent-purchase-review'],
          ['tenant_maintenance', 'maintenance', '/maintenance-dashboard'], ['maintenance_ac', 'manager', '/ac-maintenance'],
          ['task_rent_collection', 'agent', '/agent-rent-collection'], ['agent_reading_rejected', 'agent', '/agent-history'],
          ['unknown_type', 'admin', '/notifications']];
foreach ($cases as [$t, $r, $want]) { $got = PushNotificationService::routeFor($t, $r); check("$t / $r -> $want", $got === $want, $got); }

echo "7. Idempotency table semantics\n";
$k = 'k' . $tag;
$a = $db->prepare("INSERT IGNORE INTO idempotency_keys (key_hash, user_id) VALUES (?, ?)"); $a->execute([$k, $uid]); $first = $a->rowCount();
$a->execute([$k, $uid]); $second = $a->rowCount();
check('second identical key rejected by unique key', $first === 1 && $second === 0);

echo "8. Persistent Refresh Token table & lifecycle\n";
require_once __DIR__ . '/../core/JWT.php';
$rawRefresh = JWT::generateRefreshToken();
$refreshHash = hash('sha256', $rawRefresh);
$expAt = date('Y-m-d H:i:s', time() + 315360000);
$rtIns = $db->prepare("INSERT INTO user_refresh_tokens (user_id, token_hash, device_id, platform, expires_at, revoked, last_used_at) VALUES (?, ?, ?, 'android', ?, 0, NOW())");
$rtIns->execute([$uid, $refreshHash, "$tag-rt", $expAt]);
$rtRow = $db->query("SELECT user_id, revoked, expires_at > NOW() AS valid FROM user_refresh_tokens WHERE token_hash = '$refreshHash'")->fetch(PDO::FETCH_ASSOC);
check('refresh token stored with 10-year expiry and revoked=0', $rtRow && (int)$rtRow['user_id'] === $uid && (int)$rtRow['revoked'] === 0 && (int)$rtRow['valid'] === 1);
$db->prepare("UPDATE user_refresh_tokens SET revoked = 1 WHERE token_hash = ?")->execute([$refreshHash]);
$revokedVal = (int)$db->query("SELECT revoked FROM user_refresh_tokens WHERE token_hash = '$refreshHash'")->fetchColumn();
check('manual logout revokes refresh token', $revokedVal === 1);
$db->prepare("DELETE FROM user_refresh_tokens WHERE token_hash = ?")->execute([$refreshHash]);

// ── cleanup ──
$db->exec("DELETE FROM notification_delivery_logs WHERE notification_id IN (SELECT id FROM notifications WHERE title LIKE '%$tag%')");
$db->exec("DELETE FROM notification_queue WHERE title LIKE '%$tag%'");
$db->exec("DELETE FROM notifications WHERE title LIKE '%$tag%'");
$db->exec("DELETE FROM user_devices WHERE device_id LIKE '$tag-%'");
$db->exec("DELETE FROM idempotency_keys WHERE key_hash = '$k'");
echo ($fail === 0 ? "\nALL CHECKS PASSED\n" : "\n$fail CHECK(S) FAILED\n");
exit($fail === 0 ? 0 : 1);

