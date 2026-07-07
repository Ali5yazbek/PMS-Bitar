<?php
class FinancialReportsController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function generate() {
        AuthMiddleware::requireLogin();

        $start_date = $_GET['start_date'] ?? date('Y-m-01');
        $end_date   = $_GET['end_date']   ?? date('Y-m-t');
        $building_id   = !empty($_GET['building_id'])   ? $_GET['building_id']   : null;
        $apartment_id  = !empty($_GET['apartment_id'])  ? $_GET['apartment_id']  : null;
        $tenant_id     = !empty($_GET['tenant_id'])     ? $_GET['tenant_id']     : null;
        $payment_method = !empty($_GET['payment_method']) ? $_GET['payment_method'] : null;

        // ── Base apartment query ─────────────────────────────────────────────
        $where  = [];
        $params = [];

        if ($building_id) {
            $where[]  = 'a.building_id = ?';
            $params[] = $building_id;
        }
        if ($apartment_id) {
            if (strpos($apartment_id, ',') !== false) {
                $ids = explode(',', $apartment_id);
                $placeholders = str_repeat('?,', count($ids) - 1) . '?';
                $where[] = "a.id IN ($placeholders)";
                $params = array_merge($params, $ids);
            } else {
                $where[]  = 'a.id = ?';
                $params[] = $apartment_id;
            }
        }
        if ($tenant_id) {
            if (strpos($tenant_id, ',') !== false) {
                $ids = explode(',', $tenant_id);
                $placeholders = implode(',', array_fill(0, count($ids), '?'));
                $where[] = "c.tenant_id IN ($placeholders)";
                $params = array_merge($params, $ids);
            } else {
                $where[]  = 'c.tenant_id = ?';
                $params[] = $tenant_id;
            }
        }

        // Include apartments with active/approved contracts OR within date window
        $where[] = "c.status IN ('Active','Approved','Expired','Terminated')";

        $whereSQL = 'WHERE ' . implode(' AND ', $where);

