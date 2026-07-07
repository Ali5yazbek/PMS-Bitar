<?php
require 'config.php';
$pdo = new PDO('mysql:host=' . DB_HOST . ';dbname=' . DB_NAME, DB_USER, DB_PASS);
$pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);

try {
    $pdo->beginTransaction();

    // 1. Create Tenant
    $stmt = $pdo->prepare("INSERT INTO tenants (full_name, phone) VALUES ('Test User', '12345678')");
    $stmt->execute();
    $tenant_id = $pdo->lastInsertId();

    // 2. Create Apartment T100 in building 1
    // Let's check if building 1 exists, if not use any building
    $b_stmt = $pdo->query("SELECT id FROM buildings LIMIT 1");
    $building_id = $b_stmt->fetchColumn();
    if (!$building_id) {
        $pdo->query("INSERT INTO buildings (name) VALUES ('Test Building')");
        $building_id = $pdo->lastInsertId();
    }

    $stmt = $pdo->prepare("INSERT INTO apartments (building_id, code, monthly_rent, monthly_insurance) VALUES (?, 'T100', 500, 50)");
    $stmt->execute([$building_id]);
    $apartment_id = $pdo->lastInsertId();

    // 3. Create Contract
    $stmt = $pdo->prepare("INSERT INTO contracts (apartment_id, tenant_id, start_date, end_date, monthly_rent, monthly_insurance, status) VALUES (?, ?, '2026-06-01', '2027-05-31', 500, 50, 'Active')");
    $stmt->execute([$apartment_id, $tenant_id]);
    $contract_id = $pdo->lastInsertId();

    // 4. Create 2 unpaid rent invoices
    $stmt = $pdo->prepare("INSERT INTO rent_invoices (contract_id, invoice_number, amount, due_date, status) VALUES (?, ?, 500, ?, 'Unpaid')");
    $stmt->execute([$contract_id, 'INV-TEST-06', '2026-06-05']);
    $stmt->execute([$contract_id, 'INV-TEST-07', '2026-07-05']);

    // 5. Create Electricity Subscription
    $stmt = $pdo->prepare("INSERT INTO electricity_subscriptions (apartment_id, monthly_fee, amps, cost_per_amp, start_date, status) VALUES (?, 10, 5, 2, '2026-06-01', 'Active')");
    $stmt->execute([$apartment_id]);

    // 6. Create 2 unpaid electricity invoices
    $stmt = $pdo->prepare("INSERT INTO electricity_invoices (apartment_id, type, amount, amount_paid, due_date, status) VALUES (?, 'Subscription', 20, 0, ?, 'Unpaid')");
    $stmt->execute([$apartment_id, '2026-06-05']);
    $stmt->execute([$apartment_id, '2026-07-05']);

    // 7. Make sure the apartment is linked to the tenant in `apartments` table if that's how it's tracked
    // Some logic tracks current tenant in `apartments.tenant_id`. Let's just be safe.
    // Wait, the apartments table schema:
    $check = $pdo->query("DESCRIBE apartments");
    $cols = $check->fetchAll(PDO::FETCH_COLUMN);
    if (in_array('tenant_id', $cols)) {
        $pdo->prepare("UPDATE apartments SET tenant_id = ?, status = 'Rented' WHERE id = ?")->execute([$tenant_id, $apartment_id]);
    } else {
        $pdo->prepare("UPDATE apartments SET status = 'Rented' WHERE id = ?")->execute([$apartment_id]);
    }

    $pdo->commit();
    echo "Successfully created Test User, Apt T100, Contract $contract_id, and 2 months of unpaid invoices for Rent & Electricity.\n";

} catch (Exception $e) {
    $pdo->rollBack();
    echo "Error: " . $e->getMessage() . "\n";
}
