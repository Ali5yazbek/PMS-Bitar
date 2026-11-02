<?php
class TenantDocumentsController {
    private $db;

    // Allowed document types
    private $validTypes = ['passport', 'national_id', 'work_contract'];

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    // ────────────────────────────────────────────────────────────────────────
    // Helper: resolve the user_id that owns a given tenant_id
    // ────────────────────────────────────────────────────────────────────────
    private function getUserIdForTenant($tenantId) {
        $stmt = $this->db->prepare("SELECT id, user_id, full_name, email, phone, national_id FROM tenants WHERE id = ? LIMIT 1");
        $stmt->execute([$tenantId]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$row) {
            return null;
        }

        if (!empty($row['user_id'])) {
            return (int)$row['user_id'];
        }

        // Auto-provision user account if tenant does not have a user_id
        $cleanName = strtolower(preg_replace('/[^a-zA-Z0-9]/', '', $row['full_name']));
        $username = $cleanName ?: 'tenant_' . $tenantId;
        $email = $row['email'] ?: ($username . '_' . $tenantId . '@bitar.local');

        $chk = $this->db->prepare("SELECT id FROM users WHERE email = ? OR username = ? LIMIT 1");
        $chk->execute([$email, $username]);
        $existingUserId = $chk->fetchColumn();

        if (!$existingUserId) {
            $uIns = $this->db->prepare("
                INSERT INTO users (name, username, email, password, role, phone, national_id)
                VALUES (?, ?, ?, ?, 'tenant', ?, ?)
            ");
            $uIns->execute([
                $row['full_name'],
                $username . '_' . $tenantId,
                $email,
                password_hash('password123', PASSWORD_DEFAULT),
                $row['phone'],
                $row['national_id']
            ]);
            $existingUserId = (int)$this->db->lastInsertId();
        }

        $updT = $this->db->prepare("UPDATE tenants SET user_id = ? WHERE id = ?");
        $updT->execute([$existingUserId, $tenantId]);
        return (int)$existingUserId;
    }

    // ────────────────────────────────────────────────────────────────────────
    // Helper: build the keyed result map from a list of rows
    // Priority: Verified > Uploaded > Pending > Requested > Missing/null
    // ────────────────────────────────────────────────────────────────────────
    private function buildDocMap(array $rows): array {
        $result = [
            'passport'      => null,
            'national_id'   => null,
            'work_contract' => null,
        ];
        foreach ($rows as $row) {
            if (array_key_exists($row['document_type'], $result) && $result[$row['document_type']] === null) {
                $result[$row['document_type']] = $row;
            }
        }
        return $result;
    }

    /**
     * GET /api/tenants/{id}/documents
     * Admin view: returns documents for the PERSON (user_id) associated with this tenant.
     * This means Apt A1 and Apt A2 of the same person share the same document set.
     */
    public function index($tenantId) {
        AuthMiddleware::requireLogin();

        $userId = $this->getUserIdForTenant($tenantId);
        if (!$userId) {
            http_response_code(404);
            echo json_encode(['error' => 'Tenant not found']);
            return;
        }

        // Fetch all docs for this user or tenant, best-status first
        $stmt = $this->db->prepare("
            SELECT d.*, u.name AS verified_by_name
            FROM tenant_documents d
            LEFT JOIN users u ON d.verified_by = u.id
            WHERE d.user_id = ? OR d.tenant_id = ?
            ORDER BY
                CASE
                    WHEN d.status = 'Verified'  THEN 1
                    WHEN d.status = 'Uploaded'  THEN 2
                    WHEN d.status = 'Pending'   THEN 3
                    WHEN d.status = 'Requested' THEN 4
                    ELSE 5
                END ASC, d.id DESC
        ");
        $stmt->execute([$userId, $tenantId]);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        echo json_encode($this->buildDocMap($rows ?: []));
    }

    /**
     * POST /api/tenants/{id}/documents/upload
     * Admin uploads a document for a tenant.
     * Document is stored against the user_id (person), not the tenant_id (lease).
     */
    public function upload($tenantId) {
        $user = AuthMiddleware::requireLogin();

        $userId = $this->getUserIdForTenant($tenantId);
        if (!$userId) {
            http_response_code(404);
            echo json_encode(['error' => 'Tenant not found']);
            return;
        }

        $docType = $_POST['document_type'] ?? null;
        if (!in_array($docType, $this->validTypes)) {
            http_response_code(400);
            echo json_encode(['error' => 'Invalid document_type. Must be one of: ' . implode(', ', $this->validTypes)]);
            return;
        }

        if (!isset($_FILES['file']) || $_FILES['file']['error'] !== UPLOAD_ERR_OK) {
            http_response_code(400);
            $errMsg = $_FILES['file']['error'] ?? 'No file uploaded';
            echo json_encode(['error' => 'File upload error: ' . $errMsg]);
            return;
        }

        // Validate MIME type
        $allowedMimes = ['image/jpeg', 'image/png', 'image/webp', 'application/pdf'];
        $finfo = new finfo(FILEINFO_MIME_TYPE);
        $mime  = $finfo->file($_FILES['file']['tmp_name']);
        if (!in_array($mime, $allowedMimes)) {
            http_response_code(400);
            echo json_encode(['error' => 'Only JPG, PNG, WEBP, and PDF files are allowed.']);
            return;
        }

        // Validate file size (max 10 MB)
        if ($_FILES['file']['size'] > 10 * 1024 * 1024) {
            http_response_code(400);
            echo json_encode(['error' => 'File size must be under 10 MB.']);
            return;
        }

        $uploadDir = __DIR__ . '/../uploads/tenant_documents/';
        if (!is_dir($uploadDir)) {
            mkdir($uploadDir, 0777, true);
        }

        $ext      = pathinfo($_FILES['file']['name'], PATHINFO_EXTENSION);
        $fileName = "user_{$userId}_{$docType}_" . time() . ".{$ext}";
        $target   = $uploadDir . $fileName;

        if (!move_uploaded_file($_FILES['file']['tmp_name'], $target)) {
            http_response_code(500);
            echo json_encode(['error' => 'Failed to save the uploaded file.']);
            return;
        }

        $fileUrl      = "uploads/tenant_documents/{$fileName}";
        $originalName = basename($_FILES['file']['name']);

        // Upsert by (user_id, document_type) — the new unique key
        $stmt = $this->db->prepare("
            INSERT INTO tenant_documents (user_id, tenant_id, document_type, file_url, original_filename, status, uploaded_at)
            VALUES (?, ?, ?, ?, ?, 'Uploaded', NOW())
            ON DUPLICATE KEY UPDATE
                tenant_id         = VALUES(tenant_id),
                file_url          = VALUES(file_url),
                original_filename = VALUES(original_filename),
                status            = 'Uploaded',
                uploaded_at       = NOW(),
                verified_at       = NULL,
                verified_by       = NULL
        ");
        $stmt->execute([$userId, $tenantId, $docType, $fileUrl, $originalName]);

        AuditLogger::log('CREATE', 'TenantDocument', $tenantId, "Document '{$docType}' uploaded by admin #{$user['user_id']} for user #{$userId}");
        echo json_encode(['message' => 'Document uploaded successfully', 'file_url' => $fileUrl]);
    }

    /**
     * PUT /api/tenant-documents/{id}/status
     * Admin sets status: Verified | Pending | Requested | Missing | Uploaded
     */
    public function updateStatus($docId) {
        $user = AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);

        $allowedStatuses = ['Uploaded', 'Verified', 'Pending', 'Missing', 'Requested'];
        if (empty($data['status']) || !in_array($data['status'], $allowedStatuses)) {
            http_response_code(400);
            echo json_encode(['error' => 'Invalid status.']);
            return;
        }

        $verified_at = ($data['status'] === 'Verified') ? date('Y-m-d H:i:s') : null;
        $verified_by = ($data['status'] === 'Verified') ? $user['user_id']     : null;

        $stmt = $this->db->prepare("
            UPDATE tenant_documents
            SET status = ?, admin_notes = ?, verified_at = ?, verified_by = ?
            WHERE id = ?
        ");
        $stmt->execute([
            $data['status'],
            $data['admin_notes'] ?? null,
            $verified_at,
            $verified_by,
            $docId
        ]);

        AuditLogger::log('UPDATE', 'TenantDocument', $docId, "Status set to {$data['status']} by admin #{$user['user_id']}");
        echo json_encode(['message' => 'Document status updated successfully']);
    }

    /**
     * PUT /api/tenants/{id}/documents/request
     * Admin marks a document type as "Requested" so the tenant re-uploads it.
     * Operates on the user_id level — affects the shared KYC document, not a specific lease copy.
     */
    public function requestDocument($tenantId) {
        $adminUser = AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);

        $docType = $data['document_type'] ?? null;
        if (!in_array($docType, $this->validTypes)) {
            http_response_code(400);
            echo json_encode(['error' => 'Invalid document_type.']);
            return;
        }

        $userId = $this->getUserIdForTenant($tenantId);
        if (!$userId) {
            http_response_code(404);
            echo json_encode(['error' => 'Tenant not found']);
            return;
        }

        $notes = $data['admin_notes'] ?? null;

        // Upsert by (user_id, document_type): update if exists, insert placeholder if not
        $stmt = $this->db->prepare("
            INSERT INTO tenant_documents (user_id, tenant_id, document_type, status, admin_notes)
            VALUES (?, ?, ?, 'Requested', ?)
            ON DUPLICATE KEY UPDATE
                status      = 'Requested',
                admin_notes = VALUES(admin_notes)
        ");
        $stmt->execute([$userId, $tenantId, $docType, $notes]);

        AuditLogger::log('UPDATE', 'TenantDocument', $tenantId, "Document '{$docType}' requested from user #{$userId} by admin #{$adminUser['user_id']}");
        echo json_encode(['message' => 'Document requested successfully']);
    }
}
