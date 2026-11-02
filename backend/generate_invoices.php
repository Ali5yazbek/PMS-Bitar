<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/core/Database.php';
require_once __DIR__ . '/services/RentGenerationService.php';

echo "Running RentGenerationService::runDaily()...\n";
$result = RentGenerationService::runDaily();
echo "Status: {$result['status']}\n";
echo "Invoices created: {$result['invoices_created']}\n";
echo "Statuses reconciled: {$result['statuses_reconciled']}\n";
print_r($result['details']);
if (!empty($result['errors'])) {
    echo "Errors:\n";
    print_r($result['errors']);
}
echo "\nDone!\n";
