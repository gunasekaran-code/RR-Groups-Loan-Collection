<?php
// Dependency-free SMS sender for OTP delivery.
// Supports Fast2SMS and MSG91 via their HTTP APIs. Best-effort; never throws.

class Sms
{
    public static function configured(): bool
    {
        $s = config('sms') ?? [];
        return !empty($s['provider']) && !empty($s['api_key']);
    }

    /** Send an OTP to an Indian mobile number. Returns true on success. */
    public static function sendOtp(string $mobile, string $otp): bool
    {
        $s = config('sms') ?? [];
        if (!self::configured()) return false;

        $mobile = preg_replace('/\D+/', '', $mobile);
        if (strlen($mobile) > 10) $mobile = substr($mobile, -10); // strip country code

        try {
            return match ($s['provider']) {
                'fast2sms' => self::fast2sms($s, $mobile, $otp),
                'msg91'    => self::msg91($s, $mobile, $otp),
                default    => false,
            };
        } catch (\Throwable $e) {
            return false;
        }
    }

    private static function fast2sms(array $s, string $mobile, string $otp): bool
    {
        // Fast2SMS "OTP route": variables_values=<otp>, route=otp
        $url = 'https://www.fast2sms.com/dev/bulkV2?' . http_build_query([
            'authorization'    => $s['api_key'],
            'route'            => 'otp',
            'variables_values' => $otp,
            'numbers'          => $mobile,
        ]);
        $resp = self::httpGet($url);
        return $resp !== null && stripos($resp, '"return":true') !== false;
    }

    private static function msg91(array $s, string $mobile, string $otp): bool
    {
        // MSG91 OTP API. Requires a DLT-approved template that renders {{otp}}.
        $url = 'https://control.msg91.com/api/v5/otp?' . http_build_query(array_filter([
            'authkey'     => $s['api_key'],
            'mobile'      => '91' . $mobile,
            'otp'         => $otp,
            'sender'      => $s['sender_id'] ?? '',
            'template_id' => $s['template_id'] ?? '',
        ]));
        $resp = self::httpGet($url);
        return $resp !== null && stripos($resp, '"type":"success"') !== false;
    }

    private static function httpGet(string $url): ?string
    {
        if (function_exists('curl_init')) {
            $ch = curl_init($url);
            curl_setopt_array($ch, [
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_TIMEOUT        => 15,
                CURLOPT_SSL_VERIFYPEER => true,
            ]);
            $out = curl_exec($ch);
            $ok = $out !== false && curl_getinfo($ch, CURLINFO_HTTP_CODE) < 400;
            curl_close($ch);
            return $ok ? (string)$out : null;
        }
        $ctx = stream_context_create(['http' => ['timeout' => 15, 'ignore_errors' => true]]);
        $out = @file_get_contents($url, false, $ctx);
        return $out === false ? null : $out;
    }
}
