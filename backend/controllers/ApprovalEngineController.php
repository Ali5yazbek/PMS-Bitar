<?php
/**
 * ApprovalEngineController.php
 * Thin controller that routes API requests to the appropriate service.
 */

// Ensure all services are loaded
require_once __DIR__ . '/../services/AuditService.php';
require_once __DIR__ . '/../services/NotificationService.php';
require_once __DIR__ . '/../services/FinancialSyncService.php';
require_once __DIR__ . '/../services/ReadingAnalysisService.php';
require_once __DIR__ . '/../services/ConfidenceScoreService.php';
require_once __DIR__ . '/../services/ApprovalService.php';
require_once __DIR__ . '/../services/BuildingHealthService.php';
require_once __DIR__ . '/../services/AgentPerformanceService.php';

class ApprovalEngineController {
    private PDO $db;
    private ApprovalService $approvalService;
    private ReadingAnalysisService $analyzer;
    private BuildingHealthService $healthService;
    private AgentPerformanceService $agentService;
    private AuditService $auditService;

    public function __construct() {
        $this->db              = Database::getInstance()->getConnection();
        $this->approvalService = new ApprovalService();
        $this->analyzer        = new ReadingAnalysisService();
        $this->healthService   = new BuildingHealthService();
        $this->agentService    = new AgentPerformanceService();
        $this->auditService    = new AuditService();
    }

    private function getUserId(): int {
        try {
            $token = JWT::getBearerToken();
            if ($token) {
                $user = JWT::decode($token);
                if (isset($user['user_id'])) return (int)$user['user_id'];
                if (isset($user->id)) return (int)$user->id;
            }
        } catch (Exception $e) {}
        return 1; // Default fallback for development
    }

    // ─── 1. Core Actions ──────────────────────────────────────────────────────

    public function analyzeReading(string $type, string $id) {
        AuthMiddleware::requireLogin();
        $result = $this->approvalService->analyzeAndPersist((int)$id, $type);
        echo json_encode($result);
    }

    public function approve(string $type, string $id) {
        AuthMiddleware::requireLogin();
        $result = $this->approvalService->approve((int)$id, $type, $this->getUserId());
        
        // Draft update logic (Hybrid calculation trigger)
        if ($result['success'] && in_array($type, ['generator_report', 'meter_reading', 'electricity'])) {
            // Trigger background calculation of draft line items
            // Assuming there's a CLI command or we just execute a PHP script in background
            $scriptPath = __DIR__ . '/../../recalculate_drafts.php';
            if (file_exists($scriptPath)) {
                if (strtoupper(substr(PHP_OS, 0, 3)) === 'WIN') {
                    pclose(popen("start /B php $scriptPath $type $id", "r"));
                } else {
                    exec("php $scriptPath $type $id > /dev/null &");
                }
            }
        }

        http_response_code($result['success'] ? 200 : 400);
        echo json_encode($result);
    }

