<?php
require_once __DIR__ . '/core/Database.php';
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/controllers/RentController.php';

// Mock AuthMiddleware so it doesn't fail
class AuthMiddleware {
    public static function requireLogin() {
        return ['user_id' => 1];
    }
}

class AuditLogger {
    public static function log($action, $entity, $entity_id, $description) {
        // do nothing
    }
}

$db = Database::getInstance()->getConnection();

// Delete unpaid auto-generated invoices (so we can recreate them correctly)
$stmt = $db->query("DELETE FROM rent_invoices WHERE id NOT IN (SELECT invoice_id FROM rent_payments) AND invoice_number NOT LIKE '%-H'");
echo "Deleted " . $stmt->rowCount() . " invoices.\n";

$controller = new RentController();
$controller->generateInvoices();
echo "\nDone regenerating!\n";
