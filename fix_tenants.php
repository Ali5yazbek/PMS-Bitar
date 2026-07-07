<?php
require_once __DIR__ . '/backend/core/Database.php';
$db = Database::getInstance()->getConnection();
$stmt = $db->query("SELECT id, username FROM users LIMIT 1");
$user = $stmt->fetch(PDO::FETCH_ASSOC);

if ($user) {
    $db->query("UPDATE tenants SET user_id = {$user['id']} WHERE user_id IS NULL");
    echo "Assigned user {$user['id']} to tenants.";
} else {
    echo "No users found.";
}
