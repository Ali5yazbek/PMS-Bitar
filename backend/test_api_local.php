<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/core/Database.php';

// Bypass auth middleware temporarily for testing
class AuthMiddleware {
    public static function requireLogin() { return ['user_id' => 1]; }
}

require_once __DIR__ . '/controllers/AgentRentController.php';

$_GET['apartment_id'] = 1;
$controller = new AgentRentController();
$controller->getApartmentUnpaidInvoices();
