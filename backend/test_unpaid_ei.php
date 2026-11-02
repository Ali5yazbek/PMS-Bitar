<?php
$host = '127.0.0.1';
$db   = 'bitar_pms';
$user = 'root';
$pass = '';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$db", $user, $pass);
    $stmt = $pdo->query("SELECT * FROM electricity_invoices WHERE status != 'Paid'");
    print_r($stmt->fetchAll(PDO::FETCH_ASSOC));
} catch (PDOException $e) {
    echo $e->getMessage();
}
