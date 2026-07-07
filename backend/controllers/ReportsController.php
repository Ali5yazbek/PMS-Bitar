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
        $end = $_GET['end_date'] ?? date('Y-m-t');

        // Fetch buildings
        $bStmt = $this->db->query("SELECT id, name FROM buildings ORDER BY name ASC");
        $buildings = $bStmt->fetchAll(PDO::FETCH_ASSOC);

        // Fetch apartments with their buildings
        $aStmt = $this->db->query("SELECT id, building_id, code FROM apartments ORDER BY code ASC");
        $apartments = $aStmt->fetchAll(PDO::FETCH_ASSOC);

        // Fetch invoices in the date range
        $sqlInvoices = "
            SELECT ri.id as invoice_id, ri.invoice_number, ri.amount, ri.due_date, ri.status,
                   c.apartment_id,
                   COALESCE((SELECT SUM(amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0) as paid_amount
            FROM rent_invoices ri
            JOIN contracts c ON ri.contract_id = c.id
            WHERE ri.due_date >= ? AND ri.due_date <= ?
            ORDER BY ri.due_date DESC
        ";
        $iStmt = $this->db->prepare($sqlInvoices);
        $iStmt->execute([$start, $end]);
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
                'code' => $apt['code'],
                'total_income' => 0,
                'total_received' => 0,
                'total_remaining' => 0,
                'invoices' => []
            ];
        }

        foreach ($invoices as $inv) {
            $aptId = $inv['apartment_id'];
            if (isset($aptsMap[$aptId])) {
                $invAmount = (float)$inv['amount'];
                $paidAmount = (float)$inv['paid_amount'];
                $remaining = $invAmount - $paidAmount;

                $aptsMap[$aptId]['invoices'][] = $inv;
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

        // Convert map to array
        $resultBuildings = array_values($buildsMap);

        echo json_encode([
            'global' => $global,
            'buildings' => $resultBuildings
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
            LEFT JOIN contracts c ON a.id = c.apartment_id AND c.status = 'Active'
            LEFT JOIN tenants t ON c.tenant_id = t.id
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

        // Fetch invoices for generator subscriptions
        $iQuery = "
            SELECT ei.apartment_id, ei.amount, ei.amount_paid, ei.status, ei.type
            FROM electricity_invoices ei
            WHERE (ei.type IN ('Subscription', 'Fixed Subscription') OR ei.type = '')
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

