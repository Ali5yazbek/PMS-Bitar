<?php

class PrivacyMasker {
    /**
     * Masks sensitive data in strings or arrays before logging.
     */
    public static function mask($data) {
        if (is_array($data)) {
            $masked = [];
            foreach ($data as $key => $value) {
                $masked[$key] = self::maskField($key, $value);
            }
            return $masked;
        }

        if (is_string($data)) {
            return self::maskString($data);
        }

        return $data;
    }

    private static function maskField($key, $value) {
        if (!is_string($value) || empty($value)) {
            return self::mask($value); // Recurse for nested arrays
        }

        $lowerKey = strtolower($key);

        // Keywords indicating sensitive fields
        $sensitiveKeys = [
            'password', 'token', 'secret', 'national_id', 'passport', 
            'credit_card', 'cc_number', 'bank_account', 'iban'
        ];

        $isSensitive = false;
        foreach ($sensitiveKeys as $sk) {
            if (strpos($lowerKey, $sk) !== false) {
                $isSensitive = true;
                break;
            }
        }

        if ($isSensitive) {
            return self::maskValueByRules($lowerKey, $value);
        }

        // Apply string-level regex masks even if the key isn't explicitly flagged
        return self::maskString($value);
    }

    private static function maskValueByRules($key, $value) {
        if (strpos($key, 'password') !== false || strpos($key, 'token') !== false || strpos($key, 'secret') !== false) {
            return '[REDACTED]';
        }
        
        if (strpos($key, 'national_id') !== false) {
            // e.g. 1029384756 -> *******4756
            return str_pad(substr($value, -4), strlen($value), '*', STR_PAD_LEFT);
        }

        if (strpos($key, 'passport') !== false) {
            // e.g. P123456789 -> P******789
            if (strlen($value) > 4) {
                return substr($value, 0, 1) . str_repeat('*', strlen($value) - 4) . substr($value, -3);
            }
        }

        if (strpos($key, 'bank') !== false || strpos($key, 'iban') !== false) {
            if (strlen($value) > 4) {
                return str_pad(substr($value, -4), strlen($value), '*', STR_PAD_LEFT);
            }
        }

        // Default masking (leave last 4 if long enough)
        if (strlen($value) > 4) {
            return str_pad(substr($value, -4), strlen($value), '*', STR_PAD_LEFT);
        }

        return '***';
    }

    private static function maskString($str) {
        // Find things that look like National IDs (10 digits) and mask them
        $str = preg_replace('/\b\d{10}\b/', '*******$0', $str); // Wait, backreference $0 is the whole thing. We want to keep last 4.
        $str = preg_replace_callback('/\b(\d{6})(\d{4})\b/', function($matches) {
            return '******' . $matches[2];
        }, $str);

        // Find things that look like Passports (Letter followed by 8-9 digits)
        $str = preg_replace_callback('/\b([A-Z])(\d{5,6})(\d{3})\b/i', function($matches) {
            return $matches[1] . str_repeat('*', strlen($matches[2])) . $matches[3];
        }, $str);

        return $str;
    }
}
