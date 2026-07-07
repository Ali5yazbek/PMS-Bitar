<?php
$ch = curl_init("https://socimco.wormbitfactory.com/api/auth/login");
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode(["email"=>"admin@bitar.com", "password"=>"password"]));
$res = json_decode(curl_exec($ch), true);
curl_close($ch);

$token = $res["token"];
$ch = curl_init("https://socimco.wormbitfactory.com/api/dashboard/stats");
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, ["Authorization: Bearer $token"]);
echo curl_exec($ch);
