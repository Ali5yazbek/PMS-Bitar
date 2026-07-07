<?php
require 'config.php';
$pdo = new PDO('mysql:host=' . DB_HOST . ';dbname=' . DB_NAME, DB_USER, DB_PASS);
$pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);

try {
    $pdo->beginTransaction();

    // 1. Find all duplicates
    $stmt = $pdo->query("SELECT LOWER(TRIM(full_name)) as name, GROUP_CONCAT(id ORDER BY id ASC) as ids FROM tenants GROUP BY LOWER(TRIM(full_name)) HAVING COUNT(id) > 1");
    $duplicates = $stmt->fetchAll();

    foreach($duplicates as $dup) {
        $ids = explode(',', $dup['ids']);
        $primary_id = array_shift($ids); // keep the first one
        
        echo "Merging {$dup['name']} -> Keeping ID $primary_id, moving IDs: " . implode(',', $ids) . "\n";
        
        foreach($ids as $old_id) {
            // Update contracts
            $pdo->prepare("UPDATE contracts SET tenant_id = ? WHERE tenant_id = ?")->execute([$primary_id, $old_id]);
            
            // Delete duplicate tenant
            $pdo->prepare("DELETE FROM tenants WHERE id = ?")->execute([$old_id]);
        }
    }

    $pdo->commit();
    echo "Successfully merged all duplicate tenants!\n";

} catch (Exception $e) {
    $pdo->rollBack();
    echo "Error: " . $e->getMessage() . "\n";
}
