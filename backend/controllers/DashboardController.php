<?php
class DashboardController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function financialSummary() {
        AuthMiddleware::requireLogin();
        
        $stats = [
            'total_rent_due' => 0,
            'total_rent_collected' => 0,
            'outstanding_rent_balance' => 0,
            'unpaid_rent_invoices' => 0,
            'insurance_collected' => 0,
            'electricity_collected' => 0,
            'generator_collected' => 0
        ];

        // Total Rent Due (Current Month)
        $stmt = $this->db->query("SELECT SUM(amount) FROM rent_invoices WHERE MONTH(due_date) = MONTH(CURRENT_DATE()) AND YEAR(due_date) = YEAR(CURRENT_DATE())");
        $stats['total_rent_due'] = $stmt->fetchColumn() ?? 0;

        // Total Rent Collected (Current Month)
        $stmt = $this->db->query("SELECT SUM(amount) FROM rent_payments WHERE MONTH(date) = MONTH(CURRENT_DATE()) AND YEAR(date) = YEAR(CURRENT_DATE())");
        $stats['total_rent_collected'] = $stmt->fetchColumn() ?? 0;

        // Outstanding Rent Balance
        $stmt = $this->db->query("
            SELECT SUM(ri.amount - COALESCE((SELECT SUM(amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0)) 
            FROM rent_invoices ri 
            WHERE ri.status IN ('Unpaid', 'Partial', 'Overdue')
        ");
        $stats['outstanding_rent_balance'] = $stmt->fetchColumn() ?? 0;

        // Unpaid Rent Invoices
        $stmt = $this->db->query("SELECT COUNT(*) FROM rent_invoices WHERE status IN ('Unpaid', 'Partial', 'Overdue')");
        $stats['unpaid_rent_invoices'] = $stmt->fetchColumn() ?? 0;

        // Insurance Collected (Current Month)
        $stmt = $this->db->query("SELECT SUM(amount) FROM insurance_transactions WHERE type = 'Deposit' AND MONTH(date) = MONTH(CURRENT_DATE()) AND YEAR(date) = YEAR(CURRENT_DATE())");
        $stats['insurance_collected'] = $stmt->fetchColumn() ?? 0;

        // Electricity Subscriptions Collected (Current Month)
        $stmt = $this->db->query("
            SELECT SUM(amount_paid) FROM electricity_invoices 
            WHERE MONTH(due_date) = MONTH(CURRENT_DATE()) AND YEAR(due_date) = YEAR(CURRENT_DATE())
        ");
        $stats['electricity_collected'] = $stmt->fetchColumn() ?? 0;

        // Generator Subscriptions Collected (Current Month)
        $stmt = $this->db->query("SELECT SUM(amount) FROM expenses WHERE entity_type = 'generator' AND MONTH(date) = MONTH(CURRENT_DATE()) AND YEAR(date) = YEAR(CURRENT_DATE())");
        $stats['generator_collected'] = $stmt->fetchColumn() ?? 0;

        echo json_encode($stats);
    }

    public function collections() {
        AuthMiddleware::requireLogin();
        
        $stats = ['payment_methods_breakdown' => []];

        // Payment Methods Breakdown (Today)
        $stmt = $this->db->query("
            SELECT ri.payment_method, SUM(rp.amount) as total 
            FROM rent_payments rp 
            JOIN rent_invoices ri ON rp.invoice_id = ri.id 
            WHERE rp.date = CURRENT_DATE() 
            GROUP BY ri.payment_method
        ");
        $stats['payment_methods_breakdown'] = $stmt->fetchAll(PDO::FETCH_ASSOC);

        echo json_encode($stats);
    }

    public function alerts() {
        AuthMiddleware::requireLogin();
        
        $stats = ['alerts' => []];

        // Contracts expiring in <= 30 days
        $stmt = $this->db->query("
            SELECT c.id, c.tenant_id, t.full_name as tenant_name, a.id as apartment_id, a.code as apartment_number, b.name as building_name, c.end_date as due_date, DATEDIFF(c.end_date, CURRENT_DATE()) as remaining_days
            FROM contracts c
            JOIN tenants t ON c.tenant_id = t.id
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE c.status IN ('Active', 'Expired') 
            AND c.end_date <= DATE_ADD(CURRENT_DATE(), INTERVAL 30 DAY)
            AND c.id = (
                SELECT MAX(c2.id) 
                FROM contracts c2 
                WHERE c2.apartment_id = c.apartment_id 
                AND c2.status NOT IN ('Draft', 'Rejected', 'Void')
            )
        ");
        foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
            $stats['alerts'][] = [
                'id' => 'contract_' . $row['id'],
                'type' => 'alert',
                'category' => 'Contracts',
                'priority' => $row['remaining_days'] < 0 ? 'Critical' : ($row['remaining_days'] <= 10 ? 'Warning' : 'Information'),
                'apartment_id' => $row['apartment_id'],
                'apartment_number' => $row['apartment_number'],
                'tenant_id' => $row['tenant_id'],
                'tenant_name' => $row['tenant_name'],
                'related_record_id' => $row['id'],
                'action_url' => "/tenants/" . $row['tenant_id'],
                'remaining_days' => $row['remaining_days'],
                'title' => 'Contract Expiring',
                'message' => "Contract for {$row['tenant_name']} (Apt {$row['apartment_number']}) " . ($row['remaining_days'] < 0 ? "expired " . abs($row['remaining_days']) . " days ago" : "expires in {$row['remaining_days']} days"),
            ];
        }

        // Electricity subscriptions expiring soon
        $stmt = $this->db->query("
            SELECT es.id, a.id as apartment_id, a.code as apartment_number, b.name as building_name, 
                   (SELECT t.id FROM contracts c JOIN tenants t ON c.tenant_id = t.id WHERE c.apartment_id = a.id AND c.status = 'Active' ORDER BY c.id DESC LIMIT 1) as tenant_id, 
                   (SELECT t.full_name FROM contracts c JOIN tenants t ON c.tenant_id = t.id WHERE c.apartment_id = a.id AND c.status = 'Active' ORDER BY c.id DESC LIMIT 1) as tenant_name, 
                   es.end_date as due_date, DATEDIFF(es.end_date, CURRENT_DATE()) as remaining_days
            FROM electricity_subscriptions es
            JOIN apartments a ON es.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE es.status = 'Active' 
            AND es.end_date <= DATE_ADD(CURRENT_DATE(), INTERVAL 30 DAY)
        ");
        foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
            $stats['alerts'][] = [
                'id' => 'elec_sub_' . $row['id'],
                'type' => 'alert',
                'category' => 'Electricity',
                'priority' => $row['remaining_days'] < 0 ? 'Critical' : ($row['remaining_days'] <= 10 ? 'Warning' : 'Information'),
                'apartment_id' => $row['apartment_id'],
                'apartment_number' => $row['apartment_number'],
                'tenant_id' => $row['tenant_id'],
                'tenant_name' => $row['tenant_name'] ?: 'No Active Tenant',
                'related_record_id' => $row['id'],
                'action_url' => "/apartments/{$row['apartment_id']}/electricity",
                'remaining_days' => $row['remaining_days'],
                'title' => 'Electricity Subscription',
                'message' => "Electricity sub for Apt {$row['apartment_number']} " . ($row['remaining_days'] < 0 ? "expired " . abs($row['remaining_days']) . " days ago" : "expires in {$row['remaining_days']} days"),
            ];
        }

        // Pending Electricity Invoices (Unpaid/Partially Paid)
        $stmt = $this->db->query("
            SELECT ei.id, a.id as apartment_id, a.code as apartment_number, b.name as building_name, 
                   (SELECT t.id FROM contracts c JOIN tenants t ON c.tenant_id = t.id WHERE c.apartment_id = a.id AND c.status = 'Active' ORDER BY c.id DESC LIMIT 1) as tenant_id, 
                   (SELECT t.full_name FROM contracts c JOIN tenants t ON c.tenant_id = t.id WHERE c.apartment_id = a.id AND c.status = 'Active' ORDER BY c.id DESC LIMIT 1) as tenant_name, 
                   ei.amount, COALESCE(ei.amount_paid, 0) as amount_paid, ei.due_date, DATEDIFF(CURRENT_DATE(), ei.due_date) as overdue_days
            FROM electricity_invoices ei
            JOIN apartments a ON ei.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE ei.status IN ('Unpaid', 'Partially Paid')
        ");
        foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
            $balance = $row['amount'] - $row['amount_paid'];
            $stats['alerts'][] = [
                'id' => 'elec_inv_' . $row['id'],
                'type' => 'alert',
                'category' => 'Electricity',
                'priority' => $row['overdue_days'] > 0 ? 'Critical' : 'Warning',
                'apartment_id' => $row['apartment_id'],
                'apartment_number' => $row['apartment_number'],
                'tenant_id' => $row['tenant_id'],
                'tenant_name' => $row['tenant_name'] ?: 'No Active Tenant',
                'related_record_id' => $row['id'],
                'action_url' => "/apartments/{$row['apartment_id']}/electricity",
                'remaining_days' => -$row['overdue_days'],
                'title' => 'Unpaid Electricity',
                'message' => "Unpaid invoice of CFA {$balance} for Apt {$row['apartment_number']}" . ($row['overdue_days'] > 0 ? " (Overdue {$row['overdue_days']} days)" : ""),
            ];
        }

        // Rent due soon or Overdue rent
        $stmt = $this->db->query("
            SELECT ri.id, a.id as apartment_id, a.code as apartment_number, b.name as building_name, t.id as tenant_id, t.full_name as tenant_name, ri.amount, (ri.amount - COALESCE((SELECT SUM(amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0)) as balance, ri.due_date, DATEDIFF(CURRENT_DATE(), ri.due_date) as overdue_days
            FROM rent_invoices ri
            JOIN contracts c ON ri.contract_id = c.id
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            JOIN tenants t ON c.tenant_id = t.id
            WHERE ri.status IN ('Unpaid', 'Partial', 'Overdue')
            AND (ri.amount - COALESCE((SELECT SUM(amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0)) > 0
        ");
        foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
            $isOverdue = $row['overdue_days'] > 0;
            if ($isOverdue || $row['overdue_days'] >= -7) {
                $stats['alerts'][] = [
                    'id' => 'rent_inv_' . $row['id'],
                    'type' => 'alert',
                    'category' => 'Rent',
                    'priority' => $isOverdue ? 'Critical' : 'Warning',
                    'apartment_id' => $row['apartment_id'],
                    'apartment_number' => $row['apartment_number'],
                    'tenant_id' => $row['tenant_id'],
                    'tenant_name' => $row['tenant_name'],
                    'related_record_id' => $row['id'],
                    'action_url' => "/rent-hub?search=" . urlencode($row['apartment_number']),
                    'remaining_days' => -$row['overdue_days'],
                    'title' => $isOverdue ? 'Overdue Rent' : 'Rent Due Soon',
                    'message' => "Rent balance of CFA {$row['balance']} for {$row['tenant_name']} (Apt {$row['apartment_number']}) " . ($isOverdue ? "is overdue by {$row['overdue_days']} days" : "is due in " . abs($row['overdue_days']) . " days"),
                ];
            }
        }
        
        // Rent Profiles awaiting renewal or paused
        $stmtProf = $this->db->query("
            SELECT rp.id, rp.tenant_id, rp.apartment_id, rp.next_billing_date, rp.status, rp.auto_renewal, a.code as apartment_number, t.full_name as tenant_name, DATEDIFF(CURRENT_DATE(), rp.next_billing_date) as overdue_days
            FROM rent_profiles rp
            JOIN apartments a ON rp.apartment_id = a.id
            JOIN tenants t ON rp.tenant_id = t.id
            WHERE rp.status IN ('Active', 'Paused')
        ");
        foreach ($stmtProf->fetchAll(PDO::FETCH_ASSOC) as $row) {
            if ($row['status'] === 'Paused') {
                $stats['alerts'][] = [
                    'id' => 'rent_prof_p_' . $row['id'],
                    'type' => 'alert',
                    'category' => 'Rent',
                    'priority' => 'Information',
                    'apartment_id' => $row['apartment_id'],
                    'apartment_number' => $row['apartment_number'],
                    'tenant_id' => $row['tenant_id'],
                    'tenant_name' => $row['tenant_name'],
                    'related_record_id' => $row['id'],
                    'action_url' => "/tenants/{$row['tenant_id']}",
                    'remaining_days' => 0,
                    'title' => 'Rent Paused',
                    'message' => "Rent billing is currently paused for Apt {$row['apartment_number']}",
                ];
            } else if ($row['status'] === 'Active' && $row['overdue_days'] >= 0) { // next_billing_date <= today
                $renewalType = $row['auto_renewal'] ? 'Auto Renewal Enabled' : 'Manual Renewal Required';
                $priority = $row['auto_renewal'] ? 'Information' : 'Warning';
                $stats['alerts'][] = [
                    'id' => 'rent_prof_r_' . $row['id'],
                    'type' => 'alert',
                    'category' => 'Rent',
                    'priority' => $priority,
                    'apartment_id' => $row['apartment_id'],
                    'apartment_number' => $row['apartment_number'],
                    'tenant_id' => $row['tenant_id'],
                    'tenant_name' => $row['tenant_name'],
                    'related_record_id' => $row['id'],
                    'action_url' => "/tenants/{$row['tenant_id']}",
                    'remaining_days' => -$row['overdue_days'],
                    'title' => 'Rent Renewal Due',
                    'message' => "Rent period ended for Apt {$row['apartment_number']} ({$renewalType})",
                ];
            }
        }
        
        // Pending insurance payments
        $stmt = $this->db->query("
            SELECT ia.id, ia.contract_id, ia.total_saved, a.id as apartment_id, a.code as apartment_number, b.name as building_name, t.id as tenant_id, t.full_name as tenant_name, c.monthly_insurance
            FROM insurance_accounts ia
            JOIN contracts c ON ia.contract_id = c.id
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            JOIN tenants t ON c.tenant_id = t.id
            WHERE c.status = 'Active' AND ia.total_saved < c.monthly_insurance
        ");
        foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
            $deficit = $row['monthly_insurance'] - $row['total_saved'];
            if ($deficit > 0) {
                $stats['alerts'][] = [
                    'id' => 'ins_acc_' . $row['id'],
                    'type' => 'alert',
                    'category' => 'Insurance',
                    'priority' => 'Warning',
                    'apartment_id' => $row['apartment_id'],
                    'apartment_number' => $row['apartment_number'],
                    'tenant_id' => $row['tenant_id'],
                    'tenant_name' => $row['tenant_name'],
                    'related_record_id' => $row['id'],
                    'action_url' => "/rent-hub?search=" . urlencode($row['apartment_number']),
                    'remaining_days' => 0,
                    'title' => 'Pending Insurance',
                    'message' => "Pending deposit of CFA {$deficit} for {$row['tenant_name']} (Apt {$row['apartment_number']})",
                ];
            }
        }

        echo json_encode($stats);
    }

    public function expiringItems() {
        AuthMiddleware::requireLogin();
        
        $expiring = [];

        // Contracts expiring in <= 30 days or overdue (status Active or Expired)
        // Ignoring terminated/rejected ones.
        $stmt = $this->db->query("
            SELECT 
                c.id, 'Contract' as type, t.full_name as name, a.code as apartment_code, b.name as building_name, 
                c.end_date as due_date, DATEDIFF(c.end_date, CURRENT_DATE()) as days_left,
                a.id as apartment_id, t.id as tenant_id
            FROM contracts c
            JOIN tenants t ON c.tenant_id = t.id
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE c.status IN ('Active', 'Expired') 
            AND c.end_date <= DATE_ADD(CURRENT_DATE(), INTERVAL 30 DAY)
            AND NOT EXISTS (
                SELECT 1 FROM contracts c2 
                WHERE c2.apartment_id = c.apartment_id 
                AND c2.id > c.id 
                AND c2.status = 'Active'
            )
        ");
        $contracts = $stmt->fetchAll(PDO::FETCH_ASSOC);
        foreach ($contracts as $c) {
            $expiring[] = $c;
        }

        // Subscriptions expiring in <= 30 days or overdue
        $stmt = $this->db->query("
            SELECT 
                es.id, 'Subscription' as type, 'Electricity/Generator' as name, a.code as apartment_code, b.name as building_name, 
                es.end_date as due_date, DATEDIFF(es.end_date, CURRENT_DATE()) as days_left,
                a.id as apartment_id
            FROM electricity_subscriptions es
            JOIN apartments a ON es.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE es.status = 'Active' 
            AND es.end_date <= DATE_ADD(CURRENT_DATE(), INTERVAL 30 DAY)
        ");
        $subscriptions = $stmt->fetchAll(PDO::FETCH_ASSOC);
        foreach ($subscriptions as $s) {
            $expiring[] = $s;
        }

        // AC Maintenance tasks scheduled in <= 30 days or overdue
        $stmt = $this->db->query("
            SELECT 
                mt.id, 'Maintenance' as type, 'AC Maintenance' as name, a.code as apartment_code, b.name as building_name, 
                mt.scheduled_date as due_date, DATEDIFF(mt.scheduled_date, CURRENT_DATE()) as days_left,
                a.id as apartment_id
            FROM ac_maintenance_tasks mt
            JOIN apartments a ON mt.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE mt.status = 'Scheduled' 
            AND mt.scheduled_date <= DATE_ADD(CURRENT_DATE(), INTERVAL 30 DAY)
        ");
        $tasks = $stmt->fetchAll(PDO::FETCH_ASSOC);
        foreach ($tasks as $t) {
            $expiring[] = $t;
        }

        // Sort by priority: overdue first (most recently expired to oldest), then future (soonest to expire)
        usort($expiring, function($a, $b) {
            $aOverdue = $a['days_left'] < 0;
            $bOverdue = $b['days_left'] < 0;
            
            if ($aOverdue && $bOverdue) {
                return $b['days_left'] - $a['days_left']; // Descending for overdue (e.g. -14 before -27)
            }
            if (!$aOverdue && !$bOverdue) {
                return $a['days_left'] - $b['days_left']; // Ascending for future (e.g. 1 before 10)
            }
            return $aOverdue ? -1 : 1; // Overdue items always come first
        });

        echo json_encode($expiring);
    }
    public function managerStats() {
        AuthMiddleware::requireLogin();
        $stats = [
            'monthly_income' => 0,
            'occupancy_rate' => 0,
            'apartment_expenses' => 0,
            'contracts_ending_soon' => 0
        ];

        // Monthly Income
        $stmt = $this->db->query("SELECT SUM(amount) FROM rent_payments WHERE MONTH(date) = MONTH(CURRENT_DATE()) AND YEAR(date) = YEAR(CURRENT_DATE())");
        $stats['monthly_income'] = $stmt->fetchColumn() ?? 0;

        // Occupancy Rate
        $totalApts = $this->db->query("SELECT COUNT(*) FROM apartments")->fetchColumn();
        $occupiedApts = $this->db->query("SELECT COUNT(DISTINCT apartment_id) FROM contracts WHERE status = 'Active'")->fetchColumn();
        $stats['occupancy_rate'] = $totalApts > 0 ? round(($occupiedApts / $totalApts) * 100) : 0;

        // Apartment Expenses
        $stmt = $this->db->query("SELECT SUM(amount) FROM expenses WHERE entity_type = 'apartment' AND MONTH(date) = MONTH(CURRENT_DATE()) AND YEAR(date) = YEAR(CURRENT_DATE())");
        $stats['apartment_expenses'] = $stmt->fetchColumn() ?? 0;

        // Contracts Ending Soon (30 days)
        $stmt = $this->db->query("SELECT COUNT(*) FROM contracts WHERE status IN ('Active', 'Expired') AND end_date <= DATE_ADD(CURRENT_DATE(), INTERVAL 30 DAY)");
        $stats['contracts_ending_soon'] = $stmt->fetchColumn() ?? 0;

        echo json_encode($stats);
    }

    public function cashierStats() {
        AuthMiddleware::requireLogin();
        $stats = [
            'todays_sales' => 0,
            'pending_payments' => 0
        ];

        // Today's Sales (from rent, POS could be separate, but let's take rent_payments today)
        $stmt = $this->db->query("SELECT SUM(amount) FROM rent_payments WHERE date = CURRENT_DATE()");
        $stats['todays_sales'] = $stmt->fetchColumn() ?? 0;

        // Pending Payments (Unpaid invoices)
        $stmt = $this->db->query("SELECT SUM(amount - COALESCE((SELECT SUM(amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0)) FROM rent_invoices ri WHERE ri.status IN ('Unpaid', 'Partial', 'Overdue')");
        $stats['pending_payments'] = $stmt->fetchColumn() ?? 0;

        echo json_encode($stats);
    }
    public function getExecutiveMetrics() {
        AuthMiddleware::requireLogin();
        try {
            // 1. Revenue Today (From Journal Entries where Credit is Rental Revenue 4000)
            $stmt = $this->db->query("
                SELECT COALESCE(SUM(amount), 0) as revenue_today 
                FROM journal_entries 
                WHERE credit_account_id = (SELECT id FROM accounts WHERE code = '4000') 
                AND date = CURDATE()
            ");
            $revenueToday = $stmt->fetchColumn();

            // 2. Expected Revenue (Sum of Unpaid Invoices)
            $stmt = $this->db->query("
                SELECT COALESCE(SUM(amount - (SELECT COALESCE(SUM(amount_paid),0) FROM rent_payments WHERE invoice_id = rent_invoices.id)), 0) 
                FROM rent_invoices WHERE status != 'Paid'
            ");
            $expectedRevenue = $stmt->fetchColumn();

            // 3. Occupancy %
            $stmt = $this->db->query("SELECT COUNT(*) FROM apartments WHERE deleted_at IS NULL");
            $totalApartments = $stmt->fetchColumn();
            
            $stmt = $this->db->query("SELECT COUNT(DISTINCT apartment_id) FROM contracts WHERE status = 'Active' AND deleted_at IS NULL");
            $occupiedApartments = $stmt->fetchColumn();
            
            $occupancyRate = $totalApartments > 0 ? round(($occupiedApartments / $totalApartments) * 100, 2) : 0;

            // 4. Overdue Rent Total
            $stmt = $this->db->query("
                SELECT COALESCE(SUM(amount - (SELECT COALESCE(SUM(amount_paid),0) FROM rent_payments WHERE invoice_id = rent_invoices.id)), 0) 
                FROM rent_invoices WHERE status = 'Overdue'
            ");
            $overdueRent = $stmt->fetchColumn();

            // 5. Employee Productivity Ranking
            $stmt = $this->db->query("
                SELECT 
                    u.id, u.full_name, u.role,
                    COUNT(t.id) as total_assigned,
                    SUM(CASE WHEN t.status = 'Completed' THEN 1 ELSE 0 END) as total_completed,
                    SUM(CASE WHEN t.status = 'Completed' AND DATE(t.updated_at) > t.due_date THEN 1 ELSE 0 END) as late_completions
                FROM users u
                LEFT JOIN tasks t ON t.assigned_to = u.id AND DATE(t.created_at) = CURDATE()
                GROUP BY u.id, u.full_name, u.role
                HAVING total_assigned > 0
            ");
            $employees = $stmt->fetchAll(PDO::FETCH_ASSOC);

            foreach ($employees as &$emp) {
                $productivity = $emp['total_assigned'] > 0 ? round(($emp['total_completed'] / $emp['total_assigned']) * 100) : 0;
                $emp['productivity'] = $productivity;
            }

            echo json_encode([
                'status' => 'success',
                'data' => [
                    'revenue_today' => $revenueToday,
                    'expected_revenue' => $expectedRevenue,
                    'occupancy_rate' => $occupancyRate,
                    'vacant_apartments' => $totalApartments - $occupiedApartments,
                    'overdue_rent' => $overdueRent,
                    'employee_rankings' => $employees
                ]
            ]);
        } catch (Exception $e) {
            echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
            http_response_code(500);
        }
    }
}
