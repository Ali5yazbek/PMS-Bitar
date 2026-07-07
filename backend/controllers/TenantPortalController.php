<?php
class TenantPortalController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    private function getUserId() {
        AuthMiddleware::requireLogin();
        
        $headers = getallheaders();
        $token = str_replace('Bearer ', '', $headers['Authorization'] ?? '');
        $user = JWT::decode($token);
        
        if (!isset($user['role']) || $user['role'] !== 'tenant') {
            http_response_code(403);
            die(json_encode(['error' => 'Forbidden']));
        }

        return $user['user_id'];
    }

    public function dashboard() {
        $user_id = $this->getUserId();
        
        // Active contract info
        $stmt = $this->db->prepare("
            SELECT c.*, a.code as apartment_code, b.name as building_name 
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
        
        $stmt = $this->db->prepare("
            SELECT ri.*, 
                   (ri.amount - COALESCE((SELECT SUM(amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0)) as outstanding_debt,
                   COALESCE((SELECT SUM(amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0) as paid_amount,
                   a.code as apartment_code, b.name as building_name
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
        
        echo json_encode(['message' => 'Renewal declined successfully']);
    }
}
