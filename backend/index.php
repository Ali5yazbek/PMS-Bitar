<?php
// Set Central Africa Timezone (UTC+1)
date_default_timezone_set('Africa/Douala');

// CORS Headers — allow both local dev and production domain
$allowedOrigins = [
    'http://localhost:3000',
    'http://localhost',
    'http://127.0.0.1:3000',
    $_ENV['APP_URL'] ?? '',
];
$origin = $_SERVER['HTTP_ORIGIN'] ?? '';
if (in_array($origin, $allowedOrigins, true) || empty($origin)) {
    header("Access-Control-Allow-Origin: " . ($origin ?: '*'));
} else {
    header("Access-Control-Allow-Origin: " . ($_ENV['APP_URL'] ?? '*'));
}
header("Access-Control-Allow-Credentials: true");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=UTF-8");
header("Cache-Control: no-cache, no-store, must-revalidate");
header("Pragma: no-cache");
header("Expires: 0");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Global error handler — returns JSON instead of 500 HTML page
set_error_handler(function($severity, $message, $file, $line) {
    http_response_code(500);
    echo json_encode([
        'error' => 'PHP Error',
        'message' => $message,
        'file' => basename($file),
        'line' => $line
    ]);
    exit();
});

set_exception_handler(function($e) {
    http_response_code(500);
    echo json_encode([
        'error' => 'Exception',
        'message' => $e->getMessage(),
        'file' => basename($e->getFile()),
        'line' => $e->getLine()
    ]);
    exit();
});

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/core/Database.php';
require_once __DIR__ . '/core/JWT.php';
require_once __DIR__ . '/core/Router.php';
require_once __DIR__ . '/middleware/AuthMiddleware.php';
require_once __DIR__ . '/utils/AuditLogger.php';

// Load controllers
foreach (glob(__DIR__ . '/controllers/*.php') as $filename) {
    require_once $filename;
}

$router = new Router();

// Define routes
$router->get('/api/health', function() {
    echo json_encode(["status" => "ok", "message" => "PMS API is running."]);
});

// Auth Routes
$router->post('/api/auth/login', [AuthController::class, 'login']);
$router->get('/api/auth/me', [AuthController::class, 'me']);

// User Management Routes
$router->get('/api/users', [UsersController::class, 'index']);
$router->post('/api/users', [UsersController::class, 'store']);
$router->put('/api/users/{id}', [UsersController::class, 'update']);
$router->delete('/api/users/{id}', [UsersController::class, 'destroy']);

// Building Routes
$router->get('/api/buildings', [BuildingsController::class, 'index']);
$router->get('/api/buildings/{id}', [BuildingsController::class, 'show']);
$router->post('/api/buildings', [BuildingsController::class, 'store']);
$router->put('/api/buildings/{id}', [BuildingsController::class, 'update']);
$router->delete('/api/buildings/{id}', [BuildingsController::class, 'destroy']);

$router->get('/api/construction-materials', [ConstructionController::class, 'getGlobalMaterials']);

// Apartment Routes
$router->get('/api/apartments', [ApartmentsController::class, 'index']);
$router->get('/api/apartments/financials', [ApartmentsController::class, 'financials']);
$router->get('/api/apartments/{id}', [ApartmentsController::class, 'show']);
$router->get('/api/apartments/{id}/financial-overview', [ApartmentsController::class, 'financialOverview']);
$router->get('/api/apartments/{id}/rent-invoices', [ApartmentsController::class, 'getInvoices']);
$router->post('/api/apartments/{id}/expenses', [ApartmentsController::class, 'addExpense']);
$router->post('/api/apartments', [ApartmentsController::class, 'store']);
$router->put('/api/apartments/{id}', [ApartmentsController::class, 'update']);
$router->delete('/api/apartments/{id}', [ApartmentsController::class, 'destroy']);

