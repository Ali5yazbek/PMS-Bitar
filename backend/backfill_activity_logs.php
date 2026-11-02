<?php
require_once 'core/Database.php';

$db = Database::getInstance()->getConnection();

try {
    $db->beginTransaction();

    // 1. Backfill Generator Logs
    $genStmt = $db->query("
        SELECT id, generator_id, submitted_by, fuel_added, created_at, submitted_at
        FROM generator_daily_reports
        WHERE submitted_by IS NOT NULL
    ");
    $genReports = $genStmt->fetchAll(PDO::FETCH_ASSOC);

    $insertStmt = $db->prepare("
        INSERT INTO activity_logs (user_id, action, entity_type, entity_id, details, created_at)
        SELECT ?, 'Generator Log', 'Generator', ?, ?, ?
        WHERE NOT EXISTS (
            SELECT 1 FROM activity_logs 
            WHERE user_id = ? AND action = 'Generator Log' AND entity_id = ? AND DATE(created_at) = DATE(?)
        )
    ");

    $genCount = 0;
    foreach ($genReports as $rep) {
        $date = $rep['submitted_at'] ?: $rep['created_at'];
        $details = "Submitted daily report (Fuel Added: {$rep['fuel_added']}L)";
        $insertStmt->execute([
            $rep['submitted_by'], $rep['generator_id'], $details, $date,
            $rep['submitted_by'], $rep['generator_id'], $date
        ]);
        if ($insertStmt->rowCount() > 0) $genCount++;
    }

    // 2. Backfill Subscription Meter Readings
    $subStmt = $db->query("
        SELECT id, apartment_id, submitted_by, consumption, created_at
        FROM agent_subscription_readings
        WHERE submitted_by IS NOT NULL
    ");
    $subReports = $subStmt->fetchAll(PDO::FETCH_ASSOC);

    $insertSubStmt = $db->prepare("
        INSERT INTO activity_logs (user_id, action, entity_type, entity_id, details, created_at)
        SELECT ?, 'Electricity Subscription', 'Subscription', ?, ?, ?
        WHERE NOT EXISTS (
            SELECT 1 FROM activity_logs 
            WHERE user_id = ? AND action = 'Electricity Subscription' AND entity_id = ? AND DATE(created_at) = DATE(?)
        )
    ");

    $subCount = 0;
    foreach ($subReports as $rep) {
        $details = "Submitted meter reading (Consumption: {$rep['consumption']} kWh)";
        $insertSubStmt->execute([
            $rep['submitted_by'], $rep['apartment_id'], $details, $rep['created_at'],
            $rep['submitted_by'], $rep['apartment_id'], $rep['created_at']
        ]);
        if ($insertSubStmt->rowCount() > 0) $subCount++;
    }

    // 3. Backfill Electricity Meter Readings (Apartment Cost)
    $aptStmt = $db->query("
        SELECT id, apartment_id, submitted_by, consumption, bill_amount, created_at
        FROM electricity_meter_readings
        WHERE submitted_by IS NOT NULL
    ");
    $aptReports = $aptStmt->fetchAll(PDO::FETCH_ASSOC);

    $insertAptStmt = $db->prepare("
        INSERT INTO activity_logs (user_id, action, entity_type, entity_id, details, created_at)
        SELECT ?, 'Electricity Reading', 'Apartment', ?, ?, ?
        WHERE NOT EXISTS (
            SELECT 1 FROM activity_logs 
            WHERE user_id = ? AND action = 'Electricity Reading' AND entity_id = ? AND DATE(created_at) = DATE(?)
        )
    ");

    $aptCount = 0;
    foreach ($aptReports as $rep) {
        $details = $rep['consumption'] > 0 
            ? "Submitted meter reading (Consumption: {$rep['consumption']} kWh)"
            : "Submitted fixed monthly payment confirmation";
        $insertAptStmt->execute([
            $rep['submitted_by'], $rep['apartment_id'], $details, $rep['created_at'],
            $rep['submitted_by'], $rep['apartment_id'], $rep['created_at']
        ]);
        if ($insertAptStmt->rowCount() > 0) $aptCount++;
    }

    $db->commit();
    echo "Backfill complete! Added $genCount Generator logs, $subCount Subscription logs, and $aptCount Apartment logs.\n";

} catch (Exception $e) {
    $db->rollBack();
    echo "Error: " . $e->getMessage() . "\n";
}
