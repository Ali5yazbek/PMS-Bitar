<?php
$url = "http://127.0.0.1/Bitar/backend/index.php/api/agent/rent/collect";
// Instead of HTTP request, let's bypass auth and instantiate the controller directly.
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/core/Database.php';

// Bypass auth middleware
class AuthMiddleware {
    public static function requireLogin() { return ['user_id' => 1]; }
}

require_once __DIR__ . '/controllers/AgentRentController.php';

// Mock php://input by defining a stream wrapper? No, it's easier to modify $_POST?
// php://input is read directly in the controller using file_get_contents('php://input').
// We can't mock php://input easily. Let's just do a cURL request!

$payload = json_encode([
    'invoice_id' => 16,
    'amount' => 10,
    'method' => 'Cash',
    'notes' => 'Test',
    'type' => 'Electricity Subscription'
]);

$ch = curl_init('http://127.0.0.1/Bitar/backend/index.php/api/agent/rent/collect');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, $payload);
// We need a valid JWT token for auth!
require_once __DIR__ . '/core/JWT.php';
$token = JWT::encode(['user_id' => 1, 'role' => 'agent', 'exp' => time() + 3600], $_ENV['JWT_SECRET'] ?? 'your_super_secret_key_change_me_in_production_for_bitar_pms');
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Authorization: Bearer ' . $token
]);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
echo "HTTP $httpCode\n";
echo $response;
