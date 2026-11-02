<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/core/Database.php';

try {
    $db = \Database::getInstance()->getConnection();
    
    // Get all unpaid invoices
    $stmt = $db->query("
        SELECT ri.*, c.apartment_id
        FROM rent_invoices ri
        JOIN rent_periods rp ON ri.rent_period_id = rp.id
        JOIN contracts c ON rp.contract_id = c.id
        WHERE ri.status = 'Unpaid'
    ");
    $invoices = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Some rent_invoices might not have rent_period_id set if they are old schema.
    // Let's get them by contract_id as well
    $stmt2 = $db->query("
        SELECT ri.*, c.apartment_id
        FROM rent_invoices ri
        JOIN contracts c ON ri.contract_id = c.id
        WHERE ri.status = 'Unpaid' AND ri.rent_period_id IS NULL
    ");
    $invoices2 = $stmt2->fetchAll(PDO::FETCH_ASSOC);

    $allInvoices = array_merge($invoices, $invoices2);

    $tasksCreated = 0;
    foreach ($allInvoices as $inv) {
        // Find agent assigned to the apartment's building
        $stmtAgent = $db->prepare("SELECT agent_id FROM field_agent_assignments WHERE building_id = (SELECT building_id FROM apartments WHERE id = ?)");
        $stmtAgent->execute([$inv['apartment_id']]);
        $agentId = $stmtAgent->fetchColumn();

        // Fallback to a default agent (e.g., ID 1) if no assignment is found
        if (!$agentId) {
            $stmtFallback = $db->query("SELECT id FROM users WHERE role = 'agent' LIMIT 1");
            $agentId = $stmtFallback->fetchColumn() ?: 1;
        }

        // Check if task already exists
        $stmtCheck = $db->prepare("SELECT id FROM tasks WHERE type = 'Rent Collection' AND related_entity_type = 'Contract' AND related_entity_id = ?");
        // Using contract_id as related_entity_id, this is how AgentRentController joins.
        // The join is: JOIN contracts c ON t.related_entity_id = c.id
        $contractId = $inv['contract_id']; // Wait, old schema had contract_id directly on rent_invoices. If rent_period_id is used, we need to get contract_id from rent_periods.
        if (!$contractId && isset($inv['rent_period_id'])) {
            $stmtC = $db->prepare("SELECT contract_id FROM rent_periods WHERE id = ?");
            $stmtC->execute([$inv['rent_period_id']]);
            $contractId = $stmtC->fetchColumn();
        }

        if ($contractId) {
            $stmtCheck->execute([$contractId]);
            if (!$stmtCheck->fetchColumn()) {
                // Create task
                $stmtTask = $db->prepare("
                    INSERT INTO tasks (title, type, assigned_to, due_date, priority, related_entity_type, related_entity_id) 
                    VALUES (?, 'Rent Collection', ?, ?, 'High', 'Contract', ?)
                ");
                $stmtTask->execute(["Collect Rent - Pending Invoice", $agentId, $inv['due_date'], $contractId]);
                $tasksCreated++;
            }
        }
    }

    echo "Successfully generated $tasksCreated missing Rent Collection tasks.\n";

} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
