<?php
/**
 * SystemHealthController — real-time system metrics.
 */
class SystemHealthController {
    private $db;
    public function __construct() { $this->db = Database::getInstance()->getConnection(); }

    // ── GET /api/system-health ────────────────────────────────────────────────
    public function index() {
        AuthMiddleware::requireAdmin();

        // DB table stats
        $tableStats = $this->db->query("
            SELECT TABLE_NAME as name,
                   TABLE_ROWS as `rows`,
                   ROUND((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024, 2) as size_mb
            FROM information_schema.TABLES
            WHERE TABLE_SCHEMA = DATABASE()
            ORDER BY (DATA_LENGTH + INDEX_LENGTH) DESC
            LIMIT 20
        ")->fetchAll();

        $dbSize = $this->db->query("
            SELECT ROUND(SUM(DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024, 2) as total_mb
            FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE()
        ")->fetchColumn();

        // Upload directory stats
        $uploadDir   = __DIR__ . '/../../uploads/';
        $uploadCount = 0; $missingCount = 0; $brokenCount = 0; $storageMb = 0;
        if (is_dir($uploadDir)) {
            $files = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($uploadDir, FilesystemIterator::SKIP_DOTS));
            foreach ($files as $file) {
                if ($file->isFile()) {
                    $uploadCount++;
                    $storageMb += $file->getSize() / 1024 / 1024;
                    if ($file->getSize() === 0) $brokenCount++;
                }
            }
        }

        // Audit report issue counts
        $issues = $this->db->query("
            SELECT
                (SELECT COUNT(*) FROM audit_reports WHERE status='open') as open_audit,
                (SELECT COUNT(*) FROM audit_reports WHERE status='pending_review') as pending_audit,
                (SELECT COUNT(*) FROM integrity_issues WHERE status='open') as open_integrity,
                (SELECT COUNT(*) FROM financial_audit_issues WHERE status='open') as open_financial,
                (SELECT COUNT(*) FROM security_events WHERE severity='critical' AND created_at > DATE_SUB(NOW(), INTERVAL 24 HOUR)) as critical_events_24h,
                (SELECT COUNT(*) FROM approval_requests WHERE status='pending') as pending_approvals
        ")->fetch();

        // Temp permissions expiring soon
        $expiringPerms = $this->db->query("
            SELECT COUNT(*) as count FROM temp_permissions
            WHERE is_active = 1 AND expires_at BETWEEN NOW() AND DATE_ADD(NOW(), INTERVAL 2 HOUR)
        ")->fetchColumn();

        // Recent scan info
        $lastScan = $this->db->query("
            SELECT * FROM audit_scan_runs ORDER BY id DESC LIMIT 1
        ")->fetch();

        // Module health scores (based on resolved vs total per table)
        $healthByModule = $this->db->query("
            SELECT table_name as module,
                   COUNT(*) as total,
                   SUM(status='resolved') as resolved
            FROM audit_reports
            GROUP BY table_name
        ")->fetchAll();

        $moduleScores = [];
        foreach ($healthByModule as $m) {
            $score = $m['total'] > 0 ? round((1 - ($m['total'] - $m['resolved']) / $m['total']) * 100) : 100;
            $moduleScores[$m['module']] = max(0, min(100, $score));
        }

        echo json_encode([
            'database' => [
                'total_size_mb'  => (float)$dbSize,
                'table_count'    => count($tableStats),
                'top_tables'     => $tableStats,
            ],
            'storage' => [
                'file_count'  => $uploadCount,
                'size_mb'     => round($storageMb, 2),
                'broken_files'=> $brokenCount,
            ],
            'issues'           => $issues,
            'expiring_perms'   => (int)$expiringPerms,
            'last_scan'        => $lastScan,
            'module_health'    => $moduleScores,
            'overall_health'   => $moduleScores ? (int)round(array_sum($moduleScores) / count($moduleScores)) : 100,
        ]);
    }

    // ── GET /api/system-health/settings ───────────────────────────────────────
    public function settings() {
        AuthMiddleware::requireAdmin();
        $stmt = $this->db->query("SELECT * FROM enterprise_settings ORDER BY category, setting_key");
        echo json_encode($stmt->fetchAll());
    }

    // ── PUT /api/system-health/settings ───────────────────────────────────────
    public function updateSettings() {
        AuthMiddleware::requireAdmin();
        $body = json_decode(file_get_contents('php://input'), true);
        $stmt = $this->db->prepare("INSERT INTO enterprise_settings (setting_key, value, label, category) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE value=VALUES(value)");
        foreach ($body as $s) { $stmt->execute([$s['setting_key'], $s['value'], $s['label'] ?? '', $s['category'] ?? 'general']); }
        echo json_encode(['success' => true]);
    }

    // ── GET /api/system-health/analytics ──────────────────────────────────────
    // Returns all analytics data for the dashboard
    public function analytics() {
        AuthMiddleware::requireLogin();

        $byModule = $this->db->query("
            SELECT table_name as module,
                   COUNT(*) as total,
                   SUM(severity='critical') as critical,
                   SUM(severity='warning')  as warning
            FROM audit_reports WHERE status NOT IN ('resolved','rejected')
            GROUP BY table_name
        ")->fetchAll();

        $byDept = $this->db->query("
            SELECT department, COUNT(*) as total,
                   SUM(severity='critical') as critical
            FROM audit_reports WHERE status NOT IN ('resolved','rejected')
            GROUP BY department ORDER BY total DESC LIMIT 10
        ")->fetchAll();

        $byEmployee = $this->db->query("
            SELECT u.name as employee, COUNT(*) as total,
                   SUM(ar.severity='critical') as critical
            FROM audit_reports ar
            JOIN users u ON ar.employee_id = u.id
            WHERE ar.status NOT IN ('resolved','rejected')
            GROUP BY ar.employee_id, u.name
            ORDER BY critical DESC, total DESC LIMIT 10
        ")->fetchAll();

        $bySeverity = $this->db->query("
            SELECT severity, COUNT(*) as count FROM audit_reports
            WHERE status NOT IN ('resolved','rejected')
            GROUP BY severity
        ")->fetchAll();

        $overTime = $this->db->query("
            SELECT DATE(created_at) as day, COUNT(*) as total,
                   SUM(severity='critical') as critical
            FROM audit_reports
            WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
            GROUP BY DATE(created_at) ORDER BY day
        ")->fetchAll();

        $commonErrors = $this->db->query("
            SELECT field_name, problem_type, COUNT(*) as count
            FROM audit_reports
            WHERE status NOT IN ('resolved','rejected')
            GROUP BY field_name, problem_type
            ORDER BY count DESC LIMIT 10
        ")->fetchAll();

        $resolutionAvg = $this->db->query("
            SELECT AVG(TIMESTAMPDIFF(HOUR, created_at, updated_at)) as avg_hours
            FROM audit_reports WHERE status = 'resolved'
        ")->fetchColumn();

        echo json_encode(compact('byModule','byDept','byEmployee','bySeverity','overTime','commonErrors','resolutionAvg'));
    }
}
