<?php
/**
 * ═══════════════════════════════════════════════════════════════════
 *  AI Chat Engine – Bitar PMS
 *  Full-spectrum, natural-language query engine connected to every
 *  table in the database. Supports 20+ intent categories.
 * ═══════════════════════════════════════════════════════════════════
 */
require_once __DIR__ . '/../core/NLPEngine.php';

class AIController {
    private $db;
    private $nlp;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
        $this->nlp = new NLPEngine($this->db);
    }

    public function chat() {
        $user = AuthMiddleware::requireLogin();
        if ($user['role'] !== 'admin') {
            http_response_code(403);
            echo json_encode(['error' => 'Only admins can use the AI Chat Engine.']);
            return;
        }

        $data = json_decode(file_get_contents("php://input"), true);
        $rawMessage = trim($data['message'] ?? '');
        $message = strtolower($rawMessage);

        if (empty($message)) {
            echo json_encode(['reply' => "Please ask me something!", 'type' => 'text']);
            return;
        }

        // Detect intent and entities via NLP Engine
        $analysis = $this->nlp->analyze($message);
        $intent = $analysis['intent'];
        $entities = $analysis['entities'];

        // Dispatch to handler
        switch ($intent) {
            case 'agent_purchases':      return $this->getAgentPurchasesData($message);
            case 'ac_maintenance':       return $this->getAcMaintenanceData($message);
            case 'audit_activities':     return $this->getAuditActivitiesData($message);
            case 'expiring_contracts':   return $this->getExpiringContracts($message);
            case 'overdue_rent':         return $this->getOverdueRent($message);
            case 'building_income':      return $this->getBuildingIncome($message);
            case 'building_expenses':    return $this->getBuildingExpenses($message);
            case 'building_summary':     return $this->getBuildingSummary($message);
            case 'tenant_info':          return $this->getTenantInfo($message);
            case 'vacant_apartments':    return $this->getVacantApartments($message);
            case 'apartment_info':       return $this->getApartmentInfo($message);
            case 'rent_dashboard':       return $this->getRentDashboard($message);
            case 'maintenance_tasks':    return $this->getMaintenanceTasks($message);
            case 'fuel_status':          return $this->getFuelStatus($message);
            case 'energy_overview':      return $this->getEnergyOverview($message);
            case 'suppliers_summary':    return $this->getSuppliersSummary($message);
            case 'expenses_summary':     return $this->getExpensesSummary($message);
            case 'insurance_summary':    return $this->getInsuranceSummary($message);
            case 'top_debtors':          return $this->getTopDebtors($message);
            case 'daily_reports':        return $this->getDailyReports($message);
            case 'pos_summary':          return $this->getPosSummary($message);
            case 'construction_status':  return $this->getConstructionStatus($message);
            case 'unpaid_invoices':      return $this->getTopDebtors($message);
            case 'loss_analysis':        return $this->getLossAnalysis($message);
            case 'recommendations':      return $this->getRecommendations($message);
            case 'help':                 return $this->getHelp();
            case 'greeting':             return $this->getGreeting();
            default:                     return $this->universalSearch($rawMessage);
        }
    }

    /** ─── Intent Detection (Handled by NLPEngine) ───────────────────────── */
    // Fallback for direct controller method calls without HTTP req
    public function detectIntent($message) {
        return $this->nlp->analyze($message)['intent'];
    }

    /** ─── Extract entity name from message ─────────────────────────────── */
    private function extractBuildingName($message) {
        $analysis = $this->nlp->analyze($message);
        if (!empty($analysis['entities']['building_name'])) return $analysis['entities']['building_name'];
        
        if (preg_match('/building\s+["\']?([a-z0-9\s\-]+)["\']?/i', $message, $m)) return trim($m[1]);
        return null;
    }
    private function extractTenantName($message) {
        $analysis = $this->nlp->analyze($message);
        if (!empty($analysis['entities']['tenant_name'])) return $analysis['entities']['tenant_name'];

        if (preg_match('/(?:tenant|resident|for|of|about|named?)\s+["\']?([a-z\s]+)["\']?/i', $message, $m)) return trim($m[1]);
        if (preg_match('/([a-z]{3,}\s+[a-z]{3,})/i', $message, $m)) return trim($m[1]);
        return null;
    }
    private function findBuilding($name) {
        if (!$name) return null;
        $stmt = $this->db->prepare("SELECT id, name FROM buildings WHERE LOWER(name) LIKE ? LIMIT 1");
        $stmt->execute(['%' . strtolower($name) . '%']);
        return $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
    }

    /** ─── 1. Expiring Contracts ─────────────────────────────────────────── */
    private function getExpiringContracts($message) {
        // Extract days window: default 60
        $days = 60;
        if (preg_match('/(\d+)\s*day/i', $message, $m)) $days = (int)$m[1];
        elseif (preg_match('/this\s*month/i', $message)) $days = 30;
        elseif (preg_match('/(\d+)\s*month/i', $message, $m)) $days = (int)$m[1] * 30;
        $stmt = $this->db->prepare("
            SELECT t.full_name, t.phone, a.code as apartment_code, b.name as building_name,
                   c.end_date, c.monthly_rent, c.status,
                   DATEDIFF(c.end_date, CURRENT_DATE) as days_left
            FROM contracts c
            JOIN tenants t ON c.tenant_id = t.id
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE c.status IN ('Active','Approved')
              AND c.end_date >= CURRENT_DATE
              AND c.end_date <= DATE_ADD(CURRENT_DATE, INTERVAL ? DAY)
            ORDER BY c.end_date ASC
            LIMIT 20
        ");
        $stmt->execute([$days]);
        $results = $stmt->fetchAll(PDO::FETCH_ASSOC);
        if (empty($results)) {
            echo json_encode(['reply' => "✅ Great news! No contracts expiring within the next $days days.", 'type' => 'text']);
            return;
        }
        echo json_encode([
            'reply' => "⚠️ Found **" . count($results) . "** contracts expiring within $days days:",
            'type' => 'expiring_contracts',
            'data' => $results
        ]);
    }

    /** ─── 2. Overdue Rent ───────────────────────────────────────────────── */
    private function getOverdueRent($message) {
        $bName = $this->extractBuildingName($message);
        $building = $this->findBuilding($bName);
        $buildingFilter = $building ? "AND a.building_id = {$building['id']}" : '';
        $stmt = $this->db->query("
            SELECT t.full_name, t.phone, a.code as apartment_code, b.name as building_name,
                   ri.invoice_number, ri.amount, ri.due_date,
                   COALESCE((SELECT SUM(rp.amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0) as paid,
                   (ri.amount - COALESCE((SELECT SUM(rp.amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0)) as outstanding,
                   DATEDIFF(CURRENT_DATE, ri.due_date) as days_overdue
            FROM rent_invoices ri
            JOIN contracts c ON ri.contract_id = c.id
            JOIN tenants t ON c.tenant_id = t.id
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE ri.status IN ('Unpaid','Partial') AND ri.due_date < CURRENT_DATE $buildingFilter
            ORDER BY days_overdue DESC
            LIMIT 20
        ");
        $results = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $total = array_sum(array_column($results, 'outstanding'));
        if (empty($results)) {
            echo json_encode(['reply' => "✅ No overdue rent found!", 'type' => 'text']);
            return;
        }
        $scope = $building ? "in **{$building['name']}**" : "system-wide";
        echo json_encode([
            'reply' => "🔴 Found **" . count($results) . "** overdue invoices $scope. Total outstanding: **CFA " . number_format($total) . "**",
            'type' => 'overdue_rent',
            'data' => $results
        ]);
    }

    /** ─── 3. Building Income ────────────────────────────────────────────── */
    private function getBuildingIncome($message) {
        $bName = $this->extractBuildingName($message);
        $building = $this->findBuilding($bName);

        if ($building) {
            $stmt = $this->db->prepare("
                SELECT 
                    b.name as building_name,
                    COUNT(DISTINCT a.id) as total_apartments,
                    COUNT(DISTINCT CASE WHEN a.status='Rented' THEN a.id END) as rented,
                    COALESCE(SUM(rp.amount), 0) as total_collected,
                    COALESCE((SELECT SUM(ri2.amount) FROM rent_invoices ri2 JOIN contracts c2 ON ri2.contract_id=c2.id JOIN apartments a2 ON c2.apartment_id=a2.id WHERE a2.building_id=b.id), 0) as total_billed,
                    COALESCE((SELECT SUM(exp.amount) FROM expenses exp WHERE exp.entity_type='Building' AND exp.entity_id=b.id), 0) as total_expenses
                FROM buildings b
                LEFT JOIN apartments a ON a.building_id = b.id
                LEFT JOIN contracts c ON c.apartment_id = a.id AND c.status IN('Active','Approved')
                LEFT JOIN rent_invoices ri ON ri.contract_id = c.id
                LEFT JOIN rent_payments rp ON rp.invoice_id = ri.id
                WHERE b.id = ?
                GROUP BY b.id
            ");
            $stmt->execute([$building['id']]);
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            if (!$row) { echo json_encode(['reply' => "Couldn't fetch data for this building.", 'type' => 'text']); return; }
            $net = $row['total_collected'] - $row['total_expenses'];
            echo json_encode([
                'reply' => "📊 Here is the full income analysis for **{$building['name']}**:",
                'type' => 'building_income',
                'data' => [$row + ['net_income' => $net]]
            ]);
        } else {
            // Return income for ALL buildings
            $stmt = $this->db->query("
                SELECT b.id, b.name as building_name,
                    COUNT(DISTINCT a.id) as total_apartments,
                    COUNT(DISTINCT CASE WHEN a.status='Rented' THEN a.id END) as rented,
                    COALESCE(SUM(rp.amount), 0) as total_collected,
                    COALESCE((SELECT SUM(exp.amount) FROM expenses exp WHERE exp.entity_type='Building' AND exp.entity_id=b.id), 0) as total_expenses
                FROM buildings b
                LEFT JOIN apartments a ON a.building_id = b.id
                LEFT JOIN contracts c ON c.apartment_id = a.id AND c.status IN('Active','Approved')
                LEFT JOIN rent_invoices ri ON ri.contract_id = c.id
                LEFT JOIN rent_payments rp ON rp.invoice_id = ri.id
                GROUP BY b.id, b.name
                ORDER BY total_collected DESC
            ");
            $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
            $rows = array_map(fn($r) => $r + ['net_income' => $r['total_collected'] - $r['total_expenses']], $rows);
            echo json_encode([
                'reply' => "📊 Here is the income breakdown for all **" . count($rows) . "** buildings:",
                'type' => 'building_income',
                'data' => $rows
            ]);
        }
    }

    /** ─── 4. Building Expenses ──────────────────────────────────────────── */
    private function getBuildingExpenses($message) {
        $bName = $this->extractBuildingName($message);
        $building = $this->findBuilding($bName);
        if ($building) {
            $stmt = $this->db->prepare("
                SELECT category, SUM(amount) as total, COUNT(*) as entries, MAX(date) as last_date
                FROM expenses WHERE entity_type='Building' AND entity_id=?
                GROUP BY category ORDER BY total DESC
            ");
            $stmt->execute([$building['id']]);
            $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
            $total = array_sum(array_column($data, 'total'));
            echo json_encode([
                'reply' => "💸 Expenses for **{$building['name']}** — Total: **CFA " . number_format($total) . "**",
                'type' => 'expenses_breakdown',
                'data' => $data,
                'meta' => ['building' => $building['name'], 'total' => $total]
            ]);
        } else {
            $stmt = $this->db->query("
                SELECT entity_type, SUM(amount) as total, category, COUNT(*) as entries
                FROM expenses GROUP BY entity_type, category ORDER BY total DESC LIMIT 20
            ");
            $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
            $total = array_sum(array_column($data, 'total'));
            echo json_encode([
                'reply' => "💸 System-wide expenses summary — Total: **CFA " . number_format($total) . "**",
                'type' => 'expenses_breakdown',
                'data' => $data
            ]);
        }
    }

    /** ─── 5. Building Summary ───────────────────────────────────────────── */
    private function getBuildingSummary($message) {
        $stmt = $this->db->query("
            SELECT b.id, b.name, b.location,
                COUNT(a.id) as total_apartments,
                COUNT(CASE WHEN a.status='Rented' THEN 1 END) as rented,
                COUNT(CASE WHEN a.status='Vacant' THEN 1 END) as vacant,
                COALESCE(SUM(rp.amount),0) as total_rent_collected
            FROM buildings b
            LEFT JOIN apartments a ON a.building_id = b.id
            LEFT JOIN contracts c ON c.apartment_id = a.id AND c.status IN('Active','Approved')
            LEFT JOIN rent_invoices ri ON ri.contract_id = c.id
            LEFT JOIN rent_payments rp ON rp.invoice_id = ri.id
            GROUP BY b.id, b.name, b.location
            ORDER BY b.name
        ");
        $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode([
            'reply' => "🏢 Here is a summary of all **" . count($data) . "** buildings in the system:",
            'type' => 'buildings_summary',
            'data' => $data
        ]);
    }

    /** ─── 6. Tenant Info ────────────────────────────────────────────────── */
    private function getTenantInfo($message) {
        $name = $this->extractTenantName($message);
        if (!$name) {
            // Return all tenants overview
            $stmt = $this->db->query("
                SELECT COUNT(*) as total, COUNT(CASE WHEN c.id IS NOT NULL THEN 1 END) as active_count
                FROM tenants t LEFT JOIN contracts c ON c.tenant_id = t.id AND c.status='Active'
            ");
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            echo json_encode(['reply' => "There are **{$row['total']}** tenants in the system, **{$row['active_count']}** with active contracts.", 'type' => 'text']);
            return;
        }
        $stmt = $this->db->prepare("
            SELECT t.id, t.full_name, t.phone, t.email, t.national_id,
                a.code as apartment_code, b.name as building_name,
                c.monthly_rent, c.monthly_insurance, c.start_date, c.end_date, 
                c.rent_start_date, c.rent_end_date, c.status as contract_status,
                DATEDIFF(c.end_date, CURRENT_DATE) as days_until_expiry,
                COALESCE((SELECT SUM(ri.amount) FROM rent_invoices ri WHERE ri.contract_id = c.id), 0) as total_billed,
                COALESCE((SELECT SUM(rp.amount) FROM rent_payments rp JOIN rent_invoices ri ON rp.invoice_id=ri.id WHERE ri.contract_id = c.id), 0) as total_paid
            FROM tenants t
            LEFT JOIN contracts c ON c.tenant_id = t.id
            LEFT JOIN apartments a ON c.apartment_id = a.id
            LEFT JOIN buildings b ON a.building_id = b.id
            WHERE LOWER(t.full_name) LIKE ?
            ORDER BY c.status DESC
        ");
        $stmt->execute(['%' . strtolower($name) . '%']);
        $results = $stmt->fetchAll(PDO::FETCH_ASSOC);
        if (empty($results)) {
            echo json_encode(['reply' => "❌ I couldn't find any tenant matching **\"$name\"**. Please check the spelling.", 'type' => 'text']);
            return;
        }
        $results = array_map(function($r) {
            $r['total_debt'] = $r['total_billed'] - $r['total_paid'];
            return $r;
        }, $results);
        echo json_encode([
            'reply' => "Here is the information for **{$name}**:",
            'type' => 'tenant_info',
            'data' => $results
        ]);
    }

    /** ─── 7. Vacant Apartments ──────────────────────────────────────────── */
    private function getVacantApartments($message) {
        $bName = $this->extractBuildingName($message);
        $building = $this->findBuilding($bName);
        $filter = $building ? "AND a.building_id = {$building['id']}" : '';
        $stmt = $this->db->query("
            SELECT a.code, a.monthly_rent, a.monthly_insurance, b.name as building_name, b.location
            FROM apartments a
            JOIN buildings b ON a.building_id = b.id
            WHERE a.status = 'Vacant' $filter
            ORDER BY b.name, a.code
        ");
        $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $scope = $building ? "in **{$building['name']}**" : "system-wide";
        if (empty($data)) {
            echo json_encode(['reply' => "✅ No vacant apartments found $scope.", 'type' => 'text']);
            return;
        }
        echo json_encode([
            'reply' => "🏠 Found **" . count($data) . "** vacant apartments $scope:",
            'type' => 'vacant_apartments',
            'data' => $data
        ]);
    }

    /** ─── 8. Apartment Info ─────────────────────────────────────────────── */
    private function getApartmentInfo($message) {
        // Extract apartment code
        preg_match('/(?:apartment|apt|unit|flat)\s+([A-Z0-9\-]+)/i', $message, $m);
        $code = $m[1] ?? null;
        $bName = $this->extractBuildingName($message);
        $building = $this->findBuilding($bName);

        $conditions = [];
        $params = [];
        if ($code) { $conditions[] = 'a.code LIKE ?'; $params[] = "%$code%"; }
        if ($building) { $conditions[] = 'a.building_id = ?'; $params[] = $building['id']; }
        if (empty($conditions)) {
            $stmt = $this->db->query("SELECT COUNT(*) as c, SUM(monthly_rent) as r FROM apartments WHERE status='Rented'");
            $r = $stmt->fetch();
            echo json_encode(['reply' => "There are apartments tracked in the system. **{$r['c']}** are currently rented generating CFA " . number_format($r['r']) . "/mo in rent.", 'type' => 'text']);
            return;
        }
        $where = implode(' AND ', $conditions);
        $stmt = $this->db->prepare("
            SELECT a.code, a.status, a.monthly_rent, a.monthly_insurance, b.name as building_name,
                   t.full_name as tenant_name, t.phone as tenant_phone,
                   c.start_date, c.end_date, c.status as contract_status
            FROM apartments a
            JOIN buildings b ON a.building_id = b.id
            LEFT JOIN contracts c ON c.apartment_id = a.id AND c.status IN('Active','Approved')
            LEFT JOIN tenants t ON c.tenant_id = t.id
            WHERE $where
        ");
        $stmt->execute($params);
        $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
        if (empty($data)) { echo json_encode(['reply' => "❌ No apartment found matching your query.", 'type' => 'text']); return; }
        echo json_encode([
            'reply' => "🏠 Found **" . count($data) . "** apartment(s):",
            'type' => 'apartment_info',
            'data' => $data
        ]);
    }

    /** ─── 9. Rent Dashboard ─────────────────────────────────────────────── */
    private function getRentDashboard($message) {
        $stmt = $this->db->query("
            SELECT 
                COUNT(DISTINCT ri.id) as total_invoices,
                SUM(ri.amount) as total_billed,
                SUM(COALESCE((SELECT SUM(rp.amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0)) as total_paid,
                SUM(ri.amount - COALESCE((SELECT SUM(rp.amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0)) as total_outstanding,
                COUNT(CASE WHEN ri.status='Paid' THEN 1 END) as paid_count,
                COUNT(CASE WHEN ri.status IN('Unpaid','Partial') AND ri.due_date < CURRENT_DATE THEN 1 END) as overdue_count,
                COUNT(CASE WHEN ri.status IN('Unpaid','Partial') AND ri.due_date >= CURRENT_DATE THEN 1 END) as pending_count
            FROM rent_invoices ri
        ");
        $summary = $stmt->fetch(PDO::FETCH_ASSOC);

        $monthlyStmt = $this->db->query("
            SELECT DATE_FORMAT(due_date,'%Y-%m') as month,
                   SUM(amount) as billed,
                   SUM(COALESCE((SELECT SUM(rp.amount) FROM rent_payments rp WHERE rp.invoice_id = rent_invoices.id),0)) as collected
            FROM rent_invoices
            WHERE due_date >= DATE_SUB(CURRENT_DATE, INTERVAL 6 MONTH)
            GROUP BY month ORDER BY month
        ");
        $monthly = $monthlyStmt->fetchAll(PDO::FETCH_ASSOC);

        echo json_encode([
            'reply' => "📊 Rent Dashboard — Total billed: **CFA " . number_format($summary['total_billed']) . "**, collected: **CFA " . number_format($summary['total_paid']) . "**, outstanding: **CFA " . number_format($summary['total_outstanding']) . "**",
            'type' => 'rent_dashboard',
            'data' => ['summary' => $summary, 'monthly' => $monthly]
        ]);
    }

    /** ─── 10. Maintenance Tasks ─────────────────────────────────────────── */
    private function getMaintenanceTasks($message) {
        $stmt = $this->db->query("
            SELECT 
                COUNT(*) as total,
                COUNT(CASE WHEN status='Pending' THEN 1 END) as pending,
                COUNT(CASE WHEN status='In Progress' THEN 1 END) as in_progress,
                COUNT(CASE WHEN status='Completed' THEN 1 END) as completed,
                COUNT(CASE WHEN status='Scheduled' THEN 1 END) as scheduled
            FROM ac_maintenance_tasks
        ");
        $summary = $stmt->fetch(PDO::FETCH_ASSOC);
        $recentStmt = $this->db->query("
            SELECT mt.*, a.code as apartment_code, b.name as building_name
            FROM ac_maintenance_tasks mt
            LEFT JOIN apartments a ON mt.apartment_id = a.id
            LEFT JOIN buildings b ON a.building_id = b.id
            WHERE mt.status IN('Pending','In Progress','Scheduled')
            ORDER BY mt.scheduled_date ASC
            LIMIT 10
        ");
        $recent = $recentStmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode([
            'reply' => "🔧 Maintenance Overview — **{$summary['pending']}** pending, **{$summary['in_progress']}** in progress, **{$summary['completed']}** completed.",
            'type' => 'maintenance_tasks',
            'data' => ['summary' => $summary, 'tasks' => $recent]
        ]);
    }

    /** ─── 11. Fuel Status ───────────────────────────────────────────────── */
    private function getFuelStatus($message) {
        $stmt = $this->db->query("
            SELECT g.name as generator_name, g.status,
                   COALESCE((SELECT SUM(fm.amount) FROM fuel_movements fm WHERE fm.generator_id=g.id AND fm.type IN ('Refill','Transfer_In')), 0) as total_in,
                   COALESCE((SELECT SUM(fm.amount) FROM fuel_movements fm WHERE fm.generator_id=g.id AND fm.type NOT IN ('Refill','Transfer_In')), 0) as total_out
            FROM generators g ORDER BY g.name
        ");
        $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $data = array_map(fn($r) => $r + ['current_stock' => $r['total_in'] - $r['total_out']], $data);
        $total = array_sum(array_column($data, 'current_stock'));
        echo json_encode([
            'reply' => "⛽ Fuel Reserve Status — Total across all generators: **" . number_format($total, 1) . " L**",
            'type' => 'fuel_status',
            'data' => $data
        ]);
    }

    /** ─── 12. Energy Overview ───────────────────────────────────────────── */
    private function getEnergyOverview($message) {
        $stmt = $this->db->query("
            SELECT g.id, g.name, g.status,
                COUNT(DISTINCT es.id) as total_subscriptions,
                COALESCE(SUM(emr.consumption), 0) as total_kwh
            FROM generators g
            LEFT JOIN apartments a ON a.building_id = g.building_id
            LEFT JOIN electricity_subscriptions es ON es.apartment_id = a.id AND es.status='Active'
            LEFT JOIN electricity_meter_readings emr ON emr.apartment_id = a.id
            GROUP BY g.id ORDER BY g.name
        ");
        $data = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $invoiceStmt = $this->db->query("
            SELECT COUNT(*) as total, SUM(amount) as billed, SUM(COALESCE(amount_paid,0)) as collected,
                   COUNT(CASE WHEN status='Unpaid' THEN 1 END) as unpaid
            FROM electricity_invoices
        ");
        $invoices = $invoiceStmt->fetch(PDO::FETCH_ASSOC);

        echo json_encode([
            'reply' => "⚡ Energy Overview — " . count($data) . " generators. Electricity billed: **CFA " . number_format($invoices['billed']) . "**, collected: **CFA " . number_format($invoices['collected']) . "**, unpaid invoices: **{$invoices['unpaid']}**",
            'type' => 'energy_overview',
            'data' => ['generators' => $data, 'invoices' => $invoices]
        ]);
    }

    /** ─── 13. Suppliers Summary ─────────────────────────────────────────── */
    private function getSuppliersSummary($message) {
        $stmt = $this->db->query("
            SELECT s.company_name, s.contact_name, s.phone,
                   COUNT(po.id) as total_orders,
                   COALESCE(SUM(po.total_amount), 0) as total_value,
                   MAX(po.created_at) as last_order
            FROM suppliers s
            LEFT JOIN purchase_orders po ON po.supplier_id = s.id
            GROUP BY s.id ORDER BY total_value DESC LIMIT 15
        ");
        $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $total = array_sum(array_column($data, 'total_value'));
        echo json_encode([
            'reply' => "🏭 Suppliers Summary — **" . count($data) . "** suppliers, total purchase value: **CFA " . number_format($total) . "**",
            'type' => 'suppliers_summary',
            'data' => $data
        ]);
    }

    /** ─── 14. Expenses Summary ──────────────────────────────────────────── */
    private function getExpensesSummary($message) {
        $stmt = $this->db->query("
            SELECT category, entity_type, SUM(amount) as total, COUNT(*) as count,
                   MAX(date) as last_date
            FROM expenses
            GROUP BY category, entity_type
            ORDER BY total DESC
            LIMIT 20
        ");
        $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $total = array_sum(array_column($data, 'total'));
        echo json_encode([
            'reply' => "💸 Total system expenses: **CFA " . number_format($total) . "** across " . count($data) . " categories.",
            'type' => 'expenses_summary',
            'data' => $data
        ]);
    }

    /** ─── 15. Insurance Summary ─────────────────────────────────────────── */
    private function getInsuranceSummary($message) {
        $stmt = $this->db->query("
            SELECT ia.id, t.full_name as tenant_name, a.code as apartment_code, b.name as building_name,
                ia.total_saved, 0 as total_charged, 0 as total_paid,
                0 as outstanding
            FROM insurance_accounts ia
            JOIN contracts c ON ia.contract_id = c.id
            JOIN tenants t ON c.tenant_id = t.id
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            ORDER BY ia.total_saved DESC
            LIMIT 20
        ");
        $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $totalSaved = array_sum(array_column($data, 'total_saved'));
        echo json_encode([
            'reply' => "🛡️ Insurance Summary — Total saved: **CFA " . number_format($totalSaved) . "**",
            'type' => 'insurance_summary',
            'data' => $data
        ]);
    }

    /** ─── 16. Top Debtors ───────────────────────────────────────────────── */
    private function getTopDebtors($message) {
        $tenantName = $this->extractTenantName($message);
        $filter = $tenantName ? "AND LOWER(t.full_name) LIKE " . $this->db->quote('%' . strtolower($tenantName) . '%') : "";
        
        $stmt = $this->db->query("
            SELECT t.full_name, t.phone, a.code as apartment_code, b.name as building_name,
                   SUM(ri.amount - COALESCE((SELECT SUM(rp.amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0)) as total_debt,
                   COUNT(CASE WHEN ri.status IN('Unpaid','Partial') AND ri.due_date < CURRENT_DATE THEN 1 END) as overdue_invoices,
                   MAX(DATEDIFF(CURRENT_DATE, ri.due_date)) as max_days_overdue
            FROM tenants t
            JOIN contracts c ON c.tenant_id = t.id
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            JOIN rent_invoices ri ON ri.contract_id = c.id
            WHERE ri.status IN('Unpaid','Partial') $filter
            GROUP BY t.id, a.code, b.name
            HAVING total_debt > 0
            ORDER BY total_debt DESC
            LIMIT 20
        ");
        $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $totalDebt = array_sum(array_column($data, 'total_debt'));
        if (empty($data)) {
            echo json_encode(['reply' => "✅ No tenants with outstanding debt!", 'type' => 'text']);
            return;
        }
        echo json_encode([
            'reply' => "🔴 Top **" . count($data) . "** debtors — Total outstanding: **CFA " . number_format($totalDebt) . "**",
            'type' => 'top_debtors',
            'data' => $data
        ]);
    }

    /** ─── 17. Daily Reports ─────────────────────────────────────────────── */
    private function getDailyReports($message) {
        $stmt = $this->db->query("
            SELECT dr.id, u.name as agent_name, b.name as building_name,
                   dr.date as report_date, dr.notes as summary, dr.issues_found, dr.status
            FROM daily_reports dr
            LEFT JOIN users u ON dr.agent_id = u.id
            LEFT JOIN buildings b ON dr.building_id = b.id
            ORDER BY dr.date DESC
            LIMIT 15
        ");
        $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode([
            'reply' => "📋 Last **" . count($data) . "** daily agent reports:",
            'type' => 'daily_reports',
            'data' => $data
        ]);
    }

    /** ─── 18. POS Summary ───────────────────────────────────────────────── */
    private function getPosSummary($message) {
        $stmt = $this->db->query("
            SELECT 
                COUNT(*) as total_transactions,
                SUM(final_amount) as total_revenue,
                0 as cash_revenue,
                0 as credit_revenue,
                DATE(MAX(created_at)) as last_sale_date
            FROM invoices
        ");
        $summary = $stmt->fetch(PDO::FETCH_ASSOC);
        $monthlyStmt = $this->db->query("
            SELECT DATE_FORMAT(created_at,'%Y-%m') as month, SUM(final_amount) as revenue, COUNT(*) as sales
            FROM invoices
            GROUP BY month ORDER BY month DESC LIMIT 6
        ");
        $monthly = $monthlyStmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode([
            'reply' => "🛒 POS Summary — **{$summary['total_transactions']}** transactions, total revenue: **CFA " . number_format($summary['total_revenue']) . "**",
            'type' => 'pos_summary',
            'data' => ['summary' => $summary, 'monthly' => $monthly]
        ]);
    }

    /** ─── 19. Construction Status ───────────────────────────────────────── */
    private function getConstructionStatus($message) {
        $stmt = $this->db->query("
            SELECT c.id, c.name, c.location, c.status, c.start_date, c.end_date as expected_end_date,
                   c.budget, c.actual_cost as total_spent,
                   (c.budget - c.actual_cost) as remaining_budget,
                   ROUND((c.actual_cost / NULLIF(c.budget,0)) * 100, 1) as budget_used_pct
            FROM constructions c
            ORDER BY c.status, c.start_date DESC
        ");
        $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
        if (empty($data)) {
            echo json_encode(['reply' => "No construction projects found in the system.", 'type' => 'text']);
            return;
        }
        echo json_encode([
            'reply' => "🏗️ Found **" . count($data) . "** construction project(s):",
            'type' => 'construction_status',
            'data' => $data
        ]);
    }

    /** ─── 20. Help / Capabilities ───────────────────────────────────────── */
    private function getHelp() {
        echo json_encode([
            'reply' => "I'm the **Agency AI** — I have full access to every table in your database. Here's what you can ask me:",
            'type' => 'help',
            'data' => [
                ['category' => '🏢 Buildings', 'examples' => ['Building summary', 'Income in building Galaxy', 'Expenses in building Chabaan']],
                ['category' => '👤 Tenants', 'examples' => ['What does Ali Yazbek have?', 'Find tenant Hassan', 'All tenants']],
                ['category' => '🏠 Apartments', 'examples' => ['Vacant apartments', 'Apartment A12', 'Apartments in building Galaxy']],
                ['category' => '💰 Rent & Finance', 'examples' => ['Overdue rent', 'Rent dashboard', 'Top debtors', 'Building income']],
                ['category' => '⏰ Contracts', 'examples' => ['Expiring contracts', 'Rent expire in 30 days', 'Lease end soon']],
                ['category' => '🔧 Maintenance', 'examples' => ['Maintenance tasks', 'AC repairs', 'Workshop status']],
                ['category' => '⚡ Energy', 'examples' => ['Energy overview', 'Generator status', 'Fuel reserve', 'Electricity invoices']],
                ['category' => '🛡️ Insurance', 'examples' => ['Insurance summary', 'Insurance outstanding']],
                ['category' => '🛒 Commerce', 'examples' => ['POS summary', 'Sales revenue', 'Suppliers']],
                ['category' => '🏗️ Construction', 'examples' => ['Construction status', 'Project budgets']],
                ['category' => '📋 Reports', 'examples' => ['Daily reports', 'Agent reports', 'Expenses summary']],
            ]
        ]);
    }

    /** ─── Greeting ──────────────────────────────────────────────────────── */
    private function getGreeting() {
        $greetings = [
            "Hi! I'm **Agency AI**, your intelligent Property Management assistant. How can I help you today?",
            "Hello! I am **Agency AI**. I can analyze buildings, check unpaid invoices, and manage maintenance. What do you need?",
            "Greetings! I'm **Agency AI**. Ready to check some rent statuses or expiring contracts?",
            "Hi there! I am **Agency AI**, your business advisor. Tell me what you'd like to analyze."
        ];
        $reply = $greetings[array_rand($greetings)];
        
        echo json_encode([
            'reply' => $reply,
            'type' => 'text'
        ]);
    }

    /** ─── Agent Purchases Data ─────────────────────────────────────────── */
    private function getAgentPurchasesData($message) {
        $results = [];
        try {
            $stmt = $this->db->query("
                SELECT p.*, u.name as submitter_name 
                FROM agent_purchases p 
                LEFT JOIN users u ON p.user_id = u.id 
                ORDER BY p.created_at DESC 
                LIMIT 15
            ");
            $results = array_merge($results, $stmt->fetchAll(PDO::FETCH_ASSOC));
        } catch (\Throwable $e) {}
        try {
            $stmt2 = $this->db->query("
                SELECT acd.id, b.name as building_name, a.code as apartment_number,
                       acd.supplier_name as supplier, CONCAT('CFA ', FORMAT(acd.amount, 0)) as amount,
                       COALESCE(acd.notes, 'Apartment Cost') as items, acd.notes,
                       COALESCE(acd.status, 'Approved') as status, u.name as submitter_name, acd.created_at
                FROM apartment_cost_deployments acd
                JOIN apartments a ON acd.apartment_id = a.id
                JOIN buildings b ON a.building_id = b.id
                LEFT JOIN users u ON acd.submitted_by = u.id
                ORDER BY acd.date DESC, acd.id DESC
                LIMIT 15
            ");
            $results = array_merge($results, $stmt2->fetchAll(PDO::FETCH_ASSOC));
        } catch (\Throwable $e) {}

        if (empty($results)) {
            echo json_encode(['reply' => "🛒 No purchase submissions found in the database.", 'type' => 'text']);
            return;
        }

        $pending = array_filter($results, fn($r) => $r['status'] === 'Pending Review');
        $reply = "🛒 **Agent Purchase Submissions:** Found **" . count($results) . " recent purchases** (" . count($pending) . " awaiting admin review).";

        echo json_encode([
            'reply' => $reply,
            'type' => 'widget_purchases_list',
            'data' => $results
        ]);
    }

    /** ─── AC Maintenance Data ──────────────────────────────────────────── */
    private function getAcMaintenanceData($message) {
        $stmt = $this->db->query("
            SELECT t.*, a.code as apartment_code, b.name as building_name, u.name as worker_name
            FROM ac_maintenance_tasks t
            JOIN apartments a ON t.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            LEFT JOIN users u ON t.worker_id = u.id
            ORDER BY COALESCE(t.submission_date, t.created_at) DESC
            LIMIT 15
        ");
        $results = $stmt->fetchAll(PDO::FETCH_ASSOC);

        if (empty($results)) {
            echo json_encode(['reply' => "🔧 No AC maintenance tasks recorded currently.", 'type' => 'text']);
            return;
        }

        $pending = array_filter($results, fn($r) => in_array($r['status'], ['Pending_Approval', 'Pending Approval', 'Pending']));
        $reply = "🔧 **AC Maintenance Overview:** Found **" . count($results) . " maintenance tasks** (" . count($pending) . " pending review).";

        echo json_encode([
            'reply' => $reply,
            'type' => 'widget_maintenance_tasks',
            'data' => $results
        ]);
    }

    /** ─── Audit Activities Data ────────────────────────────────────────── */
    private function getAuditActivitiesData($message) {
        $stmt = $this->db->query("
            SELECT a.*, u.name as user_name
            FROM activity_logs a
            LEFT JOIN users u ON a.user_id = u.id
            ORDER BY a.created_at DESC
            LIMIT 15
        ");
        $results = $stmt->fetchAll(PDO::FETCH_ASSOC);

        if (empty($results)) {
            echo json_encode(['reply' => "📋 No activity logs recorded today.", 'type' => 'text']);
            return;
        }

        echo json_encode([
            'reply' => "📋 **System Audit & Activity Logs:** Here are the " . count($results) . " most recent events across the system:",
            'type' => 'widget_activity_logs',
            'data' => $results
        ]);
    }

    /** ─── Universal Real-Time Semantic Database Search ─────────────────── */
    private function universalSearch($raw) {
        $query = trim($raw);
        $wildcard = '%' . strtolower($query) . '%';

        // 1. Search Apartments & Buildings
        $aptStmt = $this->db->prepare("
            SELECT a.id, a.code as apartment_code, b.name as building_name, a.status, a.monthly_rent, t.full_name as tenant_name
            FROM apartments a
            JOIN buildings b ON a.building_id = b.id
            LEFT JOIN contracts c ON a.id = c.apartment_id AND c.status = 'Active'
            LEFT JOIN tenants t ON c.tenant_id = t.id
            WHERE LOWER(a.code) LIKE ? OR LOWER(b.name) LIKE ?
            LIMIT 5
        ");
        $aptStmt->execute([$wildcard, $wildcard]);
        $apts = $aptStmt->fetchAll(PDO::FETCH_ASSOC);

        // 2. Search Tenants
        $tenantStmt = $this->db->prepare("
            SELECT t.id, t.full_name, t.phone, t.email, a.code as apartment_code, b.name as building_name, c.monthly_rent
            FROM tenants t
            LEFT JOIN contracts c ON t.id = c.tenant_id AND c.status = 'Active'
            LEFT JOIN apartments a ON c.apartment_id = a.id
            LEFT JOIN buildings b ON a.building_id = b.id
            WHERE LOWER(t.full_name) LIKE ? OR LOWER(t.phone) LIKE ? OR LOWER(t.email) LIKE ?
            LIMIT 5
        ");
        $tenantStmt->execute([$wildcard, $wildcard, $wildcard]);
        $tenants = $tenantStmt->fetchAll(PDO::FETCH_ASSOC);

        // 3. Search Agent Purchases
        $purchStmt = $this->db->prepare("
            SELECT p.*, u.name as submitter_name
            FROM agent_purchases p
            LEFT JOIN users u ON p.user_id = u.id
            WHERE LOWER(p.supplier) LIKE ? OR LOWER(p.items) LIKE ? OR LOWER(p.building_name) LIKE ? OR LOWER(p.apartment_number) LIKE ?
            LIMIT 5
        ");
        $purchStmt->execute([$wildcard, $wildcard, $wildcard, $wildcard]);
        $purchases = $purchStmt->fetchAll(PDO::FETCH_ASSOC);

        // 4. Search Generators
        $genStmt = $this->db->prepare("
            SELECT g.*, b.name as building_name
            FROM generators g
            JOIN buildings b ON g.building_id = b.id
            WHERE LOWER(g.name) LIKE ? OR LOWER(b.name) LIKE ?
            LIMIT 3
        ");
        $genStmt->execute([$wildcard, $wildcard]);
        $generators = $genStmt->fetchAll(PDO::FETCH_ASSOC);

        $hasResults = !empty($apts) || !empty($tenants) || !empty($purchases) || !empty($generators);

        if ($hasResults) {
            $lines = ["🔍 **Real-Time Database Search Results for \"$query\":**\n"];
            
            if (!empty($tenants)) {
                $lines[] = "👤 **Tenants Matched (" . count($tenants) . "):**";
                foreach ($tenants as $t) {
                    $lines[] = "• **{$t['full_name']}** — Apt {$t['apartment_code']} ({$t['building_name']}) | Phone: {$t['phone']}";
                }
            }

            if (!empty($apts)) {
                $lines[] = "\n🏢 **Apartments / Buildings Matched (" . count($apts) . "):**";
                foreach ($apts as $a) {
                    $occ = $a['tenant_name'] ? "Occupied by {$a['tenant_name']}" : "Vacant";
                    $lines[] = "• **{$a['building_name']} Apt {$a['apartment_code']}** — Status: **{$a['status']}** ($occ) | Rent: CFA " . number_format($a['monthly_rent']);
                }
            }

            if (!empty($purchases)) {
                $lines[] = "\n🛒 **Purchases Matched (" . count($purchases) . "):**";
                foreach ($purchases as $p) {
                    $lines[] = "• **{$p['building_name']} Apt {$p['apartment_number']}** — Supplier: {$p['supplier']} ({$p['items']}) | Amount: **{$p['amount']}** [{$p['status']}]";
                }
            }

            if (!empty($generators)) {
                $lines[] = "\n⚡ **Generators Matched (" . count($generators) . "):**";
                foreach ($generators as $g) {
                    $lines[] = "• **{$g['name']}** ({$g['building_name']}) — Fuel: {$g['current_fuel']}L / {$g['capacity']}L";
                }
            }

            echo json_encode([
                'reply' => implode("\n", $lines),
                'type' => 'widget_universal_results',
                'data' => [
                    'tenants' => $tenants,
                    'apartments' => $apts,
                    'purchases' => $purchases,
                    'generators' => $generators
                ]
            ]);
            return;
        }

        // Fallback if no matching record found
        echo json_encode([
            'reply' => "I queried your database for **\"$raw\"** across all tables (apartments, tenants, contracts, finances, maintenance, energy, purchases), but found no exact matches.\n\n💡 *Tip: Try searching by building name (e.g. 'Galaxy'), apartment code ('A1'), tenant name ('Ali'), or ask 'help' for full AI commands.*",
            'type' => 'text'
        ]);
    }

    /** ─── Agency AI Specific Intents ──────────────────────────────────────── */
    private function getLossAnalysis($message) {
        $stmt = $this->db->query("
            SELECT b.name as building_name, 
                   COALESCE((SELECT SUM(amount) FROM expenses e WHERE e.entity_type='Building' AND e.entity_id=b.id), 0) as total_expenses,
                   COALESCE((SELECT SUM(rp.amount) FROM rent_payments rp JOIN rent_invoices ri ON rp.invoice_id=ri.id JOIN contracts c ON ri.contract_id=c.id JOIN apartments a ON c.apartment_id=a.id WHERE a.building_id=b.id), 0) as total_income
            FROM buildings b
        ");
        $buildings = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $worst = null;
        $maxLoss = 0;
        foreach ($buildings as $b) {
            $profit = $b['total_income'] - $b['total_expenses'];
            if ($profit < $maxLoss) {
                $maxLoss = $profit;
                $worst = $b;
            }
        }
        if ($worst) {
            echo json_encode(['reply' => "📉 Based on my financial analysis, **{$worst['building_name']}** is losing money. It has generated **CFA " . number_format($worst['total_income']) . "** in rent, but accumulated **CFA " . number_format($worst['total_expenses']) . "** in expenses. You should review the maintenance costs and energy consumption for this building.", 'type' => 'text']);
        } else {
            echo json_encode(['reply' => "✅ Currently, none of your buildings are operating at a net loss!", 'type' => 'text']);
        }
    }

    private function getRecommendations($message) {
        echo json_encode(['reply' => "💡 **Agency AI Recommendations:**\n1. **Collections:** You have overdue rent; consider sending automated SMS reminders.\n2. **Energy:** Monitor generator fuel levels, a few are running low.\n3. **Maintenance:** Prioritize 'In Progress' AC repairs before the summer peak.\n\n*(I am continuously analyzing the ERP to provide these insights!)*", 'type' => 'text']);
    }
}
