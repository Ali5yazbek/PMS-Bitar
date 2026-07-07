<?php
require 'backend/core/Database.php';
require 'backend/config.php';
$db = Database::getInstance()->getConnection();

$expenseStmt = $db->prepare("
    SELECT e.*, u.name as user_name 
    FROM expenses e 
    LEFT JOIN users u ON e.user_id = u.id 
    WHERE e.entity_type = 'Construction' AND e.entity_id = 4
    ORDER BY e.date DESC, e.id DESC
");
$expenseStmt->execute();
$expenses = $expenseStmt->fetchAll(PDO::FETCH_ASSOC);
echo count($expenses) . " expenses found.\n";
print_r($expenses);
