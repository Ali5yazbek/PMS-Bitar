<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/core/Database.php';
require_once __DIR__ . '/core/NLPEngine.php';

$db = Database::getInstance()->getConnection();
$nlp = new NLPEngine($db);

$query = "see all yazbek tenant what he still didnt pay";
$res = $nlp->analyze($query);
print_r($res);
