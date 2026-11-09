<?php
// Set Central Africa Timezone (UTC+1)
date_default_timezone_set('Africa/Douala');

// CORS Headers — allow both local dev and production domain
$origin = $_SERVER['HTTP_ORIGIN'] ?? '';
$isLocalhost = preg_match('/^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/', $origin);
$allowedOrigins = [
    $_ENV['APP_URL'] ?? '',
];
if ($isLocalhost || in_array($origin, $allowedOrigins, true) || empty($origin)) {
    header("Access-Control-Allow-Origin: " . ($origin ?: '*'));
} else {
    header("Access-Control-Allow-Origin: " . ($_ENV['APP_URL'] ?? '*'));
}
header("Access-Control-Allow-Credentials: true");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With, X-Idempotency-Key, X-Device-Id");
header("Content-Type: application/json; charset=UTF-8");
header("Cache-Control: no-cache, no-store, must-revalidate");
header("Pragma: no-cache");
header("Expires: 0");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Compress JSON responses (typically 5-10x smaller on slow mobile networks)
if (extension_loaded('zlib') && !ini_get('zlib.output_compression') && stripos($_SERVER['HTTP_ACCEPT_ENCODING'] ?? '', 'gzip') !== false) {
    ob_start('ob_gzhandler');
}

// Global error handler — ignores @-suppressed and non-fatal notices/deprecations
set_error_handler(function($severity, $message, $file, $line) {
    if (!(error_reporting() & $severity)) {
        return false;
    }
    if (in_array($severity, [E_NOTICE, E_USER_NOTICE, E_DEPRECATED, E_USER_DEPRECATED, E_STRICT, E_WARNING, E_USER_WARNING], true)) {
        return true;
    }
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
// Safe load for Router (loads core/Router.php or uses inline fallback if missing on server)
if (file_exists(__DIR__ . '/core/Router.php')) {
    require_once __DIR__ . '/core/Router.php';
} elseif (file_exists(__DIR__ . '/core/router.php')) {
    require_once __DIR__ . '/core/router.php';
}

if (!class_exists('Router')) {
class Router {
    private $routes = [];

    public function get($path, $callback) {
        $this->addRoute('GET', $path, $callback);
    }

    public function post($path, $callback) {
        $this->addRoute('POST', $path, $callback);
    }

    public function put($path, $callback) {
        $this->addRoute('PUT', $path, $callback);
    }

    public function delete($path, $callback) {
        $this->addRoute('DELETE', $path, $callback);
    }

    private function addRoute($method, $path, $callback) {
        // Convert path variables like {id} to regex
        $routeRegex = preg_replace('/\{[a-zA-Z0-9_]+\}/', '([a-zA-Z0-9_]+)', $path);
        $routeRegex = str_replace('/', '\/', $routeRegex);
        $routeRegex = '/^' . $routeRegex . '$/';
        $this->routes[] = [
            'method' => $method,
            'pattern' => $routeRegex,
            'callback' => $callback
        ];
    }

    public function dispatch($uri) {
        $method = $_SERVER['REQUEST_METHOD'];
        
        // Remove base path from URI if needed (Local XAMPP: /Bitar/backend)
        // On Hostinger, this should be empty since routes start with /api
        $basePath = $_ENV['API_BASE_PATH'] ?? '';
        if ($basePath !== '' && strpos($uri, $basePath) === 0) {
            $uri = substr($uri, strlen($basePath));
        }
        $uri = strtok($uri, '?'); // Remove query string
        if (empty($uri)) {
            $uri = '/';
        }

        foreach ($this->routes as $route) {
            if ($route['method'] === $method && preg_match($route['pattern'], $uri, $matches)) {
                array_shift($matches); // Remove the full match
                
                // If callback is an array like [Controller::class, 'method']
                if (is_array($route['callback'])) {
                    $controller = new $route['callback'][0]();
                    $action = $route['callback'][1];
                    call_user_func_array([$controller, $action], $matches);
                } else {
                    call_user_func_array($route['callback'], $matches);
                }
                return;
            }
        }

        http_response_code(404);
        echo json_encode(['error' => 'Route not found: ' . $uri]);
    }
}
}

if (file_exists(__DIR__ . '/core/events/Event.php')) require_once __DIR__ . '/core/events/Event.php';
if (file_exists(__DIR__ . '/core/events/PaymentReceivedEvent.php')) require_once __DIR__ . '/core/events/PaymentReceivedEvent.php';
if (file_exists(__DIR__ . '/core/EventBus.php')) require_once __DIR__ . '/core/EventBus.php';
if (file_exists(__DIR__ . '/middleware/AuthMiddleware.php')) require_once __DIR__ . '/middleware/AuthMiddleware.php';
if (file_exists(__DIR__ . '/utils/AuditLogger.php')) {
    require_once __DIR__ . '/utils/AuditLogger.php';
} elseif (!class_exists('AuditLogger')) {
    class AuditLogger {
        public static function log($action, $entity_type, $entity_id, $details = null) {
            try {
                $db = Database::getInstance()->getConnection();
                $stmt = $db->prepare("INSERT INTO activity_logs (user_id, action, entity_type, entity_id, details) VALUES (?, ?, ?, ?, ?)");
                $stmt->execute([null, $action, $entity_type, $entity_id, $details]);
            } catch (\Throwable $e) {}
        }
    }
}
require_once __DIR__ . '/core/IdempotencyGuard.php';
require_once __DIR__ . '/services/PushNotificationService.php';
if (file_exists(__DIR__ . '/services/RentGenerationService.php')) require_once __DIR__ . '/services/RentGenerationService.php';
require_once __DIR__ . '/controllers/AIController.php';
require_once __DIR__ . '/controllers/GeneratorController.php';

// Load controllers
foreach (glob(__DIR__ . '/controllers/*.php') as $filename) {
    require_once $filename;
}

$router = new Router();

// Agent Mobile App Routes (Connected 100% to Live Real Database)
$router->get('/api/agent/dashboard', [AgentController::class, 'dashboardStats']);
$router->get('/api/agent/subscriptions', [AgentController::class, 'getSubscriptionTasks']);
$router->post('/api/agent/subscriptions/submit', [AgentController::class, 'storeSubscriptionMeterReading']);
$router->get('/api/agent-purchases', [AgentController::class, 'getAgentPurchases']);
$router->post('/api/agent-purchases/submit', [AgentController::class, 'storeAgentPurchase']);
$router->post('/api/agent-purchases/{id}/approve', [AgentController::class, 'approveAgentPurchase']);
$router->post('/api/agent-purchases/{id}/reject', [AgentController::class, 'rejectAgentPurchase']);
$router->get('/api/agent/generators/assigned', [EnergyController::class, 'getGenerators']);
$router->post('/api/agent/generators/submit', [AgentController::class, 'storeGeneratorReading']);
$router->get('/api/agent/history', [AgentController::class, 'getGeneratorHistory']);
$router->post('/api/agent/daily-report/submit', [AgentController::class, 'storeGeneratorReading']);
$router->get('/api/agent/daily-report/latest', [AgentController::class, 'dashboardStats']);


// Agent Controller Smart Tasks & Editing
$router->get('/api/agent/smart-tasks', [AgentController::class, 'getSmartTasks']);
$router->post('/api/agent/reading/quick-edit', [AgentController::class, 'quickEditReading']);
$router->post('/api/agent/reading/correction', [AgentController::class, 'requestCorrection']);

// Agent Rent Collection Routes (AgentRentController — was missing from router)
$router->get('/api/agent/rent/tasks', [AgentRentController::class, 'getAssignedTasks']);
$router->post('/api/agent/rent/collect', [AgentRentController::class, 'collectPayment']);
$router->get('/api/agent/rent/history', [AgentRentController::class, 'getHistory']);
$router->get('/api/agent/rent/invoice-lookup', [AgentRentController::class, 'lookupInvoice']);
$router->get('/api/agent/rent/apartment-invoices', [AgentRentController::class, 'getApartmentUnpaidInvoices']);
$router->post('/api/agent/rent/validate-qr', [AgentRentController::class, 'validateQrCode']);

// Approval Engine Correction routes
$router->get('/api/approval/corrections', [ApprovalEngineController::class, 'getCorrectionQueue']);
$router->post('/api/approval/corrections/{id}/approve', [ApprovalEngineController::class, 'approveCorrection']);
$router->post('/api/approval/corrections/{id}/reject', [ApprovalEngineController::class, 'rejectCorrection']);
// Define routes
$router->get('/api/health', function() {
    echo json_encode(["status" => "ok", "message" => "PMS API is running."]);
});

// System Migration & Schema Heal Endpoint
$router->post('/api/system/migrate', function() {
    $user = AuthMiddleware::requireLogin();
    $role = strtolower(trim($user['role'] ?? ''));
    if ($role !== 'admin') {
        http_response_code(403);
        echo json_encode(['error' => 'Forbidden: Admins only']);
        return;
    }
    require_once __DIR__ . '/services/PushSchema.php';
    $db = Database::getInstance()->getConnection();
    PushSchema::migrate($db, false);
    echo json_encode(['success' => true, 'message' => 'Schema migrated and roles healed successfully']);
});
$router->get('/api/system/migrate', function() {
    $user = AuthMiddleware::requireLogin();
    $role = strtolower(trim($user['role'] ?? ''));
    if ($role !== 'admin') {
        http_response_code(403);
        echo json_encode(['error' => 'Forbidden: Admins only']);
        return;
    }
    require_once __DIR__ . '/services/PushSchema.php';
    $db = Database::getInstance()->getConnection();
    PushSchema::migrate($db, false);
    echo json_encode(['success' => true, 'message' => 'Schema migrated and roles healed successfully']);
});

// Autonomous Agency AI Routes (Cross-Platform Web + Mobile)
$router->post('/api/ai/chat',              [AIController::class, 'chat']);
$router->get('/api/ai/history',            [AIController::class, 'getHistory']);
$router->post('/api/ai/clear',             [AIController::class, 'clearHistory']);
$router->post('/api/ai/execute-tool',      [AIController::class, 'executeTool']);
$router->get('/api/ai/proactive-insights', [AIController::class, 'proactiveInsights']);
$router->get('/api/ai/diagnostics',        [AIController::class, 'diagnostics']);
$router->get('/api/ai/admin-control',      [AIController::class, 'adminControl']);
$router->post('/api/ai/admin-control',     [AIController::class, 'adminControl']);

// Auth Routes
$router->post('/api/auth/login', [AuthController::class, 'login']);
$router->post('/api/auth/refresh', [AuthController::class, 'refresh']);
$router->post('/api/auth/logout', [AuthController::class, 'logout']);
$router->get('/api/auth/me', [AuthController::class, 'me']);
$router->post('/api/auth/fcm-token', [AuthController::class, 'saveFcmToken']);
$router->post('/api/devices/register', [DevicesController::class, 'register']);
$router->post('/api/devices/unregister', [DevicesController::class, 'unregister']);

// User Management Routes
$router->get('/api/users', [UsersController::class, 'index']);
$router->post('/api/users', [UsersController::class, 'store']);
$router->put('/api/users/language', [UsersController::class, 'updateLanguage']);
$router->put('/api/users/{id}', [UsersController::class, 'update']);
$router->delete('/api/users/{id}', [UsersController::class, 'destroy']);

// Translations Routes
$router->get('/api/translations', [TranslationsController::class, 'index']);
$router->post('/api/translations', [TranslationsController::class, 'store']);
$router->delete('/api/translations', [TranslationsController::class, 'destroy']);

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

// Tenant Routes — specific paths MUST come before {id} wildcard routes
$router->get('/api/tenants', [TenantsController::class, 'index']);
$router->post('/api/tenants', [TenantsController::class, 'store']);

$router->get('/api/tenants/archived', [TenantsController::class, 'getArchivedTenants']);

// ── Tenant Maintenance Tickets (admin view) — registered BEFORE /api/tenants/{id} ──
$router->get('/api/tenants/{id}/maintenance-tickets',   [TenantMaintenanceController::class, 'index']);
$router->post('/api/tenants/{id}/maintenance-tickets',  [TenantMaintenanceController::class, 'store']);

// ── Tenant Documents (admin view) — registered BEFORE /api/tenants/{id} ──────────
$router->get('/api/tenants/{id}/documents',             [TenantDocumentsController::class, 'index']);
$router->post('/api/tenants/{id}/documents/upload',     [TenantDocumentsController::class, 'upload']);
$router->put('/api/tenants/{id}/documents/request',     [TenantDocumentsController::class, 'requestDocument']);

// ── Specific tenant {id} sub-paths — registered BEFORE /api/tenants/{id} wildcard ─
$router->get('/api/tenants/{id}/rent-history', [TenantsController::class, 'rentHistory']);
$router->get('/api/tenants/{id}/apartments', [TenantsController::class, 'apartments']);
$router->get('/api/tenants/{id}', [TenantsController::class, 'show']);
$router->put('/api/tenants/{id}/contract', [TenantsController::class, 'updateContract']);
$router->put('/api/tenants/{id}', [TenantsController::class, 'update']);
$router->post('/api/tenants/{id}/terminate', [TenantsController::class, 'terminate']);
$router->delete('/api/tenants/{id}', [TenantsController::class, 'destroy']);
$router->delete('/api/rent/payments/{id}', [RentController::class, 'deletePayment']);

// ── Status-update routes use TOP-LEVEL prefixes (avoids /api/tenants/{id} conflict) ─
$router->get('/api/maintenance-tickets/all',            [TenantMaintenanceController::class, 'indexAll']);
$router->put('/api/maintenance-tickets/{id}/status',    [TenantMaintenanceController::class, 'updateStatus']);
$router->put('/api/tenant-documents/{id}/status',       [TenantDocumentsController::class, 'updateStatus']);

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
$router->put('/api/contracts/{id}/close-rent', [ContractsController::class, 'closeRent']);
$router->put('/api/contracts/{id}/resume-rent', [ContractsController::class, 'resumeRent']);
$router->put('/api/contracts/{id}/pause-contract', [ContractsController::class, 'pauseContract']);
$router->put('/api/contracts/{id}/terminate-contract', [ContractsController::class, 'terminateContract']);
$router->post('/api/contracts/{id}/renew-rent-manually', [ContractsController::class, 'renewRentManually']);

$router->post('/api/contracts/{id}/upload-file', [ContractsController::class, 'uploadFile']);

// Tenant Portal Routes
$router->get('/api/tenant-portal/dashboard', [TenantPortalController::class, 'dashboard']);
$router->post('/api/tenant-portal/contract/sign', [TenantPortalController::class, 'uploadSignedContract']);
$router->get('/api/tenant-portal/rent-history', [TenantPortalController::class, 'rentHistory']);
$router->post('/api/tenant-portal/renewal/request', [TenantPortalController::class, 'requestRenewal']);
$router->post('/api/tenant-portal/renewal/decline', [TenantPortalController::class, 'declineRenewal']);

// Tenant Documents (tenant-role secured)
$router->get('/api/tenant-portal/documents',                [TenantPortalController::class, 'getMyDocuments']);
$router->post('/api/tenant-portal/documents/upload',        [TenantPortalController::class, 'uploadMyDocument']);

// Tenant Apartments (tenant-role secured)
$router->get('/api/tenant-portal/apartments',               [TenantPortalController::class, 'getMyApartments']);

// Tenant Maintenance Tickets (tenant-role secured)
$router->get('/api/tenant-portal/maintenance-tickets',      [TenantPortalController::class, 'getMyMaintenanceTickets']);
$router->post('/api/tenant-portal/maintenance-tickets',     [TenantPortalController::class, 'submitMyMaintenanceTicket']);


// Tenant Rent Renewal Requests (Step 1)
$router->get('/api/tenant/rent-requests', [TenantPortalController::class, 'getRentRequests']);
$router->post('/api/tenant/rent-requests/accept', [TenantPortalController::class, 'acceptRentRequest']);
$router->post('/api/tenant/rent-requests/deny', [TenantPortalController::class, 'denyRentRequest']);

// Rent Routes
$router->get('/api/rent/dashboard', [RentController::class, 'rentManagementDashboard']);
$router->get('/api/rent/invoices', [RentController::class, 'index']);
$router->post('/api/rent/payment', [RentController::class, 'pay']);
$router->post('/api/rent/historical', [RentController::class, 'addHistorical']);
$router->post('/api/rent/generate', [RentController::class, 'generateInvoices']); // Trigger manually or lazy
$router->post('/api/rent/process-auto-generation', [RentController::class, 'processAutoGeneration']);
$router->post('/api/rent/reconcile-statuses', [RentController::class, 'reconcileStatuses']);

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
$router->delete('/api/workshop/{id}', [WorkshopController::class, 'destroy']);
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
$router->get('/api/dashboard/financial-summary', [DashboardController::class, 'financialSummary']);
$router->get('/api/dashboard/collections', [DashboardController::class, 'collections']);
$router->get('/api/dashboard/alerts', [DashboardController::class, 'alerts']);
$router->get('/api/dashboard/expiring-items', [DashboardController::class, 'expiringItems']);
$router->get('/api/dashboard/manager', [DashboardController::class, 'managerStats']);
$router->get('/api/dashboard/cashier', [DashboardController::class, 'cashierStats']);

// Global Search
$router->get('/api/search', [SearchController::class, 'globalSearch']);

// Settings
$router->get('/api/settings/rates', [SettingsController::class, 'getRates']);
$router->post('/api/settings/rates', [SettingsController::class, 'addRate']);
$router->put('/api/settings/rates/{id}', [SettingsController::class, 'updateRate']);
$router->delete('/api/settings/rates/{id}', [SettingsController::class, 'deleteRate']);
// Cashier Routes
$router->get('/api/cashier/summary', [CashierController::class, 'getDailySummary']);
$router->get('/api/cashier/sessions', [CashierController::class, 'getSessions']);
$router->post('/api/cashier/session/open', [CashierController::class, 'openSession']);
$router->post('/api/cashier/session/close', [CashierController::class, 'closeSession']);
$router->post('/api/cashier/session/expense', [CashierController::class, 'addExpense']);

// Schedule & Compliance Operations Hub
$router->get('/api/schedule/summary', [ScheduleController::class, 'getSummary']);
$router->get('/api/schedule/calendar', [ScheduleController::class, 'getCalendarEvents']);
$router->get('/api/schedule/events', [ScheduleController::class, 'getEventsWithMetrics']);
$router->get('/api/schedule/notifications', [ScheduleController::class, 'getNotifications']);
$router->get('/api/schedule/pro-dashboard', [ScheduleController::class, 'getProDashboard']);
$router->post('/api/schedule/tasks/generate-missing', [ScheduleController::class, 'generateMissingTask']);
$router->post('/api/schedule/tasks/complete', [ScheduleController::class, 'recordTaskCompletion']);
$router->post('/api/schedule/tasks/cancel', [ScheduleController::class, 'cancelTask']);
$router->post('/api/schedule/reconcile', [ScheduleController::class, 'reconcileSchedules']);
$router->post('/api/ai/chat', [AIController::class, 'chat']);

// Audit (legacy)
$router->get('/api/audit', [AuditController::class, 'index']);

// Action Control Report
$router->get('/api/action-control/dashboard',                     [ActionControlController::class, 'dashboard']);
$router->get('/api/action-control/reports',                       [ActionControlController::class, 'reports']);
$router->get('/api/action-control/reports/{id}',                  [ActionControlController::class, 'employeeReport']);
$router->get('/api/action-control/record-detail/{id}',            [ActionControlController::class, 'recordDetail']);
$router->get('/api/action-control/trail/{id}',                    [ActionControlController::class, 'trail']);
$router->get('/api/action-control/departments',                   [ActionControlController::class, 'departments']);
$router->post('/api/action-control/run-audit',                    [ActionControlController::class, 'runAudit']);
$router->put('/api/action-control/reports/{id}/unlock',           [ActionControlController::class, 'unlock']);
$router->put('/api/action-control/reports/{id}/lock',             [ActionControlController::class, 'lock']);
$router->put('/api/action-control/reports/{id}/fix',              [ActionControlController::class, 'fix']);
$router->put('/api/action-control/reports/{id}/approve',          [ActionControlController::class, 'approve']);
$router->put('/api/action-control/reports/{id}/reject',           [ActionControlController::class, 'reject']);
$router->put('/api/action-control/reports/{id}/send-back',        [ActionControlController::class, 'sendBack']);
$router->put('/api/action-control/reports/{id}/mark-resolved',    [ActionControlController::class, 'markResolved']);

// ── Permission Center ──────────────────────────────────────────────────────────
$router->get('/api/permissions/global-menus',                  [PermissionController::class, 'globalMenus']);
$router->post('/api/permissions/global-menus/reorder',         [PermissionController::class, 'updateGlobalMenus']);
$router->post('/api/permissions/global-menus',                 [PermissionController::class, 'createGlobalMenu']);
$router->delete('/api/permissions/global-menus/{id}',          [PermissionController::class, 'deleteGlobalMenu']);
$router->get('/api/permissions/my-permissions',                [PermissionController::class, 'myPermissions']);
$router->get('/api/permissions/matrix',                        [PermissionController::class, 'matrix']);
$router->get('/api/permissions/pages',                         [PermissionController::class, 'pages']);
$router->put('/api/permissions/pages',                         [PermissionController::class, 'updatePages']);
$router->get('/api/permissions/buttons',                       [PermissionController::class, 'buttons']);
$router->put('/api/permissions/buttons',                       [PermissionController::class, 'updateButtons']);
$router->get('/api/permissions/fields',                        [PermissionController::class, 'fields']);
$router->put('/api/permissions/fields',                        [PermissionController::class, 'updateFields']);
$router->get('/api/permissions/menu',                          [PermissionController::class, 'menu']);
$router->put('/api/permissions/menu',                          [PermissionController::class, 'updateMenu']);
$router->get('/api/permissions/buildings',                     [PermissionController::class, 'buildingRestrictions']);
$router->put('/api/permissions/buildings',                     [PermissionController::class, 'updateBuildingRestrictions']);
$router->get('/api/permissions/temp',                          [PermissionController::class, 'tempPermissions']);
$router->post('/api/permissions/temp',                         [PermissionController::class, 'grantTemp']);
$router->delete('/api/permissions/temp/{id}',                  [PermissionController::class, 'revokeTemp']);
$router->get('/api/permissions/users-with-restrictions',       [PermissionController::class, 'usersWithRestrictions']);

// ── Enterprise Approval Engine ────────────────────────────────────────────────
// Analysis & Queue
$router->get('/api/approval/analyze/{type}/{id}',     [ApprovalEngineController::class, 'analyzeReading']);
$router->get('/api/approval/queue/{type}',            [ApprovalEngineController::class, 'getPendingQueue']);
$router->get('/api/approval/history/{type}/{id}',     [ApprovalEngineController::class, 'getReadingHistory']);
$router->get('/api/approval/timeline/{type}/{id}',    [ApprovalEngineController::class, 'getReadingTimeline']);
$router->get('/api/approval/versions/{type}/{id}',    [ApprovalEngineController::class, 'getReadingVersions']);

// Actions
$router->post('/api/approval/approve/{type}/{id}',    [ApprovalEngineController::class, 'approve']);
$router->post('/api/approval/reject/{type}/{id}',     [ApprovalEngineController::class, 'reject']);
$router->put('/api/approval/quick-edit/{type}/{id}',  [ApprovalEngineController::class, 'quickEdit']);
$router->post('/api/approval/bulk-approve/{type}',    [ApprovalEngineController::class, 'bulkApprove']);
$router->post('/api/approval/bulk-reject/{type}',     [ApprovalEngineController::class, 'bulkReject']);

// Dashboard & Intelligence
$router->get('/api/approval/admin-kpi',               [ApprovalEngineController::class, 'getAdminKPI']);
$router->get('/api/approval/agent-leaderboard',       [ApprovalEngineController::class, 'getAgentLeaderboard']);
$router->get('/api/approval/building-health',         [ApprovalEngineController::class, 'getBuildingHealthScores']);

// Settings
$router->get('/api/approval/settings',                [ApprovalEngineController::class, 'getApprovalSettings']);
$router->put('/api/approval/settings/{key}',          [ApprovalEngineController::class, 'updateApprovalSetting']);

// ── Approval Center ───────────────────────────────────────────────────────────
$router->get('/api/approvals/chains',                          [ApprovalController::class, 'chains']);
$router->get('/api/approvals/chains/{id}',                     [ApprovalController::class, 'showChain']);
$router->post('/api/approvals/chains',                         [ApprovalController::class, 'storeChain']);
$router->delete('/api/approvals/chains/{id}',                  [ApprovalController::class, 'deleteChain']);
$router->get('/api/approvals/requests',                        [ApprovalController::class, 'requests']);
$router->post('/api/approvals/requests',                       [ApprovalController::class, 'storeRequest']);
$router->put('/api/approvals/requests/{id}/approve',           [ApprovalController::class, 'approveRequest']);
$router->put('/api/approvals/requests/{id}/reject',            [ApprovalController::class, 'rejectRequest']);
$router->get('/api/approvals/my-actions',                      [ApprovalController::class, 'myActions']);
$router->get('/api/approvals/security-events',                 [ApprovalController::class, 'securityEvents']);
$router->post('/api/approvals/security-events',                [ApprovalController::class, 'logSecurityEvent']);
$router->get('/api/approvals/audit-search',                    [ApprovalController::class, 'auditSearch']);
$router->get('/api/approvals/compare/{id}',                    [ApprovalController::class, 'compareChanges']);

// ── Operations Center Routes
$router->post('/api/operations/ping', [OperationsController::class, 'ping']);
$router->get('/api/operations/live-feed', [OperationsController::class, 'getLiveFeed']);
$router->get('/api/operations/online-users', [OperationsController::class, 'getOnlineUsers']);
$router->get('/api/operations/session-timeline/{id}', [OperationsController::class, 'getSessionTimeline']);
$router->get('/api/operations/productivity', [OperationsController::class, 'getProductivity']);
$router->get('/api/operations/security', [OperationsController::class, 'getSecurity']);
$router->get('/api/operations/analytics', [OperationsController::class, 'getAnalytics']);

// ── Data Integrity ────────────────────────────────────────────────────────────
$router->get('/api/integrity/dashboard',                       [DataIntegrityController::class, 'dashboard']);
$router->get('/api/integrity/issues',                          [DataIntegrityController::class, 'issues']);
$router->get('/api/integrity/financial',                       [DataIntegrityController::class, 'financial']);
$router->post('/api/integrity/run',                            [DataIntegrityController::class, 'run']);
$router->put('/api/integrity/issues/{id}/resolve',             [DataIntegrityController::class, 'resolveIssue']);
$router->put('/api/integrity/issues/{id}/ignore',              [DataIntegrityController::class, 'ignoreIssue']);
$router->put('/api/integrity/financial/{id}/resolve',          [DataIntegrityController::class, 'resolveFinancial']);

// ── System Health + Analytics ─────────────────────────────────────────────────
$router->get('/api/system-health',                             [SystemHealthController::class, 'index']);
$router->get('/api/system-health/settings',                    [SystemHealthController::class, 'settings']);
$router->put('/api/system-health/settings',                    [SystemHealthController::class, 'updateSettings']);
$router->get('/api/system-health/analytics',                   [SystemHealthController::class, 'analytics']);



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
$router->get('/api/pos/invoices/by-reference/{ref}', [POSController::class, 'getByReference']);
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

// --- AI Generator Dashboard Routes ---
$router->post('/api/generator/addDailyLog', [GeneratorController::class, 'addDailyLog']);
$router->get('/api/generator/getMonthLogs', [GeneratorController::class, 'getMonthLogs']);
$router->post('/api/generator/runAnalysis', [GeneratorController::class, 'runAnalysis']);
$router->post('/api/generator/updateActualFuel', [GeneratorController::class, 'updateActualFuel']);
$router->post('/api/generator/verifyLog', [GeneratorController::class, 'verifyLog']);
$router->post('/api/generator/extract-meter', [GeneratorController::class, 'extractMeterReading']);
$router->get('/api/generator/export', [GeneratorController::class, 'exportMonthlyReport']);
$router->post('/api/fuel/movements', [FuelController::class, 'storeMovement']);
$router->put('/api/fuel/movements/{id}', [FuelController::class, 'updateMovement']);
$router->delete('/api/fuel/movements/{id}', [FuelController::class, 'deleteMovement']);
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
$router->post('/api/energy/apartments/{id}/subscriptions/{sub_id}/switch-plan', [ElectricityController::class, 'switchPlan']);
$router->put('/api/energy/apartments/{id}/subscriptions/{sub_id}/fee', [ElectricityController::class, 'updateFee']);
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
$router->get('/api/sales/summary', [SalesController::class, 'summary']);
$router->get('/api/sales/purchased-products', [SalesController::class, 'purchasedProducts']);
$router->get('/api/sales/analytics', [SalesController::class, 'analytics']);
$router->get('/api/sales/dashboard', [SalesController::class, 'dashboard']);
$router->get('/api/sales/cashier-summary', [CashierController::class, 'getDailySummary']);
$router->post('/api/sales/cashier-session/open', [CashierController::class, 'openSession']);
$router->post('/api/sales/cashier-session/close', [CashierController::class, 'closeSession']);
$router->post('/api/sales/cashier-session/expense', [CashierController::class, 'addExpense']);
$router->post('/api/sales/returns', [ReturnsController::class, 'processReturn']);
$router->get('/api/sales/returns/{id}', [ReturnsController::class, 'getReturnsHistory']);
$router->put('/api/sales/returns/{id}/status', [ReturnsController::class, 'updateReturnStatus']);
$router->post('/api/sales/convert', [SalesController::class, 'convert']);
$router->post('/api/sales/edit', [SalesController::class, 'edit']);
$router->get('/api/sales/timeline/{id}', [SalesController::class, 'timeline']);
$router->get('/api/sales/audits/{id}', [AuditController::class, 'getSalesAudits']);

// AC Maintenance Routes
$router->post('/api/maintenance/requests', [TenantMaintenanceController::class, 'storeFromRequest']);
$router->get('/api/maintenance/tasks', [ACMaintenanceController::class, 'workerTasks']);
$router->get('/api/maintenance/worker-history', [ACMaintenanceController::class, 'workerHistory']);
$router->post('/api/maintenance/submit', [ACMaintenanceController::class, 'submitTask']);
$router->post('/api/maintenance/tasks/{id}/submit', [ACMaintenanceController::class, 'submitTask']);
$router->post('/api/maintenance/tickets/{id}/submit', [ACMaintenanceController::class, 'submitTask']);
$router->put('/api/maintenance/tickets/{id}/status', [TenantMaintenanceController::class, 'updateStatus']);
$router->get('/api/maintenance/admin/tasks', [ACMaintenanceController::class, 'pendingTasks']);
$router->get('/api/maintenance/admin/history', [ACMaintenanceController::class, 'taskHistory']);
$router->post('/api/maintenance/admin/tasks/{id}/approve', [ACMaintenanceController::class, 'approveTask']);
$router->post('/api/maintenance/admin/tasks/{id}/reject', [ACMaintenanceController::class, 'rejectTask']);
$router->post('/api/maintenance/admin/buildings/{id}/generate', [ACMaintenanceController::class, 'generateSmartSchedules']);
$router->get('/api/maintenance/admin/worker-reports', [ACMaintenanceController::class, 'workerReport']);

// Agent Routes
$router->get('/api/energy/agent/dashboard-stats', [AgentController::class, 'dashboardStats']);
$router->get('/api/energy/agent/building-apartments/{building_id}', [AgentController::class, 'getBuildingApartments']);
$router->get('/api/energy/agent/history/generators', [AgentController::class, 'getGeneratorHistory']);
$router->get('/api/energy/agent/history/apartments', [AgentController::class, 'getApartmentHistory']);
$router->get('/api/energy/admin/agent-reports', [AgentController::class, 'agentReports']);
$router->post('/api/energy/agent/generator-reading', [AgentController::class, 'storeGeneratorReading']);
$router->post('/api/energy/agent/daily-report', [AgentController::class, 'storeGeneratorReading']);
$router->post('/api/energy/agent/apartment-reading', [AgentController::class, 'storeApartmentReading']);

// Agent Subscription Task Routes
$router->get('/api/energy/agent/subscription-tasks', [AgentController::class, 'getSubscriptionTasks']);
$router->get('/api/energy/agent/subscription-invoices', [AgentController::class, 'getUnpaidSubscriptionInvoices']);
$router->post('/api/energy/agent/subscription-invoices/request-qr', [AgentController::class, 'requestQrAuthorization']);
$router->post('/api/energy/agent/subscription-invoices/pay', [AgentController::class, 'submitSubscriptionPayment']);
$router->post('/api/energy/agent/subscription-reading', [AgentController::class, 'storeSubscriptionMeterReading']);
$router->get('/api/energy/agent/subscription-readings/pending', [AgentController::class, 'getPendingSubscriptionReadings']);
$router->post('/api/energy/agent/subscription-readings/{id}/verify', [AgentController::class, 'verifySubscriptionReading']);
$router->get('/api/energy/agent/reading-notifications', [AgentController::class, 'getAgentReadingNotifications']);
$router->post('/api/energy/agent/reading-notifications/{id}/seen', [AgentController::class, 'markAgentNotificationSeen']);

// Agent Apartment Purchase Routes
$router->get('/api/energy/agent/apartment-purchases', [AgentController::class, 'getApartmentPurchaseTasks']);
$router->post('/api/energy/agent/apartment-purchase', [AgentController::class, 'storeApartmentPurchase']);
$router->get('/api/energy/agent/apartment-purchases/pending', [AgentController::class, 'getPendingApartmentPurchases']);
$router->post('/api/energy/agent/apartment-purchases/{id}/verify', [AgentController::class, 'verifyApartmentPurchase']);


// Daily Reports Routes
$router->get('/api/daily-reports', [DailyReportsController::class, 'index']);
$router->get('/api/daily-reports/dashboard', [DailyReportsController::class, 'dashboard']);
$router->post('/api/daily-reports', [DailyReportsController::class, 'store']);

// Notifications Routes
$router->get('/api/notifications', [NotificationsController::class, 'index']);
$router->get('/api/notifications/unread-count', [NotificationsController::class, 'unreadCount']);
$router->get('/api/notifications/pending-actions', [NotificationsController::class, 'pendingActions']);
$router->post('/api/notifications/read-all', [NotificationsController::class, 'markAllRead']);
$router->get('/api/notifications/unread', [NotificationsController::class, 'getUnread']);
$router->post('/api/notifications/{id}/read', [NotificationsController::class, 'markAsRead']);

// Global Settings Routes
$router->get('/api/global-settings', [GlobalSettingsController::class, 'index']);
$router->post('/api/global-settings/logo', [GlobalSettingsController::class, 'uploadLogo']);
$router->post('/api/global-settings/bulk', [GlobalSettingsController::class, 'updateBulk']);
$router->put('/api/global-settings/{key}', [GlobalSettingsController::class, 'update']);

// Subscription Routes for Agent
$router->get('/api/energy/agent/subscription-tasks', [AgentController::class, 'getSubscriptionTasks']);
$router->post('/api/energy/agent/subscription-reading', [AgentController::class, 'storeSubscriptionMeterReading']);
$router->get('/api/energy/agent/subscription-invoices', [AgentController::class, 'getUnpaidSubscriptionInvoices']);

// Financial Reports Routes
$router->get('/api/financial-reports/generate', [FinancialReportsController::class, 'generate']);
$router->get('/api/financial-reports/tenant-ledger', [FinancialReportsController::class, 'tenantFinancialLedger']);

// Data Quality Control
$router->get('/api/quality/employees', [DataQualityController::class, 'employees']);
$router->get('/api/quality/errors', [DataQualityController::class, 'errors']);
$router->get('/api/quality/activities', [DataQualityController::class, 'activities']);
$router->get('/api/quality/errors/{id}/history', [DataQualityController::class, 'errorHistory']);
$router->post('/api/quality/errors/{id}/fix', [DataQualityController::class, 'fixError']);
$router->post('/api/quality/errors/{id}/action', [DataQualityController::class, 'action']);
$router->get('/api/quality/analytics', [DataQualityController::class, 'analytics']);
$router->post('/api/quality/scan', [DataQualityController::class, 'scan']);

// Mobile Telemetry & Monitoring
$router->get('/api/mobile/monitoring', [OperationsController::class, 'mobileMonitoring']);

// Mobile Agent Rent Collection
$router->get('/api/agent/rent/tasks', [AgentRentController::class, 'getAssignedTasks']);
$router->post('/api/agent/rent/collect', [AgentRentController::class, 'collectPayment']);
$router->get('/api/agent/rent/history', [AgentRentController::class, 'getHistory']);
$router->post('/api/agent/rent/request-qr', [AgentRentController::class, 'requestQrAuthorization']);
$router->get('/api/agent/rent-requests', [AgentRentController::class, 'getTenantRequests']);

// Independent App Distribution & Release Management Routes
$router->get('/api/releases/public-info', [AppReleaseController::class, 'publicInfo']);
$router->get('/api/releases/check-update', [AppReleaseController::class, 'checkUpdate']);
$router->get('/api/releases/download-latest', [AppReleaseController::class, 'download']);
$router->get('/api/releases/download/{id}', [AppReleaseController::class, 'download']);
$router->post('/api/releases/track-install', [AppReleaseController::class, 'trackInstall']);
$router->get('/api/releases/ios-manifest/{id}', [AppReleaseController::class, 'iosManifest']);

// Admin Application Release Manager Routes
$router->get('/api/releases/admin/dashboard', [AppReleaseController::class, 'adminDashboard']);
$router->post('/api/releases/admin/upload', [AppReleaseController::class, 'uploadRelease']);
$router->post('/api/releases/admin/import-local-apk', [AppReleaseController::class, 'importLocalApk']);
$router->put('/api/releases/admin/{id}', [AppReleaseController::class, 'updateRelease']);
$router->post('/api/releases/admin/{id}/activate', [AppReleaseController::class, 'activateRelease']);
$router->delete('/api/releases/admin/{id}', [AppReleaseController::class, 'deleteRelease']);
$router->post('/api/releases/admin/settings', [AppReleaseController::class, 'updateSettings']);

// Duplicate-submission guard + post-response push drain for write requests
IdempotencyGuard::guard();
if (in_array($_SERVER['REQUEST_METHOD'], ['POST', 'PUT', 'DELETE'], true)) {
    PushNotificationService::kickAfterResponse();
}

// Dispatch request
$router->dispatch($_SERVER['REQUEST_URI']);