// Tenant Routes
$router->get('/api/tenants', [TenantsController::class, 'index']);
$router->get('/api/tenants/{id}', [TenantsController::class, 'show']);
$router->get('/api/tenants/{id}/rent-history', [TenantsController::class, 'rentHistory']);
$router->get('/api/tenants/{id}/apartments', [TenantsController::class, 'apartments']);
$router->put('/api/tenants/{id}/contract', [TenantsController::class, 'updateContract']);
$router->post('/api/tenants', [TenantsController::class, 'store']);
$router->put('/api/tenants/{id}', [TenantsController::class, 'update']);
$router->delete('/api/tenants/{id}', [TenantsController::class, 'destroy']);
$router->delete('/api/rent/payments/{id}', [RentController::class, 'deletePayment']);

// --- Rent Profiles Routes ---
$router->get('/api/rent-profiles/tenant/{id}', [RentProfilesController::class, 'getByTenant']);
$router->put('/api/rent-profiles/{id}', [RentProfilesController::class, 'update']);
$router->post('/api/rent-profiles/{id}/renew', [RentProfilesController::class, 'renew']);
$router->get('/api/rent-profiles/{id}/history', [RentProfilesController::class, 'getHistory']);
$router->post('/api/rent-profiles/process-auto-renewals', [RentProfilesController::class, 'processAutoRenewals']);

// --- Contract Routes ---
$router->get('/api/contracts', [ContractsController::class, 'index']);
$router->get('/api/contracts/pending', [ContractsController::class, 'pending']);
$router->get('/api/contracts/{id}', [ContractsController::class, 'show']);
$router->post('/api/contracts', [ContractsController::class, 'store']);
$router->put('/api/contracts/{id}', [ContractsController::class, 'update']);
$router->put('/api/contracts/{id}/status', [ContractsController::class, 'updateStatus']);
$router->post('/api/contracts/{id}/renew', [ContractsController::class, 'renewContract']);
$router->post('/api/contracts/{id}/generate-rent', [ContractsController::class, 'generateMissingRent']);
$router->delete('/api/contracts/{id}', [ContractsController::class, 'delete']);
$router->put('/api/contracts/{id}/pause-rent', [ContractsController::class, 'pauseRent']);
$router->put('/api/contracts/{id}/end-rent', [ContractsController::class, 'endRent']);
$router->put('/api/contracts/{id}/resume-rent', [ContractsController::class, 'resumeRent']);
$router->post('/api/contracts/{id}/renew-rent-manually', [ContractsController::class, 'renewRentManually']);

// Tenant Portal Routes
$router->get('/api/tenant-portal/dashboard', [TenantPortalController::class, 'dashboard']);
$router->post('/api/tenant-portal/contract/sign', [TenantPortalController::class, 'uploadSignedContract']);
$router->get('/api/tenant-portal/rent-history', [TenantPortalController::class, 'rentHistory']);
$router->post('/api/tenant-portal/renewal/request', [TenantPortalController::class, 'requestRenewal']);
$router->post('/api/tenant-portal/renewal/decline', [TenantPortalController::class, 'declineRenewal']);

// Rent Routes
$router->get('/api/rent/dashboard', [RentController::class, 'rentManagementDashboard']);
$router->get('/api/rent/invoices', [RentController::class, 'index']);
$router->post('/api/rent/payment', [RentController::class, 'pay']);
$router->post('/api/rent/historical', [RentController::class, 'addHistorical']);
$router->post('/api/rent/generate', [RentController::class, 'generateInvoices']); // Trigger manually or lazy

// Insurance Routes
$router->get('/api/insurance/dashboard', [InsuranceController::class, 'dashboard']);
$router->get('/api/insurance', [InsuranceController::class, 'index']);
$router->get('/api/insurance/{id}', [InsuranceController::class, 'show']);
$router->put('/api/insurance/accounts/{id}/deposit', [InsuranceController::class, 'updateDeposit']);
$router->get('/api/insurance/by-tenant/{id}', [InsuranceController::class, 'getByTenant']);
$router->post('/api/insurance/transaction', [InsuranceController::class, 'addTransaction']);

