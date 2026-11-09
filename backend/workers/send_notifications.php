<?php
/**
 * Notification queue worker. Schedule with cron (every minute):
 *   * * * * * /usr/bin/php /path/to/backend/workers/send_notifications.php >> /dev/null 2>&1
 * Options: --loop (keeps polling for ~55 s, useful with a once-a-minute cron), --quiet
 */
if (PHP_SAPI !== 'cli') { http_response_code(403); exit('CLI only'); }

require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../core/Database.php';
require_once __DIR__ . '/../services/PushNotificationService.php';
date_default_timezone_set('Africa/Douala');

$loop = in_array('--loop', $argv, true);
$quiet = in_array('--quiet', $argv, true);
$deadline = time() + ($loop ? 55 : 0);

do {
    $swept = PushNotificationService::sweepOutbox(100);
    $stats = PushNotificationService::processQueue(100);
    if (!$quiet) echo date('c') . ' swept=' . $swept . ' ' . json_encode($stats) . PHP_EOL;
    if ($loop && time() < $deadline) sleep(5);
} while ($loop && time() < $deadline);

if (mt_rand(1, 60) === 1) PushNotificationService::purgeOld();

