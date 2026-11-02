<?php
class SearchController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function globalSearch() {
        AuthMiddleware::requireLogin();
        $query = trim($_GET['q'] ?? '');

        if (strlen($query) < 1) {
            echo json_encode([]);
            return;
        }

        $queryWildcard = "%" . $query . "%";
        $results = [];

        // 1. Tenants (Name, Phone, Email)
        try {
            $stmt = $this->db->prepare("
                SELECT t.id, t.full_name as title,
                       CONCAT('Phone: ', COALESCE(t.phone, 'N/A')) as subtitle,
                       'Tenant' as type, CONCAT('/tenants/', t.id) as path
                FROM tenants t
                WHERE t.full_name LIKE ? OR t.phone LIKE ? OR t.email LIKE ?
                LIMIT 8
            ");
            $stmt->execute([$queryWildcard, $queryWildcard, $queryWildcard]);
            $results = array_merge($results, $stmt->fetchAll(PDO::FETCH_ASSOC));
        } catch (\Throwable $e) {}

        // 2. Apartments (Code, Building Name)
        try {
            $stmt = $this->db->prepare("
                SELECT a.id, CONCAT(b.name, ' - Apt ', a.code) as title,
                       CONCAT(a.status, ' • CFA ', FORMAT(COALESCE(a.monthly_rent, 0), 0)) as subtitle,
                       'Apartment' as type, CONCAT('/buildings/', a.building_id) as path
                FROM apartments a
                JOIN buildings b ON a.building_id = b.id
                WHERE a.code LIKE ? OR b.name LIKE ?
                LIMIT 8
            ");
            $stmt->execute([$queryWildcard, $queryWildcard]);
            $results = array_merge($results, $stmt->fetchAll(PDO::FETCH_ASSOC));
        } catch (\Throwable $e) {}

        // 3. Buildings
        try {
            $stmt = $this->db->prepare("
                SELECT id, name as title, COALESCE(location, 'Property') as subtitle,
                       'Building' as type, CONCAT('/buildings/', id) as path
                FROM buildings
                WHERE name LIKE ? OR location LIKE ?
                LIMIT 5
            ");
            $stmt->execute([$queryWildcard, $queryWildcard]);
            $results = array_merge($results, $stmt->fetchAll(PDO::FETCH_ASSOC));
        } catch (\Throwable $e) {}

        // 4. Contracts
        try {
            $stmt = $this->db->prepare("
                SELECT c.id, CONCAT(t.full_name, ' (', b.name, ' Apt ', a.code, ')') as title,
                       CONCAT('Contract • ', c.status, ' • Ends ', COALESCE(c.end_date, 'N/A')) as subtitle,
                       'Contract' as type, '/contracts' as path
                FROM contracts c
                JOIN tenants t ON c.tenant_id = t.id
                JOIN apartments a ON c.apartment_id = a.id
                JOIN buildings b ON a.building_id = b.id
                WHERE t.full_name LIKE ? OR a.code LIKE ? OR b.name LIKE ?
                LIMIT 5
            ");
            $stmt->execute([$queryWildcard, $queryWildcard, $queryWildcard]);
            $results = array_merge($results, $stmt->fetchAll(PDO::FETCH_ASSOC));
        } catch (\Throwable $e) {}

        // 5. Suppliers
        try {
            $stmt = $this->db->prepare("
                SELECT id, company_name as title, COALESCE(phone, contact_name, 'Supplier') as subtitle,
                       'Supplier' as type, '/warehouse' as path
                FROM suppliers
                WHERE company_name LIKE ? OR contact_name LIKE ? OR phone LIKE ?
                LIMIT 5
            ");
            $stmt->execute([$queryWildcard, $queryWildcard, $queryWildcard]);
            $results = array_merge($results, $stmt->fetchAll(PDO::FETCH_ASSOC));
        } catch (\Throwable $e) {}

        // 6. Users
        try {
            $stmt = $this->db->prepare("
                SELECT id, name as title, UPPER(COALESCE(role, 'User')) as subtitle,
                       'User' as type, '/user-management' as path
                FROM users
                WHERE name LIKE ? OR email LIKE ?
                LIMIT 5
            ");
            $stmt->execute([$queryWildcard, $queryWildcard]);
            $results = array_merge($results, $stmt->fetchAll(PDO::FETCH_ASSOC));
        } catch (\Throwable $e) {}

        echo json_encode(array_slice($results, 0, 25));
    }
}