// Inventory Routes
$router->get('/api/inventory', [InventoryController::class, 'index']);
$router->post('/api/inventory', [InventoryController::class, 'store']);
$router->post('/api/inventory/transaction', [InventoryController::class, 'transaction']);
$router->get('/api/inventory/purchase_requests', [InventoryController::class, 'purchaseRequests']);

// Workshop Routes
$router->get('/api/workshop', [WorkshopController::class, 'index']);
$router->get('/api/workshop/{id}', [WorkshopController::class, 'show']);
$router->post('/api/workshop', [WorkshopController::class, 'store']);
$router->post('/api/workshop/{id}/reserve', [WorkshopController::class, 'checkStockAndReserve']);
$router->put('/api/workshop/estimates/{id}', [WorkshopController::class, 'updateEstimate']);
$router->post('/api/workshop/{id}/start-construction', [WorkshopController::class, 'startConstruction']);

// Apartment Cost Routes
$router->get('/api/apartment-costs/report', [ApartmentCostController::class, 'getReport']);
$router->get('/api/buildings/{id}/apartment-costs', [ApartmentCostController::class, 'getBuildingCosts']);
$router->get('/api/apartments/{id}/costs/total', [ApartmentCostController::class, 'getTotalCosts']);
$router->get('/api/apartments/{id}/costs', [ApartmentCostController::class, 'getApartmentCosts']);
$router->post('/api/apartments/{id}/costs', [ApartmentCostController::class, 'store']);

// Dashboard
$router->get('/api/dashboard/stats', [DashboardController::class, 'stats']);
$router->get('/api/dashboard/expiring-items', [DashboardController::class, 'expiringItems']);

// Settings
$router->get('/api/settings/rates', [SettingsController::class, 'getRates']);
$router->post('/api/settings/rates', [SettingsController::class, 'addRate']);
$router->put('/api/settings/rates/{id}', [SettingsController::class, 'updateRate']);
$router->delete('/api/settings/rates/{id}', [SettingsController::class, 'deleteRate']);

// Schedule & AI Assistant
$router->get('/api/schedule/summary', [ScheduleController::class, 'getSummary']);
$router->get('/api/schedule/calendar', [ScheduleController::class, 'getCalendarEvents']);
$router->get('/api/schedule/notifications', [ScheduleController::class, 'getNotifications']);

// Audit
$router->get('/api/audit', [AuditController::class, 'index']);

// Suppliers
$router->get('/api/suppliers/dashboard', [SuppliersController::class, 'dashboard']);
$router->get('/api/suppliers', [SuppliersController::class, 'index']);
$router->get('/api/suppliers/{id}', [SuppliersController::class, 'show']);
$router->post('/api/suppliers', [SuppliersController::class, 'store']);
$router->post('/api/suppliers/{id}/payments', [SuppliersController::class, 'recordPayment']);

// Purchase Orders
$router->get('/api/purchase-orders', [PurchaseOrdersController::class, 'index']);
$router->post('/api/purchase-orders', [PurchaseOrdersController::class, 'store']);
$router->put('/api/purchase-orders/{id}/status', [PurchaseOrdersController::class, 'updateStatus']);
$router->post('/api/purchase-orders/{id}/deliver', [PurchaseOrdersController::class, 'recordDelivery']);
$router->post('/api/purchase-orders/{id}/return', [PurchaseOrdersController::class, 'returnDelivery']);
$router->delete('/api/purchase-orders/{id}', [PurchaseOrdersController::class, 'delete']);

// Construction Stock
$router->get('/api/construction/{id}/site-stock', [ConstructionStockController::class, 'getSiteStock']);
$router->post('/api/construction/site-stock/movement', [ConstructionStockController::class, 'recordMovement']);

