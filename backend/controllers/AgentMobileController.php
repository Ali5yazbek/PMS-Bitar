<?php

class AgentMobileController {
    
    // GET /api/agent/dashboard
    public function dashboard() {
        echo json_encode([
            'assignedBuildings' => 3,
            'generatorTasksDue' => 1,
            'apartmentTasksDue' => 4,
            'dailyReportSubmitted' => false
        ]);
    }

    // GET /api/agent/subscriptions
    public function subscriptions() {
        echo json_encode([
            [
                'id' => 1,
                'building_name' => 'Galaxy',
                'apartment_number' => 'A1',
                'tenant_name' => 'John Doe',
                'meter_type' => 'Metered',
                'previous_reading' => 1250.5,
                'monthly_fee' => 'CFA 15,000',
                'remaining_days' => 19,
                'status' => 'Pending'
            ],
            [
                'id' => 2,
                'building_name' => 'Bitar Tower',
                'apartment_number' => 'B4',
                'tenant_name' => 'Jane Smith',
                'meter_type' => 'Fixed',
                'previous_reading' => 0,
                'monthly_fee' => 'CFA 25,000',
                'remaining_days' => 5,
                'status' => 'Rejected',
                'rejection_reason' => 'Photo blurry, please retake.'
            ]
        ]);
    }

    // POST /api/agent/subscriptions/submit
    public function submitSubscription() {
        echo json_encode(['success' => true]);
    }

    // GET /api/agent-purchases
    public function getPurchases() {
        echo json_encode([
            [
                'building_name' => 'Galaxy',
                'apartment_number' => 'A1',
                'supplier' => 'Hardware Store',
                'amount' => 'CFA 12,000',
                'items' => 'Plumbing pipe',
                'purchase_date' => '2026-08-05',
                'status' => 'Pending Review'
            ]
        ]);
    }

    // POST /api/agent-purchases/submit
    public function submitPurchase() {
        echo json_encode(['success' => true]);
    }

    // GET /api/agent/generators/assigned
    public function assignedGenerators() {
        echo json_encode([
            [
                'id' => 1,
                'building_name' => 'Galaxy',
                'generator_name' => 'CAT 350kVA',
                'running_hours' => 1420.5,
                'fuel_remaining' => 85.0,
                'last_reading_time' => 'Yesterday 07:15 AM'
            ],
            [
                'id' => 2,
                'building_name' => 'Bitar Tower',
                'generator_name' => 'Cummins 500kVA',
                'running_hours' => 3000.0,
                'fuel_remaining' => 50.0,
                'last_reading_time' => 'Yesterday 07:30 AM'
            ]
        ]);
    }

    // POST /api/agent/generators/submit
    public function submitGenerator() {
        echo json_encode(['success' => true]);
    }

    // GET /api/agent/history
    public function history() {
        echo json_encode([
            'generator' => [
                [
                    'building_name' => 'Galaxy',
                    'date' => '2026-08-05',
                    'status' => 'Approved',
                    'submitted_by' => '1'
                ]
            ],
            'apartment' => [],
            'daily_reports' => [],
            'purchases' => []
        ]);
    }

    // POST /api/agent/daily-report/submit
    public function submitDailyReport() {
        echo json_encode(['success' => true]);
    }

    // GET /api/agent/daily-report/latest
    public function latestDailyReport() {
        echo json_encode(null);
    }
}
