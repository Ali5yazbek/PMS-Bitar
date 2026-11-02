<?php
/**
 * ActionControlController — handles the full Action Control Report lifecycle
 * Routes: /api/action-control/*
 */
class ActionControlController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    // ── GET /api/action-control/dashboard ─────────────────────────────────────
    public function dashboard() {
        AuthMiddleware::requireLogin();

        $stats = $this->db->query("
            SELECT
                COUNT(*) as total,
                SUM(severity = 'critical') as critical,
                SUM(severity = 'warning')  as warning,
                SUM(severity = 'info')     as info,
                SUM(status = 'resolved')   as fixed,
                SUM(status = 'open' AND is_locked = 1)    as locked,
                SUM(status IN ('open','in_progress') AND is_locked = 0) as unlocked,
                SUM(status = 'pending_review') as pending_review,
                SUM(status = 'resolved' AND DATE(updated_at) = CURDATE()) as approved_today
            FROM audit_reports
        ")->fetch(PDO::FETCH_ASSOC);

        // Health score = resolved / (total - 0-severity info) * 100
        $nonInfo   = ($stats['total'] - $stats['info']) ?: 1;
        $healthScore = min(100, (int)round(($stats['fixed'] / $nonInfo) * 100));

        // Problems by department
        $byDept = $this->db->query("
            SELECT department, COUNT(*) as count, severity
            FROM audit_reports
            WHERE status NOT IN ('resolved','rejected')
            GROUP BY department, severity
            ORDER BY count DESC
        ")->fetchAll(PDO::FETCH_ASSOC);

        // Problems by module (table_name)
        $byModule = $this->db->query("
            SELECT table_name as module, COUNT(*) as count,
                   SUM(severity='critical') as critical,
                   SUM(severity='warning')  as warning
            FROM audit_reports
            WHERE status NOT IN ('resolved','rejected')
            GROUP BY table_name
        ")->fetchAll(PDO::FETCH_ASSOC);

        // Last 7 days trend
        $trend = $this->db->query("
            SELECT DATE(created_at) as day, COUNT(*) as count
            FROM audit_reports
            WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
            GROUP BY DATE(created_at)
            ORDER BY day ASC
        ")->fetchAll(PDO::FETCH_ASSOC);

        // Last scan info
        $lastScan = $this->db->query("
            SELECT created_at, triggered_by, total_found, duration_ms
            FROM audit_scan_runs
            ORDER BY id DESC LIMIT 1
        ")->fetch(PDO::FETCH_ASSOC);

        echo json_encode([
            'stats'       => array_merge($stats, ['health_score' => $healthScore]),
            'by_dept'     => $byDept,
            'by_module'   => $byModule,
            'trend'       => $trend,
            'last_scan'   => $lastScan,
        ]);
    }

    // ── GET /api/action-control/reports ──────────────────────────────────────
    // Returns grouped employee cards with problem counts
    public function reports() {
        AuthMiddleware::requireLogin();

        $where  = ["1=1"];
        $params = [];

        if (!empty($_GET['department'])) {
            $where[] = 'ar.department = ?';
            $params[] = $_GET['department'];
        }
        if (!empty($_GET['severity'])) {
            $where[] = 'ar.severity = ?';
            $params[] = $_GET['severity'];
        }
        if (!empty($_GET['employee_id'])) {
            $where[] = 'ar.employee_id = ?';
            $params[] = (int)$_GET['employee_id'];
        }
        if (!empty($_GET['table_name'])) {
            $where[] = 'ar.table_name = ?';
            $params[] = $_GET['table_name'];
        }
        if (!empty($_GET['date_from'])) {
            $where[] = 'ar.created_at >= ?';
            $params[] = $_GET['date_from'] . ' 00:00:00';
        }
        if (!empty($_GET['date_to'])) {
            $where[] = 'ar.created_at <= ?';
            $params[] = $_GET['date_to'] . ' 23:59:59';
        }
        if (!empty($_GET['critical_only'])) {
            $where[] = "ar.severity = 'critical'";
        }
        if (!empty($_GET['status']) && $_GET['status'] !== 'all') {
            $where[] = 'ar.status = ?';
            $params[] = $_GET['status'];
        } else {
            $where[] = "ar.status NOT IN ('resolved','rejected')";
        }

        $sql = "
            SELECT
                ar.employee_id,
                u.name   as employee_name,
                u.role   as employee_role,
                ar.department,
                COUNT(*)                        as total_problems,
                SUM(ar.severity='critical')     as critical,
                SUM(ar.severity='warning')      as warning,
                SUM(ar.severity='info')         as info,
                SUM(ar.status='pending_review') as pending_review,
                SUM(ar.is_locked=0)             as unlocked_count
            FROM audit_reports ar
            LEFT JOIN users u ON ar.employee_id = u.id
            WHERE " . implode(' AND ', $where) . "
            GROUP BY ar.employee_id, u.name, u.role, ar.department
            ORDER BY critical DESC, total_problems DESC
        ";

        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        echo json_encode($rows);
    }

    // ── GET /api/action-control/reports/{employeeId} ──────────────────────────
    // Full report for one employee, grouped by module
    public function employeeReport($employeeId) {
        $currentUser = AuthMiddleware::requireLogin();

        $stmt = $this->db->prepare("
            SELECT ar.*,
                   u.name as assigned_to_name
            FROM audit_reports ar
            LEFT JOIN users u ON ar.assigned_to = u.id
            WHERE ar.employee_id = ?
              AND ar.status NOT IN ('resolved','rejected')
            ORDER BY
                FIELD(ar.severity,'critical','warning','info'),
                ar.table_name,
                ar.created_at DESC
        ");
        $stmt->execute([$employeeId]);
        $reports = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Employee info
        $empStmt = $this->db->prepare("SELECT id, name, role, 'General' as department FROM users WHERE id = ?");
        $empStmt->execute([$employeeId]);
        $employee = $empStmt->fetch(PDO::FETCH_ASSOC);

        // Group by module
        $modules = [];
        foreach ($reports as $r) {
            $modules[$r['table_name']][] = $r;
        }

        $totalCritical = array_sum(array_map(fn($r) => $r['severity'] === 'critical' ? 1 : 0, $reports));
        $totalWarning  = array_sum(array_map(fn($r) => $r['severity'] === 'warning'  ? 1 : 0, $reports));

        // Progress: how many are in progress or pending
        $inProgress = array_sum(array_map(fn($r) => in_array($r['status'], ['in_progress','pending_review']) ? 1 : 0, $reports));
        $progress = count($reports) > 0 ? (int)round(($inProgress / count($reports)) * 100) : 0;

        echo json_encode([
            'employee'  => $employee,
            'modules'   => $modules,
            'total'     => count($reports),
            'critical'  => $totalCritical,
            'warning'   => $totalWarning,
            'progress'  => $progress,
        ]);
    }

    // ── GET /api/action-control/record-detail/{reportId} ─────────────────────
    // Returns the actual record data for full-details panel
    public function recordDetail($reportId) {
        AuthMiddleware::requireLogin();

        $report = $this->db->prepare("SELECT * FROM audit_reports WHERE id = ?");
        $report->execute([$reportId]);
        $r = $report->fetch(PDO::FETCH_ASSOC);

        if (!$r) {
            http_response_code(404);
            echo json_encode(['error' => 'Report not found']);
            return;
        }

        $recordData = [];
        try {
            $s = $this->db->prepare("SELECT * FROM `{$r['table_name']}` WHERE id = ?");
            $s->execute([$r['record_id']]);
            $recordData = $s->fetch(PDO::FETCH_ASSOC) ?: [];
        } catch (Exception $e) {
            $recordData = ['error' => 'Could not fetch record'];
        }

        echo json_encode([
            'report'      => $r,
            'record_data' => $recordData,
        ]);
    }

    // ── GET /api/action-control/trail/{reportId} ──────────────────────────────
    public function trail($reportId) {
        AuthMiddleware::requireLogin();

        $stmt = $this->db->prepare("
            SELECT at.*, u.name as user_name, u.role as user_role
            FROM audit_trail at
            LEFT JOIN users u ON at.user_id = u.id
            WHERE at.audit_report_id = ?
            ORDER BY at.created_at ASC
        ");
        $stmt->execute([$reportId]);
        echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
    }

    // ── POST /api/action-control/run-audit ───────────────────────────────────
    public function runAudit() {
        $currentUser = AuthMiddleware::requireAdmin();

        require_once __DIR__ . '/../core/AuditScanner.php';
        $scanner = new AuditScanner($this->db);
        $userId = $currentUser['user_id'] ?? ($currentUser['user_id'] ?? $currentUser['id']) ?? null;
        $result  = $scanner->run($userId);

        echo json_encode(['success' => true, 'result' => $result]);
    }

    // ── PUT /api/action-control/reports/{id}/unlock ───────────────────────────
    public function unlock($id) {
        $currentUser = AuthMiddleware::requireAdmin();
        $body = json_decode(file_get_contents('php://input'), true);

        $assignedTo   = $body['assigned_to']   ?? null;
        $unlockUntil  = $body['unlock_until']   ?? null;
        $unlockReason = $body['unlock_reason']  ?? '';

        $stmt = $this->db->prepare("
            UPDATE audit_reports
            SET is_locked = 0, assigned_to = ?, unlock_until = ?, unlock_reason = ?,
                unlocked_by = ?, status = 'in_progress', updated_at = NOW()
            WHERE id = ?
        ");
        $stmt->execute([$assignedTo, $unlockUntil, $unlockReason, ($currentUser['user_id'] ?? $currentUser['id']), $id]);

        $this->logTrail($id, ($currentUser['user_id'] ?? $currentUser['id']), 'unlocked',
            'Locked', 'Unlocked — ' . ($unlockReason ?: 'No reason given'));

        echo json_encode(['success' => true]);
    }

    // ── PUT /api/action-control/reports/{id}/lock ─────────────────────────────
    public function lock($id) {
        $currentUser = AuthMiddleware::requireAdmin();

        $stmt = $this->db->prepare("
            UPDATE audit_reports
            SET is_locked = 1, assigned_to = NULL, unlock_until = NULL, unlock_reason = NULL,
                status = 'open', updated_at = NOW()
            WHERE id = ?
        ");
        $stmt->execute([$id]);

        $this->logTrail($id, ($currentUser['user_id'] ?? $currentUser['id']), 'locked', 'Unlocked', 'Locked by admin');
        echo json_encode(['success' => true]);
    }

    // ── PUT /api/action-control/reports/{id}/fix ──────────────────────────────
    // Manager submits a fix
    public function fix($id) {
        $currentUser = AuthMiddleware::requireLogin();
        $body = json_decode(file_get_contents('php://input'), true);

        // Verify this report is unlocked and assigned to this user
        $check = $this->db->prepare("
            SELECT * FROM audit_reports
            WHERE id = ? AND is_locked = 0
              AND (assigned_to = ? OR assigned_to IS NULL)
        ");
        $check->execute([$id, ($currentUser['user_id'] ?? $currentUser['id'])]);
        $report = $check->fetch(PDO::FETCH_ASSOC);

        if (!$report) {
            http_response_code(403);
            echo json_encode(['error' => 'Record is locked or not assigned to you']);
            return;
        }

        // Check unlock expiry
        if (!empty($report['unlock_until']) && strtotime($report['unlock_until']) < time()) {
            http_response_code(403);
            echo json_encode(['error' => 'Unlock period has expired']);
            return;
        }

        $oldValue  = $body['old_value']  ?? null;
        $newValue  = $body['new_value']  ?? null;
        $comment   = $body['comment']    ?? '';

        $stmt = $this->db->prepare("
            UPDATE audit_reports
            SET status = 'pending_review', is_locked = 1, updated_at = NOW()
            WHERE id = ?
        ");
        $stmt->execute([$id]);

        $this->logTrail($id, ($currentUser['user_id'] ?? $currentUser['id']), 'submitted_fix', $oldValue, $newValue, $comment);
        echo json_encode(['success' => true]);
    }

    // ── PUT /api/action-control/reports/{id}/approve ──────────────────────────
    public function approve($id) {
        $currentUser = AuthMiddleware::requireAdmin();
        $body = json_decode(file_get_contents('php://input'), true);

        $stmt = $this->db->prepare("
            UPDATE audit_reports
            SET status = 'resolved', is_locked = 1, updated_at = NOW()
            WHERE id = ?
        ");
        $stmt->execute([$id]);

        $this->logTrail($id, ($currentUser['user_id'] ?? $currentUser['id']), 'approved', null, null, $body['comment'] ?? '');
        echo json_encode(['success' => true]);
    }

    // ── PUT /api/action-control/reports/{id}/reject ───────────────────────────
    public function reject($id) {
        $currentUser = AuthMiddleware::requireAdmin();
        $body = json_decode(file_get_contents('php://input'), true);

        $stmt = $this->db->prepare("
            UPDATE audit_reports
            SET status = 'rejected', updated_at = NOW()
            WHERE id = ?
        ");
        $stmt->execute([$id]);

        $this->logTrail($id, ($currentUser['user_id'] ?? $currentUser['id']), 'rejected', null, null, $body['comment'] ?? '');
        echo json_encode(['success' => true]);
    }

    // ── PUT /api/action-control/reports/{id}/send-back ────────────────────────
    public function sendBack($id) {
        $currentUser = AuthMiddleware::requireAdmin();
        $body = json_decode(file_get_contents('php://input'), true);

        $stmt = $this->db->prepare("
            UPDATE audit_reports
            SET status = 'in_progress', is_locked = 0, updated_at = NOW()
            WHERE id = ?
        ");
        $stmt->execute([$id]);

        $this->logTrail($id, ($currentUser['user_id'] ?? $currentUser['id']), 'sent_back', null, null, $body['comment'] ?? '');
        echo json_encode(['success' => true]);
    }

    // ── PUT /api/action-control/reports/{id}/mark-resolved ────────────────────
    public function markResolved($id) {
        $currentUser = AuthMiddleware::requireAdmin();

        $stmt = $this->db->prepare("
            UPDATE audit_reports
            SET status = 'resolved', updated_at = NOW()
            WHERE id = ?
        ");
        $stmt->execute([$id]);

        $this->logTrail($id, ($currentUser['user_id'] ?? $currentUser['id']), 'resolved_by_admin', null, null, 'Marked resolved by admin');
        echo json_encode(['success' => true]);
    }

    // ── GET /api/action-control/departments ───────────────────────────────────
    public function departments() {
        AuthMiddleware::requireLogin();
        $stmt = $this->db->query("
            SELECT DISTINCT department FROM audit_reports WHERE department IS NOT NULL ORDER BY department
        ");
        echo json_encode($stmt->fetchAll(PDO::FETCH_COLUMN));
    }

    // ── Helpers ───────────────────────────────────────────────────────────────
    private function logTrail(int $reportId, int $userId, string $action,
                              ?string $old = null, ?string $new = null, ?string $comment = null): void {
        $stmt = $this->db->prepare("
            INSERT INTO audit_trail (audit_report_id, user_id, action, old_value, new_value, comment)
            VALUES (?, ?, ?, ?, ?, ?)
        ");
        $stmt->execute([$reportId, $userId, $action, $old, $new, $comment]);
    }
}
