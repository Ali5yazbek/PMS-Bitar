<?php
class TenantsController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function index() {
        $user = AuthMiddleware::requireLogin();
        
        $whereClause = "";
        if (isset($user['role']) && $user['role'] === 'agent') {
            $whereClause = "WHERE t.status != 'Terminated'";
        }

        $stmt = $this->db->query("
            SELECT t.*, c.id as contract_id, c.status as contract_status, c.rent_status, c.start_date, c.end_date, a.code as apartment_code, b.name as building_name, b.id as building_id,
                   rp.next_billing_date, rp.billing_frequency
            FROM tenants t
            LEFT JOIN contracts c ON t.id = c.tenant_id AND c.status IN ('Active', 'Approved')
            LEFT JOIN apartments a ON c.apartment_id = a.id
            LEFT JOIN buildings b ON a.building_id = b.id
            LEFT JOIN rent_profiles rp ON c.id = rp.contract_id
            $whereClause
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
            // --- NEW LOGIC: Generate ONLY the first invoice and setup the Rent Profile ---
            
            $currentPeriodStart = new DateTime($start_date);
            $endPeriod = new DateTime($end_date);
            
            $cycleEnd = clone $currentPeriodStart;
            $cycleEnd->modify('+1 month');
            $cycleEnd->modify('-1 day'); // Ensure the period is exactly 1 month
            
            if ($cycleEnd > $endPeriod) {
                $cycleEnd = clone $endPeriod;
            }

            $month = $currentPeriodStart->format('m');
            $year = $currentPeriodStart->format('Y');
            
            // Rent due at the end of the first cycle
            $due_date = $cycleEnd->format('Y-m-d');
            
            $invoice_num = 'INV-' . $year . $month . '-' . $contract_id;
            
            // 1. Insert the FIRST month's invoice
            $insertInvoice = $this->db->prepare("
                INSERT INTO rent_invoices (contract_id, invoice_number, amount, due_date, status, period_start, period_end) 
                VALUES (?, ?, ?, ?, 'Unpaid', ?, ?)
            ");
            $insertInvoice->execute([
                $contract_id, 
                $invoice_num, 
                $monthly_rent, 
                $due_date,
                $currentPeriodStart->format('Y-m-d'),
                $cycleEnd->format('Y-m-d')
            ]);

            // 2. Create the Rent Profile so the "Generate Next Rent" button works moving forward
            $nextBillingDate = clone $cycleEnd;
            $nextBillingDate->modify('+1 month +1 day'); // The next cycle starts the day after this cycle ends
            
            $insertProfile = $this->db->prepare("
                INSERT INTO rent_profiles (tenant_id, apartment_id, contract_id, rent_start_date, monthly_amount, next_billing_date, auto_renewal, notes)
                VALUES (?, ?, ?, ?, ?, ?, 0, 'Auto-created on tenant registration')
            ");
            $insertProfile->execute([
                $tenant_id,
                $apartment_id,
                $contract_id,
                $start_date,
                $monthly_rent,
                $nextBillingDate->format('Y-m-d')
            ]);
            
            // --- END NEW LOGIC ---

            // Update apartment status and sync rent price
            $this->db->prepare("UPDATE apartments SET status = 'Rented', monthly_rent = ?, monthly_insurance = ? WHERE id = ?")->execute([$monthly_rent, $monthly_insurance, $apartment_id]);

            $this->db->commit();
            AuditLogger::log('CREATE', 'Tenant', $tenant_id, "Assigned user {$user['name']} to apartment.");
            
            require_once __DIR__ . '/../core/DataQualityEngine.php';
            $engine = new DataQualityEngine();
            $stmtTenant = $this->db->prepare("SELECT * FROM tenants WHERE id = ?");
            $stmtTenant->execute([$tenant_id]);
            $engine->validateRecord('Tenant', 'tenants', $tenant_id, $stmtTenant->fetch(PDO::FETCH_ASSOC), $currentUser['user_id'] ?? 1);
            
            echo json_encode(['message' => 'Tenant registered successfully', 'id' => $tenant_id]);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function update($id) {
        $currentUser = AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        $stmt = $this->db->prepare("UPDATE tenants SET full_name = ?, phone = ?, email = ?, national_id = ?, address = ?, emergency_contact = ?, passport_url = ?, id_url = ?, status = ? WHERE id = ?");
        $stmt->execute([$data['full_name'], $data['phone'], $data['email'] ?? null, $data['national_id'], $data['address'] ?? null, $data['emergency_contact'] ?? null, $data['passport_url'] ?? null, $data['id_url'] ?? null, $data['status'] ?? 'Active', $id]);
        
        // Also update the user email if changed
        if (!empty($data['email'])) {
            $stmt = $this->db->prepare("UPDATE users SET email = ?, name = ? WHERE id = (SELECT user_id FROM tenants WHERE id = ?)");
            $stmt->execute([$data['email'], $data['full_name'], $id]);
        }
        
        AuditLogger::log('UPDATE', 'Tenant', $id, "Updated tenant details");
        
        require_once __DIR__ . '/../core/DataQualityEngine.php';
        $engine = new DataQualityEngine();
        $stmtTenant = $this->db->prepare("SELECT * FROM tenants WHERE id = ?");
        $stmtTenant->execute([$id]);
        $engine->validateRecord('Tenant', 'tenants', $id, $stmtTenant->fetch(PDO::FETCH_ASSOC), $currentUser['user_id'] ?? 1);
        
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

    public function terminate($id) {
        AuthMiddleware::requireLogin();
        
        try {
            $this->db->beginTransaction();

            // 1. FETCH ALL HISTORICAL RECORDS BEFORE TERMINATING

            // Fetch tenant details for archiving
            $tenantStmt = $this->db->prepare("SELECT * FROM tenants WHERE id = ?");
            $tenantStmt->execute([$id]);
            $tenant = $tenantStmt->fetch(PDO::FETCH_ASSOC);

            // Fetch documents for contact details
            $docStmt = $this->db->prepare("SELECT * FROM tenant_documents WHERE tenant_id = ? OR user_id = ?");
            $docStmt->execute([$id, $tenant['user_id'] ?? 0]);
            $documents = $docStmt->fetchAll(PDO::FETCH_ASSOC);
            
            $contactDetails = [
                'phone' => $tenant['phone'],
                'email' => $tenant['email'],
                'national_id_passport' => $tenant['national_id'],
                'documents' => $documents
            ];

            // Fetch all past and present contracts to get full ledger history
            $stmt = $this->db->prepare("
                SELECT c.*, a.code as apartment_code, b.name as building_name 
                FROM contracts c
                JOIN apartments a ON c.apartment_id = a.id
                JOIN buildings b ON a.building_id = b.id
                WHERE c.tenant_id = ?
            ");
            $stmt->execute([$id]);
            $allContracts = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Gather Data for Archiving
            $rentLedger = [];
            $utilityLedger = [];
            $insuranceRecords = [];
            $maintenanceHistory = [];
            $pastAptNumbers = [];

            if (!empty($allContracts)) {
                $contractIds = array_column($allContracts, 'id');
                $aptIds = array_column($allContracts, 'apartment_id');
                
                foreach ($allContracts as $c) {
                    $pastAptNumbers[] = $c['building_name'] . ' - ' . $c['apartment_code'];
                }
                
                $pastAptNumbers = array_unique($pastAptNumbers);

                $placeholders = implode(',', array_fill(0, count($contractIds), '?'));
                $aptPlaceholders = implode(',', array_fill(0, count($aptIds), '?'));

                // Rent Ledger (All time for this tenant)
                $rentStmt = $this->db->prepare("SELECT * FROM rent_invoices WHERE contract_id IN ($placeholders)");
                $rentStmt->execute($contractIds);
                $rentLedger = $rentStmt->fetchAll(PDO::FETCH_ASSOC);

                // Electricity Invoices
                $elecStmt = $this->db->prepare("SELECT * FROM electricity_invoices WHERE apartment_id IN ($aptPlaceholders)");
                $elecStmt->execute($aptIds);
                $utilityLedger['electricity'] = $elecStmt->fetchAll(PDO::FETCH_ASSOC);
            }

            // Maintenance
            $maintStmt = $this->db->prepare("SELECT * FROM tenant_maintenance_tickets WHERE tenant_id = ?");
            $maintStmt->execute([$id]);
            $maintenanceHistory = $maintStmt->fetchAll(PDO::FETCH_ASSOC);

            // 2. INSERT INTO ARCHIVE TABLE
            $insertArchive = $this->db->prepare("
                INSERT INTO tenant_archive_history 
                (original_tenant_id, full_name, national_id_passport, past_apartment_number, termination_date, termination_reason, contact_details, rental_ledger, utility_ledger, insurance_records, maintenance_history)
                VALUES (?, ?, ?, ?, CURRENT_DATE(), ?, ?, ?, ?, ?, ?)
            ");
            $insertArchive->execute([
                $tenant['id'],
                $tenant['full_name'],
                $tenant['national_id'],
                implode(', ', $pastAptNumbers),
                'Lease Terminated',
                json_encode($contactDetails),
                json_encode($rentLedger),
                json_encode($utilityLedger),
                json_encode($insuranceRecords),
                json_encode($maintenanceHistory)
            ]);

            // 3. NOW UPDATE ACTIVE TENANT / LEASE STATUS TO TERMINATED

            // Update the tenant state
            $updateTenant = $this->db->prepare("UPDATE tenants SET status = 'Terminated', move_out_date = CURRENT_DATE() WHERE id = ?");
            $updateTenant->execute([$id]);

            // Get active contracts for state updates
            $activeContractsStmt = $this->db->prepare("SELECT id, apartment_id FROM contracts WHERE tenant_id = ? AND status IN ('Active', 'Approved')");
            $activeContractsStmt->execute([$id]);
            $activeContracts = $activeContractsStmt->fetchAll(PDO::FETCH_ASSOC);

            // Mark contracts as Terminated
            $updateContract = $this->db->prepare("UPDATE contracts SET status = 'Terminated', end_date = CURRENT_DATE(), rent_status = 'Ended' WHERE tenant_id = ? AND status IN ('Active', 'Approved')");
            $updateContract->execute([$id]);

            // Prepare statements for loops
            $updateApt = $this->db->prepare("UPDATE apartments SET status = 'Vacant' WHERE id = ?");
            
            // 3. Void future invoices ONLY (Retain past Unpaid/Partial ones as debt)
            $voidInvoices = $this->db->prepare("UPDATE rent_invoices SET status = 'Voided' WHERE contract_id = ? AND due_date > CURRENT_DATE() AND status IN ('Unpaid', 'Partial', 'Overdue')");

            // 4. Disconnect associated services without deleting them
            $disconnectServices = $this->db->prepare("UPDATE electricity_subscriptions SET status = 'Disconnected' WHERE apartment_id = ? AND status = 'Active'");

            foreach ($activeContracts as $c) {
                // Free up the unit
                $updateApt->execute([$c['apartment_id']]);
                // Void pending future invoices for the contract
                $voidInvoices->execute([$c['id']]);
                // Disconnect electricity and generator subscriptions
                $disconnectServices->execute([$c['apartment_id']]);
            }
            
            AuditLogger::log('UPDATE', 'Tenant', $id, "Terminated lease for tenant ID: {$id}, voided future invoices, disconnected services, freed unit");
            
            $this->db->commit();
            echo json_encode(['message' => 'Lease terminated, unit freed, and pending invoices voided successfully.']);
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
        try {
            require_once __DIR__ . '/../services/RentGenerationService.php';
            RentGenerationService::catchUpForTenant((int)$id);
        } catch (Throwable $e) {
            error_log("Rent catch-up error for tenant $id: " . $e->getMessage());
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
                   a.code as apartment_code, b.name as building_name
            FROM rent_invoices ri
            JOIN contracts c ON ri.contract_id = c.id
            LEFT JOIN apartments a ON c.apartment_id = a.id
            LEFT JOIN buildings b ON a.building_id = b.id
            WHERE c.tenant_id = ?
            ORDER BY ri.due_date DESC
        ");
        $stmt->execute([$id]);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode(is_array($rows) ? $rows : []);
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

    public function getArchivedTenants() {
        AuthMiddleware::requireLogin();
        
        $stmt = $this->db->query("SELECT * FROM tenant_archive_history ORDER BY archived_at DESC");
        $archives = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Fallback logic for records that were created before the fix
        foreach ($archives as &$archive) {
            $tenantId = $archive['original_tenant_id'];

            // Safely parse JSON or Fallback to Live Queries
            $rentalLedger = $archive['rental_ledger'] ? json_decode($archive['rental_ledger'], true) : null;
            $utilityLedger = $archive['utility_ledger'] ? json_decode($archive['utility_ledger'], true) : null;
            $maintenanceHistory = $archive['maintenance_history'] ? json_decode($archive['maintenance_history'], true) : null;
            $contactDetails = $archive['contact_details'] ? json_decode($archive['contact_details'], true) : null;

            // FALLBACK for Rental Ledger
            if (empty($rentalLedger)) {
                // Find all past contracts to get rent invoices
                $contractStmt = $this->db->prepare("SELECT id FROM contracts WHERE tenant_id = ?");
                $contractStmt->execute([$tenantId]);
                $contractIds = $contractStmt->fetchAll(PDO::FETCH_COLUMN);
                
                if (!empty($contractIds)) {
                    $placeholders = implode(',', array_fill(0, count($contractIds), '?'));
                    $rentStmt = $this->db->prepare("SELECT * FROM rent_invoices WHERE contract_id IN ($placeholders)");
                    $rentStmt->execute($contractIds);
                    $rentalLedger = $rentStmt->fetchAll(PDO::FETCH_ASSOC);
                } else {
                    $rentalLedger = [];
                }
                $archive['rental_ledger'] = json_encode($rentalLedger);
            }

            // FALLBACK for Utility Ledger
            if (empty($utilityLedger)) {
                // Get apartment IDs for utilities
                $aptStmt = $this->db->prepare("SELECT DISTINCT apartment_id FROM contracts WHERE tenant_id = ?");
                $aptStmt->execute([$tenantId]);
                $aptIds = $aptStmt->fetchAll(PDO::FETCH_COLUMN);
                
                if (!empty($aptIds)) {
                    $placeholders = implode(',', array_fill(0, count($aptIds), '?'));
                    $elecStmt = $this->db->prepare("SELECT * FROM electricity_invoices WHERE apartment_id IN ($placeholders)");
                    $elecStmt->execute($aptIds);
                    $utilityLedger = ['electricity' => $elecStmt->fetchAll(PDO::FETCH_ASSOC)];
                } else {
                    $utilityLedger = [];
                }
                $archive['utility_ledger'] = json_encode($utilityLedger);
            }

            // FALLBACK for Maintenance History
            if (empty($maintenanceHistory)) {
                $maintStmt = $this->db->prepare("SELECT * FROM tenant_maintenance_tickets WHERE tenant_id = ?");
                $maintStmt->execute([$tenantId]);
                $maintenanceHistory = $maintStmt->fetchAll(PDO::FETCH_ASSOC);
                $archive['maintenance_history'] = json_encode($maintenanceHistory);
            }

            // FALLBACK for Contact Details
            if (empty($contactDetails)) {
                $tenantInfoStmt = $this->db->prepare("SELECT phone, email, national_id FROM tenants WHERE id = ?");
                $tenantInfoStmt->execute([$tenantId]);
                $tenantInfo = $tenantInfoStmt->fetch(PDO::FETCH_ASSOC) ?: [];
                
                $docStmt = $this->db->prepare("SELECT * FROM tenant_documents WHERE tenant_id = ?");
                $docStmt->execute([$tenantId]);
                $docs = $docStmt->fetchAll(PDO::FETCH_ASSOC);
                
                $contactDetails = [
                    'phone' => $tenantInfo['phone'] ?? null,
                    'email' => $tenantInfo['email'] ?? null,
                    'national_id_passport' => $tenantInfo['national_id'] ?? null,
                    'documents' => $docs
                ];
                $archive['contact_details'] = json_encode($contactDetails);
            }
        }
        
        echo json_encode($archives);
    }
}
