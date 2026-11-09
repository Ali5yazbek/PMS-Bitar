<?php
/**
 * Idempotent schema management for the push-notification subsystem and for the
 * performance indexes. Safe to run any number of times (CLI, browser with key,
 * or lazily from PushNotificationService when a table is missing).
 */
class PushSchema {
    private static $ensured = false;

    /** Lazy self-heal used by runtime code when it hits a missing table/column. */
    public static function ensure(PDO $db): void {
        if (self::$ensured) return;
        self::$ensured = true;
        self::migrate($db, false);
    }

    private static function tableExists(PDO $db, string $table): bool {
        $s = $db->prepare("SELECT 1 FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? LIMIT 1");
        $s->execute([$table]);
        return (bool)$s->fetchColumn();
    }

    private static function colExists(PDO $db, string $table, string $col): bool {
        $s = $db->prepare("SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ? LIMIT 1");
        $s->execute([$table, $col]);
        return (bool)$s->fetchColumn();
    }

    private static function idxExists(PDO $db, string $table, string $idx): bool {
        $s = $db->prepare("SELECT 1 FROM information_schema.STATISTICS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND INDEX_NAME = ? LIMIT 1");
        $s->execute([$table, $idx]);
        return (bool)$s->fetchColumn();
    }

    /** Adds an index only when the table + every column exist and the index is missing. */
    private static function ensureIndex(PDO $db, string $table, string $name, array $cols, callable $log): void {
        if (!self::tableExists($db, $table)) { $log("skip   $name (table $table missing)"); return; }
        foreach ($cols as $c) {
            $plain = preg_replace('/\(\d+\)$/', '', $c);
            if (!self::colExists($db, $table, $plain)) { $log("skip   $name (column $plain missing)"); return; }
        }
        if (self::idxExists($db, $table, $name)) { return; }
        try {
            $db->exec("ALTER TABLE `$table` ADD INDEX `$name` (" . implode(',', array_map(function ($c) {
                return preg_match('/^(\w+)(\(\d+\))$/', $c, $m) ? "`{$m[1]}`{$m[2]}" : "`$c`";
            }, $cols)) . ")");
            $log("index  $name on $table");
        } catch (Throwable $e) {
            $log("WARN   $name on $table: " . $e->getMessage());
        }
    }

    private static function ensureColumn(PDO $db, string $table, string $col, string $ddl, callable $log): bool {
        if (!self::tableExists($db, $table) || self::colExists($db, $table, $col)) return false;
        try {
            $db->exec("ALTER TABLE `$table` ADD COLUMN `$col` $ddl");
            $log("column $table.$col");
            return true;
        } catch (Throwable $e) {
            $log("WARN   $table.$col: " . $e->getMessage());
            return false;
        }
    }

