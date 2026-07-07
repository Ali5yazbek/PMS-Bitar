<?php
class TenantsController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function index() {
        AuthMiddleware::requireLogin();
        $stmt = $this->db->query("
            SELECT t.*, c.id as contract_id, c.status as contract_status, c.rent_status, c.start_date, c.end_date, a.code as apartment_code, b.name as building_name, b.id as building_id,
                   rp.next_billing_date, rp.billing_frequency
            FROM tenants t
            LEFT JOIN contracts c ON t.id = c.tenant_id AND c.status IN ('Active', 'Approved')
            LEFT JOIN apartments a ON c.apartment_id = a.id
            LEFT JOIN buildings b ON a.building_id = b.id
            LEFT JOIN rent_profiles rp ON c.id = rp.contract_id
            ORDER BY t.id DESC
        ");
        echo json_encode($stmt->fetchAll());
    }

    public function show($id) {
        AuthMiddleware::requireLogin();
        $stmt = $this->db->prepare("
            SELECT t.*, c.id as contract_id, c.status as contract_status, c.rent_status, c.start_date, c.end_date, a.code as apartment_code, b.name as building_name, a.monthly_rent, a.id as apartment_id,
                   es.status as generator_subscription
            FROM tenants t
            LEFT JOIN contracts c ON t.id = c.tenant_id AND c.status IN ('Active', 'Approved')
            LEFT JOIN apartments a ON c.apartment_id = a.id
            LEFT JOIN buildings b ON a.building_id = b.id
            LEFT JOIN electricity_subscriptions es ON a.id = es.apartment_id
            WHERE t.id = ?
        ");
        $stmt->execute([$id]);
        $tenant = $stmt->fetch();
        if ($tenant) {
            echo json_encode($tenant);
        } else {
            http_response_code(404);
            echo json_encode(['error' => 'Tenant not found']);
        }
    }

    public function store() {
        $currentUser = AuthMiddleware::requireLogin();
        
        // Handle multipart/form-data
        $user_id = $_POST['user_id'] ?? null;
        $apartment_id = $_POST['apartment_id'] ?? null;
        $start_date = $_POST['start_date'] ?? null;
        $end_date = $_POST['end_date'] ?? null;
        
        if (empty($user_id) || empty($apartment_id) || empty($start_date) || empty($end_date)) {
            http_response_code(400);
            echo json_encode(['error' => 'Missing required fields']);
            return;
        }

        try {
            $this->db->beginTransaction();

            // Fetch user details
            $userStmt = $this->db->prepare("SELECT name, email, phone, national_id FROM users WHERE id = ? AND role = 'tenant'");
            $userStmt->execute([$user_id]);
            $user = $userStmt->fetch();

            if (!$user) {
                throw new Exception("Selected user is not a valid tenant account.");
            }

            // Create tenant record linked to user
            $stmt = $this->db->prepare("INSERT INTO tenants (user_id, full_name, phone, email, national_id) VALUES (?, ?, ?, ?, ?)");
            $stmt->execute([$user_id, $user['name'], $user['phone'] ?? 'N/A', $user['email'], $user['national_id'] ?? 'N/A']);
            $tenant_id = $this->db->lastInsertId();

            // Handle file upload
            $contract_file_path = null;
            if (isset($_FILES['contract_file']) && $_FILES['contract_file']['error'] === UPLOAD_ERR_OK) {
                $uploadDir = __DIR__ . '/../uploads/contracts/';
                if (!is_dir($uploadDir)) {
                    mkdir($uploadDir, 0777, true);
                }
                
                $fileName = time() . '_' . basename($_FILES['contract_file']['name']);
                $targetFile = $uploadDir . $fileName;
                
                if (move_uploaded_file($_FILES['contract_file']['tmp_name'], $targetFile)) {
                    $contract_file_path = 'uploads/contracts/' . $fileName;
                }
            }

            // Optional cost overrides
            $monthly_rent = !empty($_POST['monthly_rent']) ? $_POST['monthly_rent'] : null;
            $monthly_insurance = !empty($_POST['monthly_insurance']) ? $_POST['monthly_insurance'] : null;

            // Insert into contracts (status Pending_Signature because it needs to be signed, or Active if they already uploaded a signed one)
            // Let's set it to Active for now, or 'Pending_Signature' if that exists in ENUM. The ENUM is 'Active', 'Terminated', 'Expired'. 
            // We'll just stick to Active, but they can upload the signed copy.
            $stmt = $this->db->prepare("INSERT INTO contracts (apartment_id, tenant_id, start_date, end_date, contract_file, monthly_rent, monthly_insurance, status) VALUES (?, ?, ?, ?, ?, ?, ?, 'Active')");
            $stmt->execute([$apartment_id, $tenant_id, $start_date, $end_date, $contract_file_path, $monthly_rent, $monthly_insurance]);
            $contract_id = $this->db->lastInsertId();

            // Create insurance account and initial deposit
            if ($monthly_insurance !== null && $monthly_insurance > 0) {
                $stmtInsCreate = $this->db->prepare("INSERT INTO insurance_accounts (contract_id, total_saved) VALUES (?, ?)");
                $stmtInsCreate->execute([$contract_id, $monthly_insurance]);
                $account_id = $this->db->lastInsertId();

                $stmtInsTrans = $this->db->prepare("INSERT INTO insurance_transactions (account_id, type, amount, date, user_id, notes) VALUES (?, 'Deposit', ?, CURRENT_DATE(), ?, 'Initial Insurance/Deposit (Auto-saved)')");
                $stmtInsTrans->execute([$account_id, $monthly_insurance, $currentUser['user_id'] ?? null]);
            } else {
                $stmtInsCreate = $this->db->prepare("INSERT INTO insurance_accounts (contract_id) VALUES (?)");
                $stmtInsCreate->execute([$contract_id]);
            }

            // Generate rent invoices for the contract duration
            $currentPeriodStart = new DateTime($start_date);
            $endPeriod = new DateTime($end_date);
            
            while ($currentPeriodStart < $endPeriod) {
                $cycleEnd = clone $currentPeriodStart;
                $cycleEnd->modify('+1 month');
                
                if ($cycleEnd > $endPeriod) {
                    $cycleEnd = clone $endPeriod;
                }

                $month = $currentPeriodStart->format('m');
                $year = $currentPeriodStart->format('Y');
                $due_date = $cycleEnd->format('Y-m-d');
                
                $invoice_num = 'INV-' . $year . $month . '-' . $contract_id;
                
                $insertInvoice = $this->db->prepare("INSERT INTO rent_invoices (contract_id, invoice_number, amount, due_date, status) VALUES (?, ?, ?, ?, 'Unpaid')");
                $insertInvoice->execute([$contract_id, $invoice_num, $monthly_rent, $due_date]);
                
                $currentPeriodStart->modify('+1 month');
            }

            // Update apartment status and sync rent price
            $this->db->prepare("UPDATE apartments SET status = 'Rented', monthly_rent = ?, monthly_insurance = ? WHERE id = ?")->execute([$monthly_rent, $monthly_insurance, $apartment_id]);

            $this->db->commit();
            AuditLogger::log('CREATE', 'Tenant', $tenant_id, "Assigned user {$user['name']} to apartment.");
            echo json_encode(['message' => 'Tenant registered successfully', 'id' => $tenant_id]);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function update($id) {
        AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        $stmt = $this->db->prepare("UPDATE tenants SET full_name = ?, phone = ?, email = ?, national_id = ?, address = ?, emergency_contact = ?, passport_url = ?, id_url = ?, status = ? WHERE id = ?");
        $stmt->execute([$data['full_name'], $data['phone'], $data['email'] ?? null, $data['national_id'], $data['address'] ?? null, $data['emergency_contact'] ?? null, $data['passport_url'] ?? null, $data['id_url'] ?? null, $data['status'] ?? 'Active', $id]);
        
        // Also update the user email if changed
        if (!empty($data['email'])) {
            $stmt = $this->db->prepare("UPDATE users SET email = ?, name = ? WHERE id = (SELECT user_id FROM tenants WHERE id = ?)");
            $stmt->execute([$data['email'], $data['full_name'], $id]);
        }
        
        AuditLogger::log('UPDATE', 'Tenant', $id, "Updated tenant details");
        
        echo json_encode(['message' => 'Tenant updated successfully']);
    }

    public function destroy($id) {
        AuthMiddleware::requireLogin();
        
        try {
            $this->db->beginTransaction();

            // Find apartment(s) linked to this tenant's active contracts before deleting
            $stmt = $this->db->prepare("SELECT apartment_id FROM contracts WHERE tenant_id = ? AND status = 'Active'");
            $stmt->execute([$id]);
            $apartments = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            AuditLogger::log('DELETE', 'Tenant', $id, "Deleted tenant ID: {$id}");
            
            // Delete tenant (cascades to contracts)
            $stmt = $this->db->prepare("DELETE FROM tenants WHERE id = ?");
            $stmt->execute([$id]);

            // Mark associated apartments as Vacant
            $updateStmt = $this->db->prepare("UPDATE apartments SET status = 'Vacant' WHERE id = ?");
            foreach ($apartments as $apt) {
                $updateStmt->execute([$apt['apartment_id']]);
            }
            
            $this->db->commit();
            echo json_encode(['message' => 'Tenant deleted successfully']);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => 'Database error: ' . $e->getMessage()]);
        }
    }

    public function updateContract($id) {
        AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        if (empty($data['start_date']) || empty($data['end_date'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Start date and end date are required']);
            return;
        }

        $stmt = $this->db->prepare("UPDATE contracts SET start_date = ?, end_date = ? WHERE tenant_id = ? AND status = 'Active'");
        $stmt->execute([$data['start_date'], $data['end_date'], $id]);
        
        AuditLogger::log('UPDATE', 'Tenant', $id, "Updated active contract dates to {$data['start_date']} - {$data['end_date']}");
        
        echo json_encode(['message' => 'Contract updated successfully']);
    }

    public function rentHistory($id) {
        AuthMiddleware::requireLogin();
        $stmt = $this->db->prepare("
            SELECT ri.*, 
                   (ri.amount - COALESCE((SELECT SUM(amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0)) as outstanding_debt,
                   COALESCE((SELECT SUM(amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0) as paid_amount,
                   a.code as apartment_code, b.name as building_name
            FROM rent_invoices ri
            JOIN contracts c ON ri.contract_id = c.id
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE c.tenant_id = ?
            ORDER BY ri.due_date DESC
        ");
        $stmt->execute([$id]);
        echo json_encode($stmt->fetchAll());
    }

    public function apartments($id) {
        AuthMiddleware::requireLogin();
        $stmt = $this->db->prepare("
            SELECT a.id as apartment_id, a.code as apartment_code, b.id as building_id, b.name as building_name, 
                   c.status as contract_status, c.id as contract_id, c.start_date, c.end_date
            FROM contracts c
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE c.tenant_id = ?
            ORDER BY c.start_date DESC
        ");
        $stmt->execute([$id]);
        echo json_encode($stmt->fetchAll());
    }
}
