<?php
/**
 * FCM transport. Uses the Kreait Firebase PHP SDK (composer: kreait/firebase-php) when it is
 * installed, otherwise falls back to the FCM HTTP v1 REST API using the same service account.
 *
 * The service-account JSON never leaves the server (default: backend/storage/, web-blocked).
 * Configure with FIREBASE_CREDENTIALS in backend/.env (absolute path or path relative to backend/).
 */
class FcmSender {
    const CHANNEL_ID = 'enterprise_push_channel_v2';

    private $credentialsPath;
    private $credentials = null;
    private $messaging = null;

    public function __construct(?string $credentialsPath = null) {
        $path = $credentialsPath ?: ($_ENV['FIREBASE_CREDENTIALS'] ?? '');
        if ($path === '') $path = __DIR__ . '/../storage/firebase-service-account.json';
        if (!preg_match('~^([A-Za-z]:[\\\\/]|/)~', $path)) $path = __DIR__ . '/../' . $path;
        $this->credentialsPath = $path;

        if (!empty($_ENV['FIREBASE_SERVICE_ACCOUNT_JSON'])) {
            $inline = json_decode((string)$_ENV['FIREBASE_SERVICE_ACCOUNT_JSON'], true);
            if (is_array($inline) && !empty($inline['private_key'])) {
                $this->credentials = $inline;
            }
        }
    }

    public function isConfigured(): bool {
        if (is_array($this->credentials) && !empty($this->credentials['private_key'])) {
            return true;
        }
        return is_file($this->credentialsPath) && is_readable($this->credentialsPath);
    }

    public function transport(): string {
        return (class_exists('Kreait\\Firebase\\Factory') && is_file($this->credentialsPath)) ? 'kreait' : 'rest';
    }

    /**
     * @return array{ok:bool,message_id:?string,error_code:?string,error:?string,invalid:bool,retry:bool}
     */
    public function send(string $token, string $title, string $body, array $data = []): array {
        $data['click_action'] = 'FLUTTER_NOTIFICATION_CLICK';
        $data['title'] = $data['title'] ?? $title;
        $data['body'] = $data['body'] ?? $body;
        // FCM data values must all be strings.
        $data = array_map(function ($v) { return is_scalar($v) ? (string)$v : json_encode($v); }, $data);
        try {
            return $this->transport() === 'kreait'
                ? $this->sendKreait($token, $title, $body, $data)
                : $this->sendRest($token, $title, $body, $data);
        } catch (Throwable $e) {
            return self::classify(get_class($e), $e->getMessage(), 0);
        }
    }