    public static function migrate(PDO $db, bool $verbose = true): void {
        $log = function ($m) use ($verbose) { if ($verbose) echo $m . PHP_EOL; };

        // ── Persistent Refresh Tokens (long-lived mobile auth sessions) ────
        $db->exec("CREATE TABLE IF NOT EXISTS user_refresh_tokens (
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

        // ── Device registry ────────────────────────────────────────────────
        $db->exec("CREATE TABLE IF NOT EXISTS user_devices (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL,
            device_id VARCHAR(80) NOT NULL,
            fcm_token VARCHAR(512) NOT NULL,
            platform ENUM('android','ios','web') NOT NULL DEFAULT 'android',
            app_version VARCHAR(30) NULL,
            device_model VARCHAR(80) NULL,
            status ENUM('active','inactive') NOT NULL DEFAULT 'active',
            last_active_at DATETIME NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            UNIQUE KEY uq_user_device (user_id, device_id),
            KEY idx_devices_user_status (user_id, status),
            KEY idx_devices_token (fcm_token(191))
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

        // ── Notification history (extend the existing table) ───────────────
        $db->exec("CREATE TABLE IF NOT EXISTS notifications (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL,
            title VARCHAR(255) NOT NULL,
            message TEXT NULL,
            type VARCHAR(60) NULL,
            reference_id INT NULL,
            is_read TINYINT(1) NOT NULL DEFAULT 0,
            seen_by_agent TINYINT(1) DEFAULT 0,
            created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
        self::ensureColumn($db, 'notifications', 'related_id', 'INT NULL', $log);
        self::ensureColumn($db, 'notifications', 'route', 'VARCHAR(255) NULL', $log);
        self::ensureColumn($db, 'notifications', 'read_at', 'DATETIME NULL', $log);
        // push_queued = 0 means "row was inserted by legacy code and has not been handed to the push queue yet"
        if (self::ensureColumn($db, 'notifications', 'push_queued', 'TINYINT(1) NOT NULL DEFAULT 0', $log)) {
            $db->exec("UPDATE notifications SET push_queued = 1"); // never re-push history
            $log("backfill notifications.push_queued = 1 for existing rows");
        }

        // ── Queue + delivery log + idempotency ─────────────────────────────
        $db->exec("CREATE TABLE IF NOT EXISTS notification_queue (
            id INT AUTO_INCREMENT PRIMARY KEY,
            notification_id INT NULL,
            user_id INT NOT NULL,
            title VARCHAR(255) NOT NULL,
            body TEXT NOT NULL,
            type VARCHAR(60) NULL,
            related_id INT NULL,
            route VARCHAR(255) NULL,
            status ENUM('pending','processing','sent','failed') NOT NULL DEFAULT 'pending',
            attempts TINYINT UNSIGNED NOT NULL DEFAULT 0,
            next_attempt_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            locked_at DATETIME NULL,
            last_error VARCHAR(500) NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            sent_at DATETIME NULL,
            KEY idx_queue_status_next (status, next_attempt_at),
            KEY idx_queue_notification (notification_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

        $db->exec("CREATE TABLE IF NOT EXISTS notification_delivery_logs (
            id INT AUTO_INCREMENT PRIMARY KEY,
            queue_id INT NOT NULL,
            notification_id INT NULL,
            user_id INT NOT NULL,
            device_row_id INT NULL,
            status ENUM('sent','failed','invalid_token') NOT NULL,
            fcm_message_id VARCHAR(255) NULL,
            error_code VARCHAR(80) NULL,
            error_message VARCHAR(500) NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            KEY idx_dlog_queue (queue_id),
            KEY idx_dlog_user_created (user_id, created_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

        $db->exec("CREATE TABLE IF NOT EXISTS idempotency_keys (
            key_hash VARCHAR(64) NOT NULL,
            user_id INT NOT NULL DEFAULT 0,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (key_hash, user_id),
            KEY idx_idem_created (created_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

        // ── Query-performance indexes (only added when table + columns exist) ──
        $indexes = [
            ['notifications', 'idx_notif_user_read_created', ['user_id', 'is_read', 'created_at']],
            ['notifications', 'idx_notif_push_queued', ['push_queued', 'id']],
            ['users', 'idx_users_role', ['role']],
            ['rent_invoices', 'idx_rent_invoices_due_status', ['status', 'due_date']],
            ['rent_invoices', 'idx_rent_invoices_contract', ['contract_id']],
            ['rent_payments', 'idx_rent_payments_invoice', ['invoice_id']],
            ['electricity_invoices', 'idx_elec_inv_due', ['due_date']],
            ['electricity_invoices', 'idx_elec_inv_status_due', ['status', 'due_date']],
            ['electricity_meter_readings', 'idx_emr_status', ['status']],
            ['electricity_meter_readings', 'idx_emr_apt_date', ['apartment_id', 'reading_date']],
            ['electricity_meter_readings', 'idx_emr_submitted_by', ['submitted_by']],
            ['agent_subscription_readings', 'idx_asr_submitted_by', ['submitted_by']],
            ['agent_subscription_readings', 'idx_asr_status_created', ['status', 'created_at']],
            ['generator_daily_reports', 'idx_gdr_status_date', ['status', 'date']],
            ['generator_daily_reports', 'idx_gdr_submitted_by', ['submitted_by']],
            ['tenant_maintenance_tickets', 'idx_tmt_status', ['status']],
            ['tenant_maintenance_tickets', 'idx_tmt_worker', ['worker_id']],
            ['tenant_maintenance_tickets', 'idx_tmt_apartment', ['apartment_id']],
            ['tenant_maintenance_tickets', 'idx_tmt_tenant', ['tenant_id']],
            ['ac_maintenance_tasks', 'idx_amt_status', ['status']],
            ['ac_maintenance_tasks', 'idx_amt_worker', ['worker_id']],
            ['ac_maintenance_tasks', 'idx_amt_apartment', ['apartment_id']],
            ['apartment_cost_deployments', 'idx_acd_status', ['status']],
            ['apartment_cost_deployments', 'idx_acd_apartment', ['apartment_id']],
            ['apartment_cost_deployments', 'idx_acd_submitted_by', ['submitted_by']],
            ['activity_logs', 'idx_activity_user_created', ['user_id', 'created_at']],
            ['financial_transactions', 'idx_ft_invoice', ['invoice_id']],
        ];
        foreach ($indexes as [$table, $name, $cols]) {
            self::ensureIndex($db, $table, $name, $cols, $log);
        }
                // ── Ensure users.role column is VARCHAR(50) so all roles persist cleanly ──
        try {
            $db->exec("ALTER TABLE users MODIFY COLUMN role VARCHAR(50) NOT NULL DEFAULT 'tenant'");
            $db->exec("UPDATE users SET role = 'agent' WHERE id = 5 OR username = 'hassan' OR email LIKE '%hassan%'");
            $db->exec("UPDATE users SET role = 'maintenance' WHERE id IN (2, 6) OR username IN ('milad', 'mohamad')");
            $db->exec("UPDATE users SET role = 'cashier' WHERE id = 3 OR username = 'dwdw'");
            $db->exec("UPDATE users SET role = 'admin' WHERE id = 1 OR username = 'admin'");
            $db->exec("UPDATE users SET role = 'tenant' WHERE role = '' OR role IS NULL");
            $log("users.role column widened to VARCHAR(50) & healed");
        } catch (Throwable $e) {
            $log("WARN users.role migration: " . $e->getMessage());
        }

        $log('push schema + indexes OK');
    }
}

