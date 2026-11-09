<?php
class JWT {
    public static function encode($payload) {
        require_once __DIR__ . '/../config.php';
        $header = json_encode(['typ' => 'JWT', 'alg' => 'HS256']);
        $payload['exp'] = time() + JWT_EXPIRES_IN;
        $payload['iat'] = time();
        $payload = json_encode($payload);

        $base64UrlHeader = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($header));
        $base64UrlPayload = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($payload));

        $signature = hash_hmac('sha256', $base64UrlHeader . "." . $base64UrlPayload, JWT_SECRET, true);
        $base64UrlSignature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($signature));

        return $base64UrlHeader . "." . $base64UrlPayload . "." . $base64UrlSignature;
    }

    public static function decode($jwt) {
        require_once __DIR__ . '/../config.php';
        if (empty($jwt)) return false;

        $tokenParts = explode('.', $jwt);
        if (count($tokenParts) != 3) {
            return false;
        }

        $signature_provided = $tokenParts[2];
        $signature = hash_hmac('sha256', $tokenParts[0] . "." . $tokenParts[1], JWT_SECRET, true);
        $base64UrlSignature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($signature));

        if (hash_equals($base64UrlSignature, $signature_provided)) {
            $payloadJson = base64_decode(str_replace(['-', '_'], ['+', '/'], $tokenParts[1]));
            $data = json_decode($payloadJson, true);
            if (isset($data['exp']) && $data['exp'] < time()) {
                return false; // Expired
            }
            return $data;
        }
        return false;
    }

    /**
     * Verifies the HMAC-SHA256 signature of a JWT and returns its payload
     * even if the `exp` timestamp has passed. Used during refresh-token validation.
     */
    public static function decodeIgnoreExpiry($jwt) {
        require_once __DIR__ . '/../config.php';
        if (empty($jwt)) return false;

        $tokenParts = explode('.', $jwt);
        if (count($tokenParts) != 3) {
            return false;
        }

        $signature_provided = $tokenParts[2];
        $signature = hash_hmac('sha256', $tokenParts[0] . "." . $tokenParts[1], JWT_SECRET, true);
        $base64UrlSignature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($signature));

        if (hash_equals($base64UrlSignature, $signature_provided)) {
            $payloadJson = base64_decode(str_replace(['-', '_'], ['+', '/'], $tokenParts[1]));
            $data = json_decode($payloadJson, true);
            return is_array($data) ? $data : false;
        }
        return false;
    }

    /**
     * Generates a cryptographically secure 256-bit (64 hex chars) opaque refresh token.
     */
    public static function generateRefreshToken(): string {
        try {
            return bin2hex(random_bytes(32));
        } catch (\Throwable $e) {
            return hash('sha256', uniqid((string)mt_rand(), true) . JWT_SECRET . microtime(true));
        }
    }

    public static function getBearerToken() {
        $headers = null;

        if (!empty($_SERVER['Authorization'])) {
            $headers = trim($_SERVER["Authorization"]);
        } elseif (!empty($_SERVER['HTTP_AUTHORIZATION'])) { // Nginx, Apache or FastCGI
            $headers = trim($_SERVER["HTTP_AUTHORIZATION"]);
        } elseif (!empty($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) { // Apache rewrite redirect
            $headers = trim($_SERVER["REDIRECT_HTTP_AUTHORIZATION"]);
        } elseif (function_exists('getallheaders')) {
            $requestHeaders = getallheaders();
            if (is_array($requestHeaders)) {
                foreach ($requestHeaders as $key => $value) {
                    if (strtolower($key) === 'authorization') {
                        $headers = trim($value);
                        break;
                    }
                }
            }
        } elseif (function_exists('apache_request_headers')) {
            $requestHeaders = apache_request_headers();
            if (is_array($requestHeaders)) {
                foreach ($requestHeaders as $key => $value) {
                    if (strtolower($key) === 'authorization') {
                        $headers = trim($value);
                        break;
                    }
                }
            }
        }

        if (!empty($headers)) {
            if (preg_match('/Bearer\s+(\S+)/i', $headers, $matches)) {
                return $matches[1];
            }
            return $headers;
        }
        return null;
    }
}
