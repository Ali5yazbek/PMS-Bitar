<?php
require 'config.php';
require 'core/Database.php';
$db = Database::getInstance()->getConnection();

// Fix amount_paid for Paid electricity invoices
$db->query("UPDATE electricity_invoices SET amount_paid = amount WHERE status = 'Paid' AND amount_paid = 0");

// Fix empty type for electricity invoices that have same amount as a subscription
$db->query("UPDATE electricity_invoices SET type = 'Subscription' WHERE type = ''");

echo "Fixed!\n";