    public function reject(string $type, string $id) {
        AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents('php://input'), true) ?? $_POST;
        $result = $this->approvalService->reject((int)$id, $type, $this->getUserId(), $data);
        http_response_code($result['success'] ? 200 : 400);
        echo json_encode($result);
    }

    public function quickEdit(string $type, string $id) {
        AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents('php://input'), true) ?? [];
        $result = $this->approvalService->quickEdit((int)$id, $type, $this->getUserId(), $data);
        http_response_code($result['success'] ? 200 : 400);
        echo json_encode($result);
    }

    public function bulkApprove(string $type) {
        AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents('php://input'), true) ?? [];
        $ids = $data['ids'] ?? [];
        $skipHighRisk = $data['skip_high_risk'] ?? false;
        
        $result = $this->approvalService->bulkApprove($ids, $type, $this->getUserId(), $skipHighRisk);
        echo json_encode($result);
    }

    public function bulkReject(string $type) {
        AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents('php://input'), true) ?? [];
        $ids = $data['ids'] ?? [];
        $rejectionData = $data['rejection_data'] ?? [];
        
        $result = $this->approvalService->bulkReject($ids, $type, $this->getUserId(), $rejectionData);
        echo json_encode($result);
    }

    // ─── 2. Queues & History ──────────────────────────────────────────────────

    public function getPendingQueue(string $type) {
        AuthMiddleware::requireLogin();

        // Normalize plural alias → singular (frontend may send 'subscriptions')
        if ($type === 'subscriptions') $type = 'subscription';
        
        $table = match($type) {
            'electricity'  => 'electricity_meter_readings',
            'subscription' => 'agent_subscription_readings',
            'generator'    => 'generator_daily_reports',
            default        => 'electricity_meter_readings'
        };

        // Allow filtering by status, default to pending
        $requestedStatus = $_GET['status'] ?? 'pending';
        if ($requestedStatus === 'approved') {
            $statusCondition = "IN ('Approved', 'Verified', 'Accepted')";
        } else if ($requestedStatus === 'rejected') {
            $statusCondition = "IN ('Rejected')";
        } else {
            $statusCondition = "IN ('Pending', 'Pending Verification')";
        }

        $query = "";
        if ($type === 'generator') {
            $query = "
                SELECT 
                    r.*, 
                    COALESCE(NULLIF(r.current_meter_hours, 0), NULLIF(r.meter_hours, 0), NULLIF(r.current_kwh, 0), r.running_hours, 0) as current_reading,
                    COALESCE(NULLIF(r.previous_meter_hours, 0), NULLIF(r.previous_kwh, 0), 0) as previous_reading,
                    COALESCE(NULLIF(r.running_hours, 0), NULLIF(r.kwh_produced, 0), 0) as consumption,
                    g.name as generator_name, 
                    b.name as building_name, 
                    u.name as submitter_name
                FROM $table r
                JOIN generators g ON r.generator_id = g.id
                JOIN buildings b ON g.building_id = b.id
                LEFT JOIN users u ON r.submitted_by = u.id
                WHERE r.status $statusCondition
                ORDER BY r.created_at ASC
            ";
        } else {
            $query = "
                SELECT r.*, a.code as apartment_code, b.name as building_name, u.name as submitter_name
                FROM $table r
                JOIN apartments a ON r.apartment_id = a.id
                JOIN buildings b ON a.building_id = b.id
                LEFT JOIN users u ON r.submitted_by = u.id
                WHERE r.status $statusCondition
                ORDER BY r.created_at ASC
            ";
        }

        try {
            $stmt = $this->db->query($query);
            $results = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Format anomaly flags back into JSON if they are strings
            foreach ($results as &$r) {
                if (isset($r['anomaly_flags']) && is_string($r['anomaly_flags'])) {
                    $r['anomaly_flags'] = json_decode($r['anomaly_flags'], true);
                }
            }
            
            echo json_encode($results);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function getReadingHistory(string $type, string $id) {
        AuthMiddleware::requireLogin();
        // Uses the analysis service to get the last 12 months history
        $result = $this->analyzer->analyze((int)$id, $type);
        echo json_encode(['history' => $result['history'] ?? []]);
    }

    public function getReadingTimeline(string $type, string $id) {
        AuthMiddleware::requireLogin();
        $recordType = match($type) {
            'electricity' => 'meter_reading',
            'subscription' => 'subscription_reading',
            'generator' => 'generator_reading',
            default => 'reading'
        };
        $timeline = $this->auditService->getTimeline($recordType, (int)$id);
        echo json_encode($timeline);
    }

    public function getReadingVersions(string $type, string $id) {
        AuthMiddleware::requireLogin();
        try {
            $stmt = $this->db->prepare("
                SELECT rv.*, u.name as editor_name
                FROM reading_versions rv
                LEFT JOIN users u ON rv.edited_by = u.id
                WHERE rv.reading_type = ? AND rv.reading_id = ?
                ORDER BY rv.version_number DESC
            ");
            $stmt->execute([$type, $id]);
            echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
        } catch (PDOException $e) {
            echo json_encode([]);
        }
    }

    // ─── 3. Dashboard & Intelligence ──────────────────────────────────────────

    public function getAdminKPI() {
        AuthMiddleware::requireLogin();
        
        try {
            $stats = [
                'pending_approvals' => 0,
                'electricity_pending' => 0,
                'subscription_pending' => 0,
                'generator_pending' => 0,
                'high_risk' => 0,
                'bulk_safe' => 0,
                'rejection_rate' => '0%',
                'revenue_waiting' => 0,
                'recent_activity' => $this->auditService->getRecentActivity(10),
                'pending_over_24h' => 0,
                'pending_over_48h' => 0,
            ];

            // Count pending electricity
            $stmt = $this->db->query("
                SELECT 
                    COUNT(*) as total,
                    0 as high_risk,
                    0 as safe,
                    SUM(CASE WHEN created_at < DATE_SUB(NOW(), INTERVAL 24 HOUR) THEN 1 ELSE 0 END) as over24,
                    SUM(CASE WHEN created_at < DATE_SUB(NOW(), INTERVAL 48 HOUR) THEN 1 ELSE 0 END) as over48,
                    SUM(bill_amount) as revenue
                FROM electricity_meter_readings
                WHERE status IN ('Pending', 'Pending Verification')
            ");
            $elec = $stmt->fetch(PDO::FETCH_ASSOC);

            // Count pending subscriptions
            $stmt2 = $this->db->query("
                SELECT 
                    COUNT(*) as total,
                    0 as high_risk,
                    0 as safe,
                    SUM(CASE WHEN created_at < DATE_SUB(NOW(), INTERVAL 24 HOUR) THEN 1 ELSE 0 END) as over24,
                    SUM(CASE WHEN created_at < DATE_SUB(NOW(), INTERVAL 48 HOUR) THEN 1 ELSE 0 END) as over48
                FROM agent_subscription_readings
                WHERE status IN ('Pending', 'Pending Verification')
            ");
            $sub = $stmt2->fetch(PDO::FETCH_ASSOC);

            // Count pending generator
            $stmt3 = $this->db->query("
                SELECT 
                    COUNT(*) as total,
                    SUM(CASE WHEN created_at < DATE_SUB(NOW(), INTERVAL 24 HOUR) THEN 1 ELSE 0 END) as over24,
                    SUM(CASE WHEN created_at < DATE_SUB(NOW(), INTERVAL 48 HOUR) THEN 1 ELSE 0 END) as over48
                FROM generator_daily_reports
                WHERE status IN ('Pending', 'Pending Verification')
            ");
            $gen = $stmt3->fetch(PDO::FETCH_ASSOC);

            $stats['electricity_pending'] = (int)($elec['total'] ?? 0);
            $stats['subscription_pending'] = (int)($sub['total'] ?? 0);
            $stats['generator_pending'] = (int)($gen['total'] ?? 0);
            $stats['pending_approvals'] = $stats['electricity_pending'] + $stats['subscription_pending'] + $stats['generator_pending'];
            $stats['high_risk'] = (int)($elec['high_risk'] ?? 0) + (int)($sub['high_risk'] ?? 0);
            $stats['bulk_safe'] = (int)($elec['safe'] ?? 0) + (int)($sub['safe'] ?? 0);
            $stats['revenue_waiting'] = (float)($elec['revenue'] ?? 0);
            $stats['pending_over_24h'] = (int)($elec['over24'] ?? 0) + (int)($sub['over24'] ?? 0) + (int)($gen['over24'] ?? 0);
            $stats['pending_over_48h'] = (int)($elec['over48'] ?? 0) + (int)($sub['over48'] ?? 0) + (int)($gen['over48'] ?? 0);

            // Last 30 days rejection rate
            $rejStmt = $this->db->query("
                SELECT 
                    COUNT(*) as total,
                    SUM(CASE WHEN status = 'Rejected' THEN 1 ELSE 0 END) as rejected
                FROM electricity_meter_readings
                WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
            ");
            $rej = $rejStmt->fetch(PDO::FETCH_ASSOC);
            if ($rej && $rej['total'] > 0) {
                $stats['rejection_rate'] = round(($rej['rejected'] / $rej['total']) * 100, 1) . '%';
            }

            echo json_encode($stats);

        } catch (Throwable $e) {
            // This will catch the fatal error and send it back to React so we can see it!
            http_response_code(500);
            echo json_encode([
                'error' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine()
            ]);
        }
    }

    public function getAgentLeaderboard() {
        AuthMiddleware::requireLogin();
        $month = isset($_GET['month']) ? (int)$_GET['month'] : (int)date('n');
        $year = isset($_GET['year']) ? (int)$_GET['year'] : (int)date('Y');
        
        $results = $this->agentService->getLeaderboard($month, $year);
        echo json_encode($results);
    }

    public function getBuildingHealthScores() {
        AuthMiddleware::requireLogin();
        $results = $this->healthService->getAllScores();
        echo json_encode($results);
    }

    // ─── 4. Settings ──────────────────────────────────────────────────────────

    public function getApprovalSettings() {
        AuthMiddleware::requireLogin();
        try {
            $stmt = $this->db->query("SELECT * FROM approval_settings ORDER BY module, setting_key");
            echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
        } catch (PDOException $e) {
            echo json_encode([]);
        }
    }

    public function updateApprovalSetting(string $key) {
        AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents('php://input'), true) ?? [];
        $value = $data['value'] ?? '';

        try {
            $stmt = $this->db->prepare("UPDATE approval_settings SET setting_value = ?, updated_by = ?, updated_at = NOW() WHERE setting_key = ?");
            $stmt->execute([$value, $this->getUserId(), $key]);
            echo json_encode(['success' => true]);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function getCorrectionQueue() {
        AuthMiddleware::requireLogin();
        try {
            $stmt = $this->db->query("
                SELECT c.*, u.name as submitted_by_name 
                FROM correction_requests c
                JOIN users u ON c.submitted_by = u.id
                WHERE c.status = 'Pending'
                ORDER BY c.created_at DESC
            ");
            echo json_encode(['success' => true, 'data' => $stmt->fetchAll(PDO::FETCH_ASSOC)]);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function approveCorrection(string $id) {
        AuthMiddleware::requireLogin();
        try {
            $this->db->beginTransaction();
            
            // Get correction info
            $stmt = $this->db->prepare("SELECT * FROM correction_requests WHERE id = ? AND status = 'Pending'");
            $stmt->execute([$id]);
            $correction = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if (!$correction) {
                throw new Exception("Correction request not found or already processed.");
            }

            // Update actual value
            if ($correction['type'] === 'generator_reading') {
                $upd = $this->db->prepare("UPDATE generator_daily_reports SET current_kwh = ?, status = 'Verified' WHERE id = ?");
                $upd->execute([$correction['proposed_value'], $correction['entity_id']]);
                
                // Trigger background draft update
                $scriptPath = __DIR__ . '/../../recalculate_drafts.php';
                if (file_exists($scriptPath)) {
                    if (strtoupper(substr(PHP_OS, 0, 3)) === 'WIN') {
                        pclose(popen("start /B php $scriptPath generator_report {$correction['entity_id']}", "r"));
                    } else {
                        exec("php $scriptPath generator_report {$correction['entity_id']} > /dev/null &");
                    }
                }
            } else if ($correction['type'] === 'electricity_reading') {
                // Fetch previous to fix consumption
                $prevStmt = $this->db->prepare("SELECT previous_reading, price_per_kwh FROM electricity_meter_readings WHERE id = ?");
                $prevStmt->execute([$correction['entity_id']]);
                $r = $prevStmt->fetch(PDO::FETCH_ASSOC);
                
                $consumption = max(0, $correction['proposed_value'] - $r['previous_reading']);
                $bill = $consumption * $r['price_per_kwh'];
                
                $upd = $this->db->prepare("UPDATE electricity_meter_readings SET current_reading = ?, consumption = ?, bill_amount = ?, status = 'Verified' WHERE id = ?");
                $upd->execute([$correction['proposed_value'], $consumption, $bill, $correction['entity_id']]);
                
                // Trigger background draft update
                $scriptPath = __DIR__ . '/../../recalculate_drafts.php';
                if (file_exists($scriptPath)) {
                    if (strtoupper(substr(PHP_OS, 0, 3)) === 'WIN') {
                        pclose(popen("start /B php $scriptPath meter_reading {$correction['entity_id']}", "r"));
                    } else {
                        exec("php $scriptPath meter_reading {$correction['entity_id']} > /dev/null &");
                    }
                }
            }

            // Mark correction as approved
            $updReq = $this->db->prepare("UPDATE correction_requests SET status = 'Approved', approved_by = ? WHERE id = ?");
            $updReq->execute([$this->getUserId(), $id]);
            
            $this->db->commit();
            echo json_encode(['success' => true]);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function rejectCorrection(string $id) {
        AuthMiddleware::requireLogin();
        try {
            $updReq = $this->db->prepare("UPDATE correction_requests SET status = 'Rejected', approved_by = ? WHERE id = ?");
            $updReq->execute([$this->getUserId(), $id]);
            
            echo json_encode(['success' => true]);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }
}