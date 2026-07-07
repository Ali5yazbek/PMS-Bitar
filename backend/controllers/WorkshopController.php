<?php
class WorkshopController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function index() {
        AuthMiddleware::requireLogin();
        $stmt = $this->db->query("SELECT * FROM workshop_projects ORDER BY id DESC");
        echo json_encode($stmt->fetchAll());
    }

    public function show($id) {
        AuthMiddleware::requireLogin();
        
        $stmt = $this->db->prepare("SELECT * FROM workshop_projects WHERE id = ?");
        $stmt->execute([$id]);
        $project = $stmt->fetch();
        
        $stmt = $this->db->prepare("SELECT * FROM workshop_specifications WHERE project_id = ?");
        $stmt->execute([$id]);
        $specs = $stmt->fetch();
        
        $stmt = $this->db->prepare("SELECT * FROM workshop_estimates WHERE project_id = ?");
        $stmt->execute([$id]);
        $estimates = $stmt->fetchAll();
        
        $stmt = $this->db->prepare("SELECT id FROM constructions WHERE workshop_id = ?");
        $stmt->execute([$id]);
        $linked = $stmt->fetch();
        if ($linked) {
            $project['linked_construction_id'] = $linked['id'];
        }
        
        echo json_encode([
            'project' => $project,
            'specifications' => $specs,
            'estimates' => $estimates
        ]);
    }

    public function store() {
        AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        try {
            $this->db->beginTransaction();
            
            // 1. Create Project
            $stmt = $this->db->prepare("INSERT INTO workshop_projects (name, land_area, floors, apartments_per_floor, total_apartments) VALUES (?, ?, ?, ?, ?)");
            $stmt->execute([
                $data['name'], $data['land_area'], $data['floors'], 
                $data['apartments_per_floor'], $data['floors'] * $data['apartments_per_floor']
            ]);
            $project_id = $this->db->lastInsertId();
            
            // 2. Create Specifications
            $specs = $data['specifications'];
            $stmt = $this->db->prepare("INSERT INTO workshop_specifications (project_id, bedrooms, bathrooms, kitchens, living_rooms, balconies, windows, doors, parking_spaces, elevators, roof_area, garden_area) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
            $stmt->execute([
                $project_id, $specs['bedrooms'], $specs['bathrooms'], $specs['kitchens'], 
                $specs['living_rooms'], $specs['balconies'], $specs['windows'], 
                $specs['doors'], $specs['parking_spaces'], $specs['elevators'], 
                $specs['roof_area'], $specs['garden_area']
            ]);
            
            // 3. Run Cost Estimation Engine
            $this->generateEstimates($project_id, $data, $specs);
            
            // 4. Create Linked Construction Project Automatically
            $stmtCost = $this->db->prepare("SELECT SUM(total_price) as total_estimated FROM workshop_estimates WHERE project_id = ?");
            $stmtCost->execute([$project_id]);
            $costRow = $stmtCost->fetch();
            $estimated_cost = $costRow['total_estimated'] ?? 0;
            
            $stmtInsert = $this->db->prepare("
                INSERT INTO constructions (name, owner, location, start_date, end_date, status, budget, estimated_cost, manager, workshop_id)
                VALUES (?, 'Bitar Group', 'Local', CURRENT_DATE(), DATE_ADD(CURRENT_DATE(), INTERVAL 180 DAY), 'Active', ?, ?, 'Manager', ?)
            ");
            $stmtInsert->execute([
                $data['name'], 
                $estimated_cost,
                $estimated_cost,
                $project_id
            ]);
            
            $construction_id = $this->db->lastInsertId();
            
            $stmtEstimates = $this->db->prepare("SELECT * FROM workshop_estimates WHERE project_id = ?");
            $stmtEstimates->execute([$project_id]);
            $materials = $stmtEstimates->fetchAll();
            
            $stmtMatInsert = $this->db->prepare("
                INSERT INTO construction_materials (construction_id, item_name, category, estimated_quantity, used_quantity, unit, unit_price, total_estimated_cost)
                VALUES (?, ?, ?, ?, 0, ?, ?, ?)
            ");
            
            foreach ($materials as $mat) {
                $stmtMatInsert->execute([
                    $construction_id,
                    $mat['item_name'],
                    $mat['category'],
                    $mat['quantity'],
                    $mat['unit'],
                    $mat['unit_price'],
                    $mat['total_price']
                ]);
            }

            // Mark workshop as construction started immediately
            $updProj = $this->db->prepare("UPDATE workshop_projects SET status = 'Construction_Started' WHERE id = ?");
            $updProj->execute([$project_id]);
            
            $this->db->commit();
            AuditLogger::log('CREATE', 'WorkshopProject', $project_id, "Created new workshop project: {$data['name']}");
            echo json_encode(['message' => 'Project created successfully', 'id' => $project_id]);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }
    
    private function generateEstimates($project_id, $project, $specs) {
        $totalApts = $project['floors'] * $project['apartments_per_floor'];
        $landArea = $project['land_area'];
        
        // Fetch all market rates
        $stmt = $this->db->query("SELECT item_name, default_price FROM estimation_rates");
        $rates = [];
        while ($row = $stmt->fetch()) {
            $rates[$row['item_name']] = $row['default_price'];
        }
        
        $getRate = function($name, $fallback) use ($rates) {
            return isset($rates[$name]) ? $rates[$name] : $fallback;
        };
        
        // --- 1. Material Estimation Formulas ---
        
        // Concrete: (Land Area * 0.4 * Floors) + (Roof Area * 0.2) + (Columns/Beams factor) -> approx logic
        $concrete_m3 = ($landArea * 0.3 * $project['floors']) + ($specs['roof_area'] * 0.15) + ($totalApts * 10);
        $this->insertEstimate($project_id, 'Concrete', 'Material', $concrete_m3, 'm3', $getRate('Concrete', 120));
        
        // Steel: Approx 100kg (0.1 Ton) per m3 of concrete
        $steel_tons = $concrete_m3 * 0.12;
        $this->insertEstimate($project_id, 'Steel', 'Material', $steel_tons, 'Ton', $getRate('Steel', 800));
        
        // Cement: Approx 7 bags per m3 of concrete + mortar for blocks
        $blocks = $totalApts * 3000; // 3000 blocks per apt approx
        $cement_bags = ($concrete_m3 * 7) + ($blocks / 100); 
        $this->insertEstimate($project_id, 'Cement', 'Material', $cement_bags, 'Bag', $getRate('Cement', 12));
        
        $this->insertEstimate($project_id, 'Blocks', 'Material', $blocks, 'Piece', $getRate('Blocks', 0.50));
        
        $sand_tons = ($cement_bags / 20) * 1.5;
        $this->insertEstimate($project_id, 'Sand', 'Material', $sand_tons, 'Ton', $getRate('Sand', 30));
        
        // Tiles: approx apt area + balconies + roof
        $tiles_m2 = ($totalApts * 120) + ($specs['balconies'] * $totalApts * 10) + $specs['roof_area'];
        $this->insertEstimate($project_id, 'Tiles', 'Material', $tiles_m2, 'm2', $getRate('Tiles', 15));
        
        $paint_liters = $totalApts * 150;
        $this->insertEstimate($project_id, 'Paint', 'Material', $paint_liters, 'Liter', $getRate('Paint', 4));
        
        $cables_m = $totalApts * 400;
        $this->insertEstimate($project_id, 'Electrical Cables', 'Material', $cables_m, 'Meter', $getRate('Electrical Cables', 1.5));
        
        $pipes_m = $totalApts * 150;
        $this->insertEstimate($project_id, 'Water Pipes', 'Material', $pipes_m, 'Meter', $getRate('Water Pipes', 3.0));
        
        $total_doors = $specs['doors'] * $totalApts;
        $this->insertEstimate($project_id, 'Doors', 'Material', $total_doors, 'Piece', $getRate('Doors', 150));
        
        $total_windows = $specs['windows'] * $totalApts;
        $this->insertEstimate($project_id, 'Windows', 'Material', $total_windows, 'Piece', $getRate('Windows', 200));
        
        // --- 2. Labor Estimation ---
        // simplified logic: 20 workers for 180 days per 10 apartments
        $workers = ceil($totalApts / 1.5);
        $days = 180 * ceil($project['floors'] / 2);
        $this->insertEstimate($project_id, 'Mason', 'Labor', $workers * 0.4 * $days, 'Mandays', $getRate('Mason', 25));
        $this->insertEstimate($project_id, 'Electrician', 'Labor', $workers * 0.15 * $days, 'Mandays', $getRate('Electrician', 35));
        $this->insertEstimate($project_id, 'Plumber', 'Labor', $workers * 0.15 * $days, 'Mandays', $getRate('Plumber', 35));
        $this->insertEstimate($project_id, 'Painter', 'Labor', $workers * 0.2 * $days, 'Mandays', $getRate('Painter', 20));
        $this->insertEstimate($project_id, 'Supervisor', 'Labor', 2 * $days, 'Mandays', $getRate('Supervisor', 50));

        // --- 3. Equipment Estimation ---
        $this->insertEstimate($project_id, 'Excavator', 'Equipment', 30, 'Days', $getRate('Excavator', 200));
        $this->insertEstimate($project_id, 'Crane', 'Equipment', $days, 'Days', $getRate('Crane', 150));
        $this->insertEstimate($project_id, 'Concrete Mixer', 'Equipment', $days / 3, 'Days', $getRate('Concrete Mixer', 100));
        $this->insertEstimate($project_id, 'Generator', 'Equipment', $days, 'Days', $getRate('Generator', 50));
        
        // --- 4. Other Costs ---
        $this->insertEstimate($project_id, 'Permits & Fees', 'Other', 1, 'Lump Sum', $getRate('Permits & Fees', 15000));
    }
    
    private function insertEstimate($project_id, $name, $category, $qty, $unit, $price) {
        $total = $qty * $price;
        $stmt = $this->db->prepare("INSERT INTO workshop_estimates (project_id, item_name, category, quantity, unit, unit_price, total_price) VALUES (?, ?, ?, ?, ?, ?, ?)");
        $stmt->execute([$project_id, $name, $category, $qty, $unit, $price, $total]);
    }

    public function checkStockAndReserve($id) {
        // Here we would check workshop_estimates against inventory_items
        // For simplicity, we just mark estimates as 'reserved' and auto-generate purchase requests for shortages
        AuthMiddleware::requireLogin();
        
        $this->db->beginTransaction();
        try {
            $stmt = $this->db->prepare("SELECT * FROM workshop_estimates WHERE project_id = ? AND category = 'Material' AND is_reserved = FALSE");
            $stmt->execute([$id]);
            $materials = $stmt->fetchAll();
            
            foreach ($materials as $mat) {
                // Find matching inventory item
                $invStmt = $this->db->prepare("SELECT * FROM inventory_items WHERE name = ?");
                $invStmt->execute([$mat['item_name']]);
                $invItem = $invStmt->fetch();
                
                if ($invItem) {
                    if ($invItem['current_stock'] < $mat['quantity']) {
                        $shortage = $mat['quantity'] - $invItem['current_stock'];
                        // Generate Purchase Request
                        $prStmt = $this->db->prepare("INSERT INTO purchase_requests (project_id, item_id, quantity_needed, estimated_cost) VALUES (?, ?, ?, ?)");
                        $prStmt->execute([$id, $invItem['id'], $shortage, $shortage * $invItem['unit_cost']]);
                    } else {
                        // Deduct stock
                        $upStmt = $this->db->prepare("UPDATE inventory_items SET current_stock = current_stock - ? WHERE id = ?");
                        $upStmt->execute([$mat['quantity'], $invItem['id']]);
                        
                        // Log transaction
                        $user = AuthMiddleware::requireLogin();
                        $trStmt = $this->db->prepare("INSERT INTO inventory_transactions (item_id, type, quantity, project_id, user_id, notes, date) VALUES (?, 'OUT', ?, ?, ?, 'Auto-reserved for project', CURRENT_DATE())");
                        $trStmt->execute([$invItem['id'], $mat['quantity'], $id, $user['user_id']]);
                    }
                }
                
                $updEst = $this->db->prepare("UPDATE workshop_estimates SET is_reserved = TRUE WHERE id = ?");
                $updEst->execute([$mat['id']]);
            }
            
            $this->db->commit();
            echo json_encode(['message' => 'Material reservation processed successfully']);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function updateEstimate($id) {
        AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        
        try {
            $newPrice = $data['unit_price'];
            // Fetch quantity
            $stmt = $this->db->prepare("SELECT quantity FROM workshop_estimates WHERE id = ?");
            $stmt->execute([$id]);
            $est = $stmt->fetch();
            
            if (!$est) {
                http_response_code(404);
                echo json_encode(['error' => 'Estimate not found']);
                return;
            }
            
            $newTotal = $est['quantity'] * $newPrice;
            
            $upd = $this->db->prepare("UPDATE workshop_estimates SET unit_price = ?, total_price = ? WHERE id = ?");
            $upd->execute([$newPrice, $newTotal, $id]);
            
            // Sync with construction materials
            $stmtProj = $this->db->prepare("SELECT project_id, item_name FROM workshop_estimates WHERE id = ?");
            $stmtProj->execute([$id]);
            $estInfo = $stmtProj->fetch();
            if ($estInfo) {
                $updMat = $this->db->prepare("
                    UPDATE construction_materials cm 
                    JOIN constructions c ON cm.construction_id = c.id 
                    SET cm.unit_price = ?, cm.total_estimated_cost = ? 
                    WHERE c.workshop_id = ? AND cm.item_name = ?
                ");
                $updMat->execute([$newPrice, $newTotal, $estInfo['project_id'], $estInfo['item_name']]);
                
                // Recalculate construction estimated_cost
                $recalc = $this->db->prepare("
                    UPDATE constructions c
                    SET c.budget = (SELECT SUM(total_estimated_cost) FROM construction_materials WHERE construction_id = c.id),
                        c.estimated_cost = (SELECT SUM(total_estimated_cost) FROM construction_materials WHERE construction_id = c.id)
                    WHERE c.workshop_id = ?
                ");
                $recalc->execute([$estInfo['project_id']]);
            }
            
            echo json_encode(['message' => 'Price updated successfully']);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function startConstruction($id) {
        $user = AuthMiddleware::requireLogin();
        
        try {
            $this->db->beginTransaction();
            
            $check = $this->db->prepare("SELECT id FROM constructions WHERE workshop_id = ?");
            $check->execute([$id]);
            if ($check->fetch()) {
                throw new Exception("Construction already started for this project.");
            }
            
            $stmtProj = $this->db->prepare("SELECT * FROM workshop_projects WHERE id = ?");
            $stmtProj->execute([$id]);
            $workshop = $stmtProj->fetch();
            
            if (!$workshop) {
                throw new Exception("Workshop project not found.");
            }
            
            $stmtCost = $this->db->prepare("SELECT SUM(total_price) as total_estimated FROM workshop_estimates WHERE project_id = ?");
            $stmtCost->execute([$id]);
            $costRow = $stmtCost->fetch();
            $estimated_cost = $costRow['total_estimated'] ?? 0;
            
            $stmtInsert = $this->db->prepare("
                INSERT INTO constructions (name, owner, location, start_date, end_date, status, budget, estimated_cost, manager, workshop_id)
                VALUES (?, 'Bitar Group', 'Local', CURRENT_DATE(), DATE_ADD(CURRENT_DATE(), INTERVAL 180 DAY), 'Active', ?, ?, ?, ?)
            ");
            $stmtInsert->execute([
                $workshop['name'], 
                $estimated_cost,
                $estimated_cost,
                $user['name'] ?? 'Manager',
                $id
            ]);
            
            $construction_id = $this->db->lastInsertId();
            
            // Only tracking materials for now, or we can copy everything if needed
            // Wait, the user specifically mentioned materials tracking. We will track Materials.
            $stmtEstimates = $this->db->prepare("SELECT * FROM workshop_estimates WHERE project_id = ?");
            $stmtEstimates->execute([$id]);
            $materials = $stmtEstimates->fetchAll();
            
            $stmtMatInsert = $this->db->prepare("
                INSERT INTO construction_materials (construction_id, item_name, category, estimated_quantity, used_quantity, unit, unit_price, total_estimated_cost)
                VALUES (?, ?, ?, ?, 0, ?, ?, ?)
            ");
            
            foreach ($materials as $mat) {
                $stmtMatInsert->execute([
                    $construction_id,
                    $mat['item_name'],
                    $mat['category'],
                    $mat['quantity'],
                    $mat['unit'],
                    $mat['unit_price'],
                    $mat['total_price']
                ]);
            }
            
            $updProj = $this->db->prepare("UPDATE workshop_projects SET status = 'Construction_Started' WHERE id = ?");
            $updProj->execute([$id]);
            
            $this->db->commit();
            AuditLogger::log('CREATE', 'Construction', $construction_id, "Started construction from workshop project: {$workshop['name']}");
            
            echo json_encode(['message' => 'Construction started successfully', 'construction_id' => $construction_id]);
        } catch (Exception $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }
}
