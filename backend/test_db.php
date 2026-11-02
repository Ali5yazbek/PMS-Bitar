<?php
require_once 'core/Database.php';

$db = Database::getInstance()->getConnection();
$tasks = [];

// 0. Generator Logs (Buildings needing report today or have a rejected report)
$genStmt = $db->query("
    SELECT g.id, g.name, b.id as building_id, b.name as building_name 
    FROM generators g
    JOIN buildings b ON g.building_id = b.id
    WHERE NOT EXISTS (
        SELECT 1 FROM generator_daily_reports gdr 
        WHERE gdr.generator_id = g.id AND gdr.date = CURDATE() AND gdr.status != 'Rejected'
    )
");
while ($row = $genStmt->fetch(PDO::FETCH_ASSOC)) {
    $tasks[] = [
        'id' => 'gen_log_' . $row['id'],
        'task_tag' => 'DAILY GENERATOR CHECK',
        'title' => $row['name'] . ' (' . $row['building_name'] . ')',
        'description' => "Required submission between 7:00 AM and 11:59 PM.",
        'action_text' => 'Tap to log daily generator status',
        'status' => 'pending',
        'action_type' => 'GENERATOR_LOG',
        'entity_id' => $row['id']
    ];
}

// 2. Upcoming Subscription Expiries (Based on next_billing_date like getSubscriptionTasks)
$subsStmt = $db->prepare("
    SELECT es.id, es.next_billing_date, es.end_date, es.type, es.monthly_fee, es.last_meter_reading, a.code as apartment_code, b.name as building_name, t.full_name as tenant_name,
           (SELECT status FROM agent_subscription_readings WHERE subscription_id = es.id ORDER BY created_at DESC LIMIT 1) as latest_status,
           DATEDIFF(es.next_billing_date, CURDATE()) as days_until_expiry
    FROM electricity_subscriptions es
    JOIN apartments a ON es.apartment_id = a.id
    JOIN buildings b ON a.building_id = b.id
    LEFT JOIN contracts c ON a.id = c.apartment_id AND c.status = 'Active'
    LEFT JOIN tenants t ON c.tenant_id = t.id
    WHERE es.status = 'Active' 
    AND es.next_billing_date IS NOT NULL 
    AND es.next_billing_date <= ?
");
$subsStmt->execute([date('Y-m-d', strtotime('+30 days'))]);

while ($row = $subsStmt->fetch(PDO::FETCH_ASSOC)) {
    // Only show if not pending review
    if ($row['latest_status'] === 'Pending') continue;
    
    $tasks[] = [
        'id' => 'sub_' . $row['id'],
        'task_tag' => 'SUBSCRIPTION REVIEW',
        'title' => $row['building_name'] . ' - Apt ' . $row['apartment_code'],
        'description' => "Billing due on {$row['next_billing_date']}. Tenant: " . ($row['tenant_name'] ?: 'None'),
        'action_text' => 'Tap to review subscription',
        'status' => 'pending',
        'action_type' => 'SUBSCRIPTION_REVIEW',
        'entity_id' => $row['id'],
        // Include extras needed by the modal
        'building_name' => $row['building_name'],
        'apartment_code' => $row['apartment_code'],
        'tenant_name' => $row['tenant_name'],
        'subscription_type' => $row['type'],
        'monthly_fee' => $row['monthly_fee'],
        'previous_reading' => $row['last_meter_reading'],
        'days_until_expiry' => $row['days_until_expiry']
    ];
}

// 3. Monthly Meter Cycles (If between 25th and 5th of next month)
$day = (int)date('d');
if ($day >= 25 || $day <= 5) {
    $buildingsStmt = $db->query("SELECT id, name FROM buildings");
    while ($b = $buildingsStmt->fetch(PDO::FETCH_ASSOC)) {
        $tasks[] = [
            'id' => 'meter_cycle_' . $b['id'],
            'task_tag' => 'METER CYCLE',
            'title' => $b['name'],
            'description' => "Submit monthly electricity meter readings for this building.",
            'action_text' => 'Tap to start meter readings',
            'status' => 'pending',
            'action_type' => 'METER_READING',
            'entity_id' => $b['id']
        ];
    }
}

// 4. Pending Collections (Unpaid Rent Invoices)
$collectionsStmt = $db->query("
    SELECT b.id, b.name, COUNT(ri.id) as unpaid_count, SUM(ri.amount) as total_due
    FROM rent_invoices ri
    JOIN contracts c ON ri.contract_id = c.id
    JOIN apartments a ON c.apartment_id = a.id
    JOIN buildings b ON a.building_id = b.id
    WHERE ri.status != 'Paid'
    GROUP BY b.id, b.name
    HAVING unpaid_count > 0
");
while ($row = $collectionsStmt->fetch(PDO::FETCH_ASSOC)) {
    $tasks[] = [
        'id' => 'collection_' . $row['id'],
        'task_tag' => 'RENT COLLECTION',
        'title' => $row['name'],
        'description' => "{$row['unpaid_count']} pending invoices (Total: $" . number_format($row['total_due'], 2) . ")",
        'action_text' => 'Tap to start collections',
        'status' => 'pending',
        'action_type' => 'RENT_COLLECTION',
        'entity_id' => $row['id']
    ];
}

echo json_encode(['success' => true, 'tasks' => $tasks]);
