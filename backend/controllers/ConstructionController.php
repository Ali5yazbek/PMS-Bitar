<?php
class ConstructionController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function index() {
        AuthMiddleware::requireLogin();
        $stmt = $this->db->query("SELECT * FROM constructions ORDER BY id DESC");
        echo json_encode($stmt->fetchAll());
    }

    public function getGlobalMaterials() {
        AuthMiddleware::requireLogin();
        $stmt = $this->db->query("SELECT DISTINCT item_name, unit FROM construction_materials ORDER BY item_name ASC");
        $result = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode($result);
    }

    public function show($id) {
        AuthMiddleware::requireLogin();
        
        $stmt = $this->db->prepare("SELECT * FROM constructions WHERE id = ?");
        $stmt->execute([$id]);
        $project = $stmt->fetch();
        
        if (!$project) {
            http_response_code(404);
            echo json_encode(['error' => 'Project not found']);
            return;
        }
        
        // Get Expenses Ledger for this project
        $expenseStmt = $this->db->prepare("
            SELECT e.*, u.name as user_name 
            FROM expenses e 
            LEFT JOIN users u ON e.user_id = u.id 
            WHERE e.entity_type = 'Construction' AND e.entity_id = ?
            ORDER BY e.date DESC, e.id DESC
        ");
        $expenseStmt->execute([$id]);
        $expenses = $expenseStmt->fetchAll();

        // Fetch invoice items for expenses that came from the warehouse
        foreach ($expenses as &$exp) {
            if ($exp['reference_id'] && strpos($exp['reference_id'], 'INV-') === 0) {
                $invStmt = $this->db->prepare("
                    SELECT i.quantity, i.total_price, p.name as product_name 
                    FROM invoice_items i 
                    JOIN invoices inv ON i.invoice_id = inv.id
                    JOIN products p ON i.product_id = p.id
                    WHERE inv.invoice_number = ?
                ");
                $invStmt->execute([$exp['reference_id']]);
                $exp['items'] = $invStmt->fetchAll();
            } else {
                $exp['items'] = [];
            }
        }
        unset($exp); // Break the reference with the last element
        
        // Calculate totals based on expenses categories
        $materialCost = 0;
        $laborCost = 0;
        $otherCost = 0;
        $totalSpent = 0;
        
        foreach ($expenses as $exp) {
            $totalSpent += $exp['amount'];
            if ($exp['category'] === 'Material' || $exp['category'] === 'Warehouse') {
                $materialCost += $exp['amount'];
            } elseif ($exp['category'] === 'Labor') {
                $laborCost += $exp['amount'];
            } else {
                $otherCost += $exp['amount'];
            }
        }
        
        // Update actual_cost in database
        $upd = $this->db->prepare("UPDATE constructions SET actual_cost = ? WHERE id = ?");
        $upd->execute([$totalSpent, $id]);
        $project['actual_cost'] = $totalSpent;
        
        // Fetch construction materials
        $matStmt = $this->db->prepare("SELECT * FROM construction_materials WHERE construction_id = ?");
        $matStmt->execute([$id]);
        $materials = $matStmt->fetchAll();

        // Fetch site stock
        $stockStmt = $this->db->prepare("SELECT * FROM construction_site_stock WHERE construction_id = ?");
        $stockStmt->execute([$id]);
        $site_stock = $stockStmt->fetchAll();
        
        echo json_encode([
            'project' => $project,
            'expenses' => $expenses,
            'materials' => $materials,
            'site_stock' => $site_stock,
            'ledger' => [
                'total' => $totalSpent,
                'materials' => $materialCost,
                'labor' => $laborCost,
                'other' => $otherCost
            ]
        ]);
    }

    public function store() {
        $user = AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        try {
            $this->db->beginTransaction();

            $budget = floatval($data['budget'] ?? 0);
            $landArea = floatval($data['land_area'] ?? 600);
            $floors = intval($data['floors'] ?? 3);
            $apts = intval($data['total_apartments'] ?? ($floors * 2));
            $status = $data['status'] ?? 'Active';

            // 1. Create matching Workshop Project
            $stmtW = $this->db->prepare("
                INSERT INTO workshop_projects (name, land_area, floors, apartments_per_floor, total_apartments, status, progress)
                VALUES (?, ?, ?, ?, ?, ?, 0)
            ");
            $stmtW->execute([
                $data['name'], 
                $landArea, 
                $floors, 
                max(1, ceil($apts / max($floors, 1))), 
                $apts, 
                $status
            ]);
            $workshop_id = $this->db->lastInsertId();

            // Default specifications
            $stmtSpecs = $this->db->prepare("
                INSERT INTO workshop_specifications (project_id, bedrooms, bathrooms, kitchens, living_rooms, balconies, windows, doors, parking_spaces, elevators, roof_area, garden_area)
                VALUES (?, 2, 1, 1, 1, 1, 4, 3, 1, 0, 0, 0)
            ");
            $stmtSpecs->execute([$workshop_id]);

            // 2. Create Construction linked to Workshop
            $stmt = $this->db->prepare("
                INSERT INTO constructions (name, owner, location, start_date, end_date, status, budget, estimated_cost, manager, notes, workshop_id)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ");
            $stmt->execute([
                $data['name'], 
                $data['owner'] ?? 'Bitar Group', 
                $data['location'] ?? 'Local', 
                $data['start_date'] ?? date('Y-m-d'), 
                $data['end_date'] ?? date('Y-m-d', strtotime('+180 days')), 
                $status, 
                $budget, 
                $budget, 
                $data['manager'] ?? 'Manager', 
                $data['notes'] ?? null,
                $workshop_id
            ]);
            $id = $this->db->lastInsertId();

            $this->db->commit();
            AuditLogger::log('CREATE', 'Construction', $id, "Created construction project: {$data['name']}");
            echo json_encode(['id' => $id, 'message' => 'Project created successfully', 'workshop_id' => $workshop_id]);
        } catch (Exception $e) {
            if ($this->db->inTransaction()) {
                $this->db->rollBack();
            }
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function update($id) {
        $user = AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        try {
            $this->db->beginTransaction();

            $stmt = $this->db->prepare("
                UPDATE constructions SET 
                    name = ?, owner = ?, location = ?, start_date = ?, end_date = ?, 
                    status = ?, budget = ?, estimated_cost = ?, manager = ?, notes = ?
                WHERE id = ?
            ");
            $stmt->execute([
                $data['name'], $data['owner'], $data['location'], 
                $data['start_date'], $data['end_date'], 
                $data['status'], $data['budget'], 
                $data['estimated_cost'], $data['manager'], 
                $data['notes'], $id
            ]);

            // Synchronize status and name in linked workshop project
            $updW = $this->db->prepare("
                UPDATE workshop_projects 
                SET name = ?, status = ? 
                WHERE id = (SELECT workshop_id FROM constructions WHERE id = ?) OR name = ?
            ");
            $updW->execute([$data['name'], $data['status'], $id, $data['name']]);

            $this->db->commit();
            AuditLogger::log('UPDATE', 'Construction', $id, "Updated project details: {$data['name']}");
            echo json_encode(['message' => 'Project updated successfully']);
        } catch (Exception $e) {
            if ($this->db->inTransaction()) {
                $this->db->rollBack();
            }
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function destroy($id) {
        $user = AuthMiddleware::requireLogin();
        
        try {
            $this->db->beginTransaction();

            $stmt = $this->db->prepare("SELECT * FROM constructions WHERE id = ?");
            $stmt->execute([$id]);
            $construction = $stmt->fetch();

            if (!$construction) {
                // If not found in constructions, maybe it's in workshop_projects
                $stmtW = $this->db->prepare("SELECT * FROM workshop_projects WHERE id = ?");
                $stmtW->execute([$id]);
                $wRow = $stmtW->fetch();
                if (!$wRow) {
                    http_response_code(404);
                    echo json_encode(['error' => 'Project not found']);
                    return;
                }
                $workshop_id = $wRow['id'];
                $projectName = $wRow['name'];
            } else {
                $workshop_id = $construction['workshop_id'];
                $projectName = $construction['name'];
            }

            // Find linked workshop project if not set
            if (!$workshop_id) {
                $stmtW = $this->db->prepare("SELECT id FROM workshop_projects WHERE name = ?");
                $stmtW->execute([$projectName]);
                $wRow = $stmtW->fetch();
                if ($wRow) {
                    $workshop_id = $wRow['id'];
                }
            }

            // 1. Delete linked workshop records if exists
            if ($workshop_id) {
                $this->db->prepare("UPDATE inventory_transactions SET project_id = NULL WHERE project_id = ?")->execute([$workshop_id]);
                $this->db->prepare("DELETE FROM purchase_requests WHERE project_id = ?")->execute([$workshop_id]);
                $this->db->prepare("DELETE FROM workshop_estimates WHERE project_id = ?")->execute([$workshop_id]);
                $this->db->prepare("DELETE FROM workshop_specifications WHERE project_id = ?")->execute([$workshop_id]);
                $this->db->prepare("DELETE FROM workshop_projects WHERE id = ?")->execute([$workshop_id]);
            }
            // Also clean any workshop project matching by name
            $this->db->prepare("DELETE FROM workshop_projects WHERE name = ?")->execute([$projectName]);

            // 2. Delete construction and its dependencies
            $this->db->prepare("UPDATE purchase_orders SET construction_id = NULL WHERE construction_id = ?")->execute([$id]);
            $this->db->prepare("DELETE FROM construction_material_movements WHERE construction_id = ?")->execute([$id]);
            $this->db->prepare("DELETE FROM construction_site_stock WHERE construction_id = ?")->execute([$id]);
            $this->db->prepare("DELETE FROM construction_materials WHERE construction_id = ?")->execute([$id]);
            $this->db->prepare("DELETE FROM constructions WHERE id = ? OR name = ?")->execute([$id, $projectName]);

            $this->db->commit();
            AuditLogger::log('DELETE', 'Construction', $id, "Deleted construction and linked workshop project: {$projectName}");

            echo json_encode(['message' => 'Project and linked workshop deleted successfully']);
        } catch (Exception $e) {
            if ($this->db->inTransaction()) {
                $this->db->rollBack();
            }
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }
}
