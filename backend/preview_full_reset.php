<?php
require 'config.php';
require 'core/Database.php';

$db = Database::getInstance()->getConnection();

echo "=== FULL RESET PREVIEW ===" . PHP_EOL;
echo PHP_EOL;

$tables = [
    'rent_payments'         => 'Payment records',
    'rent_invoices'         => 'Rent invoices',
    'rent_profiles'         => 'Rent profiles',
    'rent_profile_history'  => 'Rent profile history',
    'contracts'             => 'Contracts',
    'electricity_invoices'  => 'Electricity invoices',
    'electricity_subscriptions' => 'Electricity subscriptions',
    'expenses'              => 'Expenses',
    'maintenance_requests'  => 'Maintenance requests',
    'insurance_accounts'    => 'Insurance accounts',
    'tenants'               => 'Tenants',
];

foreach ($tables as $table => $label) {
    try {
        $count = $db->query("SELECT COUNT(*) FROM $table")->fetchColumn();
        echo "  $label ($table): $count rows" . PHP_EOL;
    } catch (Exception $e) {
        echo "  $label ($table): table not found" . PHP_EOL;
    }
}

echo PHP_EOL;
echo "=== WILL BE KEPT ===" . PHP_EOL;
echo "  buildings: " . $db->query('SELECT COUNT(*) FROM buildings')->fetchColumn() . " rows" . PHP_EOL;
echo "  apartments: " . $db->query('SELECT COUNT(*) FROM apartments')->fetchColumn() . " rows (reset to Vacant)" . PHP_EOL;
echo "  users (admin/manager accounts): kept" . PHP_EOL;
