<?php
$ch = curl_init('http://localhost/Bitar/backend/api/generator/addDailyLog');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode(['generator_id' => 13, 'submitted_hours' => 2000, 'date' => date('Y-m-d')]));
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
echo "HTTP Code: $http_code\n";
echo "Response: $response\n";
