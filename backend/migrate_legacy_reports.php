<?php
require_once __DIR__ . '/core/Database.php';

$db = Database::getInstance()->getConnection();

try {
    echo "Starting Phase 4 Data Migration...\n";
    $db->beginTransaction();

    // Move data from generator_daily_reports to daily_logs
    $stmt = $db->query("SELECT * FROM generator_daily_reports");
    $reports = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $insertStmt = $db->prepare("
        INSERT INTO daily_logs (
            generator_id, date, submitted_hours, calculated_hours_worked, 
            expected_factory_fuel_burn, status_flag, admin_actual_fuel
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
    ");

    $count = 0;
    foreach ($reports as $r) {
        // Skip if already migrated (by checking date/generator_id)
        $checkStmt = $db->prepare("SELECT id FROM daily_logs WHERE generator_id = ? AND date = ?");
        $checkStmt->execute([$r['generator_id'], $r['date']]);
        if ($checkStmt->fetch()) continue;

        $insertStmt->execute([
            $r['generator_id'],
            $r['date'],
            $r['current_meter_hours'] ?? 0,
            $r['running_hours'] ?? 0,
            $r['expected_fuel_consumption'] ?? 0,
            'Verified', // Since it's legacy data, assume it's finalized
            $r['actual_fuel_used'] ?? 0
        ]);
        $count++;
    }

    echo "Migrated $count records from generator_daily_reports to daily_logs.\n";

    // Rename tables for safety
    $db->exec("RENAME TABLE generator_daily_reports TO generator_daily_reports_archived");
    
    try {
        $db->exec("RENAME TABLE generator_analysis TO generator_analysis_archived");
    } catch(PDOException $e) {}
    
    try {
        $db->exec("RENAME TABLE generator_predictions TO generator_predictions_archived");
    } catch(PDOException $e) {}

    $db->commit();
    echo "Migration completed successfully! Legacy tables have been archived.\n";

} catch (Exception $e) {
    $db->rollBack();
    echo "Error during migration: " . $e->getMessage() . "\n";
}
