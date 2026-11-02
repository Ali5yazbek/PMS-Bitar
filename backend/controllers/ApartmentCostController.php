<?php
class ApartmentCostController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function getReport() {
        AuthMiddleware::requireLogin();
        
        $startDate = $_GET['start_date'] ?? date('Y-m-01');
        $endDate = $_GET['end_date'] ?? date('Y-m-t');
        $search = $_GET['search'] ?? '';
        
        $allCosts = [];

        // 1. Fetch from apartment_cost_deployments
        $query1 = "
            SELECT 
                c.id, c.supplier_name, c.amount, c.date, c.notes, c.receipt_image, 'Deployment' as type,
                a.code as apartment_code, 
                b.name as building_name
            FROM apartment_cost_deployments c
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE c.date >= ? AND c.date <= ?
              AND (c.status IS NULL OR c.status = 'Accepted')
        ";
        $params1 = [$startDate, $endDate];
        if (!empty($search)) {
            $query1 .= " AND (a.code LIKE ? OR b.name LIKE ?)";
            $params1[] = "%$search%";
            $params1[] = "%$search%";
        }
        $stmt1 = $this->db->prepare($query1);
        $stmt1->execute($params1);
        foreach ($stmt1->fetchAll(PDO::FETCH_ASSOC) as $row) {
            $row['id'] = 'dep_' . $row['id'];
            $allCosts[] = $row;
        }

        // 2. Fetch from expenses (from POS, etc)
        $query2 = "
            SELECT 
                e.id, 'Warehouse / POS' as supplier_name, e.amount, e.date, CONCAT(e.notes, ' (Ref: ', COALESCE(e.reference_id, 'N/A'), ')') as notes, NULL as receipt_image, 'POS Expense' as type,
                a.code as apartment_code,
                b.name as building_name
            FROM expenses e
            JOIN apartments a ON e.entity_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE e.entity_type = 'Apartment' AND e.date >= ? AND e.date <= ?
        ";
        $params2 = [$startDate, $endDate];
        if (!empty($search)) {
            $query2 .= " AND (a.code LIKE ? OR b.name LIKE ?)";
            $params2[] = "%$search%";
            $params2[] = "%$search%";
        }
        $stmt2 = $this->db->prepare($query2);
        $stmt2->execute($params2);
        foreach ($stmt2->fetchAll(PDO::FETCH_ASSOC) as $row) {
            $row['id'] = 'exp_' . $row['id'];
            $allCosts[] = $row;
        }

        // 3. Fetch from apartment_expenses
        $query3 = "
            SELECT 
                ae.id, p.name as supplier_name, ae.total as amount, ae.date, CONCAT('Quantity: ', ae.quantity) as notes, NULL as receipt_image, 'Direct Product' as type,
                a.code as apartment_code,
                b.name as building_name
            FROM apartment_expenses ae
            JOIN products p ON ae.product_id = p.id
            JOIN apartments a ON ae.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE ae.date >= ? AND ae.date <= ?
        ";
        $params3 = [$startDate, $endDate];
        if (!empty($search)) {
            $query3 .= " AND (a.code LIKE ? OR b.name LIKE ?)";
            $params3[] = "%$search%";
            $params3[] = "%$search%";
        }
        $stmt3 = $this->db->prepare($query3);
        $stmt3->execute($params3);
        foreach ($stmt3->fetchAll(PDO::FETCH_ASSOC) as $row) {
            $row['id'] = 'ae_' . $row['id'];
            $allCosts[] = $row;
        }

        // Sort by date DESC
        usort($allCosts, function($a, $b) {
            return strtotime($b['date']) - strtotime($a['date']);
        });
        
