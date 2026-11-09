<?php
/**
 * Creates/updates the push-notification tables and performance indexes.
 * Idempotent. Run once after deploying:
 *   CLI:      php migrate_push_notifications.php
 *   Browser:  /migrate_push_notifications.php?key=<JWT_SECRET>   (delete the file afterwards)
 */
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/core/Database.php';
require_once __DIR__ . '/services/PushSchema.php';

if (PHP_SAPI !== 'cli') {
    header('Content-Type: text/plain; charset=UTF-8');
    if (!hash_equals((string)JWT_SECRET, (string)($_GET['key'] ?? ''))) {
        http_response_code(403);
        exit("Forbidden\n");
    }
}

try {
    PushSchema::migrate(Database::getInstance()->getConnection(), true);
    echo "DONE\n";
} catch (Throwable $e) {
    http_response_code(500);
    echo "ERROR: " . $e->getMessage() . "\n";
    exit(1);
}