// Warehouse Routes
$router->get('/api/warehouse', [WarehouseController::class, 'index']);
$router->get('/api/warehouse/stats', [WarehouseController::class, 'stats']);
$router->get('/api/warehouse/{id}', [WarehouseController::class, 'show']);
$router->post('/api/warehouse', [WarehouseController::class, 'store']);
$router->put('/api/warehouse/{id}', [WarehouseController::class, 'update']);
$router->delete('/api/warehouse/{id}', [WarehouseController::class, 'destroy']);

// Depot & Transfer Routes
$router->get('/api/depots', [DepotController::class, 'index']);
$router->post('/api/depots', [DepotController::class, 'store']);
$router->put('/api/depots/{id}', [DepotController::class, 'update']);
$router->delete('/api/depots/{id}', [DepotController::class, 'destroy']);
$router->get('/api/transfers', [TransferController::class, 'index']);
$router->post('/api/transfers', [TransferController::class, 'store']);

// POS Routes
$router->get('/api/pos/invoices', [POSController::class, 'index']);
$router->get('/api/pos/invoices/{id}', [POSController::class, 'show']);
$router->put('/api/pos/invoices/{id}', [POSController::class, 'update']);
$router->post('/api/pos/checkout', [POSController::class, 'checkout']);

// Energy Routes
$router->get('/api/energy/generators', [EnergyController::class, 'getGenerators']);
$router->get('/api/energy/generators/{id}', [EnergyController::class, 'getGenerator']);
$router->post('/api/energy/generators', [EnergyController::class, 'storeGenerator']);
$router->put('/api/energy/generators/{id}', [EnergyController::class, 'updateGenerator']);
$router->put('/api/energy/generators/{id}/status', [EnergyController::class, 'updateGeneratorStatus']);
$router->delete('/api/energy/generators/{id}', [EnergyController::class, 'deleteGenerator']);
$router->get('/api/energy/generators/{id}/reports', [EnergyController::class, 'getDailyReports']);
$router->get('/api/energy/reports/pending', [EnergyController::class, 'getPendingGeneratorReadings']);
$router->post('/api/energy/reports', [EnergyController::class, 'storeDailyReading']);
$router->post('/api/energy/reports/{id}/verify', [EnergyController::class, 'verifyGeneratorReading']);
$router->post('/api/energy/reports/verify', [EnergyController::class, 'verifyActualFuel']);
$router->get('/api/energy/generators/{id}/stats', [EnergyController::class, 'getGeneratorStats']);
$router->get('/api/energy/generators/{id}/ai-insights', [EnergyController::class, 'getAIInsights']);
$router->get('/api/energy/dashboard', [EnergyController::class, 'getEnergyDashboardStats']);
$router->get('/api/energy/alerts', [EnergyController::class, 'getAlerts']);
$router->put('/api/energy/alerts/{id}/read', [EnergyController::class, 'markAlertRead']);
$router->get('/api/energy/executive-dashboard', [EnergyController::class, 'getExecutiveDashboardStats']);
$router->get('/api/energy/smart-alerts', [EnergyController::class, 'getSmartMonitoringAlerts']);
$router->put('/api/energy/smart-alerts/{id}/resolve', [EnergyController::class, 'resolveSmartAlert']);
$router->get('/api/energy/ai/summaries', [EnergyController::class, 'getAISummaries']);
$router->post('/api/energy/ai/chat', [EnergyController::class, 'aiChatQuery']);
$router->get('/api/energy/calendar', [EnergyController::class, 'getCalendarEvents']);

// Fuel Routes
$router->get('/api/fuel/movements', [FuelController::class, 'getMovements']);
$router->get('/api/fuel/generators/{id}/movements', [FuelController::class, 'getMovements']);
$router->post('/api/fuel/movements', [FuelController::class, 'storeMovement']);
$router->get('/api/fuel/suppliers', [FuelController::class, 'getSuppliers']);
$router->post('/api/fuel/suppliers', [FuelController::class, 'storeSupplier']);

