<?php
/**
 * DataIntegrityController — runs and queries the data integrity scanner.
 */
class DataIntegrityController {
    private $db;
    public function __construct() { $this->db = Database::getInstance()->getConnection(); }

    // ── GET /api/integrity/dashboard ──────────────────────────────────────────
    public function dashboard() {
        AuthMiddleware::requireLogin();
        $dupStats = $this->db->query("
            SELECT issue_type, severity, COUNT(*) as count
            FROM integrity_issues WHERE status = 'open'
            GROUP BY issue_type, severity ORDER BY count DESC
        ")->fetchAll();
        $finStats = $this->db->query("
            SELECT issue_type, severity, COUNT(*) as count
            FROM financial_audit_issues WHERE status = 'open'
            GROUP BY issue_type, severity ORDER BY count DESC
        ")->fetchAll();
        $totals = $this->db->query("
            SELECT
                (SELECT COUNT(*) FROM integrity_issues WHERE status='open') as integrity_open,
                (SELECT COUNT(*) FROM integrity_issues WHERE severity='critical' AND status='open') as integrity_critical,
                (SELECT COUNT(*) FROM financial_audit_issues WHERE status='open') as financial_open,
                (SELECT COUNT(*) FROM financial_audit_issues WHERE severity='critical' AND status='open') as financial_critical
        ")->fetch();
        echo json_encode(compact('dupStats', 'finStats', 'totals'));
    }

    // ── GET /api/integrity/issues ─────────────────────────────────────────────
    public function issues() {
        AuthMiddleware::requireLogin();
        $type   = $_GET['type']   ?? null;
        $status = $_GET['status'] ?? 'open';
        $where = ['status = ?']; $params = [$status];
        if ($type) { $where[] = 'issue_type = ?'; $params[] = $type; }
        $stmt = $this->db->prepare("
            SELECT * FROM integrity_issues
            WHERE " . implode(' AND ', $where) . " ORDER BY severity DESC, created_at DESC LIMIT 500
        ");
        $stmt->execute($params);
        echo json_encode($stmt->fetchAll());
    }

    // ── GET /api/integrity/financial ──────────────────────────────────────────
    public function financial() {
        AuthMiddleware::requireLogin();
        $status = $_GET['status'] ?? 'open';
        $stmt = $this->db->prepare("
            SELECT * FROM financial_audit_issues WHERE status = ? ORDER BY severity DESC, created_at DESC LIMIT 500
        ");
        $stmt->execute([$status]);
        echo json_encode($stmt->fetchAll());
    }

    // ── POST /api/integrity/run ───────────────────────────────────────────────
    public function run() {
        AuthMiddleware::requireAdmin();
        require_once __DIR__ . '/../core/DataIntegrityScanner.php';
        $scanner = new DataIntegrityScanner($this->db);
        $result  = $scanner->run();
        echo json_encode(['success' => true, 'result' => $result]);
    }

    // ── PUT /api/integrity/issues/{id}/resolve ────────────────────────────────
    public function resolveIssue($id) {
        $user = AuthMiddleware::requireAdmin();
        $this->db->prepare("UPDATE integrity_issues SET status='resolved', resolved_by=? WHERE id=?")->execute([$user['user_id'], $id]);
        echo json_encode(['success' => true]);
    }

    // ── PUT /api/integrity/issues/{id}/ignore ────────────────────────────────
    public function ignoreIssue($id) {
        AuthMiddleware::requireAdmin();
        $this->db->prepare("UPDATE integrity_issues SET status='ignored' WHERE id=?")->execute([$id]);
        echo json_encode(['success' => true]);
    }

    // ── PUT /api/integrity/financial/{id}/resolve ─────────────────────────────
    public function resolveFinancial($id) {
        AuthMiddleware::requireAdmin();
        $this->db->prepare("UPDATE financial_audit_issues SET status='resolved' WHERE id=?")->execute([$id]);
        echo json_encode(['success' => true]);
    }
}
