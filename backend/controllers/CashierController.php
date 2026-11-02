<?php
class CashierController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function getDailySummary() {
        $user = AuthMiddleware::requireLogin();
        
        $date = $_GET['date'] ?? date('Y-m-d');
        
        try {
            $stmt = $this->db->prepare("
                SELECT id, customer_type, payment_type, final_amount, returned_amount, status, discount, tax 
                FROM invoices 
                WHERE date = ? AND status != 'Cancelled'
            ");
            $stmt->execute([$date]);
            $invoices = $stmt->fetchAll();
            
            $summary = [
                'customers' => [
                    'Walk-In' => ['invoices' => 0, 'amount' => 0],
                    'Account' => ['invoices' => 0, 'amount' => 0],
                    'Construction' => ['invoices' => 0, 'amount' => 0],
                    'Apartment' => ['invoices' => 0, 'amount' => 0],
                    'Building' => ['invoices' => 0, 'amount' => 0],
                    'Supplier' => ['invoices' => 0, 'amount' => 0],
                    'Employee' => ['invoices' => 0, 'amount' => 0],
                    'Government' => ['invoices' => 0, 'amount' => 0],
                    'Other' => ['invoices' => 0, 'amount' => 0]
                ],
                'payments' => [
                    'Cash' => ['invoices' => 0, 'amount' => 0],
                    'Card' => ['invoices' => 0, 'amount' => 0],
                    'Bank' => ['invoices' => 0, 'amount' => 0],
                    'Transfer' => ['invoices' => 0, 'amount' => 0],
                    'Cheque' => ['invoices' => 0, 'amount' => 0],
                    'Account' => ['invoices' => 0, 'amount' => 0],
                    'Mixed' => ['invoices' => 0, 'amount' => 0]
                ],
                'totals' => [
                    'gross' => 0,
                    'discounts' => 0,
                    'tax_collected' => 0,
                    'refunds' => 0,
                    'net_cash' => 0,
                    'net_total' => 0
                ]
            ];
            
            foreach ($invoices as $inv) {
                $cType = $inv['customer_type'];
                $pType = $inv['payment_type'];
                
                // Fallbacks if enum didn't match perfectly
                if (!isset($summary['customers'][$cType])) $cType = 'Walk-In';
                if (!isset($summary['payments'][$pType])) $pType = 'Cash';
                
                $amount = (float)$inv['final_amount'];
                $refund = (float)$inv['returned_amount'];
                $discount = (float)$inv['discount'];
                $tax = (float)$inv['tax'];
                $net = $amount - $refund;
                
                // Aggregate Customers
                $summary['customers'][$cType]['invoices']++;
                $summary['customers'][$cType]['amount'] += $amount;
                
                // Aggregate Payments
                $summary['payments'][$pType]['invoices']++;
                $summary['payments'][$pType]['amount'] += $amount;
                
                // Totals
                $summary['totals']['gross'] += ($amount + $discount - $tax);
                $summary['totals']['discounts'] += $discount;
                $summary['totals']['tax_collected'] += $tax;
                $summary['totals']['refunds'] += $refund;
                $summary['totals']['net_total'] += $net;
                
                if ($pType === 'Cash') {
                    $summary['totals']['net_cash'] += $net;
                }
            }
            
            // Get active session if any
            $stmtSession = $this->db->prepare("SELECT * FROM cashier_sessions WHERE user_id = ? AND status = 'Open'");
            $stmtSession->execute([$user['user_id']]);
            $session = $stmtSession->fetch();
            
            if ($session) {
                $summary['session'] = $session;
                // Calculate closing cash = Opening + Net Cash - Expenses (total_expenses tracked in session)
                $summary['session']['expected_closing'] = $session['opening_cash'] + $summary['totals']['net_cash'] - $session['total_expenses'];
            } else {
                $summary['session'] = null;
            }
            
            echo json_encode($summary);
            
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => 'Failed to fetch cashier summary: ' . $e->getMessage()]);
        }
    }
    
    public function getSessions() {
        $user = AuthMiddleware::requireLogin();
        $userId = $user['user_id'];
        
        try {
            $stmt = $this->db->prepare("SELECT * FROM cashier_sessions WHERE user_id = ? ORDER BY opened_at DESC");
            $stmt->execute([$userId]);
            $sessions = $stmt->fetchAll();
            echo json_encode($sessions);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }
    
    // Cashier Drawer Methods
    public function openSession() {
        $user = AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        $userId = $user['user_id'];
        $openingCash = $data['opening_cash'] ?? $data['opening_amount'] ?? 0;
        
        try {
            // Check if already open
            $stmtCheck = $this->db->prepare("SELECT id FROM cashier_sessions WHERE user_id = ? AND status = 'Open'");
            $stmtCheck->execute([$userId]);
            if ($stmtCheck->fetch()) {
                http_response_code(400);
                echo json_encode(['error' => 'A session is already open for this user.']);
                return;
            }
            
            $stmt = $this->db->prepare("INSERT INTO cashier_sessions (user_id, opened_at, opening_cash) VALUES (?, NOW(), ?)");
            $stmt->execute([$userId, $openingCash]);
            
            echo json_encode(['message' => 'Session opened successfully', 'session_id' => $this->db->lastInsertId()]);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }
    
    public function closeSession() {
        $user = AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        $userId = $user['user_id'];
        $closingCash = $data['closing_cash'] ?? $data['closing_amount'] ?? 0;
        $notes = $data['notes'] ?? '';
        
        // We will grab the net cash from daily summary logic
        // Ideally we'd sum exactly between opened_at and NOW()
        try {
            $stmtSession = $this->db->prepare("SELECT * FROM cashier_sessions WHERE user_id = ? AND status = 'Open'");
            $stmtSession->execute([$userId]);
            $session = $stmtSession->fetch();
            
            if (!$session) {
                http_response_code(400);
                echo json_encode(['error' => 'No open session found.']);
                return;
            }
            
            // Calculate sales during this period
            $stmtSales = $this->db->prepare("
                SELECT SUM(final_amount - returned_amount) 
                FROM invoices 
                WHERE created_by = ? AND date >= DATE(?) AND payment_type = 'Cash' AND status != 'Cancelled'
            ");
            // Simplified: we check sales today by this user. 
            // In a strict POS, it checks timestamp >= opened_at
            $stmtSales->execute([$userId, explode(' ', $session['opened_at'])[0]]);
            $netCashSales = (float)$stmtSales->fetchColumn();
            
            $stmt = $this->db->prepare("
                UPDATE cashier_sessions 
                SET closed_at = NOW(), closing_cash = ?, total_sales = ?, status = 'Closed', notes = ? 
                WHERE id = ?
            ");
            $stmt->execute([$closingCash, $netCashSales, $notes, $session['id']]);
            
            echo json_encode(['message' => 'Session closed successfully']);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }
    
    public function addExpense() {
        $user = AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        $userId = $user['user_id'];
        $amount = (float)($data['amount'] ?? 0);
        
        try {
            $stmtSession = $this->db->prepare("SELECT id FROM cashier_sessions WHERE user_id = ? AND status = 'Open'");
            $stmtSession->execute([$userId]);
            $session = $stmtSession->fetch();
            
            if (!$session) {
                http_response_code(400);
                echo json_encode(['error' => 'You must open a cash drawer session first.']);
                return;
            }
            
            $stmtUpdate = $this->db->prepare("UPDATE cashier_sessions SET total_expenses = total_expenses + ? WHERE id = ?");
            $stmtUpdate->execute([$amount, $session['id']]);
            
            echo json_encode(['message' => 'Expense added to drawer successfully']);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }
}
