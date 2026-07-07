<?php

class ScheduleController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function getSummary() {
        AuthMiddleware::requireLogin();

        // Rent Queries
        $rentDueToday = $this->db->query("SELECT COUNT(*) FROM rent_invoices WHERE due_date = CURRENT_DATE() AND status != 'Paid'")->fetchColumn();
        $rentOverdue = $this->db->query("SELECT COUNT(*) FROM rent_invoices WHERE due_date < CURRENT_DATE() AND status != 'Paid'")->fetchColumn();
        $rentUpcoming = $this->db->query("SELECT COUNT(*) FROM rent_invoices WHERE due_date BETWEEN CURRENT_DATE() + INTERVAL 1 DAY AND CURRENT_DATE() + INTERVAL 7 DAY AND status != 'Paid'")->fetchColumn();

        // AC Queries
        $acDueToday = $this->db->query("SELECT COUNT(*) FROM ac_maintenance_tasks WHERE scheduled_date = CURRENT_DATE() AND status = 'Scheduled'")->fetchColumn();
        $acOverdue = $this->db->query("SELECT COUNT(*) FROM ac_maintenance_tasks WHERE scheduled_date < CURRENT_DATE() AND status = 'Scheduled'")->fetchColumn();
        $acPending = $this->db->query("SELECT COUNT(*) FROM ac_maintenance_tasks WHERE status = 'Pending_Approval'")->fetchColumn();
        $acUpcoming = $this->db->query("SELECT COUNT(*) FROM ac_maintenance_tasks WHERE scheduled_date BETWEEN CURRENT_DATE() + INTERVAL 1 DAY AND CURRENT_DATE() + INTERVAL 7 DAY AND status = 'Scheduled'")->fetchColumn();

        $totalUpcoming = $rentUpcoming + $acUpcoming;

