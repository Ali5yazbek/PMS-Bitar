<?php
require 'backend/core/Database.php';
require 'backend/config.php';
$db = Database::getInstance()->getConnection();

$expenseStmt = $db->prepare("
    SELECT e.*, u.name as user_name 
    FROM expenses e 
    LEFT JOIN users u ON e.user_id = u.id 
    WHERE e.entity_type = 'Construction'
    ORDER BY e.date DESC, e.id DESC
");
$expenseStmt->execute();
$expenses = $expenseStmt->fetchAll(PDO::FETCH_ASSOC);
echo count($expenses) . " expenses found.\n";
foreach($expenses as $e) {
    echo "ID: {$e['id']} | EntityID: {$e['entity_id']} | Ref: {$e['reference_id']} | Amount: {$e['amount']} \n";
}
