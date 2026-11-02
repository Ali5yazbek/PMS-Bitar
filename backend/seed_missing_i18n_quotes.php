<?php
require_once __DIR__ . '/core/Database.php';
$db = Database::getInstance()->getConnection();
$translations = [
  "TODAY'S COMMAND" => ["fr" => "COMMANDES DU JOUR", "ar" => "أوامر اليوم"],
  "TODAY'S TASKS & ALERTS" => ["fr" => "TÂCHES ET ALERTES DU JOUR", "ar" => "مهام وتنبيهات اليوم"],
  "No alerts in this category. You're all caught up!" => ["fr" => "Aucune alerte dans cette catégorie. Vous êtes à jour !", "ar" => "لا توجد تنبيهات في هذه الفئة. أنت على اطلاع دائم!"]
];

try {
    $db->beginTransaction();
    foreach ($translations as $key => $langs) {
        foreach ($langs as $langCode => $val) {
            $stmt = $db->prepare("
                INSERT INTO translations (translation_key, lang_code, translated_value)
                VALUES (?, ?, ?)
                ON DUPLICATE KEY UPDATE translated_value = VALUES(translated_value)
            ");
            $stmt->execute([$key, $langCode, $val]);
        }
    }
    $db->commit();
    echo "Translations inserted successfully!\n";
} catch (Exception $e) {
    $db->rollBack();
    echo "Error: " . $e->getMessage() . "\n";
}
