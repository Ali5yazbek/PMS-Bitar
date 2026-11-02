<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/core/Database.php';
require_once __DIR__ . '/core/NLPEngine.php';
require_once __DIR__ . '/controllers/AIController.php';

try {
    $db = Database::getInstance()->getConnection();
    $controller = new AIController();
    
    // We mock the input using a reflection trick or just test a method directly.
    // Instead of chat(), which requires AuthMiddleware, let's test detectIntent or one of the handlers directly.
    $method = new ReflectionMethod('AIController', 'getTenantInfo');
    $method->setAccessible(true);
    
    ob_start();
    $method->invoke($controller, "ali yazbek");
    $output = ob_get_clean();
    
    echo "OUTPUT:\n";
    print_r(json_decode($output, true) ?: $output);

} catch (Throwable $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
    echo $e->getTraceAsString();
}
