<?php
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../core/Database.php';

class NotificationScheduler {
    public static function run() {
        $db = \Database::getInstance()->getConnection();
        $startTime = microtime(true);
        $records = 0;
        $status = 'Success';
        $error = null;

        try {
            $db->beginTransaction();

            // Find all active contracts where the current period expires in exactly 7 days
            $stmt = $db->query("
                SELECT c.*, 
                       (SELECT MAX(end_date) FROM rent_periods WHERE contract_id = c.id) as latest_end_date
                FROM contracts c
                WHERE c.status = 'Active' AND c.deleted_at IS NULL
            ");
            
            $contracts = $stmt->fetchAll(PDO::FETCH_ASSOC);
            $targetDate = date('Y-m-d', strtotime('+7 days'));

            foreach ($contracts as $c) {
                $dueDate = $c['latest_end_date'] ?: $c['start_date'];
                
                // If it expires in exactly 7 days
                if ($dueDate === $targetDate) {
                    
                    $stmtPeriod = $db->prepare("SELECT id FROM rent_periods WHERE contract_id = ? AND end_date = ?");
                    $stmtPeriod->execute([$c['id'], $dueDate]);
                    $periodId = $stmtPeriod->fetchColumn();

                    if ($periodId) {
                        // Check if a request already exists to ensure idempotency
                        $stmtCheck = $db->prepare("SELECT id FROM rent_collection_requests WHERE contract_id = ? AND rent_period_id = ?");
                        $stmtCheck->execute([$c['id'], $periodId]);
                        $existingReq = $stmtCheck->fetchColumn();

                        if (!$existingReq) {
                            // Find assigned agent
                            $stmtAgent = $db->prepare("SELECT agent_id FROM field_agent_assignments WHERE building_id = (SELECT building_id FROM apartments WHERE id = ?)");
                            $stmtAgent->execute([$c['apartment_id']]);
                            $agentId = $stmtAgent->fetchColumn();

                            // Get building and apartment name for notification
                            $stmtApt = $db->prepare("SELECT a.code as apartment_code, b.name as building_name FROM apartments a JOIN buildings b ON a.building_id = b.id WHERE a.id = ?");
                            $stmtApt->execute([$c['apartment_id']]);
                            $aptInfo = $stmtApt->fetch(PDO::FETCH_ASSOC);

                            // Get amount from contract
                            $amount = $c['monthly_rent'] ?? 0;

                            $stmtReq = $db->prepare("
                                INSERT INTO rent_collection_requests (tenant_id, contract_id, apartment_id, rent_period_id, amount, status, assigned_agent_id) 
                                VALUES (?, ?, ?, ?, ?, 'PENDING_RESPONSE', ?)
                            ");
                            $stmtReq->execute([$c['tenant_id'], $c['id'], $c['apartment_id'], $periodId, $amount, $agentId ?: null]);

                            $msg = "Your rent for " . $aptInfo['building_name'] . " - " . $aptInfo['apartment_code'] . " is ending soon. Please confirm your payment.";

                            // Generate Notification for Tenant
                            $stmtNotif = $db->prepare("
                                INSERT INTO notifications (user_id, title, message, type, priority, delivery_channel)
                                VALUES ((SELECT user_id FROM tenants WHERE id = ?), 'Rent Ending Soon', ?, 'rent_renewal_request', 'High', 'Push')
                            ");
                            $stmtNotif->execute([$c['tenant_id'], $msg]);
                            
                            $records++;
                        }
                    }
                }
            }

            $db->commit();
        } catch (Exception $e) {
            $db->rollBack();
            $status = 'Failed';
            $error = $e->getMessage();
        }

        $duration = round(microtime(true) - $startTime);
        
        try {
            $stmt = $db->prepare("
                INSERT INTO scheduled_jobs (job_name, status, duration_seconds, records_processed, last_run, error_message) 
                VALUES ('Notification Scheduler', ?, ?, ?, NOW(), ?)
                ON DUPLICATE KEY UPDATE 
                    status = VALUES(status), duration_seconds = VALUES(duration_seconds), 
                    records_processed = VALUES(records_processed), last_run = VALUES(last_run), 
                    error_message = VALUES(error_message)
            ");
            $stmt->execute([$status, $duration, $records, $error]);
        } catch(Exception $e) {}
    }
}

if (php_sapi_name() == "cli") {
    NotificationScheduler::run();
}
