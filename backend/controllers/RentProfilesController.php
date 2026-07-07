<?php
require_once __DIR__ . '/../core/Database.php';
require_once __DIR__ . '/../middleware/AuthMiddleware.php';
require_once __DIR__ . '/../utils/AuditLogger.php';

class RentProfilesController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    private function logHistory($profileId, $action, $prevValue, $newValue, $notes, $userId) {
        $stmt = $this->db->prepare("
            INSERT INTO rent_profile_history (rent_profile_id, action, previous_value, new_value, notes, user_id)
            VALUES (?, ?, ?, ?, ?, ?)
        ");
        $stmt->execute([$profileId, $action, $prevValue, $newValue, $notes, $userId]);
    }

    public function getByTenant($tenantId) {
        AuthMiddleware::requireLogin();
        
        $stmt = $this->db->prepare("SELECT * FROM rent_profiles WHERE tenant_id = ? ORDER BY id DESC LIMIT 1");
        $stmt->execute([$tenantId]);
        $profile = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$profile) {
            echo json_encode(null);
            return;
        }

        echo json_encode($profile);
    }

    public function update($id) {
        $user = AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        try {
            $this->db->beginTransaction();

            $stmt = $this->db->prepare("SELECT * FROM rent_profiles WHERE id = ?");
            $stmt->execute([$id]);
            $profile = $stmt->fetch(PDO::FETCH_ASSOC);

            if (!$profile) throw new Exception("Rent Profile not found");

            $updates = [];
            $params = [];

            // Tracking changes for history
            $changes = [];

            if (isset($data['auto_renewal']) && $profile['auto_renewal'] != $data['auto_renewal']) {
                $updates[] = "auto_renewal = ?";
                $params[] = $data['auto_renewal'] ? 1 : 0;
                $changes[] = ['action' => 'Auto Renewal Changed', 'prev' => $profile['auto_renewal'] ? 'On' : 'Off', 'new' => $data['auto_renewal'] ? 'On' : 'Off'];
            }

            if (isset($data['billing_frequency']) && $profile['billing_frequency'] !== $data['billing_frequency']) {
                $updates[] = "billing_frequency = ?";
                $params[] = $data['billing_frequency'];
                $changes[] = ['action' => 'Billing Frequency Changed', 'prev' => $profile['billing_frequency'], 'new' => $data['billing_frequency']];
            }

            if (isset($data['monthly_amount']) && $profile['monthly_amount'] !== $data['monthly_amount']) {
                $updates[] = "monthly_amount = ?";
                $params[] = $data['monthly_amount'];
                $changes[] = ['action' => 'Monthly Amount Changed', 'prev' => $profile['monthly_amount'], 'new' => $data['monthly_amount']];
            }

            if (isset($data['status']) && $profile['status'] !== $data['status']) {
                $updates[] = "status = ?";
                $params[] = $data['status'];
                $changes[] = ['action' => 'Status Changed', 'prev' => $profile['status'], 'new' => $data['status']];
            }

            if (isset($data['default_payment_method']) && $profile['default_payment_method'] !== $data['default_payment_method']) {
                $updates[] = "default_payment_method = ?";
                $params[] = $data['default_payment_method'];
                $changes[] = ['action' => 'Default Payment Method Changed', 'prev' => $profile['default_payment_method'] ?? 'None', 'new' => $data['default_payment_method']];
            }

            if (count($updates) > 0) {
                $params[] = $id;
                $sql = "UPDATE rent_profiles SET " . implode(', ', $updates) . " WHERE id = ?";
                $stmtUpdate = $this->db->prepare($sql);
                $stmtUpdate->execute($params);

                foreach ($changes as $change) {
                    $this->logHistory($id, $change['action'], $change['prev'], $change['new'], 'Updated manually via API', $user['user_id']);
                }
            }

            $this->db->commit();
            echo json_encode(['message' => 'Rent Profile updated successfully']);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function renew($id) {
        $user = AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        $action = $data['action'] ?? null; // 'renew_same', 'renew_new', 'skip'
        $newAmount = $data['new_amount'] ?? null;

        try {
            $this->db->beginTransaction();

            $stmt = $this->db->prepare("SELECT * FROM rent_profiles WHERE id = ?");
            $stmt->execute([$id]);
            $profile = $stmt->fetch(PDO::FETCH_ASSOC);

            if (!$profile) throw new Exception("Rent Profile not found");

            $currentBillingDate = new DateTime($profile['next_billing_date']);
            $nextBillingDate = clone $currentBillingDate;
            
            // Calculate next cycle based on frequency
            if ($profile['billing_frequency'] === 'Weekly') $nextBillingDate->modify('+1 week');
            else if ($profile['billing_frequency'] === 'Quarterly') $nextBillingDate->modify('+3 months');
            else if ($profile['billing_frequency'] === 'Yearly') $nextBillingDate->modify('+1 year');
            else $nextBillingDate->modify('+1 month'); // Default Monthly

            $amountToBill = $profile['monthly_amount'];
            $invoice_num = 'INV-' . date('Ym') . '-' . $profile['contract_id'] . '-' . rand(100, 999);

            if ($action === 'renew_new' && $newAmount) {
                $amountToBill = $newAmount;
                // Also update the profile amount for future?
                $stmtUp = $this->db->prepare("UPDATE rent_profiles SET monthly_amount = ? WHERE id = ?");
                $stmtUp->execute([$amountToBill, $id]);
                $this->logHistory($id, 'Monthly Amount Changed (Renewal)', $profile['monthly_amount'], $amountToBill, null, $user['user_id']);
            }

            if ($action === 'renew_same' || $action === 'renew_new') {
                // Determine period start and end for the invoice
                $periodStart = $currentBillingDate->format('Y-m-d');
                $periodEnd = clone $nextBillingDate;
                $periodEnd->modify('-1 day'); // Because periods are inclusive
                
                $insertInvoice = $this->db->prepare("
                    INSERT INTO rent_invoices (contract_id, invoice_number, amount, due_date, status, period_start, period_end) 
                    VALUES (?, ?, ?, ?, 'Unpaid', ?, ?)
                ");
                $insertInvoice->execute([
                    $profile['contract_id'], 
                    $invoice_num, 
                    $amountToBill, 
                    $periodStart, 
                    $periodStart, 
                    $periodEnd->format('Y-m-d')
                ]);
                $this->logHistory($id, 'Rent Renewed', $profile['next_billing_date'], $nextBillingDate->format('Y-m-d'), "Generated invoice $invoice_num", $user['user_id']);
            } else if ($action === 'skip') {
                $this->logHistory($id, 'Billing Cycle Skipped', $profile['next_billing_date'], $nextBillingDate->format('Y-m-d'), "Skipped 1 billing cycle without generating invoice", $user['user_id']);
            } else {
                throw new Exception("Invalid renewal action");
            }

            // Update profile with next billing date and make sure status is Active
            $stmtUp = $this->db->prepare("UPDATE rent_profiles SET next_billing_date = ?, status = 'Active' WHERE id = ?");
            $stmtUp->execute([$nextBillingDate->format('Y-m-d'), $id]);

            $this->db->commit();
            echo json_encode(['message' => 'Rent successfully renewed for the next cycle']);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }
    
    public function getHistory($id) {
        AuthMiddleware::requireLogin();
        $stmt = $this->db->prepare("
            SELECT h.*, u.name as user_name 
            FROM rent_profile_history h
            LEFT JOIN users u ON h.user_id = u.id
            WHERE h.rent_profile_id = ?
            ORDER BY h.created_at DESC
        ");
        $stmt->execute([$id]);
        echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
    }

    public function processAutoRenewals() {
        // Can be called by a cron job or admin
        // AuthMiddleware::requireLogin(); // Or an API key check if it's a cron
        
        try {
            $this->db->beginTransaction();

            $stmt = $this->db->query("
                SELECT * FROM rent_profiles 
                WHERE status = 'Active' 
                AND auto_renewal = 1 
                AND next_billing_date <= CURRENT_DATE()
            ");
            $profiles = $stmt->fetchAll(PDO::FETCH_ASSOC);

            $processedCount = 0;

            foreach ($profiles as $profile) {
                $currentBillingDate = new DateTime($profile['next_billing_date']);
                $nextBillingDate = clone $currentBillingDate;
                
                if ($profile['billing_frequency'] === 'Weekly') $nextBillingDate->modify('+1 week');
                else if ($profile['billing_frequency'] === 'Quarterly') $nextBillingDate->modify('+3 months');
                else if ($profile['billing_frequency'] === 'Yearly') $nextBillingDate->modify('+1 year');
                else $nextBillingDate->modify('+1 month'); // Default Monthly

                $invoice_num = 'INV-' . date('Ym') . '-' . $profile['contract_id'] . '-' . rand(100, 999);
                
                $periodStart = $currentBillingDate->format('Y-m-d');
                $periodEnd = clone $nextBillingDate;
                $periodEnd->modify('-1 day'); 
                
                $insertInvoice = $this->db->prepare("
                    INSERT INTO rent_invoices (contract_id, invoice_number, amount, due_date, status, period_start, period_end) 
                    VALUES (?, ?, ?, ?, 'Unpaid', ?, ?)
                ");
                $insertInvoice->execute([
                    $profile['contract_id'], 
                    $invoice_num, 
                    $profile['monthly_amount'], 
                    $periodStart, 
                    $periodStart, 
                    $periodEnd->format('Y-m-d')
                ]);

                $this->logHistory($profile['id'], 'Auto Renewed', $profile['next_billing_date'], $nextBillingDate->format('Y-m-d'), "System auto-generated invoice $invoice_num", null);

                $stmtUp = $this->db->prepare("UPDATE rent_profiles SET next_billing_date = ? WHERE id = ?");
                $stmtUp->execute([$nextBillingDate->format('Y-m-d'), $profile['id']]);
                
                $processedCount++;
            }

            $this->db->commit();
            echo json_encode(['message' => "$processedCount auto-renewals processed successfully"]);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }
}
