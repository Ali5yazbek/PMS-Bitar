<?php
/**
 * ApprovalService.php
 * Generic workflow engine: approve, reject, quick-edit, bulk operations.
 * Orchestrates AuditService, NotificationService, FinancialSyncService.
 */
class ApprovalService {
    private PDO $db;
    private AuditService $audit;
    private NotificationService $notifier;
    private FinancialSyncService $financial;
    private ReadingAnalysisService $analyzer;
    private ConfidenceScoreService $scorer;

    public function __construct() {
        $this->db        = Database::getInstance()->getConnection();
        $this->audit     = new AuditService();
        $this->notifier  = new NotificationService();
        $this->financial = new FinancialSyncService();
        $this->analyzer  = new ReadingAnalysisService();
        $this->scorer    = new ConfidenceScoreService();
    }

    // ─── Approve ─────────────────────────────────────────────────────────────

    /**
     * Approve a single reading.
     *
     * @param int    $id       Reading ID
     * @param string $type     'electricity' | 'subscription' | 'generator'
     * @param int    $adminId  Admin user ID
     * @param array  $options  Optional overrides
     * @return array { success, message, financial }
     */
    public function approve(int $id, string $type, int $adminId, array $options = []): array {
        [$table, $statusField, $approvedStatus] = $this->getTableMeta($type);

        $reading = $this->fetchRow($table, $id);
        if (!$reading) return ['success' => false, 'error' => 'Reading not found'];

        $this->db->beginTransaction();
        try {
            // Update reading status
            $hasLifecycle  = $this->columnExists($table, 'status_lifecycle');
            $hasApprovedBy = $this->columnExists($table, 'approved_by');
            $hasReviewedAt = $this->columnExists($table, 'reviewed_at');
            $hasApprovedAt = $this->columnExists($table, 'approved_at');

            $setClauses = ["status = ?"];
            $params = [$approvedStatus];

            if ($hasLifecycle) {
                $setClauses[] = "status_lifecycle = 'approved'";
            }
            if ($hasApprovedBy) {
                $setClauses[] = "approved_by = ?";
                $params[] = $adminId;
            }
            if ($hasReviewedAt) {
                $setClauses[] = "reviewed_at = NOW()";
            }
            if ($hasApprovedAt) {
                $setClauses[] = "approved_at = NOW()";
            }
            $params[] = $id;

            $this->db->prepare("UPDATE $table SET " . implode(', ', $setClauses) . " WHERE id = ?")
                ->execute($params);

            // Financial sync — this is the ONLY place finances are updated
            $financial = match($type) {
                'electricity'  => $this->financial->syncElectricityApproval($id, $adminId),
                'subscription' => $this->financial->syncSubscriptionApproval($id, $adminId),
                'generator'    => $this->financial->syncGeneratorApproval($id, $adminId),
                default        => ['success' => true],
            };

            // Record agent action
            if (!empty($reading['submitted_by'])) {
                $this->financial->recordAgentAction((int)$reading['submitted_by'], 'approved');
            }

            // Invalidate building cache
            $buildingId = $this->getBuildingId($reading, $type);
            if ($buildingId) $this->financial->invalidateBuildingCache($buildingId);

            // Audit log
            $this->audit->log($type, $this->getRecordType($type), $id, 'approved',
                ['status' => $reading['status']],
                ['status' => $approvedStatus],
                $options['comment'] ?? 'Approved by admin',
                'info',
                $adminId
            );

            // Notify agent
            if (!empty($reading['submitted_by'])) {
                $wasEdited = !empty($reading['corrected_reading']);
                if ($wasEdited) {
                    $this->notifier->notifyAgentCorrected(
                        (int)$reading['submitted_by'], $reading, $type,
                        floatval($reading['current_reading']),
                        floatval($reading['corrected_reading'])
                    );
                } else {
                    $this->notifier->notifyAgentApproved((int)$reading['submitted_by'], $reading, $type);
                }
            }

            $this->db->commit();

            return [
                'success'   => true,
                'message'   => 'Reading approved successfully.',
                'financial' => $financial,
            ];

        } catch (PDOException $e) {
            $this->db->rollBack();
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    // ─── Reject ──────────────────────────────────────────────────────────────

    /**
     * Reject a reading with structured reason.
     *
     * @param array $rejectionData { reason_code, comment, severity, notify_push }
     */
    public function reject(int $id, string $type, int $adminId, array $rejectionData): array {
        [$table] = $this->getTableMeta($type);
        $reading  = $this->fetchRow($table, $id);
        if (!$reading) return ['success' => false, 'error' => 'Reading not found'];

        $reasonCode = $rejectionData['reason_code'] ?? 'other';
        $comment    = $rejectionData['comment']     ?? '';
        $severity   = $rejectionData['severity']    ?? 'medium';

        $this->db->beginTransaction();
        try {
            $hasLifecycle      = $this->columnExists($table, 'status_lifecycle');
            $hasReasonCode     = $this->columnExists($table, 'rejection_reason_code');
            $hasRejectSeverity = $this->columnExists($table, 'rejection_severity');
            $hasReviewedAt     = $this->columnExists($table, 'reviewed_at');
            $hasRejectedAt     = $this->columnExists($table, 'rejected_at');

            $setClauses = ["status = 'Rejected'"];
            $params     = [];

            if ($hasReviewedAt)     { $setClauses[] = "reviewed_at = NOW()"; }
            if ($hasRejectedAt)     { $setClauses[] = "rejected_at = NOW()"; }
            if ($hasLifecycle)      { $setClauses[] = "status_lifecycle = 'rejected'"; }
            if (true)               { $setClauses[] = "rejection_reason = ?"; $params[] = $comment ?: $reasonCode; }
            if ($hasReasonCode)     { $setClauses[] = "rejection_reason_code = ?"; $params[] = $reasonCode; }
            if ($hasRejectSeverity) { $setClauses[] = "rejection_severity = ?"; $params[] = $severity; }
            $params[] = $id;

            $this->db->prepare("UPDATE $table SET " . implode(', ', $setClauses) . " WHERE id = ?")
                ->execute($params);

            // Update agent performance
            if (!empty($reading['submitted_by'])) {
                $this->financial->recordAgentAction((int)$reading['submitted_by'], 'rejected');
            }

            $buildingId = $this->getBuildingId($reading, $type);
            if ($buildingId) $this->financial->invalidateBuildingCache($buildingId);

            $this->audit->log($type, $this->getRecordType($type), $id, 'rejected',
                ['status' => $reading['status']],
                ['status' => 'Rejected', 'reason_code' => $reasonCode, 'severity' => $severity],
                $comment ?: $reasonCode,
                'warning',
                $adminId
            );

            // Notify agent
            if (!empty($reading['submitted_by'])) {
                $this->notifier->notifyAgentRejected(
                    (int)$reading['submitted_by'], $reading, $type,
                    $reasonCode, $comment, $severity
                );
            }

            $this->db->commit();
            return ['success' => true, 'message' => 'Reading rejected. Agent has been notified.'];

        } catch (PDOException $e) {
            $this->db->rollBack();
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    // ─── Quick Edit ──────────────────────────────────────────────────────────

    /**
     * Admin corrects a reading value before approving.
     * Creates a version snapshot first, then updates the record.
     *
     * @param array $corrections { current_reading, reading_date, notes, edit_reason }
     */
    public function quickEdit(int $id, string $type, int $adminId, array $corrections): array {
        [$table] = $this->getTableMeta($type);
        $reading  = $this->fetchRow($table, $id);
        if (!$reading) return ['success' => false, 'error' => 'Reading not found'];

        $this->db->beginTransaction();
        try {
            // 1. Save current version before editing
            $versionNum = intval($reading['version_number'] ?? 1);
            $this->db->prepare("
                INSERT INTO reading_versions
                    (reading_id, reading_type, version_number, previous_reading, current_reading,
                     consumption, reading_date, notes, photo_path, edited_by, edit_reason, snapshot)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ")->execute([
                $id,
                $type,
                $versionNum,
                $reading['previous_reading'] ?? null,
                $reading['current_reading']  ?? null,
                $reading['consumption']      ?? null,
                $reading['reading_date']     ?? null,
                $reading['notes']            ?? null,
                $reading['photo_path']       ?? null,
                $adminId,
                $corrections['edit_reason'] ?? 'Admin correction',
                json_encode($reading),
            ]);

            // 2. Apply corrections
            $newReading  = floatval($corrections['current_reading'] ?? $reading['current_reading'] ?? $reading['current_meter_hours'] ?? $reading['meter_hours'] ?? 0);
            $prevReading = floatval($reading['previous_reading'] ?? $reading['previous_meter_hours'] ?? $reading['previous_kwh'] ?? 0);
            $newConsumption = max(0, $newReading - $prevReading);

            // Recalculate bill_amount if we have price_per_kwh
            $pricePerKwh = floatval($reading['price_per_kwh'] ?? 0);
            $newBill     = $pricePerKwh > 0 ? round($newConsumption * $pricePerKwh, 2) : floatval($reading['bill_amount'] ?? 0);

            $hasLifecycle     = $this->columnExists($table, 'status_lifecycle');
            $hasCorrectedBy   = $this->columnExists($table, 'corrected_by');
            $hasVersionNumber = $this->columnExists($table, 'version_number');
            $hasCorrectedAt   = $this->columnExists($table, 'corrected_at');

            if ($type === 'generator') {
                $setClauses = ['meter_hours = ?', 'current_meter_hours = ?', 'current_kwh = ?', 'running_hours = ?', 'kwh_produced = ?', 'notes = ?'];
                $params     = [$newReading, $newReading, $newReading, $newConsumption, $newConsumption, $corrections['notes'] ?? $reading['notes']];
            } else {
                $setClauses = ['current_reading = ?', 'consumption = ?', 'bill_amount = ?', 'corrected_reading = ?', 'notes = ?'];
                $params     = [$newReading, $newConsumption, $newBill, $newReading, $corrections['notes'] ?? $reading['notes']];
            }

            if ($hasCorrectedBy)   { $setClauses[] = 'corrected_by = ?';     $params[] = $adminId; }
            if ($hasCorrectedAt)   { $setClauses[] = 'corrected_at = NOW()'; }
            if ($hasVersionNumber) { $setClauses[] = 'version_number = ?';   $params[] = $versionNum + 1; }
            if ($hasLifecycle)     { $setClauses[] = "status_lifecycle = 'pending_review'"; }
            $params[] = $id;

            $this->db->prepare("UPDATE $table SET " . implode(', ', $setClauses) . " WHERE id = ?")
                ->execute($params);

            // 3. Audit the correction
            $this->audit->log($type, $this->getRecordType($type), $id, 'edited',
                ['current_reading' => $reading['current_reading'], 'consumption' => $reading['consumption']],
                ['current_reading' => $newReading, 'consumption' => $newConsumption],
                $corrections['edit_reason'] ?? 'Digit correction from uploaded meter image.',
                'warning',
                $adminId
            );

            $this->db->commit();

            return [
                'success'         => true,
                'message'         => 'Reading corrected. You can now approve it.',
                'new_reading'     => $newReading,
                'new_consumption' => $newConsumption,
                'new_bill'        => $newBill,
                'version'         => $versionNum + 1,
            ];

        } catch (PDOException $e) {
            $this->db->rollBack();
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    // ─── Bulk Approve ────────────────────────────────────────────────────────

    /**
     * Approve multiple readings at once.
     *
     * @param array  $ids         Array of reading IDs
     * @param string $type        'electricity' | 'subscription' | 'generator'
     * @param int    $adminId     Admin user ID
     * @param bool   $skipHighRisk Skip readings with risk_level in ('high','critical')
     */
    public function bulkApprove(array $ids, string $type, int $adminId, bool $skipHighRisk = false): array {
        $approved = 0; $skipped = 0; $errors = [];

        foreach ($ids as $id) {
            // Check risk level
            if ($skipHighRisk) {
                [$table] = $this->getTableMeta($type);
                $row = $this->fetchRow($table, (int)$id);
                if ($row && in_array($row['risk_level'] ?? 'low', ['high', 'critical'])) {
                    $skipped++;
                    continue;
                }
            }

            $result = $this->approve((int)$id, $type, $adminId);
            if ($result['success']) {
                $approved++;
            } else {
                $errors[] = ['id' => $id, 'error' => $result['error'] ?? 'Unknown'];
            }
        }

        // Notify admin bulk complete
        $this->notifier->notifyAdminsBulkComplete($adminId, $approved, 0, $skipped);

        return [
            'success'  => true,
            'approved' => $approved,
            'skipped'  => $skipped,
            'errors'   => $errors,
            'message'  => "{$approved} reading(s) approved. {$skipped} skipped (high-risk).",
        ];
    }

    // ─── Bulk Reject ─────────────────────────────────────────────────────────

    public function bulkReject(array $ids, string $type, int $adminId, array $rejectionData): array {
        $rejected = 0; $errors = [];
        foreach ($ids as $id) {
            $result = $this->reject((int)$id, $type, $adminId, $rejectionData);
            if ($result['success']) $rejected++;
            else $errors[] = ['id' => $id, 'error' => $result['error'] ?? 'Unknown'];
        }
        return ['success' => true, 'rejected' => $rejected, 'errors' => $errors];
    }

    // ─── Run Analysis & Persist Scores ───────────────────────────────────────

    /**
     * Run anomaly analysis and persist confidence score + risk level into the reading row.
     */
    public function analyzeAndPersist(int $id, string $type): array {
        $analysis = $this->analyzer->analyze($id, $type);
        if (isset($analysis['error'])) return $analysis;

        $settings = $this->loadSettings();
        $scored   = $this->scorer->calculate($analysis['warnings'], $settings);

        [$table]  = $this->getTableMeta($type);
        $this->db->prepare("
            UPDATE $table
            SET confidence_score = ?,
                risk_level       = ?,
                anomaly_flags    = ?,
                priority         = ?
            WHERE id = ?
        ")->execute([
            $scored['score'],
            $scored['risk_level'],
            json_encode($analysis['warnings']),
            $scored['priority'],
            $id,
        ]);

        return array_merge($analysis, $scored);
    }

    // ─── Private Helpers ─────────────────────────────────────────────────────

    private function getTableMeta(string $type): array {
        if ($type === 'subscriptions') $type = 'subscription'; // normalize plural alias
        return match($type) {
            'electricity'  => ['electricity_meter_readings',      'status', 'Verified'],
            'subscription' => ['agent_subscription_readings',     'status', 'Accepted'],
            'generator'    => ['generator_daily_reports',         'status', 'Verified'],
            default        => ['electricity_meter_readings',      'status', 'Verified'],
        };
    }

    private function getRecordType(string $type): string {
        if ($type === 'subscriptions') $type = 'subscription';
        return match($type) {
            'electricity'  => 'meter_reading',
            'subscription' => 'subscription_reading',
            'generator'    => 'generator_reading',
            default        => 'reading',
        };
    }

    private function fetchRow(string $table, int $id): ?array {
        $stmt = $this->db->prepare("SELECT * FROM $table WHERE id = ?");
        $stmt->execute([$id]);
        return $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
    }

    private function getBuildingId(array $reading, string $type): ?int {
        try {
            if ($type === 'generator') {
                $stmt = $this->db->prepare("SELECT building_id FROM generators WHERE id = ?");
                $stmt->execute([$reading['generator_id']]);
                return (int)($stmt->fetchColumn() ?: 0) ?: null;
            }
            $stmt = $this->db->prepare("SELECT building_id FROM apartments WHERE id = ?");
            $stmt->execute([$reading['apartment_id']]);
            return (int)($stmt->fetchColumn() ?: 0) ?: null;
        } catch (PDOException $e) { return null; }
    }

    private function columnExists(string $table, string $column): bool {
        try {
            $stmt = $this->db->query("SHOW COLUMNS FROM $table LIKE '$column'");
            return (bool)$stmt->fetch();
        } catch (PDOException $e) { return false; }
    }

    private function loadSettings(): array {
        try {
            $stmt = $this->db->query("SELECT setting_key, setting_value FROM approval_settings");
            $out  = [];
            foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
                $out[$row['setting_key']] = $row['setting_value'];
            }
            return $out;
        } catch (PDOException $e) { return []; }
    }
}
