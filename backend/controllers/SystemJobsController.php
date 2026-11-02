<?php
class SystemJobsController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function getJobs() {
        AuthMiddleware::requireLogin();
        try {
            $stmt = $this->db->query("SELECT * FROM scheduled_jobs ORDER BY last_run DESC");
            echo json_encode(['status' => 'success', 'data' => $stmt->fetchAll(PDO::FETCH_ASSOC)]);
        } catch (Exception $e) {
            echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
            http_response_code(500);
        }
    }

    public function runJob($id) {
        AuthMiddleware::requireLogin();
        try {
            $stmt = $this->db->prepare("SELECT job_name FROM scheduled_jobs WHERE id = ?");
            $stmt->execute([$id]);
            $jobName = $stmt->fetchColumn();

            if (!$jobName) {
                throw new Exception("Job not found");
            }

            // We simulate triggering it via exec or directly calling the class
            // In a real environment, we'd trigger the background process
            $output = [];
            $returnVar = 0;
            
            if ($jobName === 'Daily Rent Scheduler') {
                require_once __DIR__ . '/../services/RentGenerationService.php';
                $result = RentGenerationService::runDaily();
                echo json_encode([
                    'status' => 'success',
                    'message' => 'Daily Rent Scheduler executed successfully',
                    'invoices_created' => $result['invoices_created'],
                    'statuses_reconciled' => $result['statuses_reconciled']
                ]);
                return;
            } elseif ($jobName === 'Notification Scheduler') {
                exec("php " . __DIR__ . "/../cron/notification_scheduler.php", $output, $returnVar);
            } else {
                throw new Exception("Unknown job execution mapping");
            }

            echo json_encode(['status' => 'success', 'message' => 'Job executed successfully']);
        } catch (Exception $e) {
            echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
            http_response_code(500);
        }
    }

    public function toggleJob($id, $enable) {
        AuthMiddleware::requireLogin();
        try {
            $status = filter_var($enable, FILTER_VALIDATE_BOOLEAN) ? 'Pending' : 'Disabled';
            $stmt = $this->db->prepare("UPDATE scheduled_jobs SET status = ? WHERE id = ?");
            $stmt->execute([$status, $id]);
            echo json_encode(['status' => 'success', 'message' => "Job status updated to $status"]);
        } catch (Exception $e) {
            echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
            http_response_code(500);
        }
    }
}
