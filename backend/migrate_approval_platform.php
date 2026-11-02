<?php
/**
 * migrate_approval_platform.php
 * Enterprise Approval & Verification Platform — Database Migration
 * Run once via browser: http://localhost/Bitar/backend/migrate_approval_platform.php
 */

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/core/Database.php';

$db = Database::getInstance()->getConnection();
$results = [];

function run($db, string $label, string $sql): void {
    global $results;
    try {
        $db->exec($sql);
        $results[] = "✅ $label";
    } catch (PDOException $e) {
        // Ignore "already exists" errors gracefully
        if (strpos($e->getMessage(), 'Duplicate column') !== false ||
            strpos($e->getMessage(), 'already exists') !== false) {
            $results[] = "⏭ $label (already exists — skipped)";
        } else {
            $results[] = "❌ $label — " . $e->getMessage();
        }
    }
}

// ─── 1. approval_settings ────────────────────────────────────────────────────
run($db, 'CREATE TABLE approval_settings', "
CREATE TABLE IF NOT EXISTS approval_settings (
    id INT PRIMARY KEY AUTO_INCREMENT,
    setting_key VARCHAR(100) NOT NULL UNIQUE,
    setting_value VARCHAR(255) NOT NULL DEFAULT '',
    label VARCHAR(255) NOT NULL DEFAULT '',
    description TEXT,
    data_type ENUM('integer','decimal','boolean','string') DEFAULT 'integer',
    module VARCHAR(100) DEFAULT 'global',
    updated_by INT DEFAULT NULL,
    updated_at DATETIME DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
");

// ─── 2. activity_log ─────────────────────────────────────────────────────────
run($db, 'CREATE TABLE activity_log', "
CREATE TABLE IF NOT EXISTS activity_log (
    id INT PRIMARY KEY AUTO_INCREMENT,
    module VARCHAR(100) NOT NULL DEFAULT '',
    record_type VARCHAR(100) NOT NULL DEFAULT '',
    record_id INT DEFAULT NULL,
    action VARCHAR(100) NOT NULL DEFAULT '',
    old_value TEXT DEFAULT NULL,
    new_value TEXT DEFAULT NULL,
    user_id INT DEFAULT NULL,
    user_name VARCHAR(255) DEFAULT NULL,
    user_role VARCHAR(100) DEFAULT NULL,
    ip_address VARCHAR(50) DEFAULT NULL,
    device VARCHAR(500) DEFAULT NULL,
    browser VARCHAR(500) DEFAULT NULL,
    reason TEXT DEFAULT NULL,
    severity ENUM('info','warning','critical') DEFAULT 'info',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_record (record_type, record_id),
    INDEX idx_module (module),
    INDEX idx_action (action),
    INDEX idx_user (user_id),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
");

// ─── 3. reading_versions ─────────────────────────────────────────────────────
run($db, 'CREATE TABLE reading_versions', "
CREATE TABLE IF NOT EXISTS reading_versions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    reading_id INT NOT NULL,
    reading_type ENUM('electricity','subscription','generator') NOT NULL,
    version_number INT DEFAULT 1,
    previous_reading DECIMAL(12,2) DEFAULT NULL,
    current_reading DECIMAL(12,2) DEFAULT NULL,
    consumption DECIMAL(12,2) DEFAULT NULL,
    reading_date DATE DEFAULT NULL,
    notes TEXT DEFAULT NULL,
    photo_path VARCHAR(500) DEFAULT NULL,
    edited_by INT DEFAULT NULL,
    edit_reason TEXT DEFAULT NULL,
    snapshot JSON DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_reading (reading_type, reading_id),
    INDEX idx_editor (edited_by)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
");

// ─── 4. building_health_scores ───────────────────────────────────────────────
run($db, 'CREATE TABLE building_health_scores', "
CREATE TABLE IF NOT EXISTS building_health_scores (
    id INT PRIMARY KEY AUTO_INCREMENT,
    building_id INT NOT NULL UNIQUE,
    score DECIMAL(5,2) DEFAULT 100.00,
    grade ENUM('Excellent','Good','Fair','Poor','Critical') DEFAULT 'Excellent',
    missing_readings_score DECIMAL(5,2) DEFAULT 30.00,
    rejection_rate_score DECIMAL(5,2) DEFAULT 25.00,
    anomaly_score DECIMAL(5,2) DEFAULT 20.00,
    late_submission_score DECIMAL(5,2) DEFAULT 15.00,
    pending_requests_score DECIMAL(5,2) DEFAULT 10.00,
    total_apartments INT DEFAULT 0,
    pending_count INT DEFAULT 0,
    rejected_count INT DEFAULT 0,
    details JSON DEFAULT NULL,
    calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (building_id) REFERENCES buildings(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
");

// ─── 5. agent_performance ────────────────────────────────────────────────────
run($db, 'CREATE TABLE agent_performance', "
CREATE TABLE IF NOT EXISTS agent_performance (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    month INT NOT NULL,
    year INT NOT NULL,
    total_submissions INT DEFAULT 0,
    approved_count INT DEFAULT 0,
    rejected_count INT DEFAULT 0,
    correction_count INT DEFAULT 0,
    late_submissions INT DEFAULT 0,
    avg_consumption_diff DECIMAL(10,2) DEFAULT 0.00,
    accuracy_score DECIMAL(5,2) DEFAULT 100.00,
    approval_rate DECIMAL(5,2) DEFAULT 100.00,
    rejection_rate DECIMAL(5,2) DEFAULT 0.00,
    avg_submission_hour DECIMAL(5,2) DEFAULT NULL,
    rank_in_period INT DEFAULT NULL,
    calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_agent_month (user_id, month, year),
    INDEX idx_user (user_id),
    INDEX idx_period (year, month)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
");

// ─── 6. financial_transactions ───────────────────────────────────────────────
run($db, 'CREATE TABLE financial_transactions', "
CREATE TABLE IF NOT EXISTS financial_transactions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    transaction_type ENUM('electricity_invoice','subscription_invoice','generator_invoice','fuel_purchase','manual') NOT NULL,
    module VARCHAR(100) DEFAULT NULL,
    apartment_id INT DEFAULT NULL,
    building_id INT DEFAULT NULL,
    source_reading_id INT DEFAULT NULL,
    source_reading_type VARCHAR(100) DEFAULT NULL,
    approval_log_id INT DEFAULT NULL,
    amount DECIMAL(10,2) DEFAULT 0.00,
    invoice_id INT DEFAULT NULL,
    created_by INT DEFAULT NULL,
    notes TEXT DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_apartment (apartment_id),
    INDEX idx_building (building_id),
    INDEX idx_type (transaction_type),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
");

// ─── ALTER: electricity_meter_readings ───────────────────────────────────────
$emrColumns = [
    "ADD COLUMN IF NOT EXISTS status_lifecycle ENUM('draft','submitted','pending_review','needs_correction','approved','rejected','cancelled','archived') DEFAULT 'submitted'",
    "ADD COLUMN IF NOT EXISTS anomaly_flags JSON DEFAULT NULL",
    "ADD COLUMN IF NOT EXISTS confidence_score TINYINT UNSIGNED DEFAULT 100",
    "ADD COLUMN IF NOT EXISTS risk_level ENUM('low','medium','high','critical') DEFAULT 'low'",
    "ADD COLUMN IF NOT EXISTS rejection_reason TEXT DEFAULT NULL",
    "ADD COLUMN IF NOT EXISTS rejection_reason_code VARCHAR(100) DEFAULT NULL",
    "ADD COLUMN IF NOT EXISTS rejection_severity ENUM('minor','medium','major','critical') DEFAULT NULL",
    "ADD COLUMN IF NOT EXISTS corrected_reading DECIMAL(12,2) DEFAULT NULL",
    "ADD COLUMN IF NOT EXISTS corrected_by INT DEFAULT NULL",
    "ADD COLUMN IF NOT EXISTS corrected_at DATETIME DEFAULT NULL",
    "ADD COLUMN IF NOT EXISTS version_number INT DEFAULT 1",
    "ADD COLUMN IF NOT EXISTS priority TINYINT DEFAULT 2",
    "ADD COLUMN IF NOT EXISTS reviewed_at DATETIME DEFAULT NULL",
    "ADD COLUMN IF NOT EXISTS approved_by INT DEFAULT NULL",
    "ADD COLUMN IF NOT EXISTS submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP",
    "ADD COLUMN IF NOT EXISTS billing_month INT DEFAULT NULL",
    "ADD COLUMN IF NOT EXISTS billing_year INT DEFAULT NULL",
];
foreach ($emrColumns as $col) {
    run($db, "ALTER electricity_meter_readings: " . substr($col, 20, 40) . '...', "ALTER TABLE electricity_meter_readings $col");
}

// ─── ALTER: agent_subscription_readings ──────────────────────────────────────
$asrColumns = [
    "ADD COLUMN IF NOT EXISTS status_lifecycle ENUM('draft','submitted','pending_review','needs_correction','approved','rejected','cancelled','archived') DEFAULT 'submitted'",
    "ADD COLUMN IF NOT EXISTS anomaly_flags JSON DEFAULT NULL",
    "ADD COLUMN IF NOT EXISTS confidence_score TINYINT UNSIGNED DEFAULT 100",
    "ADD COLUMN IF NOT EXISTS risk_level ENUM('low','medium','high','critical') DEFAULT 'low'",
    "ADD COLUMN IF NOT EXISTS rejection_reason_code VARCHAR(100) DEFAULT NULL",
    "ADD COLUMN IF NOT EXISTS rejection_severity ENUM('minor','medium','major','critical') DEFAULT NULL",
    "ADD COLUMN IF NOT EXISTS corrected_reading DECIMAL(12,2) DEFAULT NULL",
    "ADD COLUMN IF NOT EXISTS corrected_by INT DEFAULT NULL",
    "ADD COLUMN IF NOT EXISTS corrected_at DATETIME DEFAULT NULL",
    "ADD COLUMN IF NOT EXISTS version_number INT DEFAULT 1",
    "ADD COLUMN IF NOT EXISTS priority TINYINT DEFAULT 2",
];
foreach ($asrColumns as $col) {
    run($db, "ALTER agent_subscription_readings: " . substr($col, 20, 40) . '...', "ALTER TABLE agent_subscription_readings $col");
}

// ─── ALTER: generator_daily_reports ──────────────────────────────────────────
$gdrColumns = [
    "ADD COLUMN IF NOT EXISTS anomaly_flags JSON DEFAULT NULL",
    "ADD COLUMN IF NOT EXISTS confidence_score TINYINT UNSIGNED DEFAULT 100",
    "ADD COLUMN IF NOT EXISTS risk_level ENUM('low','medium','high','critical') DEFAULT 'low'",
    "ADD COLUMN IF NOT EXISTS rejection_reason TEXT DEFAULT NULL",
    "ADD COLUMN IF NOT EXISTS rejection_reason_code VARCHAR(100) DEFAULT NULL",
    "ADD COLUMN IF NOT EXISTS rejection_severity ENUM('minor','medium','major','critical') DEFAULT NULL",
    "ADD COLUMN IF NOT EXISTS reviewed_at DATETIME DEFAULT NULL",
    "ADD COLUMN IF NOT EXISTS reviewed_by INT DEFAULT NULL",
    "ADD COLUMN IF NOT EXISTS version_number INT DEFAULT 1",
    "ADD COLUMN IF NOT EXISTS priority TINYINT DEFAULT 2",
];
foreach ($gdrColumns as $col) {
    run($db, "ALTER generator_daily_reports: " . substr($col, 20, 40) . '...', "ALTER TABLE generator_daily_reports $col");
}

// ─── SEED: approval_settings ─────────────────────────────────────────────────
$settings = [
    ['high_consumption_percent',      '200',  'High Consumption Threshold (%)',      'If consumption is more than X% above the apartment average, flag as high consumption.',         'integer',  'readings'],
    ['low_consumption_percent',       '30',   'Low Consumption Threshold (%)',       'If consumption is more than X% below the apartment average, flag as low consumption.',          'integer',  'readings'],
    ['duplicate_reading_days',        '2',    'Duplicate Detection Window (days)',   'Flag if the same reading value is submitted within this many days.',                            'integer',  'readings'],
    ['critical_confidence_score',     '40',   'Critical Risk Score Threshold',       'Readings at or below this confidence score are flagged as Critical risk.',                      'integer',  'readings'],
    ['medium_confidence_score',       '70',   'Medium Risk Score Threshold',         'Readings between critical and this value are High risk. Above this is Medium/Low.',             'integer',  'readings'],
    ['require_image',                 'true', 'Require Meter Photo',                 'If true, reject any submission that does not include a meter photo.',                           'boolean',  'readings'],
    ['max_daily_consumption_kwh',     '1000', 'Max Plausible Daily Consumption (kWh)', 'Any consumption above this value per day is flagged as a spike.',                            'integer',  'readings'],
    ['auto_lock_after_submit',        'true', 'Lock Reading After Submission',       'If true, agents cannot edit a reading after it is submitted.',                                  'boolean',  'readings'],
    ['possible_digit_error_pct',      '40',   'Possible Wrong Digit Threshold (%)', 'If the reading differs from expected by more than X%, suggest possible typing error.',          'integer',  'readings'],
    ['long_without_reading_days',     '45',   'Long Without Reading Alert (days)',   'Alert if no reading has been submitted for this apartment in X days.',                          'integer',  'readings'],
    ['bulk_approve_max_risk',         'low',  'Bulk Approve Max Risk Level',         'The maximum risk level that can be approved in bulk without warning.',                          'string',   'readings'],
    ['auto_analyze_on_submit',        'true', 'Auto-Analyze on Submission',          'Automatically run anomaly detection when an agent submits a reading.',                          'boolean',  'readings'],
    ['health_score_excellent_min',    '90',   'Building Health: Excellent Minimum',  'Buildings with a health score >= this are graded Excellent.',                                   'integer',  'buildings'],
    ['health_score_good_min',         '75',   'Building Health: Good Minimum',       'Buildings with a health score >= this are graded Good.',                                        'integer',  'buildings'],
    ['health_score_fair_min',         '55',   'Building Health: Fair Minimum',       'Buildings with a health score >= this are graded Fair.',                                        'integer',  'buildings'],
    ['health_score_poor_min',         '35',   'Building Health: Poor Minimum',       'Buildings with a health score >= this are graded Poor. Below this is Critical.',               'integer',  'buildings'],
];

$settingStmt = $db->prepare("
    INSERT IGNORE INTO approval_settings (setting_key, setting_value, label, description, data_type, module)
    VALUES (?, ?, ?, ?, ?, ?)
");
foreach ($settings as $s) {
    try {
        $settingStmt->execute($s);
        $results[] = "🌱 Seeded setting: {$s[0]}";
    } catch (PDOException $e) {
        $results[] = "⏭ Setting already exists: {$s[0]}";
    }
}

// ─── Initialize building health scores ───────────────────────────────────────
run($db, 'Initialize building health scores', "
    INSERT IGNORE INTO building_health_scores (building_id, score, grade)
    SELECT id, 100.00, 'Excellent' FROM buildings
");

// Output
header('Content-Type: text/html; charset=utf-8');
echo "<html><head><title>Migration</title><style>
body { font-family: monospace; background: #0f172a; color: #e2e8f0; padding: 2rem; }
h1 { color: #6366f1; }
.ok { color: #22c55e; }
.skip { color: #94a3b8; }
.err { color: #ef4444; }
</style></head><body>";
echo "<h1>🚀 Enterprise Approval Platform — Migration</h1><pre>";
foreach ($results as $r) {
    $class = str_starts_with($r, '✅') ? 'ok' : (str_starts_with($r, '❌') ? 'err' : 'skip');
    echo "<span class='$class'>" . htmlspecialchars($r) . "</span>\n";
}
$errors = array_filter($results, fn($r) => str_starts_with($r, '❌'));
echo "\n";
if (empty($errors)) {
    echo "<span class='ok'>✅ Migration completed successfully. " . count($results) . " operations total.</span>\n";
    echo "<span class='ok'>✅ You can now use the Enterprise Approval Engine.</span>\n";
} else {
    echo "<span class='err'>⚠ Migration completed with " . count($errors) . " error(s). Review above.</span>\n";
}
echo "</pre></body></html>";