        echo json_encode([
            'rent_due_today' => (int)$rentDueToday,
            'rent_overdue' => (int)$rentOverdue,
            'ac_due_today' => (int)$acDueToday,
            'ac_overdue' => (int)$acOverdue,
            'ac_pending' => (int)$acPending,
            'upcoming_events' => (int)$totalUpcoming,
            'ac_upcoming_week' => (int)$acUpcoming // For AI message
        ]);
    }

    public function getCalendarEvents() {
        AuthMiddleware::requireLogin();

        // Fetch Rent Events
        $rentStmt = $this->db->query("
            SELECT 
                r.id, 
                'rent' as event_type,
                r.due_date as date, 
                r.status, 
                a.code as apartment_code, 
                b.name as building_name 
            FROM rent_invoices r
            JOIN contracts c ON r.contract_id = c.id
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
        ");
        $rentEvents = $rentStmt->fetchAll(PDO::FETCH_ASSOC);

        // Fetch AC Events
        $acStmt = $this->db->query("
            SELECT 
                t.id, 
                'ac' as event_type,
                t.scheduled_date as date, 
                t.status, 
                a.code as apartment_code, 
                b.name as building_name 
            FROM ac_maintenance_tasks t
            JOIN apartments a ON t.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
        ");
        $acEvents = $acStmt->fetchAll(PDO::FETCH_ASSOC);

        $allEvents = array_merge($rentEvents, $acEvents);

        echo json_encode($allEvents);
    }

    public function getNotifications() {
        AuthMiddleware::requireLogin();
        $notifications = [];

        // 1. Rent Overdue
        $rentOverdueStmt = $this->db->query("
            SELECT 
                r.id, r.due_date, a.code as apartment_code, b.name as building_name, DATEDIFF(CURRENT_DATE(), r.due_date) as days_overdue
            FROM rent_invoices r
            JOIN contracts c ON r.contract_id = c.id
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE r.due_date < CURRENT_DATE() AND r.status != 'Paid'
            ORDER BY r.due_date ASC
        ");
        foreach ($rentOverdueStmt->fetchAll(PDO::FETCH_ASSOC) as $item) {
            $notifications[] = [
                'type' => 'rent_overdue',
                'building' => $item['building_name'],
                'apartment' => $item['apartment_code'],
                'days' => (int)$item['days_overdue']
            ];
        }

        // 2. Rent Due Today
        $rentTodayStmt = $this->db->query("
            SELECT 
                r.id, a.code as apartment_code, b.name as building_name
            FROM rent_invoices r
            JOIN contracts c ON r.contract_id = c.id
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE r.due_date = CURRENT_DATE() AND r.status != 'Paid'
        ");
        foreach ($rentTodayStmt->fetchAll(PDO::FETCH_ASSOC) as $item) {
            $notifications[] = [
                'type' => 'rent_due_today',
                'building' => $item['building_name'],
                'apartment' => $item['apartment_code']
            ];
        }

        // 3. Rent Due Tomorrow
        $rentTomorrowStmt = $this->db->query("
            SELECT 
                r.id, a.code as apartment_code, b.name as building_name
            FROM rent_invoices r
            JOIN contracts c ON r.contract_id = c.id
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE r.due_date = CURRENT_DATE() + INTERVAL 1 DAY AND r.status != 'Paid'
        ");
        foreach ($rentTomorrowStmt->fetchAll(PDO::FETCH_ASSOC) as $item) {
            $notifications[] = [
                'type' => 'rent_due_tomorrow',
                'building' => $item['building_name'],
                'apartment' => $item['apartment_code']
            ];
        }

        // 4. AC Overdue
        $acOverdueStmt = $this->db->query("
            SELECT 
                t.id, t.scheduled_date, a.code as apartment_code, b.name as building_name, DATEDIFF(CURRENT_DATE(), t.scheduled_date) as days_overdue
            FROM ac_maintenance_tasks t
            JOIN apartments a ON t.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE t.scheduled_date < CURRENT_DATE() AND t.status = 'Scheduled'
            ORDER BY t.scheduled_date ASC
        ");
        foreach ($acOverdueStmt->fetchAll(PDO::FETCH_ASSOC) as $item) {
            $notifications[] = [
                'type' => 'ac_overdue',
                'building' => $item['building_name'],
                'apartment' => $item['apartment_code'],
                'days' => (int)$item['days_overdue']
            ];
        }

        // 5. AC Due Today
        $acTodayStmt = $this->db->query("
            SELECT 
                t.id, a.code as apartment_code, b.name as building_name
            FROM ac_maintenance_tasks t
            JOIN apartments a ON t.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE t.scheduled_date = CURRENT_DATE() AND t.status = 'Scheduled'
        ");
        foreach ($acTodayStmt->fetchAll(PDO::FETCH_ASSOC) as $item) {
            $notifications[] = [
                'type' => 'ac_due_today',
                'building' => $item['building_name'],
                'apartment' => $item['apartment_code']
            ];
        }

        // We can aggregate totals here or let frontend do it.
        // Frontend will aggregate them.
        
        // 6. Contract Expiring Soon (Next 30 days)
        $contractExpiringStmt = $this->db->query("
            SELECT 
                c.id, c.end_date, t.full_name as tenant_name, a.code as apartment_code, b.name as building_name, DATEDIFF(c.end_date, CURRENT_DATE()) as days_left
            FROM contracts c
            JOIN tenants t ON c.tenant_id = t.id
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE c.status = 'Active' 
              AND c.end_date >= CURRENT_DATE() 
              AND c.end_date <= CURRENT_DATE() + INTERVAL 30 DAY
            ORDER BY c.end_date ASC
        ");
        foreach ($contractExpiringStmt->fetchAll(PDO::FETCH_ASSOC) as $item) {
            $notifications[] = [
                'type' => 'contract_expiring',
                'building' => $item['building_name'],
                'apartment' => $item['apartment_code'],
                'tenant' => $item['tenant_name'],
                'days' => (int)$item['days_left'],
                'end_date' => $item['end_date']
            ];
        }

        // 7. Generator Subscriptions Due/Overdue (within 3 days)
        $genStmt = $this->db->query("
            SELECT 
                es.next_billing_date, es.amps, a.code as apartment_code, b.name as building_name, DATEDIFF(es.next_billing_date, CURRENT_DATE()) as days_left
            FROM electricity_subscriptions es
            JOIN apartments a ON es.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE es.status = 'Active' 
              AND es.next_billing_date <= DATE_ADD(CURRENT_DATE(), INTERVAL 7 DAY)
            ORDER BY es.next_billing_date ASC
        ");
        foreach ($genStmt->fetchAll(PDO::FETCH_ASSOC) as $item) {
            $is_metered = floatval($item['amps']) == 0;
            $notifications[] = [
                'type' => $is_metered ? 'generator_meter_reading' : 'generator_subscription_renewal',
                'building' => $item['building_name'],
                'apartment' => $item['apartment_code'],
                'days' => (int)$item['days_left'],
                'date' => $item['next_billing_date']
            ];
        }

        echo json_encode($notifications);
    }
}
