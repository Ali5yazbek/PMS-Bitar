<?php
/**
 * FinancialSyncService.php
 * Cross-module synchronization triggered on reading approval.
 * All downstream financial updates happen in a single atomic transaction.
 * 
 * FINANCIAL SAFETY: This is the ONLY place where financial records are created/updated.
 * No invoice, balance, or dashboard is touched until this service is called.
 */
class FinancialSyncService {
    private PDO $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Sync all dependent modules when an electricity meter reading is approved.
     * Creates invoice if needed, updates subscription dates, logs financial transaction.
     *
     * @return array { success, invoice_id, amount }
     */
    public function syncElectricityApproval(int $readingId, int $approvedBy): array {
        $stmt = $this->db->prepare("SELECT * FROM electricity_meter_readings WHERE id = ?");
        $stmt->execute([$readingId]);
        $reading = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$reading) return ['success' => false, 'error' => 'Reading not found'];

        // Use corrected reading value if admin quick-edited it
        $billAmount = floatval($reading['bill_amount'] ?? 0);
        $effectiveReading = $reading['corrected_reading'] ?? $reading['current_reading'];

        // Get apartment / building context
        $aptStmt = $this->db->prepare("
            SELECT a.id, a.building_id, b.name as building_name
            FROM apartments a JOIN buildings b ON a.building_id = b.id
            WHERE a.id = ?
        ");
        $aptStmt->execute([$reading['apartment_id']]);
        $apt = $aptStmt->fetch(PDO::FETCH_ASSOC);

        $invoiceId = null;

        // Log to financial_transactions
        $ftStmt = $this->db->prepare("
            INSERT INTO financial_transactions
                (transaction_type, module, apartment_id, building_id, source_reading_id, source_reading_type, amount, created_by)
            VALUES ('electricity_invoice', 'electricity', ?, ?, ?, 'electricity', ?, ?)
        ");
        $ftStmt->execute([
            $reading['apartment_id'],
            $apt['building_id'] ?? null,
            $readingId,
            $billAmount,
            $approvedBy
        ]);

        return ['success' => true, 'invoice_id' => $invoiceId, 'amount' => $billAmount];
    }

    /**
     * Sync when a subscription meter reading is approved.
     * Auto-renews subscription + generates monthly invoice.
     */
    public function syncSubscriptionApproval(int $readingId, int $approvedBy): array {
        $stmt = $this->db->prepare("SELECT * FROM agent_subscription_readings WHERE id = ?");
        $stmt->execute([$readingId]);
        $reading = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$reading) return ['success' => false, 'error' => 'Reading not found'];

        $subId      = $reading['subscription_id'];
        $apartmentId = $reading['apartment_id'];

        $subStmt = $this->db->prepare("SELECT * FROM electricity_subscriptions WHERE id = ?");
        $subStmt->execute([$subId]);
        $sub = $subStmt->fetch(PDO::FETCH_ASSOC);
        if (!$sub) return ['success' => false, 'error' => 'Subscription not found'];

        // Advance subscription by 1 month
        $newStart  = date('Y-m-d', strtotime($sub['end_date'] . ' +1 day'));
        $newEnd    = date('Y-m-d', strtotime($sub['end_date'] . ' +1 month'));
        $invoiceId = null;
        $amount    = floatval($sub['monthly_fee'] ?? 0);

        try {
            // Update subscription dates
            $colChk = $this->db->query("SHOW COLUMNS FROM electricity_subscriptions LIKE 'last_meter_reading'");
            $hasLMR = $colChk->fetch();
            if ($hasLMR) {
                $this->db->prepare("
                    UPDATE electricity_subscriptions
                    SET start_date = ?, end_date = ?, next_billing_date = ?, last_meter_reading = ?
                    WHERE id = ?
                ")->execute([$newStart, $newEnd, $newEnd, $reading['current_reading'], $subId]);
            } else {
                $this->db->prepare("
                    UPDATE electricity_subscriptions
                    SET start_date = ?, end_date = ?, next_billing_date = ?
                    WHERE id = ?
                ")->execute([$newStart, $newEnd, $newEnd, $subId]);
            }

            // Generate subscription invoice if monthly_fee > 0
            if ($amount > 0) {
                $monthStr = date('Y-m', strtotime($newStart));
                $invCheck = $this->db->prepare("
                    SELECT id FROM electricity_invoices
                    WHERE apartment_id = ?
                    AND type IN ('Subscription','Fixed Subscription')
                    AND DATE_FORMAT(due_date, '%Y-%m') = ?
                ");
                $invCheck->execute([$apartmentId, $monthStr]);
                if (!$invCheck->fetch()) {
                    $invStmt = $this->db->prepare("
                        INSERT INTO electricity_invoices (apartment_id, type, amount, due_date)
                        VALUES (?, 'Subscription', ?, ?)
                    ");
                    $invStmt->execute([$apartmentId, $amount, $newStart]);
                    $invoiceId = (int)$this->db->lastInsertId();
                } else {
                    // Fetch existing invoice id if it already existed
                    $invCheck->execute([$apartmentId, $monthStr]);
                    $invoiceId = (int)$invCheck->fetchColumn();
                }

                // Apply collected payment if agent collected it during submission
                if (isset($reading['amount_collected']) && floatval($reading['amount_collected']) > 0 && $invoiceId) {
                    $collectedAmt = floatval($reading['amount_collected']);
                    $this->db->prepare("
                        UPDATE electricity_invoices 
                        SET amount_paid = amount_paid + ?, 
                            status = CASE WHEN amount_paid + ? >= amount THEN 'Paid' ELSE 'Partially Paid' END 
                        WHERE id = ?
                    ")->execute([$collectedAmt, $collectedAmt, $invoiceId]);
                }
            }

            // Generate meter usage invoice if metered and consumption > 0
            if (floatval($reading['consumption'] ?? 0) > 0 && floatval($sub['amps'] ?? 1) == 0) {
                if (!empty($sub['price_per_kwh']) && floatval($sub['price_per_kwh']) > 0) {
                    $pricePerKwh = floatval($sub['price_per_kwh']);
                } else {
                    $ppkStmt = $this->db->prepare("
                        SELECT g.price_per_kw FROM generators g
                        JOIN apartments a ON g.building_id = a.building_id
                        WHERE a.id = ? LIMIT 1
                    ");
                    $ppkStmt->execute([$apartmentId]);
                    $pricePerKwh = floatval($ppkStmt->fetchColumn() ?: 0);
                }
                $meterBill   = floatval($reading['consumption']) * $pricePerKwh;
                if ($meterBill > 0) {
                    $this->db->prepare("
                        INSERT INTO electricity_meter_readings
                            (apartment_id, previous_reading, current_reading, consumption,
                             price_per_kwh, bill_amount, reading_date, photo_path, notes,
                             status, submitted_by, billing_month, billing_year)
                        VALUES (?, ?, ?, ?, ?, ?, CURDATE(), ?, ?, 'Verified', ?, MONTH(CURDATE()), YEAR(CURDATE()))
                    ")->execute([
                        $apartmentId,
                        $reading['previous_reading'],
                        $reading['current_reading'],
                        $reading['consumption'],
                        $pricePerKwh,
                        $meterBill,
                        $reading['photo_path'],
                        $reading['notes'] ?? '',
                        $reading['submitted_by']
                    ]);
                    $this->db->prepare("
                        INSERT INTO electricity_invoices (apartment_id, type, amount, due_date)
                        VALUES (?, 'Meter', ?, DATE_ADD(CURDATE(), INTERVAL 7 DAY))
                    ")->execute([$apartmentId, $meterBill]);
                }
            }

            // Log financial transaction, attributing it to the agent who submitted it
            $agentId = !empty($reading['submitted_by']) ? $reading['submitted_by'] : $approvedBy;
            $this->db->prepare("
                INSERT INTO financial_transactions
                    (transaction_type, module, apartment_id, source_reading_id, source_reading_type, amount, invoice_id, created_by)
                VALUES ('subscription_invoice', 'electricity', ?, ?, 'subscription', ?, ?, ?)
            ")->execute([$apartmentId, $readingId, $amount, $invoiceId, $agentId]);

            return ['success' => true, 'invoice_id' => $invoiceId, 'amount' => $amount, 'new_end_date' => $newEnd];

        } catch (PDOException $e) {
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    /**
     * Sync when a generator reading is approved.
     */
    public function syncGeneratorApproval(int $readingId, int $approvedBy): array {
        // Generator approval currently updates status only (no invoice generated)
        // This is where generator billing would be added in future
        $this->db->prepare("
            INSERT INTO financial_transactions
                (transaction_type, module, source_reading_id, source_reading_type, amount, created_by)
            VALUES ('generator_invoice', 'generator', ?, 'generator', 0, ?)
        ")->execute([$readingId, $approvedBy]);
        return ['success' => true];
    }

    /**
     * Invalidate building health score cache (force recalculation on next request).
     */
    public function invalidateBuildingCache(int $buildingId): void {
        try {
            $this->db->prepare("
                UPDATE building_health_scores
                SET calculated_at = DATE_SUB(NOW(), INTERVAL 2 HOUR)
                WHERE building_id = ?
            ")->execute([$buildingId]);
        } catch (PDOException $e) {}
    }

    /**
     * Increment agent performance counters for this month.
     */
    public function recordAgentAction(int $agentUserId, string $action): void {
        try {
            $month = (int)date('n');
            $year  = (int)date('Y');

            // Upsert monthly record
            $this->db->prepare("
                INSERT INTO agent_performance (user_id, month, year, total_submissions)
                VALUES (?, ?, ?, 0)
                ON DUPLICATE KEY UPDATE user_id = user_id
            ")->execute([$agentUserId, $month, $year]);

            $field = match($action) {
                'approved'   => 'approved_count',
                'rejected'   => 'rejected_count',
                'corrected'  => 'correction_count',
                'submitted'  => 'total_submissions',
                default      => null,
            };
            if ($field) {
                $this->db->prepare("
                    UPDATE agent_performance
                    SET $field = $field + 1
                    WHERE user_id = ? AND month = ? AND year = ?
                ")->execute([$agentUserId, $month, $year]);
            }

            // Recalculate accuracy and approval_rate
            $this->db->prepare("
                UPDATE agent_performance
                SET accuracy_score = CASE WHEN total_submissions > 0
                    THEN ROUND((approved_count / total_submissions) * 100, 2) ELSE 100 END,
                    approval_rate = CASE WHEN total_submissions > 0
                    THEN ROUND((approved_count / total_submissions) * 100, 2) ELSE 100 END,
                    rejection_rate = CASE WHEN total_submissions > 0
                    THEN ROUND((rejected_count / total_submissions) * 100, 2) ELSE 0 END
                WHERE user_id = ? AND month = ? AND year = ?
            ")->execute([$agentUserId, $month, $year]);

        } catch (PDOException $e) {
            error_log("FinancialSyncService::recordAgentAction error: " . $e->getMessage());
        }
    }
}
