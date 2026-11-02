<?php
// backend/migrations/migrate_translations_and_tenant_users.php
require_once __DIR__ . '/../config.php';
require_once __DIR__ . '/../core/Database.php';

$db = Database::getInstance()->getConnection();

echo "1. Creating translations table if not exists...\n";
$db->exec("
    CREATE TABLE IF NOT EXISTS translations (
        id INT AUTO_INCREMENT PRIMARY KEY,
        translation_key VARCHAR(255) NOT NULL,
        lang_code VARCHAR(10) NOT NULL,
        translated_value TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        UNIQUE KEY uq_key_lang (translation_key, lang_code)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
");
echo "   Translations table ready.\n";

echo "2. Seeding initial translations...\n";
$initialTranslations = [
    "TODAY'S COMMAND" => ["fr" => "COMMANDES DU JOUR", "ar" => "أوامر اليوم"],
    "TODAY'S TASKS & ALERTS" => ["fr" => "TÂCHES ET ALERTES DU JOUR", "ar" => "مهام وتنبيهات اليوم"],
    "No alerts in this category. You're all caught up!" => ["fr" => "Aucune alerte dans cette catégorie. Vous êtes à jour !", "ar" => "لا توجد تنبيهات في هذه الفئة. أنت على اطلاع دائم!"]
];

$ins = $db->prepare("
    INSERT INTO translations (translation_key, lang_code, translated_value)
    VALUES (?, ?, ?)
    ON DUPLICATE KEY UPDATE translated_value = VALUES(translated_value)
");
foreach ($initialTranslations as $k => $langs) {
    foreach ($langs as $lang => $v) {
        $ins->execute([$k, $lang, $v]);
    }
}
echo "   Translations seeded.\n";

echo "3. Updating tenant_documents table schema...\n";
try {
    $db->exec("ALTER TABLE tenant_documents MODIFY COLUMN user_id INT NULL");
} catch (Exception $e) {}
try {
    $db->exec("ALTER TABLE tenant_documents MODIFY COLUMN tenant_id INT NULL");
} catch (Exception $e) {}
echo "   tenant_documents columns are nullable.\n";

echo "4. Linking missing user_id for tenants...\n";
$stmt = $db->query("SELECT id, full_name, email, phone, national_id FROM tenants WHERE user_id IS NULL");
$tenants = $stmt->fetchAll(PDO::FETCH_ASSOC);

foreach ($tenants as $t) {
    $tid = $t['id'];
    $cleanName = strtolower(preg_replace('/[^a-zA-Z0-9]/', '', $t['full_name']));
    $username = $cleanName ?: 'tenant_' . $tid;
    $email = $t['email'] ?: ($username . '@bitar.local');
    
    // Check if user already exists
    $chk = $db->prepare("SELECT id FROM users WHERE email = ? OR username = ? LIMIT 1");
    $chk->execute([$email, $username]);
    $existingUserId = $chk->fetchColumn();
    
    if (!$existingUserId) {
        $uIns = $db->prepare("
            INSERT INTO users (name, username, email, password, role, phone, national_id)
            VALUES (?, ?, ?, ?, 'tenant', ?, ?)
        ");
        $uIns->execute([
            $t['full_name'],
            $username . '_' . $tid,
            $email,
            password_hash('password123', PASSWORD_DEFAULT),
            $t['phone'],
            $t['national_id']
        ]);
        $existingUserId = (int)$db->lastInsertId();
    }
    
    $updT = $db->prepare("UPDATE tenants SET user_id = ? WHERE id = ?");
    $updT->execute([$existingUserId, $tid]);
    echo "   Linked Tenant #$tid ({$t['full_name']}) -> User #$existingUserId ($email)\n";
}

echo "Migration completed successfully!\n";
