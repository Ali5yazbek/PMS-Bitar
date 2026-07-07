<?php
require 'backend/config.php';
require 'backend/core/Database.php';

$db = Database::getInstance()->getConnection();

// Add rent_status
try { $db->exec("ALTER TABLE contracts ADD COLUMN rent_status ENUM('Active', 'Paused', 'Ended') DEFAULT 'Active' AFTER status"); } catch(Exception $e) {}
// Add insurance_status
try { $db->exec("ALTER TABLE contracts ADD COLUMN insurance_status ENUM('Pending Payment', 'Paid') DEFAULT 'Pending Payment' AFTER rent_status"); } catch(Exception $e) {}
// Add period_start
try { $db->exec("ALTER TABLE rent_invoices ADD COLUMN period_start DATE AFTER amount"); } catch(Exception $e) {}
// Add period_end
try { $db->exec("ALTER TABLE rent_invoices ADD COLUMN period_end DATE AFTER period_start"); } catch(Exception $e) {}
// Add notes
try { $db->exec("ALTER TABLE rent_invoices ADD COLUMN notes TEXT AFTER status"); } catch(Exception $e) {}

try {
    $db->beginTransaction();

    $db->exec("
        UPDATE rent_invoices 
        SET period_start = DATE_FORMAT(due_date, '%Y-%m-01'),
            period_end = LAST_DAY(due_date)
        WHERE period_start IS NULL
    ");

    $db->commit();
    echo "Migration completed successfully.\n";

} catch (Exception $e) {
    $db->rollBack();
    echo "Migration failed: " . $e->getMessage() . "\n";
}
