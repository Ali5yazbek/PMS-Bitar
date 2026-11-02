<?php

class DataQualityEngine {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Reusable Validation Service
     * @param string $module
     * @param string $table_name
     * @param int $record_id
     * @param array $data The submitted/saved data (associative array)
     * @param int $user_id The user who submitted it
     */
    public function validateRecord($module, $table_name, $record_id, $data, $user_id) {
        $errors = [];
        
        // 1. Dynamic Validation Rules (from DB)
        $stmt = $this->db->prepare("SELECT * FROM validation_rules WHERE module = ?");
        $stmt->execute([$module]);
        $rules = $stmt->fetchAll(PDO::FETCH_ASSOC);

        foreach ($rules as $rule) {
            $field = $rule['field_name'];
            $value = isset($data[$field]) ? $data[$field] : null;

            // Missing Data
            if ($rule['is_required'] && (is_null($value) || $value === '')) {
                $errors[] = [
                    'field_name' => $field,
                    'problem_type' => 'Missing Data',
                    'severity' => 'critical',
                    'description' => "Required field '$field' is missing.",
                    'expected_value' => 'Required',
                    'actual_value' => 'Empty'
                ];
                continue;
            }
        }

        // 2. Hardcoded Business Rules depending on Module
        $businessErrors = $this->applyBusinessRules($module, $data);
        $errors = array_merge($errors, $businessErrors);

        // Calculate Completion %
        $totalFields = count($data);
        if ($totalFields === 0) $totalFields = 1;
        $missingCount = 0;
        foreach ($data as $k => $v) {
            if (is_null($v) || $v === '') {
                $missingCount++;
            }
        }
        
        // Get user details for audit
        $stmtUser = $this->db->prepare("SELECT role, (SELECT name FROM buildings LIMIT 1) as department FROM users WHERE id = ?");
        $stmtUser->execute([$user_id]);
        $user = $stmtUser->fetch(PDO::FETCH_ASSOC);
        $department = $user['department'] ?? 'General';

        // Check existing errors for this record
        $stmtExisting = $this->db->prepare("SELECT id, field_name, problem_type FROM audit_reports WHERE table_name = ? AND record_id = ? AND status != 'Resolved'");
        $stmtExisting->execute([$table_name, $record_id]);
        $existingErrors = $stmtExisting->fetchAll(PDO::FETCH_ASSOC);
        
        $existingMap = [];
        foreach ($existingErrors as $ee) {
            $existingMap[$ee['field_name'] . '-' . $ee['problem_type']] = $ee['id'];
        }

        $fullRecordJson = json_encode($data);

        // Process found errors
        foreach ($errors as $error) {
            $key = $error['field_name'] . '-' . $error['problem_type'];
            if (isset($existingMap[$key])) {
                // Already exists, maybe update full_record_json and expected/actual
                $stmtUpdate = $this->db->prepare("UPDATE audit_reports SET actual_value = ?, expected_value = ?, full_record_json = ?, updated_at = NOW() WHERE id = ?");
                $stmtUpdate->execute([$error['actual_value'], $error['expected_value'], $fullRecordJson, $existingMap[$key]]);
                unset($existingMap[$key]); // Mark as still relevant
            } else {
                // Create new
                $stmtInsert = $this->db->prepare("
                    INSERT INTO audit_reports 
                    (employee_id, department, module_name, table_name, record_id, field_name, problem_type, severity, description, status, actual_value, expected_value, full_record_json, assigned_to, created_at, updated_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'Open', ?, ?, ?, ?, NOW(), NOW())
                ");
                $stmtInsert->execute([
                    $user_id,
                    $department,
                    $module,
                    $table_name,
                    $record_id,
                    $error['field_name'],
                    $error['problem_type'],
                    $error['severity'],
                    $error['description'],
                    $error['actual_value'],
                    $error['expected_value'],
                    $fullRecordJson,
                    $user_id // Assign back to creator
                ]);
                
                $auditId = $this->db->lastInsertId();
                $this->logTrail($auditId, $user_id, 'Problem Found', null, 'Open', 'System detected an issue during save.');
            }
        }

        // Resolve existing errors that are no longer present
        foreach ($existingMap as $key => $auditId) {
            $stmtResolve = $this->db->prepare("UPDATE audit_reports SET status = 'Resolved', updated_at = NOW() WHERE id = ?");
            $stmtResolve->execute([$auditId]);
            $this->logTrail($auditId, $user_id, 'Auto Resolved', 'Open', 'Resolved', 'System detected issue is fixed upon resave.');
        }

        return [
            'success' => true,
            'errors_found' => count($errors)
        ];
    }

    private function applyBusinessRules($module, $data) {
        $errors = [];

        if ($module === 'Contracts') {
            if (!empty($data['start_date']) && !empty($data['end_date'])) {
                if (strtotime($data['end_date']) <= strtotime($data['start_date'])) {
                    $errors[] = [
                        'field_name'    => 'end_date',
                        'problem_type'  => 'Business Rule Error',
                        'severity'      => 'critical',
                        'description'   => 'Contract end date must be after start date.',
                        'expected_value'=> 'After ' . $data['start_date'],
                        'actual_value'  => $data['end_date']
                    ];
                }
            }
            if (isset($data['monthly_rent']) && floatval($data['monthly_rent']) < 0) {
                $errors[] = [
                    'field_name'    => 'monthly_rent',
                    'problem_type'  => 'Financial Error',
                    'severity'      => 'critical',
                    'description'   => 'Rent amount cannot be less than zero.',
                    'expected_value'=> '>= 0',
                    'actual_value'  => $data['monthly_rent']
                ];
            }
        }

        if ($module === 'Apartments') {
            if (isset($data['status']) && $data['status'] === 'Rented' && empty($data['tenant_id'])) {
                $errors[] = [
                    'field_name'    => 'tenant_id',
                    'problem_type'  => 'Relationship Error',
                    'severity'      => 'critical',
                    'description'   => 'Apartment is marked occupied but no tenant is assigned.',
                    'expected_value'=> 'Valid Tenant ID',
                    'actual_value'  => 'Empty'
                ];
            }
        }

        if ($module === 'Generator') {
            if (isset($data['current_reading']) && isset($data['previous_reading'])) {
                if (floatval($data['current_reading']) < floatval($data['previous_reading'])) {
                    $errors[] = [
                        'field_name'    => 'current_reading',
                        'problem_type'  => 'Calculation Error',
                        'severity'      => 'critical',
                        'description'   => 'Current reading is lower than previous reading.',
                        'expected_value'=> '>= ' . $data['previous_reading'],
                        'actual_value'  => $data['current_reading']
                    ];
                }
            }
        }

        if ($module === 'Workshop') {
            if (isset($data['status']) && $data['status'] === 'Completed' && empty($data['technician_id'])) {
                $errors[] = [
                    'field_name'    => 'technician_id',
                    'problem_type'  => 'Business Rule Error',
                    'severity'      => 'critical',
                    'description'   => 'Workshop marked completed but no technician assigned.',
                    'expected_value'=> 'Technician ID',
                    'actual_value'  => 'Empty'
                ];
            }
        }

        // ─── Agent Generator Report Rules ─────────────────────────────────────
        if ($module === 'AgentGenerator') {
            // Missing meter photo
            if (empty($data['photo_meter_path'])) {
                $errors[] = [
                    'field_name'    => 'photo_meter_path',
                    'problem_type'  => 'Missing Photo',
                    'severity'      => 'high',
                    'description'   => 'Generator meter photo is missing from this daily report.',
                    'expected_value'=> 'Photo file path',
                    'actual_value'  => 'Empty'
                ];
            }
            // Missing fuel photo
            if (empty($data['fuel_photo_path'])) {
                $errors[] = [
                    'field_name'    => 'fuel_photo_path',
                    'problem_type'  => 'Missing Photo',
                    'severity'      => 'high',
                    'description'   => 'Generator fuel photo is missing from this daily report.',
                    'expected_value'=> 'Photo file path',
                    'actual_value'  => 'Empty'
                ];
            }
            // Missing generator reference
            if (empty($data['generator_id'])) {
                $errors[] = [
                    'field_name'    => 'generator_id',
                    'problem_type'  => 'Missing Reference',
                    'severity'      => 'critical',
                    'description'   => 'Generator daily report is not linked to any generator.',
                    'expected_value'=> 'Valid Generator ID',
                    'actual_value'  => 'Empty'
                ];
            }
            // Missing fuel level
            if (!isset($data['fuel_level']) || $data['fuel_level'] === null || $data['fuel_level'] === '') {
                $errors[] = [
                    'field_name'    => 'fuel_level',
                    'problem_type'  => 'Missing Data',
                    'severity'      => 'medium',
                    'description'   => 'Fuel level was not recorded in this generator report.',
                    'expected_value'=> 'Fuel level value',
                    'actual_value'  => 'Empty'
                ];
            }
            // Reading regression
            if (isset($data['current_meter_hours']) && isset($data['previous_meter_hours'])) {
                if (floatval($data['current_meter_hours']) < floatval($data['previous_meter_hours'])) {
                    $errors[] = [
                        'field_name'    => 'current_meter_hours',
                        'problem_type'  => 'Calculation Error',
                        'severity'      => 'critical',
                        'description'   => 'Generator meter hours decreased (current < previous). Possible data entry error.',
                        'expected_value'=> '>= ' . $data['previous_meter_hours'],
                        'actual_value'  => $data['current_meter_hours']
                    ];
                }
            }
        }

        // ─── Agent Apartment / Meter Reading Rules ─────────────────────────────
        if ($module === 'AgentApartmentReading') {
            // Missing photo for metered readings
            if (empty($data['photo_path']) && floatval($data['current_reading'] ?? 0) > 0) {
                $errors[] = [
                    'field_name'    => 'photo_path',
                    'problem_type'  => 'Missing Photo',
                    'severity'      => 'high',
                    'description'   => 'Electricity meter photo is missing from this reading.',
                    'expected_value'=> 'Photo file path',
                    'actual_value'  => 'Empty'
                ];
            }
            // Missing apartment reference
            if (empty($data['apartment_id'])) {
                $errors[] = [
                    'field_name'    => 'apartment_id',
                    'problem_type'  => 'Missing Reference',
                    'severity'      => 'critical',
                    'description'   => 'Meter reading is not linked to any apartment.',
                    'expected_value'=> 'Valid Apartment ID',
                    'actual_value'  => 'Empty'
                ];
            }
            // Current reading lower than previous (for metered)
            if (isset($data['current_reading']) && isset($data['previous_reading'])) {
                if (floatval($data['current_reading']) > 0 && floatval($data['previous_reading']) > 0
                    && floatval($data['current_reading']) < floatval($data['previous_reading'])) {
                    $errors[] = [
                        'field_name'    => 'current_reading',
                        'problem_type'  => 'Calculation Error',
                        'severity'      => 'critical',
                        'description'   => 'Current meter reading is lower than previous reading. Possible entry error.',
                        'expected_value'=> '>= ' . $data['previous_reading'],
                        'actual_value'  => $data['current_reading']
                    ];
                }
            }
        }

        return $errors;
    }

    public function logTrail($audit_id, $user_id, $action, $old_value, $new_value, $comment) {
        $stmt = $this->db->prepare("
            INSERT INTO audit_trail (audit_report_id, user_id, action, old_value, new_value, comment, created_at)
            VALUES (?, ?, ?, ?, ?, ?, NOW())
        ");
        $stmt->execute([$audit_id, $user_id, $action, $old_value, $new_value, $comment]);
    }

    public function runScheduledScan() {
        $scanned = 0;
        $errorsFound = 0;

        // ─── 1. Orphaned active tenants (no active contract) ──────────────────
        $stmt = $this->db->query("
            SELECT * FROM tenants
            WHERE status = 'Active'
              AND id NOT IN (SELECT tenant_id FROM contracts WHERE status = 'Active')
        ");
        foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $t) {
            $r = $this->validateRecord('Tenant', 'tenants', $t['id'], $t, 1);
            $errorsFound += $r['errors_found'];
            $scanned++;
        }

        // ─── 2. Agent generator daily reports (last 30 days) ──────────────────
        // Check for missing photos, missing generator link, fuel level, reading regression
        $stmt = $this->db->prepare("
            SELECT gdr.*, u.id as agent_user_id
            FROM generator_daily_reports gdr
            JOIN generators g ON gdr.generator_id = g.id
            JOIN users u ON gdr.submitted_by = u.id
            WHERE gdr.submitted_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
              AND u.role = 'agent'
        ");
        $stmt->execute();
        foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $report) {
            $agentId = $report['agent_user_id'] ?? $report['submitted_by'];
            // Fetch the previous reading for comparison
            $prevStmt = $this->db->prepare("
                SELECT current_meter_hours FROM generator_daily_reports
                WHERE generator_id = ? AND submitted_at < ?
                ORDER BY submitted_at DESC LIMIT 1
            ");
            $prevStmt->execute([$report['generator_id'], $report['submitted_at']]);
            $prev = $prevStmt->fetchColumn();
            $reportData = [
                'generator_id'         => $report['generator_id'],
                'photo_meter_path'     => $report['photo_meter_path'] ?? $report['meter_photo_path'] ?? null,
                'fuel_photo_path'      => $report['fuel_photo_path'] ?? null,
                'fuel_level'           => $report['fuel_level'] ?? null,
                'current_meter_hours'  => $report['current_meter_hours'] ?? null,
                'previous_meter_hours' => $prev ?: null,
                'date'                 => $report['date'] ?? $report['submitted_at'],
                'notes'                => $report['notes'] ?? null,
                'submitted_by'         => $report['submitted_by'],
            ];
            $r = $this->validateRecord('AgentGenerator', 'generator_daily_reports', $report['id'], $reportData, $agentId);
            $errorsFound += $r['errors_found'];
            $scanned++;
        }

        // ─── 3. Agent apartment / electricity meter readings (last 30 days) ───
        $stmt = $this->db->prepare("
            SELECT emr.*, u.id as agent_user_id
            FROM electricity_meter_readings emr
            JOIN users u ON emr.submitted_by = u.id
            WHERE emr.submitted_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
              AND u.role = 'agent'
        ");
        $stmt->execute();
        foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $reading) {
            $agentId = $reading['agent_user_id'] ?? $reading['submitted_by'];
            $readingData = [
                'apartment_id'     => $reading['apartment_id'],
                'photo_path'       => $reading['photo_path'],
                'current_reading'  => $reading['current_reading'],
                'previous_reading' => $reading['previous_reading'],
                'consumption'      => $reading['consumption'],
                'price_per_kwh'    => $reading['price_per_kwh'],
                'reading_date'     => $reading['reading_date'],
                'notes'            => $reading['notes'],
                'submitted_by'     => $reading['submitted_by'],
                'status'           => $reading['status'],
            ];
            $r = $this->validateRecord('AgentApartmentReading', 'electricity_meter_readings', $reading['id'], $readingData, $agentId);
            $errorsFound += $r['errors_found'];
            $scanned++;
        }

        return [
            'scanned'      => $scanned,
            'errors_found' => $errorsFound
        ];
    }
}

