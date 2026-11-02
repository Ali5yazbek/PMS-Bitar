<?php
// backend/services/RentGenerationService.php

require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../core/Database.php';
require_once __DIR__ . '/../utils/AuditLogger.php';

class RentGenerationService {
    public const TIMEZONE = 'Africa/Bangui';

    /**
     * Get the current date in the configured timezone.
     */
    public static function getNowBangui(?DateTimeInterface $asOfDate = null): DateTime {
        $tz = new DateTimeZone(self::TIMEZONE);
        if ($asOfDate !== null) {
            $dt = new DateTime($asOfDate->format('Y-m-d H:i:s'), $asOfDate->getTimezone());
            $dt->setTimezone($tz);
            return $dt;
        }
        return new DateTime('now', $tz);
    }

    /**
     * Calculate the next billing date given a current billing date, frequency, and an anchor billing day.
     * Preserves the anchor day (e.g., 31st or 21st) and safely clamps to month-end (e.g. Feb 28/29, Apr 30)
     * without month-skipping or date drift.
     */
    public static function calculateNextBillingDate(string $currentDate, string $frequency = 'Monthly', ?int $anchorDay = null): string {
        $date = new DateTime($currentDate);
        $currDay = (int)$date->format('d');
        $currMonth = (int)$date->format('m');
        $currYear = (int)$date->format('Y');

        $day = $anchorDay ?: $currDay;

        switch ($frequency) {
            case 'Weekly':
                $date->modify('+1 week');
                return $date->format('Y-m-d');

            case 'Quarterly':
                $targetMonth = $currMonth + 3;
                $targetYear = $currYear;
                if ($targetMonth > 12) {
                    $targetMonth -= 12;
                    $targetYear += 1;
                }
                $daysInTarget = (int)(new DateTime(sprintf('%04d-%02d-01', $targetYear, $targetMonth)))->format('t');
                $actualDay = min($day, $daysInTarget);
                return sprintf('%04d-%02d-%02d', $targetYear, $targetMonth, $actualDay);

            case 'Yearly':
                $targetYear = $currYear + 1;
                $targetMonth = $currMonth;
                $daysInTarget = (int)(new DateTime(sprintf('%04d-%02d-01', $targetYear, $targetMonth)))->format('t');
                $actualDay = min($day, $daysInTarget);
                return sprintf('%04d-%02d-%02d', $targetYear, $targetMonth, $actualDay);

            case 'Monthly':
            default:
                $targetMonth = $currMonth + 1;
                $targetYear = $currYear;
                if ($targetMonth > 12) {
                    $targetMonth = 1;
                    $targetYear += 1;
                }
                $daysInTarget = (int)(new DateTime(sprintf('%04d-%02d-01', $targetYear, $targetMonth)))->format('t');
                $actualDay = min($day, $daysInTarget);
                return sprintf('%04d-%02d-%02d', $targetYear, $targetMonth, $actualDay);
        }
    }

    /**
     * Compute period_start, period_end, and next_billing_date for a given cycle.
     */
    public static function calculatePeriodDates(string $dueDate, string $frequency = 'Monthly', ?int $anchorDay = null): array {
        $nextDate = self::calculateNextBillingDate($dueDate, $frequency, $anchorDay);
        $periodStart = $dueDate;
        $periodEnd = (new DateTime($nextDate))->modify('-1 day')->format('Y-m-d');

        return [
            'period_start'      => $periodStart,
            'period_end'        => $periodEnd,
            'next_billing_date' => $nextDate
        ];
    }

