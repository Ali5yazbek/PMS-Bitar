<?php
require_once __DIR__ . '/config.php';

try {
    $dsn = "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4";
    $db = new PDO($dsn, DB_USER, DB_PASS);
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $db->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);

    // Check if column exists
    $stmt = $db->query("SHOW COLUMNS FROM users LIKE 'username'");
    $exists = $stmt->fetch();

    if (!$exists) {
        // Add username column
        $db->exec("ALTER TABLE users ADD COLUMN username VARCHAR(100) NULL UNIQUE AFTER name");
        echo "Added username column.\n";
        
        // Populate existing users
        $stmt = $db->query("SELECT id, name, email FROM users");
        $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        $updateStmt = $db->prepare("UPDATE users SET username = ? WHERE id = ?");
        
        foreach ($users as $user) {
            // Generate a basic username from email or name
            if (!empty($user['email'])) {
                $username = explode('@', $user['email'])[0];
            } else {
                $username = strtolower(str_replace(' ', '_', $user['name'])) . $user['id'];
            }
            
            // Basic conflict resolution
            $checkStmt = $db->prepare("SELECT id FROM users WHERE username = ? AND id != ?");
            $suffix = '';
            $originalUsername = $username;
            
            while (true) {
                $checkStmt->execute([$username . $suffix, $user['id']]);
                if (!$checkStmt->fetch()) {
                    break;
                }
                $suffix = (int)$suffix + 1;
            }
            
            $finalUsername = $username . $suffix;
            $updateStmt->execute([$finalUsername, $user['id']]);
            echo "Updated user ID {$user['id']} with username {$finalUsername}\n";
        }
    } else {
        echo "Username column already exists.\n";
    }
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
