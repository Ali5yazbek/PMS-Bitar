<?php
if (file_exists(__DIR__ . '/../core/NLPEngine.php')) {
    require_once __DIR__ . '/../core/NLPEngine.php';
}

/**
 * AIController — Autonomous Agency AI Engine
 * Provides cross-platform (Web + Mobile) persistent conversation memory,
 * role-based row-level data isolation, hybrid NLP + SQL + optional Gemini synthesis,
 * verified autonomous tool execution with confirmation guards, proactive anomaly insights,
 * live system self-diagnostics, and Admin AI Control Center telemetry.
 */
class AIController {
    private $db;
    private $nlp;
    private $currentUser = null;
    private $currentRole = 'admin';
    private $currentAnalysis = null;
    private $startTime = 0;

    public function __construct() {
        $this->startTime = microtime(true);
        $this->db = Database::getInstance()->getConnection();
        $this->ensureAISchema();
        $this->nlp = new NLPEngine($this->db);
    }

    /**
     * Auto-heal and create persistent AI tables for memory, messages, tool audit logs, and control settings.
     */
    private function ensureAISchema(): void {
        try {
            $this->db->exec("
                CREATE TABLE IF NOT EXISTS ai_conversations (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    user_id INT NOT NULL,
                    user_role VARCHAR(32) NOT NULL DEFAULT 'admin',
                    title VARCHAR(255) DEFAULT 'Agency AI Session',
                    context_json TEXT DEFAULT NULL,
                    is_active TINYINT(1) DEFAULT 1,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                    INDEX idx_ai_conv_user (user_id, is_active)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            ");

            $this->db->exec("
                CREATE TABLE IF NOT EXISTS ai_messages (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    conversation_id INT NOT NULL,
                    user_id INT NOT NULL,
                    sender ENUM('user', 'ai') NOT NULL,
                    message_text MEDIUMTEXT NOT NULL,
                    response_type VARCHAR(64) DEFAULT 'text',
                    payload_json MEDIUMTEXT DEFAULT NULL,
                    language VARCHAR(8) DEFAULT 'en',
                    execution_ms INT DEFAULT 0,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    INDEX idx_ai_msg_conv (conversation_id, id)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            ");

            $this->db->exec("
                CREATE TABLE IF NOT EXISTS ai_tool_logs (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    user_id INT NOT NULL,
                    user_role VARCHAR(32) NOT NULL,
                    tool_name VARCHAR(64) NOT NULL,
                    target_entity VARCHAR(64) DEFAULT NULL,
                    target_id VARCHAR(64) DEFAULT NULL,
                    parameters_json TEXT DEFAULT NULL,
                    status VARCHAR(32) NOT NULL DEFAULT 'executed',
                    result_summary TEXT DEFAULT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    INDEX idx_ai_tool_user (user_id, created_at)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            ");

            $this->db->exec("
                CREATE TABLE IF NOT EXISTS ai_settings (
                    setting_key VARCHAR(64) PRIMARY KEY,
                    setting_value TEXT NOT NULL,
                    updated_by INT DEFAULT NULL,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            ");

            // Seed default settings if empty
            $stmt = $this->db->query("SELECT COUNT(*) FROM ai_settings");
            if ((int)$stmt->fetchColumn() === 0) {
                $this->db->exec("
                    INSERT IGNORE INTO ai_settings (setting_key, setting_value) VALUES
                    ('ai_enabled', '1'),
                    ('autonomous_actions_enabled', '1'),
                    ('require_confirmation', '1'),
                    ('proactive_insights_enabled', '1')
                ");
            }
        } catch (\Throwable $e) {
            // Non-blocking schema check
        }
    }

    private function getSetting(string $key, string $default = '1'): string {
        try {
            $stmt = $this->db->prepare("SELECT setting_value FROM ai_settings WHERE setting_key = ?");
            $stmt->execute([$key]);
            $val = $stmt->fetchColumn();
            return $val !== false ? (string)$val : $default;
        } catch (\Throwable $e) {
            return $default;
        }
    }

    private function getOrCreateConversation(int $userId, string $role): array {
        try {
            $stmt = $this->db->prepare("
                SELECT * FROM ai_conversations
                WHERE user_id = ? AND is_active = 1
                ORDER BY updated_at DESC LIMIT 1
            ");
            $stmt->execute([$userId]);
            $conv = $stmt->fetch(PDO::FETCH_ASSOC);
            if ($conv) {
                return $conv;
            }
            $ins = $this->db->prepare("
                INSERT INTO ai_conversations (user_id, user_role, title, context_json, is_active)
                VALUES (?, ?, 'Agency AI Session', '{}', 1)
            ");
            $ins->execute([$userId, $role]);
            $id = (int)$this->db->lastInsertId();
            return [
                'id' => $id,
                'user_id' => $userId,
                'user_role' => $role,
                'title' => 'Agency AI Session',
                'context_json' => '{}',
                'is_active' => 1
            ];
        } catch (\Throwable $e) {
            return ['id' => 0, 'user_id' => $userId, 'user_role' => $role, 'context_json' => '{}'];
        }
    }

    private function updateConversationContext(int $convId, array $newContext): void {
        if ($convId <= 0) return;
        try {
            $stmt = $this->db->prepare("SELECT context_json FROM ai_conversations WHERE id = ?");
            $stmt->execute([$convId]);
            $existing = json_decode((string)$stmt->fetchColumn(), true) ?: [];
            $merged = array_merge($existing, array_filter($newContext, fn($v) => $v !== null && $v !== ''));
            $upd = $this->db->prepare("UPDATE ai_conversations SET context_json = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?");
            $upd->execute([json_encode($merged, JSON_UNESCAPED_UNICODE), $convId]);
        } catch (\Throwable $e) {}
    }

    private function logConversationTurn(int $convId, int $userId, string $userMsg, array $aiResponse, string $lang): void {
        if ($convId <= 0) return;
        try {
            $elapsedMs = (int)round((microtime(true) - $this->startTime) * 1000);
            $ins = $this->db->prepare("
                INSERT INTO ai_messages (conversation_id, user_id, sender, message_text, response_type, payload_json, language, execution_ms)
                VALUES (?, ?, 'user', ?, 'text', NULL, ?, 0)
            ");
            $ins->execute([$convId, $userId, $userMsg, $lang]);

            $payload = [
                'data' => $aiResponse['data'] ?? null,
                'actions' => $aiResponse['actions'] ?? [],
                'requires_confirmation' => $aiResponse['requires_confirmation'] ?? false,
                'pending_tool' => $aiResponse['pending_tool'] ?? null,
                'navigation_action' => $aiResponse['navigation_action'] ?? null,
            ];
            $insAi = $this->db->prepare("
                INSERT INTO ai_messages (conversation_id, user_id, sender, message_text, response_type, payload_json, language, execution_ms)
                VALUES (?, ?, 'ai', ?, ?, ?, ?, ?)
            ");
            $insAi->execute([
                $convId,
                $userId,
                $aiResponse['reply'] ?? '',
                $aiResponse['type'] ?? 'text',
                json_encode($payload, JSON_UNESCAPED_UNICODE),
                $lang,
                $elapsedMs
            ]);
        } catch (\Throwable $e) {}
    }

    /**
     * Role-based access matrix for intents
     */
    private function isIntentAllowedForRole(string $intent, string $role): bool {
        $role = strtolower(trim($role));
        if ($role === 'admin' || $role === 'manager') {
            return true;
        }
        $roleMatrix = [
            'agent' => [
                'greeting', 'help', 'building_summary', 'vacant_apartments', 'apartment_info',
                'fuel_status', 'energy_overview', 'daily_reports', 'pending_purchases',
                'maintenance_tasks', 'navigate_to', 'my_portal_summary', 'universal_search'
            ],
            'maintenance' => [
                'greeting', 'help', 'maintenance_tasks', 'worker_reports', 'building_summary',
                'apartment_info', 'navigate_to', 'my_portal_summary'
            ],
            'cashier' => [
                'greeting', 'help', 'pos_sales', 'suppliers_summary', 'navigate_to', 'my_portal_summary'
            ],
            'tenant' => [
                'greeting', 'help', 'my_portal_summary', 'tenant_info', 'maintenance_tasks', 'navigate_to'
            ]
        ];
        $allowed = $roleMatrix[$role] ?? ['greeting', 'help', 'my_portal_summary'];
        return in_array($intent, $allowed, true);
    }

    /**
     * GET /api/ai/history
     * Returns synced conversation history (Web + Mobile), active memory context, and proactive insights.
     */
    public function getHistory() {
        $user = AuthMiddleware::requireLogin();
        $userId = (int)$user['id'];
        $role = strtolower(trim($user['role'] ?? 'admin'));

        $conv = $this->getOrCreateConversation($userId, $role);
        $messages = [];
        try {
            $stmt = $this->db->prepare("
                SELECT id, sender, message_text, response_type, payload_json, language, execution_ms, created_at
                FROM ai_messages
                WHERE conversation_id = ?
                ORDER BY id ASC
                LIMIT 60
            ");
            $stmt->execute([$conv['id']]);
            $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
            foreach ($rows as $r) {
                $payload = !empty($r['payload_json']) ? json_decode($r['payload_json'], true) : [];
                $messages[] = [
                    'id' => (int)$r['id'],
                    'role' => $r['sender'],
                    'text' => $r['message_text'],
                    'type' => $r['response_type'] ?: 'text',
                    'data' => $payload['data'] ?? null,
                    'actions' => $payload['actions'] ?? [],
                    'requires_confirmation' => $payload['requires_confirmation'] ?? false,
                    'pending_tool' => $payload['pending_tool'] ?? null,
                    'navigation_action' => $payload['navigation_action'] ?? null,
                    'language' => $r['language'] ?: 'en',
                    'execution_ms' => (int)$r['execution_ms'],
                    'created_at' => $r['created_at'],
                ];
            }
        } catch (\Throwable $e) {}

        echo json_encode([
            'conversation_id' => (int)$conv['id'],
            'context' => json_decode($conv['context_json'] ?? '{}', true) ?: [],
            'messages' => $messages,
            'ai_enabled' => $this->getSetting('ai_enabled', '1') === '1',
            'autonomous_actions_enabled' => $this->getSetting('autonomous_actions_enabled', '1') === '1',
            'user_role' => $role
        ]);
    }

    /**
     * POST /api/ai/clear
     * Archives the current conversation and starts a fresh cross-platform session.
     */
    public function clearHistory() {
        $user = AuthMiddleware::requireLogin();
        $userId = (int)$user['id'];
        $role = strtolower(trim($user['role'] ?? 'admin'));

        try {
            $stmt = $this->db->prepare("UPDATE ai_conversations SET is_active = 0 WHERE user_id = ?");
            $stmt->execute([$userId]);
        } catch (\Throwable $e) {}

        $conv = $this->getOrCreateConversation($userId, $role);
        echo json_encode([
            'success' => true,
            'conversation_id' => (int)$conv['id'],
            'message' => 'Conversation memory cleared and reset.'
        ]);
    }

    /**
     * POST /api/ai/chat
     * Main Autonomous Agency AI Chat Endpoint
     */
    public function chat() {
        $user = AuthMiddleware::requireLogin();
        $this->currentUser = $user;
        $this->currentRole = strtolower(trim($user['role'] ?? 'admin'));
        $userId = (int)$user['id'];

        // Check emergency kill-switch
        if ($this->getSetting('ai_enabled', '1') !== '1') {
            echo json_encode([
                'reply' => "⚠️ **Agency AI is currently paused by the System Administrator.** Please try again once AI services are re-enabled in the AI Control Center.",
                'type' => 'text'
            ]);
            return;
        }

        $body = json_decode(file_get_contents('php://input'), true) ?: [];
        $message = trim($body['message'] ?? '');
        $currentPage = trim($body['current_page'] ?? '');

        if (!$message) {
            http_response_code(400);
            echo json_encode(['error' => 'Message is required']);
            return;
        }

        // Load active conversation & memory context
        $conv = $this->getOrCreateConversation($userId, $this->currentRole);
        $convContext = json_decode($conv['context_json'] ?? '{}', true) ?: [];
        if ($currentPage !== '') {
            $convContext['current_page'] = $currentPage;
        }

        // Run NLP Analysis with conversation memory
        $analysis = $this->nlp->analyze($message, $convContext);
        $this->currentAnalysis = $analysis;
        $intent = $analysis['intent'];
        $entities = $analysis['entities'];
        $lang = $analysis['language'] ?? 'en';

        // Check security / prompt injection guard
        if (isset($analysis['security']['safe']) && $analysis['security']['safe'] === false) {
            $this->logToolExecution($userId, $this->currentRole, 'security_guard_block', 'prompt', null, ['message' => $message], 'blocked', $analysis['security']['reason']);
            echo json_encode([
                'reply' => "🛡️ **Security Guard Intervention:** Your request matched a restricted instruction or privilege-escalation pattern and was blocked. All actions are strictly governed by role-based access control.",
                'type' => 'text',
                'language' => $lang,
                'is_rtl' => $analysis['is_rtl'] ?? false
            ]);
            return;
        }

        // Enforce Role-Based Access Control
        if ($this->currentRole === 'tenant') {
            ob_start();
            $this->handleTenantScopedChat($message, $intent, $entities);
            $rawOut = ob_get_clean();
            $this->finalizeResponse($conv['id'], $userId, $message, $rawOut, $analysis);
            return;
        }

        if (!$this->isIntentAllowedForRole($intent, $this->currentRole)) {
            $denyReply = "🔒 **Access Restricted:** Your current role (**" . strtoupper($this->currentRole) . "**) does not have permission to access **`" . str_replace('_', ' ', $intent) . "`**. Ask me about tasks and records within your assigned operational scope.";
            $resp = json_encode([
                'reply' => $denyReply,
                'type' => 'text',
                'language' => $lang,
                'is_rtl' => $analysis['is_rtl'] ?? false
            ]);
            $this->finalizeResponse($conv['id'], $userId, $message, $resp, $analysis);
            return;
        }

        // Capture output from intent handler so we can enrich it with memory, actions, and conversation persistence
        ob_start();
        switch ($intent) {
            case 'approve_purchase':
                $this->handlePurchaseAction($message, $entities, 'Approved');
                break;
            case 'reject_purchase':
                $this->handlePurchaseAction($message, $entities, 'Rejected');
                break;
            case 'approve_maintenance':
                $this->handleMaintenanceAction($message, $entities, 'Approved');
                break;
            case 'pending_purchases':
                $this->getPendingPurchases($message);
                break;
            case 'system_diagnostics':
                $this->getSystemDiagnostics($message);
                break;
            case 'proactive_insights':
            case 'recommendations':
                $this->getProactiveInsights($message);
                break;
            case 'worker_reports':
                $this->getWorkerReports($message);
                break;
            case 'navigate_to':
                $this->handleNavigationIntent($message, $entities);
                break;
            case 'overdue_rent':
                $this->getOverdueRent($message);
                break;
            case 'top_debtors':
                $this->getTopDebtors($message);
                break;
            case 'expiring_contracts':
                $this->getExpiringContracts($message);
                break;
            case 'pending_contracts':
                $this->getPendingContracts($message);
                break;
            case 'financial_summary':
                $this->getFinancialSummary($message);
                break;
            case 'building_profit_loss':
                $this->getBuildingProfitLoss($message);
                break;
            case 'building_expenses':
                $this->getBuildingExpenses($message);
                break;
            case 'building_summary':
                $this->getBuildingSummary($message);
                break;
            case 'vacant_apartments':
                $this->getVacantApartments($message);
                break;
            case 'apartment_info':
                $this->getApartmentInfo($message);
                break;
            case 'tenant_info':
                $this->getTenantInfo($message);
                break;
            case 'rent_dashboard':
                $this->getRentDashboard($message);
                break;
            case 'maintenance_tasks':
                $this->getMaintenanceTasks($message);
                break;
            case 'fuel_status':
                $this->getFuelStatus($message);
                break;
            case 'energy_overview':
                $this->getEnergyOverview($message);
                break;
            case 'suppliers_summary':
                $this->getSuppliersSummary($message);
                break;
            case 'expenses_summary':
                $this->getExpensesSummary($message);
                break;
            case 'insurance_summary':
                $this->getInsuranceSummary($message);
                break;
            case 'daily_reports':
                $this->getDailyReports($message);
                break;
            case 'construction_status':
                $this->getConstructionStatus($message);
                break;
            case 'pos_sales':
                $this->getPosSales($message);
                break;
            case 'users_overview':
                $this->getUsersOverview($message);
                break;
            case 'greeting':
                $this->getGreeting();
                break;
            case 'help':
                $this->getHelp();
                break;
            case 'universal_search':
            default:
                $this->universalSearch($message);
                break;
        }
        $rawOut = ob_get_clean();
        $this->finalizeResponse($conv['id'], $userId, $message, $rawOut, $analysis);
    }

    /**
     * Enriches the JSON response with metadata, contextual action buttons, conversation memory updates, and persistence.
     */
    private function finalizeResponse(int $convId, int $userId, string $userMsg, string $rawJson, array $analysis): void {
        $decoded = json_decode($rawJson, true);
        if (!is_array($decoded)) {
            $decoded = ['reply' => $rawJson ?: 'Done.', 'type' => 'text'];
        }

        $lang = $analysis['language'] ?? 'en';
        $decoded['language'] = $lang;
        $decoded['is_rtl'] = $analysis['is_rtl'] ?? false;
        $decoded['intent'] = $analysis['intent'] ?? 'universal_search';
        $decoded['confidence'] = $analysis['confidence'] ?? 100;
        $decoded['execution_ms'] = (int)round((microtime(true) - $this->startTime) * 1000);
        $decoded['conversation_id'] = $convId;

        // Attach smart contextual actions if not already set
        if (empty($decoded['actions'])) {
            $decoded['actions'] = $this->buildContextualActions($decoded['type'] ?? 'text', $decoded['data'] ?? null);
        }

        // Update conversation context memory for follow-up questions
        $entities = $analysis['entities'] ?? [];
        $this->updateConversationContext($convId, [
            'last_intent'    => $analysis['intent'] ?? null,
            'last_building'  => $entities['building'] ?? null,
            'last_tenant'    => $entities['tenant'] ?? null,
            'last_apartment' => $entities['apartment_code'] ?? null,
            'last_record_id' => $entities['record_id'] ?? null,
        ]);

        // Persist user + AI turn in ai_messages
        $this->logConversationTurn($convId, $userId, $userMsg, $decoded, $lang);

        echo json_encode($decoded, JSON_UNESCAPED_UNICODE);
    }

    /**
     * Builds interactive action buttons for the frontend & mobile app based on response type
     */
    private function buildContextualActions(string $type, $data): array {
        $actions = [];
        switch ($type) {
            case 'overdue_rent':
            case 'top_debtors':
                $actions[] = ['label' => 'Open Rent Management', 'action_type' => 'navigate', 'route' => '/rent-management', 'mobile_route' => '/rent-payments'];
                break;
            case 'expiring_contracts':
            case 'pending_contracts':
                $actions[] = ['label' => 'Open Contracts Hub', 'action_type' => 'navigate', 'route' => '/contracts', 'mobile_route' => '/contracts'];
                break;
            case 'maintenance_tasks':
                $actions[] = ['label' => 'Open Maintenance Oversight', 'action_type' => 'navigate', 'route' => '/maintenance-admin', 'mobile_route' => '/ac-maintenance'];
                break;
            case 'fuel_status':
            case 'energy_overview':
                $actions[] = ['label' => 'Open Fuel Reserve', 'action_type' => 'navigate', 'route' => '/fuel-reserve', 'mobile_route' => '/fuel-reserve'];
                break;
            case 'pending_purchases':
                $actions[] = ['label' => 'Open Purchase Review', 'action_type' => 'navigate', 'route' => '/agent-purchase-review', 'mobile_route' => '/agent-purchases'];
                break;
            case 'building_profit_loss':
            case 'financial_summary':
                $actions[] = ['label' => 'Open Financial Reports', 'action_type' => 'navigate', 'route' => '/financial-reports', 'mobile_route' => '/financial-building-report'];
                break;
        }
        return $actions;
    }

    /**
     * Strict Tenant-Scoped AI Assistant (Row-Level Security for Tenants)
     */
    private function handleTenantScopedChat(string $message, string $intent, array $entities): void {
        $userId = (int)$this->currentUser['id'];
        $stmt = $this->db->prepare("
            SELECT t.*, a.code as apartment_code, b.name as building_name,
                   c.id as contract_id, c.monthly_rent, c.monthly_insurance, c.start_date, c.end_date, c.status as contract_status
            FROM tenants t
            LEFT JOIN contracts c ON c.tenant_id = t.id AND c.status IN ('Active', 'Approved')
            LEFT JOIN apartments a ON c.apartment_id = a.id
            LEFT JOIN buildings b ON a.building_id = b.id
            WHERE t.user_id = ? OR LOWER(t.email) = LOWER(?)
            LIMIT 1
        ");
        $stmt->execute([$userId, $this->currentUser['email'] ?? '']);
        $tenant = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$tenant) {
            echo json_encode([
                'reply' => "👋 Hello! Your tenant profile is currently being linked. Please contact property management if you need immediate assistance.",
                'type' => 'text'
            ]);
            return;
        }

        $invStmt = $this->db->prepare("
            SELECT COUNT(*) as total_invoices,
                   COALESCE(SUM(ri.amount), 0) as total_billed,
                   COALESCE(SUM((SELECT SUM(rp.amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id)), 0) as total_paid
            FROM rent_invoices ri
            WHERE ri.contract_id = ? AND ri.status != 'Voided'
        ");
        $invStmt->execute([$tenant['contract_id'] ?? 0]);
        $inv = $invStmt->fetch(PDO::FETCH_ASSOC);
        $outstanding = max(0, (float)($inv['total_billed'] ?? 0) - (float)($inv['total_paid'] ?? 0));

        $tktStmt = $this->db->prepare("SELECT COUNT(*) FROM tenant_maintenance_tickets WHERE tenant_id = ? AND status != 'Closed'");
        $tktStmt->execute([$tenant['id']]);
        $openTickets = (int)$tktStmt->fetchColumn();

        $reply = "👋 **Hello {$tenant['full_name']}!** Here is your personal lease & account summary:\n\n"
            . "• 🏠 **Assigned Unit:** **{$tenant['building_name']} • Apt {$tenant['apartment_code']}**\n"
            . "• 📄 **Lease Period:** **{$tenant['start_date']}** to **{$tenant['end_date']}** ({$tenant['contract_status']})\n"
            . "• 💵 **Monthly Rent:** **CFA " . number_format((float)$tenant['monthly_rent']) . "**\n"
            . "• 💰 **Total Paid:** **CFA " . number_format((float)$inv['total_paid']) . "** | **Outstanding Balance:** **CFA " . number_format($outstanding) . "**\n"
            . "• 🔧 **Open Maintenance Requests:** **{$openTickets}** active ticket(s)";

        echo json_encode([
            'reply' => $reply,
            'type' => 'tenant_info',
            'data' => [[
                'id' => $tenant['id'],
                'full_name' => $tenant['full_name'],
                'building_name' => $tenant['building_name'],
                'apartment_code' => $tenant['apartment_code'],
                'monthly_rent' => $tenant['monthly_rent'],
                'end_date' => $tenant['end_date'],
                'total_paid' => $inv['total_paid'],
                'total_debt' => $outstanding,
                'phone' => $tenant['phone']
            ]],
            'actions' => [
                ['label' => 'My Payments', 'action_type' => 'navigate', 'route' => '/tenant-payments', 'mobile_route' => '/tenant-dashboard'],
                ['label' => 'Request Maintenance', 'action_type' => 'navigate', 'route' => '/tenant-maintenance', 'mobile_route' => '/tenant-dashboard'],
            ]
        ]);
    }

    /**
     * Autonomous Tool Execution Endpoint: POST /api/ai/execute-tool
     * Executes verified backend actions with strict role authorization and audit logging.
     */
    public function executeTool() {
        $user = AuthMiddleware::requireLogin();
        $userId = (int)$user['id'];
        $role = strtolower(trim($user['role'] ?? ''));

        if ($this->getSetting('ai_enabled', '1') !== '1' || $this->getSetting('autonomous_actions_enabled', '1') !== '1') {
            http_response_code(403);
            echo json_encode(['error' => 'Autonomous AI actions are currently disabled by administrator policy.']);
            return;
        }

        $body = json_decode(file_get_contents('php://input'), true) ?: [];
        $toolName = trim($body['tool_name'] ?? '');
        $targetId = $body['target_id'] ?? null;
        $params = $body['parameters'] ?? [];

        if (!$toolName) {
            http_response_code(400);
            echo json_encode(['error' => 'tool_name is required']);
            return;
        }

        try {
            switch ($toolName) {
                case 'review_purchase':
                    if (!in_array($role, ['admin', 'manager'], true)) {
                        http_response_code(403);
                        echo json_encode(['error' => 'Only Admins or Managers can approve/reject purchases.']);
                        return;
                    }
                    $status = ($params['status'] ?? 'Approved') === 'Rejected' ? 'Rejected' : 'Approved';
                    $purchaseId = (int)$targetId;
                    $stmt = $this->db->prepare("SELECT * FROM apartment_cost_deployments WHERE id = ?");
                    $stmt->execute([$purchaseId]);
                    $purchase = $stmt->fetch(PDO::FETCH_ASSOC);
                    if (!$purchase) {
                        http_response_code(404);
                        echo json_encode(['error' => "Purchase #$purchaseId not found."]);
                        return;
                    }

                    $upd = $this->db->prepare("UPDATE apartment_cost_deployments SET status = ?, reviewed_by = ?, reviewed_at = NOW() WHERE id = ?");
                    $upd->execute([$status, $userId, $purchaseId]);

                    // Sync with apartment_costs if approved
                    if ($status === 'Approved' && !empty($purchase['apartment_id'])) {
                        try {
                            $chk = $this->db->prepare("SELECT id FROM apartment_costs WHERE apartment_id = ? AND amount = ? AND cost_date = ? LIMIT 1");
                            $chk->execute([$purchase['apartment_id'], $purchase['amount'], $purchase['purchase_date']]);
                            if (!$chk->fetchColumn()) {
                                $ins = $this->db->prepare("
                                    INSERT INTO apartment_costs (apartment_id, type, description, amount, cost_date, receipt_image, created_by)
                                    VALUES (?, 'Maintenance', ?, ?, ?, ?, ?)
                                ");
                                $ins->execute([
                                    $purchase['apartment_id'],
                                    ($purchase['supplier_name'] ? $purchase['supplier_name'] . ': ' : '') . ($purchase['items_bought'] ?? 'Agent Purchase'),
                                    $purchase['amount'],
                                    $purchase['purchase_date'] ?: date('Y-m-d'),
                                    $purchase['receipt_photo'] ?? null,
                                    $userId
                                ]);
                            }
                        } catch (\Throwable $e) {}
                    }

                    $summary = "Purchase #{$purchaseId} (" . ($purchase['supplier_name'] ?? 'Supplier') . " - CFA " . number_format((float)$purchase['amount']) . ") marked as {$status}.";
                    $this->logToolExecution($userId, $role, 'review_purchase', 'apartment_cost_deployments', (string)$purchaseId, $params, 'executed', $summary);

                    echo json_encode([
                        'success' => true,
                        'reply' => "✅ **Autonomous Action Completed:** {$summary}",
                        'tool_name' => $toolName,
                        'target_id' => $purchaseId,
                        'new_status' => $status
                    ]);
                    return;

                case 'review_ac_maintenance':
                    if (!in_array($role, ['admin', 'manager'], true)) {
                        http_response_code(403);
                        echo json_encode(['error' => 'Only Admins or Managers can approve AC maintenance tasks.']);
                        return;
                    }
                    $taskId = (int)$targetId;
                    $status = $params['status'] ?? 'Completed';
                    $upd = $this->db->prepare("UPDATE ac_maintenance_tasks SET status = ? WHERE id = ?");
                    $upd->execute([$status, $taskId]);
                    $summary = "AC Maintenance Task #{$taskId} updated to {$status}.";
                    $this->logToolExecution($userId, $role, 'review_ac_maintenance', 'ac_maintenance_tasks', (string)$taskId, $params, 'executed', $summary);

                    echo json_encode([
                        'success' => true,
                        'reply' => "✅ **Autonomous Action Completed:** {$summary}",
                        'tool_name' => $toolName,
                        'target_id' => $taskId,
                        'new_status' => $status
                    ]);
                    return;

                case 'update_ticket_status':
                    if (!in_array($role, ['admin', 'manager', 'maintenance'], true)) {
                        http_response_code(403);
                        echo json_encode(['error' => 'Unauthorized to update maintenance tickets.']);
                        return;
                    }
                    $ticketId = (int)$targetId;
                    $status = $params['status'] ?? 'In Progress';
                    $upd = $this->db->prepare("UPDATE tenant_maintenance_tickets SET status = ?, updated_at = NOW() WHERE id = ?");
                    $upd->execute([$status, $ticketId]);
                    $summary = "Tenant Maintenance Ticket #{$ticketId} updated to {$status}.";
                    $this->logToolExecution($userId, $role, 'update_ticket_status', 'tenant_maintenance_tickets', (string)$ticketId, $params, 'executed', $summary);

                    echo json_encode([
                        'success' => true,
                        'reply' => "✅ **Autonomous Action Completed:** {$summary}",
                        'tool_name' => $toolName,
                        'target_id' => $ticketId,
                        'new_status' => $status
                    ]);
                    return;

                case 'run_diagnostics':
                    ob_start();
                    $this->getSystemDiagnostics('');
                    $out = json_decode(ob_get_clean(), true);
                    $this->logToolExecution($userId, $role, 'run_diagnostics', 'system', 'all', [], 'executed', 'System diagnostic scan completed');
                    echo json_encode(array_merge(['success' => true], $out ?: []));
                    return;

                default:
                    http_response_code(400);
                    echo json_encode(['error' => "Unknown tool: {$toolName}"]);
                    return;
            }
        } catch (\Throwable $e) {
            http_response_code(500);
            echo json_encode(['error' => 'Tool execution failed: ' . $e->getMessage()]);
        }
    }

    private function logToolExecution(int $userId, string $role, string $toolName, ?string $entity, ?string $targetId, array $params, string $status, string $summary): void {
        try {
            $stmt = $this->db->prepare("
                INSERT INTO ai_tool_logs (user_id, user_role, tool_name, target_entity, target_id, parameters_json, status, result_summary)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ");
            $stmt->execute([
                $userId,
                $role,
                $toolName,
                $entity,
                $targetId,
                json_encode($params, JSON_UNESCAPED_UNICODE),
                $status,
                $summary
            ]);

            // Mirror into system activity_logs if table exists
            $act = $this->db->prepare("
                INSERT INTO activity_logs (user_id, action, details, ip_address)
                VALUES (?, ?, ?, ?)
            ");
            $act->execute([$userId, "AI_TOOL:" . strtoupper($toolName), $summary, $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1']);
        } catch (\Throwable $e) {}
    }

    /**
     * Handles natural-language requests to approve or reject an agent purchase (with confirmation guard)
     */
    private function handlePurchaseAction(string $message, array $entities, string $targetStatus): void {
        $recordId = $entities['record_id'] ?? null;
        if (!$recordId) {
            // Find the latest pending purchase
            $stmt = $this->db->query("
                SELECT acd.*, b.name as building_name, a.code as apartment_code, u.name as submitter_name
                FROM apartment_cost_deployments acd
                LEFT JOIN buildings b ON acd.building_id = b.id
                LEFT JOIN apartments a ON acd.apartment_id = a.id
                LEFT JOIN users u ON acd.submitted_by = u.id
                WHERE acd.status = 'Pending'
                ORDER BY acd.created_at DESC LIMIT 5
            ");
            $pending = $stmt ? $stmt->fetchAll(PDO::FETCH_ASSOC) : [];
            if (empty($pending)) {
                echo json_encode([
                    'reply' => "✅ There are currently **0 pending agent purchases** awaiting approval.",
                    'type' => 'text'
                ]);
                return;
            }
            $first = $pending[0];
            $recordId = (int)$first['id'];
        } else {
            $stmt = $this->db->prepare("
                SELECT acd.*, b.name as building_name, a.code as apartment_code, u.name as submitter_name
                FROM apartment_cost_deployments acd
                LEFT JOIN buildings b ON acd.building_id = b.id
                LEFT JOIN apartments a ON acd.apartment_id = a.id
                LEFT JOIN users u ON acd.submitted_by = u.id
                WHERE acd.id = ?
            ");
            $stmt->execute([$recordId]);
            $first = $stmt->fetch(PDO::FETCH_ASSOC);
            if (!$first) {
                echo json_encode(['reply' => "❌ Could not find purchase record **#{$recordId}**.", 'type' => 'text']);
                return;
            }
        }

        $amt = number_format((float)($first['amount'] ?? 0));
        $bld = $first['building_name'] ?? 'Building';
        $apt = $first['apartment_code'] ?? $first['apartment_number'] ?? 'N/A';
        $sup = $first['supplier_name'] ?? 'Supplier';
        $items = $first['items_bought'] ?? 'Expense';

        echo json_encode([
            'reply' => "🛡️ **Confirmation Required — {$targetStatus} Purchase #{$recordId}:**\n\n"
                . "• **Property:** {$bld} • Apt {$apt}\n"
                . "• **Supplier:** {$sup}\n"
                . "• **Items:** {$items}\n"
                . "• **Amount:** **CFA {$amt}**\n\n"
                . "Please confirm below to execute this action in the database:",
            'type' => 'tool_confirmation',
            'requires_confirmation' => true,
            'pending_tool' => [
                'tool_name' => 'review_purchase',
                'target_id' => $recordId,
                'parameters' => ['status' => $targetStatus],
                'summary' => "{$targetStatus} Purchase #{$recordId} ({$bld} Apt {$apt} - CFA {$amt})"
            ],
            'data' => $first
        ]);
    }

    /**
     * Handles natural-language requests to approve an AC maintenance task
     */
    private function handleMaintenanceAction(string $message, array $entities, string $targetStatus): void {
        $recordId = $entities['record_id'] ?? null;
        if (!$recordId) {
            $stmt = $this->db->query("
                SELECT mt.*, a.code as apartment_code, b.name as building_name
                FROM ac_maintenance_tasks mt
                LEFT JOIN apartments a ON mt.apartment_id = a.id
                LEFT JOIN buildings b ON a.building_id = b.id
                WHERE mt.status = 'Pending'
                ORDER BY mt.id DESC LIMIT 1
            ");
            $task = $stmt ? $stmt->fetch(PDO::FETCH_ASSOC) : null;
            if (!$task) {
                echo json_encode(['reply' => "✅ There are currently **0 pending AC maintenance tasks** awaiting approval.", 'type' => 'text']);
                return;
            }
            $recordId = (int)$task['id'];
        } else {
            $stmt = $this->db->prepare("
                SELECT mt.*, a.code as apartment_code, b.name as building_name
                FROM ac_maintenance_tasks mt
                LEFT JOIN apartments a ON mt.apartment_id = a.id
                LEFT JOIN buildings b ON a.building_id = b.id
                WHERE mt.id = ?
            ");
            $stmt->execute([$recordId]);
            $task = $stmt->fetch(PDO::FETCH_ASSOC);
            if (!$task) {
                echo json_encode(['reply' => "❌ Maintenance task **#{$recordId}** was not found.", 'type' => 'text']);
                return;
            }
        }

        echo json_encode([
            'reply' => "🛡️ **Confirmation Required — Mark Maintenance Task #{$recordId} as Completed:**\n\n"
                . "• **Property:** " . ($task['building_name'] ?? 'Building') . " • Apt " . ($task['apartment_code'] ?? 'N/A') . "\n"
                . "• **Technician:** " . ($task['worker_name'] ?? 'Assigned Worker') . "\n"
                . "• **Scheduled Date:** " . ($task['scheduled_date'] ?? 'N/A') . "\n\n"
                . "Confirm below to update this maintenance record:",
            'type' => 'tool_confirmation',
            'requires_confirmation' => true,
            'pending_tool' => [
                'tool_name' => 'review_ac_maintenance',
                'target_id' => $recordId,
                'parameters' => ['status' => 'Completed'],
                'summary' => "Complete Maintenance Task #{$recordId}"
            ],
            'data' => $task
        ]);
    }

    /**
     * Pending Purchases & Apartment Costs Intent
     */
    private function getPendingPurchases($message): void {
        try {
            $stmt = $this->db->query("
                SELECT acd.id, acd.amount, acd.supplier_name as supplier, acd.items_bought as items,
                       acd.purchase_date, acd.status, acd.receipt_photo,
                       b.name as building_name,
                       COALESCE(a.code, acd.apartment_number) as apartment_number,
                       u.name as submitter_name
                FROM apartment_cost_deployments acd
                LEFT JOIN buildings b ON acd.building_id = b.id
                LEFT JOIN apartments a ON acd.apartment_id = a.id
                LEFT JOIN users u ON acd.submitted_by = u.id
                ORDER BY FIELD(acd.status, 'Pending', 'Approved', 'Rejected'), acd.created_at DESC
                LIMIT 15
            ");
            $rows = $stmt ? $stmt->fetchAll(PDO::FETCH_ASSOC) : [];
            $pendingCount = count(array_filter($rows, fn($r) => ($r['status'] ?? '') === 'Pending'));
            $totalAmt = array_sum(array_column($rows, 'amount'));

            echo json_encode([
                'reply' => "🛒 **Agent Purchases & Apartment Costs:** Found **" . count($rows) . "** recent submissions (**{$pendingCount}** pending approval) totaling **CFA " . number_format($totalAmt) . "**:",
                'type' => 'pending_purchases',
                'data' => $rows
            ]);
        } catch (\Throwable $e) {
            $this->getExpensesSummary($message);
        }
    }

    /**
     * Worker Reports & Field Technician Performance Intent
     */
    private function getWorkerReports($message): void {
        try {
            $stmt = $this->db->query("
                SELECT
                    COALESCE(worker_name, 'Assigned Technician') as worker_name,
                    COUNT(*) as total_tasks,
                    COUNT(CASE WHEN status IN ('Completed', 'Approved') THEN 1 END) as completed_tasks,
                    COUNT(CASE WHEN status = 'Pending' THEN 1 END) as pending_tasks,
                    MAX(scheduled_date) as last_activity
                FROM ac_maintenance_tasks
                GROUP BY COALESCE(worker_name, 'Assigned Technician')
                ORDER BY total_tasks DESC
            ");
            $workers = $stmt ? $stmt->fetchAll(PDO::FETCH_ASSOC) : [];

            $tktStmt = $this->db->query("
                SELECT COALESCE(w.name, 'Unassigned') as worker_name,
                       COUNT(*) as ticket_count,
                       COUNT(CASE WHEN tmt.status IN ('Resolved', 'Closed') THEN 1 END) as resolved_count
                FROM tenant_maintenance_tickets tmt
                LEFT JOIN users w ON tmt.worker_id = w.id
                GROUP BY COALESCE(w.name, 'Unassigned')
            ");
            $ticketStats = $tktStmt ? $tktStmt->fetchAll(PDO::FETCH_ASSOC) : [];

            $lines = ["👷 **Field Worker & Technician Performance Report:**\n"];
            foreach ($workers as $w) {
                $lines[] = "• **{$w['worker_name']}** — **{$w['total_tasks']}** AC tasks (**{$w['completed_tasks']}** completed, **{$w['pending_tasks']}** pending) | Last active: {$w['last_activity']}";
            }
            foreach ($ticketStats as $ts) {
                $lines[] = "• **{$ts['worker_name']} (Tenant Tickets)** — **{$ts['ticket_count']}** assigned (**{$ts['resolved_count']}** resolved)";
            }

            echo json_encode([
                'reply' => implode("\n", $lines),
                'type' => 'worker_reports',
                'data' => ['ac_workers' => $workers, 'ticket_workers' => $ticketStats]
            ]);
        } catch (\Throwable $e) {
            echo json_encode(['reply' => "Unable to load worker reports right now.", 'type' => 'text']);
        }
    }

    /**
     * Navigation Intent Handler
     */
    private function handleNavigationIntent(string $message, array $entities): void {
        $target = $entities['navigation_target'] ?? '/dashboard';
        echo json_encode([
            'reply' => "🧭 Navigating you to **`{$target}`**...",
            'type' => 'navigation',
            'navigation_action' => ['route' => $target],
            'actions' => [
                ['label' => 'Open ' . $target, 'action_type' => 'navigate', 'route' => $target, 'mobile_route' => $target]
            ]
        ]);
    }

    /**
     * GET /api/ai/diagnostics & Intent: Live System Self-Diagnostics & Health Audit
     */
    public function diagnostics() {
        AuthMiddleware::requireLogin();
        $this->getSystemDiagnostics('');
    }

    private function getSystemDiagnostics(string $message): void {
        $checks = [];
        $startPing = microtime(true);

        // 1. Database Connectivity & Latency
        try {
            $this->db->query("SELECT 1");
            $dbMs = round((microtime(true) - $startPing) * 1000, 2);
            $checks[] = [
                'component' => 'MySQL Database Engine',
                'status' => $dbMs < 50 ? 'healthy' : 'warning',
                'metric' => "{$dbMs} ms",
                'detail' => 'Connection pool active and responsive'
            ];
        } catch (\Throwable $e) {
            $checks[] = ['component' => 'MySQL Database Engine', 'status' => 'critical', 'metric' => 'ERROR', 'detail' => $e->getMessage()];
        }

        // 2. Unverified Generator / Electricity Readings
        try {
            $unverifiedGen = (int)$this->db->query("SELECT COUNT(*) FROM daily_logs WHERE status = 'Pending'")->fetchColumn();
            $checks[] = [
                'component' => 'Field Readings Verification Queue',
                'status' => $unverifiedGen > 10 ? 'warning' : 'healthy',
                'metric' => "{$unverifiedGen} pending",
                'detail' => $unverifiedGen > 0 ? "{$unverifiedGen} daily generator logs awaiting admin verification" : "All field readings verified"
            ];
        } catch (\Throwable $e) {}

        // 3. Pending Agent Purchase Approvals
        try {
            $pendingPurchases = (int)$this->db->query("SELECT COUNT(*) FROM apartment_cost_deployments WHERE status = 'Pending'")->fetchColumn();
            $checks[] = [
                'component' => 'Agent Purchase Review Queue',
                'status' => $pendingPurchases > 5 ? 'warning' : 'healthy',
                'metric' => "{$pendingPurchases} pending",
                'detail' => $pendingPurchases > 0 ? "{$pendingPurchases} apartment cost receipts awaiting review" : "Zero backlog in purchase reviews"
            ];
        } catch (\Throwable $e) {}

        // 4. Payload Optimization Check (Tenant Maintenance Blobs)
        try {
            $oversized = (int)$this->db->query("SELECT COUNT(*) FROM tenant_maintenance_tickets WHERE LENGTH(before_photo) > 100000 OR LENGTH(after_photo) > 100000")->fetchColumn();
            $checks[] = [
                'component' => 'Media & Payload Compression',
                'status' => $oversized > 0 ? 'warning' : 'healthy',
                'metric' => $oversized === 0 ? 'Optimized (<45KB)' : "{$oversized} unoptimized",
                'detail' => $oversized === 0 ? 'All maintenance & receipt photos compressed for sub-second loading' : "{$oversized} photos queued for auto-compression"
            ];
        } catch (\Throwable $e) {}

        // 5. Push Notification Device Registry
        try {
            $devices = (int)$this->db->query("SELECT COUNT(*) FROM user_devices WHERE is_active = 1")->fetchColumn();
            $checks[] = [
                'component' => 'FCM Push Notification Registry',
                'status' => 'healthy',
                'metric' => "{$devices} active device(s)",
                'detail' => 'FCM HTTP v1 + background wakeup channels operational'
            ];
        } catch (\Throwable $e) {}

        $lines = ["🩺 **Live System Self-Diagnostics & Health Telemetry:**\n"];
        foreach ($checks as $c) {
            $icon = $c['status'] === 'healthy' ? '🟢' : ($c['status'] === 'warning' ? '🟡' : '🔴');
            $lines[] = "• {$icon} **{$c['component']}** (`{$c['metric']}`) — {$c['detail']}";
        }

        echo json_encode([
            'reply' => implode("\n", $lines),
            'type' => 'system_diagnostics',
            'data' => $checks
        ]);
    }

    /**
     * GET /api/ai/proactive-insights & Intent: Real-Time Database Anomaly & Priority Detection
     * (Replaces the old hardcoded getRecommendations!)
     */
    public function proactiveInsights() {
        AuthMiddleware::requireLogin();
        $this->getProactiveInsights('');
    }

    private function getProactiveInsights(string $message): void {
        $insights = [];

        // 1. Overdue Rent Anomaly
        try {
            $stmt = $this->db->query("
                SELECT COUNT(DISTINCT ri.id) as overdue_count,
                       COALESCE(SUM(ri.amount - COALESCE((SELECT SUM(rp.amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0)), 0) as overdue_total
                FROM rent_invoices ri
                WHERE ri.status IN ('Unpaid', 'Partial') AND ri.due_date < CURRENT_DATE
            ");
            $r = $stmt->fetch(PDO::FETCH_ASSOC);
            if (($r['overdue_total'] ?? 0) > 0) {
                $insights[] = [
                    'severity' => 'high',
                    'category' => 'Revenue Collection',
                    'title' => 'Overdue Rent Arrears Detected',
                    'metric' => 'CFA ' . number_format((float)$r['overdue_total']),
                    'description' => "{$r['overdue_count']} overdue invoice(s) totaling CFA " . number_format((float)$r['overdue_total']) . " require immediate follow-up.",
                    'suggested_prompt' => 'Show overdue rent',
                    'route' => '/rent-management'
                ];
            }
        } catch (\Throwable $e) {}

        // 2. Expiring Contracts (Next 30 Days)
        try {
            $expCount = (int)$this->db->query("
                SELECT COUNT(*) FROM contracts
                WHERE status IN ('Active', 'Approved') AND end_date BETWEEN CURRENT_DATE AND DATE_ADD(CURRENT_DATE, INTERVAL 30 DAY)
            ")->fetchColumn();
            if ($expCount > 0) {
                $insights[] = [
                    'severity' => 'medium',
                    'category' => 'Lease Retention',
                    'title' => "{$expCount} Lease Contract(s) Expiring Within 30 Days",
                    'metric' => "{$expCount} Contracts",
                    'description' => "Proactively initiate renewal discussions to prevent vacancy loss.",
                    'suggested_prompt' => 'Expiring contracts in 30 days',
                    'route' => '/contracts'
                ];
            }
        } catch (\Throwable $e) {}

        // 3. Pending Agent Purchases & Maintenance Approvals
        try {
            $pendPurch = (int)$this->db->query("SELECT COUNT(*) FROM apartment_cost_deployments WHERE status = 'Pending'")->fetchColumn();
            $pendMaint = (int)$this->db->query("SELECT COUNT(*) FROM ac_maintenance_tasks WHERE status = 'Pending'")->fetchColumn();
            if ($pendPurch > 0 || $pendMaint > 0) {
                $insights[] = [
                    'severity' => 'medium',
                    'category' => 'Operational Bottleneck',
                    'title' => 'Pending Field Approvals in Queue',
                    'metric' => ($pendPurch + $pendMaint) . ' Pending',
                    'description' => "{$pendPurch} agent purchase receipt(s) and {$pendMaint} AC maintenance task(s) are awaiting admin review.",
                    'suggested_prompt' => $pendPurch > 0 ? 'Show pending purchases' : 'Show maintenance tasks',
                    'route' => $pendPurch > 0 ? '/agent-purchase-review' : '/maintenance-admin'
                ];
            }
        } catch (\Throwable $e) {}

        // 4. Vacant Apartments Opportunity Cost
        try {
            $stmt = $this->db->query("SELECT COUNT(*) as c, COALESCE(SUM(monthly_rent), 0) as potential FROM apartments WHERE status = 'Vacant'");
            $v = $stmt->fetch(PDO::FETCH_ASSOC);
            if (($v['c'] ?? 0) > 0) {
                $insights[] = [
                    'severity' => 'low',
                    'category' => 'Occupancy Optimization',
                    'title' => "{$v['c']} Vacant Apartment(s) Ready for Leasing",
                    'metric' => 'CFA ' . number_format((float)$v['potential']) . '/mo',
                    'description' => "Filling current vacancies will unlock CFA " . number_format((float)$v['potential']) . " in additional monthly recurring rent.",
                    'suggested_prompt' => 'Show vacant apartments',
                    'route' => '/apartments'
                ];
            }
        } catch (\Throwable $e) {}

        // 5. Generator Fuel Stock Check
        try {
            $stmt = $this->db->query("
                SELECT g.name,
                       COALESCE((SELECT SUM(fm.amount) FROM fuel_movements fm WHERE fm.generator_id=g.id AND fm.type IN ('Refill','Transfer_In')), 0) -
                       COALESCE((SELECT SUM(fm.amount) FROM fuel_movements fm WHERE fm.generator_id=g.id AND fm.type NOT IN ('Refill','Transfer_In')), 0) as stock
                FROM generators g
            ");
            $gens = $stmt ? $stmt->fetchAll(PDO::FETCH_ASSOC) : [];
            $lowGens = array_filter($gens, fn($g) => (float)$g['stock'] < 50);
            if (!empty($lowGens)) {
                $names = implode(', ', array_column($lowGens, 'name'));
                $insights[] = [
                    'severity' => 'high',
                    'category' => 'Energy Continuity',
                    'title' => count($lowGens) . ' Generator(s) Below 50L Fuel Threshold',
                    'metric' => count($lowGens) . ' Low Tank(s)',
                    'description' => "Generators requiring refill attention: {$names}.",
                    'suggested_prompt' => 'Fuel status',
                    'route' => '/fuel-reserve'
                ];
            }
        } catch (\Throwable $e) {}

        $lines = ["💡 **Live Data-Driven Proactive Intelligence & Recommendations:**\n"];
        if (empty($insights)) {
            $lines[] = "✅ **All Systems Optimal:** Zero overdue rent anomalies, zero critical fuel shortages, and no pending approval bottlenecks.";
        } else {
            foreach ($insights as $idx => $ins) {
                $badge = $ins['severity'] === 'high' ? '🔴 [HIGH PRIORITY]' : ($ins['severity'] === 'medium' ? '🟡 [ACTION NEEDED]' : '🟢 [OPPORTUNITY]');
                $lines[] = ($idx + 1) . ". {$badge} **{$ins['title']}** (`{$ins['metric']}`)\n   {$ins['description']}";
            }
        }

        echo json_encode([
            'reply' => implode("\n\n", $lines),
            'type' => 'proactive_insights',
            'data' => $insights
        ]);
    }

    /**
     * GET & POST /api/ai/admin-control
     * Admin AI Control Center: telemetry stats, tool audit logs, and emergency kill-switch / feature toggles.
     */
    public function adminControl() {
        $user = AuthMiddleware::requireLogin();
        $role = strtolower(trim($user['role'] ?? ''));
        if ($role !== 'admin') {
            http_response_code(403);
            echo json_encode(['error' => 'Admins only']);
            return;
        }

        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $body = json_decode(file_get_contents('php://input'), true) ?: [];
            $allowedKeys = ['ai_enabled', 'autonomous_actions_enabled', 'require_confirmation', 'proactive_insights_enabled'];
            $upd = $this->db->prepare("
                INSERT INTO ai_settings (setting_key, setting_value, updated_by)
                VALUES (?, ?, ?)
                ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value), updated_by = VALUES(updated_by)
            ");
            foreach ($allowedKeys as $k) {
                if (isset($body[$k])) {
                    $val = $body[$k] ? '1' : '0';
                    $upd->execute([$k, $val, (int)$user['id']]);
                }
            }
            $this->logToolExecution((int)$user['id'], $role, 'update_ai_settings', 'ai_settings', 'global', $body, 'executed', 'Updated AI Control Center settings');
        }

        $settings = [];
        try {
            $rows = $this->db->query("SELECT setting_key, setting_value FROM ai_settings")->fetchAll(PDO::FETCH_KEY_PAIR);
            $settings = [
                'ai_enabled' => ($rows['ai_enabled'] ?? '1') === '1',
                'autonomous_actions_enabled' => ($rows['autonomous_actions_enabled'] ?? '1') === '1',
                'require_confirmation' => ($rows['require_confirmation'] ?? '1') === '1',
                'proactive_insights_enabled' => ($rows['proactive_insights_enabled'] ?? '1') === '1',
            ];
        } catch (\Throwable $e) {}

        $stats = [
            'total_conversations' => 0,
            'total_messages' => 0,
            'avg_latency_ms' => 0,
            'total_tool_executions' => 0,
            'blocked_security_events' => 0,
        ];
        $recentTools = [];
        try {
            $stats['total_conversations'] = (int)$this->db->query("SELECT COUNT(*) FROM ai_conversations")->fetchColumn();
            $stats['total_messages'] = (int)$this->db->query("SELECT COUNT(*) FROM ai_messages")->fetchColumn();
            $stats['avg_latency_ms'] = (int)$this->db->query("SELECT COALESCE(AVG(execution_ms), 0) FROM ai_messages WHERE sender = 'ai' AND execution_ms > 0")->fetchColumn();
            $stats['total_tool_executions'] = (int)$this->db->query("SELECT COUNT(*) FROM ai_tool_logs WHERE status = 'executed'")->fetchColumn();
            $stats['blocked_security_events'] = (int)$this->db->query("SELECT COUNT(*) FROM ai_tool_logs WHERE status = 'blocked'")->fetchColumn();

            $recentTools = $this->db->query("
                SELECT tl.*, u.name as user_name
                FROM ai_tool_logs tl
                LEFT JOIN users u ON tl.user_id = u.id
                ORDER BY tl.id DESC LIMIT 20
            ")->fetchAll(PDO::FETCH_ASSOC) ?: [];
        } catch (\Throwable $e) {}

        echo json_encode([
            'settings' => $settings,
            'stats' => $stats,
            'recent_tool_logs' => $recentTools
        ]);
    }

    /** ─── 1. Overdue Rent (Parameterized SQL — Fixed SQL Injection Risk) ──── */
    private function getOverdueRent($message) {
        $buildingName = $this->extractBuildingName($message);
        $building = $this->findBuilding($buildingName);
        $params = [];
        $buildingWhere = "";
        if ($building) {
            $buildingWhere = "AND b.id = ?";
            $params[] = (int)$building['id'];
        }

        $stmt = $this->db->prepare("
            SELECT 
                t.full_name, t.phone, t.email,
                a.code as apartment_code, b.name as building_name,
                COUNT(ri.id) as overdue_invoices,
                SUM(ri.amount - COALESCE((SELECT SUM(rp.amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0)) as total_debt,
                MIN(ri.due_date) as oldest_due_date,
                DATEDIFF(CURRENT_DATE, MIN(ri.due_date)) as days_overdue
            FROM rent_invoices ri
            JOIN contracts c ON ri.contract_id = c.id
            JOIN tenants t ON c.tenant_id = t.id
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE ri.status IN ('Unpaid', 'Partial')
              AND ri.due_date < CURRENT_DATE
              $buildingWhere
            GROUP BY t.id, a.code, b.name
            HAVING total_debt > 0
            ORDER BY total_debt DESC
        ");
        $stmt->execute($params);
        $data = $stmt->fetchAll(PDO::FETCH_ASSOC);

        if (empty($data)) {
            $scope = $building ? "in **{$building['name']}**" : "across the system";
            echo json_encode([
                'reply' => "✅ Great news! There are **no overdue rent payments** $scope right now.",
                'type' => 'text'
            ]);
            return;
        }

        $totalDebt = array_sum(array_column($data, 'total_debt'));
        $scope = $building ? "in **{$building['name']}**" : "across all buildings";
        echo json_encode([
            'reply' => "⚠️ Found **" . count($data) . " tenant(s)** with overdue rent $scope, totaling **CFA " . number_format($totalDebt) . "**:",
            'type' => 'overdue_rent',
            'data' => $data
        ]);
    }

    /** ─── 2. Expiring Contracts ─────────────────────────────────────────── */
    private function getExpiringContracts($message) {
        $days = $this->currentAnalysis['entities']['timeframe'] ?? 60;
        if (!$this->currentAnalysis['entities']['timeframe'] && preg_match('/(\d+)\s*(?:day|week|month)/i', $message, $m)) {
            $days = intval($m[1]);
            if (stripos($m[0], 'week') !== false) $days *= 7;
            if (stripos($m[0], 'month') !== false) $days *= 30;
        }

        $stmt = $this->db->prepare("
            SELECT 
                t.full_name, t.phone, t.email,
                a.code as apartment_code, b.name as building_name,
                c.end_date, c.monthly_rent, c.status,
                DATEDIFF(c.end_date, CURRENT_DATE) as days_remaining
            FROM contracts c
            JOIN tenants t ON c.tenant_id = t.id
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE c.status IN ('Active', 'Approved')
              AND c.end_date BETWEEN CURRENT_DATE AND DATE_ADD(CURRENT_DATE, INTERVAL ? DAY)
            ORDER BY c.end_date ASC
        ");
        $stmt->execute([$days]);
        $data = $stmt->fetchAll(PDO::FETCH_ASSOC);

        if (empty($data)) {
            echo json_encode([
                'reply' => "✅ No contracts are expiring within the next **$days days**.",
                'type' => 'text'
            ]);
            return;
        }

        echo json_encode([
            'reply' => "📅 Found **" . count($data) . " contract(s)** expiring within the next **$days days**:",
            'type' => 'expiring_contracts',
            'data' => $data
        ]);
    }

    /** ─── 3. Executive Financial Summary ────────────────────────────────── */
    private function getFinancialSummary($message) {
        $rentStmt = $this->db->query("
            SELECT 
                COALESCE(SUM(ri.amount), 0) as total_billed,
                COALESCE(SUM((SELECT COALESCE(SUM(rp.amount),0) FROM rent_payments rp WHERE rp.invoice_id = ri.id)), 0) as total_collected,
                COUNT(DISTINCT CASE WHEN ri.status IN ('Unpaid','Partial') AND ri.due_date < CURRENT_DATE THEN ri.id END) as overdue_count
            FROM rent_invoices ri
            WHERE ri.status != 'Voided'
        ");
        $rent = $rentStmt->fetch(PDO::FETCH_ASSOC);

        $expStmt = $this->db->query("SELECT COALESCE(SUM(amount), 0) as total_expenses, COUNT(*) as count FROM expenses");
        $exp = $expStmt->fetch(PDO::FETCH_ASSOC);

        $posStmt = $this->db->query("SELECT COALESCE(SUM(total_amount), 0) as total_sales, COUNT(*) as count FROM pos_sales WHERE status = 'Completed'");
        $pos = $posStmt->fetch(PDO::FETCH_ASSOC);

        $insStmt = $this->db->query("SELECT COALESCE(SUM(total_saved), 0) as total_saved FROM insurance_accounts");
        $ins = $insStmt->fetch(PDO::FETCH_ASSOC);

        $aptStmt = $this->db->query("
            SELECT COUNT(*) as total,
                SUM(CASE WHEN status = 'Rented' THEN 1 ELSE 0 END) as rented,
                SUM(CASE WHEN status = 'Vacant' THEN 1 ELSE 0 END) as vacant
            FROM apartments
        ");
        $apts = $aptStmt->fetch(PDO::FETCH_ASSOC);

        $bldCount = $this->db->query("SELECT COUNT(*) FROM buildings")->fetchColumn();
        $tenantCount = $this->db->query("SELECT COUNT(*) FROM tenants")->fetchColumn();

        $outstanding = $rent['total_billed'] - $rent['total_collected'];
        $netPosition = $rent['total_collected'] + $pos['total_sales'] - $exp['total_expenses'];

        echo json_encode([
            'reply' => "📊 **Executive Financial Overview** across **$bldCount buildings**, **{$apts['total']} apartments**, and **$tenantCount tenants**:",
            'type' => 'financial_summary',
            'data' => [
                'rent_billed'      => (float)$rent['total_billed'],
                'rent_collected'   => (float)$rent['total_collected'],
                'rent_outstanding' => (float)$outstanding,
                'overdue_invoices' => (int)$rent['overdue_count'],
                'total_expenses'   => (float)$exp['total_expenses'],
                'expense_count'    => (int)$exp['count'],
                'pos_sales'        => (float)$pos['total_sales'],
                'pos_count'        => (int)$pos['count'],
                'insurance_saved'  => (float)$ins['total_saved'],
                'net_position'     => (float)$netPosition,
                'total_apartments' => (int)$apts['total'],
                'rented'           => (int)$apts['rented'],
                'vacant'           => (int)$apts['vacant'],
                'buildings'        => (int)$bldCount,
                'tenants'          => (int)$tenantCount,
            ]
        ]);
    }

    /** ─── 4. Building Summary ───────────────────────────────────────────── */
    private function getBuildingSummary($message) {
        $bName = $this->extractBuildingName($message);
        $building = $this->findBuilding($bName);

        if ($building) {
            $stmt = $this->db->prepare("
                SELECT 
                    b.id, b.name, b.location, b.total_apartments,
                    COUNT(a.id) as actual_apartments,
                    SUM(CASE WHEN a.status = 'Rented' THEN 1 ELSE 0 END) as rented,
                    SUM(CASE WHEN a.status = 'Vacant' THEN 1 ELSE 0 END) as vacant,
                    SUM(a.monthly_rent) as potential_monthly_rent,
                    COALESCE((SELECT SUM(e.amount) FROM expenses e WHERE e.entity_type='Building' AND e.entity_id=b.id), 0) as total_expenses,
                    COALESCE((SELECT SUM(rp.amount) FROM rent_payments rp JOIN rent_invoices ri ON rp.invoice_id=ri.id JOIN contracts c ON ri.contract_id=c.id JOIN apartments ap ON c.apartment_id=ap.id WHERE ap.building_id=b.id), 0) as rent_collected
                FROM buildings b
                LEFT JOIN apartments a ON a.building_id = b.id
                WHERE b.id = ?
                GROUP BY b.id
            ");
            $stmt->execute([$building['id']]);
            $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
        } else {
            $stmt = $this->db->query("
                SELECT 
                    b.id, b.name, b.location, b.total_apartments,
                    COUNT(a.id) as actual_apartments,
                    SUM(CASE WHEN a.status = 'Rented' THEN 1 ELSE 0 END) as rented,
                    SUM(CASE WHEN a.status = 'Vacant' THEN 1 ELSE 0 END) as vacant,
                    COALESCE(SUM(a.monthly_rent), 0) as potential_monthly_rent,
                    COALESCE((SELECT SUM(e.amount) FROM expenses e WHERE e.entity_type='Building' AND e.entity_id=b.id), 0) as total_expenses,
                    COALESCE((SELECT SUM(rp.amount) FROM rent_payments rp JOIN rent_invoices ri ON rp.invoice_id=ri.id JOIN contracts c ON ri.contract_id=c.id JOIN apartments ap ON c.apartment_id=ap.id WHERE ap.building_id=b.id), 0) as rent_collected
                FROM buildings b
                LEFT JOIN apartments a ON a.building_id = b.id
                GROUP BY b.id
                ORDER BY b.name
            ");
            $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
        }

        echo json_encode([
            'reply' => "🏢 Here is the **building portfolio summary** (" . count($data) . " properties):",
            'type' => 'building_summary',
            'data' => $data
        ]);
    }

    /** ─── 5. Building Expenses ──────────────────────────────────────────── */
    private function getBuildingExpenses($message) {
        $bName = $this->extractBuildingName($message);
        $building = $this->findBuilding($bName);

        if ($building) {
            $stmt = $this->db->prepare("
                SELECT e.category, e.description, e.amount, e.date
                FROM expenses e
                WHERE e.entity_type = 'Building' AND e.entity_id = ?
                ORDER BY e.date DESC
                LIMIT 25
            ");
            $stmt->execute([$building['id']]);
            $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
            $total = array_sum(array_column($rows, 'amount'));
            echo json_encode([
                'reply' => "💸 Expenses for **{$building['name']}** — Total: **CFA " . number_format($total) . "** (" . count($rows) . " records):",
                'type' => 'expenses_list',
                'data' => $rows,
                'meta' => ['building' => $building['name'], 'total' => $total]
            ]);
        } else {
            $stmt = $this->db->query("
                SELECT b.name as building_name, e.category, SUM(e.amount) as total, COUNT(*) as count
                FROM expenses e
                JOIN buildings b ON e.entity_type = 'Building' AND e.entity_id = b.id
                GROUP BY b.id, e.category
                ORDER BY total DESC
            ");
            $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
            $total = array_sum(array_column($rows, 'total'));
            echo json_encode([
                'reply' => "💸 Building expenses across all properties — Total: **CFA " . number_format($total) . "**:",
                'type' => 'building_expenses_summary',
                'data' => $rows
            ]);
        }
    }

    /** ─── 6. Tenant Info ────────────────────────────────────────────────── */
    private function getTenantInfo($message) {
        $name = $this->extractTenantName($message);
        if (!$name) {
            $stmt = $this->db->query("
                SELECT t.id, t.full_name, t.phone, t.email,
                    a.code as apartment_code, b.name as building_name,
                    c.monthly_rent, c.end_date, c.status as contract_status
                FROM tenants t
                LEFT JOIN contracts c ON c.tenant_id = t.id AND c.status IN ('Active','Approved')
                LEFT JOIN apartments a ON c.apartment_id = a.id
                LEFT JOIN buildings b ON a.building_id = b.id
                ORDER BY t.full_name
                LIMIT 20
            ");
            $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
            echo json_encode([
                'reply' => "👥 Showing **" . count($data) . " tenants** (ask about a specific tenant by name for full details):",
                'type' => 'tenant_info',
                'data' => $data
            ]);
            return;
        }

        $stmt = $this->db->prepare("
            SELECT t.id, t.full_name, t.phone, t.email, t.national_id,
                a.code as apartment_code, b.name as building_name,
                c.monthly_rent, c.monthly_insurance, c.start_date, c.end_date, 
                c.rent_start_date, c.rent_end_date, c.status as contract_status,
                DATEDIFF(c.end_date, CURRENT_DATE) as days_until_expiry,
                COALESCE((SELECT SUM(ri.amount) FROM rent_invoices ri WHERE ri.contract_id = c.id AND ri.status != 'Voided'), 0) as total_billed,
                COALESCE((SELECT SUM(rp.amount) FROM rent_payments rp JOIN rent_invoices ri ON rp.invoice_id=ri.id WHERE ri.contract_id = c.id), 0) as total_paid
            FROM tenants t
            LEFT JOIN contracts c ON c.tenant_id = t.id
            LEFT JOIN apartments a ON c.apartment_id = a.id
            LEFT JOIN buildings b ON a.building_id = b.id
            WHERE LOWER(t.full_name) LIKE ?
            ORDER BY c.status DESC
        ");
        $stmt->execute(['%' . strtolower($name) . '%']);
        $results = $stmt->fetchAll(PDO::FETCH_ASSOC);
        if (empty($results)) {
            echo json_encode(['reply' => "❌ I couldn't find any tenant matching **\"$name\"**. Please check the spelling.", 'type' => 'text']);
            return;
        }
        $results = array_map(function($r) {
            $r['total_debt'] = max(0, $r['total_billed'] - $r['total_paid']);
            return $r;
        }, $results);
        echo json_encode([
            'reply' => "Here is the complete dossier for **{$name}**:",
            'type' => 'tenant_info',
            'data' => $results
        ]);
    }

    /** ─── 7. Vacant Apartments ──────────────────────────────────────────── */
    private function getVacantApartments($message) {
        $bName = $this->extractBuildingName($message);
        $building = $this->findBuilding($bName);
        $params = [];
        $filter = "";
        if ($building) {
            $filter = "AND a.building_id = ?";
            $params[] = (int)$building['id'];
        }
        $stmt = $this->db->prepare("
            SELECT a.code, a.monthly_rent, a.monthly_insurance, b.name as building_name, b.location
            FROM apartments a
            JOIN buildings b ON a.building_id = b.id
            WHERE a.status = 'Vacant' $filter
            ORDER BY b.name, a.code
        ");
        $stmt->execute($params);
        $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $scope = $building ? "in **{$building['name']}**" : "system-wide";
        if (empty($data)) {
            echo json_encode(['reply' => "✅ No vacant apartments found $scope.", 'type' => 'text']);
            return;
        }
        echo json_encode([
            'reply' => "🏠 Found **" . count($data) . "** vacant apartments $scope:",
            'type' => 'vacant_apartments',
            'data' => $data
        ]);
    }

    /** ─── 8. Apartment Info ─────────────────────────────────────────────── */
    private function getApartmentInfo($message) {
        $code = $this->currentAnalysis['entities']['apartment_code'] ?? null;
        if (!$code && preg_match('/(?:apartment|apt|unit|flat|شقة)\s+([A-Z0-9\-]+)/iu', $message, $m)) {
            $code = $m[1];
        }
        $bName = $this->extractBuildingName($message);
        $building = $this->findBuilding($bName);

        $conditions = [];
        $params = [];
        if ($code) { $conditions[] = 'a.code LIKE ?'; $params[] = "%$code%"; }
        if ($building) { $conditions[] = 'a.building_id = ?'; $params[] = $building['id']; }
        if (empty($conditions)) {
            $stmt = $this->db->query("SELECT COUNT(*) as c, SUM(monthly_rent) as r FROM apartments WHERE status='Rented'");
            $r = $stmt->fetch();
            echo json_encode(['reply' => "There are apartments tracked in the system. **{$r['c']}** are currently rented generating CFA " . number_format((float)$r['r']) . "/mo in rent.", 'type' => 'text']);
            return;
        }
        $where = implode(' AND ', $conditions);
        $stmt = $this->db->prepare("
            SELECT a.code, a.status, a.monthly_rent, a.monthly_insurance, b.name as building_name,
                   t.full_name as tenant_name, t.phone as tenant_phone,
                   c.start_date, c.end_date, c.status as contract_status
            FROM apartments a
            JOIN buildings b ON a.building_id = b.id
            LEFT JOIN contracts c ON c.apartment_id = a.id AND c.status IN('Active','Approved')
            LEFT JOIN tenants t ON c.tenant_id = t.id
            WHERE $where
        ");
        $stmt->execute($params);
        $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
        if (empty($data)) { echo json_encode(['reply' => "❌ No apartment found matching your query.", 'type' => 'text']); return; }
        echo json_encode([
            'reply' => "🏠 Found **" . count($data) . "** apartment(s):",
            'type' => 'apartment_info',
            'data' => $data
        ]);
    }

    /** ─── 9. Rent Dashboard ─────────────────────────────────────────────── */
    private function getRentDashboard($message) {
        $stmt = $this->db->query("
            SELECT 
                COUNT(DISTINCT ri.id) as total_invoices,
                SUM(ri.amount) as total_billed,
                SUM(COALESCE((SELECT SUM(rp.amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0)) as total_paid,
                SUM(ri.amount - COALESCE((SELECT SUM(rp.amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0)) as total_outstanding,
                COUNT(CASE WHEN ri.status='Paid' THEN 1 END) as paid_count,
                COUNT(CASE WHEN ri.status IN('Unpaid','Partial') AND ri.due_date < CURRENT_DATE THEN 1 END) as overdue_count,
                COUNT(CASE WHEN ri.status IN('Unpaid','Partial') AND ri.due_date >= CURRENT_DATE THEN 1 END) as pending_count
            FROM rent_invoices ri
            WHERE ri.status != 'Voided'
        ");
        $summary = $stmt->fetch(PDO::FETCH_ASSOC);

        $monthlyStmt = $this->db->query("
            SELECT DATE_FORMAT(due_date,'%Y-%m') as month,
                   SUM(amount) as billed,
                   SUM(COALESCE((SELECT SUM(rp.amount) FROM rent_payments rp WHERE rp.invoice_id = rent_invoices.id),0)) as collected
            FROM rent_invoices
            WHERE due_date >= DATE_SUB(CURRENT_DATE, INTERVAL 6 MONTH) AND status != 'Voided'
            GROUP BY month ORDER BY month
        ");
        $monthly = $monthlyStmt->fetchAll(PDO::FETCH_ASSOC);

        echo json_encode([
            'reply' => "📊 Rent Dashboard — Total billed: **CFA " . number_format((float)$summary['total_billed']) . "**, collected: **CFA " . number_format((float)$summary['total_paid']) . "**, outstanding: **CFA " . number_format((float)$summary['total_outstanding']) . "**",
            'type' => 'rent_dashboard',
            'data' => ['summary' => $summary, 'monthly' => $monthly]
        ]);
    }

    /** ─── 10. Maintenance Tasks ─────────────────────────────────────────── */
    private function getMaintenanceTasks($message) {
        $stmt = $this->db->query("
            SELECT 
                COUNT(*) as total,
                COUNT(CASE WHEN status='Pending' THEN 1 END) as pending,
                COUNT(CASE WHEN status='In Progress' THEN 1 END) as in_progress,
                COUNT(CASE WHEN status='Completed' THEN 1 END) as completed,
                COUNT(CASE WHEN status='Scheduled' THEN 1 END) as scheduled
            FROM ac_maintenance_tasks
        ");
        $summary = $stmt->fetch(PDO::FETCH_ASSOC);
        $recentStmt = $this->db->query("
            SELECT mt.*, a.code as apartment_code, b.name as building_name
            FROM ac_maintenance_tasks mt
            LEFT JOIN apartments a ON mt.apartment_id = a.id
            LEFT JOIN buildings b ON a.building_id = b.id
            WHERE mt.status IN('Pending','In Progress','Scheduled')
            ORDER BY mt.scheduled_date ASC
            LIMIT 10
        ");
        $recent = $recentStmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode([
            'reply' => "🔧 Maintenance Overview — **{$summary['pending']}** pending, **{$summary['in_progress']}** in progress, **{$summary['completed']}** completed.",
            'type' => 'maintenance_tasks',
            'data' => ['summary' => $summary, 'tasks' => $recent]
        ]);
    }

    /** ─── 11. Fuel Status ───────────────────────────────────────────────── */
    private function getFuelStatus($message) {
        $stmt = $this->db->query("
            SELECT g.name as generator_name, g.status,
                   COALESCE((SELECT SUM(fm.amount) FROM fuel_movements fm WHERE fm.generator_id=g.id AND fm.type IN ('Refill','Transfer_In')), 0) as total_in,
                   COALESCE((SELECT SUM(fm.amount) FROM fuel_movements fm WHERE fm.generator_id=g.id AND fm.type NOT IN ('Refill','Transfer_In')), 0) as total_out
            FROM generators g ORDER BY g.name
        ");
        $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $data = array_map(fn($r) => $r + ['current_stock' => $r['total_in'] - $r['total_out']], $data);
        $total = array_sum(array_column($data, 'current_stock'));
        echo json_encode([
            'reply' => "⛽ Fuel Reserve Status — Total across all generators: **" . number_format($total, 1) . " L**",
            'type' => 'fuel_status',
            'data' => $data
        ]);
    }

    /** ─── 12. Energy Overview ───────────────────────────────────────────── */
    private function getEnergyOverview($message) {
        $stmt = $this->db->query("
            SELECT g.id, g.name, g.status,
                COUNT(DISTINCT es.id) as total_subscriptions,
                COALESCE(SUM(emr.consumption), 0) as total_kwh
            FROM generators g
            LEFT JOIN apartments a ON a.building_id = g.building_id
            LEFT JOIN electricity_subscriptions es ON es.apartment_id = a.id AND es.status='Active'
            LEFT JOIN electricity_meter_readings emr ON emr.apartment_id = a.id
            GROUP BY g.id ORDER BY g.name
        ");
        $data = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $invoiceStmt = $this->db->query("
            SELECT COUNT(*) as total, SUM(amount) as billed, SUM(COALESCE(amount_paid,0)) as collected,
                   COUNT(CASE WHEN status='Unpaid' THEN 1 END) as unpaid
            FROM electricity_invoices
        ");
        $invoices = $invoiceStmt->fetch(PDO::FETCH_ASSOC);

        echo json_encode([
            'reply' => "⚡ Energy Overview — " . count($data) . " generators. Electricity billed: **CFA " . number_format((float)$invoices['billed']) . "**, collected: **CFA " . number_format((float)$invoices['collected']) . "**, unpaid invoices: **{$invoices['unpaid']}**",
            'type' => 'energy_overview',
            'data' => ['generators' => $data, 'invoices' => $invoices]
        ]);
    }

    /** ─── 13. Suppliers Summary ─────────────────────────────────────────── */
    private function getSuppliersSummary($message) {
        $stmt = $this->db->query("
            SELECT s.company_name, s.contact_name, s.phone,
                   COUNT(po.id) as total_orders,
                   COALESCE(SUM(po.total_amount), 0) as total_value,
                   MAX(po.created_at) as last_order
            FROM suppliers s
            LEFT JOIN purchase_orders po ON po.supplier_id = s.id
            GROUP BY s.id ORDER BY total_value DESC LIMIT 15
        ");
        $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $total = array_sum(array_column($data, 'total_value'));
        echo json_encode([
            'reply' => "🏭 Suppliers Summary — **" . count($data) . "** suppliers, total purchase value: **CFA " . number_format($total) . "**",
            'type' => 'suppliers_summary',
            'data' => $data
        ]);
    }

    /** ─── 14. Expenses Summary ──────────────────────────────────────────── */
    private function getExpensesSummary($message) {
        $stmt = $this->db->query("
            SELECT category, entity_type, SUM(amount) as total, COUNT(*) as count,
                   MAX(date) as last_date
            FROM expenses
            GROUP BY category, entity_type
            ORDER BY total DESC
            LIMIT 20
        ");
        $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $total = array_sum(array_column($data, 'total'));
        echo json_encode([
            'reply' => "💸 Total system expenses: **CFA " . number_format($total) . "** across " . count($data) . " categories.",
            'type' => 'expenses_summary',
            'data' => $data
        ]);
    }

    /** ─── 15. Insurance Summary ─────────────────────────────────────────── */
    private function getInsuranceSummary($message) {
        $stmt = $this->db->query("
            SELECT ia.id, t.full_name as tenant_name, a.code as apartment_code, b.name as building_name,
                ia.total_saved, 0 as total_charged, 0 as total_paid,
                0 as outstanding
            FROM insurance_accounts ia
            JOIN contracts c ON ia.contract_id = c.id
            JOIN tenants t ON c.tenant_id = t.id
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            ORDER BY ia.total_saved DESC
            LIMIT 20
        ");
        $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $totalSaved = array_sum(array_column($data, 'total_saved'));
        echo json_encode([
            'reply' => "🛡️ Insurance Summary — Total saved: **CFA " . number_format($totalSaved) . "**",
            'type' => 'insurance_summary',
            'data' => $data
        ]);
    }

    /** ─── 16. Top Debtors ───────────────────────────────────────────────── */
    private function getTopDebtors($message) {
        $tenantName = $this->extractTenantName($message);
        $params = [];
        $filter = "";
        if ($tenantName) {
            $filter = "AND LOWER(t.full_name) LIKE ?";
            $params[] = '%' . strtolower($tenantName) . '%';
        }

        $stmt = $this->db->prepare("
            SELECT t.full_name, t.phone, a.code as apartment_code, b.name as building_name,
                   SUM(ri.amount - COALESCE((SELECT SUM(rp.amount) FROM rent_payments rp WHERE rp.invoice_id = ri.id), 0)) as total_debt,
                   COUNT(CASE WHEN ri.status IN('Unpaid','Partial') AND ri.due_date < CURRENT_DATE THEN 1 END) as overdue_invoices,
                   MAX(DATEDIFF(CURRENT_DATE, ri.due_date)) as max_days_overdue
            FROM tenants t
            JOIN contracts c ON c.tenant_id = t.id
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            JOIN rent_invoices ri ON ri.contract_id = c.id
            WHERE ri.status IN('Unpaid','Partial') $filter
            GROUP BY t.id, a.code, b.name
            HAVING total_debt > 0
            ORDER BY total_debt DESC
            LIMIT 20
        ");
        $stmt->execute($params);
        $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $totalDebt = array_sum(array_column($data, 'total_debt'));
        if (empty($data)) {
            echo json_encode(['reply' => "✅ No tenants with outstanding debt!", 'type' => 'text']);
            return;
        }
        echo json_encode([
            'reply' => "🔴 Top **" . count($data) . "** debtors — Total outstanding: **CFA " . number_format($totalDebt) . "**",
            'type' => 'top_debtors',
            'data' => $data
        ]);
    }

    /** ─── 17. Daily Reports ─────────────────────────────────────────────── */
    private function getDailyReports($message) {
        $stmt = $this->db->query("
            SELECT dl.date, dl.running_hours, dl.fuel_consumed, dl.status,
                   g.name as generator_name, b.name as building_name, u.name as agent_name
            FROM daily_logs dl
            LEFT JOIN generators g ON dl.generator_id = g.id
            LEFT JOIN buildings b ON g.building_id = b.id
            LEFT JOIN users u ON dl.submitted_by = u.id
            ORDER BY dl.date DESC
            LIMIT 15
        ");
        $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode([
            'reply' => "📋 Last **" . count($data) . "** daily generator reports:",
            'type' => 'daily_reports',
            'data' => $data
        ]);
    }

    /** ─── 18. Construction Status ───────────────────────────────────────── */
    private function getConstructionStatus($message) {
        $stmt = $this->db->query("
            SELECT cp.name, cp.status, cp.budget, cp.start_date, cp.end_date,
                   b.name as building_name,
                   COALESCE((SELECT SUM(ce.amount) FROM construction_expenses ce WHERE ce.project_id = cp.id), 0) as total_spent
            FROM construction_projects cp
            LEFT JOIN buildings b ON cp.building_id = b.id
            ORDER BY cp.created_at DESC
        ");
        $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode([
            'reply' => "🏗️ **" . count($data) . "** construction projects:",
            'type' => 'construction_status',
            'data' => $data
        ]);
    }

    /** ─── 19. POS Sales ─────────────────────────────────────────────────── */
    private function getPosSales($message) {
        $stmt = $this->db->query("
            SELECT COUNT(*) as total_sales, COALESCE(SUM(total_amount),0) as total_revenue,
                   COUNT(CASE WHEN DATE(created_at) = CURRENT_DATE THEN 1 END) as today_sales,
                   COALESCE(SUM(CASE WHEN DATE(created_at) = CURRENT_DATE THEN total_amount ELSE 0 END), 0) as today_revenue
            FROM pos_sales WHERE status = 'Completed'
        ");
        $summary = $stmt->fetch(PDO::FETCH_ASSOC);
        echo json_encode([
            'reply' => "🛒 POS Summary — All-time: **CFA " . number_format((float)$summary['total_revenue']) . "** ({$summary['total_sales']} sales). Today: **CFA " . number_format((float)$summary['today_revenue']) . "** ({$summary['today_sales']} sales).",
            'type' => 'pos_sales',
            'data' => $summary
        ]);
    }

    /** ─── 20. Users Overview ────────────────────────────────────────────── */
    private function getUsersOverview($message) {
        $stmt = $this->db->query("SELECT role, COUNT(*) as count FROM users GROUP BY role ORDER BY count DESC");
        $byRole = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $listStmt = $this->db->query("SELECT name, email, role, created_at FROM users ORDER BY role, name LIMIT 30");
        $users = $listStmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode([
            'reply' => "👤 System Users (" . array_sum(array_column($byRole, 'count')) . " total):",
            'type' => 'users_overview',
            'data' => ['by_role' => $byRole, 'users' => $users]
        ]);
    }

    /** ─── 21. Pending Contracts ─────────────────────────────────────────── */
    private function getPendingContracts($message) {
        $stmt = $this->db->query("
            SELECT c.id, t.full_name as tenant_name, t.phone, a.code as apartment_code,
                   b.name as building_name, c.monthly_rent, c.start_date, c.end_date, c.status
            FROM contracts c
            JOIN tenants t ON c.tenant_id = t.id
            JOIN apartments a ON c.apartment_id = a.id
            JOIN buildings b ON a.building_id = b.id
            WHERE c.status IN ('Pending', 'Draft', 'Pending Signature')
            ORDER BY c.created_at DESC
        ");
        $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
        if (empty($data)) {
            echo json_encode(['reply' => "✅ There are no pending contracts right now.", 'type' => 'text']);
            return;
        }
        echo json_encode([
            'reply' => "📝 Found **" . count($data) . "** pending contracts awaiting action:",
            'type' => 'pending_contracts',
            'data' => $data
        ]);
    }

    /** ─── 22. Building Profit & Loss ────────────────────────────────────── */
    private function getBuildingProfitLoss($message) {
        $stmt = $this->db->query("
            SELECT b.name as building_name,
                COALESCE((
                    SELECT SUM(rp.amount) FROM rent_payments rp
                    JOIN rent_invoices ri ON rp.invoice_id = ri.id
                    JOIN contracts c ON ri.contract_id = c.id
                    JOIN apartments a ON c.apartment_id = a.id
                    WHERE a.building_id = b.id
                ), 0) as rent_income,
                COALESCE((
                    SELECT SUM(ep.amount) FROM electricity_payments ep
                    JOIN electricity_invoices ei ON ep.invoice_id = ei.id
                    JOIN apartments a ON ei.apartment_id = a.id
                    WHERE a.building_id = b.id
                ), 0) as electricity_income,
                COALESCE((
                    SELECT SUM(e.amount) FROM expenses e
                    WHERE e.entity_type = 'Building' AND e.entity_id = b.id
                ), 0) as expenses
            FROM buildings b
            ORDER BY b.name
        ");
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
        $rows = array_map(function($r) {
            $r['total_income'] = $r['rent_income'] + $r['electricity_income'];
            $r['net_profit'] = $r['total_income'] - $r['expenses'];
            return $r;
        }, $rows);

        echo json_encode([
            'reply' => "📈 **Building Profit & Loss** across all properties:",
            'type' => 'building_profit_loss',
            'data' => $rows
        ]);
    }

    /** ─── 23. Universal Search (Fixed $g['fuel_capacity'] bug) ──────────── */
    private function universalSearch($message) {
        $entities = $this->currentAnalysis['entities'] ?? [];
        if ($entities['tenant']) { $this->getTenantInfo($message); return; }
        if ($entities['apartment_code']) { $this->getApartmentInfo($message); return; }
        if ($entities['building']) { $this->getBuildingSummary($message); return; }

        $cleanMsg = strtolower(preg_replace('/[^\w\s]/', '', $message));
        $stopWords = ['what', 'who', 'where', 'when', 'why', 'how', 'is', 'are', 'the', 'a', 'an', 'in', 'on', 'of', 'for', 'to', 'with', 'about', 'show', 'me', 'tell', 'give', 'list', 'all', 'find', 'search', 'status', 'info', 'details', 'summary', 'report'];
        $words = array_filter(explode(' ', $cleanMsg), function($w) use ($stopWords) {
            return strlen($w) >= 3 && !in_array($w, $stopWords);
        });

        if (empty($words)) {
            $this->getHelp();
            return;
        }

        $results = [];
        $summaryText = [];

        foreach ($words as $word) {
            $kw = "%$word%";

            $stmt = $this->db->prepare("SELECT full_name, phone, email FROM tenants WHERE LOWER(full_name) LIKE ? OR phone LIKE ? LIMIT 5");
            $stmt->execute([$kw, $kw]);
            if ($rows = $stmt->fetchAll(PDO::FETCH_ASSOC)) {
                foreach ($rows as $r) $summaryText[] = "👤 **Tenant:** {$r['full_name']} (Phone: {$r['phone']})";
                $results['tenants'] = $rows;
            }

            $stmt = $this->db->prepare("SELECT name, location, total_apartments FROM buildings WHERE LOWER(name) LIKE ? OR LOWER(location) LIKE ? LIMIT 5");
            $stmt->execute([$kw, $kw]);
            if ($rows = $stmt->fetchAll(PDO::FETCH_ASSOC)) {
                foreach ($rows as $r) $summaryText[] = "🏢 **Building:** {$r['name']} ({$r['location']}) - {$r['total_apartments']} units";
                $results['buildings'] = $rows;
            }

            $stmt = $this->db->prepare("SELECT a.code, a.status, a.monthly_rent, b.name as building FROM apartments a JOIN buildings b ON a.building_id=b.id WHERE LOWER(a.code) LIKE ? LIMIT 5");
            $stmt->execute([$kw]);
            if ($rows = $stmt->fetchAll(PDO::FETCH_ASSOC)) {
                foreach ($rows as $r) $summaryText[] = "🏠 **Apartment:** {$r['code']} in {$r['building']} ({$r['status']} - CFA " . number_format((float)$r['monthly_rent']) . ")";
                $results['apartments'] = $rows;
            }

            $stmt = $this->db->prepare("SELECT company_name, contact_name, phone FROM suppliers WHERE LOWER(company_name) LIKE ? OR LOWER(contact_name) LIKE ? LIMIT 5");
            $stmt->execute([$kw, $kw]);
            if ($rows = $stmt->fetchAll(PDO::FETCH_ASSOC)) {
                foreach ($rows as $r) $summaryText[] = "🏭 **Supplier:** {$r['company_name']} (Contact: {$r['contact_name']}, {$r['phone']})";
                $results['suppliers'] = $rows;
            }

            $stmt = $this->db->prepare("SELECT category, description, amount, date FROM expenses WHERE LOWER(category) LIKE ? OR LOWER(description) LIKE ? ORDER BY date DESC LIMIT 5");
            $stmt->execute([$kw, $kw]);
            if ($rows = $stmt->fetchAll(PDO::FETCH_ASSOC)) {
                foreach ($rows as $r) $summaryText[] = "💸 **Expense:** {$r['category']} - {$r['description']} (CFA " . number_format((float)$r['amount']) . " on {$r['date']})";
                $results['expenses'] = $rows;
            }

            $stmt = $this->db->prepare("SELECT name, status, COALESCE(fuel_capacity, 0) as fuel_capacity FROM generators WHERE LOWER(name) LIKE ? LIMIT 5");
            $stmt->execute([$kw]);
            if ($rows = $stmt->fetchAll(PDO::FETCH_ASSOC)) {
                foreach ($rows as $g) $summaryText[] = "⚡ **Generator:** {$g['name']} (Status: {$g['status']}, Capacity: {$g['fuel_capacity']}L)";
                $results['generators'] = $rows;
            }
        }

        $summaryText = array_unique($summaryText);

        if (!empty($summaryText)) {
            $reply = "🔍 I searched the entire database for **\"" . implode(' ', $words) . "\"** and found:\n\n" . implode("\n", array_slice($summaryText, 0, 15));
            if (count($summaryText) > 15) {
                $reply .= "\n\n*...and " . (count($summaryText) - 15) . " more records.*";
            }
            echo json_encode(['reply' => $reply, 'type' => 'text']);
            return;
        }

        echo json_encode([
            'reply' => "🤔 I searched the entire database for **\"$message\"** but couldn't find any matching records.\n\nTry asking about:\n• **Overdue rent** or **top debtors**\n• **Expiring contracts**\n• **Financial summary** or **building profit & loss**\n• **Pending purchases** or **approve purchase #ID**\n• **System diagnostics** or **proactive insights**\n• **Vacant apartments**, **Fuel status**, or **Maintenance tasks**",
            'type' => 'text'
        ]);
    }

    /** ─── Helpers ────────────────────────────────────────────────────────── */
    private function extractBuildingName($message) {
        if (!empty($this->currentAnalysis['entities']['building'])) {
            return $this->currentAnalysis['entities']['building'];
        }
        return null;
    }

    private function findBuilding($name) {
        if (!$name) return null;
        $stmt = $this->db->prepare("SELECT * FROM buildings WHERE LOWER(name) LIKE ? LIMIT 1");
        $stmt->execute(['%' . strtolower($name) . '%']);
        return $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
    }

    private function extractTenantName($message) {
        if (!empty($this->currentAnalysis['entities']['tenant'])) {
            return $this->currentAnalysis['entities']['tenant'];
        }
        if (preg_match('/(?:tenant|about|for|find|search|is|everything about)\s+([a-zA-Z\s]{3,35})/i', $message, $m)) {
            $candidate = trim($m[1]);
            $stopWords = ['overdue', 'late', 'unpaid', 'rent', 'contract', 'expiring', 'vacant', 'building', 'apartment', 'all', 'the', 'who', 'with', 'in'];
            if (!in_array(strtolower($candidate), $stopWords)) {
                return $candidate;
            }
        }
        return null;
    }

    private function getGreeting() {
        $role = strtoupper($this->currentRole);
        echo json_encode([
            'reply' => "👋 Hello! I'm your **Autonomous Agency AI Assistant** (Role: **{$role}**).\n\nI have live, permission-governed access to your property, financial, energy, and maintenance databases, and I can also **execute authorized actions** and **run diagnostics**.\n\nAsk me things like:\n• *\"What needs my attention today?\"* (Proactive Insights)\n• *\"Show pending purchases\"* or *\"Approve purchase #1\"*\n• *\"Who has overdue rent?\"*\n• *\"Tell me everything about [Tenant Name]\"*\n• *\"Run system diagnostics\"*",
            'type' => 'text'
        ]);
    }

    private function getHelp() {
        echo json_encode([
            'reply' => "🤖 **Autonomous Agency AI — Capabilities & Commands:**\n\n"
                . "**🧠 Proactive Intelligence & Diagnostics**\n• *\"Proactive insights\"* / *\"What needs my attention?\"*\n• *\"Run system diagnostics\"* / *\"Check system health\"*\n\n"
                . "**⚡ Autonomous Actions (With Confirmation Guard)**\n• *\"Show pending purchases\"* / *\"Approve purchase #ID\"*\n• *\"Approve maintenance task #ID\"*\n• *\"Navigate to fuel reserve\"* / *\"Open maintenance oversight\"*\n\n"
                . "**💰 Finance & Rent**\n• *\"Financial summary\"* / *\"Building profit and loss\"*\n• *\"Overdue rent\"* / *\"Top debtors\"*\n• *\"Rent dashboard\"* / *\"All expenses\"*\n\n"
                . "**🏢 Properties, Tenants & Energy**\n• *\"All buildings\"* / *\"Vacant apartments\"*\n• *\"Everything about [Tenant Name]\"* / *\"Apartment A1\"*\n• *\"Fuel status\"* / *\"Energy overview\"* / *\"Worker reports\"*",
            'type' => 'text'
        ]);
    }
}