        echo json_encode($allCosts);
    }

    public function getBuildingCosts($building_id) {
        AuthMiddleware::requireLogin();
        
        $stmt = $this->db->prepare("
            SELECT a.id, a.code, b.name as building_name,
            (
                COALESCE((SELECT SUM(amount) FROM apartment_cost_deployments WHERE apartment_id = a.id AND (status IS NULL OR status = 'Accepted')), 0) +
                COALESCE((SELECT SUM(amount) FROM expenses WHERE entity_type = 'Apartment' AND entity_id = a.id), 0) +
                COALESCE((SELECT SUM(total) FROM apartment_expenses WHERE apartment_id = a.id), 0)
            ) as total_cost
            FROM apartments a
            JOIN buildings b ON a.building_id = b.id
            WHERE a.building_id = ?
        ");
        $stmt->execute([$building_id]);
        $apartments = $stmt->fetchAll();
        
        echo json_encode($apartments);
    }

    public function getApartmentCosts($apartment_id) {
        AuthMiddleware::requireLogin();
        
        $allCosts = [];

        // 1. Fetch from apartment_cost_deployments
        $stmt1 = $this->db->prepare("
            SELECT id, supplier_name, amount, date, notes, receipt_image, 'Deployment' as type
            FROM apartment_cost_deployments
            WHERE apartment_id = ? AND (status IS NULL OR status = 'Accepted')
        ");
        $stmt1->execute([$apartment_id]);
        $deployments = $stmt1->fetchAll(PDO::FETCH_ASSOC);
        foreach ($deployments as $d) {
            $d['id'] = 'dep_' . $d['id'];
            $allCosts[] = $d;
        }

        // 2. Fetch from expenses (from POS, etc)
        $stmt2 = $this->db->prepare("
            SELECT id, 'Warehouse / POS' as supplier_name, amount, date, CONCAT(notes, ' (Ref: ', COALESCE(reference_id, 'N/A'), ')') as notes, NULL as receipt_image, 'POS Expense' as type
            FROM expenses
            WHERE entity_type = 'Apartment' AND entity_id = ?
        ");
        $stmt2->execute([$apartment_id]);
        $expenses = $stmt2->fetchAll(PDO::FETCH_ASSOC);
        foreach ($expenses as $e) {
            $e['id'] = 'exp_' . $e['id'];
            $allCosts[] = $e;
        }

        // 3. Fetch from apartment_expenses
        $stmt3 = $this->db->prepare("
            SELECT ae.id, p.name as supplier_name, ae.total as amount, ae.date, CONCAT('Quantity: ', ae.quantity) as notes, NULL as receipt_image, 'Direct Product' as type
            FROM apartment_expenses ae
            JOIN products p ON ae.product_id = p.id
            WHERE ae.apartment_id = ?
        ");
        $stmt3->execute([$apartment_id]);
        $aptExpenses = $stmt3->fetchAll(PDO::FETCH_ASSOC);
        foreach ($aptExpenses as $ae) {
            $ae['id'] = 'ae_' . $ae['id'];
            $allCosts[] = $ae;
        }

        // 4. Fetch matching agent_purchases by apartment code & building name
        $aptInfoStmt = $this->db->prepare("
            SELECT a.code as apartment_code, b.name as building_name 
            FROM apartments a 
            JOIN buildings b ON a.building_id = b.id 
            WHERE a.id = ?
        ");
        $aptInfoStmt->execute([$apartment_id]);
        $aptInfo = $aptInfoStmt->fetch(PDO::FETCH_ASSOC);

        if ($aptInfo) {
            $this->db->exec("CREATE TABLE IF NOT EXISTS agent_purchases (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_id INT NOT NULL,
                building_name VARCHAR(100) DEFAULT 'Galaxy',
                apartment_number VARCHAR(50) DEFAULT 'A1',
                supplier VARCHAR(100) NOT NULL,
                amount VARCHAR(50) NOT NULL,
                items VARCHAR(255) DEFAULT 'General Material',
                notes TEXT,
                status VARCHAR(50) DEFAULT 'Pending Review',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )");

            $stmt4 = $this->db->prepare("
                SELECT id, supplier as supplier_name, amount, DATE(created_at) as date, CONCAT('Items: ', items, ' • ', COALESCE(notes, '')) as notes, NULL as receipt_image, 'Agent Purchase' as type
                FROM agent_purchases
                WHERE (building_name LIKE ? OR building_name LIKE ?) 
                  AND (apartment_number LIKE ? OR apartment_number LIKE ?)
                  AND status = 'Accepted'
            ");
            $bName = $aptInfo['building_name'];
            $aCode = $aptInfo['apartment_code'];
            $stmt4->execute(["%$bName%", "$bName%", "%$aCode%", "$aCode%"]);
            $agentPurchases = $stmt4->fetchAll(PDO::FETCH_ASSOC);

            // Keep track of suppliers & dates to prevent duplication if inserted in step 1
            $existingKeys = [];
            foreach ($allCosts as $c) {
                $existingKeys[] = ($c['supplier_name'] ?? '') . '_' . (float)($c['amount'] ?? 0);
            }

            foreach ($agentPurchases as $ap) {
                $numericVal = is_numeric($ap['amount']) ? (float)$ap['amount'] : (float)preg_replace('/[^0-9.]/', '', $ap['amount']);
                $key = ($ap['supplier_name'] ?? '') . '_' . $numericVal;
                if (!in_array($key, $existingKeys)) {
                    $ap['id'] = 'ap_' . $ap['id'];
                    $ap['amount'] = $numericVal;
                    $allCosts[] = $ap;
                }
            }
        }

        // Sort by date DESC
        usort($allCosts, function($a, $b) {
            return strtotime($b['date']) - strtotime($a['date']);
        });
        
        echo json_encode($allCosts);
    }

    public function getTotalCosts($apartment_id) {
        AuthMiddleware::requireLogin();

        $stmt1 = $this->db->prepare("SELECT COALESCE(SUM(amount), 0) FROM expenses WHERE entity_type = 'Apartment' AND entity_id = ?");
        $stmt1->execute([$apartment_id]);
        $cost1 = (float)$stmt1->fetchColumn();

        $stmt2 = $this->db->prepare("SELECT COALESCE(SUM(total), 0) FROM apartment_expenses WHERE apartment_id = ?");
        $stmt2->execute([$apartment_id]);
        $cost2 = (float)$stmt2->fetchColumn();

        $stmt3 = $this->db->prepare("SELECT COALESCE(SUM(amount), 0) FROM apartment_cost_deployments WHERE apartment_id = ? AND (status IS NULL OR status = 'Accepted')");
        $stmt3->execute([$apartment_id]);
        $cost3 = (float)$stmt3->fetchColumn();

        $total = $cost1 + $cost2 + $cost3;

        echo json_encode(['total_costs' => $total]);
    }

    public function store($apartment_id) {
        $user = AuthMiddleware::requireLogin();
        
        $supplierName = $_POST['supplier_name'] ?? '';
        $amount = $_POST['amount'] ?? 0;
        $date = $_POST['date'] ?? date('Y-m-d');
        $notes = $_POST['notes'] ?? '';
        
        if (empty($amount)) {
            http_response_code(400);
            echo json_encode(['error' => 'Amount is required']);
            return;
        }
        
        $receiptPath = null;
        if (isset($_FILES['receipt_image']) && $_FILES['receipt_image']['error'] === UPLOAD_ERR_OK) {
            $uploadDir = __DIR__ . '/../uploads/receipts/';
            if (!is_dir($uploadDir)) {
                mkdir($uploadDir, 0755, true);
            }
            
            $fileInfo = pathinfo($_FILES['receipt_image']['name']);
            $extension = strtolower($fileInfo['extension']);
            
            // Allow common image extensions
            $allowedExtensions = ['jpg', 'jpeg', 'png', 'pdf'];
            if (in_array($extension, $allowedExtensions)) {
                $filename = uniqid('receipt_') . '.' . $extension;
                $targetFile = $uploadDir . $filename;
                
                if (move_uploaded_file($_FILES['receipt_image']['tmp_name'], $targetFile)) {
                    $receiptPath = '/uploads/receipts/' . $filename;
                }
            }
        }
        
        try {
            $stmt = $this->db->prepare("
                INSERT INTO apartment_cost_deployments (apartment_id, supplier_name, amount, receipt_image, notes, date)
                VALUES (?, ?, ?, ?, ?, ?)
            ");
            $stmt->execute([$apartment_id, $supplierName, $amount, $receiptPath, $notes, $date]);
            
            $id = $this->db->lastInsertId();
            AuditLogger::log($user['user_id'], 'Create', 'apartment_cost', $id, "Added cost deployment to apartment $apartment_id");
            
            echo json_encode(['message' => 'Cost deployment created successfully', 'id' => $id]);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => 'Failed to create cost deployment: ' . $e->getMessage()]);
        }
    }
}
