<?php
/**
 * AuditScanner — scans key database tables for data-quality problems
 * and writes findings to the `audit_reports` table.
 *
 * Called by ActionControlController::runAudit() or the daily cron.
 */
class AuditScanner {
    private $db;
    private int $foundCount   = 0;
    private int $criticalCount = 0;
    private int $warningCount  = 0;
    private int $infoCount     = 0;

    public function __construct(PDO $db) {
        $this->db = $db;
    }

    // ── Public entry point ────────────────────────────────────────────────────
    public function run(int $triggeredBy = 0): array {
        $start = microtime(true);

        $this->scanTenants();
        $this->scanApartments();
        $this->scanContracts();
        $this->scanWorkshops();

        $duration = (int)((microtime(true) - $start) * 1000);

        // Log the scan run
        $stmt = $this->db->prepare("
            INSERT INTO audit_scan_runs (triggered_by, total_found, critical_found, warning_found, info_found, duration_ms)
            VALUES (?, ?, ?, ?, ?, ?)
        ");
        $stmt->execute([
            $triggeredBy ?: null,
            $this->foundCount,
            $this->criticalCount,
            $this->warningCount,
            $this->infoCount,
            $duration
        ]);

        return [
            'total'    => $this->foundCount,
            'critical' => $this->criticalCount,
            'warning'  => $this->warningCount,
            'info'     => $this->infoCount,
            'duration_ms' => $duration,
        ];
    }

    // ── Tenants ───────────────────────────────────────────────────────────────
    private function scanTenants(): void {
        try {
            $stmtCols = $this->db->query("SHOW COLUMNS FROM tenants");
            $cols = array_column($stmtCols->fetchAll(PDO::FETCH_ASSOC), 'Field');
        } catch (Exception $e) { return; }

        $select = "SELECT t.id, t.full_name, t.user_id, 'General' as department, u.name as user_name";
        if (in_array('national_id', $cols)) $select .= ", t.national_id";
        if (in_array('phone', $cols)) $select .= ", t.phone";
        if (in_array('email', $cols)) $select .= ", t.email";
        if (in_array('passport_expiry', $cols)) $select .= ", t.passport_expiry";
        if (in_array('contract_file', $cols)) $select .= ", t.contract_file";

        $select .= " FROM tenants t LEFT JOIN users u ON t.user_id = u.id";

        $stmt = $this->db->query($select);
        $tenants = $stmt->fetchAll(PDO::FETCH_ASSOC);

        foreach ($tenants as $t) {
            $empId = $t['user_id'];
            $dept  = $t['department'] ?? 'General';

            // Critical: national_id missing or default
            if (isset($t['national_id']) && (empty($t['national_id']) || $t['national_id'] === 'N/A')) {
                $this->upsert($empId, $dept, 'tenants', $t['id'], 'national_id', 'Missing', 'critical',
                    'National ID is missing for tenant: ' . $t['full_name']);
            }

            // Critical: no contract file
            if (isset($t['contract_file']) && empty($t['contract_file'])) {
                $this->upsert($empId, $dept, 'tenants', $t['id'], 'contract_file', 'Missing', 'critical',
                    'Contract PDF has not been uploaded for tenant: ' . $t['full_name']);
            }

            // Critical: passport expired
            if (isset($t['passport_expiry']) && !empty($t['passport_expiry'])) {
                $expiry = strtotime($t['passport_expiry']);
                if ($expiry !== false && $expiry < time()) {
                    $this->upsert($empId, $dept, 'tenants', $t['id'], 'passport_expiry', 'Expired', 'critical',
                        'Passport expired on ' . date('Y-m-d', $expiry) . ' for tenant: ' . $t['full_name']);
                } elseif ($expiry !== false && $expiry < strtotime('+30 days')) {
                    $this->upsert($empId, $dept, 'tenants', $t['id'], 'passport_expiry', 'Expired', 'info',
                        'Passport expires soon (' . date('Y-m-d', $expiry) . ') for tenant: ' . $t['full_name']);
                }
            }

            // Warning: phone missing or default
            if (isset($t['phone']) && (empty($t['phone']) || $t['phone'] === 'N/A')) {
                $this->upsert($empId, $dept, 'tenants', $t['id'], 'phone', 'Missing', 'warning',
                    'Phone number is missing for tenant: ' . $t['full_name']);
            }

            // Warning: email missing
            if (isset($t['email']) && empty($t['email'])) {
                $this->upsert($empId, $dept, 'tenants', $t['id'], 'email', 'Missing', 'warning',
                    'Email address is missing for tenant: ' . $t['full_name']);
            }
        }
    }

    // ── Apartments ────────────────────────────────────────────────────────────
    private function scanApartments(): void {
        try {
            $stmtCols = $this->db->query("SHOW COLUMNS FROM apartments");
            $cols = array_column($stmtCols->fetchAll(PDO::FETCH_ASSOC), 'Field');
        } catch (Exception $e) { return; }

        $select = "SELECT a.id, a.code, a.status, a.building_id, b.name as building_name, 'General' as department";
        if (in_array('owner_id', $cols)) {
            $select .= ", a.owner_id, u.id as owner_user_id";
        } else {
            $select .= ", NULL as owner_id, NULL as owner_user_id";
        }
        if (in_array('monthly_rent', $cols)) $select .= ", a.monthly_rent";

        $select .= " FROM apartments a LEFT JOIN buildings b ON a.building_id = b.id";
        if (in_array('owner_id', $cols)) {
            $select .= " LEFT JOIN users u ON a.owner_id = u.id";
        }

        $stmt = $this->db->query($select);
        $apartments = $stmt->fetchAll(PDO::FETCH_ASSOC);

        foreach ($apartments as $a) {
            $empId = $a['owner_user_id'] ?? null;
            $dept  = $a['department'] ?? 'General';

            // Critical: owner not assigned
            if (isset($a['owner_id']) && empty($a['owner_id'])) {
                $this->upsert($empId, $dept, 'apartments', $a['id'], 'owner_id', 'Missing', 'critical',
                    'Owner not assigned for apartment: ' . ($a['code'] ?? '#' . $a['id']));
            }

            // Critical: monthly rent = 0
            if (isset($a['monthly_rent']) && (empty($a['monthly_rent']) || (float)$a['monthly_rent'] <= 0)) {
                $this->upsert($empId, $dept, 'apartments', $a['id'], 'monthly_rent', 'Invalid', 'critical',
                    'Monthly rent is 0 or missing for apartment: ' . ($a['code'] ?? '#' . $a['id']));
            }

            // Warning: status is null or empty
            if (empty($a['status'])) {
                $this->upsert($empId, $dept, 'apartments', $a['id'], 'status', 'Missing', 'warning',
                    'Maintenance status not set for apartment: ' . ($a['code'] ?? '#' . $a['id']));
            }
        }
    }

    // ── Contracts ─────────────────────────────────────────────────────────────
    private function scanContracts(): void {
        try {
            $stmtCols = $this->db->query("SHOW COLUMNS FROM contracts");
            $cols = array_column($stmtCols->fetchAll(PDO::FETCH_ASSOC), 'Field');
        } catch (Exception $e) { return; }

        $select = "SELECT c.id, c.status, t.full_name as tenant_name, t.user_id as tenant_user_id, 'General' as department";
        if (in_array('tenant_id', $cols)) $select .= ", c.tenant_id";
        if (in_array('apartment_id', $cols)) $select .= ", c.apartment_id";
        if (in_array('start_date', $cols)) $select .= ", c.start_date";
        if (in_array('end_date', $cols)) $select .= ", c.end_date";
        if (in_array('contract_file', $cols)) $select .= ", c.contract_file";

        $select .= " FROM contracts c LEFT JOIN tenants t ON c.tenant_id = t.id";

        $stmt = $this->db->query($select);
        $contracts = $stmt->fetchAll(PDO::FETCH_ASSOC);

        foreach ($contracts as $c) {
            $empId = $c['tenant_user_id'] ?? null;
            $dept  = $c['department'] ?? 'General';

            // Critical: contract file missing
            if (isset($c['contract_file']) && empty($c['contract_file'])) {
                $this->upsert($empId, $dept, 'contracts', $c['id'], 'contract_file', 'Missing', 'critical',
                    'Contract file (#' . $c['id'] . ') is missing');
            }

            // Critical: start_date > end_date
            if (isset($c['start_date']) && isset($c['end_date'])) {
                if (!empty($c['start_date']) && !empty($c['end_date'])) {
                    if (strtotime($c['start_date']) > strtotime($c['end_date'])) {
                        $this->upsert($empId, $dept, 'contracts', $c['id'], 'end_date', 'Invalid', 'critical',
                            'Contract #' . $c['id'] . ' end date (' . $c['end_date'] . ') is before start date (' . $c['start_date'] . ')');
                    }

                    // Critical: contract already expired
                    if (strtotime($c['end_date']) < time()) {
                        $this->upsert($empId, $dept, 'contracts', $c['id'], 'end_date', 'Expired', 'critical',
                            'Contract #' . $c['id'] . ' expired on ' . $c['end_date']);
                    } elseif (strtotime($c['end_date']) < strtotime('+30 days')) {
                        $this->upsert($empId, $dept, 'contracts', $c['id'], 'end_date', 'Expired', 'info',
                            'Contract #' . $c['id'] . ' expires soon on ' . $c['end_date']);
                    }
                } else {
                    if (empty($c['start_date'])) {
                        $this->upsert($empId, $dept, 'contracts', $c['id'], 'start_date', 'Missing', 'critical',
                            'Contract #' . $c['id'] . ' has no start date');
                    }
                    if (empty($c['end_date'])) {
                        $this->upsert($empId, $dept, 'contracts', $c['id'], 'end_date', 'Missing', 'critical',
                            'Contract #' . $c['id'] . ' has no end date');
                    }
                }
            }

            // Critical: tenant not linked
            if (isset($c['tenant_id']) && empty($c['tenant_id'])) {
                $this->upsert($empId, $dept, 'contracts', $c['id'], 'tenant_id', 'Missing', 'critical',
                    'Contract #' . $c['id'] . ' has no tenant linked');
            }
        }
    }

    // ── Workshops ─────────────────────────────────────────────────────────────
    private function scanWorkshops(): void {
        // Check what columns exist first (flexible for various workshop table schemas)
        try {
            $stmt = $this->db->query("SHOW COLUMNS FROM workshops");
            $cols = array_column($stmt->fetchAll(PDO::FETCH_ASSOC), 'Field');
        } catch (Exception $e) {
            return; // workshops table doesn't exist
        }

        $select = "SELECT w.id, w.name";
        if (in_array('license_expiry', $cols))    $select .= ", w.license_expiry";
        if (in_array('vat_number', $cols))         $select .= ", w.vat_number";
        if (in_array('manager_id', $cols))         $select .= ", w.manager_id";
        if (in_array('emergency_contact', $cols))  $select .= ", w.emergency_contact";
        if (in_array('user_id', $cols))            $select .= ", w.user_id";
        $select .= " FROM workshops w";

        $stmt = $this->db->query($select);
        $workshops = $stmt->fetchAll(PDO::FETCH_ASSOC);

        foreach ($workshops as $w) {
            $empId = $w['user_id'] ?? null;
            $dept  = 'Workshop';

            // Critical: license expired
            if (isset($w['license_expiry']) && !empty($w['license_expiry'])) {
                if (strtotime($w['license_expiry']) < time()) {
                    $this->upsert($empId, $dept, 'workshops', $w['id'], 'license_expiry', 'Expired', 'critical',
                        'Workshop license expired on ' . $w['license_expiry'] . ' for: ' . $w['name']);
                }
            }

            // Critical: VAT number missing
            if (isset($w['vat_number']) && empty($w['vat_number'])) {
                $this->upsert($empId, $dept, 'workshops', $w['id'], 'vat_number', 'Missing', 'critical',
                    'VAT number is missing for workshop: ' . $w['name']);
            }

            // Warning: manager not assigned
            if (isset($w['manager_id']) && empty($w['manager_id'])) {
                $this->upsert($empId, $dept, 'workshops', $w['id'], 'manager_id', 'Missing', 'warning',
                    'Manager not assigned for workshop: ' . $w['name']);
            }

            // Warning: emergency contact missing
            if (isset($w['emergency_contact']) && empty($w['emergency_contact'])) {
                $this->upsert($empId, $dept, 'workshops', $w['id'], 'emergency_contact', 'Missing', 'warning',
                    'No emergency contact for workshop: ' . $w['name']);
            }
        }
    }

    // ── Upsert helper — prevents duplicate reports for same issue ─────────────
    private function upsert(
        ?int   $empId,
        string $dept,
        string $table,
        int    $recordId,
        string $field,
        string $problemType,
        string $severity,
        string $description
    ): void {
        // Check if an open/in-progress report already exists for this exact issue
        $check = $this->db->prepare("
            SELECT id, status FROM audit_reports
            WHERE table_name = ? AND record_id = ? AND field_name = ?
              AND status NOT IN ('resolved', 'rejected')
            LIMIT 1
        ");
        $check->execute([$table, $recordId, $field]);
        $existing = $check->fetch(PDO::FETCH_ASSOC);

        if (!$existing) {
            $ins = $this->db->prepare("
                INSERT INTO audit_reports
                    (employee_id, department, table_name, record_id, field_name, problem_type, severity, description, status, is_locked)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'open', 1)
            ");
            $ins->execute([$empId, $dept, $table, $recordId, $field, $problemType, $severity, $description]);

            $reportId = (int)$this->db->lastInsertId();

            // Log to audit trail
            $trail = $this->db->prepare("
                INSERT INTO audit_trail (audit_report_id, user_id, action, new_value)
                VALUES (?, 0, 'detected', ?)
            ");
            $trail->execute([$reportId, $description]);

            $this->foundCount++;
            match($severity) {
                'critical' => $this->criticalCount++,
                'warning'  => $this->warningCount++,
                default    => $this->infoCount++,
            };
        }
    }
}
