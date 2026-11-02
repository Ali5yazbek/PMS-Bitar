<?php
require 'config.php';
require 'core/Database.php';

$db = Database::getInstance()->getConnection();

echo "=== CURRENT DATA COUNTS ===" . PHP_EOL;
echo "rent_invoices: " . $db->query('SELECT COUNT(*) FROM rent_invoices')->fetchColumn() . PHP_EOL;
echo "rent_payments: " . $db->query('SELECT COUNT(*) FROM rent_payments')->fetchColumn() . PHP_EOL;
echo "electricity_invoices: " . $db->query('SELECT COUNT(*) FROM electricity_invoices')->fetchColumn() . PHP_EOL;
echo "rent_profiles (will keep but reset billing dates): " . $db->query('SELECT COUNT(*) FROM rent_profiles')->fetchColumn() . PHP_EOL;
echo PHP_EOL;
echo "If you run reset_payments.php it will:" . PHP_EOL;
echo "  - DELETE all rows from rent_payments" . PHP_EOL;
echo "  - DELETE all rows from rent_invoices" . PHP_EOL;
echo "  - DELETE all rows from electricity_invoices" . PHP_EOL;
echo "  - KEEP rent_profiles (reset next_billing_date to today, status to Active)" . PHP_EOL;
echo "  - KEEP contracts, tenants, apartments, buildings" . PHP_EOL;
