<?php
class ContractsController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function index() {
        AuthMiddleware::requireLogin();
        $stmt = $this->db->query("
            SELECT c.*, a.code as apartment_code, b.name as building_name, t.full_name as tenant_name
            FROM contracts c
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            JOIN tenants t ON c.tenant_id = t.id
            ORDER BY c.id DESC
        ");
        echo json_encode($stmt->fetchAll());
    }

    public function pending() {
        AuthMiddleware::requireLogin();
        $stmt = $this->db->query("
            SELECT c.*, a.code as apartment_code, b.name as building_name, t.full_name as tenant_name
            FROM contracts c
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            JOIN tenants t ON c.tenant_id = t.id
            WHERE c.status IN ('Pending_Signature', 'Signed', 'Rejected', 'Renewal_Pending')
            ORDER BY c.id DESC
        ");
        echo json_encode($stmt->fetchAll());
    }

    public function store() {
        $currentUser = AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        if (empty($data['apartment_id']) || empty($data['tenant_id']) || empty($data['start_date']) || empty($data['end_date'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Missing required fields']);
            return;
        }

        try {
            $this->db->beginTransaction();

            // Fetch apartment details for rent and insurance
            $stmt = $this->db->prepare("SELECT monthly_rent, monthly_insurance FROM apartments WHERE id = ?");
            $stmt->execute([$data['apartment_id']]);
            $apartment = $stmt->fetch();

            if (!$apartment) {
                throw new Exception("Apartment not found");
            }

            // RBAC: Agents cannot create contracts for Terminated tenants
            $tStmt = $this->db->prepare("SELECT status FROM tenants WHERE id = ?");
            $tStmt->execute([$data['tenant_id']]);
            $tRecord = $tStmt->fetch();
            if ($tRecord && $tRecord['status'] === 'Terminated' && isset($currentUser['role']) && $currentUser['role'] === 'agent') {
                throw new Exception("Agents are not authorized to create contracts for Terminated tenants.");
            }

            $monthly_rent = !empty($data['monthly_rent']) ? $data['monthly_rent'] : $apartment['monthly_rent'];
            $monthly_insurance = !empty($data['monthly_insurance']) ? $data['monthly_insurance'] : $apartment['monthly_insurance'];

            $rent_start = !empty($data['rent_start_date']) ? $data['rent_start_date'] : $data['start_date'];
            $rent_end = !empty($data['rent_end_date']) ? $data['rent_end_date'] : $data['end_date'];

            $stmt = $this->db->prepare("
                INSERT INTO contracts (apartment_id, tenant_id, start_date, end_date, rent_start_date, rent_end_date, monthly_rent, monthly_insurance, payment_terms, status, payment_method_rule) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'Draft', ?)
            ");
            
            $stmt->execute([
                $data['apartment_id'], 
                $data['tenant_id'], 
                $data['start_date'], 
                $data['end_date'],
                $rent_start,
                $rent_end,
                $monthly_rent,
                $monthly_insurance,
                $data['payment_terms'] ?? '',
                $data['payment_method_rule'] ?? 'Any Method'
            ]);
            
            $contract_id = $this->db->lastInsertId();

            $this->db->commit();
            AuditLogger::log('CREATE', 'Contract', $contract_id, "Created new draft contract for apartment ID: {$data['apartment_id']}.");
            
            echo json_encode(['message' => 'Contract draft created successfully', 'id' => $contract_id]);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function show($id) {
        AuthMiddleware::requireLogin();
        $stmt = $this->db->prepare("
            SELECT c.*, a.code as apartment_code, b.name as building_name, t.full_name as tenant_name, t.national_id, t.phone, t.email
            FROM contracts c
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            JOIN tenants t ON c.tenant_id = t.id
            WHERE c.id = ?
        ");
        $stmt->execute([$id]);
        $contract = $stmt->fetch();
        if ($contract) {
            echo json_encode($contract);
        } else {
            http_response_code(404);
            echo json_encode(['error' => 'Contract not found']);
        }
    }

    public function updateStatus($id) {
        $currentUser = AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        if (empty($data['status'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Status is required']);
            return;
        }

        try {
            $this->db->beginTransaction();

            $stmt = $this->db->prepare("SELECT * FROM contracts WHERE id = ?");
            $stmt->execute([$id]);
            $contract = $stmt->fetch();

            if (!$contract) {
                throw new Exception("Contract not found");
            }

            $status = $data['status'];
            
            $updateSql = "UPDATE contracts SET status = ?";
            $params = [$status];

            if ($status === 'Approved') {
                $updateSql .= ", manager_approval_date = NOW()";
                
                // Set apartment to rented
                $stmtApt = $this->db->prepare("UPDATE apartments SET status = 'Rented' WHERE id = ?");
                $stmtApt->execute([$contract['apartment_id']]);

                // Create insurance account if not exists
                $stmtIns = $this->db->prepare("SELECT id FROM insurance_accounts WHERE contract_id = ?");
                $stmtIns->execute([$id]);
                if (!$stmtIns->fetch()) {
                    $monthly_insurance = $contract['monthly_insurance'];
                    if ($monthly_insurance !== null && $monthly_insurance > 0) {
                        $stmtInsCreate = $this->db->prepare("INSERT INTO insurance_accounts (contract_id, total_saved) VALUES (?, ?)");
                        $stmtInsCreate->execute([$id, $monthly_insurance]);
                        $account_id = $this->db->lastInsertId();

                        $stmtInsTrans = $this->db->prepare("INSERT INTO insurance_transactions (account_id, type, amount, date, user_id, notes) VALUES (?, 'Deposit', ?, CURRENT_DATE(), ?, 'Initial Insurance/Deposit (Auto-saved)')");
                        $stmtInsTrans->execute([$account_id, $monthly_insurance, $currentUser['user_id'] ?? null]);
                    } else {
                        $stmtInsCreate = $this->db->prepare("INSERT INTO insurance_accounts (contract_id) VALUES (?)");
                        $stmtInsCreate->execute([$id]);
                    }
                }

                // Auto-generate ONLY the FIRST rent invoice if it doesn't exist
                $stmtInv = $this->db->prepare("SELECT id FROM rent_invoices WHERE contract_id = ? LIMIT 1");
                $stmtInv->execute([$id]);
                
                $cycleEnd = null;
                $currentPeriodStart = new DateTime($contract['rent_start_date'] ?? $contract['start_date']);
                
                if (!$stmtInv->fetch()) {
                    $monthly_rent = $contract['monthly_rent'];

                    $cycleEnd = clone $currentPeriodStart;
                    $cycleEnd->modify('+1 month');
                    // Subtract 1 day so the period is exactly 1 month (e.g. 05/07 to 04/08)
                    $cycleEnd->modify('-1 day');
                    
                    $month = $currentPeriodStart->format('m');
                    $year = $currentPeriodStart->format('Y');
                    $due_date = $currentPeriodStart->format('Y-m-d'); // Due at start of period
                    
                    $invoice_num = 'INV-' . $year . $month . '-' . $id;
                    
                    $insertInvoice = $this->db->prepare("
                        INSERT INTO rent_invoices (contract_id, invoice_number, amount, due_date, status, period_start, period_end) 
                        VALUES (?, ?, ?, ?, 'Unpaid', ?, ?)
                    ");
                    $insertInvoice->execute([$id, $invoice_num, $monthly_rent, $due_date, $currentPeriodStart->format('Y-m-d'), $cycleEnd->format('Y-m-d')]);
                } else {
                    $cycleEnd = clone $currentPeriodStart;
                    $cycleEnd->modify('+1 month');
                    $cycleEnd->modify('-1 day');
                }

                // Check if Rent Profile exists, if not, create it
                $stmtProf = $this->db->prepare("SELECT id FROM rent_profiles WHERE contract_id = ? LIMIT 1");
                $stmtProf->execute([$id]);
                if (!$stmtProf->fetch()) {
                    $nextBillingDate = clone $cycleEnd;
                    $nextBillingDate->modify('+1 day');
                    
                    $insertProfile = $this->db->prepare("
                        INSERT INTO rent_profiles (tenant_id, apartment_id, contract_id, rent_start_date, monthly_amount, next_billing_date, auto_renewal, notes)
                        VALUES (?, ?, ?, ?, ?, ?, 0, 'Auto-created on contract approval')
                    ");
                    $insertProfile->execute([
                        $contract['tenant_id'],
                        $contract['apartment_id'],
                        $id,
                        $contract['rent_start_date'] ?? $contract['start_date'],
                        $contract['monthly_rent'],
                        $nextBillingDate->format('Y-m-d')
                    ]);
                    $profileId = $this->db->lastInsertId();
                    
                    $this->db->prepare("INSERT INTO rent_profile_history (rent_profile_id, action, notes, user_id) VALUES (?, 'Created', 'Profile created automatically', ?)")
                             ->execute([$profileId, $currentUser['user_id'] ?? null]);
                }
            } else if ($status === 'Rejected' || $status === 'Terminated' || $status === 'Expired') {
                // Free the apartment
                $stmtApt = $this->db->prepare("UPDATE apartments SET status = 'Vacant' WHERE id = ?");
                $stmtApt->execute([$contract['apartment_id']]);
            }

            $updateSql .= " WHERE id = ?";
            $params[] = $id;

            $stmtUpdate = $this->db->prepare($updateSql);
            $stmtUpdate->execute($params);

            $this->db->commit();
            AuditLogger::log('UPDATE', 'Contract', $id, "Updated contract status to {$status}");
            
            echo json_encode(['message' => 'Contract status updated successfully']);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function update($id) {
        AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        try {
            $this->db->beginTransaction();

            $stmt = $this->db->prepare("SELECT * FROM contracts WHERE id = ?");
            $stmt->execute([$id]);
            $contract = $stmt->fetch();

            if (!$contract) {
                throw new Exception("Contract not found");
            }

            $rent_start = !empty($data['rent_start_date']) ? $data['rent_start_date'] : $data['start_date'];
            $rent_end = !empty($data['rent_end_date']) ? $data['rent_end_date'] : $data['end_date'];

            $newStatus = $contract['status'];
            if ($newStatus === 'Expired' && strtotime($data['end_date']) >= strtotime('today')) {
                $newStatus = 'Active';
            }

            $stmtUpdate = $this->db->prepare("
                UPDATE contracts 
                SET monthly_rent = ?, monthly_insurance = ?, start_date = ?, end_date = ?, rent_start_date = ?, rent_end_date = ?, payment_terms = ?, payment_method_rule = ?, status = ?
                WHERE id = ?
            ");
            $stmtUpdate->execute([
                $data['monthly_rent'],
                $data['monthly_insurance'],
                $data['start_date'],
                $data['end_date'],
                $rent_start,
                $rent_end,
                $data['payment_terms'],
                $data['payment_method_rule'] ?? 'Any Method',
                $newStatus,
                $id
            ]);

            $this->db->commit();
            AuditLogger::log('UPDATE', 'Contract', $id, "Updated contract details");
            
            echo json_encode(['message' => 'Contract updated successfully']);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function renewContract($id) {
        $currentUser = AuthMiddleware::requireLogin();

        try {
            $this->db->beginTransaction();

            $stmt = $this->db->prepare("SELECT * FROM contracts WHERE id = ?");
            $stmt->execute([$id]);
            $oldContract = $stmt->fetch();

            if (!$oldContract) {
                throw new Exception("Contract not found");
            }

            // Set old contract to expired
            $stmtUpdate = $this->db->prepare("UPDATE contracts SET status = 'Expired' WHERE id = ?");
            $stmtUpdate->execute([$id]);

            $data = json_decode(file_get_contents("php://input"), true);
            
            // Create new contract dates
            $startDate = !empty($data['start_date']) ? $data['start_date'] : $oldContract['end_date'];
            $endDate = !empty($data['end_date']) ? $data['end_date'] : date('Y-m-d', strtotime($startDate . ' + 30 days'));

            $stmtInsert = $this->db->prepare("
                INSERT INTO contracts (apartment_id, tenant_id, start_date, end_date, rent_start_date, rent_end_date, monthly_rent, monthly_insurance, payment_terms, status, manager_approval_date) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'Active', NOW())
            ");
            $stmtInsert->execute([
                $oldContract['apartment_id'],
                $oldContract['tenant_id'],
                $startDate,
                $endDate,
                $startDate,
                $endDate,
                $oldContract['monthly_rent'],
                $oldContract['monthly_insurance'],
                $oldContract['payment_terms']
            ]);

            $newContractId = $this->db->lastInsertId();

            // Transfer insurance deposit
            $stmtIns = $this->db->prepare("SELECT * FROM insurance_accounts WHERE contract_id = ?");
            $stmtIns->execute([$id]);
            $oldAccount = $stmtIns->fetch();

            if ($oldAccount) {
                $totalSaved = $oldAccount['total_saved'];
                
                // Deduct from old
                if ($totalSaved > 0) {
                    $stmtUpdateOldAcct = $this->db->prepare("UPDATE insurance_accounts SET total_saved = 0 WHERE id = ?");
                    $stmtUpdateOldAcct->execute([$oldAccount['id']]);

                    $stmtInsTransOut = $this->db->prepare("INSERT INTO insurance_transactions (account_id, type, amount, date, user_id, notes) VALUES (?, 'Deduction', ?, CURRENT_DATE(), ?, 'Transfer to renewed contract')");
                    $stmtInsTransOut->execute([$oldAccount['id'], $totalSaved, $currentUser['user_id'] ?? null]);
                }

                // Create new account
                $stmtInsCreate = $this->db->prepare("INSERT INTO insurance_accounts (contract_id, total_saved) VALUES (?, ?)");
                $stmtInsCreate->execute([$newContractId, $totalSaved]);
                $newAccountId = $this->db->lastInsertId();

                if ($totalSaved > 0) {
                    $stmtInsTransIn = $this->db->prepare("INSERT INTO insurance_transactions (account_id, type, amount, date, user_id, notes) VALUES (?, 'Deposit', ?, CURRENT_DATE(), ?, 'Transfer from old contract')");
                    $stmtInsTransIn->execute([$newAccountId, $totalSaved, $currentUser['user_id'] ?? null]);
                }
            } else {
                 $stmtInsCreate = $this->db->prepare("INSERT INTO insurance_accounts (contract_id) VALUES (?)");
                 $stmtInsCreate->execute([$newContractId]);
            }

            // Generate rent invoice for the new contract
            $invoice_num = 'INV-' . date('Ym', strtotime($startDate)) . '-' . $newContractId;
            // The rent for the new period is due on the END DATE of the period as requested
            $due_date = $endDate;
            
            $insertInvoice = $this->db->prepare("INSERT INTO rent_invoices (contract_id, invoice_number, amount, due_date, status) VALUES (?, ?, ?, ?, 'Unpaid')");
            $insertInvoice->execute([$newContractId, $invoice_num, $oldContract['monthly_rent'], $due_date]);

            $this->db->commit();
            AuditLogger::log('CREATE', 'Contract', $newContractId, "Renewed contract from old ID: {$id}");
            
            echo json_encode(['message' => 'Contract renewed successfully', 'new_contract_id' => $newContractId]);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    // Router alias — index.php calls 'generateMissingRent'
    public function generateMissingRent($id) { return $this->generateRent($id); }

    public function generateRent($id) {
        $currentUser = AuthMiddleware::requireLogin();
        require_once __DIR__ . '/../services/RentGenerationService.php';
        
        try {
            // First run due generation for this contract up to today
            $result = RentGenerationService::generateDueInvoices((int)$id);

            // If no invoices were generated because next_billing_date is in the future,
            // generate the upcoming cycle on demand
            if ($result['invoices_created'] === 0) {
                $stmt = $this->db->prepare("
                    SELECT rp.next_billing_date 
                    FROM rent_profiles rp 
                    WHERE rp.contract_id = ?
                ");
                $stmt->execute([$id]);
                $nextDate = $stmt->fetchColumn();
                if ($nextDate) {
                    $result = RentGenerationService::generateDueInvoices((int)$id, new DateTime($nextDate));
                }
            }

            if (!empty($result['errors'])) {
                throw new Exception($result['errors'][0]['error'] ?? 'Error generating rent');
            }

            // Fetch current updated next billing date
            $stmt = $this->db->prepare("
                SELECT rp.next_billing_date 
                FROM rent_profiles rp 
                WHERE rp.contract_id = ?
            ");
            $stmt->execute([$id]);
            $newBillingDate = $stmt->fetchColumn();

            echo json_encode([
                'success'           => true,
                'message'           => 'Next month rent generated successfully!',
                'invoices_created'  => $result['invoices_created'],
                'next_billing_date' => $newBillingDate,
                'details'           => $result['details']
            ]);

        } catch (Exception $e) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'error'   => $e->getMessage()
            ]);
        }
    }

    // --- Rent Management Endpoints ---

    public function pauseRent($id) {
        $user = AuthMiddleware::requireLogin();
        if (!in_array($user['role'], ['admin', 'manager'])) {
            http_response_code(403);
            echo json_encode(['error' => 'Forbidden']);
            return;
        }
        try {
            $this->db->beginTransaction();
            $stmt = $this->db->prepare("UPDATE contracts SET rent_status = 'Paused' WHERE id = ?");
            $stmt->execute([$id]);
            
            $stmtProf = $this->db->prepare("UPDATE rent_profiles SET status = 'Paused' WHERE contract_id = ?");
            $stmtProf->execute([$id]);

            $this->db->commit();
            AuditLogger::log('UPDATE', 'Contract', $id, "Paused rent for contract $id");
            echo json_encode(['message' => 'Rent paused successfully']);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function endRent($id) {
        return $this->closeRent($id);
    }

    public function closeRent($id) {
        $user = AuthMiddleware::requireLogin();
        if (!in_array($user['role'], ['admin', 'manager'])) {
            http_response_code(403);
            echo json_encode(['error' => 'Forbidden']);
            return;
        }
        try {
            $this->db->beginTransaction();
            $stmt = $this->db->prepare("UPDATE contracts SET rent_status = 'Closed' WHERE id = ?");
            $stmt->execute([$id]);

            $stmtProf = $this->db->prepare("UPDATE rent_profiles SET status = 'Closed' WHERE contract_id = ?");
            $stmtProf->execute([$id]);

            $this->db->commit();
            AuditLogger::log('UPDATE', 'Contract', $id, "Closed rent for contract $id");
            echo json_encode(['message' => 'Rent closed successfully']);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function resumeRent($id) {
        $user = AuthMiddleware::requireLogin();
        try {
            $this->db->beginTransaction();

            // Resume both the contract AND the rent profile
            $stmt = $this->db->prepare("UPDATE contracts SET rent_status = 'Active' WHERE id = ?");
            $stmt->execute([$id]);

            $stmtProf = $this->db->prepare("UPDATE rent_profiles SET status = 'Active' WHERE contract_id = ?");
            $stmtProf->execute([$id]);

            $this->db->commit();
            AuditLogger::log('UPDATE', 'Contract', $id, "Resumed rent for contract $id");
            echo json_encode(['message' => 'Rent resumed successfully']);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function renewRentManually($id) {
        $user = AuthMiddleware::requireLogin();
        try {
            // Find the latest invoice for this contract
            $stmt = $this->db->prepare("SELECT * FROM rent_invoices WHERE contract_id = ? ORDER BY period_end DESC LIMIT 1");
            $stmt->execute([$id]);
            $lastInvoice = $stmt->fetch();

            $stmt = $this->db->prepare("SELECT monthly_rent FROM contracts WHERE id = ?");
            $stmt->execute([$id]);
            $contract = $stmt->fetch();

            if (!$contract) throw new Exception("Contract not found");

            // Update status back to active in case it was paused
            $this->db->prepare("UPDATE contracts SET rent_status = 'Active' WHERE id = ?")->execute([$id]);

            $newStart = new DateTime();
            if ($lastInvoice && $lastInvoice['period_end']) {
                $newStart = new DateTime($lastInvoice['period_end']);
                $newStart->modify('+1 day');
            }

            $newEnd = clone $newStart;
            $newEnd->modify('+1 month');
            $newEnd->modify('-1 day');

            $month = $newStart->format('m');
            $year = $newStart->format('Y');
            $due_date = $newStart->format('Y-m-d');
            
            $invoice_num = 'INV-' . $year . $month . '-' . $id . '-M'; // M for Manual
            
            $insertInvoice = $this->db->prepare("
                INSERT INTO rent_invoices (contract_id, invoice_number, amount, due_date, status, period_start, period_end) 
                VALUES (?, ?, ?, ?, 'Unpaid', ?, ?)
            ");
            $insertInvoice->execute([$id, $invoice_num, $contract['monthly_rent'], $due_date, $newStart->format('Y-m-d'), $newEnd->format('Y-m-d')]);

            AuditLogger::log('UPDATE', 'Contract', $id, "Manually renewed rent for contract $id");
            echo json_encode(['message' => 'Rent renewed for another month successfully']);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function uploadFile($id) {
        $user = AuthMiddleware::requireLogin();
        
        try {
            $this->db->beginTransaction();

            $stmt = $this->db->prepare("SELECT * FROM contracts WHERE id = ?");
            $stmt->execute([$id]);
            $contract = $stmt->fetch();

            if (!$contract) {
                throw new Exception("Contract not found");
            }

            if (!isset($_FILES['contract_file']) || $_FILES['contract_file']['error'] !== UPLOAD_ERR_OK) {
                throw new Exception("No valid file uploaded.");
            }

            $fileTmpPath = $_FILES['contract_file']['tmp_name'];
            $fileName = $_FILES['contract_file']['name'];
            $fileExtension = strtolower(pathinfo($fileName, PATHINFO_EXTENSION));
            
            $allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'];
            if (!in_array($fileExtension, $allowedExtensions)) {
                throw new Exception("Invalid file extension.");
            }

            $uploadDir = __DIR__ . '/../uploads/contracts/';
            if (!is_dir($uploadDir)) {
                mkdir($uploadDir, 0777, true);
            }

            $newFileName = 'contract_' . $id . '_' . time() . '.' . $fileExtension;
            $destination = $uploadDir . $newFileName;

            if (move_uploaded_file($fileTmpPath, $destination)) {
                $dbPath = 'uploads/contracts/' . $newFileName;

                $stmtUpdate = $this->db->prepare("UPDATE contracts SET contract_file = ? WHERE id = ?");
                $stmtUpdate->execute([$dbPath, $id]);

                $this->db->commit();
                AuditLogger::log('UPDATE', 'Contract', $id, "Uploaded contract file");
                
                echo json_encode(['message' => 'Contract file uploaded successfully', 'file_path' => $dbPath]);
            } else {
                throw new Exception("Failed to move uploaded file.");
            }
        } catch (Exception $e) {
            if ($this->db->inTransaction()) {
                $this->db->rollBack();
            }
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }
}
