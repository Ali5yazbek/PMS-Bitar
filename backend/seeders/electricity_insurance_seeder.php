<?php
// backend/seeders/electricity_insurance_seeder.php

require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../core/Database.php';

try {
    $db = Database::getInstance()->getConnection();
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    echo "Starting Dual Electricity & Insurance Modules Seeder...\n";

    $db->beginTransaction();

    // 1. CLEAN UP PREVIOUS TEST DATA
    echo "Cleaning up previous test data...\n";
    $testTenantNames = ['Rami', 'Sarah', 'Karim', 'Layla', 'Omar'];
    $placeholders = implode(',', array_fill(0, count($testTenantNames), '?'));
    
    // Find tenant IDs
    $stmt = $db->prepare("SELECT id FROM tenants WHERE full_name IN ($placeholders)");
    $stmt->execute($testTenantNames);
    $tenantIds = $stmt->fetchAll(PDO::FETCH_COLUMN);

    if (!empty($tenantIds)) {
        $tPlaceholders = implode(',', array_fill(0, count($tenantIds), '?'));
        
        // Find contracts
        $stmt = $db->prepare("SELECT id FROM contracts WHERE tenant_id IN ($tPlaceholders)");
        $stmt->execute($tenantIds);
        $contractIds = $stmt->fetchAll(PDO::FETCH_COLUMN);
        
        if (!empty($contractIds)) {
            $cPlaceholders = implode(',', array_fill(0, count($contractIds), '?'));
            $db->prepare("DELETE FROM insurance_transactions WHERE account_id IN (SELECT id FROM insurance_accounts WHERE contract_id IN ($cPlaceholders))")->execute($contractIds);
            $db->prepare("DELETE FROM insurance_accounts WHERE contract_id IN ($cPlaceholders)")->execute($contractIds);
            $db->prepare("DELETE FROM rent_invoices WHERE contract_id IN ($cPlaceholders)")->execute($contractIds);
            $db->prepare("DELETE FROM rent_periods WHERE contract_id IN ($cPlaceholders)")->execute($contractIds);
            $db->prepare("DELETE FROM rent_profiles WHERE contract_id IN ($cPlaceholders)")->execute($contractIds);
            $db->prepare("DELETE FROM contracts WHERE id IN ($cPlaceholders)")->execute($contractIds);
        }
        
        $db->prepare("DELETE FROM tenants WHERE id IN ($tPlaceholders)")->execute($tenantIds);
    }
    
    // Cleanup apartments
    $testAptCodes = ['101', '102', '103', '104', '105'];
    $aPlaceholders = implode(',', array_fill(0, count($testAptCodes), '?'));
    $stmt = $db->prepare("SELECT id FROM apartments WHERE code IN ($aPlaceholders)");
    $stmt->execute($testAptCodes);
    $aptIds = $stmt->fetchAll(PDO::FETCH_COLUMN);
    
    if (!empty($aptIds)) {
        $aIds = implode(',', array_fill(0, count($aptIds), '?'));
        $db->prepare("DELETE FROM electricity_meter_readings WHERE apartment_id IN ($aIds)")->execute($aptIds);
        $db->prepare("DELETE FROM electricity_invoices WHERE apartment_id IN ($aIds)")->execute($aptIds);
        $db->prepare("DELETE FROM electricity_subscriptions WHERE apartment_id IN ($aIds)")->execute($aptIds);
        $db->prepare("DELETE FROM apartments WHERE id IN ($aIds)")->execute($aptIds);
    }

    // 2. INSERT TEST DATA (Building & Apartments)
    // Assume building 1 exists. If not, insert it.
    $stmt = $db->query("SELECT id FROM buildings LIMIT 1");
    $buildingId = $stmt->fetchColumn();
    if (!$buildingId) {
        $db->query("INSERT INTO buildings (name, address) VALUES ('Seeder Building', '123 Test St')");
        $buildingId = $db->lastInsertId();
    }

    $testData = [
        ['name' => 'Rami',  'apt' => '101', 'rent' => 500, 'ins' => 120, 'amp' => 10, 'meter_prev' => 1000, 'meter_curr' => 1250],
        ['name' => 'Sarah', 'apt' => '102', 'rent' => 650, 'ins' => 150, 'amp' => 15, 'meter_prev' => 2100, 'meter_curr' => 2400],
        ['name' => 'Karim', 'apt' => '103', 'rent' => 550, 'ins' => 120, 'amp' => 5,  'meter_prev' => 800,  'meter_curr' => 1000],
        ['name' => 'Layla', 'apt' => '104', 'rent' => 700, 'ins' => 180, 'amp' => 20, 'meter_prev' => 3000, 'meter_curr' => 3400],
        ['name' => 'Omar',  'apt' => '105', 'rent' => 480, 'ins' => 100, 'amp' => 10, 'meter_prev' => 1500, 'meter_curr' => 1700],
    ];

    $startDate = '2026-04-21';
    $endDate = '2027-04-21';

    foreach ($testData as $data) {
        // Insert Tenant
        $stmt = $db->prepare("INSERT INTO tenants (user_id, full_name, phone, email, national_id, status) VALUES (NULL, ?, '12345678', ?, '12345', 'Active')");
        $stmt->execute([$data['name'], strtolower($data['name']) . '@test.com']);
        $tenantId = $db->lastInsertId();

        // Insert Apartment
        $stmt = $db->prepare("INSERT INTO apartments (building_id, code, monthly_rent, monthly_insurance, status) VALUES (?, ?, ?, ?, 'Rented')");
        $stmt->execute([$buildingId, $data['apt'], $data['rent'], $data['ins']]);
        $aptId = $db->lastInsertId();

        // Insert Contract
        $stmt = $db->prepare("INSERT INTO contracts (apartment_id, tenant_id, start_date, end_date, rent_start_date, rent_end_date, status, rent_status, insurance_status, monthly_rent, monthly_insurance) VALUES (?, ?, ?, ?, ?, ?, 'Active', 'Active', 'Active', ?, ?)");
        $stmt->execute([$aptId, $tenantId, $startDate, $endDate, $startDate, $endDate, $data['rent'], $data['ins']]);
        $contractId = $db->lastInsertId();

        // Insert Rent Profile (next_billing_date is explicitly set to Sept 21 2026)
        $nextBillingDate = '2026-09-21';
        $stmt = $db->prepare("INSERT INTO rent_profiles (tenant_id, apartment_id, contract_id, rent_start_date, monthly_amount, next_billing_date, billing_frequency, status, auto_renewal) VALUES (?, ?, ?, ?, ?, ?, 'monthly', 'Active', 1)");
        $stmt->execute([$tenantId, $aptId, $contractId, $startDate, $data['rent'], $nextBillingDate]);

        // Insert Insurance Account & Initial Transaction
        $stmt = $db->prepare("INSERT INTO insurance_accounts (contract_id, total_saved, created_at) VALUES (?, ?, ?)");
        $stmt->execute([$contractId, $data['ins'], $startDate]);
        $insId = $db->lastInsertId();

        $stmt = $db->prepare("INSERT INTO insurance_transactions (account_id, type, amount, date, notes) VALUES (?, 'Deposit', ?, ?, 'Initial Policy Generation')");
        $stmt->execute([$insId, $data['ins'], $startDate]);

        // Insert Electricity Subscriptions
        // 1. Fixed Amp ($5 per amp)
        $stmt = $db->prepare("INSERT INTO electricity_subscriptions (apartment_id, type, monthly_fee, amps, cost_per_amp, start_date, end_date, status, next_billing_date, price_per_kwh) VALUES (?, 'Fixed Amp', ?, ?, 5.00, ?, ?, 'Active', ?, 0)");
        $monthlyFeeAmp = $data['amp'] * 5;
        $stmt->execute([$aptId, $monthlyFeeAmp, $data['amp'], $startDate, $endDate, $nextBillingDate]);

        // 2. Meter (Base Fee is handled via generation logic, rate $0.20)
        $stmt = $db->prepare("INSERT INTO electricity_subscriptions (apartment_id, type, monthly_fee, amps, cost_per_amp, start_date, end_date, status, next_billing_date, last_meter_reading, price_per_kwh) VALUES (?, 'Meter', 0, 0, 0, ?, ?, 'Active', ?, ?, 0.20)");
        $stmt->execute([$aptId, $startDate, $endDate, $nextBillingDate, $data['meter_curr']]); 
        $meterSubId = $db->lastInsertId();

        // GENERATE HISTORICAL DATA (5 Months from April 21 2026 to Sept 21 2026)
        $currentCycleDate = strtotime($startDate);
        $endCycleDate = strtotime($nextBillingDate); // Stop before today

        $totalConsumption = $data['meter_curr'] - $data['meter_prev'];
        $monthlyConsumption = $totalConsumption / 5; // Spread evenly over 5 months
        $currentReadingTracker = $data['meter_prev'];

        while ($currentCycleDate < $endCycleDate) {
            $cycleStart = date('Y-m-d', $currentCycleDate);
            $cycleEnd = date('Y-m-d', strtotime('+1 month', $currentCycleDate));
            $dueDate = $cycleStart; // Invoices generated ON the cycle start date

            // Rent Invoice
            $stmt = $db->prepare("INSERT INTO rent_periods (contract_id, start_date, end_date) VALUES (?, ?, ?)");
            $stmt->execute([$contractId, $cycleStart, $cycleEnd]);
            $periodId = $db->lastInsertId();
            
            $invNum = 'INV-' . date('Ymd', strtotime($dueDate)) . '-' . $contractId . '-' . $periodId;
            $stmt = $db->prepare("INSERT INTO rent_invoices (contract_id, rent_period_id, invoice_number, amount, due_date, status) VALUES (?, ?, ?, ?, ?, 'Paid')");
            $stmt->execute([$contractId, $periodId, $invNum, $data['rent'], $dueDate]);

            // Fixed Amp Invoice
            $stmt = $db->prepare("INSERT INTO electricity_invoices (apartment_id, type, amount, due_date, status) VALUES (?, 'Fixed Amp', ?, ?, 'Paid')");
            $stmt->execute([$aptId, $monthlyFeeAmp, $dueDate]);

            // Meter Reading & Invoice
            $prevReading = $currentReadingTracker;
            $currentReadingTracker += $monthlyConsumption;
            $currReading = round($currentReadingTracker); // Round to avoid weird floats
            $actualConsumption = $currReading - $prevReading;
            
            $billAmount = ($actualConsumption * 0.20) + 5; // User requirement: (Curr - Prev) * 0.20 + 5 Base Fee

            $stmt = $db->prepare("INSERT INTO electricity_meter_readings (apartment_id, meter_number, previous_reading, current_reading, price_per_kwh, consumption, bill_amount, reading_date, status, billing_month, billing_year) VALUES (?, ?, ?, ?, 0.20, ?, ?, ?, 'Approved', ?, ?)");
            $stmt->execute([$aptId, 'MTR-' . $aptId, $prevReading, $currReading, $actualConsumption, $billAmount, $dueDate, date('m', strtotime($dueDate)), date('Y', strtotime($dueDate))]);

            $stmt = $db->prepare("INSERT INTO electricity_invoices (apartment_id, type, amount, due_date, status) VALUES (?, 'Meter', ?, ?, 'Paid')");
            $stmt->execute([$aptId, $billAmount, $dueDate]);

            $currentCycleDate = strtotime('+1 month', $currentCycleDate);
        }
    }

    $db->commit();
    echo "Seeding completed successfully! System is ready to test cron catchup on 21/09/2026.\n";

} catch (Exception $e) {
    if (isset($db) && $db->inTransaction()) {
        $db->rollBack();
    }
    echo "Error during seeding: " . $e->getMessage() . "\n";
}
