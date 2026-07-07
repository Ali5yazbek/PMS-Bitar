<?php
require 'backend/core/Database.php';
$db = Database::getInstance()->getConnection();
$s = $db->prepare("SELECT * FROM electricity_invoices WHERE apartment_id=1");
$s->execute();
var_dump($s->fetchAll());
