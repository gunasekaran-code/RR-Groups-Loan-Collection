<?php
// Minimal dependency-free SMTP client (STARTTLS + AUTH LOGIN).
// Enough to deliver transactional email (OTP codes) via Gmail or any SMTP host.

class Mailer
{
    /** Whether SMTP is configured (username + password present). */
    public static function configured(): bool
    {
        $s = config('smtp') ?? [];
        return !empty($s['username']) && !empty($s['password']);
    }

    /**
     * Send an email. Pass $html for a rich message (a multipart/alternative with
     * the plain-text $body as fallback is built automatically). Returns true on
     * success. Never throws — OTP delivery is best-effort and callers fall back.
     */
    public static function send(string $toEmail, string $subject, string $body, ?string $html = null): bool
    {
        $s = config('smtp') ?? [];
        if (!self::configured()) return false;

        $host = $s['host'] ?: 'smtp.gmail.com';
        $port = (int)($s['port'] ?: 587);
        $user = $s['username'];
        $pass = $s['password'];
        $from = $s['from_email'] ?: $user;
        $fromName = $s['from_name'] ?: 'RR Groups';

        try {
            $fp = @fsockopen($host, $port, $errno, $errstr, 15);
            if (!$fp) return false;
            stream_set_timeout($fp, 15);

            $expect = function (string $code) use ($fp): bool {
                $line = '';
                do {
                    $line = fgets($fp, 515);
                    if ($line === false) return false;
                } while (isset($line[3]) && $line[3] === '-'); // multi-line reply
                return str_starts_with($line, $code);
            };
            $cmd = function (string $c) use ($fp) { fputs($fp, $c . "\r\n"); };

            if (!$expect('220')) { fclose($fp); return false; }
            $cmd('EHLO rrgroups.local');
            if (!$expect('250')) { fclose($fp); return false; }

            // STARTTLS
            $cmd('STARTTLS');
            if (!$expect('220')) { fclose($fp); return false; }
            if (!stream_socket_enable_crypto($fp, true, STREAM_CRYPTO_METHOD_TLS_CLIENT
                | STREAM_CRYPTO_METHOD_TLSv1_1_CLIENT | STREAM_CRYPTO_METHOD_TLSv1_2_CLIENT)) {
                fclose($fp); return false;
            }
            $cmd('EHLO rrgroups.local');
            if (!$expect('250')) { fclose($fp); return false; }

            // AUTH LOGIN
            $cmd('AUTH LOGIN');
            if (!$expect('334')) { fclose($fp); return false; }
            $cmd(base64_encode($user));
            if (!$expect('334')) { fclose($fp); return false; }
            $cmd(base64_encode($pass));
            if (!$expect('235')) { fclose($fp); return false; }

            $cmd('MAIL FROM:<' . $from . '>');
            if (!$expect('250')) { fclose($fp); return false; }
            $cmd('RCPT TO:<' . $toEmail . '>');
            if (!$expect('250')) { fclose($fp); return false; }
            $cmd('DATA');
            if (!$expect('354')) { fclose($fp); return false; }

            $headers = 'From: ' . self::encodeName($fromName) . ' <' . $from . ">\r\n"
                . 'To: <' . $toEmail . ">\r\n"
                . 'Subject: ' . self::encodeName($subject) . "\r\n"
                . 'Date: ' . date('r') . "\r\n"
                . 'Message-ID: <' . bin2hex(random_bytes(12)) . '@rrgroups.local>' . "\r\n"
                . "MIME-Version: 1.0\r\n";

            if ($html !== null) {
                $boundary = 'rrg_' . bin2hex(random_bytes(10));
                $headers .= "Content-Type: multipart/alternative; boundary=\"$boundary\"\r\n";
                $mime = "--$boundary\r\n"
                    . "Content-Type: text/plain; charset=UTF-8\r\n"
                    . "Content-Transfer-Encoding: 8bit\r\n\r\n"
                    . $body . "\r\n"
                    . "--$boundary\r\n"
                    . "Content-Type: text/html; charset=UTF-8\r\n"
                    . "Content-Transfer-Encoding: 8bit\r\n\r\n"
                    . $html . "\r\n"
                    . "--$boundary--\r\n";
            } else {
                $headers .= "Content-Type: text/plain; charset=UTF-8\r\n"
                    . "Content-Transfer-Encoding: 8bit\r\n";
                $mime = $body;
            }

            $message = $headers . "\r\n" . $mime;
            // Normalise line endings and dot-stuff lines beginning with '.'.
            $message = str_replace("\r\n", "\n", $message);
            $message = str_replace("\n.", "\n..", $message);
            $message = str_replace("\n", "\r\n", $message);
            $cmd($message . "\r\n.");
            if (!$expect('250')) { fclose($fp); return false; }

            $cmd('QUIT');
            fclose($fp);
            return true;
        } catch (\Throwable $e) {
            return false;
        }
    }

    private static function encodeName(string $s): string
    {
        // RFC 2047 encode for non-ASCII header values.
        return preg_match('/[^\x20-\x7E]/', $s)
            ? '=?UTF-8?B?' . base64_encode($s) . '?='
            : $s;
    }
}
