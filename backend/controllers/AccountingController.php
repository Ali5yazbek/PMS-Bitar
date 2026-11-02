<?php
namespace Controllers;

use Core\Response;
use Core\EventBus;
use Core\Events\PaymentReceivedEvent;

class AccountingController {
    private $db;

    public function __construct() {
        $this->db = \Database::getInstance()->getConnection();
        
        // Listen to events
        EventBus::subscribe('Core\\Events\\PaymentReceivedEvent', [$this, 'handlePaymentReceived']);
    }

    /**
     * Event Listener for Payment Received
     * Debits Cash, Credits Accounts Receivable/Rental Revenue
     */
    public function handlePaymentReceived(PaymentReceivedEvent $event) {
        try {
            // Find account IDs
            $stmt = $this->db->prepare("SELECT id, code FROM accounts WHERE code IN ('1000', '4000')");
            $stmt->execute();
            $accounts = $stmt->fetchAll(\PDO::FETCH_ASSOC);
            
            $cashAccountId = null;
            $revenueAccountId = null;
            
            foreach ($accounts as $acc) {
                if ($acc['code'] == '1000') $cashAccountId = $acc['id'];
                if ($acc['code'] == '4000') $revenueAccountId = $acc['id'];
            }

            if (!$cashAccountId || !$revenueAccountId) return;

            // Create Journal Entry
            $desc = "Rent Payment #" . $event->paymentId . " for Invoice #" . $event->invoiceId;
            $stmt = $this->db->prepare("
                INSERT INTO journal_entries (date, description, debit_account_id, credit_account_id, amount, reference_type, reference_id, created_by) 
                VALUES (CURDATE(), ?, ?, ?, ?, 'Payment', ?, ?)
            ");
            $stmt->execute([
                $desc, 
                $cashAccountId, 
                $revenueAccountId, 
                $event->amount, 
                $event->paymentId,
                $event->userId
            ]);

            // Update Agent Cash Drawer
            $stmt = $this->db->prepare("
                INSERT INTO cash_drawers (user_id, balance) VALUES (?, ?) 
                ON DUPLICATE KEY UPDATE balance = balance + ?
            ");
            $stmt->execute([$event->userId, $event->amount, $event->amount]);

        } catch (\Exception $e) {
            error_log("Accounting Event Error: " . $e->getMessage());
        }
    }

    /**
     * Get Trial Balance
     */
    public function getTrialBalance() {
        try {
            $stmt = $this->db->prepare("
                SELECT 
                    a.code, a.name, a.type,
                    COALESCE(SUM(CASE WHEN je.debit_account_id = a.id THEN je.amount ELSE 0 END), 0) as total_debit,
                    COALESCE(SUM(CASE WHEN je.credit_account_id = a.id THEN je.amount ELSE 0 END), 0) as total_credit
                FROM accounts a
                LEFT JOIN journal_entries je ON (je.debit_account_id = a.id OR je.credit_account_id = a.id)
                GROUP BY a.id, a.code, a.name, a.type
                ORDER BY a.code ASC
            ");
            $stmt->execute();
            $balances = $stmt->fetchAll(\PDO::FETCH_ASSOC);
            
            return Response::json(['status' => 'success', 'data' => $balances]);
        } catch (\Exception $e) {
            return Response::json(['status' => 'error', 'message' => $e->getMessage()], 500);
        }
    }

    /**
     * Get General Ledger for a specific account
     */
    public function getGeneralLedger($accountId) {
        try {
            $stmt = $this->db->prepare("
                SELECT date, description, 
                       CASE WHEN debit_account_id = ? THEN amount ELSE 0 END as debit,
                       CASE WHEN credit_account_id = ? THEN amount ELSE 0 END as credit
                FROM journal_entries 
                WHERE debit_account_id = ? OR credit_account_id = ?
                ORDER BY date ASC, id ASC
            ");
            $stmt->execute([$accountId, $accountId, $accountId, $accountId]);
            $entries = $stmt->fetchAll(\PDO::FETCH_ASSOC);
            
            return Response::json(['status' => 'success', 'data' => $entries]);
        } catch (\Exception $e) {
            return Response::json(['status' => 'error', 'message' => $e->getMessage()], 500);
        }
    }
}
