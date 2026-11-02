i wan<?php
/**
 * Fix: Update today's daily_logs record for generator CORNISHE
 *
 * AUTO MODE: Recalculates hours from previous log (works if submitted_hours is the real meter value)
 * MANUAL MODE: Pass ?submitted_hours=1955.2 in URL to override the stored meter value first,
 *              then recalculate.
 *
 * Usage:
 *   Auto:   https://socimco.wormbitfactory.com/backend/fix_today_generator_log.php
 *   Manual: https://socimco.wormbitfactory.com/backend/fix_today_generator_log.php?submitted_hours=1955.2&generator_id=13
 */

require_once __DIR__ . "/core/Database.php";

try {
    $db = Database::getInstance()->getConnection();
    echo "<pre>";
    echo "=== Fix Today Generator Daily Logs ===\n\n";

    // Optional manual override via GET params
    $manual_submitted_hours = isset($_GET['submitted_hours']) ? floatval($_GET['submitted_hours']) : null;
    $manual_gen_id          = isset($_GET['generator_id'])   ? intval($_GET['generator_id'])       : null;

    $gens = $db->query("SELECT id, name, expected_fuel_consumption_per_hour FROM generators")->fetchAll(PDO::FETCH_ASSOC);

    foreach ($gens as $gen) {
        $gen_id = (int)$gen['id'];
        
        // If manual mode targets a specific generator, skip others
        if ($manual_gen_id && $gen_id !== $manual_gen_id) continue;

        echo "Generator [{$gen_id}] {$gen['name']}\n";

        $todayLog = $db->prepare("SELECT * FROM daily_logs WHERE generator_id = ? AND date = CURDATE()");
        $todayLog->execute([$gen_id]);
        $log = $todayLog->fetch(PDO::FETCH_ASSOC);

        if (!$log) {
            echo "  No log for today.\n\n";
            continue;
        }

        echo "  Log ID={$log['id']}, submitted_hours={$log['submitted_hours']}, calculated_hours_worked={$log['calculated_hours_worked']}\n";

        // Apply manual override if provided
        if ($manual_submitted_hours !== null) {
            $db->prepare("UPDATE daily_logs SET submitted_hours = ? WHERE id = ?")->execute([$manual_submitted_hours, $log['id']]);
            echo "  MANUAL OVERRIDE: submitted_hours set to {$manual_submitted_hours}\n";
            $log['submitted_hours'] = $manual_submitted_hours;
        }

        // Get previous log
        $prevLog = $db->prepare("SELECT submitted_hours FROM daily_logs WHERE generator_id = ? AND id < ? ORDER BY date DESC, id DESC LIMIT 1");
        $prevLog->execute([$gen_id, $log['id']]);
        $prev = $prevLog->fetch(PDO::FETCH_ASSOC);

        if (!$prev) {
            echo "  No previous log found - cannot auto-fix. Use ?submitted_hours=VALUE manually.\n\n";
            continue;
        }

        $prev_hours    = floatval($prev['submitted_hours']);
        $curr_hours    = floatval($log['submitted_hours']);
        $calculated    = round(max(0, $curr_hours - $prev_hours), 2);
        $expected_burn = round($calculated * floatval($gen['expected_fuel_consumption_per_hour']), 2);

        echo "  Previous meter: {$prev_hours}h\n";
        echo "  Current meter:  {$curr_hours}h\n";
        echo "  Hours worked:   {$calculated}h\n";
        echo "  Expected burn:  {$expected_burn}L\n";

        if (abs($calculated - floatval($log['calculated_hours_worked'])) < 0.001) {
            echo "  Already correct - no update needed.\n\n";
            continue;
        }

        $upd = $db->prepare("UPDATE daily_logs SET calculated_hours_worked = ?, expected_factory_fuel_burn = ?, status_flag = 'Pending Analysis' WHERE id = ?");
        $upd->execute([$calculated, $expected_burn, $log['id']]);
        echo "  FIXED! calculated_hours_worked={$calculated}h, expected_fuel={$expected_burn}L\n\n";
    }

    echo "\n=== Current state of today's daily_logs ===\n";
    $all = $db->query("
        SELECT dl.id, g.name as gen_name, dl.submitted_hours, dl.calculated_hours_worked,
               dl.expected_factory_fuel_burn, dl.admin_actual_fuel, dl.predicted_fuel_remaining, dl.status_flag
        FROM daily_logs dl JOIN generators g ON dl.generator_id = g.id
        WHERE dl.date = CURDATE()
    ")->fetchAll(PDO::FETCH_ASSOC);

    if (empty($all)) {
        echo "  (no logs for today)\n";
    }
    foreach ($all as $row) {
        echo "  [{$row['gen_name']}] ID={$row['id']}, meter={$row['submitted_hours']}, worked={$row['calculated_hours_worked']}h, expected_fuel={$row['expected_factory_fuel_burn']}L, status={$row['status_flag']}\n";
    }

    echo "\n=== Done. Delete this file after use. ===\n";
    echo "</pre>";

} catch (PDOException $e) {
    http_response_code(500);
    echo "<pre style='color:red'>FAILED: " . $e->getMessage() . "</pre>";
}
