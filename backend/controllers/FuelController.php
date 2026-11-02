<?php
class FuelController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function getMovements($generator_id = null) {
        try {
            $query = "
                SELECT m.*, g.name as generator_name, s.name as supplier_name, u.name as user_name
                FROM fuel_movements m
                JOIN generators g ON m.generator_id = g.id
                LEFT JOIN suppliers s ON m.supplier_id = s.id
                LEFT JOIN users u ON m.user_id = u.id
            ";
            $params = [];
            if ($generator_id) {
                $query .= " WHERE m.generator_id = ?";
                $params[] = $generator_id;
            }
            $query .= " ORDER BY m.date DESC, m.created_at DESC";

            $stmt = $this->db->prepare($query);
            $stmt->execute($params);
            echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function storeMovement() {
        try {
            $data = json_decode(file_get_contents("php://input"), true);
            $userId = isset($data['user_id']) ? $data['user_id'] : 1;

            $receiptPath = null;
            if (isset($_FILES['receipt']) && $_FILES['receipt']['error'] == UPLOAD_ERR_OK) {
                $uploadDir = __DIR__ . '/../../uploads/fuel/';
                if (!is_dir($uploadDir)) mkdir($uploadDir, 0777, true);
                $ext = pathinfo($_FILES['receipt']['name'], PATHINFO_EXTENSION);
                $filename = time() . '_' . rand(1000, 9999) . '.' . $ext;
                $receiptPath = 'uploads/fuel/' . $filename;
                move_uploaded_file($_FILES['receipt']['tmp_name'], $uploadDir . $filename);
            }

            if (!isset($data['generator_id'])) {
                $data = $_POST;
            }

            $generatorId = $data['generator_id'];
            $type = $data['type'];
            $amount = floatval($data['amount']);
            $costPerLiter = floatval($data['cost_per_liter'] ?? 0);
            
            $supplierId = !empty($data['supplier_id']) ? $data['supplier_id'] : null;
            $date = !empty($data['date']) ? $data['date'] : date('Y-m-d H:i:s');
            $notes = !empty($data['notes']) ? $data['notes'] : null;

            $this->db->beginTransaction();

            $stmt = $this->db->prepare("
                INSERT INTO fuel_movements 
                (generator_id, type, amount, cost_per_liter, supplier_id, date, user_id, notes, receipt_path)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ");
            $stmt->execute([
                $generatorId,
                $type,
                $amount,
                $costPerLiter,
                $supplierId,
                $date,
                $userId,
                $notes,
                $receiptPath
            ]);

            $direction = 1;
            if ($type === 'Transfer_Out') $direction = -1;
            $fuelChange = $amount * $direction;

            $updStmt = $this->db->prepare("UPDATE generators SET current_fuel = current_fuel + ? WHERE id = ?");
            $updStmt->execute([$fuelChange, $generatorId]);

            $this->db->commit();
            echo json_encode(['message' => 'Fuel movement recorded successfully']);
        } catch (PDOException $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function updateMovement($id) {
        try {
            $data = json_decode(file_get_contents("php://input"), true);
            if (!$data) $data = $_POST;
            
            $stmt = $this->db->prepare("UPDATE fuel_movements SET amount=?, cost_per_liter=?, date=?, type=?, notes=? WHERE id=?");
            $stmt->execute([
                floatval($data['amount'] ?? 0),
                floatval($data['cost_per_liter'] ?? 0),
                $data['date'] ?? date('Y-m-d'),
                $data['type'] ?? 'Refill',
                $data['notes'] ?? null,
                $id
            ]);
            echo json_encode(['message' => 'Movement updated']);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function deleteMovement($id) {
        try {
            $stmt = $this->db->prepare("UPDATE fuel_movements SET status='Voided', amount=0, cost_per_liter=0, notes=CONCAT(COALESCE(notes,''), ' [VOIDED]') WHERE id=?");
            $stmt->execute([$id]);
            echo json_encode(['message' => 'Movement voided']);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function getSuppliers() {
        AuthMiddleware::requireLogin();
        try {
            $stmt = $this->db->query("SELECT * FROM suppliers WHERE FIND_IN_SET('Fuel', supplier_type) > 0 OR supplier_type = 'General' ORDER BY name ASC");
            echo json_encode($stmt->fetchAll());
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function storeSupplier() {
        try {
            $data = json_decode(file_get_contents("php://input"), true);
            $stmt = $this->db->prepare("INSERT INTO fuel_suppliers (name, contact_info) VALUES (?, ?)");
            $stmt->execute([$data['name'], $data['contact_info'] ?? null]);
            echo json_encode(['message' => 'Supplier added successfully']);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    // =========================================================
    // FUEL RESERVE SIMULATION MODULE
    // =========================================================

    public function getFuelReserveDashboard() {
        try {
            $today = date('Y-m-d');

            $stmt = $this->db->query("
                SELECT g.id, g.name, g.capacity_kva, g.fuel_capacity, g.current_fuel,
                       g.status, g.min_fuel_level_alert, g.expected_fuel_consumption_per_hour,
                       b.name as building_name, b.id as building_id
                FROM generators g
                JOIN buildings b ON g.building_id = b.id
                ORDER BY b.name ASC
            ");
            $generators = $stmt->fetchAll(PDO::FETCH_ASSOC);

            $todayStmt = $this->db->query("
                SELECT r.generator_id,
                       COALESCE(SUM(COALESCE(r.admin_actual_fuel, r.ml_predicted_fuel_burn)), 0) as consumed_today,
                       COALESCE(SUM(r.calculated_hours_worked), 0) as hours_today
                FROM generator_logs r
                WHERE r.log_date = '{$today}'
                GROUP BY r.generator_id
            ");
            $todayData = [];
            while ($row = $todayStmt->fetch(PDO::FETCH_ASSOC)) {
                $todayData[$row['generator_id']] = $row;
            }

            $avgStmt = $this->db->query("
                SELECT generator_id, AVG(COALESCE(admin_actual_fuel, ml_predicted_fuel_burn)) as avg_daily_fuel
                FROM generator_logs
                WHERE COALESCE(admin_actual_fuel, ml_predicted_fuel_burn) > 0 AND log_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
                GROUP BY generator_id
            ");
            $avgData = [];
            while ($row = $avgStmt->fetch(PDO::FETCH_ASSOC)) {
                $avgData[$row['generator_id']] = floatval($row['avg_daily_fuel']);
            }

            $transferTotal = $this->db->query("
                SELECT COALESCE(SUM(amount), 0) as total 
                FROM fuel_movements WHERE type = 'Transfer_Out'
            ")->fetchColumn();

            $buildings = [];
            $totalCapacity = 0;
            $totalFuel = 0;
            $totalConsumedToday = 0;
            $totalHoursToday = 0;
            $lowFuelCount = 0;
            $nearFullCount = 0;
            $alerts = [];

            foreach ($generators as $g) {
                $id = $g['id'];
                $tankCap = floatval($g['fuel_capacity']);
                $currentFuel = floatval($g['current_fuel']);
                $freeCap = $tankCap - $currentFuel;
                $fuelPct = $tankCap > 0 ? round(($currentFuel / $tankCap) * 100, 1) : 0;
                $avgDaily = $avgData[$id] ?? (floatval($g['expected_fuel_consumption_per_hour'] ?? 0) * 8);
                $remainingDays = ($avgDaily > 0) ? round($currentFuel / $avgDaily, 1) : null;
                $todayConsumed = floatval($todayData[$id]['consumed_today'] ?? 0);
                $todayHours = floatval($todayData[$id]['hours_today'] ?? 0);

                $totalCapacity += $tankCap;
                $totalFuel += $currentFuel;
                $totalConsumedToday += $todayConsumed;
                $totalHoursToday += $todayHours;

                $status = 'Normal';
                if ($tankCap > 0 && $currentFuel > $tankCap) {
                    $status = 'Overfilled';
                    $over = round($currentFuel - $tankCap, 1);
                    $alerts[] = ['level' => 'danger', 'icon' => '🔴', 'message' => "{$g['name']} tank is over capacity by {$over} liters."];
                } elseif ($fuelPct < 10) {
                    $status = 'Critical';
                    $lowFuelCount++;
                    $alerts[] = ['level' => 'danger', 'icon' => '🔴', 'message' => "{$g['name']} requires immediate fuel refill ({$fuelPct}%)."];
                } elseif ($fuelPct < 25) {
                    $status = 'Low';
                    $lowFuelCount++;
                    $alerts[] = ['level' => 'warning', 'icon' => '🟡', 'message' => "{$g['name']} is low on fuel ({$fuelPct}% remaining)."];
                } elseif ($fuelPct > 95) {
                    $status = 'Near Full';
                    $nearFullCount++;
                }

                if ($remainingDays !== null && $remainingDays <= 2 && $status === 'Normal') {
                    $status = 'Low';
                    $lowFuelCount++;
                    $alerts[] = ['level' => 'warning', 'icon' => '🟡', 'message' => "{$g['name']} generator has fuel remaining for approximately {$remainingDays} days."];
                }

                $buildings[] = [
                    'id' => $id,
                    'name' => $g['name'],
                    'building_name' => $g['building_name'],
                    'building_id' => $g['building_id'],
                    'capacity_kva' => floatval($g['capacity_kva']),
                    'tank_capacity' => $tankCap,
                    'current_fuel' => round($currentFuel, 1),
                    'free_capacity' => round($freeCap, 1),
                    'fuel_percentage' => $fuelPct,
                    'status' => $status,
                    'remaining_days' => $remainingDays,
                    'consumed_today' => round($todayConsumed, 2),
                    'hours_today' => round($todayHours, 2),
                    'avg_daily_fuel' => round($avgDaily, 2),
                ];
            }

            echo json_encode([
                'summary' => [
                    'total_capacity' => round($totalCapacity, 1),
                    'total_fuel' => round($totalFuel, 1),
                    'total_free' => round($totalCapacity - $totalFuel, 1),
                    'total_consumed_today' => round($totalConsumedToday, 2),
                    'total_hours_today' => round($totalHoursToday, 2),
                    'total_transferred' => round(floatval($transferTotal), 1),
                    'low_fuel_buildings' => $lowFuelCount,
                    'near_full_buildings' => $nearFullCount,
                ],
                'buildings' => $buildings,
                'alerts' => $alerts,
            ]);

        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function getAIAnalysis() {
        try {
            $today = date('Y-m-d');

            $stmt = $this->db->query("
                SELECT g.id, g.name, g.fuel_capacity, g.current_fuel,
                       g.expected_fuel_consumption_per_hour,
                       b.name as building_name
                FROM generators g
                JOIN buildings b ON g.building_id = b.id
                ORDER BY b.name ASC
            ");
            $generators = $stmt->fetchAll(PDO::FETCH_ASSOC);

            $avgStmt = $this->db->query("
                SELECT generator_id, AVG(COALESCE(admin_actual_fuel, ml_predicted_fuel_burn)) as avg_daily_fuel
                FROM generator_logs
                WHERE COALESCE(admin_actual_fuel, ml_predicted_fuel_burn) > 0 AND log_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
                GROUP BY generator_id
            ");
            $avgData = [];
            while ($row = $avgStmt->fetch(PDO::FETCH_ASSOC)) {
                $avgData[$row['generator_id']] = floatval($row['avg_daily_fuel']);
            }

            $todayStmt = $this->db->query("
                SELECT generator_id,
                       COALESCE(SUM(COALESCE(admin_actual_fuel, ml_predicted_fuel_burn)), 0) as consumed_today,
                       COALESCE(SUM(calculated_hours_worked), 0) as hours_today
                FROM generator_logs WHERE log_date = '{$today}' GROUP BY generator_id
            ");
            $todayData = [];
            while ($row = $todayStmt->fetch(PDO::FETCH_ASSOC)) {
                $todayData[$row['generator_id']] = $row;
            }

            $totalFuel = 0;
            $totalCapacity = 0;
            $totalConsumedToday = 0;
            $totalHoursToday = 0;
            $needsRefill = [];
            $overfilled = [];
            $lowDays = [];
            $forecastItems = [];

            foreach ($generators as $g) {
                $id = $g['id'];
                $tankCap = floatval($g['fuel_capacity']);
                $currentFuel = floatval($g['current_fuel']);
                $fuelPct = $tankCap > 0 ? ($currentFuel / $tankCap) * 100 : 0;
                $avgDaily = $avgData[$id] ?? (floatval($g['expected_fuel_consumption_per_hour'] ?? 0) * 8);
                $todayConsumed = floatval($todayData[$id]['consumed_today'] ?? 0);
                $todayHours = floatval($todayData[$id]['hours_today'] ?? 0);
                $remainingDays = $avgDaily > 0 ? round($currentFuel / $avgDaily, 1) : null;

                $totalFuel += $currentFuel;
                $totalCapacity += $tankCap;
                $totalConsumedToday += $todayConsumed;
                $totalHoursToday += $todayHours;

                if ($tankCap > 0 && $currentFuel > $tankCap) {
                    $overfilled[] = $g['name'];
                }
                if ($fuelPct < 25 && $tankCap > 0) {
                    $needsRefill[] = $g['name'];
                }
                if ($remainingDays !== null && $remainingDays <= 5) {
                    $lowDays[] = ['name' => $g['name'], 'days' => $remainingDays, 'avgDaily' => round($avgDaily, 1)];
                }
                if ($remainingDays !== null) {
                    $forecastItems[] = [
                        'name' => $g['name'],
                        'current_fuel' => round($currentFuel, 1),
                        'avg_daily' => round($avgDaily, 2),
                        'remaining_days' => $remainingDays,
                        'depletion_date' => $avgDaily > 0 ? date('Y-m-d', strtotime('+' . intval($remainingDays) . ' days')) : 'N/A',
                    ];
                }
            }

            $messages = [];
            $messages[] = "Current total diesel stock is " . number_format($totalFuel, 0) . " liters.";
            $messages[] = "Total free storage capacity is " . number_format($totalCapacity - $totalFuel, 0) . " liters.";

            if (count($needsRefill) > 0) {
                $messages[] = count($needsRefill) . " building(s) require fuel refilling: " . implode(', ', $needsRefill) . ".";
            } else {
                $messages[] = "All buildings have adequate fuel levels.";
            }

            foreach ($overfilled as $name) {
                $messages[] = "{$name} tank appears to be overfilled — please verify the reading.";
            }
            foreach ($lowDays as $item) {
                $messages[] = "Based on average consumption ({$item['avgDaily']} L/day), {$item['name']} has enough fuel for approximately {$item['days']} days.";
            }

            if ($totalConsumedToday > 0) {
                $messages[] = "Today's total consumption was " . number_format($totalConsumedToday, 2) . " liters over " . number_format($totalHoursToday, 2) . " operating hours.";
            }

            // Transfer recommendation
            usort($forecastItems, fn($a, $b) => ($a['remaining_days'] ?? 999) <=> ($b['remaining_days'] ?? 999));
            if (count($forecastItems) >= 2) {
                $emptiest = $forecastItems[0];
                $fullest = end($forecastItems);
                if ($fullest['current_fuel'] > 300 && ($emptiest['remaining_days'] ?? 999) < 3) {
                    $transferAmt = min(300, round($fullest['current_fuel'] * 0.15));
                    $messages[] = "Recommended action: transfer {$transferAmt} liters from {$fullest['name']} to {$emptiest['name']}.";
                }
            }

            echo json_encode([
                'messages' => $messages,
                'forecast' => $forecastItems,
            ]);

        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function performTransfer() {
        try {
            $data = json_decode(file_get_contents("php://input"), true);
            $fromId = intval($data['from_generator_id'] ?? 0);
            $toId = intval($data['to_generator_id'] ?? 0);
            $amount = floatval($data['amount'] ?? 0);
            $notes = $data['notes'] ?? null;
            $date = $data['date'] ?? date('Y-m-d H:i:s');
            $userId = $data['user_id'] ?? 1;

            if ($fromId <= 0 || $toId <= 0 || $amount <= 0) {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid transfer parameters.']);
                return;
            }
            if ($fromId === $toId) {
                http_response_code(400);
                echo json_encode(['error' => 'Source and destination cannot be the same building.']);
                return;
            }

            $this->db->beginTransaction();

            // Lock lowest ID first to prevent deadlocks
            $firstId = min($fromId, $toId);
            $secondId = max($fromId, $toId);
            $this->db->prepare("SELECT id FROM generators WHERE id = ? FOR UPDATE")->execute([$firstId]);
            $this->db->prepare("SELECT id FROM generators WHERE id = ? FOR UPDATE")->execute([$secondId]);

            $srcStmt = $this->db->prepare("SELECT id, name, current_fuel, fuel_capacity FROM generators WHERE id = ?");
            $srcStmt->execute([$fromId]);
            $src = $srcStmt->fetch(PDO::FETCH_ASSOC);

            $dstStmt = $this->db->prepare("SELECT id, name, current_fuel, fuel_capacity FROM generators WHERE id = ?");
            $dstStmt->execute([$toId]);
            $dst = $dstStmt->fetch(PDO::FETCH_ASSOC);

            if (!$src || !$dst) {
                $this->db->rollBack();
                http_response_code(404);
                echo json_encode(['error' => 'Generator not found.']);
                return;
            }
            if ($amount > floatval($src['current_fuel'])) {
                $this->db->rollBack();
                http_response_code(400);
                echo json_encode(['error' => "Insufficient fuel in {$src['name']}. Available: " . round(floatval($src['current_fuel']), 1) . " L."]);
                return;
            }
            $newDstFuel = floatval($dst['current_fuel']) + $amount;
            if (floatval($dst['fuel_capacity']) > 0 && $newDstFuel > floatval($dst['fuel_capacity'])) {
                $this->db->rollBack();
                $freeInDst = round(floatval($dst['fuel_capacity']) - floatval($dst['current_fuel']), 1);
                http_response_code(400);
                echo json_encode(['error' => "Transfer would overfill {$dst['name']}. Free capacity: {$freeInDst} L."]);
                return;
            }

            $outStmt = $this->db->prepare("
                INSERT INTO fuel_movements (generator_id, type, amount, date, user_id, notes)
                VALUES (?, 'Transfer_Out', ?, ?, ?, ?)
            ");
            $outStmt->execute([$fromId, $amount, $date, $userId, "Transfer to {$dst['name']}. " . $notes]);

            $inStmt = $this->db->prepare("
                INSERT INTO fuel_movements (generator_id, type, amount, date, user_id, notes)
                VALUES (?, 'Transfer_In', ?, ?, ?, ?)
            ");
            $inStmt->execute([$toId, $amount, $date, $userId, "Transfer from {$src['name']}. " . $notes]);

            $this->db->prepare("UPDATE generators SET current_fuel = current_fuel - ? WHERE id = ?")->execute([$amount, $fromId]);
            $this->db->prepare("UPDATE generators SET current_fuel = current_fuel + ? WHERE id = ?")->execute([$amount, $toId]);

            $this->db->commit();

            echo json_encode([
                'message' => "Successfully transferred {$amount} L from {$src['name']} to {$dst['name']}.",
                'from' => $src['name'],
                'to' => $dst['name'],
                'amount' => $amount,
            ]);

        } catch (PDOException $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function getTransferHistory() {
        try {
            $stmt = $this->db->query("
                SELECT m.id, m.date, m.amount, m.notes, m.type, m.created_at,
                       g.name as generator_name, b.name as building_name,
                       u.name as user_name
                FROM fuel_movements m
                JOIN generators g ON m.generator_id = g.id
                JOIN buildings b ON g.building_id = b.id
                LEFT JOIN users u ON m.user_id = u.id
                WHERE m.type IN ('Transfer_In', 'Transfer_Out')
                ORDER BY m.date DESC, m.created_at DESC
                LIMIT 200
            ");
            echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function getFuelForecast() {
        try {
            $stmt = $this->db->query("
                SELECT g.id, g.name, g.fuel_capacity, g.current_fuel,
                       g.expected_fuel_consumption_per_hour,
                       b.name as building_name,
                       AVG(COALESCE(r.admin_actual_fuel, r.ml_predicted_fuel_burn)) as avg_daily_fuel,
                       COUNT(r.id) as report_count
                FROM generators g
                JOIN buildings b ON g.building_id = b.id
                LEFT JOIN generator_logs r 
                    ON r.generator_id = g.id 
                    AND COALESCE(r.admin_actual_fuel, r.ml_predicted_fuel_burn) > 0 
                    AND r.log_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
                GROUP BY g.id, g.name, g.fuel_capacity, g.current_fuel,
                         g.expected_fuel_consumption_per_hour, b.name
                ORDER BY b.name ASC
            ");
            $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

            $forecast = [];
            foreach ($rows as $row) {
                $avgDaily = floatval($row['avg_daily_fuel'] ?? 0);
                if ($avgDaily <= 0) {
                    $avgDaily = floatval($row['expected_fuel_consumption_per_hour'] ?? 0) * 8;
                }
                $currentFuel = floatval($row['current_fuel']);
                $remainingDays = $avgDaily > 0 ? round($currentFuel / $avgDaily, 1) : null;
                $depletionDate = ($remainingDays !== null && $remainingDays > 0)
                    ? date('Y-m-d', strtotime('+' . intval($remainingDays) . ' days'))
                    : null;

                $forecast[] = [
                    'id' => $row['id'],
                    'name' => $row['name'],
                    'building_name' => $row['building_name'],
                    'current_fuel' => round($currentFuel, 1),
                    'tank_capacity' => floatval($row['fuel_capacity']),
                    'avg_daily_fuel' => round($avgDaily, 2),
                    'remaining_days' => $remainingDays,
                    'depletion_date' => $depletionDate,
                    'monthly_estimate' => round($avgDaily * 30, 0),
                    'report_count' => intval($row['report_count']),
                ];
            }

            echo json_encode($forecast);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }
}
