<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/core/Database.php';

try {
    $db = Database::getInstance()->getConnection();
    
    // Function to add index if it doesn't exist
    function addIndexIfNotExists($db, $table, $column, $indexName) {
        try {
            $stmt = $db->prepare("SHOW INDEX FROM $table WHERE Key_name = ?");
            $stmt->execute([$indexName]);
            if ($stmt->rowCount() == 0) {
                $db->exec("ALTER TABLE $table ADD INDEX $indexName ($column)");
                echo "✅ Index $indexName on $table($column) created.\n";
            } else {
                echo "ℹ️ Index $indexName on $table already exists.\n";
            }
        } catch (PDOException $e) {
            echo "⚠️ Could not add index $indexName on $table: " . $e->getMessage() . "\n";
        }
    }

    addIndexIfNotExists($db, 'apartments', 'building_id', 'idx_apartments_building_id');
    addIndexIfNotExists($db, 'apartments', 'status', 'idx_apartments_status');
    
    addIndexIfNotExists($db, 'tenants', 'status', 'idx_tenants_status');
    
    addIndexIfNotExists($db, 'contracts', 'apartment_id', 'idx_contracts_apartment_id');
    addIndexIfNotExists($db, 'contracts', 'tenant_id', 'idx_contracts_tenant_id');
    addIndexIfNotExists($db, 'contracts', 'status', 'idx_contracts_status');
    
    addIndexIfNotExists($db, 'electricity_invoices', 'apartment_id', 'idx_electricity_invoices_apartment_id');
    addIndexIfNotExists($db, 'electricity_invoices', 'status', 'idx_electricity_invoices_status');
    addIndexIfNotExists($db, 'electricity_invoices', 'type', 'idx_electricity_invoices_type');
    
    addIndexIfNotExists($db, 'electricity_subscriptions', 'apartment_id', 'idx_electricity_subs_apartment_id');
    addIndexIfNotExists($db, 'electricity_subscriptions', 'status', 'idx_electricity_subs_status');

    addIndexIfNotExists($db, 'rent_invoices', 'profile_id', 'idx_rent_invoices_profile_id');
    addIndexIfNotExists($db, 'rent_invoices', 'status', 'idx_rent_invoices_status');

    addIndexIfNotExists($db, 'agent_subscription_readings', 'subscription_id', 'idx_asr_subscription_id');
    addIndexIfNotExists($db, 'agent_subscription_readings', 'status', 'idx_asr_status');
    
    addIndexIfNotExists($db, 'notifications', 'user_id', 'idx_notifications_user_id');
    addIndexIfNotExists($db, 'notifications', 'is_read', 'idx_notifications_is_read');

    echo "🎉 Database indexing complete.\n";
    
} catch (Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "\n";
}
