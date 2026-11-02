<?php
class TenantPortalController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    private function getUserId() {
        AuthMiddleware::requireLogin();

        // Use JWT::getBearerToken() instead of getallheaders() directly.
        // On Windows/Apache, getallheaders() returns keys in lowercase ('authorization'),
        // so $headers['Authorization'] is always null → JWT decodes empty string → user_id = null.
        $token = JWT::getBearerToken();
        $user  = JWT::decode($token);

        if (!$user || !isset($user['role']) || $user['role'] !== 'tenant') {
            http_response_code(403);
            die(json_encode(['error' => 'Forbidden']));
        }

        return (int)$user['user_id'];
    }

    public function dashboard() {
        $user_id = $this->getUserId();
        
        // Active contract info
        $stmt = $this->db->prepare("
            SELECT c.*, a.code as apartment_code, b.name as building_name, t.full_name, t.phone, t.email, t.national_id
            FROM contracts c 
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            JOIN tenants t ON c.tenant_id = t.id
            WHERE t.user_id = ? AND c.status IN ('Active', 'Pending_Signature', 'Signed', 'Approved', 'Renewal_Pending')
            ORDER BY c.id DESC
        ");
        $stmt->execute([$user_id]);
        $contracts = $stmt->fetchAll();

        echo json_encode([
            'contracts' => $contracts
        ]);
    }

    public function uploadSignedContract() {
        $user_id = $this->getUserId();
        
        // In a real scenario we'd parse multipart/form-data for the file or base64.
        // Assuming JSON with base64 for simplicity in this implementation.
        $data = json_decode(file_get_contents("php://input"), true);
        
        if (empty($data['contract_id']) || empty($data['document_url'])) {
            http_response_code(400);
            die(json_encode(['error' => 'Missing contract_id or document_url']));
        }

        $contract_id = $data['contract_id'];
        
        $stmt = $this->db->prepare("
            UPDATE contracts c
            JOIN tenants t ON c.tenant_id = t.id
            SET c.status = 'Signed', c.signed_document_url = ? 
            WHERE c.id = ? AND t.user_id = ?
        ");
        $stmt->execute([$data['document_url'], $contract_id, $user_id]);
        
        AuditLogger::log('UPDATE', 'Contract', $contract_id, "User ID {$user_id} uploaded signed contract");
        
        echo json_encode(['message' => 'Contract signed successfully']);
    }

    public function rentHistory() {
        $user_id = $this->getUserId();
        require_once __DIR__ . '/../services/RentGenerationService.php';

        // Find tenant_id for this user
        $stmtT = $this->db->prepare("SELECT id FROM tenants WHERE user_id = ?");
        $stmtT->execute([$user_id]);
        $tenantId = $stmtT->fetchColumn();
        if ($tenantId) {
            RentGenerationService::catchUpForTenant((int)$tenantId);
        }
        
        $stmt = $this->db->prepare("
            SELECT ri.id, ri.contract_id, ri.rent_profile_id, ri.rent_period_id, ri.invoice_number,
                   ri.amount, ri.period_start, ri.period_end, ri.due_date, ri.notes, ri.created_at,
                   ri.payment_method, ri.payment_date, ri.reference_number, ri.bank_name,
                   ri.account_number, ri.proof_of_payment, ri.qr_requested_at,
                   CASE 
                       WHEN ri.status = 'Voided' THEN 'Voided'
                       WHEN (ri.amount - COALESCE((SELECT SUM(amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0)) <= 0.001 AND ri.amount > 0 THEN 'Paid'
                       WHEN COALESCE((SELECT SUM(amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0) > 0 THEN 'Partial'
                       WHEN ri.due_date < CURRENT_DATE() THEN 'Overdue'
                       ELSE 'Unpaid'
                   END as status,
                   (ri.amount - COALESCE((SELECT SUM(amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0)) as outstanding_debt,
                   COALESCE((SELECT SUM(amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0) as paid_amount,
                   a.code as apartment_code, b.name as building_name,
                   t.id as tenant_id, a.id as apartment_id, b.id as building_id
            FROM rent_invoices ri
            JOIN contracts c ON ri.contract_id = c.id
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            JOIN tenants t ON c.tenant_id = t.id
            WHERE t.user_id = ?
            ORDER BY ri.due_date DESC
        ");
        $stmt->execute([$user_id]);
        echo json_encode($stmt->fetchAll());
    }

    public function requestRenewal() {
        $user_id = $this->getUserId();
        $data = json_decode(file_get_contents("php://input"), true);
        
        if (empty($data['contract_id'])) {
            http_response_code(400);
            die(json_encode(['error' => 'contract_id is required']));
        }

        $stmt = $this->db->prepare("SELECT c.id FROM contracts c JOIN tenants t ON c.tenant_id = t.id WHERE c.id = ? AND t.user_id = ?");
        $stmt->execute([$data['contract_id'], $user_id]);
        if (!$stmt->fetch()) {
            http_response_code(403);
            die(json_encode(['error' => 'Forbidden']));
        }
        
        $stmt = $this->db->prepare("INSERT INTO renewal_requests (contract_id, status) VALUES (?, 'Requested')");
        $stmt->execute([$data['contract_id']]);
        
        echo json_encode(['message' => 'Renewal requested successfully']);
    }

    public function declineRenewal() {
        $user_id = $this->getUserId();
        $data = json_decode(file_get_contents("php://input"), true);
        
        if (empty($data['contract_id'])) {
            http_response_code(400);
            die(json_encode(['error' => 'contract_id is required']));
        }

        $stmt = $this->db->prepare("SELECT c.id FROM contracts c JOIN tenants t ON c.tenant_id = t.id WHERE c.id = ? AND t.user_id = ?");
        $stmt->execute([$data['contract_id'], $user_id]);
        if (!$stmt->fetch()) {
            http_response_code(403);
            die(json_encode(['error' => 'Forbidden']));
        }
        
        $stmt = $this->db->prepare("INSERT INTO renewal_requests (contract_id, status) VALUES (?, 'Declined')");
        $stmt->execute([$data['contract_id']]);
        echo json_encode(['success' => true]);
    }
        
    public function getRentRequests() {
        $user_id = $this->getUserId();
        
        $stmt = $this->db->prepare("
            SELECT r.*, a.code as apartment_code, b.name as building_name, rp.start_date, rp.end_date 
            FROM rent_collection_requests r
            JOIN apartments a ON r.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            JOIN tenants t ON r.tenant_id = t.id
            JOIN rent_periods rp ON r.rent_period_id = rp.id
            WHERE t.user_id = ?
            ORDER BY r.created_at DESC
        ");
        $stmt->execute([$user_id]);
        echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
    }

    public function acceptRentRequest() {
        $user_id = $this->getUserId();
        $data = json_decode(file_get_contents("php://input"), true);
        
        if (empty($data['request_id']) || empty($data['collection_date'])) {
            http_response_code(400);
            die(json_encode(['error' => 'request_id and collection_date are required']));
        }

        $stmt = $this->db->prepare("
            SELECT r.*, rp.end_date, rp.start_date
            FROM rent_collection_requests r
            JOIN tenants t ON r.tenant_id = t.id
            JOIN rent_periods rp ON r.rent_period_id = rp.id
            WHERE r.id = ? AND t.user_id = ? AND r.status = 'PENDING_RESPONSE'
        ");
        $stmt->execute([$data['request_id'], $user_id]);
        $request = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$request) {
            http_response_code(403);
            die(json_encode(['error' => 'Invalid request or already processed']));
        }

        // Validate date
        $collectionDate = $data['collection_date'];
        $endDate = $request['end_date'];
        $startDate = $request['start_date'];
        $today = date('Y-m-d');

        if ($collectionDate < $today) {
            http_response_code(400);
            die(json_encode(['error' => 'Collection date cannot be in the past']));
        }
        if ($collectionDate >= $endDate) {
            http_response_code(400);
            die(json_encode(['error' => 'Collection date must be before the rent expiration date']));
        }
        if ($collectionDate < $startDate) {
            http_response_code(400);
            die(json_encode(['error' => 'Collection date must be within the rent period']));
        }

        $stmtUpdate = $this->db->prepare("
            UPDATE rent_collection_requests 
            SET status = 'SCHEDULED', requested_collection_date = ?, confirmed_at = NOW()
            WHERE id = ?
        ");
        $stmtUpdate->execute([$collectionDate, $data['request_id']]);

        // Agent notification removed as per Step 1 instructions ("Do NOT notify the Agent yet.")

        echo json_encode(['message' => 'Request accepted and scheduled successfully']);
    }

    public function denyRentRequest() {
        $user_id = $this->getUserId();
        $data = json_decode(file_get_contents("php://input"), true);
        
        if (empty($data['request_id']) || empty($data['reason'])) {
            http_response_code(400);
            die(json_encode(['error' => 'request_id and reason are required']));
        }

        $stmt = $this->db->prepare("
            SELECT r.* 
            FROM rent_collection_requests r
            JOIN tenants t ON r.tenant_id = t.id
            WHERE r.id = ? AND t.user_id = ? AND r.status = 'PENDING_RESPONSE'
        ");
        $stmt->execute([$data['request_id'], $user_id]);
        $request = $stmt->fetch();

        if (!$request) {
            http_response_code(403);
            die(json_encode(['error' => 'Invalid request or already processed']));
        }

        $stmtUpdate = $this->db->prepare("
            UPDATE rent_collection_requests 
            SET status = 'DENIED', denial_reason = ?, denied_at = NOW()
            WHERE id = ?
        ");
        $stmtUpdate->execute([$data['reason'], $data['request_id']]);

        echo json_encode(['message' => 'Request denied successfully']);
    }

    // ════════════════════════════════════════════════════════════════════════
    // TENANT DOCUMENTS (tenant-facing — authenticated by tenant JWT)
    // ════════════════════════════════════════════════════════════════════════

    /** GET /api/tenant-portal/documents */
    public function getMyDocuments() {
        $user_id = $this->getUserId();

        // Documents are now keyed by user_id (the person), not tenant_id (the lease).
        // Best-status wins: Verified > Uploaded > Pending > Requested > Missing
        $stmt = $this->db->prepare("
            SELECT d.*, u.name AS verified_by_name
            FROM tenant_documents d
            LEFT JOIN users u ON d.verified_by = u.id
            WHERE d.user_id = ?
            ORDER BY
                CASE
                    WHEN d.status = 'Verified'  THEN 1
                    WHEN d.status = 'Uploaded'  THEN 2
                    WHEN d.status = 'Pending'   THEN 3
                    WHEN d.status = 'Requested' THEN 4
                    ELSE 5
                END ASC, d.id DESC
        ");
        $stmt->execute([$user_id]);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $result = ['passport' => null, 'national_id' => null, 'work_contract' => null];
        foreach ($rows as $row) {
            if (array_key_exists($row['document_type'], $result) && $result[$row['document_type']] === null) {
                $result[$row['document_type']] = $row;
            }
        }
        echo json_encode($result);
    }

    /** POST /api/tenant-portal/documents/upload */
    public function uploadMyDocument() {
        $user_id = $this->getUserId();

        // Resolve the primary tenant_id for this user (stored as reference on the document)
        $tStmt = $this->db->prepare("SELECT id FROM tenants WHERE user_id = ? ORDER BY id ASC LIMIT 1");
        $tStmt->execute([$user_id]);
        $tenant = $tStmt->fetch(PDO::FETCH_ASSOC);
        if (!$tenant) {
            http_response_code(404);
            die(json_encode(['error' => 'Tenant profile not found']));
        }
        $tenantId = $tenant['id'];

        $validTypes = ['passport', 'national_id', 'work_contract'];
        $docType    = $_POST['document_type'] ?? null;

        if (!in_array($docType, $validTypes)) {
            http_response_code(400);
            die(json_encode(['error' => 'Invalid document_type']));
        }
        if (!isset($_FILES['file']) || $_FILES['file']['error'] !== UPLOAD_ERR_OK) {
            http_response_code(400);
            die(json_encode(['error' => 'No valid file uploaded. Error code: ' . ($_FILES['file']['error'] ?? 'none')]));
        }

        $allowedMimes = ['image/jpeg', 'image/png', 'image/webp', 'application/pdf'];
        $finfo = new finfo(FILEINFO_MIME_TYPE);
        $mime  = $finfo->file($_FILES['file']['tmp_name']);
        if (!in_array($mime, $allowedMimes)) {
            http_response_code(400);
            die(json_encode(['error' => 'Only JPG, PNG, WEBP and PDF allowed']));
        }
        if ($_FILES['file']['size'] > 10 * 1024 * 1024) {
            http_response_code(400);
            die(json_encode(['error' => 'File must be under 10 MB']));
        }

        $uploadDir = __DIR__ . '/../uploads/tenant_documents/';
        if (!is_dir($uploadDir)) mkdir($uploadDir, 0777, true);

        $ext      = pathinfo($_FILES['file']['name'], PATHINFO_EXTENSION);
        $fileName = "user_{$user_id}_{$docType}_" . time() . ".{$ext}";
        if (!move_uploaded_file($_FILES['file']['tmp_name'], $uploadDir . $fileName)) {
            http_response_code(500);
            die(json_encode(['error' => 'Failed to save file']));
        }

        $fileUrl      = "uploads/tenant_documents/{$fileName}";
        $originalName = basename($_FILES['file']['name']);

        // Upsert by (user_id, document_type) — the new unique key.
        // ON DUPLICATE KEY covers both first-upload and re-upload cases in one query.
        $stmt = $this->db->prepare("
            INSERT INTO tenant_documents
                (user_id, tenant_id, document_type, file_url, original_filename, status, uploaded_at)
            VALUES (?, ?, ?, ?, ?, 'Uploaded', NOW())
            ON DUPLICATE KEY UPDATE
                file_url          = VALUES(file_url),
                original_filename = VALUES(original_filename),
                status            = 'Uploaded',
                uploaded_at       = NOW(),
                verified_at       = NULL,
                verified_by       = NULL
        ");
        $stmt->execute([$user_id, $tenantId, $docType, $fileUrl, $originalName]);

        AuditLogger::log('CREATE', 'TenantDocument', $tenantId, "Tenant (user #{$user_id}) uploaded '{$docType}'");
        echo json_encode(['message' => 'Document uploaded successfully', 'file_url' => $fileUrl]);
    }

    // ════════════════════════════════════════════════════════════════════════
    // TENANT MAINTENANCE TICKETS (tenant-facing)
    // ════════════════════════════════════════════════════════════════════════

    /** GET /api/tenant-portal/maintenance-tickets */
    public function getMyMaintenanceTickets() {
        $user_id = $this->getUserId();

        $stmt = $this->db->prepare("
            SELECT tmt.*, a.code AS apartment_code, b.name AS building_name
            FROM tenant_maintenance_tickets tmt
            JOIN tenants t ON tmt.tenant_id = t.id
            LEFT JOIN apartments a ON tmt.apartment_id = a.id
            LEFT JOIN buildings  b ON a.building_id    = b.id
            WHERE t.user_id = ?
            ORDER BY tmt.created_at DESC
        ");
        $stmt->execute([$user_id]);
        echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
    }

    /** POST /api/tenant-portal/maintenance-tickets */
    public function submitMyMaintenanceTicket() {
        $user_id = $this->getUserId();

        $stmt = $this->db->prepare("SELECT id FROM tenants WHERE user_id = ? LIMIT 1");
        $stmt->execute([$user_id]);
        $tenant = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$tenant) { http_response_code(404); die(json_encode(['error' => 'Tenant profile not found'])); }

        $data = json_decode(file_get_contents("php://input"), true);
        if (empty($data['title']) || empty($data['description'])) {
            http_response_code(400); die(json_encode(['error' => 'Title and description are required']));
        }
        
        $apartment_id = null;
        if (!empty($data['apartment_id'])) {
            $apartment_id = $data['apartment_id'];
        } else {
            // fallback if not provided
            $aptStmt = $this->db->prepare("
                SELECT c.apartment_id FROM contracts c
                JOIN tenants t ON c.tenant_id = t.id
                WHERE t.user_id = ? AND c.status IN ('Active', 'Approved')
                ORDER BY c.id DESC LIMIT 1
            ");
            $aptStmt->execute([$user_id]);
            $contract = $aptStmt->fetch(PDO::FETCH_ASSOC);
            $apartment_id = $contract ? $contract['apartment_id'] : null;
        }

        $stmt = $this->db->prepare("
            INSERT INTO tenant_maintenance_tickets
                (tenant_id, apartment_id, title, description, category, priority, status, submitted_by)
            VALUES (?, ?, ?, ?, ?, ?, 'Open', ?)
        ");
        
        // Find the specific tenant_id linked to this apartment_id for this user
        $tenantStmt = $this->db->prepare("
            SELECT t.id FROM contracts c 
            JOIN tenants t ON c.tenant_id = t.id 
            WHERE t.user_id = ? AND c.apartment_id = ? 
            LIMIT 1
        ");
        $tenantStmt->execute([$user_id, $apartment_id]);
        $specificTenant = $tenantStmt->fetch(PDO::FETCH_ASSOC);
        $final_tenant_id = $specificTenant ? $specificTenant['id'] : $tenant['id'];

        $stmt->execute([
            $final_tenant_id,
            $apartment_id,
            trim($data['title']),
            trim($data['description']),
            $data['category'] ?? null,
            $data['priority'] ?? 'Medium',
            $user_id
        ]);

        $id = $this->db->lastInsertId();
        AuditLogger::log('CREATE', 'MaintenanceTicket', $id, "Tenant #{$final_tenant_id} submitted ticket");
        http_response_code(201);
        echo json_encode(['message' => 'Ticket submitted successfully', 'id' => $id]);
    }

    public function getMyApartments() {
        $user_id = $this->getUserId();
        
        $stmt = $this->db->prepare("
            SELECT DISTINCT a.id, a.code as apartment_code, b.name as building_name
            FROM contracts c
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            JOIN tenants t ON c.tenant_id = t.id
            WHERE t.user_id = ? AND c.status IN ('Active', 'Approved', 'Renewal_Pending', 'Signed')
        ");
        $stmt->execute([$user_id]);
        echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
    }
}

