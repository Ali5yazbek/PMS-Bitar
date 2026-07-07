<?php
$_SERVER['REQUEST_METHOD'] = 'GET';
$_SERVER['REQUEST_URI'] = '/api/constructions/1';
require_once __DIR__ . '/backend/config.php';
require_once __DIR__ . '/backend/core/Database.php';
require_once __DIR__ . '/backend/core/JWT.php';

$token = JWT::encode(['data' => ['id' => 1, 'role' => 'admin']], base64_encode('BitarPMS_Secret_Key'));
$_SERVER['HTTP_AUTHORIZATION'] = 'Bearer ' . $token;

require_once __DIR__ . '/backend/middleware/AuthMiddleware.php';
require_once __DIR__ . '/backend/controllers/ConstructionController.php';

$controller = new ConstructionController();
$controller->show(1);
