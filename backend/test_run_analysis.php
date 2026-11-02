<?php
$ch = curl_init('http://localhost/Bitar/backend/api/generator/runAnalysis');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode(['log_id' => 1])); // Assuming log_id is 1
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
echo "HTTP Code: $http_code\n";
echo "Response: $response\n";
