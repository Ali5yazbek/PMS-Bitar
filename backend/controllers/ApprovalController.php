<?php
/**
 * ApprovalController — multi-level approval chains, requests, and security events.
 */
class ApprovalController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    // ── GET /api/approvals/chains ─────────────────────────────────────────────
    public function chains() {
        AuthMiddleware::requireLogin();
        $stmt = $this->db->query("
            SELECT ac.*, COUNT(acs.id) as step_count
            FROM approval_chains ac
            LEFT JOIN approval_chain_steps acs ON ac.id = acs.chain_id
            GROUP BY ac.id
            ORDER BY ac.created_at DESC
        ");
        echo json_encode($stmt->fetchAll());
    }

    // ── GET /api/approvals/chains/{id} ────────────────────────────────────────
    public function showChain($id) {
        AuthMiddleware::requireLogin();
        $chain = $this->db->prepare("SELECT * FROM approval_chains WHERE id = ?");
        $chain->execute([$id]);
        $c = $chain->fetch();
        if (!$c) { http_response_code(404); echo json_encode(['error' => 'Not found']); return; }

        $steps = $this->db->prepare("
            SELECT acs.*, u.name as approver_name
            FROM approval_chain_steps acs
            LEFT JOIN users u ON acs.approver_user_id = u.id
            WHERE acs.chain_id = ?
            ORDER BY acs.step_order
        ");
        $steps->execute([$id]);
        $c['steps'] = $steps->fetchAll();
        echo json_encode($c);
    }

    // ── POST /api/approvals/chains ────────────────────────────────────────────
    public function storeChain() {
        $admin = AuthMiddleware::requireAdmin();
        $body  = json_decode(file_get_contents('php://input'), true);
        $this->db->beginTransaction();
        $stmt = $this->db->prepare("INSERT INTO approval_chains (name, action_type, description, created_by) VALUES (?, ?, ?, ?)");
        $stmt->execute([$body['name'], $body['action_type'], $body['description'] ?? '', $admin['user_id']]);
        $chainId = (int)$this->db->lastInsertId();

        $stepStmt = $this->db->prepare("
            INSERT INTO approval_chain_steps (chain_id, step_order, step_label, approver_role, approver_user_id, can_reject, can_delegate)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ");
        foreach ($body['steps'] ?? [] as $i => $step) {
            $stepStmt->execute([
                $chainId, $i + 1, $step['step_label'], $step['approver_role'] ?? null,
                $step['approver_user_id'] ?? null, (int)($step['can_reject'] ?? 1), (int)($step['can_delegate'] ?? 0)
            ]);
        }
        $this->db->commit();
        echo json_encode(['success' => true, 'id' => $chainId]);
    }

    // ── DELETE /api/approvals/chains/{id} ─────────────────────────────────────
    public function deleteChain($id) {
        AuthMiddleware::requireAdmin();
        $this->db->prepare("DELETE FROM approval_chain_steps WHERE chain_id = ?")->execute([$id]);
        $this->db->prepare("DELETE FROM approval_chains WHERE id = ?")->execute([$id]);
        echo json_encode(['success' => true]);
    }

    // ── GET /api/approvals/requests ───────────────────────────────────────────
    public function requests() {
        $user = AuthMiddleware::requireLogin();
        $status = $_GET['status'] ?? null;
        $mine   = $_GET['mine']   ?? null;
        $where  = ['1=1']; $params = [];

        if ($status) { $where[] = 'ar.status = ?'; $params[] = $status; }
        if ($mine)   { $where[] = 'ar.requester_id = ?'; $params[] = $user['user_id']; }

        $stmt = $this->db->prepare("
            SELECT ar.*, ac.name as chain_name,
                   u.name as requester_name,
                   acs.step_label as current_step_label
            FROM approval_requests ar
            JOIN approval_chains ac ON ar.chain_id = ac.id
            JOIN users u ON ar.requester_id = u.id
            LEFT JOIN approval_chain_steps acs ON ar.chain_id = acs.chain_id AND ar.current_step = acs.step_order
            WHERE " . implode(' AND ', $where) . "
            ORDER BY ar.created_at DESC
            LIMIT 200
        ");
        $stmt->execute($params);
        echo json_encode($stmt->fetchAll());
    }

    // ── POST /api/approvals/requests ──────────────────────────────────────────
    public function storeRequest() {
        $user = AuthMiddleware::requireLogin();
        $body = json_decode(file_get_contents('php://input'), true);

        // Validate chain exists
        $chain = $this->db->prepare("SELECT * FROM approval_chains WHERE id = ? AND is_active = 1");
        $chain->execute([$body['chain_id']]);
        if (!$chain->fetch()) {
            http_response_code(400); echo json_encode(['error' => 'Invalid or inactive chain']); return;
        }

        $stmt = $this->db->prepare("
            INSERT INTO approval_requests (chain_id, requester_id, title, reason, record_type, record_id, data_payload)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ");
        $stmt->execute([
            $body['chain_id'], $user['user_id'], $body['title'], $body['reason'] ?? '',
            $body['record_type'] ?? null, $body['record_id'] ?? null,
            isset($body['data_payload']) ? json_encode($body['data_payload']) : null
        ]);
        $requestId = (int)$this->db->lastInsertId();

        // Create step rows
        $steps = $this->db->prepare("SELECT * FROM approval_chain_steps WHERE chain_id = ? ORDER BY step_order");
        $steps->execute([$body['chain_id']]);
        $stepStmt = $this->db->prepare("INSERT INTO approval_request_steps (request_id, chain_step_id) VALUES (?, ?)");
        foreach ($steps->fetchAll() as $s) { $stepStmt->execute([$requestId, $s['id']]); }

        echo json_encode(['success' => true, 'id' => $requestId]);
    }

    // ── PUT /api/approvals/requests/{id}/approve ──────────────────────────────
    public function approveRequest($id) {
        $user = AuthMiddleware::requireLogin();
        $body = json_decode(file_get_contents('php://input'), true);
        $this->processRequestAction($id, $user['user_id'], 'approved', $body['comment'] ?? '');
    }

    // ── PUT /api/approvals/requests/{id}/reject ───────────────────────────────
    public function rejectRequest($id) {
        $user = AuthMiddleware::requireLogin();
        $body = json_decode(file_get_contents('php://input'), true);
        $this->processRequestAction($id, $user['user_id'], 'rejected', $body['comment'] ?? '');
    }

    // ── GET /api/approvals/my-actions ────────────────────────────────────────
    // What requests are waiting for the current user's approval
    public function myActions() {
        $user = AuthMiddleware::requireLogin();
        $stmt = $this->db->prepare("
            SELECT ar.*, ac.name as chain_name, u.name as requester_name,
                   acs.step_label, acs.step_order
            FROM approval_requests ar
            JOIN approval_chains ac ON ar.chain_id = ac.id
            JOIN users u ON ar.requester_id = u.id
            JOIN approval_chain_steps acs ON ar.chain_id = acs.chain_id AND ar.current_step = acs.step_order
            WHERE ar.status = 'pending'
              AND (acs.approver_role = ? OR acs.approver_user_id = ?)
            ORDER BY ar.created_at ASC
        ");
        $stmt->execute([$user['role'], $user['user_id']]);
        echo json_encode($stmt->fetchAll());
    }

    // ── GET /api/approvals/security-events ───────────────────────────────────
    public function securityEvents() {
        AuthMiddleware::requireAdmin();
        $type     = $_GET['type']     ?? null;
        $severity = $_GET['severity'] ?? null;
        $from     = $_GET['from']     ?? null;
        $to       = $_GET['to']       ?? null;
        $search   = $_GET['search']   ?? null;

        $where = ['1=1']; $params = [];
        if ($type)     { $where[] = 'event_type = ?';     $params[] = $type; }
        if ($severity) { $where[] = 'severity = ?';        $params[] = $severity; }
        if ($from)     { $where[] = 'created_at >= ?';     $params[] = $from . ' 00:00:00'; }
        if ($to)       { $where[] = 'created_at <= ?';     $params[] = $to . ' 23:59:59'; }
        if ($search)   { $where[] = '(description LIKE ? OR user_name LIKE ?)'; $params[] = "%$search%"; $params[] = "%$search%"; }

        $stmt = $this->db->prepare("
            SELECT se.*, u.name as user_full_name
            FROM security_events se
            LEFT JOIN users u ON se.user_id = u.id
            WHERE " . implode(' AND ', $where) . "
            ORDER BY created_at DESC
            LIMIT 500
        ");
        $stmt->execute($params);

        // Also get summary
        $summary = $this->db->query("
            SELECT severity, COUNT(*) as count,
                   SUM(created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)) as last_24h
            FROM security_events
            GROUP BY severity
        ")->fetchAll();

        echo json_encode(['events' => $stmt->fetchAll(), 'summary' => $summary]);
    }

    // ── POST /api/approvals/security-events ──────────────────────────────────
    public function logSecurityEvent() {
        $user = AuthMiddleware::requireLogin();
        $body = json_decode(file_get_contents('php://input'), true);
        $stmt = $this->db->prepare("
            INSERT INTO security_events (user_id, user_name, event_type, severity, description, ip_address, metadata)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ");
        $stmt->execute([
            $user['user_id'], $user['name'],
            $body['event_type'], $body['severity'] ?? 'info',
            $body['description'],
            $_SERVER['REMOTE_ADDR'] ?? null,
            isset($body['metadata']) ? json_encode($body['metadata']) : null
        ]);
        echo json_encode(['success' => true]);
    }

    // ── GET /api/approvals/audit-search ──────────────────────────────────────
    // Search audit trail across all records
    public function auditSearch() {
        AuthMiddleware::requireLogin();
        $q    = $_GET['q']    ?? '';
        $from = $_GET['from'] ?? null;
        $to   = $_GET['to']   ?? null;

        $where = ['1=1']; $params = [];
        if ($q) {
            $where[] = '(u.name LIKE ? OR at.action LIKE ? OR at.old_value LIKE ? OR at.new_value LIKE ? OR at.comment LIKE ?)';
            $like = "%$q%";
            $params = array_merge($params, [$like, $like, $like, $like, $like]);
        }
        if ($from) { $where[] = 'at.created_at >= ?'; $params[] = $from . ' 00:00:00'; }
        if ($to)   { $where[] = 'at.created_at <= ?'; $params[] = $to . ' 23:59:59'; }

        $stmt = $this->db->prepare("
            SELECT at.*, u.name as user_name, u.role as user_role,
                   ar.table_name, ar.field_name, ar.description as problem_desc
            FROM audit_trail at
            LEFT JOIN users u ON at.user_id = u.id
            LEFT JOIN audit_reports ar ON at.audit_report_id = ar.id
            WHERE " . implode(' AND ', $where) . "
            ORDER BY at.created_at DESC
            LIMIT 300
        ");
        $stmt->execute($params);
        echo json_encode($stmt->fetchAll());
    }

    // ── GET /api/approvals/compare/{reportId} ─────────────────────────────────
    // Returns before/after comparison for a report
    public function compareChanges($reportId) {
        AuthMiddleware::requireLogin();
        $stmt = $this->db->prepare("
            SELECT at.*, u.name as user_name, u.role,
                   au.name as approved_by_name
            FROM audit_trail at
            LEFT JOIN users u ON at.user_id = u.id
            LEFT JOIN users au ON at.user_id = au.id
            WHERE at.audit_report_id = ?
              AND at.action IN ('submitted_fix','approved','rejected')
            ORDER BY at.created_at ASC
        ");
        $stmt->execute([$reportId]);
        echo json_encode($stmt->fetchAll());
    }

    // ── Private: process approve/reject ───────────────────────────────────────
    private function processRequestAction(int $requestId, int $userId, string $action, string $comment): void {
        $req = $this->db->prepare("SELECT * FROM approval_requests WHERE id = ? AND status = 'pending'");
        $req->execute([$requestId]);
        $r = $req->fetch();
        if (!$r) { http_response_code(404); echo json_encode(['error' => 'Request not found or not pending']); return; }

        // Update current step
        $step = $this->db->prepare("
            SELECT ars.*, acs.step_order, acs.step_label
            FROM approval_request_steps ars
            JOIN approval_chain_steps acs ON ars.chain_step_id = acs.id
            WHERE ars.request_id = ? AND acs.step_order = ? AND ars.status = 'pending'
            LIMIT 1
        ");
        $step->execute([$requestId, $r['current_step']]);
        $s = $step->fetch();
        if (!$s) { http_response_code(400); echo json_encode(['error' => 'Step not found']); return; }

        // Mark this step
        $this->db->prepare("UPDATE approval_request_steps SET status=?, approver_id=?, comment=?, acted_at=NOW() WHERE id=?")
            ->execute([$action, $userId, $comment, $s['id']]);

        if ($action === 'rejected') {
            $this->db->prepare("UPDATE approval_requests SET status='rejected', resolved_at=NOW() WHERE id=?")->execute([$requestId]);
        } else {
            // Check if there's a next step
            $next = $this->db->prepare("
                SELECT acs.step_order FROM approval_chain_steps acs
                WHERE acs.chain_id = ? AND acs.step_order > ?
                ORDER BY acs.step_order ASC LIMIT 1
            ");
            $next->execute([$r['chain_id'], $r['current_step']]);
            $nextStep = $next->fetch();
            if ($nextStep) {
                $this->db->prepare("UPDATE approval_requests SET current_step=? WHERE id=?")->execute([$nextStep['step_order'], $requestId]);
            } else {
                // All steps passed → approved
                $this->db->prepare("UPDATE approval_requests SET status='approved', resolved_at=NOW() WHERE id=?")->execute([$requestId]);
            }
        }
        echo json_encode(['success' => true]);
    }
}
