<?php
require_once __DIR__ . '/../core/Database.php';
require_once __DIR__ . '/../utils/PrivacyMasker.php';

class OperationsController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    private function getAuthUser() {
        $headers = getallheaders();
        $authHeader = $headers['Authorization'] ?? '';
        if (preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
            if (class_exists('JWT')) {
                return JWT::decode($matches[1]);
            }
        }
        return null;
    }

    private function getClientIP() {
        return $_SERVER['HTTP_CLIENT_IP'] ?? $_SERVER['HTTP_X_FORWARDED_FOR'] ?? $_SERVER['REMOTE_ADDR'] ?? 'Unknown';
    }

    private function getUserAgent() {
        return $_SERVER['HTTP_USER_AGENT'] ?? 'Unknown';
    }

    // 1. Session Ping (Hybrid Tracker)
    public function ping() {
        $user = $this->getAuthUser();
        if (!$user) {
            http_response_code(401);
            echo json_encode(["error" => "Unauthorized"]);
            return;
        }

        $input = json_decode(file_get_contents("php://input"), true) ?: [];
        $currentPage = $input['current_page'] ?? null;
        $currentAction = $input['current_action'] ?? null;
        $currentRecordId = $input['current_record_id'] ?? null;
        $editMode = $input['edit_mode'] ?? 'viewing';
        $changedFields = isset($input['changed_fields']) ? json_encode(PrivacyMasker::mask($input['changed_fields'])) : null;
        $unsaved = !empty($input['unsaved_changes']) ? 1 : 0;
        
        // Status calculation (online, idle, away, editing, viewing)
        // If editMode is editing and they are active, status is 'editing'
        // If input['status'] is passed explicitly (e.g. away, idle), use that
        $status = $input['status'] ?? ($editMode === 'editing' ? 'editing' : 'online');
        
        $userId = is_array($user) ? ($user['user_id'] ?? $user['id']) : (is_object($user) ? $user->id : null);
        if (!$userId) {
            echo json_encode(["status" => "error", "message" => "Invalid user"]);
            return;
        }

        $sessionToken = "auth_" . $userId; 
        $ip = $this->getClientIP();
        $ua = $this->getUserAgent();

        // 1. Update session
        $stmt = $this->db->prepare("
            INSERT INTO user_sessions (user_id, session_token, ip_address, user_agent, current_page, current_action, current_record_id, edit_mode, changed_fields, unsaved_changes, status, last_activity)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())
            ON DUPLICATE KEY UPDATE
            ip_address = VALUES(ip_address),
            user_agent = VALUES(user_agent),
            current_page = VALUES(current_page),
            current_action = VALUES(current_action),
            current_record_id = VALUES(current_record_id),
            edit_mode = VALUES(edit_mode),
            changed_fields = VALUES(changed_fields),
            unsaved_changes = VALUES(unsaved_changes),
            status = VALUES(status),
            last_activity = NOW()
        ");
        $stmt->execute([
            $userId, $sessionToken, $ip, $ua, $currentPage, $currentAction, 
            $currentRecordId, $editMode, $changedFields, $unsaved, $status
        ]);

        // 2. If it's a navigation or explicit action event, log it to enterprise_activity_log
        if (!empty($input['event_type']) && $input['event_type'] === 'navigation') {
            $uStmt = $this->db->prepare("SELECT name, role, 'General' as department FROM users WHERE id = ?");
            $uStmt->execute([$userId]);
            $u = $uStmt->fetch(PDO::FETCH_ASSOC);
            if ($u) {
                self::logActivity(
                    $userId, $u['name'], $u['role'], $u['department'],
                    'navigation', 'system', null, 'Opened ' . $currentAction
                );
            }
        }

        echo json_encode(["status" => "ok"]);
    }

    // 2. Get Live Activity Feed (Server Pagination across split tables)
    public function getLiveFeed() {
        $page = isset($_GET['page']) ? max(1, (int)$_GET['page']) : 1;
        $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 100;
        $offset = ($page - 1) * $limit;

        // Unified view of all activity
        $sql = "
            SELECT id, user_name, role, department, action, module, record_id, description, status, severity, ip_address, device_info, created_at, 'enterprise' as source_table FROM enterprise_activity_log
            UNION ALL
            SELECT id, user_name, role, NULL as department, action, 'security' as module, NULL as record_id, description, status, severity, ip_address, device_info, created_at, 'security' as source_table FROM security_activity_log
            UNION ALL
            SELECT id, user_name, role, NULL as department, action, module, record_id, description, status, 'low' as severity, NULL as ip_address, NULL as device_info, created_at, 'financial' as source_table FROM financial_activity_log
            UNION ALL
            SELECT id, user_name, NULL as role, NULL as department, action, 'system' as module, NULL as record_id, description, status, severity, NULL as ip_address, NULL as device_info, created_at, 'system' as source_table FROM system_activity_log
            ORDER BY created_at DESC
            LIMIT :limit OFFSET :offset
        ";

        $stmt = $this->db->prepare($sql);
        $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
        $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
        $stmt->execute();
        
        $feed = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode($feed);
    }

    // 3. Get Online Users (Enterprise Dashboard)
    public function getOnlineUsers() {
        $this->db->exec("UPDATE user_sessions SET status = 'idle' WHERE last_activity < DATE_SUB(NOW(), INTERVAL 5 MINUTE) AND status IN ('online', 'editing', 'viewing')");
        $this->db->exec("UPDATE user_sessions SET status = 'offline' WHERE last_activity < DATE_SUB(NOW(), INTERVAL 15 MINUTE) AND status != 'offline'");

        // Fetch Users & Sessions & Today's Work
        $stmt = $this->db->query("
            SELECT u.id as user_id, u.name as user_name, u.role, 'Property' as department, NULL as avatar,
            COALESCE(s.status, 'offline') as status, s.last_activity as login_time, s.current_page, s.current_action, s.current_record_id,
            (SELECT COUNT(*) FROM enterprise_activity_log WHERE user_id = u.id AND DATE(created_at) = CURDATE() AND action IN ('completed', 'created', 'approved')) as todays_work
            FROM users u
            LEFT JOIN user_sessions s ON u.id = s.user_id
            ORDER BY COALESCE(s.last_activity, '1970-01-01') DESC
        ");
        $usersRaw = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Fetch All Open Problems
        $reportStmt = $this->db->query("
            SELECT id, employee_id, table_name, field_name, description, severity, status, created_at 
            FROM audit_reports 
            WHERE status NOT IN ('resolved', 'rejected')
        ");
        $reports = $reportStmt->fetchAll(PDO::FETCH_ASSOC);

        // Group Reports by Employee
        $groupedReports = [];
        foreach ($reports as $r) {
            $eid = $r['employee_id'];
            if (!isset($groupedReports[$eid])) $groupedReports[$eid] = [];
            $groupedReports[$eid][] = $r;
        }

        $users = [];
        $role_summary = [];

        foreach ($usersRaw as $u) {
            $eid = $u['user_id'];
            $myReports = $groupedReports[$eid] ?? [];

            $total = count($myReports);
            $critical = 0;
            $warning = 0;
            $info = 0;
            $missing = 0;
            $expired = 0;
            $pending = 0;
            $overdue = 0; // We'll infer this if description has 'late' or 'overdue'

            $healthScore = 100;
            $topProblems = [];

            foreach ($myReports as $idx => $r) {
                // Determine severity
                if ($r['severity'] === 'critical') {
                    $critical++;
                    $healthScore -= 15;
                } elseif ($r['severity'] === 'warning') {
                    $warning++;
                    $healthScore -= 5;
                } else {
                    $info++;
                    $healthScore -= 2;
                }

                // Determine classification via text matching
                $desc = strtolower($r['description']);
                if (strpos($desc, 'missing') !== false || strpos($desc, 'not uploaded') !== false) {
                    $missing++;
                    if ($r['severity'] === 'critical') $healthScore -= 15; // Additional penalty for missing mandatory
                }
                if (strpos($desc, 'expired') !== false) {
                    $expired++;
                    $healthScore -= 20; // Additional penalty for expired
                }
                if (strpos($desc, 'late') !== false || strpos($desc, 'overdue') !== false) {
                    $overdue++;
                    $healthScore -= 10;
                }
                if ($r['status'] === 'pending_review') {
                    $pending++;
                }

                // Add to top problems
                if ($idx < 5) {
                    $topProblems[] = [
                        'module' => $r['table_name'],
                        'field' => $r['field_name'],
                        'description' => $r['description'],
                        'severity' => $r['severity']
                    ];
                }
            }

            $healthScore = max(0, $healthScore); // clamp at 0

            // Color Coding
            $healthColor = 'green';
            if ($healthScore < 50 || $total >= 8) $healthColor = 'red';
            elseif ($healthScore < 80 || $total >= 4) $healthColor = 'orange';
            elseif ($healthScore < 100 || $total >= 1) $healthColor = 'yellow';

            $u['total_problems'] = $total;
            $u['critical_problems'] = $critical;
            $u['warning_problems'] = $warning;
            $u['info_problems'] = $info;
            $u['missing_fields'] = $missing;
            $u['expired_documents'] = $expired;
            $u['pending_reviews'] = $pending;
            
            $u['health_score'] = $healthScore;
            $u['health_color'] = $healthColor;
            $u['top_problems'] = $topProblems;
            $u['error_count'] = $total;
            $u['id'] = $u['user_id'];

            // Build role summary dynamically
            $r = strtolower($u['role']);
            if (!isset($role_summary[$r])) $role_summary[$r] = 0;
            $role_summary[$r]++;

            $users[] = $u;
        }

        echo json_encode([
            "users" => $users,
            "role_summary" => $role_summary
        ]);
    }

    // 4. Session Timeline (Chronological Replay)
    public function getSessionTimeline($userId) {
        // Get all navigation and CRUD events for a specific user in the last 24h to form a timeline
        $stmt = $this->db->prepare("
            SELECT action, module, record_id, description, created_at
            FROM enterprise_activity_log
            WHERE user_id = ? AND created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
            ORDER BY created_at ASC
        ");
        $stmt->execute([$userId]);
        $timeline = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode($timeline);
    }

    // 5. Get Productivity Analytics
    public function getProductivity() {
        $stmt = $this->db->query("
            SELECT 
                user_id, user_name, role, department,
                SUM(CASE WHEN action = 'completed' OR action = 'approved' THEN 1 ELSE 0 END) as tasks_completed,
                SUM(CASE WHEN action = 'created' AND module = 'reports' THEN 1 ELSE 0 END) as reports_submitted,
                SUM(CASE WHEN status = 'error' OR status = 'warning' THEN 1 ELSE 0 END) as problems,
                COUNT(*) as total_actions
            FROM enterprise_activity_log
            WHERE DATE(created_at) = CURDATE() AND user_id IS NOT NULL
            GROUP BY user_id, user_name, role, department
            ORDER BY total_actions DESC
            LIMIT 20
        ");
        $leaderboard = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $stmt2 = $this->db->query("
            SELECT 
                COUNT(*) as total_events,
                SUM(CASE WHEN action IN ('created', 'added') THEN 1 ELSE 0 END) as records_created,
                SUM(CASE WHEN action IN ('edited', 'updated') THEN 1 ELSE 0 END) as records_edited,
                SUM(CASE WHEN action = 'deleted' THEN 1 ELSE 0 END) as records_deleted
            FROM enterprise_activity_log
            WHERE DATE(created_at) = CURDATE()
        ");
        $summary = $stmt2->fetch(PDO::FETCH_ASSOC);

        echo json_encode(["leaderboard" => $leaderboard, "summary" => $summary]);
    }

    // 6. Security Detections
    public function getSecurity() {
        // Mass Deletions
        $stmtDeletes = $this->db->query("
            SELECT user_name, COUNT(*) as delete_count, MAX(created_at) as last_delete
            FROM enterprise_activity_log
            WHERE action = 'deleted' AND created_at >= DATE_SUB(NOW(), INTERVAL 10 MINUTE)
            GROUP BY user_name
            HAVING delete_count >= 5
        ");
        $massDeletes = $stmtDeletes->fetchAll(PDO::FETCH_ASSOC);

        // Large Exports
        $stmtExports = $this->db->query("
            SELECT user_name, module, COUNT(*) as export_count, MAX(created_at) as last_export
            FROM enterprise_activity_log
            WHERE action = 'exported' AND created_at >= DATE_SUB(NOW(), INTERVAL 60 MINUTE)
            GROUP BY user_name, module
            HAVING export_count >= 2
        ");
        $largeExports = $stmtExports->fetchAll(PDO::FETCH_ASSOC);

        // Recent Security Logs
        $stmtEvents = $this->db->query("SELECT * FROM security_activity_log ORDER BY created_at DESC LIMIT 20");
        $events = $stmtEvents->fetchAll(PDO::FETCH_ASSOC);

        echo json_encode([
            "mass_deletes" => $massDeletes,
            "large_exports" => $largeExports,
            "events" => $events
        ]);
    }

    // 7. Analytics
    public function getAnalytics() {
        $stmtHourly = $this->db->query("
            SELECT HOUR(created_at) as hour, COUNT(*) as event_count
            FROM enterprise_activity_log
            WHERE created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
            GROUP BY HOUR(created_at)
            ORDER BY created_at ASC
        ");
        $hourly = $stmtHourly->fetchAll(PDO::FETCH_ASSOC);

        $stmtModules = $this->db->query("
            SELECT module, COUNT(*) as event_count
            FROM enterprise_activity_log
            WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
            GROUP BY module
            ORDER BY event_count DESC
            LIMIT 10
        ");
        $modules = $stmtModules->fetchAll(PDO::FETCH_ASSOC);

        echo json_encode([
            "hourly_activity" => $hourly,
            "top_modules" => $modules
        ]);
    }

    public function mobileMonitoring() {
        AuthMiddleware::requireLogin();
        
        $agents = [
            [
                'id' => 1,
                'name' => 'Agent Ali Yazbek',
                'role' => 'agent',
                'status' => 'Online',
                'lastSync' => 'Just now',
                'pendingQueue' => 0,
                'battery' => 92,
                'appVersion' => '2.1.0',
                'completedToday' => 8,
                'rejectedToday' => 0,
                'accuracyScore' => '98.5%',
                'currentBuilding' => 'Galaxy Building'
            ]
        ];

        $maint = [
            [
                'id' => 2,
                'name' => 'Tech Hassan',
                'role' => 'maintenance',
                'status' => 'Online',
                'lastSync' => '2 mins ago',
                'pendingQueue' => 1,
                'battery' => 74,
                'appVersion' => '2.1.0',
                'completedToday' => 3,
                'rejectedToday' => 0,
                'accuracyScore' => '100%',
                'currentBuilding' => 'Bitar Tower'
            ]
        ];

        echo json_encode([
            'agents' => $agents,
            'maintenance' => $maint,
            'activeCount' => count($agents) + count($maint),
            'systemHealth' => '100%'
        ]);
    }

    // Global Activity Logger helper
    public static function logActivity($userId, $userName, $role, $department, $action, $module, $recordId, $description, $status = 'success') {
        $db = Database::getInstance()->getConnection();
        $ip = $_SERVER['HTTP_CLIENT_IP'] ?? $_SERVER['HTTP_X_FORWARDED_FOR'] ?? $_SERVER['REMOTE_ADDR'] ?? 'Unknown';
        $ua = $_SERVER['HTTP_USER_AGENT'] ?? 'Unknown';
        
        // Apply privacy masking to description
        $description = PrivacyMasker::mask($description);

        $stmt = $db->prepare("
            INSERT INTO enterprise_activity_log 
            (user_id, user_name, role, department, action, module, record_id, description, status, ip_address, device_info)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ");
        $stmt->execute([
            $userId, $userName, $role, $department, 
            $action, $module, $recordId, $description, 
            $status, $ip, $ua
        ]);
    }
}
