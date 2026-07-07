<?php
class SalesController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function index() {
        AuthMiddleware::requireLogin();
        
        $startDate = $_GET['start_date'] ?? date('Y-m-d', strtotime('-30 days'));
        $endDate = $_GET['end_date'] ?? date('Y-m-d');
        $customerType = $_GET['customer_type'] ?? 'All';
        
        $query = "SELECT * FROM invoices WHERE date >= ? AND date <= ?";
        $params = [$startDate, $endDate];
        
        if ($customerType !== 'All') {
            $query .= " AND customer_type = ?";
            $params[] = $customerType;
        }
        
        $query .= " ORDER BY date DESC, id DESC";
        
        $stmt = $this->db->prepare($query);
        $stmt->execute($params);
        $invoices = $stmt->fetchAll();
        
        // Fetch items for each invoice
        foreach ($invoices as &$inv) {
            $itemStmt = $this->db->prepare("
                SELECT i.*, p.name as product_name 
                FROM invoice_items i 
                JOIN products p ON i.product_id = p.id 
                WHERE i.invoice_id = ?
            ");
            $itemStmt->execute([$inv['id']]);
            $inv['items'] = $itemStmt->fetchAll();
            
            // Enrich customer name dynamically if not stored properly
            if ($inv['customer_type'] === 'Construction' && $inv['customer_id']) {
                $q = $this->db->prepare("SELECT name FROM constructions WHERE id = ?");
                $q->execute([$inv['customer_id']]);
                if ($res = $q->fetch()) $inv['customer_name'] = $res['name'];
            } elseif ($inv['customer_type'] === 'Building' && $inv['customer_id']) {
                $q = $this->db->prepare("SELECT name FROM buildings WHERE id = ?");
                $q->execute([$inv['customer_id']]);
                if ($res = $q->fetch()) $inv['customer_name'] = $res['name'];
            } elseif ($inv['customer_type'] === 'Apartment' && $inv['customer_id']) {
                $q = $this->db->prepare("SELECT a.code, b.name as building FROM apartments a JOIN buildings b ON a.building_id = b.id WHERE a.id = ?");
                $q->execute([$inv['customer_id']]);
                if ($res = $q->fetch()) $inv['customer_name'] = "Apt " . $res['code'] . " (" . $res['building'] . ")";
            }
        }
        unset($inv); // Break the reference
        
        echo json_encode($invoices);
    }
    
    public function dashboard() {
        AuthMiddleware::requireLogin();
        $today = date('Y-m-d');
        
        $stmt = $this->db->prepare("
            SELECT customer_type, SUM(final_amount) as total 
            FROM invoices 
            WHERE date = ? 
            GROUP BY customer_type
        ");
        $stmt->execute([$today]);
        $rawSales = $stmt->fetchAll();
        
        $sales = [
            'Walk-In' => 0,
            'Building' => 0,
            'Apartment' => 0,
            'Construction' => 0,
            'Total' => 0
        ];
        
        foreach ($rawSales as $s) {
            $sales[$s['customer_type']] = (float)$s['total'];
            $sales['Total'] += (float)$s['total'];
        }
        
        echo json_encode($sales);
    }
}