// Fuel Reserve Simulation Routes
$router->get('/api/fuel/reserve/dashboard', [FuelController::class, 'getFuelReserveDashboard']);
$router->get('/api/fuel/reserve/ai-analysis', [FuelController::class, 'getAIAnalysis']);
$router->post('/api/fuel/reserve/transfer', [FuelController::class, 'performTransfer']);
$router->get('/api/fuel/reserve/transfers', [FuelController::class, 'getTransferHistory']);
$router->get('/api/fuel/reserve/forecast', [FuelController::class, 'getFuelForecast']);

// Electricity Routes
$router->get('/api/electricity/subscriptions', [ElectricityController::class, 'getSubscriptions']);
$router->get('/api/energy/buildings/{id}/subscriptions', [ElectricityController::class, 'getBuildingSubscriptions']);
$router->get('/api/energy/apartments/{id}/subscriptions', [ElectricityController::class, 'getApartmentSubscription']);
$router->post('/api/energy/apartments/{id}/subscriptions', [ElectricityController::class, 'storeSubscription']);
$router->post('/api/energy/apartments/{id}/renew-subscription', [ElectricityController::class, 'renewSubscription']);
$router->post('/api/energy/apartments/{id}/request-renewal', [ElectricityController::class, 'requestRenewal']);
$router->post('/api/energy/apartments/{id}/respond-renewal', [ElectricityController::class, 'respondRenewal']);
$router->get('/api/energy/apartments/{id}/subscription-invoices', [ElectricityController::class, 'getSubscriptionInvoices']);
$router->get('/api/energy/apartments/{id}/meter-readings', [ElectricityController::class, 'getMeterReadings']);
$router->get('/api/energy/apartments/{id}/meter-readings/latest', [ElectricityController::class, 'getLatestMeterReading']);
$router->get('/api/energy/apartments/meter-readings/pending', [ElectricityController::class, 'getPendingMeterReadings']);
$router->post('/api/energy/apartments/{id}/meter-readings', [ElectricityController::class, 'storeMeterReading']);
$router->post('/api/energy/apartments/meter-readings/{id}/verify', [ElectricityController::class, 'verifyMeterReading']);
$router->get('/api/electricity/apartments/{id}/invoices', [ElectricityController::class, 'getInvoices']);
$router->put('/api/electricity/invoices/{id}/pay', [ElectricityController::class, 'payInvoice']);
$router->get('/api/electricity/apartments/{id}/analysis', [ElectricityController::class, 'getApartmentAnalysis']);

// Construction Routes
$router->get('/api/constructions', [ConstructionController::class, 'index']);
$router->get('/api/constructions/{id}', [ConstructionController::class, 'show']);
$router->post('/api/constructions', [ConstructionController::class, 'store']);
$router->put('/api/constructions/{id}', [ConstructionController::class, 'update']);
$router->delete('/api/constructions/{id}', [ConstructionController::class, 'destroy']);

// Expense Routes
$router->get('/api/expenses', [ExpenseController::class, 'index']);
$router->get('/api/expenses/dashboard', [ExpenseController::class, 'dashboard']);
$router->post('/api/expenses', [ExpenseController::class, 'store']);
$router->post('/api/expenses/apartment', [ExpenseController::class, 'assignApartmentExpense']);
$router->get('/api/expenses/apartment/{id}', [ExpenseController::class, 'getApartmentExpenses']);

// Reports Routes
$router->get('/api/reports/rent-collection', [ReportsController::class, 'rentCollection']);
$router->get('/api/reports/outstanding-balance', [ReportsController::class, 'outstandingBalance']);
$router->get('/api/reports/insurance', [ReportsController::class, 'insurance']);
$router->get('/api/reports/apartment-expense', [ReportsController::class, 'apartmentExpense']);
$router->get('/api/reports/contract-expiration', [ReportsController::class, 'contractExpiration']);
$router->get('/api/reports/renewal', [ReportsController::class, 'renewal']);
$router->get('/api/reports/tenant-payment', [ReportsController::class, 'tenantPaymentHistory']);
$router->get('/api/reports/building-financial', [ReportsController::class, 'buildingFinancialSummary']);
$router->get('/api/reports/detailed-financial-buildings', [ReportsController::class, 'detailedFinancialBuildings']);
$router->get('/api/reports/generator-subscriptions', [ReportsController::class, 'generatorSubscriptions']);

