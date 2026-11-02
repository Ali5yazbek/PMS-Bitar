<?php
class AuditController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function index() {
        AuthMiddleware::requireLogin();
        
        $stmt = $this->db->query("
            SELECT a.*, u.name as user_name 
            FROM audit_logs a
            JOIN users u ON a.user_id = u.id
            ORDER BY a.created_at DESC
            LIMIT 500
        ");
        
        echo json_encode($stmt->fetchAll());
    }
    public function getSalesAudits($invoiceId) {
        AuthMiddleware::requireLogin();
        
        $stmt = $this->db->prepare("
            SELECT a.*, u.username as user_name 
            FROM sales_audits a
            LEFT JOIN users u ON a.user_id = u.id
            WHERE a.invoice_id = ?
            ORDER BY a.created_at DESC
        ");
        $stmt->execute([$invoiceId]);
        
        echo json_encode($stmt->fetchAll());
    }
}
