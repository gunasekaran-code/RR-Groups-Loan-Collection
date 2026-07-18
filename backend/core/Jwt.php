<?php
// Minimal HS256 JWT (no external dependencies).

class Jwt
{
    private static function b64UrlEncode(string $data): string
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    private static function b64UrlDecode(string $data): string
    {
        return base64_decode(strtr($data, '-_', '+/'));
    }

    public static function encode(array $payload): string
    {
        $secret = config('jwt_secret');
        $ttl = config('jwt_ttl');
        $now = time();
        $payload['iat'] = $now;
        $payload['exp'] = $now + $ttl;

        $segments = [
            self::b64UrlEncode(json_encode(['alg' => 'HS256', 'typ' => 'JWT'])),
            self::b64UrlEncode(json_encode($payload)),
        ];
        $signature = hash_hmac('sha256', implode('.', $segments), $secret, true);
        $segments[] = self::b64UrlEncode($signature);
        return implode('.', $segments);
    }

    public static function decode(string $jwt): ?array
    {
        $parts = explode('.', $jwt);
        if (count($parts) !== 3) {
            return null;
        }
        [$h, $p, $s] = $parts;
        $expected = self::b64UrlEncode(hash_hmac('sha256', "$h.$p", config('jwt_secret'), true));
        if (!hash_equals($expected, $s)) {
            return null;
        }
        $payload = json_decode(self::b64UrlDecode($p), true);
        if (!is_array($payload)) {
            return null;
        }
        if (isset($payload['exp']) && time() >= $payload['exp']) {
            return null;
        }
        return $payload;
    }
}
