<?php
$ch = curl_init('https://socimco.wormbitfactory.com/backend/api/agent/rent/collect');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode(['invoice_id' => 16, 'amount' => 10, 'method' => 'Cash', 'notes' => 'Test', 'type' => 'Electricity Subscription']));
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo1LCJyb2xlIjoiYWdlbnQiLCJuYW1lIjoiaGFzc2FuIGhhZGVkIiwiZXhwIjoxNzg2NzExOTcyLCJpYXQiOjE3ODY2MjU1NzJ9.64j-0svQ5P0fzY11A40QppkkYoN-ecLFCi9KlBm9FZI'
]);
echo curl_exec($ch);
