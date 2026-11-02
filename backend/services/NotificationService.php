<?php
/**
 * NotificationService.php
 * Centralized notification dispatch for all approval events.
 * Writes to the existing `notifications` table.
 * Structured for future FCM/push integration.
 */
class NotificationService {
    private PDO $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    // ─── Agent Notifications ──────────────────────────────────────────────────

    public function notifyAgentApproved(int $agentUserId, array $reading, string $type): void {
        $locationInfo = $this->buildLocationLabel($reading, $type);
        $title   = '✅ Reading Approved';
        $message = "Your meter reading for {$locationInfo} has been approved. "
                 . "The invoice has been generated automatically.";
        $this->insertNotification($agentUserId, $title, $message, 'agent_reading_accepted', $reading['id'] ?? null);
    }

    public function notifyAgentRejected(
        int $agentUserId,
        array $reading,
        string $type,
        string $reasonCode,
        string $comment,
        string $severity
    ): void {
        $locationInfo = $this->buildLocationLabel($reading, $type);
        $reasonLabel  = $this->getRejectionLabel($reasonCode);
        $title   = '❌ Reading Rejected';
        $message = "Your reading for {$locationInfo} was rejected.\n"
                 . "Reason: {$reasonLabel}\n"
                 . ($comment ? "Comment: {$comment}\n" : '')
                 . "Severity: {$severity}\n"
                 . "Please resubmit with corrections.";
        $this->insertNotification($agentUserId, $title, $message, 'agent_reading_rejected', $reading['id'] ?? null);

        // Action-required follow-up
        $this->insertNotification(
            $agentUserId,
            '🚨 Action Required',
            "A new reading is required for {$locationInfo}. Tap to resubmit.",
            'agent_action_required',
            $reading['id'] ?? null
        );
    }

    public function notifyAgentCorrected(int $agentUserId, array $reading, string $type, float $original, float $corrected): void {
        $locationInfo = $this->buildLocationLabel($reading, $type);
        $title   = '✏️ Reading Approved with Correction';
        $message = "Your reading for {$locationInfo} was approved.\n"
                 . "Administrator corrected the submitted reading based on the uploaded meter image.\n"
                 . "Original: {$original} kWh → Corrected: {$corrected} kWh";
        $this->insertNotification($agentUserId, $title, $message, 'agent_reading_corrected', $reading['id'] ?? null);
    }

    // ─── Admin Notifications ──────────────────────────────────────────────────

    public function notifyAdminsNewCriticalReading(array $reading, string $type): void {
        $admins = $this->getAdminUsers();
        $locationInfo = $this->buildLocationLabel($reading, $type);
        $title   = '🔴 Critical Reading Requires Review';
        $message = "A new reading for {$locationInfo} has been flagged as HIGH RISK. "
                 . "Confidence score: {$reading['confidence_score']}%. Immediate review recommended.";
        foreach ($admins as $admin) {
            $this->insertNotification($admin['id'], $title, $message, 'admin_critical_reading', $reading['id'] ?? null);
        }
    }

    public function notifyAdminsBulkComplete(int $adminId, int $approved, int $rejected, int $skipped): void {
        $title   = '✅ Bulk Approval Complete';
        $message = "Bulk action completed: {$approved} approved, {$rejected} rejected, {$skipped} skipped.";
        $this->insertNotification($adminId, $title, $message, 'admin_bulk_complete', null);
    }

    // ─── Internal Helpers ─────────────────────────────────────────────────────

    private function insertNotification(int $userId, string $title, string $message, string $type, ?int $refId): void {
        try {
            $stmt = $this->db->prepare("
                INSERT INTO notifications (user_id, title, message, type, reference_id, seen_by_agent)
                VALUES (?, ?, ?, ?, ?, 0)
            ");
            $stmt->execute([$userId, $title, $message, $type, $refId]);
        } catch (PDOException $e) {
            error_log("NotificationService insert error: " . $e->getMessage());
        }
    }

    private function getAdminUsers(): array {
        $stmt = $this->db->query("SELECT id FROM users WHERE role IN ('admin', 'superadmin')");
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    private function buildLocationLabel(array $reading, string $type): string {
        if ($type === 'generator') {
            return ($reading['building_name'] ?? 'Building') . ' — ' . ($reading['generator_name'] ?? 'Generator');
        }
        return ($reading['building_name'] ?? 'Building') . ' — Apt ' . ($reading['apartment_code'] ?? '?');
    }

    private function getRejectionLabel(string $code): string {
        $labels = [
            'image_blurry'      => 'Image is too blurry to verify the reading',
            'wrong_meter'       => 'Wrong meter photographed',
            'incorrect_reading' => 'Incorrect reading value entered',
            'duplicate'         => 'Duplicate submission',
            'missing_image'     => 'Meter photo is missing',
            'wrong_apartment'   => 'Reading submitted for wrong apartment',
            'fraud_suspected'   => 'Fraud suspected — escalated for review',
            'other'             => 'Other reason (see admin comment)',
        ];
        return $labels[$code] ?? $code;
    }
}