    // ── Kreait ─────────────────────────────────────────────────────────────
    private function sendKreait(string $token, string $title, string $body, array $data): array {
        if ($this->messaging === null) {
            $this->messaging = (new \Kreait\Firebase\Factory())
                ->withServiceAccount($this->credentialsPath)
                ->createMessaging();
        }
        $message = \Kreait\Firebase\Messaging\CloudMessage::withTarget('token', $token)
            ->withNotification(\Kreait\Firebase\Messaging\Notification::create($title, $body))
            ->withData($data)
            ->withAndroidConfig(\Kreait\Firebase\Messaging\AndroidConfig::fromArray([
                'priority' => 'high',
                'ttl' => '86400s',
                'notification' => [
                    'channel_id' => self::CHANNEL_ID,
                    'sound' => 'default',
                    'default_sound' => true,
                    'default_vibrate_timings' => true,
                    'visibility' => 'PUBLIC',
                    'notification_priority' => 'PRIORITY_MAX',
                    'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                ],
            ]))
            ->withApnsConfig(\Kreait\Firebase\Messaging\ApnsConfig::fromArray([
                'headers' => [
                    'apns-priority' => '10',
                    'apns-push-type' => 'alert',
                ],
                'payload' => [
                    'aps' => [
                        'alert' => ['title' => $title, 'body' => $body],
                        'sound' => 'default',
                        'badge' => 1,
                        'content-available' => 1,
                        'mutable-content' => 1,
                    ],
                ],
            ]));
        $res = $this->messaging->send($message);
        return ['ok' => true, 'message_id' => $res['name'] ?? null, 'error_code' => null, 'error' => null, 'invalid' => false, 'retry' => false];
    }

    // ── REST fallback (FCM HTTP v1) ────────────────────────────────────────
    private function creds(): array {
        if ($this->credentials === null) {
            $this->credentials = json_decode((string)file_get_contents($this->credentialsPath), true) ?: [];
        }
        return $this->credentials;
    }

    private function accessToken(bool $forceRefresh = false): string {
        $c = $this->creds();
        $cacheFile = sys_get_temp_dir() . '/fcm_token_' . md5($c['client_email'] ?? 'x') . '.json';
        if (!$forceRefresh && is_file($cacheFile)) {
            $cached = json_decode((string)file_get_contents($cacheFile), true);
            if (!empty($cached['token']) && ($cached['exp'] ?? 0) > time() + 120) return $cached['token'];
        }
        $now = time();
        $b64 = function ($s) { return rtrim(strtr(base64_encode($s), '+/', '-_'), '='); };
        $header = $b64(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
        $claims = $b64(json_encode([
            'iss' => $c['client_email'], 'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
            'aud' => 'https://oauth2.googleapis.com/token', 'iat' => $now, 'exp' => $now + 3600,
        ]));
        $signature = '';
        if (!openssl_sign("$header.$claims", $signature, $c['private_key'], OPENSSL_ALGO_SHA256)) {
            throw new RuntimeException('Cannot sign service-account JWT');
        }
        $ch = curl_init('https://oauth2.googleapis.com/token');
        curl_setopt_array($ch, [
            CURLOPT_POST => true, CURLOPT_RETURNTRANSFER => true, CURLOPT_TIMEOUT => 10,
            CURLOPT_POSTFIELDS => http_build_query([
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion' => "$header.$claims." . $b64($signature),
            ]),
        ]);
        $raw = curl_exec($ch);
        curl_close($ch);
        $json = json_decode((string)$raw, true);
        if (empty($json['access_token'])) throw new RuntimeException('OAuth failed: ' . substr((string)$raw, 0, 200));
        @file_put_contents($cacheFile, json_encode(['token' => $json['access_token'], 'exp' => $now + (int)($json['expires_in'] ?? 3500)]));
        return $json['access_token'];
    }

    private function sendRest(string $token, string $title, string $body, array $data, bool $retried = false): array {
        $c = $this->creds();
        $payload = ['message' => [
            'token' => $token,
            'notification' => ['title' => $title, 'body' => $body],
            'data' => (object)$data,
            'android' => [
                'priority' => 'HIGH',
                'ttl' => '86400s',
                'notification' => [
                    'channel_id' => self::CHANNEL_ID,
                    'sound' => 'default',
                    'default_sound' => true,
                    'default_vibrate_timings' => true,
                    'visibility' => 'PUBLIC',
                    'notification_priority' => 'PRIORITY_MAX',
                    'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                ],
            ],
            'apns' => [
                'headers' => [
                    'apns-priority' => '10',
                    'apns-push-type' => 'alert',
                ],
                'payload' => [
                    'aps' => [
                        'alert' => ['title' => $title, 'body' => $body],
                        'sound' => 'default',
                        'badge' => 1,
                        'content-available' => 1,
                        'mutable-content' => 1,
                    ],
                ],
            ],
        ]];
        $ch = curl_init('https://fcm.googleapis.com/v1/projects/' . rawurlencode($c['project_id'] ?? '') . '/messages:send');
        curl_setopt_array($ch, [
            CURLOPT_POST => true, CURLOPT_RETURNTRANSFER => true, CURLOPT_TIMEOUT => 10,
            CURLOPT_HTTPHEADER => ['Authorization: Bearer ' . $this->accessToken($retried), 'Content-Type: application/json'],
            CURLOPT_POSTFIELDS => json_encode($payload),
        ]);
        $raw = curl_exec($ch);
        $http = (int)curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $curlErr = curl_error($ch);
        curl_close($ch);

        if ($raw === false) return self::classify('CurlError', $curlErr, 0);
        $json = json_decode((string)$raw, true) ?: [];
        if ($http >= 200 && $http < 300) {
            return ['ok' => true, 'message_id' => $json['name'] ?? null, 'error_code' => null, 'error' => null, 'invalid' => false, 'retry' => false];
        }
        if ($http === 401 && !$retried) return $this->sendRest($token, $title, $body, $data, true);
        $status = $json['error']['status'] ?? '';
        $detail = '';
        foreach (($json['error']['details'] ?? []) as $d) { if (!empty($d['errorCode'])) $detail = $d['errorCode']; }
        return self::classify($detail ?: $status, $json['error']['message'] ?? $raw, $http);
    }

    /** Maps an FCM / SDK failure to "token is dead" vs "try again later" vs "permanent failure". */
    public static function classify(string $code, string $message, int $http): array {
        $hay = strtoupper($code . ' ' . $message);
        $invalid = (bool)preg_match('/UNREGISTERED|NOTFOUND|NOT_FOUND|REGISTRATION-TOKEN-NOT-REGISTERED|INVALID_ARGUMENT|INVALIDARGUMENT|INVALIDMESSAGE|SENDER_ID_MISMATCH/', $hay)
            && !preg_match('/QUOTA|UNAVAILABLE/', $hay);
        $retry = !$invalid && ($http === 0 || $http === 429 || $http >= 500
            || (bool)preg_match('/UNAVAILABLE|INTERNAL|QUOTA|TIMEOUT|CURL|SERVERERROR|OAUTH FAILED/', $hay));
        return ['ok' => false, 'message_id' => null, 'error_code' => substr($code ?: ('HTTP_' . $http), 0, 80),
                'error' => substr($message, 0, 480), 'invalid' => $invalid, 'retry' => $retry];
    }
}