// Sales Routes
$router->get('/api/sales', [SalesController::class, 'index']);
$router->get('/api/sales/dashboard', [SalesController::class, 'dashboard']);

// AC Maintenance Routes
$router->get('/api/maintenance/tasks', [ACMaintenanceController::class, 'workerTasks']);
$router->post('/api/maintenance/tasks/{id}/submit', [ACMaintenanceController::class, 'submitTask']);
$router->get('/api/maintenance/admin/tasks', [ACMaintenanceController::class, 'pendingTasks']);
$router->get('/api/maintenance/admin/history', [ACMaintenanceController::class, 'taskHistory']);
$router->post('/api/maintenance/admin/tasks/{id}/approve', [ACMaintenanceController::class, 'approveTask']);
$router->post('/api/maintenance/admin/tasks/{id}/reject', [ACMaintenanceController::class, 'rejectTask']);
$router->post('/api/maintenance/admin/buildings/{id}/generate', [ACMaintenanceController::class, 'generateSmartSchedules']);
$router->get('/api/maintenance/admin/worker-reports', [ACMaintenanceController::class, 'workerReport']);

// Agent Routes
$router->get('/api/energy/agent/dashboard-stats', [AgentController::class, 'dashboardStats']);
$router->get('/api/energy/agent/history/generators', [AgentController::class, 'getGeneratorHistory']);
$router->get('/api/energy/agent/history/apartments', [AgentController::class, 'getApartmentHistory']);
$router->get('/api/energy/admin/agent-reports', [AgentController::class, 'agentReports']);
$router->post('/api/energy/agent/generator-reading', [AgentController::class, 'storeGeneratorReading']);
$router->post('/api/energy/agent/apartment-reading', [AgentController::class, 'storeApartmentReading']);

// Agent Subscription Task Routes
$router->get('/api/energy/agent/subscription-tasks', [AgentController::class, 'getSubscriptionTasks']);
$router->post('/api/energy/agent/subscription-reading', [AgentController::class, 'storeSubscriptionMeterReading']);
$router->get('/api/energy/agent/subscription-readings/pending', [AgentController::class, 'getPendingSubscriptionReadings']);
$router->post('/api/energy/agent/subscription-readings/{id}/verify', [AgentController::class, 'verifySubscriptionReading']);
$router->get('/api/energy/agent/reading-notifications', [AgentController::class, 'getAgentReadingNotifications']);
$router->post('/api/energy/agent/reading-notifications/{id}/seen', [AgentController::class, 'markAgentNotificationSeen']);


// Daily Reports Routes
$router->get('/api/daily-reports', [DailyReportsController::class, 'index']);
$router->get('/api/daily-reports/dashboard', [DailyReportsController::class, 'dashboard']);
$router->post('/api/daily-reports', [DailyReportsController::class, 'store']);

// Notifications Routes
$router->get('/api/notifications/unread', [NotificationsController::class, 'getUnread']);
$router->post('/api/notifications/{id}/read', [NotificationsController::class, 'markAsRead']);

// Global Settings Routes
$router->get('/api/global-settings', [GlobalSettingsController::class, 'index']);
$router->put('/api/global-settings/{key}', [GlobalSettingsController::class, 'update']);

// Financial Reports Routes
$router->get('/api/financial-reports/generate', [FinancialReportsController::class, 'generate']);

// Dispatch request
$router->dispatch($_SERVER['REQUEST_URI']);
