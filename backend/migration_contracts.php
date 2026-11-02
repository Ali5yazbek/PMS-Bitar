<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/core/Database.php';

try {
    $db = Database::getInstance()->getConnection();

    // Check if rent_start_date already exists
    $stmt = $db->query("SHOW COLUMNS FROM contracts LIKE 'rent_start_date'");
    $exists = $stmt->fetch();

    if (!$exists) {
        echo "Adding rent_start_date and rent_end_date columns to contracts table...\n";
        
        $sql = "ALTER TABLE contracts 
                ADD COLUMN rent_start_date DATE NULL AFTER end_date,
                ADD COLUMN rent_end_date DATE NULL AFTER rent_start_date";
                
        $db->exec($sql);
        echo "Columns added.\n";

        echo "Migrating existing dates...\n";
        $db->exec("UPDATE contracts SET rent_start_date = start_date, rent_end_date = end_date WHERE rent_start_date IS NULL");
        echo "Migration completed successfully.\n";
    } else {
        echo "Columns already exist.\n";
    }

} catch (Exception $e) {
    echo "Migration failed: " . $e->getMessage() . "\n";
}