        $stmt = $this->db->prepare("
            SELECT DISTINCT
                a.id          AS apartment_id,
                a.code        AS apartment_code,
                a.monthly_rent,
                a.monthly_insurance,
                b.id          AS building_id,
                b.name        AS building_name,
                c.id          AS contract_id,
                c.start_date  AS contract_start,
                c.end_date    AS contract_end,
                c.status      AS contract_status,
                c.monthly_rent     AS contract_rent,
                c.monthly_insurance AS contract_insurance,
                c.tenant_id   AS tenant_id,
                t.full_name   AS tenant_name,
                t.phone       AS tenant_phone,
                ia.id         AS insurance_account_id,
                ia.total_saved AS insurance_balance
            FROM apartments a
            JOIN buildings b ON a.building_id = b.id
            JOIN contracts c ON a.id = c.apartment_id
            JOIN tenants t ON c.tenant_id = t.id
            LEFT JOIN insurance_accounts ia ON ia.contract_id = c.id
            $whereSQL
            ORDER BY b.name, a.code, c.id DESC
        ");
        $stmt->execute($params);
        $apartments = $stmt->fetchAll();

        // De-duplicate: if tenant_id filter is set, keep all; otherwise keep latest contract per apartment
        if (!$tenant_id) {
            $seen = [];
            $filtered = [];
            foreach ($apartments as $apt) {
                $key = $apt['apartment_id'];
                if (!isset($seen[$key])) {
                    $seen[$key] = true;
                    $filtered[] = $apt;
                }
            }
            $apartments = $filtered;
        }

        $result = [];

        foreach ($apartments as $apt) {
            $cid  = $apt['contract_id'];
            $aid  = $apt['apartment_id'];
            $iaid = $apt['insurance_account_id'];

            // ── RENT ──────────────────────────────────────────────────────────
            $rent = ['invoices' => [], 'total_billed' => 0, 'total_paid' => 0, 'total_outstanding' => 0];
            if ($cid) {
                $pmFilter = $payment_method ? " AND payment_method = " . $this->db->quote($payment_method) : "";
                
                // Rent Collected (Payments made in this period)
                $sPay = $this->db->prepare("
                    SELECT COALESCE(SUM(amount), 0) FROM rent_payments 
                    WHERE invoice_id IN (SELECT id FROM rent_invoices WHERE contract_id = ? $pmFilter) 
                    AND date BETWEEN ? AND ?
                ");
                $sPay->execute([$cid, $start_date, $end_date]);
                $rent['total_paid'] = (float)$sPay->fetchColumn();

                // Rent Billed (Invoices due in this period)
                $sBill = $this->db->prepare("
                    SELECT COALESCE(SUM(amount), 0) FROM rent_invoices 
                    WHERE contract_id = ? AND due_date BETWEEN ? AND ? $pmFilter
                ");
                $sBill->execute([$cid, $start_date, $end_date]);
                $rent['total_billed'] = (float)$sBill->fetchColumn();

                // Total Outstanding (Global balance)
                $sOut = $this->db->prepare("
                    SELECT COALESCE(SUM(amount - (SELECT COALESCE(SUM(amount),0) FROM rent_payments WHERE invoice_id = ri.id)), 0)
                    FROM rent_invoices ri
                    WHERE ri.contract_id = ? AND ri.status != 'Paid' $pmFilter
                ");
                $sOut->execute([$cid]);
                $rent['total_outstanding'] = (float)$sOut->fetchColumn();

                // Invoices to show in the table (Show invoices due in period OR globally unpaid invoices)
                $s = $this->db->prepare("
                    SELECT ri.id, ri.invoice_number, ri.amount, ri.due_date, ri.status, ri.payment_method, ri.payment_date,
                           COALESCE((SELECT SUM(rp.amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0) AS paid_amount
                    FROM rent_invoices ri
                    WHERE ri.contract_id = ? $pmFilter
                    AND (ri.due_date BETWEEN ? AND ? OR ri.status != 'Paid')
                    ORDER BY ri.due_date ASC
                ");
                $s->execute([$cid, $start_date, $end_date]);
                foreach ($s->fetchAll() as $inv) {
                    $outstanding = max(0, $inv['amount'] - $inv['paid_amount']);
                    $rent['invoices'][] = [
                        'id'             => $inv['id'],
                        'invoice_number' => $inv['invoice_number'],
                        'amount'         => (float)$inv['amount'],
                        'paid'           => (float)$inv['paid_amount'],
                        'outstanding'    => (float)$outstanding,
                        'due_date'       => $inv['due_date'],
                        'status'         => $inv['status'],
                    ];
                }
            }

            // ── INSURANCE ─────────────────────────────────────────────────────
            $insurance = [
                'transactions'    => [],
                'total_deposited' => 0,
                'total_deducted'  => 0,
                'balance'         => (float)($apt['insurance_balance'] ?? 0),
                'required_monthly'=> (float)($apt['contract_insurance'] ?? 0),
            ];
            if ($iaid) {
                $s = $this->db->prepare("
                    SELECT type, amount, date, notes
                    FROM insurance_transactions
                    WHERE account_id = ? AND date BETWEEN ? AND ?
                    ORDER BY date ASC
                ");
                $s->execute([$iaid, $start_date, $end_date]);
                foreach ($s->fetchAll() as $tr) {
                    if ($tr['type'] === 'Deposit') {
                        $insurance['total_deposited'] += (float)$tr['amount'];
                    } else {
                        $insurance['total_deducted']  += (float)$tr['amount'];
                    }
                    $insurance['transactions'][] = $tr;
                }
            }

            // ── ELECTRICITY SUBSCRIPTION ──────────────────────────────────────
            // Table: electricity_subscriptions(id, apartment_id, monthly_fee, status, start_date, end_date)
            // Table: electricity_invoices(id, apartment_id, amount, amount_paid, due_date, status)
            $electricity = [
                'subscriptions'   => [],
                'invoices'        => [],
                'total_billed'    => 0,
                'total_paid'      => 0,
                'total_outstanding'=> 0,
                'monthly_fee'     => 0,
            ];
            $s = $this->db->prepare("
                SELECT id, monthly_fee, amps, status, start_date, end_date
                FROM electricity_subscriptions
                WHERE apartment_id = ? AND status IN ('Active','Suspended')
                LIMIT 1
            ");
            $s->execute([$aid]);
            $sub = $s->fetch();
            if ($sub) {
                $electricity['monthly_fee'] = (float)$sub['monthly_fee'];
                $electricity['subscriptions'][] = $sub;
            }

            // Electricity invoices in date range OR globally unpaid
            $s = $this->db->prepare("
                SELECT id, amount, COALESCE(amount_paid, 0) AS amount_paid, due_date, status
                FROM electricity_invoices
                WHERE apartment_id = ? 
                AND (due_date BETWEEN ? AND ? OR status != 'Paid')
                ORDER BY due_date ASC
            ");
            $s->execute([$aid, $start_date, $end_date]);
            foreach ($s->fetchAll() as $inv) {
                $outstanding = max(0, $inv['amount'] - $inv['amount_paid']);
                $electricity['invoices'][] = [
                    'amount'      => (float)$inv['amount'],
                    'paid'        => (float)$inv['amount_paid'],
                    'outstanding' => (float)$outstanding,
                    'due_date'    => $inv['due_date'],
                    'status'      => $inv['status'],
                ];
                
                // Only add to billed/paid if it's within the requested period
                if ($inv['due_date'] >= $start_date && $inv['due_date'] <= $end_date) {
                    $electricity['total_billed'] += (float)$inv['amount'];
                    $electricity['total_paid']   += (float)$inv['amount_paid'];
                }
                
                // Outstanding accumulates globally
                $electricity['total_outstanding'] += (float)$outstanding;
            }

            // ── GENERATOR SUBSCRIPTION ────────────────────────────────────────
            // No generator_subscriptions table — look up via building's generator readings
            // We'll show any energy-related charges from expenses with entity_type = 'generator'
            $generator = [
                'records'         => [],
                'total_billed'    => 0,
                'total_paid'      => 0,
                'total_outstanding'=> 0,
            ];
            // Try to get generator subscription charges from expenses (entity_type = 'generator' or 'electricity')
            $s = $this->db->prepare("
                SELECT e.amount, e.date, e.notes, e.category
                FROM expenses e
                WHERE e.entity_type = 'generator' AND e.entity_id = ? AND e.date BETWEEN ? AND ?
                ORDER BY e.date ASC
            ");
            $s->execute([$aid, $start_date, $end_date]);
            foreach ($s->fetchAll() as $ex) {
                $generator['records'][] = [
                    'amount'  => (float)$ex['amount'],
                    'paid'    => 0, // It's an expense, not paid by tenant
                    'outstanding' => (float)$ex['amount'],
                    'date'    => $ex['date'],
                    'status'  => 'Unpaid',
                    'notes'   => $ex['notes'],
                ];
                $generator['total_billed'] += (float)$ex['amount'];
                $generator['total_outstanding'] += (float)$ex['amount'];
            }

            // ── APARTMENT EXPENSES ────────────────────────────────────────────
            // Table: apartment_expenses(id, apartment_id, product_id, quantity, cost, total, date)
            // Also check expenses table with entity_type = 'apartment'
            $expenses = ['items' => [], 'total' => 0];

            // From apartment_expenses table
            $s = $this->db->prepare("
                SELECT ae.date, ae.quantity, ae.cost, ae.total,
                       p.name as product_name
                FROM apartment_expenses ae
                LEFT JOIN products p ON ae.product_id = p.id
                WHERE ae.apartment_id = ? AND ae.date BETWEEN ? AND ?
                ORDER BY ae.date ASC
            ");
            $s->execute([$aid, $start_date, $end_date]);
            foreach ($s->fetchAll() as $ex) {
                $expenses['items'][] = [
                    'date'     => $ex['date'],
                    'category' => $ex['product_name'] ?? 'Material',
                    'description' => ($ex['quantity'] ? "Qty: {$ex['quantity']}" : ''),
                    'amount'   => (float)$ex['total'],
                ];
                $expenses['total'] += (float)$ex['total'];
            }

            // From expenses table (entity_type = 'apartment')
            $s = $this->db->prepare("
                SELECT e.date, e.amount, e.notes, e.category, e.expense_type
                FROM expenses e
                WHERE e.entity_type = 'apartment' AND e.entity_id = ? AND e.date BETWEEN ? AND ?
                ORDER BY e.date ASC
            ");
            $s->execute([$aid, $start_date, $end_date]);
            foreach ($s->fetchAll() as $ex) {
                $expenses['items'][] = [
                    'date'        => $ex['date'],
                    'category'    => $ex['category'] ?? $ex['expense_type'] ?? 'Expense',
                    'description' => $ex['notes'] ?? '',
                    'amount'      => (float)$ex['amount'],
                ];
                $expenses['total'] += (float)$ex['amount'];
            }

            // ── FINANCIAL SUMMARY ─────────────────────────────────────────────
            // Insurance deposits are NOT income. They are held in trust.
            $total_collected = $rent['total_paid'] + $electricity['total_paid'] + $generator['total_paid'];
            $net_income = $total_collected - $expenses['total'];

            $result[] = [
                'apartment_id'   => $apt['apartment_id'],
                'apartment_code' => $apt['apartment_code'],
                'building_id'    => $apt['building_id'],
                'building_name'  => $apt['building_name'],
                'contract_id'    => $apt['contract_id'],
                'contract_status'=> $apt['contract_status'],
                'tenant_id'      => $apt['tenant_id'],
                'tenant_name'    => $apt['tenant_name'] ?? 'Vacant',
                'tenant_phone'   => $apt['tenant_phone'] ?? null,
                'rent'           => $rent,
                'insurance'      => $insurance,
                'electricity'    => $electricity,
                'generator'      => $generator,
                'expenses'       => $expenses,
                'summary' => [
                    'total_rent_billed'             => $rent['total_billed'],
                    'total_rent_collected'          => $rent['total_paid'],
                    'total_rent_outstanding'        => $rent['total_outstanding'],
                    'total_insurance_billed'        => $insurance['required_monthly'],
                    'total_insurance_deposited'     => $insurance['total_deposited'],
                    'total_insurance_deducted'      => $insurance['total_deducted'],
                    'insurance_balance'             => $insurance['balance'],
                    'total_electricity_billed'      => $electricity['total_billed'],
                    'total_electricity_collected'   => $electricity['total_paid'],
                    'total_electricity_outstanding' => $electricity['total_outstanding'],
                    'total_generator_billed'        => $generator['total_billed'],
                    'total_generator_collected'     => $generator['total_paid'],
                    'total_generator_outstanding'   => $generator['total_outstanding'],
                    'total_expenses'                => $expenses['total'],
                    'total_collected'               => $total_collected,
                    'net_income'                    => $net_income,
                ]
            ];
        }

        echo json_encode($result);
    }
}
