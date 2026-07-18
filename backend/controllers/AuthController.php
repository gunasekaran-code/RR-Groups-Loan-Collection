<?php
// Handles login (email/password -> JWT) and the current-user lookup.

class AuthController extends Controller
{
    public function handle(string $action): void
    {
        match ($action) {
            'login'          => $this->login(),
            'me'             => $this->me(),
            'update_profile' => $this->updateProfile(),
            'request_otp'    => $this->requestOtp(),
            'reset_password' => $this->resetPassword(),
            default          => json_error('Unknown action', 404),
        };
    }

    private static function clean($v): ?string
    {
        $v = is_string($v) ? trim($v) : '';
        return $v === '' ? null : $v;
    }

    /**
     * Self-service update of the authenticated user's own profile row.
     * Allows editing contact/KYC fields and (with the current password) the
     * email and password. Never lets a user change their own role or status.
     */
    private function updateProfile(): void
    {
        if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
            json_error('Method not allowed', 405);
        }
        $claims = $this->requireAuth();
        $id = $claims['sub'] ?? '';
        $current = Profile::firstRaw(' WHERE id = ?', [$id]);
        if (!$current) json_error('User not found', 404);

        $b = $this->body();
        $data = [];

        if (array_key_exists('full_name', $b)) {
            $fn = self::clean($b['full_name']);
            if (!$fn) json_error('Full name cannot be empty', 400);
            $data['full_name'] = $fn;
        }
        foreach (['mobile', 'avatar_url', 'address', 'aadhaar', 'pan', 'occupation'] as $f) {
            if (array_key_exists($f, $b)) $data[$f] = self::clean($b[$f]);
        }

        // Email or password changes require verifying the current password.
        $wantsEmail = array_key_exists('email', $b)
            && strtolower((string)(self::clean($b['email']) ?? '')) !== strtolower((string)($current['email'] ?? ''));
        $wantsPassword = !empty($b['new_password']);

        if ($wantsEmail || $wantsPassword) {
            $currentPassword = (string)($b['current_password'] ?? '');
            if ($currentPassword === '' || !$current['password_hash']
                || !password_verify($currentPassword, $current['password_hash'])) {
                json_error('Your current password is incorrect', 403);
            }
        }

        if ($wantsEmail) {
            $email = strtolower((string)(self::clean($b['email']) ?? ''));
            if (!$email || !filter_var($email, FILTER_VALIDATE_EMAIL)) json_error('A valid email is required', 400);
            if (Profile::emailTaken($email, $id)) json_error('That email is already registered', 409);
            $data['email'] = $email;
        }
        if ($wantsPassword) {
            if (strlen((string)$b['new_password']) < 6) json_error('New password must be at least 6 characters', 400);
            $data['password_hash'] = password_hash((string)$b['new_password'], PASSWORD_BCRYPT);
        }

        if (!$data) json_error('Nothing to update', 400);

