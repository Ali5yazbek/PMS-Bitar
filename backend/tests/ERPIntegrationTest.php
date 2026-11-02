<?php
// ERPIntegrationTest.php
// Basic script to verify the EventBus, Accounting Ledgers, and Schedulers

require_once __DIR__ . '/../core/Database.php';
require_once __DIR__ . '/../core/EventBus.php';
require_once __DIR__ . '/../core/events/PaymentReceivedEvent.php';
require_once __DIR__ . '/../controllers/AccountingController.php';

use Core\EventBus;
use Core\Events\PaymentReceivedEvent;
use Controllers\AccountingController;

echo "Starting V4 ERP Integration Tests...\n";
echo "====================================\n";

$db = Database::getInstance()->getConnection();

// 1. Test Database Connectivity & V4 Schema Presence
try {
    $stmt = $db->query("SELECT 1 FROM journal_entries LIMIT 1");
    echo "[PASS] Database connected and V4 schema (journal_entries) is present.\n";
} catch (Exception $e) {
    echo "[FAIL] Database V4 schema missing: " . $e->getMessage() . "\n";
}

// 2. Test Event Bus & Accounting Integration
try {
    $db->beginTransaction();
    
    // Subscribe AccountingController to the EventBus
    $accountingController = new AccountingController(); // This automatically subscribes
    
    // Simulate a $500 rent payment for User #1, Invoice #9999
    $simulatedPaymentId = 99999;
    $simulatedInvoiceId = 99999;
    $simulatedAmount = 500.00;
    $simulatedUserId = 1;
    
    $event = new PaymentReceivedEvent($simulatedPaymentId, $simulatedInvoiceId, $simulatedAmount, $simulatedUserId);
    
    echo "Dispatching PaymentReceivedEvent for $500...\n";
    EventBus::dispatch($event);
    
    // Verify journal_entries was created
    $stmt = $db->prepare("SELECT * FROM journal_entries WHERE reference_type = 'Payment' AND reference_id = ?");
    $stmt->execute([$simulatedPaymentId]);
    $journalEntry = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($journalEntry && $journalEntry['amount'] == 500.00) {
        echo "[PASS] Accounting Controller successfully caught EventBus event and inserted Journal Entry.\n";
    } else {
        echo "[FAIL] Journal Entry was not created by the Event Bus.\n";
    }
    
    // Rollback test data
    $db->rollBack();
    echo "[PASS] Test data successfully rolled back.\n";
    
} catch (Exception $e) {
    if ($db->inTransaction()) {
        $db->rollBack();
    }
    echo "[FAIL] EventBus Integration Test Exception: " . $e->getMessage() . "\n";
}

echo "====================================\n";
echo "ERP Integration Tests Completed.\n";
