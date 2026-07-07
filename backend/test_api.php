<?php
require 'config.php';
require 'core/Database.php';

// generate token for user 4
$user = ['id' => 4, 'role' => 'tenant', 'name' => 'ali yazbekk'];
$token = JWT::encode($user);
echo "Token: $token\n";

$ch = curl_init('http://localhost/Bitar/backend/api/tenant-portal/dashboard');
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Authorization: Bearer ' . $token]);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
$response = curl_exec($ch);
echo "Response: $response\n";
