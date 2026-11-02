<?php
class TranslationsController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    public function index() {
        $formatted = [
            'en' => [],
            'fr' => [],
            'ar' => []
        ];
        try {
            $stmt = $this->db->query("SELECT * FROM translations");
            $translations = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            foreach ($translations as $t) {
                if (isset($formatted[$t['lang_code']])) {
                    $keys = explode('.', $t['translation_key']);
                    $ref = &$formatted[$t['lang_code']];
                    foreach ($keys as $i => $k) {
                        if ($i === count($keys) - 1) {
                            $ref[$k] = $t['translated_value'];
                        } else {
                            if (!isset($ref[$k]) || !is_array($ref[$k])) {
                                $ref[$k] = [];
                            }
                            $ref = &$ref[$k];
                        }
                    }
                }
            }
            echo json_encode($formatted);
        } catch (Throwable $e) {
            error_log("Translations index error: " . $e->getMessage());
            echo json_encode($formatted);
        }
    }

    public function store() {
        AuthMiddleware::requireLogin();
        // Check if admin
        $headers = getallheaders();
        $authHeader = isset($headers['Authorization']) ? $headers['Authorization'] : '';
        if ($authHeader) {
            $token = str_replace('Bearer ', '', $authHeader);
            $decoded = JWT::decode($token);
            if ($decoded && isset($decoded['role']) && $decoded['role'] !== 'admin') {
                http_response_code(403);
                echo json_encode(['error' => 'Forbidden']);
                exit();
            }
        }
        
        try {
            $data = json_decode(file_get_contents("php://input"), true);
            $key = $data['translation_key'];
            
            $this->db->beginTransaction();
            foreach (['en', 'fr', 'ar'] as $lang) {
                if (isset($data[$lang])) {
                    $stmt = $this->db->prepare("
                        INSERT INTO translations (translation_key, lang_code, translated_value)
                        VALUES (?, ?, ?)
                        ON DUPLICATE KEY UPDATE translated_value = VALUES(translated_value)
                    ");
                    $stmt->execute([$key, $lang, $data[$lang]]);
                }
            }
            $this->db->commit();
            echo json_encode(['message' => 'Translation saved']);
        } catch (PDOException $e) {
            $this->db->rollBack();
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }

    public function destroy() {
        AuthMiddleware::requireLogin();
        $data = json_decode(file_get_contents("php://input"), true);
        $key = $data['translation_key'];
        
        try {
            $stmt = $this->db->prepare("DELETE FROM translations WHERE translation_key = ?");
            $stmt->execute([$key]);
            echo json_encode(['message' => 'Deleted']);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
    }
}
