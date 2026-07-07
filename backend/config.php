<?php

// Load .env file
$envFile = __DIR__ . '/.env';
if (file_exists($envFile)) {
    $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        if (strpos(trim($line), '#') === 0) continue; // skip comments
        if (strpos($line, '=') !== false) {
            [$key, $value] = explode('=', $line, 2);
            $_ENV[trim($key)] = trim($value);
        }
    }
}

define('DB_HOST',     $_ENV['DB_HOST']     ?? 'localhost');
define('DB_PORT',     $_ENV['DB_PORT']     ?? '3306');
define('DB_USER',     $_ENV['DB_USERNAME'] ?? 'root');
define('DB_PASS',     $_ENV['DB_PASSWORD'] ?? '');
define('DB_NAME',     $_ENV['DB_DATABASE'] ?? 'bitar_pms');
define('JWT_SECRET',  $_ENV['JWT_SECRET']  ?? 'change_me');
define('JWT_EXPIRES_IN', (int)($_ENV['JWT_EXPIRES_IN'] ?? 86400));
