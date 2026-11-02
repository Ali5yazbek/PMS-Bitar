<?php
/**
 * Daily Audit Cron Job
 * Schedule this to run daily: php /path/to/Bitar/backend/cron/audit_daily_scan.php
 *
 * Windows Task Scheduler example:
 *   Program: php.exe
 *   Arguments: "d:\xamp\htdocs\Bitar\backend\cron\audit_daily_scan.php"
 *   Schedule: Daily at 02:00 AM
 */

// Bootstrap
chdir(dirname(__DIR__)); // go to backend/
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../core/Database.php';
require_once __DIR__ . '/../core/AuditScanner.php';

$db      = Database::getInstance()->getConnection();
$scanner = new AuditScanner($db);
$result  = $scanner->run(0); // 0 = system/cron

$timestamp = date('Y-m-d H:i:s');
$log = "[{$timestamp}] Audit scan complete: "
    . "total={$result['total']}, "
    . "critical={$result['critical']}, "
    . "warning={$result['warning']}, "
    . "info={$result['info']}, "
    . "duration={$result['duration_ms']}ms\n";

// Write log to cron log file
$logFile = __DIR__ . '/audit_scan.log';
file_put_contents($logFile, $log, FILE_APPEND | LOCK_EX);

echo $log;
