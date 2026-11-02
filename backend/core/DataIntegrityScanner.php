<?php
/**
 * DataIntegrityScanner — detects duplicates, financial violations,
 * orphaned records, and broken relationships.
 */
class DataIntegrityScanner {
    private $db;
    private array $found = [];

    public function __construct(PDO $db) { $this->db = $db; }

    // ── Run all checks ────────────────────────────────────────────────────────
    public function run(): array {
        // Clear old open issues before re-scanning
        $this->db->exec("DELETE FROM integrity_issues WHERE status = 'open'");
        $this->db->exec("DELETE FROM financial_audit_issues WHERE status = 'open'");

        $this->detectDuplicateNationalIds();
        $this->detectDuplicatePhones();
        $this->detectDuplicatePassports();
        $this->detectDuplicateContracts();
        $this->detectOrphanedContracts();
        $this->detectFinancialIssues();

        return [
            'total'    => count($this->found),
            'critical' => count(array_filter($this->found, fn($f) => $f['severity'] === 'critical')),
            'warning'  => count(array_filter($this->found, fn($f) => $f['severity'] === 'warning')),
        ];
    }

    // ── Duplicate National IDs ─────────────────────────────────────────────────
    private function detectDuplicateNationalIds(): void {
        $stmt = $this->db->query("
            SELECT national_id, COUNT(*) as cnt
            FROM tenants
            WHERE national_id IS NOT NULL AND national_id != '' AND national_id != 'N/A'
            GROUP BY national_id HAVING cnt > 1
        ");
        foreach ($stmt->fetchAll() as $dup) {
            $ids = $this->db->prepare("SELECT id, full_name FROM tenants WHERE national_id = ?");
            $ids->execute([$dup['national_id']]);
            $records = $ids->fetchAll();
            $this->insertIntegrity('duplicate_national_id', 'critical', 'tenants',
                $records[0]['id'], $records[1]['id'] ?? null,
                "Duplicate National ID '{$dup['national_id']}' found on {$dup['cnt']} tenants: " . implode(', ', array_column($records, 'full_name')));
        }
    }

    // ── Duplicate Phones ──────────────────────────────────────────────────────
    private function detectDuplicatePhones(): void {
        $stmt = $this->db->query("
            SELECT phone, COUNT(*) as cnt
            FROM tenants
            WHERE phone IS NOT NULL AND phone != '' AND phone != 'N/A'
            GROUP BY phone HAVING cnt > 1
        ");
        foreach ($stmt->fetchAll() as $dup) {
            $ids = $this->db->prepare("SELECT id, full_name FROM tenants WHERE phone = ?");
            $ids->execute([$dup['phone']]);
            $records = $ids->fetchAll();
            $this->insertIntegrity('duplicate_phone', 'warning', 'tenants',
                $records[0]['id'], $records[1]['id'] ?? null,
                "Duplicate phone '{$dup['phone']}' found on {$dup['cnt']} tenants: " . implode(', ', array_column($records, 'full_name')));
        }
    }

    // ── Duplicate Passports ───────────────────────────────────────────────────
    private function detectDuplicatePassports(): void {
        try {
            $stmt = $this->db->query("
                SELECT passport_number, COUNT(*) as cnt
                FROM tenants
                WHERE passport_number IS NOT NULL AND passport_number != ''
                GROUP BY passport_number HAVING cnt > 1
            ");
            foreach ($stmt->fetchAll() as $dup) {
                $ids = $this->db->prepare("SELECT id, full_name FROM tenants WHERE passport_number = ?");
                $ids->execute([$dup['passport_number']]);
                $records = $ids->fetchAll();
                $this->insertIntegrity('duplicate_passport', 'critical', 'tenants',
                    $records[0]['id'], $records[1]['id'] ?? null,
                    "Duplicate Passport '{$dup['passport_number']}' on {$dup['cnt']} tenants: " . implode(', ', array_column($records, 'full_name')));
            }
        } catch (Exception $e) { /* passport_number column may not exist */ }
    }

    // ── Duplicate Active Contracts for same apartment ─────────────────────────
    private function detectDuplicateContracts(): void {
        $stmt = $this->db->query("
            SELECT apartment_id, COUNT(*) as cnt
            FROM contracts
            WHERE status IN ('Active','Approved')
            GROUP BY apartment_id HAVING cnt > 1
        ");
        foreach ($stmt->fetchAll() as $dup) {
            $contracts = $this->db->prepare("SELECT id FROM contracts WHERE apartment_id = ? AND status IN ('Active','Approved')");
            $contracts->execute([$dup['apartment_id']]);
            $rows = $contracts->fetchAll();
            $this->insertIntegrity('duplicate_active_contract', 'critical', 'contracts',
                $rows[0]['id'], $rows[1]['id'] ?? null,
                "Apartment #{$dup['apartment_id']} has {$dup['cnt']} active contracts simultaneously");
        }
    }

    // ── Orphaned Contracts (no valid tenant) ──────────────────────────────────
    private function detectOrphanedContracts(): void {
        $stmt = $this->db->query("
            SELECT c.id FROM contracts c
            LEFT JOIN tenants t ON c.tenant_id = t.id
            WHERE c.tenant_id IS NOT NULL AND t.id IS NULL
              AND c.status IN ('Active','Approved')
        ");
        foreach ($stmt->fetchAll() as $row) {
            $this->insertIntegrity('orphaned_contract', 'critical', 'contracts',
                $row['id'], null, "Contract #{$row['id']} references a tenant that no longer exists");
        }
    }

    // ── Financial Violations ──────────────────────────────────────────────────
    private function detectFinancialIssues(): void {
        // Negative rent amounts
        try {
            $stmt = $this->db->query("SELECT id, amount FROM rent_invoices WHERE amount < 0");
            foreach ($stmt->fetchAll() as $r) {
                $this->insertFinancial('rent_invoices', $r['id'], 'negative_amount',
                    'critical', 0, $r['amount'], "Negative rent amount on invoice #{$r['id']}: {$r['amount']}");
            }
        } catch (Exception $e) {}

        // Paid > Invoice total
        try {
            $stmt = $this->db->query("SELECT id, amount, paid_amount FROM rent_invoices WHERE paid_amount > amount AND amount > 0");
            foreach ($stmt->fetchAll() as $r) {
                $this->insertFinancial('rent_invoices', $r['id'], 'overpayment',
                    'warning', $r['amount'], $r['paid_amount'], "Paid ({$r['paid_amount']}) exceeds invoice ({$r['amount']}) on #{$r['id']}");
            }
        } catch (Exception $e) {}

        // Apartments with no rent profile but active contract
        try {
            $stmt = $this->db->query("
                SELECT c.id, c.apartment_id FROM contracts c
                LEFT JOIN rent_profiles rp ON c.id = rp.contract_id
                WHERE c.status IN ('Active','Approved') AND rp.id IS NULL
            ");
            foreach ($stmt->fetchAll() as $r) {
                $this->insertFinancial('contracts', $r['id'], 'missing_rent_profile',
                    'warning', null, null, "Active contract #{$r['id']} has no rent profile attached");
            }
        } catch (Exception $e) {}
    }

    // ── Helpers ───────────────────────────────────────────────────────────────
    private function insertIntegrity(string $type, string $severity, string $table,
                                     int $recordId, ?int $dupId, string $desc): void {
        $stmt = $this->db->prepare("
            INSERT INTO integrity_issues (issue_type, severity, table_name, record_id, duplicate_id, description)
            VALUES (?, ?, ?, ?, ?, ?)
        ");
        $stmt->execute([$type, $severity, $table, $recordId, $dupId, $desc]);
        $this->found[] = ['severity' => $severity];
    }

    private function insertFinancial(string $table, int $recordId, string $type,
                                      string $severity, ?float $expected, ?float $actual, string $desc): void {
        $stmt = $this->db->prepare("
            INSERT INTO financial_audit_issues (table_name, record_id, issue_type, severity, expected_value, actual_value, description)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ");
        $stmt->execute([$table, $recordId, $type, $severity, $expected, $actual, $desc]);
        $this->found[] = ['severity' => $severity];
    }
}
