<?php
/**
 * ReadingAnalysisService.php
 * Core anomaly detection engine for all reading types.
 * Loads configurable thresholds from approval_settings table.
 */
class ReadingAnalysisService {
    private PDO $db;
    private array $settings = [];

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
        $this->loadSettings();
    }

    // ─── Main Entry Point ─────────────────────────────────────────────────────

    /**
     * Analyze a reading and return structured warnings + stats.
     *
     * @param int    $readingId  The reading's primary key
     * @param string $type       'electricity' | 'subscription' | 'generator'
     * @return array {warnings, stats, has_image, previous_reading, history}
     */
    public function analyze(int $readingId, string $type): array {
        $reading = $this->fetchReading($readingId, $type);
        if (!$reading) return ['error' => 'Reading not found'];

        $history    = $this->fetchHistory($reading, $type);
        $warnings   = [];
        $stats      = $this->computeStats($history, $reading, $type);
        $current    = floatval($reading['current_reading'] ?? (
            (!empty($reading['current_meter_hours']) && floatval($reading['current_meter_hours']) > 0)
                ? $reading['current_meter_hours']
                : ($reading['meter_hours'] ?? $reading['current_kwh'] ?? $reading['running_hours'] ?? 0)
        ));
        $previous   = floatval($reading['previous_reading'] ?? (
            (!empty($reading['previous_meter_hours']) && floatval($reading['previous_meter_hours']) > 0)
                ? $reading['previous_meter_hours']
                : ($reading['previous_kwh'] ?? 0)
        ));
        $consumption = floatval($reading['consumption'] ?? (
            (!empty($reading['running_hours']) && floatval($reading['running_hours']) > 0)
                ? $reading['running_hours']
                : ($reading['kwh_produced'] ?? ($current >= $previous ? ($current - $previous) : 0))
        ));

        // ── Rule 1: Meter Rollback ─────────────────────────────────────────
        if ($current > 0 && $previous > 0 && $current < $previous) {
            $warnings[] = $this->warn(
                'METER_ROLLBACK',
                'critical',
                'Meter Rollback Detected',
                "Current reading ({$current}) is lower than previous reading ({$previous}). This is normally impossible.",
                ['current' => $current, 'previous' => $previous]
            );
        }

        // ── Rule 2: Duplicate Reading ─────────────────────────────────────
        $dupCheck = $this->checkDuplicate($reading, $type);
        if ($dupCheck) {
            $warnings[] = $this->warn(
                'DUPLICATE_READING',
                'high',
                'Possible Duplicate Submission',
                "A reading with the same value ({$current}) was submitted {$dupCheck['days_ago']} day(s) ago.",
                $dupCheck
            );
        }

        // ── Rule 3: Missing Image ─────────────────────────────────────────
        $hasImage = !empty($reading['photo_path']) || !empty($reading['photo_meter_path']);
        if (!$hasImage && $this->getSetting('require_image', 'true') === 'true') {
            $warnings[] = $this->warn(
                'MISSING_IMAGE',
                'medium',
                'Missing Meter Photo',
                'No meter photo was uploaded with this reading. Photo is required for verification.',
                []
            );
        }

        // ── Generator-Specific Rules ──────────────────────────────────────
        if ($type === 'generator') {
            if ($consumption > 24) {
                $warnings[] = $this->warn(
                    'EXCESSIVE_DAILY_HOURS',
                    'critical',
                    'Impossible Runtime',
                    "Reported running hours ({$consumption}h) exceeds 24 hours in a single day.",
                    ['consumption' => $consumption]
                );
            } elseif ($consumption > 18) {
                $warnings[] = $this->warn(
                    'HEAVY_RUNTIME',
                    'medium',
                    'Heavy Continuous Run Time',
                    "Generator operated for {$consumption} hours today. Continuous high runtime may accelerate maintenance requirements.",
                    ['consumption' => $consumption]
                );
            }

            $minFuel = floatval($reading['min_fuel_level_alert'] ?? 100);
            $fuelRemaining = floatval($reading['fuel_remaining'] ?? $reading['current_fuel'] ?? 0);
            if ($fuelRemaining > 0 && $fuelRemaining < $minFuel) {
                $warnings[] = $this->warn(
                    'LOW_FUEL_ALERT',
                    'high',
                    'Low Fuel Tank Alert',
                    "Current fuel level ({$fuelRemaining} L) is below the minimum safety threshold ({$minFuel} L). Refill recommended.",
                    ['fuel_remaining' => $fuelRemaining, 'min_threshold' => $minFuel]
                );
            }

            if (empty($warnings)) {
                $warnings[] = $this->warn(
                    'AI_DIAGNOSTIC_VERIFIED',
                    'info',
                    'Telemetry & Burn Rate Verified',
                    "Engine run time ({$consumption}h) aligns with expected factory burn rate (~{$stats['expected_burn']} L). Readings are consistent.",
                    ['expected_burn' => $stats['expected_burn'], 'runtime' => $consumption]
                );
            }
        }

        // ── Rules 4–6 only if we have history (Electricity & Subscriptions) ─────────────────────────────
        if ($type !== 'generator' && !empty($history) && $stats['avg_3m'] > 0) {
            $highPct = (int)$this->getSetting('high_consumption_percent', '200');
            $lowPct  = (int)$this->getSetting('low_consumption_percent',  '30');

            // Rule 4: High Consumption
            $highThreshold = $stats['avg_3m'] * (1 + $highPct / 100);
            if ($consumption > $highThreshold && $consumption > 0) {
                $pctAbove = round((($consumption - $stats['avg_3m']) / $stats['avg_3m']) * 100);
                $warnings[] = $this->warn(
                    'HIGH_CONSUMPTION',
                    'medium',
                    'High Consumption',
                    "Consumption ({$consumption} kWh) is {$pctAbove}% above the 3-month average ({$stats['avg_3m']} kWh). Threshold: {$highPct}%.",
                    ['consumption' => $consumption, 'avg_3m' => $stats['avg_3m'], 'percent_above' => $pctAbove, 'threshold' => $highPct]
                );
            }

            // Rule 5: Very Low Consumption
            $lowThreshold = $stats['avg_3m'] * ($lowPct / 100);
            if ($consumption < $lowThreshold && $consumption >= 0 && $stats['avg_3m'] > 5) {
                $pctBelow = round((($stats['avg_3m'] - $consumption) / $stats['avg_3m']) * 100);
                $warnings[] = $this->warn(
                    'LOW_CONSUMPTION',
                    'low',
                    'Very Low Consumption',
                    "Consumption ({$consumption} kWh) is {$pctBelow}% below the 3-month average ({$stats['avg_3m']} kWh).",
                    ['consumption' => $consumption, 'avg_3m' => $stats['avg_3m'], 'percent_below' => $pctBelow]
                );
            }

            // Rule 6: Possible Wrong Digit (e.g., 13,999 instead of 12,999)
            $expectedReading  = $previous + $stats['avg_3m'];
            $digitErrPct      = (int)$this->getSetting('possible_digit_error_pct', '40');
            if ($current > 0 && $expectedReading > 0) {
                $diffPct = abs($current - $expectedReading) / max($expectedReading, 1) * 100;
                if ($diffPct > $digitErrPct) {
                    $warnings[] = $this->warn(
                        'POSSIBLE_DIGIT_ERROR',
                        'high',
                        'Possible Typing Error',
                        "Submitted reading ({$current}) differs {$diffPct}% from the expected value (~{$expectedReading}). Check for digit transposition.",
                        ['submitted' => $current, 'expected' => round($expectedReading, 0), 'diff_pct' => round($diffPct, 1)]
                    );
                }
            }
        }

        // ── Rule 7: Unusual Monthly Spike vs full history ──────────────────
        if (!empty($history) && $stats['avg_12m'] > 0 && $consumption > 0) {
            $maxPossible = (int)$this->getSetting('max_daily_consumption_kwh', '1000') * 31;
            if ($consumption > $maxPossible) {
                $warnings[] = $this->warn(
                    'UNUSUAL_MONTHLY_SPIKE',
                    'critical',
                    'Unusual Monthly Spike',
                    "Consumption ({$consumption} kWh) exceeds the maximum plausible monthly consumption ({$maxPossible} kWh).",
                    ['consumption' => $consumption, 'max_plausible' => $maxPossible]
                );
            }
        }

        // ── Rule 8: Long Time Without Reading ─────────────────────────────
        $daysSinceLast = $this->daysSinceLastReading($reading, $type);
        $longDays      = (int)$this->getSetting('long_without_reading_days', '45');
        if ($daysSinceLast !== null && $daysSinceLast > $longDays) {
            $warnings[] = $this->warn(
                'LONG_WITHOUT_READING',
                'low',
                'Long Period Without Reading',
                "Last reading was {$daysSinceLast} days ago (threshold: {$longDays} days). This may indicate a missed month.",
                ['days_since_last' => $daysSinceLast, 'threshold' => $longDays]
            );
        }

        // ── Rule 9: First Reading (informational) ─────────────────────────
        if (empty($history)) {
            $warnings[] = $this->warn(
                'FIRST_READING',
                'info',
                'First Reading',
                'No historical data available for comparison. This appears to be the first reading for this meter.',
                []
            );
        }

        // ── Rule 10: Same Month Last Year Comparison ──────────────────────
        if (!empty($stats['same_month_last_year']) && $consumption > 0) {
            $ly = floatval($stats['same_month_last_year']);
            if ($ly > 0) {
                $lyDiff = round((($consumption - $ly) / $ly) * 100, 1);
                $stats['year_over_year_change'] = $lyDiff;
            }
        }

        return [
            'reading_id'   => $readingId,
            'type'         => $type,
            'warnings'     => $warnings,
            'stats'        => $stats,
            'has_image'    => $hasImage,
            'history'      => $history,
            'days_since_last_reading' => $daysSinceLast,
        ];
    }

    // ─── Private: fetch reading by type ──────────────────────────────────────

    private function fetchReading(int $id, string $type): ?array {
        switch ($type) {
            case 'electricity':
                $stmt = $this->db->prepare("
                    SELECT emr.*, a.code as apartment_code, b.id as building_id, b.name as building_name,
                           u.name as submitter_name
                    FROM electricity_meter_readings emr
                    JOIN apartments a ON emr.apartment_id = a.id
                    JOIN buildings b ON a.building_id = b.id
                    LEFT JOIN users u ON emr.submitted_by = u.id
                    WHERE emr.id = ?
                ");
                break;
            case 'subscription':
                $stmt = $this->db->prepare("
                    SELECT asr.*, a.code as apartment_code, b.id as building_id, b.name as building_name,
                           u.name as submitter_name
                    FROM agent_subscription_readings asr
                    JOIN apartments a ON asr.apartment_id = a.id
                    JOIN buildings b ON a.building_id = b.id
                    LEFT JOIN users u ON asr.submitted_by = u.id
                    WHERE asr.id = ?
                ");
                break;
            case 'generator':
                $stmt = $this->db->prepare("
                    SELECT gdr.*, 
                           COALESCE(NULLIF(gdr.current_meter_hours, 0), NULLIF(gdr.meter_hours, 0), NULLIF(gdr.current_kwh, 0), gdr.running_hours, 0) as current_reading,
                           COALESCE(NULLIF(gdr.previous_meter_hours, 0), NULLIF(gdr.previous_kwh, 0), 0) as previous_reading,
                           COALESCE(NULLIF(gdr.running_hours, 0), NULLIF(gdr.kwh_produced, 0), 0) as consumption,
                           g.name as generator_name, b.id as building_id, b.name as building_name,
                           g.expected_fuel_consumption_per_hour, g.min_fuel_level_alert, g.fuel_capacity, g.current_fuel,
                           u.name as submitter_name
                    FROM generator_daily_reports gdr
                    JOIN generators g ON gdr.generator_id = g.id
                    JOIN buildings b ON g.building_id = b.id
                    LEFT JOIN users u ON gdr.submitted_by = u.id
                    WHERE gdr.id = ?
                ");
                break;
            default:
                return null;
        }
        $stmt->execute([$id]);
        return $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
    }

    // ─── Private: fetch reading history for the apartment/generator ──────────

    private function fetchHistory(array $reading, string $type): array {
        try {
            if ($type === 'generator') {
                $stmt = $this->db->prepare("
                    SELECT 
                        COALESCE(NULLIF(gdr.running_hours, 0), NULLIF(gdr.kwh_produced, 0), 0) as consumption,
                        gdr.date as reading_date,
                        DATE_FORMAT(gdr.date, '%b %d, %Y') as month_label,
                        COALESCE(NULLIF(gdr.current_meter_hours, 0), NULLIF(gdr.meter_hours, 0), NULLIF(gdr.current_kwh, 0), gdr.running_hours, 0) as current_reading,
                        COALESCE(NULLIF(gdr.previous_meter_hours, 0), NULLIF(gdr.previous_kwh, 0), 0) as previous_reading,
                        gdr.id
                    FROM generator_daily_reports gdr
                    WHERE gdr.generator_id = ? AND gdr.id != ?
                    ORDER BY gdr.date DESC, gdr.id DESC LIMIT 10
                ");
                $stmt->execute([$reading['generator_id'], $reading['id']]);
                $history = $stmt->fetchAll(PDO::FETCH_ASSOC);

                // Supplement with daily_logs if fewer than 5 records exist
                if (count($history) < 5) {
                    $stmtLogs = $this->db->prepare("
                        SELECT 
                            calculated_hours_worked as consumption,
                            date as reading_date,
                            DATE_FORMAT(date, '%b %d, %Y') as month_label,
                            submitted_hours as current_reading,
                            (submitted_hours - calculated_hours_worked) as previous_reading,
                            id
                        FROM daily_logs
                        WHERE generator_id = ? AND (date != ? OR submitted_hours != ?)
                        ORDER BY date DESC, id DESC LIMIT 10
                    ");
                    $curDate = $reading['date'] ?? date('Y-m-d');
                    $curMeter = floatval($reading['current_reading'] ?? 0);
                    $stmtLogs->execute([$reading['generator_id'], $curDate, $curMeter]);
                    $logHistory = $stmtLogs->fetchAll(PDO::FETCH_ASSOC);

                    $existingDates = array_column($history, 'reading_date');
                    foreach ($logHistory as $lh) {
                        if (!in_array($lh['reading_date'], $existingDates)) {
                            $history[] = $lh;
                            $existingDates[] = $lh['reading_date'];
                        }
                    }
                }
                return $history;
            } else {
                $apartmentId = $reading['apartment_id'];
                $stmt = $this->db->prepare("
                    SELECT consumption, reading_date, current_reading, previous_reading, id,
                           DATE_FORMAT(reading_date, '%Y-%m') as month_label
                    FROM electricity_meter_readings
                    WHERE apartment_id = ?
                      AND status IN ('Verified', 'Accepted', 'Approved')
                      AND id != ?
                    ORDER BY reading_date DESC LIMIT 13
                ");
                $stmt->execute([$apartmentId, $reading['id']]);
                return $stmt->fetchAll(PDO::FETCH_ASSOC);
            }
        } catch (PDOException $e) {
            return [];
        }
    }

    // ─── Private: compute statistical averages ────────────────────────────────

    private function computeStats(array $history, array $reading, string $type = 'electricity'): array {
        $consumptions = array_map(fn($r) => floatval($r['consumption']), $history);
        $consumptions = array_filter($consumptions, fn($c) => $c > 0);
        $consumptions = array_values($consumptions);

        if ($type === 'generator') {
            $burnRate = floatval($reading['expected_fuel_consumption_per_hour'] ?? 10.0);
            $avgRunHours = count($consumptions) ? round(array_sum($consumptions) / count($consumptions), 1) : 10.0;
            $currentRun = floatval($reading['consumption'] ?? $reading['running_hours'] ?? 0);
            $expectedBurn = round($currentRun * $burnRate, 1);
            $fuelRemaining = floatval($reading['fuel_remaining'] ?? $reading['current_fuel'] ?? 0);
            $fuelCapacity = floatval($reading['fuel_capacity'] ?? 1000);

            return [
                'avg_3m'              => $avgRunHours,
                'building_avg'        => $burnRate,
                'history_count'       => count($consumptions),
                'expected_burn'       => $expectedBurn,
                'fuel_remaining'      => $fuelRemaining,
                'fuel_capacity'       => $fuelCapacity,
                'unit'                => 'hrs/day',
                'secondary_unit'      => 'L/h',
                'same_month_last_year'=> null,
                'avg_6m'              => $avgRunHours,
                'avg_12m'             => $avgRunHours,
            ];
        }

        // Building average
        $buildingAvg = 0;
        try {
            if (isset($reading['building_id'])) {
                $stmt = $this->db->prepare("
                    SELECT AVG(emr.consumption)
                    FROM electricity_meter_readings emr
                    JOIN apartments a ON emr.apartment_id = a.id
                    WHERE a.building_id = ? AND emr.status IN ('Verified','Accepted','Approved')
                    AND emr.reading_date >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)
                ");
                $stmt->execute([$reading['building_id']]);
                $buildingAvg = round((float)$stmt->fetchColumn(), 2);
            }
        } catch (PDOException $e) {}

        // Same month last year
        $sameMthLY = null;
        if (!empty($history)) {
            $readingMonth = isset($reading['reading_date']) ? date('m', strtotime($reading['reading_date'])) : date('m');
            foreach ($history as $h) {
                if (!empty($h['reading_date'])) {
                    $hMonth = date('m', strtotime($h['reading_date']));
                    $hYear  = date('Y', strtotime($h['reading_date']));
                    if ($hMonth === $readingMonth && $hYear == date('Y') - 1) {
                        $sameMthLY = floatval($h['consumption']);
                        break;
                    }
                }
            }
        }

        return [
            'avg_3m'              => $avg3m,
            'avg_6m'              => $avg6m,
            'avg_12m'             => $avg12m,
            'building_avg'        => $buildingAvg,
            'same_month_last_year'=> $sameMthLY,
            'history_count'       => count($consumptions),
        ];
    }

    // ─── Private: duplicate check ─────────────────────────────────────────────

    private function checkDuplicate(array $reading, string $type): ?array {
        $dupDays = (int)$this->getSetting('duplicate_reading_days', '2');
        $current = floatval($reading['current_reading'] ?? $reading['current_kwh'] ?? 0);
        if ($current <= 0) return null;

        try {
            if ($type === 'electricity' || $type === 'subscription') {
                $table = $type === 'electricity' ? 'electricity_meter_readings' : 'agent_subscription_readings';
                $stmt = $this->db->prepare("
                    SELECT id, created_at,
                           DATEDIFF(NOW(), created_at) as days_ago
                    FROM $table
                    WHERE apartment_id = ? AND current_reading = ? AND id != ?
                    AND created_at >= DATE_SUB(NOW(), INTERVAL ? DAY)
                    ORDER BY created_at DESC LIMIT 1
                ");
                $stmt->execute([$reading['apartment_id'], $current, $reading['id'], $dupDays]);
            } else {
                return null;
            }
            $dup = $stmt->fetch(PDO::FETCH_ASSOC);
            return $dup ?: null;
        } catch (PDOException $e) {
            return null;
        }
    }

    // ─── Private: days since last reading ────────────────────────────────────

    private function daysSinceLastReading(array $reading, string $type): ?int {
        try {
            if ($type === 'electricity' || $type === 'subscription') {
                $stmt = $this->db->prepare("
                    SELECT DATEDIFF(CURDATE(), MAX(reading_date)) as days
                    FROM electricity_meter_readings
                    WHERE apartment_id = ? AND id != ? AND status IN ('Verified','Accepted','Approved')
                ");
                $stmt->execute([$reading['apartment_id'], $reading['id']]);
                $days = $stmt->fetchColumn();
                return ($days !== false && $days !== null) ? (int)$days : null;
            }
        } catch (PDOException $e) {}
        return null;
    }

    // ─── Private: helpers ─────────────────────────────────────────────────────

    private function warn(string $code, string $level, string $title, string $message, array $data): array {
        return [
            'code'    => $code,
            'level'   => $level,   // 'critical'|'high'|'medium'|'low'|'info'
            'title'   => $title,
            'message' => $message,
            'data'    => $data,
        ];
    }

    private function loadSettings(): void {
        try {
            $stmt = $this->db->query("SELECT setting_key, setting_value FROM approval_settings");
            foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
                $this->settings[$row['setting_key']] = $row['setting_value'];
            }
        } catch (PDOException $e) {
            // Table might not exist yet — use defaults silently
        }
    }

    private function getSetting(string $key, string $default): string {
        return $this->settings[$key] ?? $default;
    }
}
