<?php
/**
 * PermissionController — full CRUD for the Enterprise Permission Center.
 * Handles: page, button, field, menu permissions, building/department restrictions,
 * temporary permissions, and the full role matrix.
 */
class PermissionController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    // ── GET /api/permissions/global-menus ─────────────────────────────────────
    public function globalMenus() {
        AuthMiddleware::requireLogin();
        $stmt = $this->db->query("SELECT * FROM global_menus ORDER BY sort_order");
        echo json_encode($stmt->fetchAll());
    }

    // ── POST /api/permissions/global-menus/reorder ────────────────────────────
    public function updateGlobalMenus() {
        AuthMiddleware::requireAdmin();
        $body = json_decode(file_get_contents('php://input'), true);
        $stmt = $this->db->prepare("UPDATE global_menus SET parent_key = ?, sort_order = ? WHERE id = ?");
        $this->db->beginTransaction();
        foreach ($body as $item) {
            $stmt->execute([$item['parent_key'], $item['sort_order'], $item['id']]);
        }
        $this->db->commit();
        echo json_encode(['success' => true]);
    }

    // ── POST /api/permissions/global-menus ────────────────────────────────────
    public function createGlobalMenu() {
        AuthMiddleware::requireAdmin();
        $body = json_decode(file_get_contents('php://input'), true);
        $stmt = $this->db->prepare("
            INSERT INTO global_menus (menu_key, label, path, icon, parent_key, sort_order, is_custom)
            VALUES (?, ?, ?, ?, ?, ?, 1)
        ");
        $stmt->execute([
            $body['menu_key'], $body['label'], $body['path'], 
            $body['icon'] ?? 'FileText', $body['parent_key'] ?? null, 
            (int)($body['sort_order'] ?? 0)
        ]);
        echo json_encode(['success' => true, 'id' => $this->db->lastInsertId()]);
    }

    // ── DELETE /api/permissions/global-menus/{id} ─────────────────────────────
    public function deleteGlobalMenu($id) {
        AuthMiddleware::requireAdmin();
        $stmt = $this->db->prepare("DELETE FROM global_menus WHERE id = ? AND is_custom = 1");
        $stmt->execute([$id]);
        echo json_encode(['success' => true]);
    }

    // ── GET /api/permissions/my-permissions ───────────────────────────────────
    // Returns the current user's effective permissions (used by frontend)
    public function myPermissions() {
        $currentUser = AuthMiddleware::requireLogin();
        $role = $currentUser['role'];
        $userId = $currentUser['user_id'];

        $pages = $this->db->prepare("SELECT * FROM page_permissions WHERE role = ?");
        $pages->execute([$role]);

        $menu = $this->db->prepare("SELECT * FROM menu_permissions WHERE role = ?");
        $menu->execute([$role]);

        $fields = $this->db->prepare("SELECT * FROM field_permissions WHERE role = ?");
        $fields->execute([$role]);

        $buttons = $this->db->prepare("SELECT * FROM button_permissions WHERE role = ?");
        $buttons->execute([$role]);

        // Temp permissions
        $temp = $this->db->prepare("
            SELECT * FROM temp_permissions
            WHERE user_id = ? AND is_active = 1 AND expires_at > NOW()
        ");
        $temp->execute([$userId]);

        // Building restrictions
        $buildings = $this->db->prepare("SELECT building_id FROM building_restrictions WHERE user_id = ? AND can_access = 1");
        $buildings->execute([$userId]);

        echo json_encode([
            'role'                => $role,
            'pages'               => $pages->fetchAll(),
            'menu'                => $menu->fetchAll(),
            'fields'              => $fields->fetchAll(),
            'buttons'             => $buttons->fetchAll(),
            'temp_permissions'    => $temp->fetchAll(),
            'allowed_buildings'   => array_column($buildings->fetchAll(), 'building_id'),
        ]);
    }

    // ── GET /api/permissions/matrix ───────────────────────────────────────────
    // Full role × page permission matrix
    public function matrix() {
        AuthMiddleware::requireAdmin();
        $stmt = $this->db->query("
            SELECT role, page_key, can_view, can_add, can_edit, can_delete,
                   can_print, can_export, can_approve
            FROM page_permissions
            ORDER BY page_key, role
        ");
        echo json_encode($stmt->fetchAll());
    }

    // ── GET /api/permissions/pages ────────────────────────────────────────────
    public function pages() {
        AuthMiddleware::requireAdmin();
        $role = $_GET['role'] ?? null;
        if ($role) {
            $stmt = $this->db->prepare("SELECT * FROM page_permissions WHERE role = ? ORDER BY page_key");
            $stmt->execute([$role]);
        } else {
            $stmt = $this->db->query("SELECT * FROM page_permissions ORDER BY page_key, role");
        }
        echo json_encode($stmt->fetchAll());
    }

    // ── PUT /api/permissions/pages ────────────────────────────────────────────
    public function updatePages() {
        $admin = AuthMiddleware::requireAdmin();
        $body = json_decode(file_get_contents('php://input'), true);
        // body = [{ role, page_key, can_view, can_add, can_edit, can_delete, can_print, can_export, can_approve }]
        $stmt = $this->db->prepare("
            INSERT INTO page_permissions (role, page_key, can_view, can_add, can_edit, can_delete, can_print, can_export, can_approve)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
                can_view=VALUES(can_view), can_add=VALUES(can_add), can_edit=VALUES(can_edit),
                can_delete=VALUES(can_delete), can_print=VALUES(can_print),
                can_export=VALUES(can_export), can_approve=VALUES(can_approve)
        ");
        $this->db->beginTransaction();
        foreach ($body as $p) {
            $stmt->execute([
                $p['role'], $p['page_key'],
                (int)($p['can_view'] ?? 0), (int)($p['can_add'] ?? 0),
                (int)($p['can_edit'] ?? 0), (int)($p['can_delete'] ?? 0),
                (int)($p['can_print'] ?? 0), (int)($p['can_export'] ?? 0),
                (int)($p['can_approve'] ?? 0)
            ]);
        }
        $this->db->commit();
        $this->logSecurityEvent($admin['user_id'], 'permission_update', 'info',
            'Updated page permissions for role: ' . ($body[0]['role'] ?? 'unknown'));
        echo json_encode(['success' => true]);
    }

    // ── GET /api/permissions/buttons ──────────────────────────────────────────
    public function buttons() {
        AuthMiddleware::requireAdmin();
        $role = $_GET['role'] ?? null;
        $page = $_GET['page'] ?? null;
        $where = ['1=1']; $params = [];
        if ($role) { $where[] = 'role = ?'; $params[] = $role; }
        if ($page) { $where[] = 'page_key = ?'; $params[] = $page; }
        $stmt = $this->db->prepare("SELECT * FROM button_permissions WHERE " . implode(' AND ', $where) . " ORDER BY page_key, button_key");
        $stmt->execute($params);
        echo json_encode($stmt->fetchAll());
    }

    // ── PUT /api/permissions/buttons ──────────────────────────────────────────
    public function updateButtons() {
        AuthMiddleware::requireAdmin();
        $body = json_decode(file_get_contents('php://input'), true);
        $stmt = $this->db->prepare("
            INSERT INTO button_permissions (role, page_key, button_key, button_label, is_visible, is_enabled)
            VALUES (?, ?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
                button_label=VALUES(button_label), is_visible=VALUES(is_visible), is_enabled=VALUES(is_enabled)
        ");
        $this->db->beginTransaction();
        foreach ($body as $b) {
            $stmt->execute([$b['role'], $b['page_key'], $b['button_key'],
                $b['button_label'] ?? '', (int)($b['is_visible'] ?? 0), (int)($b['is_enabled'] ?? 0)]);
        }
        $this->db->commit();
        echo json_encode(['success' => true]);
    }

    // ── GET /api/permissions/fields ───────────────────────────────────────────
    public function fields() {
        AuthMiddleware::requireAdmin();
        $role   = $_GET['role']   ?? null;
        $entity = $_GET['entity'] ?? null;
        $where = ['1=1']; $params = [];
        if ($role)   { $where[] = 'role = ?';   $params[] = $role; }
        if ($entity) { $where[] = 'entity = ?'; $params[] = $entity; }
        $stmt = $this->db->prepare("SELECT * FROM field_permissions WHERE " . implode(' AND ', $where) . " ORDER BY entity, field_name");
        $stmt->execute($params);
        echo json_encode($stmt->fetchAll());
    }

    // ── PUT /api/permissions/fields ───────────────────────────────────────────
    public function updateFields() {
        AuthMiddleware::requireAdmin();
        $body = json_decode(file_get_contents('php://input'), true);
        $stmt = $this->db->prepare("
            INSERT INTO field_permissions (role, entity, field_name, field_label, is_visible, is_editable)
            VALUES (?, ?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
                field_label=VALUES(field_label), is_visible=VALUES(is_visible), is_editable=VALUES(is_editable)
        ");
        $this->db->beginTransaction();
        foreach ($body as $f) {
            $stmt->execute([$f['role'], $f['entity'], $f['field_name'],
                $f['field_label'] ?? '', (int)($f['is_visible'] ?? 0), (int)($f['is_editable'] ?? 0)]);
        }
        $this->db->commit();
        echo json_encode(['success' => true]);
    }

    // ── GET /api/permissions/menu ─────────────────────────────────────────────
    public function menu() {
        AuthMiddleware::requireAdmin();
        $role = $_GET['role'] ?? null;
        if ($role) {
            $stmt = $this->db->prepare("SELECT * FROM menu_permissions WHERE role = ? ORDER BY sort_order");
            $stmt->execute([$role]);
        } else {
            $stmt = $this->db->query("SELECT * FROM menu_permissions ORDER BY role, sort_order");
        }
        echo json_encode($stmt->fetchAll());
    }

    // ── PUT /api/permissions/menu ─────────────────────────────────────────────
    public function updateMenu() {
        AuthMiddleware::requireAdmin();
        $body = json_decode(file_get_contents('php://input'), true);
        $stmt = $this->db->prepare("
            INSERT INTO menu_permissions (role, menu_key, menu_label, is_visible, sort_order)
            VALUES (?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE menu_label=VALUES(menu_label), is_visible=VALUES(is_visible)
        ");
        $this->db->beginTransaction();
        foreach ($body as $m) {
            $stmt->execute([$m['role'], $m['menu_key'], $m['menu_label'] ?? '',
                (int)($m['is_visible'] ?? 0), (int)($m['sort_order'] ?? 0)]);
        }
        $this->db->commit();
        echo json_encode(['success' => true]);
    }

    // ── GET /api/permissions/buildings ────────────────────────────────────────
    public function buildingRestrictions() {
        AuthMiddleware::requireAdmin();
        $userId = $_GET['user_id'] ?? null;
        if ($userId) {
            $stmt = $this->db->prepare("
                SELECT br.*, b.name as building_name
                FROM building_restrictions br
                JOIN buildings b ON br.building_id = b.id
                WHERE br.user_id = ?
            ");
            $stmt->execute([$userId]);
        } else {
            $stmt = $this->db->query("
                SELECT br.*, b.name as building_name, u.name as user_name
                FROM building_restrictions br
                JOIN buildings b ON br.building_id = b.id
                JOIN users u ON br.user_id = u.id
            ");
        }
        echo json_encode($stmt->fetchAll());
    }

    // ── PUT /api/permissions/buildings ────────────────────────────────────────
    public function updateBuildingRestrictions() {
        $admin = AuthMiddleware::requireAdmin();
        $body = json_decode(file_get_contents('php://input'), true);
        // Delete existing for this user, then re-insert
        $userId = $body['user_id'];
        $this->db->prepare("DELETE FROM building_restrictions WHERE user_id = ?")->execute([$userId]);
        $stmt = $this->db->prepare("INSERT INTO building_restrictions (user_id, building_id, can_access, granted_by) VALUES (?, ?, ?, ?)");
        foreach ($body['buildings'] as $bld) {
            $stmt->execute([$userId, $bld['building_id'], (int)($bld['can_access'] ?? 1), $admin['user_id']]);
        }
        echo json_encode(['success' => true]);
    }

    // ── GET /api/permissions/temp ─────────────────────────────────────────────
    public function tempPermissions() {
        AuthMiddleware::requireAdmin();
        $stmt = $this->db->query("
            SELECT tp.*, u.name as user_name, g.name as granted_by_name
            FROM temp_permissions tp
            JOIN users u ON tp.user_id = u.id
            JOIN users g ON tp.granted_by = g.id
            ORDER BY tp.created_at DESC
            LIMIT 100
        ");
        echo json_encode($stmt->fetchAll());
    }

    // ── POST /api/permissions/temp ────────────────────────────────────────────
    public function grantTemp() {
        $admin = AuthMiddleware::requireAdmin();
        $body = json_decode(file_get_contents('php://input'), true);
        $stmt = $this->db->prepare("
            INSERT INTO temp_permissions (user_id, granted_by, permission_type, target_table, target_id, expires_at, reason)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ");
        $stmt->execute([
            $body['user_id'], $admin['user_id'],
            $body['permission_type'], $body['target_table'] ?? null, $body['target_id'] ?? null,
            $body['expires_at'], $body['reason'] ?? ''
        ]);
        $this->logSecurityEvent($admin['user_id'], 'temp_permission_granted', 'warning',
            'Temp permission granted: ' . $body['permission_type'] . ' to user ' . $body['user_id']);
        echo json_encode(['success' => true, 'id' => $this->db->lastInsertId()]);
    }

    // ── DELETE /api/permissions/temp/{id} ─────────────────────────────────────
    public function revokeTemp($id) {
        AuthMiddleware::requireAdmin();
        $this->db->prepare("UPDATE temp_permissions SET is_active = 0 WHERE id = ?")->execute([$id]);
        echo json_encode(['success' => true]);
    }

    // ── GET /api/permissions/users-with-restrictions ──────────────────────────
    public function usersWithRestrictions() {
        AuthMiddleware::requireAdmin();
        $stmt = $this->db->query("
            SELECT u.id, u.name, u.role, u.email,
                   COUNT(br.id) as building_restriction_count,
                   COUNT(tp.id) as active_temp_permissions
            FROM users u
            LEFT JOIN building_restrictions br ON u.id = br.user_id
            LEFT JOIN temp_permissions tp ON u.id = tp.user_id AND tp.is_active = 1 AND tp.expires_at > NOW()
            GROUP BY u.id
            ORDER BY u.name
        ");
        echo json_encode($stmt->fetchAll());
    }

    // ── Helper ────────────────────────────────────────────────────────────────
    private function logSecurityEvent(int $userId, string $type, string $severity, string $desc): void {
        try {
            $stmt = $this->db->prepare("
                INSERT INTO security_events (user_id, event_type, severity, description, ip_address)
                VALUES (?, ?, ?, ?, ?)
            ");
            $stmt->execute([$userId, $type, $severity, $desc, $_SERVER['REMOTE_ADDR'] ?? null]);
        } catch (Exception $e) { /* non-fatal */ }
    }
}
