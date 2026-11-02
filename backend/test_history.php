<?php
require_once __DIR__ . '/config.php';
try {
    $db = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASS);
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $stmt = $db->query("SELECT * FROM rent_payments ORDER BY id DESC LIMIT 5");
    $payments = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode($payments, JSON_PRETTY_PRINT);
} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}
