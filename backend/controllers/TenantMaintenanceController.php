<?php
class TenantMaintenanceController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * GET /api/maintenance-tickets/all
     * List all tickets across all tenants (global admin view)
     */
    public function indexAll() {
        AuthMiddleware::requireLogin();

        $stmt = $this->db->query("
            SELECT
                tmt.*,
                t.full_name    AS tenant_name,
                t.phone        AS tenant_phone,
                a.code         AS apartment_code,
                b.name         AS building_name,
                u.name         AS submitted_by_name,
                w.name         AS worker_name
            FROM tenant_maintenance_tickets tmt
            JOIN tenants t      ON tmt.tenant_id    = t.id
            LEFT JOIN apartments a ON tmt.apartment_id  = a.id
            LEFT JOIN buildings  b ON a.building_id     = b.id
            LEFT JOIN users      u ON tmt.submitted_by  = u.id
            LEFT JOIN users      w ON tmt.worker_id     = w.id
            ORDER BY tmt.created_at DESC
        ");
        echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
    }

    /**
     * GET /api/tenants/{id}/maintenance-tickets
     * List all tickets for a specific tenant (admin/manager view)
     */
    public function index($tenantId) {
        AuthMiddleware::requireLogin();

        $stmt = $this->db->prepare("
            SELECT
                tmt.*,
                t.full_name    AS tenant_name,
                t.phone        AS tenant_phone,
                a.code         AS apartment_code,
                b.name         AS building_name,
                u.name         AS submitted_by_name,
                w.name         AS worker_name
            FROM tenant_maintenance_tickets tmt
            JOIN tenants t      ON tmt.tenant_id    = t.id
            LEFT JOIN apartments a ON tmt.apartment_id  = a.id
            LEFT JOIN buildings  b ON a.building_id     = b.id
            LEFT JOIN users      u ON tmt.submitted_by  = u.id
            LEFT JOIN users      w ON tmt.worker_id     = w.id
            WHERE tmt.tenant_id = ?
            ORDER BY tmt.created_at DESC
        ");
        $stmt->execute([$tenantId]);
        echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
    }

    /**
     * POST /api/tenants/{id}/maintenance-tickets
     * Submit a new maintenance ticket
     */
    public function store($tenantId) {
        $user = AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);

        if (empty($data['title']) || empty($data['description'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Title and description are required']);
            return;
        }

        // Resolve apartment from active contract
        $aptStmt = $this->db->prepare("
            SELECT c.apartment_id FROM contracts c
            WHERE c.tenant_id = ? AND c.status IN ('Active', 'Approved')
            ORDER BY c.id DESC LIMIT 1
        ");
        $aptStmt->execute([$tenantId]);
        $contract = $aptStmt->fetch(PDO::FETCH_ASSOC);
        $apartment_id = $contract ? $contract['apartment_id'] : null;

        $stmt = $this->db->prepare("
            INSERT INTO tenant_maintenance_tickets
                (tenant_id, apartment_id, title, description, category, priority, status, submitted_by)
            VALUES (?, ?, ?, ?, ?, ?, 'Open', ?)
        ");
        $stmt->execute([
            $tenantId,
            $apartment_id,
            trim($data['title']),
            trim($data['description']),
            $data['category'] ?? null,
            $data['priority']  ?? 'Medium',
            $user['user_id']
        ]);

        $id = $this->db->lastInsertId();
        AuditLogger::log('CREATE', 'MaintenanceTicket', $id, "Maintenance ticket created for tenant #{$tenantId}");

        http_response_code(201);
        echo json_encode(['message' => 'Ticket created successfully', 'id' => $id]);
    }

    /**
     * POST /api/maintenance/requests
     * Create maintenance ticket from mobile app or generalized request payload
     */
    public function storeFromRequest() {
        $user = AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true) ?? [];

        if (empty($data['title']) || empty($data['description'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Title and description are required']);
            return;
        }

        $userId = $user['user_id'] ?? $user['id'] ?? null;
        $tenantId = $data['tenant_id'] ?? null;

        // Auto-discover tenant if not explicitly provided
        if (!$tenantId && $userId) {
            $tStmt = $this->db->prepare("SELECT id FROM tenants WHERE user_id = ? LIMIT 1");
            $tStmt->execute([$userId]);
            $tRow = $tStmt->fetch(PDO::FETCH_ASSOC);
            if ($tRow) {
                $tenantId = $tRow['id'];
            }
        }

        // Auto-discover apartment from tenant active contract
        $apartmentId = $data['apartment_id'] ?? null;
        if (!$apartmentId && $tenantId) {
            $aptStmt = $this->db->prepare("
                SELECT c.apartment_id FROM contracts c
                WHERE c.tenant_id = ? AND c.status IN ('Active', 'Approved')
                ORDER BY c.id DESC LIMIT 1
            ");
            $aptStmt->execute([$tenantId]);
            $contract = $aptStmt->fetch(PDO::FETCH_ASSOC);
            $apartmentId = $contract ? $contract['apartment_id'] : null;
        }

        // Normalize urgency/priority
        $rawPriority = $data['urgency'] ?? ($data['priority'] ?? 'Medium');
        $priority = 'Medium';
        if (strcasecmp($rawPriority, 'Critical') === 0 || strcasecmp($rawPriority, 'Urgent') === 0) {
            $priority = 'Urgent';
        } elseif (in_array(ucfirst(strtolower($rawPriority)), ['Low', 'Medium', 'High', 'Urgent'])) {
            $priority = ucfirst(strtolower($rawPriority));
        }

        $category = $data['category'] ?? 'General Maintenance';

        $stmt = $this->db->prepare("
            INSERT INTO tenant_maintenance_tickets
                (tenant_id, apartment_id, title, description, category, priority, status, submitted_by)
            VALUES (?, ?, ?, ?, ?, ?, 'Open', ?)
        ");
        $stmt->execute([
            $tenantId,
            $apartmentId,
            trim($data['title']),
            trim($data['description']),
            $category,
            $priority,
            $userId
        ]);

        $id = $this->db->lastInsertId();
        AuditLogger::log('CREATE', 'MaintenanceTicket', $id, "Maintenance request created for tenant #{$tenantId}, apt #{$apartmentId}");

        http_response_code(201);
        echo json_encode([
            'message' => 'Maintenance request submitted successfully',
            'id' => $id,
            'ticket' => [
                'id' => $id,
                'tenant_id' => $tenantId,
                'apartment_id' => $apartmentId,
                'title' => trim($data['title']),
                'category' => $category,
                'priority' => $priority,
                'status' => 'Open'
            ]
        ]);
    }

    /**
     * PUT /api/tenants/maintenance-tickets/{id}/status
     * Update ticket status (admin or worker action)
     */
    public function updateStatus($ticketId) {
        $user = AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);

        if (empty($data['status'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Status is required']);
            return;
        }

        $resolved_at = in_array($data['status'], ['Resolved', 'Closed'])
            ? date('Y-m-d H:i:s')
            : null;

        $worker_id = $data['worker_id'] ?? ($user['user_id'] ?? $user['id'] ?? null);
        $before_photo = $data['before_photo'] ?? null;
        $after_photo = $data['after_photo'] ?? null;
        $worker_notes = $data['worker_notes'] ?? ($data['notes'] ?? null);

        $stmt = $this->db->prepare("
            UPDATE tenant_maintenance_tickets
            SET status = ?, 
                admin_notes = COALESCE(?, admin_notes), 
                resolved_at = COALESCE(?, resolved_at),
                worker_id = COALESCE(?, worker_id),
                before_photo = COALESCE(?, before_photo),
                after_photo = COALESCE(?, after_photo),
                worker_notes = COALESCE(?, worker_notes),
                completion_date = CASE WHEN ? IN ('Resolved', 'Closed') THEN NOW() ELSE completion_date END
            WHERE id = ?
        ");
        $stmt->execute([
            $data['status'],
            $data['admin_notes'] ?? null,
            $resolved_at,
            $worker_id,
            $before_photo,
            $after_photo,
            $worker_notes,
            $data['status'],
            $ticketId
        ]);

        AuditLogger::log('UPDATE', 'MaintenanceTicket', $ticketId, "Status changed to {$data['status']}");
        echo json_encode(['message' => 'Ticket updated successfully']);
    }
}
