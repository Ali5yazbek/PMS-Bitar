<?php
namespace Controllers;

use Core\Database;
use Core\Response;

class ReportController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Generate Tenant Statement Ledger
     */
    public function generateTenantStatement($tenantId, $startDate, $endDate) {
        try {
            // Find tenant
            $stmt = $this->db->prepare("SELECT full_name, email FROM tenants WHERE id = ?");
            $stmt->execute([$tenantId]);
            $tenant = $stmt->fetch(\PDO::FETCH_ASSOC);

            if (!$tenant) {
                return Response::json(['status' => 'error', 'message' => 'Tenant not found'], 404);
            }

            // Ledger records
            $ledger = [];
            $balance = 0;

            // 1. Get Opening Balance (Invoices before start date)
            $stmtOB = $this->db->prepare("
                SELECT 
                    COALESCE(SUM(amount), 0) as past_charges,
                    COALESCE((
                        SELECT SUM(amount) 
                        FROM rent_payments 
                        WHERE invoice_id IN (SELECT id FROM rent_invoices WHERE contract_id IN (SELECT id FROM contracts WHERE tenant_id = ?) AND due_date < ?)
                    ), 0) as past_payments
                FROM rent_invoices 
                WHERE contract_id IN (SELECT id FROM contracts WHERE tenant_id = ?) AND due_date < ?
            ");
            $stmtOB->execute([$tenantId, $startDate, $tenantId, $startDate]);
            $obData = $stmtOB->fetch(\PDO::FETCH_ASSOC);
            
            $openingBalance = $obData['past_charges'] - $obData['past_payments'];
            $balance += $openingBalance;

            // 2. Get Charges (Invoices within date range)
            $stmtCharges = $this->db->prepare("
                SELECT 'Charge' as type, invoice_number as description, due_date as date, amount as debit, 0 as credit 
                FROM rent_invoices 
                WHERE contract_id IN (SELECT id FROM contracts WHERE tenant_id = ?) 
                AND due_date BETWEEN ? AND ?
            ");
            $stmtCharges->execute([$tenantId, $startDate, $endDate]);
            $charges = $stmtCharges->fetchAll(\PDO::FETCH_ASSOC);

            // 3. Get Payments (Payments within date range)
            $stmtPayments = $this->db->prepare("
                SELECT 'Payment' as type, CONCAT('Payment Ref: ', rp.id) as description, rp.date as date, 0 as debit, rp.amount as credit 
                FROM rent_payments rp
                JOIN rent_invoices ri ON rp.invoice_id = ri.id
                WHERE ri.contract_id IN (SELECT id FROM contracts WHERE tenant_id = ?)
                AND rp.date BETWEEN ? AND ?
            ");
            $stmtPayments->execute([$tenantId, $startDate, $endDate]);
            $payments = $stmtPayments->fetchAll(\PDO::FETCH_ASSOC);

            // Merge and sort
            $transactions = array_merge($charges, $payments);
            usort($transactions, function($a, $b) {
                return strtotime($a['date']) - strtotime($b['date']);
            });

            foreach ($transactions as &$tx) {
                $balance += $tx['debit'] - $tx['credit'];
                $tx['balance'] = $balance;
                $ledger[] = $tx;
            }

            return Response::json([
                'status' => 'success',
                'data' => [
                    'tenant' => $tenant,
                    'period' => ['start' => $startDate, 'end' => $endDate],
                    'opening_balance' => $openingBalance,
                    'closing_balance' => $balance,
                    'transactions' => $ledger
                ]
            ]);

        } catch (\Exception $e) {
            return Response::json(['status' => 'error', 'message' => $e->getMessage()], 500);
        }
    }
}
