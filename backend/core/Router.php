<?php
class Router {
    private $routes = [];

    public function get($path, $callback) {
        $this->addRoute('GET', $path, $callback);
    }

    public function post($path, $callback) {
        $this->addRoute('POST', $path, $callback);
    }

    public function put($path, $callback) {
        $this->addRoute('PUT', $path, $callback);
    }

    public function delete($path, $callback) {
        $this->addRoute('DELETE', $path, $callback);
    }

    private function addRoute($method, $path, $callback) {
        // Convert path variables like {id} to regex
        $routeRegex = preg_replace('/\{[a-zA-Z0-9_]+\}/', '([a-zA-Z0-9_]+)', $path);
        $routeRegex = str_replace('/', '\/', $routeRegex);
        $routeRegex = '/^' . $routeRegex . '$/';
        $this->routes[] = [
            'method' => $method,
            'pattern' => $routeRegex,
            'callback' => $callback
        ];
    }

    public function dispatch($uri) {
        $method = $_SERVER['REQUEST_METHOD'];
        
        // Remove base path from URI if needed (Local XAMPP: /Bitar/backend)
        // On Hostinger, this should be empty since routes start with /api
        $basePath = $_ENV['API_BASE_PATH'] ?? '';
        if ($basePath !== '' && strpos($uri, $basePath) === 0) {
            $uri = substr($uri, strlen($basePath));
        }
        $uri = strtok($uri, '?'); // Remove query string
        if (empty($uri)) {
            $uri = '/';
        }

        foreach ($this->routes as $route) {
            if ($route['method'] === $method && preg_match($route['pattern'], $uri, $matches)) {
                array_shift($matches); // Remove the full match
                
                // If callback is an array like [Controller::class, 'method']
                if (is_array($route['callback'])) {
                    $controller = new $route['callback'][0]();
                    $action = $route['callback'][1];
                    call_user_func_array([$controller, $action], $matches);
                } else {
                    call_user_func_array($route['callback'], $matches);
                }
                return;
            }
        }

        http_response_code(404);
        echo json_encode(['error' => 'Route not found: ' . $uri]);
    }
}
