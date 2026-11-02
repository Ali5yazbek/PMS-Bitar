<?php
require_once __DIR__ . '/../config.php';

// Database connection
$conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Fetch all admins
$admin_ids = [];
$res = $conn->query("SELECT id FROM users WHERE role = 'admin' OR role = 'superadmin'");
if ($res) {
    while($row = $res->fetch_assoc()) {
        $admin_ids[] = $row['id'];
    }
}
if (empty($admin_ids)) $admin_ids = [1]; // Fallback

$trigger_days = [30, 14, 7, 3, 1, 0];
$today = date('Y-m-d');

function addNotification($conn, $user_id, $title, $message, $type, $ref_id = null) {
    $stmt = $conn->prepare("SELECT id FROM notifications WHERE user_id = ? AND title = ? AND DATE(created_at) = CURDATE()");
    $stmt->bind_param("is", $user_id, $title);
    $stmt->execute();
    if ($stmt->get_result()->num_rows == 0) {
        $insert = $conn->prepare("INSERT INTO notifications (user_id, title, message, type, reference_id) VALUES (?, ?, ?, ?, ?)");
        $insert->bind_param("isssi", $user_id, $title, $message, $type, $ref_id);
        $insert->execute();
    }
}

// 1. Contract Expiries
foreach ($trigger_days as $days) {
    $target_date = date('Y-m-d', strtotime("+$days days"));
    $sql = "SELECT c.id, t.name as tenant_name, c.end_date FROM contracts c JOIN tenants t ON c.tenant_id = t.id WHERE c.end_date = '$target_date' AND c.status = 'active'";
    $result = $conn->query($sql);
    while ($row = $result->fetch_assoc()) {
        $title = "Contract Expiry Reminder ($days days)";
        $msg = "Contract for tenant {$row['tenant_name']} expires on {$row['end_date']}.";
        if ($days == 0) $title = "Contract Expiring Today!";
        foreach ($admin_ids as $aid) addNotification($conn, $aid, $title, $msg, 'contract_expiry', $row['id']);
    }
}

// 2. Rent Expiries
foreach ($trigger_days as $days) {
    $target_date = date('Y-m-d', strtotime("+$days days"));
    $sql = "SELECT r.id, t.name as tenant_name, r.next_due_date FROM rent_invoices r JOIN contracts c ON r.contract_id = c.id JOIN tenants t ON c.tenant_id = t.id WHERE r.next_due_date = '$target_date' AND r.status != 'Paid'";
    $result = $conn->query($sql);
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            $title = "Rent Payment Reminder ($days days)";
            $msg = "Rent for tenant {$row['tenant_name']} is due on {$row['next_due_date']}.";
            if ($days == 0) $title = "Rent Due Today!";
            foreach ($admin_ids as $aid) addNotification($conn, $aid, $title, $msg, 'rent_expiry', $row['id']);
        }
    }
}

// 3. Electricity Subscription Expiries
foreach ($trigger_days as $days) {
    $target_date = date('Y-m-d', strtotime("+$days days"));
    $sql = "SELECT e.id, a.apartment_number, e.end_date FROM electricity_subscriptions e JOIN apartments a ON e.apartment_id = a.id WHERE e.end_date = '$target_date' AND e.status = 'active'";
    $result = $conn->query($sql);
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            $title = "Electricity Sub Expiry ($days days)";
            $msg = "Electricity subscription for Apt {$row['apartment_number']} expires on {$row['end_date']}.";
            if ($days == 0) $title = "Electricity Sub Expiring Today!";
            foreach ($admin_ids as $aid) addNotification($conn, $aid, $title, $msg, 'electricity_expiry', $row['id']);
        }
    }
}

// 4. Generator Subscription Expiries
foreach ($trigger_days as $days) {
    $target_date = date('Y-m-d', strtotime("+$days days"));
    $sql = "SELECT g.id, a.apartment_number, g.end_date FROM generator_subscriptions g JOIN apartments a ON g.apartment_id = a.id WHERE g.end_date = '$target_date' AND g.status = 'active'";
    $result = $conn->query($sql);
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            $title = "Generator Sub Expiry ($days days)";
            $msg = "Generator subscription for Apt {$row['apartment_number']} expires on {$row['end_date']}.";
            if ($days == 0) $title = "Generator Sub Expiring Today!";
            foreach ($admin_ids as $aid) addNotification($conn, $aid, $title, $msg, 'generator_expiry', $row['id']);
        }
    }
}

echo "Expirations checked and notifications created successfully.\n";
$conn->close();
?>
