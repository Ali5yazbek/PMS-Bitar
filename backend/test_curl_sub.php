<?php
$ch = curl_init('https://socimco.wormbitfactory.com/backend/api/energy/agent/subscription-invoices/pay');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode(['invoice_id' => 16, 'amount_collected' => 10, 'status' => 'collected']));
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo1LCJyb2xlIjoiYWdlbnQiLCJuYW1lIjoiaGFzc2FuIGhhZGVkIiwiZXhwIjoxNzg2NzExOTcyLCJpYXQiOjE3ODY2MjU1NzJ9.64j-0svQ5P0fzY11A40QppkkYoN-ecLFCi9KlBm9FZI'
]);
echo curl_exec($ch);