    /**
     * Generate all due rent invoices across eligible active contracts (or for a specific contract).
     * Catch-up mechanism: If multiple months were missed, generates every missing period sequentially.
     * Idempotent: Can be run multiple times safely.
     *
     * @param int|null $specificContractId Optional filter for a specific contract.
     * @param DateTimeInterface|null $asOfDate Reference date for generation decisions (defaults to today in Africa/Bangui).
     * @return array Summary of processed, generated, and skipped contracts.
     */
    public static function generateDueInvoices(?int $specificContractId = null, ?DateTimeInterface $asOfDate = null): array {
        $db = Database::getInstance()->getConnection();
        $now = self::getNowBangui($asOfDate);
        $todayStr = $now->format('Y-m-d');

        $summary = [
            'status'            => 'Success',
            'as_of_date'        => $todayStr,
            'timezone'          => self::TIMEZONE,
            'contracts_checked' => 0,
            'invoices_created'  => 0,
            'details'           => [],
            'errors'            => []
        ];

        // 1. Fetch eligible active contracts
        $sql = "
            SELECT c.id AS contract_id, c.tenant_id, c.apartment_id, c.start_date, c.end_date, 
                   c.monthly_rent, c.status AS contract_status, c.rent_status,
                   t.full_name AS tenant_name, t.status AS tenant_status,
                   rp.id AS profile_id, rp.next_billing_date, rp.billing_frequency, 
                   rp.rent_start_date, rp.monthly_amount, rp.status AS profile_status
            FROM contracts c
            JOIN tenants t ON c.tenant_id = t.id
            LEFT JOIN rent_profiles rp ON c.id = rp.contract_id
            WHERE c.status IN ('Active', 'Approved')
              AND c.deleted_at IS NULL
              AND c.rent_status = 'Active'
              AND t.status = 'Active'
        ";

        $params = [];
        if ($specificContractId !== null) {
            $sql .= " AND c.id = ?";
            $params[] = $specificContractId;
        }

        $sql .= " ORDER BY c.id ASC";

        $stmt = $db->prepare($sql);
        $stmt->execute($params);
        $contracts = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $summary['contracts_checked'] = count($contracts);

        foreach ($contracts as $contract) {
            $contractId = (int)$contract['contract_id'];
            $frequency = $contract['billing_frequency'] ?: 'Monthly';
            $monthlyRent = (float)($contract['monthly_amount'] ?: $contract['monthly_rent']);
            $contractEnd = $contract['end_date'];

            // Skip if contract lease has already passed
            if (!empty($contractEnd) && $contractEnd < $todayStr) {
                continue;
            }

            // Skip if rent profile is explicitly Ended or Closed
            if (in_array($contract['profile_status'], ['Ended', 'Closed'])) {
                continue;
            }

            // Determine the anchor day (e.g., 21)
            $anchorSource = $contract['rent_start_date'] ?: $contract['start_date'];
            $anchorDay = $anchorSource ? (int)date('d', strtotime($anchorSource)) : 1;

            // Determine what the current unbilled due date is
            // Look up the latest invoice in the DB for this contract
            $stmtLastInv = $db->prepare("
                SELECT due_date, period_end 
                FROM rent_invoices 
                WHERE contract_id = ? 
                ORDER BY due_date DESC 
                LIMIT 1
            ");
            $stmtLastInv->execute([$contractId]);
            $lastInvoice = $stmtLastInv->fetch(PDO::FETCH_ASSOC);

            if ($lastInvoice) {
                // Next due date should be the cycle following the last invoice's due_date
                $currentDueDate = self::calculateNextBillingDate($lastInvoice['due_date'], $frequency, $anchorDay);
            } else {
                // No invoices exist yet: use rent profile next_billing_date or contract start date
                $currentDueDate = $contract['next_billing_date'] ?: ($contract['rent_start_date'] ?: $contract['start_date']);
            }

            // Sync rent_profile if next_billing_date drifted behind or forward without invoices
            $profileId = $contract['profile_id'];
            if (!$profileId) {
                // Create rent profile if missing
                $stmtInsProf = $db->prepare("
                    INSERT INTO rent_profiles (tenant_id, apartment_id, contract_id, rent_start_date, monthly_amount, next_billing_date, billing_frequency, status, auto_renewal)
                    VALUES (?, ?, ?, ?, ?, ?, ?, 'Active', 1)
                ");
                $stmtInsProf->execute([
                    $contract['tenant_id'],
                    $contract['apartment_id'],
                    $contractId,
                    $anchorSource ?: $todayStr,
                    $monthlyRent,
                    $currentDueDate,
                    $frequency
                ]);
                $profileId = (int)$db->lastInsertId();
            }

            // Catch-up loop: Generate all eligible periods where due_date <= todayStr
            while ($currentDueDate <= $todayStr) {
                // Do not generate invoices past contract end_date
                if (!empty($contractEnd) && $currentDueDate > $contractEnd) {
                    break;
                }

                $periodInfo = self::calculatePeriodDates($currentDueDate, $frequency, $anchorDay);
                $periodStart = $periodInfo['period_start'];
                $periodEnd = $periodInfo['period_end'];
                $nextDueDate = $periodInfo['next_billing_date'];

                // Truncate period_end if it exceeds contract end date
                if (!empty($contractEnd) && $periodEnd > $contractEnd) {
                    $periodEnd = $contractEnd;
                }

                // Check for duplicate invoice in DB
                $stmtCheck = $db->prepare("
                    SELECT id FROM rent_invoices 
                    WHERE contract_id = ? AND (due_date = ? OR period_start = ?)
                ");
                $stmtCheck->execute([$contractId, $currentDueDate, $periodStart]);
                $existingInvId = $stmtCheck->fetchColumn();

                if ($existingInvId) {
                    // Already exists — advance pointer safely and continue catch-up
                    $currentDueDate = $nextDueDate;
                    continue;
                }

                // Generate unique invoice number
                $invDate = new DateTime($currentDueDate);
                $invoiceNum = 'INV-' . $invDate->format('Ym') . '-' . $contractId;

                // Ensure invoice number uniqueness
                $stmtNumCheck = $db->prepare("SELECT id FROM rent_invoices WHERE invoice_number = ?");
                $stmtNumCheck->execute([$invoiceNum]);
                if ($stmtNumCheck->fetch()) {
                    $invoiceNum = 'INV-' . $invDate->format('Ymd') . '-' . $contractId . '-' . substr(uniqid(), -3);
                }

                $isInnerTx = false;
                try {
                    if (!$db->inTransaction()) {
                        $db->beginTransaction();
                        $isInnerTx = true;
                    }

                    // Optional: Link/Create rent_period for ERP backwards-compatibility
                    $rentPeriodId = null;
                    try {
                        $stmtCheckPeriod = $db->prepare("
                            SELECT id FROM rent_periods 
                            WHERE contract_id = ? AND start_date = ? AND end_date = ?
                        ");
                        $stmtCheckPeriod->execute([$contractId, $periodStart, $periodEnd]);
                        $rentPeriodId = $stmtCheckPeriod->fetchColumn();

                        if (!$rentPeriodId) {
                            $stmtInsPeriod = $db->prepare("
                                INSERT INTO rent_periods (contract_id, start_date, end_date) 
                                VALUES (?, ?, ?)
                            ");
                            $stmtInsPeriod->execute([$contractId, $periodStart, $periodEnd]);
                            $rentPeriodId = (int)$db->lastInsertId();
                        }
                    } catch (Exception $ePeriod) {
                        // Table may not have unique index or non-essential, ignore
                    }

                    // Insert the new rent invoice
                    $stmtInsInv = $db->prepare("
                        INSERT INTO rent_invoices (
                            contract_id, rent_profile_id, rent_period_id, invoice_number, 
                            amount, due_date, status, period_start, period_end, created_at
                        ) VALUES (?, ?, ?, ?, ?, ?, 'Unpaid', ?, ?, NOW())
                    ");
                    $stmtInsInv->execute([
                        $contractId,
                        $profileId,
                        $rentPeriodId,
                        $invoiceNum,
                        $monthlyRent,
                        $currentDueDate,
                        $periodStart,
                        $periodEnd
                    ]);
                    $newInvoiceId = (int)$db->lastInsertId();

                    // Advance the profile's next_billing_date ONLY AFTER successfully saving invoice
                    $stmtUpdProfile = $db->prepare("
                        UPDATE rent_profiles 
                        SET next_billing_date = ?, status = 'Active', updated_at = NOW() 
                        WHERE id = ?
                    ");
                    $stmtUpdProfile->execute([$nextDueDate, $profileId]);

                    // Record history
                    try {
                        $stmtHist = $db->prepare("
                            INSERT INTO rent_profile_history (rent_profile_id, action, previous_value, new_value, notes)
                            VALUES (?, 'Rent Auto-Generated', ?, ?, ?)
                        ");
                        $stmtHist->execute([
                            $profileId,
                            $currentDueDate,
                            $nextDueDate,
                            "System auto-generated invoice #{$invoiceNum} for {$currentDueDate} (Amount: {$monthlyRent} CFA)"
                        ]);
                    } catch (Exception $eHist) {}

                    if ($isInnerTx && $db->inTransaction()) {
                        $db->commit();
                    }

                    $summary['invoices_created']++;
                    $summary['details'][] = [
                        'contract_id'       => $contractId,
                        'tenant_name'       => $contract['tenant_name'],
                        'invoice_id'        => $newInvoiceId,
                        'invoice_number'    => $invoiceNum,
                        'due_date'          => $currentDueDate,
                        'amount'            => $monthlyRent,
                        'next_billing_date' => $nextDueDate
                    ];

                    AuditLogger::log(
                        'CREATE', 
                        'RentInvoice', 
                        $newInvoiceId, 
                        "Auto-generated rent invoice #{$invoiceNum} for {$contract['tenant_name']} (Due: {$currentDueDate})"
                    );

                    // Move to next cycle for catch-up
                    $currentDueDate = $nextDueDate;

                } catch (Exception $e) {
                    if ($isInnerTx && $db->inTransaction()) {
                        $db->rollBack();
                    }
                    $summary['errors'][] = [
                        'contract_id' => $contractId,
                        'due_date'    => $currentDueDate,
                        'error'       => $e->getMessage()
                    ];
                    // Break loop for this contract on error to prevent infinite loop
                    break;
                }
            }
        }

        return $summary;
    }

    /**
     * Reconcile payment status and financial totals for all invoices (or single contract).
     * Enforces:
     * - Paid: balance <= 0 and amount > 0
     * - Partial: paid > 0 and balance > 0
     * - Overdue: paid == 0 and due_date < today
     * - Unpaid: paid == 0 and due_date >= today
     * - Voided: preserved
     */
    public static function reconcileInvoiceStatuses(?int $contractId = null, ?DateTimeInterface $asOfDate = null): array {
        $db = Database::getInstance()->getConnection();
        $now = self::getNowBangui($asOfDate);
        $todayStr = $now->format('Y-m-d');

        $sql = "
            SELECT ri.id, ri.contract_id, ri.invoice_number, ri.amount, ri.due_date, ri.status,
                   COALESCE((SELECT SUM(amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0) as paid_amount
            FROM rent_invoices ri
            WHERE 1=1
        ";
        $params = [];
        if ($contractId !== null) {
            $sql .= " AND ri.contract_id = ?";
            $params[] = $contractId;
        }

        $stmt = $db->prepare($sql);
        $stmt->execute($params);
        $invoices = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $reconciled = 0;
        $upd = $db->prepare("UPDATE rent_invoices SET status = ? WHERE id = ?");

        foreach ($invoices as $inv) {
            if ($inv['status'] === 'Voided') {
                continue;
            }

            $amount = (float)$inv['amount'];
            $paid = (float)$inv['paid_amount'];
            $balance = $amount - $paid;
            $isOverdue = ($inv['due_date'] < $todayStr);

            $targetStatus = 'Unpaid';
            if ($balance <= 0.001 && $amount > 0) {
                $targetStatus = 'Paid';
            } elseif ($paid > 0 && $balance > 0.001) {
                $targetStatus = 'Partial';
            } else {
                $targetStatus = $isOverdue ? 'Overdue' : 'Unpaid';
            }

            if ($inv['status'] !== $targetStatus) {
                $upd->execute([$targetStatus, $inv['id']]);
                $reconciled++;
            }
        }

        return ['reconciled_count' => $reconciled, 'total_checked' => count($invoices)];
    }

    /**
     * Run the full daily automation:
     * 1. Generate all due rent invoices (with catch-up).
     * 2. Reconcile statuses.
     * 3. Log results to scheduled_jobs table.
     */
    public static function runDaily(?DateTimeInterface $asOfDate = null): array {
        $startTime = microtime(true);
        $db = Database::getInstance()->getConnection();

        $genResult = self::generateDueInvoices(null, $asOfDate);
        $recResult = self::reconcileInvoiceStatuses(null, $asOfDate);

        $duration = round(microtime(true) - $startTime, 2);
        $status = empty($genResult['errors']) ? 'Success' : 'Partial Failure';
        $errorMsg = !empty($genResult['errors']) ? json_encode($genResult['errors']) : null;
        $records = $genResult['invoices_created'] + $recResult['reconciled_count'];

        // Record to scheduled_jobs table
        try {
            $stmt = $db->prepare("
                INSERT INTO scheduled_jobs (job_name, status, duration_seconds, records_processed, last_run, error_message)
                VALUES ('Daily Rent Scheduler', ?, ?, ?, NOW(), ?)
                ON DUPLICATE KEY UPDATE
                    status = VALUES(status),
                    duration_seconds = VALUES(duration_seconds),
                    records_processed = VALUES(records_processed),
                    last_run = VALUES(last_run),
                    error_message = VALUES(error_message)
            ");
            $stmt->execute([$status, $duration, $records, $errorMsg]);
        } catch (Exception $e) {}

        return [
            'status'             => $status,
            'duration_seconds'   => $duration,
            'invoices_created'   => $genResult['invoices_created'],
            'statuses_reconciled'=> $recResult['reconciled_count'],
            'errors'             => $genResult['errors'],
            'details'            => $genResult['details']
        ];
    }

    /**
     * Safe catch-up mechanism for web requests.
     * Checks if the scheduled job has run today; if not or stale, runs generation.
     * Rate-limited to run at most once every 30 minutes to prevent overhead.
     */
    public static function runCatchUpIfDue(): void {
        try {
            $db = Database::getInstance()->getConnection();
            $stmt = $db->query("
                SELECT last_run 
                FROM scheduled_jobs 
                WHERE job_name = 'Daily Rent Scheduler'
            ");
            $lastRun = $stmt->fetchColumn();

            $shouldRun = true;
            if ($lastRun) {
                $lastTime = strtotime($lastRun);
                // If run within the last 30 minutes, skip
                if ((time() - $lastTime) < 1800) {
                    $shouldRun = false;
                }
            }

            if ($shouldRun) {
                self::runDaily();
            }
        } catch (Throwable $e) {
            // Fail silently on web catch-up check to not interrupt user request
        }
    }

    /**
     * Catch up invoices for a specific tenant when their details or history is requested.
     */
    public static function catchUpForTenant(int $tenantId): void {
        try {
            $db = Database::getInstance()->getConnection();
            $stmt = $db->prepare("
                SELECT id 
                FROM contracts 
                WHERE tenant_id = ? AND status IN ('Active', 'Approved') AND deleted_at IS NULL
            ");
            $stmt->execute([$tenantId]);
            $contractIds = $stmt->fetchAll(PDO::FETCH_COLUMN);

            foreach ($contractIds as $cid) {
                self::generateDueInvoices((int)$cid);
                self::reconcileInvoiceStatuses((int)$cid);
            }
        } catch (Throwable $e) {
            // Fail silently
        }
    }
}
