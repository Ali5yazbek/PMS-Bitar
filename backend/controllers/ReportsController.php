<?php
class ReportsController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    private function getFilters() {
        $filters = [];
        $params = [];
        
        if (!empty($_GET['start_date'])) {
            $filters[] = "date >= ?";
            $params[] = $_GET['start_date'];
        }
        if (!empty($_GET['end_date'])) {
            $filters[] = "date <= ?";
            $params[] = $_GET['end_date'];
        }
        if (!empty($_GET['building_id'])) {
            $filters[] = "building_id = ?";
            $params[] = $_GET['building_id'];
        }
        if (!empty($_GET['tenant_id'])) {
            $filters[] = "tenant_id = ?";
            $params[] = $_GET['tenant_id'];
        }
        
        return ['filters' => $filters, 'params' => $params];
    }

    public function rentCollection() {
        AuthMiddleware::requireLogin();
        
        // This report shows rent collected over a period
        $start = $_GET['start_date'] ?? date('Y-m-01');
        $end = $_GET['end_date'] ?? date('Y-m-t');
        $building = $_GET['building_id'] ?? null;
        
        $sql = "
            SELECT rp.date, rp.amount, ri.invoice_number, a.code as apartment_code, b.name as building_name, t.full_name as tenant_name
            FROM rent_payments rp
            JOIN rent_invoices ri ON rp.invoice_id = ri.id
            JOIN contracts c ON ri.contract_id = c.id
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            JOIN tenants t ON c.tenant_id = t.id
            WHERE rp.date >= ? AND rp.date <= ?
        ";
        $params = [$start, $end];
        
        if ($building) {
            $sql .= " AND b.id = ?";
            $params[] = $building;
        }
        
        $sql .= " ORDER BY rp.date DESC";
        
        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        echo json_encode($stmt->fetchAll());
    }

    public function outstandingBalance() {
        AuthMiddleware::requireLogin();
        
        $building = $_GET['building_id'] ?? null;
        
        $sql = "
            SELECT ri.due_date, ri.invoice_number, 
                   ri.amount as expected_amount, 
                   COALESCE((SELECT SUM(amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0) as paid_amount,
                   (ri.amount - COALESCE((SELECT SUM(amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0)) as outstanding_balance,
                   a.code as apartment_code, b.name as building_name, t.full_name as tenant_name
            FROM rent_invoices ri
            JOIN contracts c ON ri.contract_id = c.id
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            JOIN tenants t ON c.tenant_id = t.id
            WHERE ri.status != 'Paid'
        ";
        $params = [];
        
        if ($building) {
            $sql .= " AND b.id = ?";
            $params[] = $building;
        }
        
        $sql .= " ORDER BY ri.due_date ASC";
        
        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        echo json_encode($stmt->fetchAll());
    }

    public function insurance() {
        AuthMiddleware::requireLogin();
        
        $start = $_GET['start_date'] ?? date('Y-m-01');
        $end = $_GET['end_date'] ?? date('Y-m-t');
        
        $stmt = $this->db->prepare("
            SELECT it.date, it.type, it.amount, it.notes, 
                   a.code as apartment_code, b.name as building_name, t.full_name as tenant_name
            FROM insurance_transactions it
            JOIN insurance_accounts ia ON it.account_id = ia.id
            JOIN contracts c ON ia.contract_id = c.id
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            JOIN tenants t ON c.tenant_id = t.id
            WHERE it.date >= ? AND it.date <= ?
            ORDER BY it.date DESC
        ");
        $stmt->execute([$start, $end]);
        echo json_encode($stmt->fetchAll());
    }

    public function apartmentExpense() {
        AuthMiddleware::requireLogin();
        
        $start = $_GET['start_date'] ?? date('Y-m-01');
        $end = $_GET['end_date'] ?? date('Y-m-t');
        $building = $_GET['building_id'] ?? null;
        
        $sql = "
            SELECT ae.date, ae.quantity, ae.cost, ae.total, p.name as product_name,
                   a.code as apartment_code, b.name as building_name
            FROM apartment_expenses ae
            JOIN products p ON ae.product_id = p.id
            JOIN apartments a ON ae.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE ae.date >= ? AND ae.date <= ?
        ";
        $params = [$start, $end];
        
        if ($building) {
            $sql .= " AND b.id = ?";
            $params[] = $building;
        }
        
        $sql .= " ORDER BY ae.date DESC";
        
        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        echo json_encode($stmt->fetchAll());
    }

    public function contractExpiration() {
        AuthMiddleware::requireLogin();
        
        // Show contracts expiring in the next 30 days or already expired but active
        $sql = "
            SELECT c.end_date, c.status, a.code as apartment_code, b.name as building_name, 
                   t.full_name as tenant_name, t.phone
            FROM contracts c
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            JOIN tenants t ON c.tenant_id = t.id
            WHERE c.status IN ('Active', 'Approved', 'Renewal_Pending') 
              AND c.end_date <= DATE_ADD(CURRENT_DATE(), INTERVAL 30 DAY)
            ORDER BY c.end_date ASC
        ";
        $stmt = $this->db->query($sql);
        echo json_encode($stmt->fetchAll());
    }

    public function renewal() {
        AuthMiddleware::requireLogin();
        
        $sql = "
            SELECT rr.status as renewal_status, rr.created_at as request_date,
                   c.end_date, a.code as apartment_code, b.name as building_name, 
                   t.full_name as tenant_name
            FROM renewal_requests rr
            JOIN contracts c ON rr.contract_id = c.id
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            JOIN tenants t ON c.tenant_id = t.id
            ORDER BY rr.created_at DESC
        ";
        $stmt = $this->db->query($sql);
        echo json_encode($stmt->fetchAll());
    }

    public function tenantPaymentHistory() {
        AuthMiddleware::requireLogin();
        
        $tenant_id = $_GET['tenant_id'] ?? null;
        if (!$tenant_id) {
            http_response_code(400);
            die(json_encode(['error' => 'tenant_id is required']));
        }
        
        $stmt = $this->db->prepare("
            SELECT rp.date, rp.amount, ri.invoice_number, ri.due_date,
                   a.code as apartment_code, b.name as building_name
            FROM rent_payments rp
            JOIN rent_invoices ri ON rp.invoice_id = ri.id
            JOIN contracts c ON ri.contract_id = c.id
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE c.tenant_id = ?
            ORDER BY rp.date DESC
        ");
        $stmt->execute([$tenant_id]);
        echo json_encode($stmt->fetchAll());
    }

    public function buildingFinancialSummary() {
        AuthMiddleware::requireLogin();
        
        $start = $_GET['start_date'] ?? date('Y-m-01');
        $end = $_GET['end_date'] ?? date('Y-m-t');
        
        // This is a complex query, we'll build it with subqueries
        $sql = "
            SELECT b.name as building_name,
                   COALESCE((
                       SELECT SUM(rp.amount) 
                       FROM rent_payments rp 
                       JOIN rent_invoices ri ON rp.invoice_id = ri.id
                       JOIN contracts c ON ri.contract_id = c.id
                       JOIN apartments a ON c.apartment_id = a.id
                       WHERE a.building_id = b.id AND rp.date >= ? AND rp.date <= ?
                   ), 0) as total_rent_collected,
                   COALESCE((
                       SELECT SUM(ae.total)
                       FROM apartment_expenses ae
                       JOIN apartments a ON ae.apartment_id = a.id
                       WHERE a.building_id = b.id AND ae.date >= ? AND ae.date <= ?
                   ), 0) as total_apartment_expenses
            FROM buildings b
            ORDER BY b.name ASC
        ";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$start, $end, $start, $end]);
        echo json_encode($stmt->fetchAll());
    }

    public function detailedFinancialBuildings() {
        AuthMiddleware::requireLogin();

        $start = $_GET['start_date'] ?? date('Y-m-01');
        $end   = $_GET['end_date']   ?? date('Y-m-t');

        // ── Fetch structural data ──────────────────────────────────────────
        $buildings  = $this->db->query("SELECT id, name FROM buildings ORDER BY name ASC")->fetchAll(PDO::FETCH_ASSOC);
        $apartments = $this->db->query("SELECT id, building_id, code FROM apartments ORDER BY code ASC")->fetchAll(PDO::FETCH_ASSOC);

        // Pre-build apartment map
        $aptsMap = [];
        foreach ($apartments as $apt) {
            $aptsMap[$apt['id']] = [
                'id'              => $apt['id'],
                'building_id'     => $apt['building_id'],
                'code'            => $apt['code'],
                'total_income'    => 0,
                'total_received'  => 0,
                'total_remaining' => 0,
                'invoices'        => [],
                'tenant_names'    => [],
            ];
        }

        $global = [
            'total_income'    => 0,
            'total_received'  => 0,
            'total_remaining' => 0,
        ];

        // ════════════════════════════════════════════════════════════════════
        // STREAM 1 — RENT (Only Rent)
        // ════════════════════════════════════════════════════════════════════

        // Rent invoices billed in period (Voided excluded; terminated contracts included)
        $rentInvStmt = $this->db->prepare("
            SELECT ri.id AS invoice_id, ri.invoice_number, ri.amount, ri.due_date, ri.status, c.apartment_id, t.full_name as tenant_name
            FROM rent_invoices ri
            JOIN contracts c ON ri.contract_id = c.id
            JOIN tenants t ON c.tenant_id = t.id
            WHERE ri.due_date BETWEEN ? AND ?
              AND ri.status != 'Voided'
            ORDER BY ri.due_date DESC
        ");
        $rentInvStmt->execute([$start, $end]);
        $rentInvRows = $rentInvStmt->fetchAll(PDO::FETCH_ASSOC);
        $rentInvIds  = array_column($rentInvRows, 'invoice_id');

        // Payments received in period (by payment date, not invoice date)
        $rentPayStmt = $this->db->prepare("
            SELECT rp.invoice_id, SUM(rp.amount) AS period_paid
            FROM rent_payments rp WHERE rp.date BETWEEN ? AND ?
            GROUP BY rp.invoice_id
        ");
        $rentPayStmt->execute([$start, $end]);
        $rentPayMap = [];
        foreach ($rentPayStmt->fetchAll(PDO::FETCH_ASSOC) as $p) {
            $rentPayMap[$p['invoice_id']] = (float)$p['period_paid'];
        }

        foreach ($rentInvRows as $inv) {
            $aptId = $inv['apartment_id'];
            if (!isset($aptsMap[$aptId])) continue;
            
            $invAmt     = (float)$inv['amount'];
            $paidPeriod = $rentPayMap[$inv['invoice_id']] ?? 0;
            
            $allPaidS   = $this->db->prepare("SELECT COALESCE(SUM(amount),0) FROM rent_payments WHERE invoice_id = ?");
            $allPaidS->execute([$inv['invoice_id']]);
            $allPaid    = (float)$allPaidS->fetchColumn();
            
            $remaining  = max(0, $invAmt - $allPaid);
            
            $inv['paid_amount'] = $paidPeriod; 
            $inv['all_paid_amount'] = $allPaid;
            $inv['remaining_amount'] = $remaining;
            
            $aptsMap[$aptId]['invoices'][]     = $inv;
            $aptsMap[$aptId]['total_income']   += $invAmt;
            $aptsMap[$aptId]['total_received'] += $paidPeriod;
            $aptsMap[$aptId]['total_remaining']+= $remaining;
            
            if (!empty($inv['tenant_name'])) {
                $aptsMap[$aptId]['tenant_names'][$inv['tenant_name']] = true;
            }
            
            $global['total_income']    += $invAmt;
            $global['total_received']  += $paidPeriod;
            $global['total_remaining'] += $remaining;
        }

        // Payments in-period on rent invoices outside date range (overdue cleared this period)
        foreach ($rentPayMap as $invId => $paidAmt) {
            if (in_array($invId, $rentInvIds)) continue;
            $xS = $this->db->prepare("SELECT ri.status, c.apartment_id, t.full_name as tenant_name FROM rent_invoices ri JOIN contracts c ON ri.contract_id = c.id JOIN tenants t ON c.tenant_id = t.id WHERE ri.id = ? AND ri.status != 'Voided'");
            $xS->execute([$invId]);
            $xR = $xS->fetch(PDO::FETCH_ASSOC);
            if (!$xR || !isset($aptsMap[$xR['apartment_id']])) continue;
            
            $aptsMap[$xR['apartment_id']]['total_received'] += $paidAmt;
            if (!empty($xR['tenant_name'])) {
                $aptsMap[$xR['apartment_id']]['tenant_names'][$xR['tenant_name']] = true;
            }
            $global['total_received'] += $paidAmt;
        }

        // ── Map apartments → buildings ─────────────────────────────────────
        $buildsMap = [];
        foreach ($buildings as $b) {
            $buildsMap[$b['id']] = [
                'id'              => $b['id'], 
                'name'            => $b['name'],
                'total_income'    => 0, 
                'total_received'  => 0, 
                'total_remaining' => 0,
                'apartments'      => [],
            ];
        }

        foreach ($aptsMap as $apt) {
            $bId = $apt['building_id'];
            if (!isset($buildsMap[$bId])) continue;
            
            $apt['tenant_names_str'] = !empty($apt['tenant_names']) ? implode(', ', array_keys($apt['tenant_names'])) : 'Vacant';
            
            $buildsMap[$bId]['apartments'][] = $apt;
            $buildsMap[$bId]['total_income']    += $apt['total_income'];
            $buildsMap[$bId]['total_received']  += $apt['total_received'];
            $buildsMap[$bId]['total_remaining'] += $apt['total_remaining'];
        }

        echo json_encode([
            'global'    => $global,
            'buildings' => array_values($buildsMap),
        ]);
    }
    public function generatorSubscriptions() {
        AuthMiddleware::requireLogin();
        
        $buildingId = $_GET['building_id'] ?? null;
        $startDate = $_GET['start_date'] ?? null;
        $endDate = $_GET['end_date'] ?? null;

        // Fetch buildings
        $bQuery = "SELECT id, name FROM buildings";
        $bParams = [];
        if ($buildingId) {
            $bQuery .= " WHERE id = ?";
            $bParams[] = $buildingId;
        }
        $bQuery .= " ORDER BY name ASC";
        $bStmt = $this->db->prepare($bQuery);
        $bStmt->execute($bParams);
        $buildings = $bStmt->fetchAll(PDO::FETCH_ASSOC);

        // Fetch apartments with their building and tenant
        $aQuery = "
            SELECT a.id, a.building_id, a.code as name,
                   t.full_name as tenant_name,
                   es.next_billing_date, es.end_date, es.status as subscription_status,
                   DATEDIFF(COALESCE(es.next_billing_date, es.end_date), CURRENT_DATE) as days_remaining
            FROM apartments a
            LEFT JOIN tenants t ON t.id = (SELECT tenant_id FROM contracts WHERE apartment_id = a.id ORDER BY id DESC LIMIT 1)
            LEFT JOIN electricity_subscriptions es ON a.id = es.apartment_id
            WHERE es.id IS NOT NULL
        ";
        $aParams = [];
        if ($buildingId) {
            $aQuery .= " AND a.building_id = ?";
            $aParams[] = $buildingId;
        }
        $aQuery .= " ORDER BY a.code ASC";
        $aStmt = $this->db->prepare($aQuery);
        $aStmt->execute($aParams);
        $apartments = $aStmt->fetchAll(PDO::FETCH_ASSOC);

        // Fetch invoices for generator subscriptions (including Meter)
        $iQuery = "
            SELECT ei.apartment_id, ei.amount, ei.amount_paid, ei.status, ei.type
            FROM electricity_invoices ei
            WHERE (ei.type IN ('Subscription', 'Fixed Subscription', 'Meter') OR ei.type = '')
        ";
        $iParams = [];
        if ($startDate) {
            $iQuery .= " AND ei.due_date >= ?";
            $iParams[] = $startDate;
        }
        if ($endDate) {
            $iQuery .= " AND ei.due_date <= ?";
            $iParams[] = $endDate;
        }
        $iStmt = $this->db->prepare($iQuery);
        $iStmt->execute($iParams);
        $invoices = $iStmt->fetchAll(PDO::FETCH_ASSOC);

        // Build hierarchy
        $global = [
            'total_income' => 0,
            'total_received' => 0,
            'total_remaining' => 0
        ];

        // Map invoices to apartments
        $aptsMap = [];
        foreach ($apartments as $apt) {
            $aptsMap[$apt['id']] = [
                'id' => $apt['id'],
                'building_id' => $apt['building_id'],
                'name' => $apt['name'],
                'tenant_name' => $apt['tenant_name'] ?: 'No Active Tenant',
                'days_remaining' => $apt['days_remaining'],
                'total_income' => 0,
                'total_received' => 0,
                'total_remaining' => 0
            ];
        }

        foreach ($invoices as $inv) {
            $aptId = $inv['apartment_id'];
            if (isset($aptsMap[$aptId])) {
                $invAmount = (float)$inv['amount'];
                
                // Fix for legacy data: if status is Paid, assume amount_paid = amount
                if ($inv['status'] === 'Paid' && (float)$inv['amount_paid'] == 0) {
                    $paidAmount = $invAmount;
                } else {
                    $paidAmount = (float)$inv['amount_paid'];
                }
                
                $remaining = $invAmount - $paidAmount;

                $aptsMap[$aptId]['total_income'] += $invAmount;
                $aptsMap[$aptId]['total_received'] += $paidAmount;
                $aptsMap[$aptId]['total_remaining'] += $remaining;

                $global['total_income'] += $invAmount;
                $global['total_received'] += $paidAmount;
                $global['total_remaining'] += $remaining;
            }
        }

        // Map apartments to buildings
        $buildsMap = [];
        foreach ($buildings as $b) {
            $buildsMap[$b['id']] = [
                'id' => $b['id'],
                'name' => $b['name'],
                'total_income' => 0,
                'total_received' => 0,
                'total_remaining' => 0,
                'apartments' => []
            ];
        }

        foreach ($aptsMap as $apt) {
            $bId = $apt['building_id'];
            if (isset($buildsMap[$bId])) {
                $buildsMap[$bId]['apartments'][] = $apt;
                $buildsMap[$bId]['total_income'] += $apt['total_income'];
                $buildsMap[$bId]['total_received'] += $apt['total_received'];
                $buildsMap[$bId]['total_remaining'] += $apt['total_remaining'];
            }
        }

        // Convert map to array and remove empty buildings
        $resultBuildings = array_filter(array_values($buildsMap), function($b) {
            return count($b['apartments']) > 0;
        });

        echo json_encode([
            'global' => $global,
            'buildings' => array_values($resultBuildings)
        ]);
    }
}