        $rows = Profile::updateWhere($data, ' WHERE id = ?', [$id]);
        json_out(['profile' => $rows[0] ?? null]);
    }

    private function login(): void
    {
        if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
            json_error('Method not allowed', 405);
        }
        $body = $this->body();
        $email = strtolower(trim($body['email'] ?? ''));
        $password = (string)($body['password'] ?? '');
        if ($email === '' || $password === '') {
            json_error('Email and password are required', 400);
        }

        $user = Profile::findByEmail($email);
        if (!$user || !$user['password_hash'] || !password_verify($password, $user['password_hash'])) {
            json_error('Invalid email or password', 401);
        }
        if ($user['status'] === 'inactive') {
            json_error('Your account is inactive. Please contact the administrator.', 403);
        }

        $token = Jwt::encode([
            'sub'   => $user['id'],
            'email' => $user['email'],
            'role'  => $user['role'],
        ]);
        unset($user['password_hash']);
        json_out([
            'token'   => $token,
            'user'    => ['id' => $user['id'], 'email' => $user['email']],
            'profile' => $user,
        ]);
    }

    /** Find the account for a reset request, verifying email + mobile match. */
    private function findResetUser(array $b): array
    {
        $email  = strtolower(trim((string)($b['email'] ?? '')));
        $mobile = preg_replace('/\D+/', '', (string)($b['mobile'] ?? '')); // digits only
        if ($email === '' || $mobile === '') {
            json_error('Email and registered mobile number are required', 400);
        }
        $user = Profile::findByEmail($email);
        // Generic message so we don't reveal which part didn't match.
        $onFile = $user ? preg_replace('/\D+/', '', (string)($user['mobile'] ?? '')) : '';
        if (!$user || $onFile === '' || $onFile !== $mobile) {
            json_error('No account matches that email and mobile number', 404);
        }
        if (($user['status'] ?? '') === 'inactive') {
            json_error('Your account is inactive. Please contact the administrator.', 403);
        }
        return $user;
    }

    /**
     * Step 1 of reset: verify email + mobile, generate a 6-digit OTP, store it
     * (hashed, 5-minute expiry) and "send" it. No SMTP/SMS provider is wired,
     * so the code is returned in `demo_otp` for on-screen display; in production
     * that field would be removed and the code delivered by SMS/email instead.
     */
    private function requestOtp(): void
    {
        if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
            json_error('Method not allowed', 405);
        }
        $user = $this->findResetUser($this->body());

        $otp = str_pad((string)random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        Profile::updateWhere(
            [
                'reset_otp_hash'    => password_hash($otp, PASSWORD_BCRYPT),
                'reset_otp_expires' => date('Y-m-d H:i:s', time() + 300),
            ],
            ' WHERE id = ?',
            [$user['id']],
        );

        // Deliver the OTP over any configured channel (email / SMS).
        $emailConfigured = Mailer::configured();
        $smsConfigured   = Sms::configured();
        $demo            = !$emailConfigured && !$smsConfigured;

        $name = $user['full_name'] ?: 'there';
        $subject = 'Your RR Groups password reset code';
        $body = "Hi $name,\n\n"
              . "Your RR Groups password reset OTP is: $otp\n\n"
              . "This code expires in 5 minutes. If you didn't request this, you can ignore this message.\n\n"
              . "— RR Groups";
        $html = self::otpEmailHtml($name, $otp);

        $emailSent = $emailConfigured && !empty($user['email']) ? Mailer::send($user['email'], $subject, $body, $html) : false;
        $smsSent   = $smsConfigured   && !empty($user['mobile']) ? Sms::sendOtp((string)$user['mobile'], $otp) : false;

        if (!$demo && !$emailSent && !$smsSent) {
            json_error('We could not send the OTP right now. Please try again shortly.', 502);
        }

        $mobile = (string)($user['mobile'] ?? '');
        $channels = [];
        if ($emailSent) $channels[] = 'email';
        if ($smsSent)   $channels[] = 'sms';

        $resp = [
            'ok'           => true,
            'channels'     => $channels,
            'sent_to'      => self::maskMobile($mobile),
            'email_masked' => self::maskEmail((string)($user['email'] ?? '')),
        ];
        if ($demo) {
            $resp['demo_otp'] = $otp; // DEMO ONLY — shown when no email/SMS provider is configured.
        }
        json_out($resp);
    }

    private static function maskMobile(string $m): string
    {
        $m = preg_replace('/\D+/', '', $m);
        return strlen($m) >= 4 ? str_repeat('•', max(0, strlen($m) - 4)) . substr($m, -4) : $m;
    }

    private static function maskEmail(string $e): string
    {
        if (!str_contains($e, '@')) return $e;
        [$u, $d] = explode('@', $e, 2);
        $head = substr($u, 0, 1);
        return $head . str_repeat('•', max(1, strlen($u) - 1)) . '@' . $d;
    }

    /** Branded HTML for the OTP email (table-based, inline styles for email clients). */
    private static function otpEmailHtml(string $name, string $otp): string
    {
        $name = htmlspecialchars($name, ENT_QUOTES, 'UTF-8');
        $otp  = htmlspecialchars($otp, ENT_QUOTES, 'UTF-8');
        $year = date('Y');
        return <<<HTML
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>
<body style="margin:0;padding:0;background:#f4f6fb;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#f4f6fb;padding:32px 12px;font-family:Arial,Helvetica,sans-serif;">
    <tr><td align="center">
      <table role="presentation" width="480" cellpadding="0" cellspacing="0" style="width:480px;max-width:480px;background:#ffffff;border-radius:16px;overflow:hidden;border:1px solid #eef0f6;">
        <!-- header -->
        <tr><td style="background:#0d1226;padding:26px 32px;">
          <table role="presentation" cellpadding="0" cellspacing="0"><tr>
            <td style="width:42px;height:42px;background:#a87615;border-radius:21px;color:#2e1f04;font-size:15px;font-weight:bold;text-align:center;line-height:42px;">RR</td>
            <td style="padding-left:12px;color:#ffffff;font-size:18px;font-weight:bold;letter-spacing:-0.3px;">RR Groups</td>
          </tr></table>
        </td></tr>
        <!-- body -->
        <tr><td style="padding:32px 32px 8px;">
          <p style="margin:0 0 6px;color:#0d1226;font-size:19px;font-weight:bold;">Password reset code</p>
          <p style="margin:0 0 22px;color:#5f6890;font-size:14px;line-height:1.55;">Hi $name, use the one-time code below to reset your RR Groups password.</p>
          <table role="presentation" width="100%" cellpadding="0" cellspacing="0"><tr>
            <td align="center" style="background:#fdf8ec;border:1px solid #f3da88;border-radius:12px;padding:20px;">
              <div style="font-size:36px;font-weight:bold;letter-spacing:12px;color:#8a5f13;font-family:'Courier New',Courier,monospace;">$otp</div>
            </td>
          </tr></table>
          <p style="margin:20px 0 0;color:#5f6890;font-size:13px;line-height:1.55;">This code expires in <b style="color:#0d1226;">5 minutes</b>. If you didn't request a password reset, you can safely ignore this email — your password won't change.</p>
        </td></tr>
        <!-- footer -->
        <tr><td style="padding:22px 32px 26px;">
          <hr style="border:none;border-top:1px solid #eef0f6;margin:0 0 16px;">
          <p style="margin:0;color:#8891b3;font-size:12px;line-height:1.5;">RR Groups &middot; Loan &amp; Collection Suite<br>&copy; $year RR Groups. This is an automated security message.</p>
        </td></tr>
      </table>
    </td></tr>
  </table>
</body>
</html>
HTML;
    }

    /**
     * Step 2 of reset: verify email + mobile + the OTP, then set the new password.
     */
    private function resetPassword(): void
    {
        if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
            json_error('Method not allowed', 405);
        }
        $b = $this->body();
        $user = $this->findResetUser($b);

        $otp = preg_replace('/\D+/', '', (string)($b['otp'] ?? ''));
        $new = (string)($b['new_password'] ?? '');
        if ($otp === '') {
            json_error('Enter the OTP sent to your mobile number', 400);
        }
        if (strlen($new) < 6) {
            json_error('New password must be at least 6 characters', 400);
        }

        $hash    = (string)($user['reset_otp_hash'] ?? '');
        $expires = (string)($user['reset_otp_expires'] ?? '');
        if ($hash === '' || $expires === '') {
            json_error('Please request an OTP first', 400);
        }
        if (strtotime($expires) < time()) {
            json_error('That OTP has expired. Please request a new one.', 400);
        }
        if (!password_verify($otp, $hash)) {
            json_error('Incorrect OTP. Please check and try again.', 400);
        }

        Profile::updateWhere(
            [
                'password_hash'     => password_hash($new, PASSWORD_BCRYPT),
                'reset_otp_hash'    => null,
                'reset_otp_expires' => null,
            ],
            ' WHERE id = ?',
            [$user['id']],
        );
        json_out(['ok' => true]);
    }

    private function me(): void
    {
        $claims = $this->requireAuth();
        $user = Profile::findPublic($claims['sub']);
        if (!$user) {
            json_error('User not found', 404);
        }
        json_out([
            'user'    => ['id' => $user['id'], 'email' => $user['email']],
            'profile' => $user,
        ]);
    }
}
