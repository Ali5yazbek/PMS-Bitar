<?php
require 'core/Database.php';
try {
    $db = Database::getInstance()->getConnection();
    // Update the ID of the generator from 11 to 1
    $stmt = $db->exec("UPDATE generators SET id = 1 WHERE id = 11");
    if ($stmt) {
        echo "Successfully changed ID 11 to 1!";
    } else {
        echo "No rows affected or query failed.";
    }
} catch (PDOException $e) {
    echo "Error: " . $e->getMessage();
}
