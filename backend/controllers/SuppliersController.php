<?php
class SuppliersController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function index() {
        AuthMiddleware::requireLogin();
        $type = $_GET['type'] ?? '';
        $query = "SELECT * FROM suppliers";
        $params = [];
        if ($type) {
            $query .= " WHERE FIND_IN_SET(?, supplier_type) > 0";
            $params[] = $type;
        }
        $query .= " ORDER BY name ASC";
        $stmt = $this->db->prepare($query);
        $stmt->execute($params);
        echo json_encode($stmt->fetchAll());
    }

    public function show($id) {
        AuthMiddleware::requireLogin();
        $stmt = $this->db->prepare("SELECT * FROM suppliers WHERE id = ?");
        $stmt->execute([$id]);
        $supplier = $stmt->fetch();

        if (!$supplier) {
            http_response_code(404);
            echo json_encode(['error' => 'Supplier not found']);
            return;
        }

        // Transactions
        $stmtTx = $this->db->prepare("SELECT * FROM supplier_transactions WHERE supplier_id = ? ORDER BY transaction_date ASC, id ASC");
        $stmtTx->execute([$id]);
        $transactions = $stmtTx->fetchAll();

        // Purchases (Invoices)
        $stmtPurchases = $this->db->prepare("
            SELECT po.*, c.name as construction_name 
            FROM purchase_orders po
            LEFT JOIN constructions c ON po.construction_id = c.id
            WHERE po.supplier_id = ? 
            ORDER BY po.created_at DESC
        ");
        $stmtPurchases->execute([$id]);
        $purchases = $stmtPurchases->fetchAll();

        // Payments
        $stmtPayments = $this->db->prepare("SELECT * FROM supplier_payments WHERE supplier_id = ? ORDER BY payment_date DESC, id DESC");
        $stmtPayments->execute([$id]);
        $payments = $stmtPayments->fetchAll();

        // Aging Report
        $aging = [
            '0_30' => 0,
            '31_60' => 0,
            '61_90' => 0,
            '90_plus' => 0
        ];
        foreach ($purchases as $p) {
            if ($p['remaining_balance'] > 0 && $p['due_date']) {
                $due = new DateTime($p['due_date']);
                $now = new DateTime();
                if ($now > $due) {
                    $diff = $now->diff($due)->days;
                    if ($diff <= 30) $aging['0_30'] += $p['remaining_balance'];
                    elseif ($diff <= 60) $aging['31_60'] += $p['remaining_balance'];
                    elseif ($diff <= 90) $aging['61_90'] += $p['remaining_balance'];
                    else $aging['90_plus'] += $p['remaining_balance'];
                }
            }
        }

        // Products Summary
        $products = [];
        // Projects Summary
        $projects = [];
        
        $totalPurchases = 0;
        $totalPaid = 0;

        foreach ($payments as $pay) {
            $totalPaid += floatval($pay['amount']);
        }

        foreach ($purchases as $p) {
            $totalPurchases += floatval($p['total_price']);

            if ($p['item_name']) {
                if (!isset($products[$p['item_name']])) {
                    $products[$p['item_name']] = ['quantity' => 0, 'total' => 0];
                }
                $products[$p['item_name']]['quantity'] += floatval($p['quantity_ordered']);
                $products[$p['item_name']]['total'] += floatval($p['total_price']);
            }

            if ($p['construction_id']) {
                if (!isset($projects[$p['construction_id']])) {
                    $projects[$p['construction_id']] = [
                        'name' => $p['construction_name'],
                        'total' => 0
                    ];
                }
                $projects[$p['construction_id']]['total'] += floatval($p['total_price']);
            }
        }

        // Add opening balance to totals if we want, or just rely on transactions for balance
        $currentBalance = 0;
        if (count($transactions) > 0) {
            $currentBalance = $transactions[count($transactions)-1]['balance_after'];
        }

        echo json_encode([
            'supplier' => $supplier,
            'transactions' => $transactions,
            'purchases' => $purchases,
            'payments' => $payments,
            'aging' => $aging,
            'products' => $products,
            'projects' => array_values($projects),
            'summary' => [
                'totalPurchases' => $totalPurchases,
                'totalPaid' => $totalPaid,
                'currentBalance' => $currentBalance
            ]
        ]);
    }

    public function store() {
        AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        $types = isset($data['supplier_type']) && is_array($data['supplier_type']) 
                 ? implode(',', $data['supplier_type']) 
                 : ($data['supplier_type'] ?? 'General');

        $credit_limit = floatval($data['credit_limit'] ?? 0);
        $payment_terms_days = intval($data['payment_terms_days'] ?? 30);
        $opening_balance = floatval($data['opening_balance'] ?? 0);
        $opening_balance_date = $data['opening_balance_date'] ?? date('Y-m-d');

        $this->db->beginTransaction();
        try {
            $stmt = $this->db->prepare("INSERT INTO suppliers (name, contact_info, supplier_type, credit_limit, payment_terms_days, opening_balance, opening_balance_date) VALUES (?, ?, ?, ?, ?, ?, ?)");
            $stmt->execute([$data['name'], $data['contact_info'] ?? '', $types, $credit_limit, $payment_terms_days, $opening_balance, $opening_balance_date]);
            $supplier_id = $this->db->lastInsertId();

            if ($opening_balance > 0) {
                $stmtTx = $this->db->prepare("INSERT INTO supplier_transactions (supplier_id, type, reference_id, amount, balance_after, transaction_date) VALUES (?, 'Opening Balance', 'OPENING', ?, ?, ?)");
                $stmtTx->execute([$supplier_id, $opening_balance, $opening_balance, $opening_balance_date]);
            }

            $this->db->commit();
            echo json_encode(['message' => 'Supplier added successfully', 'id' => $supplier_id]);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function recordPayment($id) {
        AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        $amount = floatval($data['amount']);
        if ($amount <= 0) {
            http_response_code(400);
            echo json_encode(['error' => 'Amount must be greater than 0']);
            return;
        }

        $date = $data['payment_date'] ?? date('Y-m-d');
        $method = $data['payment_method'] ?? 'Bank Transfer';
        $ref = $data['reference_number'] ?? '';
        $bank = $data['bank_name'] ?? '';
        $notes = $data['notes'] ?? '';

        $this->db->beginTransaction();
        try {
            // 1. Create supplier_payment
            $stmtPay = $this->db->prepare("INSERT INTO supplier_payments (supplier_id, amount, payment_date, payment_method, reference_number, bank_name, notes) VALUES (?, ?, ?, ?, ?, ?, ?)");
            $stmtPay->execute([$id, $amount, $date, $method, $ref, $bank, $notes]);
            $payment_id = $this->db->lastInsertId();

            // 2. Allocate payment to invoices if specified, else do FIFO
            $remainingAmountToAllocate = $amount;
            $allocations = [];
            
            if (isset($data['allocations']) && is_array($data['allocations']) && count($data['allocations']) > 0) {
                // Specific allocation
                foreach ($data['allocations'] as $alloc) {
                    $allocAmt = floatval($alloc['amount']);
                    $poId = $alloc['purchase_order_id'];
                    if ($allocAmt > 0 && $remainingAmountToAllocate >= $allocAmt) {
                        $allocations[] = ['po_id' => $poId, 'amount' => $allocAmt];
                        $remainingAmountToAllocate -= $allocAmt;
                    }
                }
            } else {
                // Auto FIFO allocation
                $stmtUnpaid = $this->db->prepare("SELECT id, remaining_balance FROM purchase_orders WHERE supplier_id = ? AND remaining_balance > 0 ORDER BY due_date ASC, created_at ASC");
                $stmtUnpaid->execute([$id]);
                $unpaidPOs = $stmtUnpaid->fetchAll();
                
                foreach ($unpaidPOs as $po) {
                    if ($remainingAmountToAllocate <= 0) break;
                    
                    $payAmt = min($remainingAmountToAllocate, floatval($po['remaining_balance']));
                    $allocations[] = ['po_id' => $po['id'], 'amount' => $payAmt];
                    $remainingAmountToAllocate -= $payAmt;
                }
            }

            // 3. Process allocations
            $stmtAlloc = $this->db->prepare("INSERT INTO supplier_payment_allocations (payment_id, purchase_order_id, amount) VALUES (?, ?, ?)");
            $stmtUpdatePO = $this->db->prepare("UPDATE purchase_orders SET amount_paid = amount_paid + ?, remaining_balance = remaining_balance - ? WHERE id = ?");
            
            foreach ($allocations as $alloc) {
                $stmtAlloc->execute([$payment_id, $alloc['po_id'], $alloc['amount']]);
                $stmtUpdatePO->execute([$alloc['amount'], $alloc['amount'], $alloc['po_id']]);
                
                // Update payment_status dynamically
                $this->db->exec("UPDATE purchase_orders SET payment_status = CASE WHEN remaining_balance <= 0 THEN 'Paid' ELSE 'Partially Paid' END WHERE id = " . intval($alloc['po_id']));
            }

            // 4. Update Ledger
            // Get current balance
            $stmtBal = $this->db->prepare("SELECT balance_after FROM supplier_transactions WHERE supplier_id = ? ORDER BY transaction_date DESC, id DESC LIMIT 1");
            $stmtBal->execute([$id]);
            $lastBal = $stmtBal->fetchColumn();
            $newBal = floatval($lastBal) - $amount; // Payment decreases debt

            $stmtTx = $this->db->prepare("INSERT INTO supplier_transactions (supplier_id, type, reference_id, amount, balance_after, transaction_date) VALUES (?, 'Payment', ?, ?, ?, ?)");
            $stmtTx->execute([$id, 'PAY-'.$payment_id, -$amount, $newBal, $date]); // Use negative amount for payments to signify reduction

            $this->db->commit();
            echo json_encode(['message' => 'Payment recorded successfully', 'payment_id' => $payment_id, 'unallocated' => $remainingAmountToAllocate]);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function dashboard() {
        AuthMiddleware::requireLogin();
        
        $today = date('Y-m-d');
        $thisMonth = date('Y-m-01');

        $stats = [
            'todayPurchases' => 0,
            'todayPayments' => 0,
            'monthlyPurchases' => 0,
            'monthlyPayments' => 0,
            'totalDebt' => 0
        ];

        // Today Purchases
        $stmtTP = $this->db->query("SELECT SUM(amount) FROM supplier_transactions WHERE type = 'Purchase' AND transaction_date = '$today'");
        $stats['todayPurchases'] = floatval($stmtTP->fetchColumn());

        // Today Payments
        $stmtTPay = $this->db->query("SELECT SUM(amount) FROM supplier_payments WHERE payment_date = '$today'");
        $stats['todayPayments'] = floatval($stmtTPay->fetchColumn());

        // Monthly Purchases
        $stmtMP = $this->db->query("SELECT SUM(amount) FROM supplier_transactions WHERE type = 'Purchase' AND transaction_date >= '$thisMonth'");
        $stats['monthlyPurchases'] = floatval($stmtMP->fetchColumn());

        // Monthly Payments
        $stmtMPay = $this->db->query("SELECT SUM(amount) FROM supplier_payments WHERE payment_date >= '$thisMonth'");
        $stats['monthlyPayments'] = floatval($stmtMPay->fetchColumn());

        // Total Debt
        // Sum of all last balances from each supplier
        $stmtDebt = $this->db->query("
            SELECT SUM(latest.balance_after) as total_debt
            FROM (
                SELECT supplier_id, MAX(id) as max_id
                FROM supplier_transactions
                GROUP BY supplier_id
            ) as m
            JOIN supplier_transactions latest ON m.max_id = latest.id
        ");
        $stats['totalDebt'] = floatval($stmtDebt->fetchColumn());

        // Top Suppliers
        $stmtTop = $this->db->query("
            SELECT s.name, latest.balance_after as debt
            FROM (
                SELECT supplier_id, MAX(id) as max_id
                FROM supplier_transactions
                GROUP BY supplier_id
            ) as m
            JOIN supplier_transactions latest ON m.max_id = latest.id
            JOIN suppliers s ON latest.supplier_id = s.id
            WHERE latest.balance_after > 0
            ORDER BY latest.balance_after DESC
            LIMIT 5
        ");
        $topSuppliers = $stmtTop->fetchAll();

        echo json_encode([
            'stats' => $stats,
            'topSuppliers' => $topSuppliers
        ]);
    }
}
