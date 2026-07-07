<?php
require_once __DIR__ . '/backend/core/Database.php';
try {
    $db = Database::getInstance()->getConnection();
    $db->exec("ALTER TABLE inventory_items ADD COLUMN is_construction_material BOOLEAN DEFAULT FALSE");
    echo "Done";
} catch (Exception $e) {}
