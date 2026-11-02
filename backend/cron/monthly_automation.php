<?php
// backend/cron/monthly_automation.php
// This script should be executed on the 1st of every month via cron, or lazy-loaded.

require_once __DIR__ . '/../config.php';

try {
    $db = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASS);
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    echo "Starting monthly automation...\n";
    $currentDate = date('Y-m-d');
    $currentMonthStr = date('Y-m');

    $stmt = $db->query("SELECT * FROM electricity_subscriptions WHERE status = 'Active'");
    $subscriptions = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $invoicesGenerated = 0;
    $tasksGenerated = 0;

    foreach ($subscriptions as $sub) {
        $apartment_id = $sub['apartment_id'];
        $type = $sub['type'];
        $monthly_fee = floatval($sub['monthly_fee']);
        
        if ($type === 'Fixed Monthly' || $type === 'Fixed Amp') {
            // Check if invoice already exists for this month
            $invCheck = $db->prepare("SELECT id FROM electricity_invoices WHERE apartment_id = ? AND type = 'Subscription' AND DATE_FORMAT(due_date, '%Y-%m') = ?");
            $invCheck->execute([$apartment_id, $currentMonthStr]);
            
            if (!$invCheck->fetch()) {
                // Create invoice
                $invStmt = $db->prepare("INSERT INTO electricity_invoices (apartment_id, type, amount, due_date) VALUES (?, 'Subscription', ?, ?)");
                $invStmt->execute([$apartment_id, $monthly_fee, $currentDate]);
                $invoicesGenerated++;
                
                // Update next_billing_date
                $updStmt = $db->prepare("UPDATE electricity_subscriptions SET next_billing_date = DATE_ADD(?, INTERVAL 1 MONTH) WHERE id = ?");
                $updStmt->execute([$currentDate, $sub['id']]);

                // Log history
                $histStmt = $db->prepare("INSERT INTO subscription_history (subscription_id, action, reason, performed_by) VALUES (?, 'Invoice Generated', 'Monthly Automation', 1)");
                $histStmt->execute([$sub['id']]);
            }
        } elseif ($type === 'Meter') {
            $updStmt = $db->prepare("UPDATE electricity_subscriptions SET next_billing_date = DATE_ADD(?, INTERVAL 1 MONTH) WHERE id = ? AND next_billing_date <= ?");
            $updStmt->execute([$currentDate, $sub['id'], $currentDate]);
            if ($updStmt->rowCount() > 0) {
                $tasksGenerated++;
                // Log history
                $histStmt = $db->prepare("INSERT INTO subscription_history (subscription_id, action, reason, performed_by) VALUES (?, 'Task Generated', 'Monthly Automation', 1)");
                $histStmt->execute([$sub['id']]);
            }
        }
    }

    echo "Completed. Invoices: $invoicesGenerated, Tasks: $tasksGenerated\n";
} catch (PDOException $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
