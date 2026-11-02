<?php
$_SERVER['REQUEST_URI'] = '/api/operations/online-users';
$_SERVER['REQUEST_METHOD'] = 'GET';
session_start();
$_SESSION['user'] = ['id' => 1, 'role' => 'admin'];
require_once 'index.php';
