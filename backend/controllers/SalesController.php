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
    public function summary() {
        AuthMiddleware::requireLogin();
        
        $startDate = !empty($_GET['start_date']) ? $_GET['start_date'] : null;
        $endDate = !empty($_GET['end_date']) ? $_GET['end_date'] : null;
        $filter = $_GET['filter'] ?? $_GET['category'] ?? 'All'; // Walk-In, Account, Apartment, Construction, Building, Cash, Card, Bank, Transfer, Returned, Refund, Cancelled
        $search = $_GET['search'] ?? '';
        
        $query = "SELECT i.*, u.username as cashier_name 
                  FROM invoices i
                  LEFT JOIN users u ON i.created_by = u.id 
                  WHERE 1=1";
        $params = [];
        
        if ($startDate && $endDate) {
            $query .= " AND i.date >= ? AND i.date <= ?";
            $params[] = $startDate;
            $params[] = $endDate;
        } elseif ($startDate) {
            $query .= " AND i.date >= ?";
            $params[] = $startDate;
        }
        
        // Handle categories and payment types
        $customerTypes = ['Walk-In', 'Account', 'Apartment', 'Construction', 'Building', 'Supplier', 'Employee'];
        $paymentTypes = ['Cash', 'Card', 'Bank', 'Transfer', 'Mixed'];
        $statuses = ['Returned', 'Refunded', 'Cancelled'];
        
        if ($filter !== 'All') {
            if (in_array($filter, $customerTypes)) {
                $query .= " AND i.customer_type = ?";
                $params[] = $filter;
            } elseif (in_array($filter, $paymentTypes)) {
                $query .= " AND i.payment_type = ?";
                $params[] = $filter;
            } elseif (in_array($filter, $statuses)) {
                $query .= " AND i.status = ?";
                $params[] = $filter;
            } elseif ($filter === 'Cash Sale') {
                $query .= " AND i.payment_type = 'Cash'";
            }
        }
        
        // Smart Search
        if ($search) {
            $search = "%$search%";
            $query .= " AND (
                i.invoice_number LIKE ? OR 
                i.customer_name LIKE ? OR 
                u.username LIKE ? OR
                EXISTS (SELECT 1 FROM invoice_items ii JOIN products p ON ii.product_id = p.id WHERE ii.invoice_id = i.id AND (p.name LIKE ? OR p.barcode LIKE ?))
            )";
            $params[] = $search; // invoice_number
            $params[] = $search; // customer_name
            $params[] = $search; // cashier
            $params[] = $search; // product name
            $params[] = $search; // product barcode
        }
        
        $query .= " ORDER BY i.date DESC, i.id DESC";
        
        $stmt = $this->db->prepare($query);
        $stmt->execute($params);
        $invoices = $stmt->fetchAll();
        
        // Enrich
        foreach ($invoices as &$inv) {
            $itemStmt = $this->db->prepare("
                SELECT i.*, p.name as product_name 
                FROM invoice_items i 
                JOIN products p ON i.product_id = p.id 
                WHERE i.invoice_id = ?
            ");
            $itemStmt->execute([$inv['id']]);
            $inv['items'] = $itemStmt->fetchAll();
            $inv['items_count'] = count($inv['items']);
        }
        unset($inv);
        
        echo json_encode($invoices);
    }
    
    public function analytics() {
        AuthMiddleware::requireLogin();
        
        $startDate = !empty($_GET['start_date']) ? $_GET['start_date'] : date('Y-m-d', strtotime('-30 days'));
        $endDate = !empty($_GET['end_date']) ? $_GET['end_date'] : date('Y-m-d');
        
        $stats = [
            'total_revenue' => 0,
            'total_invoices' => 0,
            'total_returns' => 0,
            'net_sales' => 0,
            'avg_invoice_value' => 0,
            'highest_invoice' => 0,
            'lowest_invoice' => 0,
            'best_selling_product' => null,
            'most_returned_product' => null,
            'most_active_cashier' => null,
            'highest_spending_customer' => null,
            'sales_by_building' => 0,
            'sales_by_construction' => 0,
            'sales_by_apartment' => 0,
            'profit' => 0
        ];
        
        // Sales in range
        $stmtSales = $this->db->prepare("SELECT SUM(final_amount) as total, COUNT(*) as cnt, SUM(returned_amount) as ret, MAX(final_amount) as highest, MIN(final_amount) as lowest, SUM(final_amount - discount) as profit FROM invoices WHERE date >= ? AND date <= ? AND status != 'Cancelled'");
        $stmtSales->execute([$startDate, $endDate]);
        if ($row = $stmtSales->fetch()) {
            $stats['total_revenue'] = (float)$row['total'];
            $stats['total_invoices'] = (int)$row['cnt'];
            $stats['total_returns'] = (float)$row['ret'];
            $stats['highest_invoice'] = (float)$row['highest'];
            $stats['lowest_invoice'] = (float)$row['lowest'];
            $stats['profit'] = (float)$row['profit'];
            $stats['net_sales'] = $stats['total_revenue'] - $stats['total_returns'];
            if ($stats['total_invoices'] > 0) {
                $stats['avg_invoice_value'] = $stats['total_revenue'] / $stats['total_invoices'];
            }
        }
        
        // Best selling product
        $stmtProduct = $this->db->prepare("
            SELECT p.name, SUM(ii.quantity) as qty 
            FROM invoice_items ii 
            JOIN invoices i ON ii.invoice_id = i.id 
            JOIN products p ON ii.product_id = p.id
            WHERE i.status != 'Cancelled' AND i.date >= ? AND i.date <= ?
            GROUP BY ii.product_id 
            ORDER BY qty DESC LIMIT 1
        ");
        $stmtProduct->execute([$startDate, $endDate]);
        if ($row = $stmtProduct->fetch()) $stats['best_selling_product'] = $row['name'];
        
        // Most returned product
        $stmtRetProduct = $this->db->prepare("
            SELECT p.name, SUM(ri.quantity) as qty 
            FROM return_items ri 
            JOIN returns r ON ri.return_id = r.id 
            JOIN products p ON ri.product_id = p.id
            WHERE r.created_at >= ? AND r.created_at <= ?
            GROUP BY ri.product_id 
            ORDER BY qty DESC LIMIT 1
        ");
        $stmtRetProduct->execute([$startDate . " 00:00:00", $endDate . " 23:59:59"]);
        if ($row = $stmtRetProduct->fetch()) $stats['most_returned_product'] = $row['name'];
        
        // Most active cashier
        $stmtCashier = $this->db->prepare("
            SELECT u.username, COUNT(i.id) as count 
            FROM invoices i 
            JOIN users u ON i.created_by = u.id 
            WHERE i.date >= ? AND i.date <= ?
            GROUP BY i.created_by 
            ORDER BY count DESC LIMIT 1
        ");
        $stmtCashier->execute([$startDate, $endDate]);
        if ($row = $stmtCashier->fetch()) $stats['most_active_cashier'] = $row['username'];
        
        // Highest spending customer
        $stmtCustomer = $this->db->prepare("
            SELECT customer_name, SUM(final_amount) as total 
            FROM invoices 
            WHERE customer_name IS NOT NULL AND customer_name != '' AND date >= ? AND date <= ?
            GROUP BY customer_name 
            ORDER BY total DESC LIMIT 1
        ");
        $stmtCustomer->execute([$startDate, $endDate]);
        if ($row = $stmtCustomer->fetch()) $stats['highest_spending_customer'] = $row['customer_name'];
        
        // Sales by Building/Construction/Apartment
        $stmtBuilding = $this->db->prepare("SELECT SUM(final_amount) FROM invoices WHERE customer_type = 'Building' AND date >= ? AND date <= ?");
        $stmtBuilding->execute([$startDate, $endDate]);
        $stats['sales_by_building'] = (float)$stmtBuilding->fetchColumn();
        
        $stmtConstruction = $this->db->prepare("SELECT SUM(final_amount) FROM invoices WHERE customer_type = 'Construction' AND date >= ? AND date <= ?");
        $stmtConstruction->execute([$startDate, $endDate]);
        $stats['sales_by_construction'] = (float)$stmtConstruction->fetchColumn();
        
        $stmtApartment = $this->db->prepare("SELECT SUM(final_amount) FROM invoices WHERE customer_type = 'Apartment' AND date >= ? AND date <= ?");
        $stmtApartment->execute([$startDate, $endDate]);
        $stats['sales_by_apartment'] = (float)$stmtApartment->fetchColumn();
        
        echo json_encode($stats);
    }
    
    public function convert() {
        AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        $invoiceId = $data['invoice_id'] ?? null;
        $newCustomerType = $data['customer_type'] ?? null;
        $newCustomerId = $data['customer_id'] ?? null;
        $newCustomerName = $data['customer_name'] ?? null;
        $reason = $data['reason'] ?? 'Conversion';
        
        if (!$invoiceId || !$newCustomerType) {
            http_response_code(400);
            echo json_encode(['error' => 'Missing data']);
            return;
        }
        
        try {
            $this->db->beginTransaction();
            
            $stmt = $this->db->prepare("SELECT * FROM invoices WHERE id = ?");
            $stmt->execute([$invoiceId]);
            $oldInvoice = $stmt->fetch();
            
            $stmtUpdate = $this->db->prepare("UPDATE invoices SET customer_type = ?, customer_id = ?, customer_name = ? WHERE id = ?");
            $stmtUpdate->execute([$newCustomerType, $newCustomerId, $newCustomerName, $invoiceId]);
            
            // Audit
            $oldValues = json_encode(['customer_type' => $oldInvoice['customer_type'], 'customer_id' => $oldInvoice['customer_id'], 'customer_name' => $oldInvoice['customer_name']]);
            $newValues = json_encode(['customer_type' => $newCustomerType, 'customer_id' => $newCustomerId, 'customer_name' => $newCustomerName]);
            
            $stmtAudit = $this->db->prepare("INSERT INTO sales_audits (invoice_id, user_id, action, old_values, new_values, reason) VALUES (?, ?, 'CONVERT', ?, ?, ?)");
            $stmtAudit->execute([$invoiceId, $_SESSION['user_id'] ?? null, $oldValues, $newValues, $reason]);
            
            $this->db->commit();
            echo json_encode(['message' => 'Invoice converted successfully']);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }
    
    public function edit() {
        AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        $invoiceId = $data['invoice_id'] ?? null;
        $reason = $data['reason'] ?? 'Edit Invoice';
        
        if (!$invoiceId) {
            http_response_code(400);
            echo json_encode(['error' => 'Invoice ID required']);
            return;
        }
        
        try {
            $this->db->beginTransaction();
            
            $stmt = $this->db->prepare("SELECT * FROM invoices WHERE id = ?");
            $stmt->execute([$invoiceId]);
            $oldInvoice = $stmt->fetch();
            
            $updateFields = [];
            $params = [];
            $oldAudit = [];
            $newAudit = [];
            
            $allowedFields = ['customer_name', 'customer_type', 'customer_id', 'payment_type', 'created_by', 'date', 'invoice_time', 'discount', 'tax', 'notes'];
            
            foreach ($allowedFields as $field) {
                if (isset($data[$field]) && $data[$field] !== $oldInvoice[$field]) {
                    $updateFields[] = "$field = ?";
                    $params[] = $data[$field];
                    $oldAudit[$field] = $oldInvoice[$field];
                    $newAudit[$field] = $data[$field];
                }
            }
            
            // Check items
            $stmtItems = $this->db->prepare("SELECT * FROM invoice_items WHERE invoice_id = ?");
            $stmtItems->execute([$invoiceId]);
            $oldItems = $stmtItems->fetchAll();
            $oldItemsMap = [];
            foreach($oldItems as $i) $oldItemsMap[$i['id']] = $i;

            $itemsChanged = false;
            $newItemsData = $data['items'] ?? [];
            if (!empty($newItemsData)) {
                $stmtUpdateItem = $this->db->prepare("UPDATE invoice_items SET quantity = ?, price = ?, total = ? WHERE id = ? AND invoice_id = ?");
                foreach ($newItemsData as $item) {
                    $itemId = $item['id'];
                    $oldItem = $oldItemsMap[$itemId] ?? null;
                    if ($oldItem) {
                        if ($item['quantity'] != $oldItem['quantity'] || $item['price'] != $oldItem['price']) {
                            $itemsChanged = true;
                            $newTotal = $item['quantity'] * $item['price'];
                            $stmtUpdateItem->execute([$item['quantity'], $item['price'], $newTotal, $itemId, $invoiceId]);
                            
                            $oldAudit['items'][] = ['id' => $itemId, 'quantity' => $oldItem['quantity'], 'price' => $oldItem['price']];
                            $newAudit['items'][] = ['id' => $itemId, 'quantity' => $item['quantity'], 'price' => $item['price']];
                        }
                    }
                }
            }
            
            // Recalculate Subtotal, VAT, Final if items changed
            if ($itemsChanged || isset($newAudit['discount']) || isset($newAudit['tax'])) {
                // Get all current items
                $stmtCurrItems = $this->db->prepare("SELECT SUM(total) as new_subtotal FROM invoice_items WHERE invoice_id = ?");
                $stmtCurrItems->execute([$invoiceId]);
                $newSubtotal = $stmtCurrItems->fetchColumn();
                
                $currDiscount = isset($newAudit['discount']) ? $newAudit['discount'] : $oldInvoice['discount'];
                $currTax = isset($newAudit['tax']) ? $newAudit['tax'] : $oldInvoice['tax'];
                
                $newFinal = $newSubtotal - $currDiscount + $currTax;
                
                $updateFields[] = "subtotal = ?";
                $params[] = $newSubtotal;
                $updateFields[] = "final_amount = ?";
                $params[] = $newFinal;
                
                $oldAudit['subtotal'] = $oldInvoice['subtotal'];
                $oldAudit['final_amount'] = $oldInvoice['final_amount'];
                $newAudit['subtotal'] = $newSubtotal;
                $newAudit['final_amount'] = $newFinal;
            }

            if (!empty($updateFields)) {
                $params[] = $invoiceId;
                $stmtUpdate = $this->db->prepare("UPDATE invoices SET " . implode(", ", $updateFields) . " WHERE id = ?");
                $stmtUpdate->execute($params);
                
                $ipAddress = $_SERVER['REMOTE_ADDR'] ?? null;
                $device = $_SERVER['HTTP_USER_AGENT'] ?? null;
                
                $stmtAudit = $this->db->prepare("INSERT INTO sales_audits (invoice_id, user_id, action, old_values, new_values, reason, ip_address, device) VALUES (?, ?, 'EDIT', ?, ?, ?, ?, ?)");
                $stmtAudit->execute([$invoiceId, $_SESSION['user_id'] ?? null, json_encode($oldAudit), json_encode($newAudit), $reason, $ipAddress, $device]);
            }
            
            $this->db->commit();
            echo json_encode(['message' => 'Invoice edited successfully']);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }
    
    public function timeline($id) {
        AuthMiddleware::requireLogin();
        try {
            // Created (from invoices table)
            $stmt = $this->db->prepare("SELECT date, IFNULL(invoice_time, '00:00:00') as time, created_by, 'CREATE' as action, 'Invoice Created' as details FROM invoices WHERE id = ?");
            $stmt->execute([$id]);
            $created = $stmt->fetch();
            
            $timeline = [];
            if ($created) {
                $timeline[] = [
                    'timestamp' => $created['date'] . ' ' . $created['time'],
                    'user_id' => $created['created_by'],
                    'action' => 'CREATED',
                    'details' => $created['details']
                ];
            }
            
            // Audits (Edits, Converts, Returns)
            $stmtAudits = $this->db->prepare("SELECT created_at as timestamp, user_id, action, new_values as details FROM sales_audits WHERE invoice_id = ?");
            $stmtAudits->execute([$id]);
            $audits = $stmtAudits->fetchAll();
            foreach ($audits as $a) {
                $timeline[] = [
                    'timestamp' => $a['timestamp'],
                    'user_id' => $a['user_id'],
                    'action' => $a['action'],
                    'details' => $a['details']
                ];
            }
            
            // Prints
            // We'll log prints to sales_audits now
            
            usort($timeline, function($a, $b) {
                return strtotime($a['timestamp']) - strtotime($b['timestamp']);
            });
            
            echo json_encode($timeline);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }
    
    public function purchasedProducts() {
        AuthMiddleware::requireLogin();
        
        $startDate = !empty($_GET['start_date']) ? $_GET['start_date'] : null;
        $endDate = !empty($_GET['end_date']) ? $_GET['end_date'] : null;
        $filter = $_GET['filter'] ?? $_GET['category'] ?? 'All'; 
        
        $query = "SELECT ii.*, p.name as product_name, i.invoice_number, i.date as invoice_date, i.customer_name, i.customer_type, i.status as invoice_status
                  FROM invoice_items ii
                  JOIN invoices i ON ii.invoice_id = i.id
                  JOIN products p ON ii.product_id = p.id
                  WHERE 1=1";
        $params = [];
        
        if ($startDate && $endDate) {
            $query .= " AND i.date >= ? AND i.date <= ?";
            $params[] = $startDate;
            $params[] = $endDate;
        } elseif ($startDate) {
            $query .= " AND i.date >= ?";
            $params[] = $startDate;
        }
        
        if ($filter !== 'All') {
            $customerTypes = ['Walk-In', 'Account', 'Apartment', 'Construction', 'Building', 'Supplier', 'Employee'];
            if (in_array($filter, $customerTypes)) {
                $query .= " AND i.customer_type = ?";
                $params[] = $filter;
            }
        }
        
        $query .= " ORDER BY i.date DESC, i.id DESC";
        
        $stmt = $this->db->prepare($query);
        $stmt->execute($params);
        $products = $stmt->fetchAll();
        
        echo json_encode($products);
    }
}
