<?php
// Biometric login (WebAuthn / passkeys) — configured under Settings ▸ Biometric
// Login and enrolled per user here.
//   GET  → the caller's biometric status: feature enabled?, is the caller's role
//          in scope?, is the caller already enrolled?, their credential list.
//   POST { action: 'register', credential_id, public_key?, label? }
//          → store a credential for the caller (enrol this device).
//   POST { action: 'resolve', credential_id }
//          → map a credential id to its owner user id (used during sign-in).
//   POST { action: 'login', credential_id }
//          → issue a JWT for the credential's owner (biometric sign-in).
//   DELETE ?id=<row id>  → remove one of the caller's credentials.

class BiometricController extends Controller
{
    public function handle(): void
    {
        $method   = $_SERVER['REQUEST_METHOD'] ?? 'GET';
        $settings = Setting::current();
        $enabled  = (bool)($settings['biometric_enabled'] ?? false);
        $roles    = array_filter(array_map('trim', explode(',', (string)($settings['biometric_required_roles'] ?? 'admin,agent'))));

        // 'resolve' and 'login' are called before the user is authenticated
        // (during sign-in), so they are handled without requireAuth().
        if ($method === 'POST') {
            $body   = $this->body();
            $action = $body['action'] ?? '';

            if ($action === 'resolve') {
                $credId = trim((string)($body['credential_id'] ?? ''));
                if ($credId === '') json_error('credential_id required', 400);
                $userId = BiometricCredential::ownerOf($credId);
                if (!$userId) json_error('Unknown credential', 404);
                json_out(['user_id' => $userId]);
            }

            if ($action === 'login') {
                if (!$enabled) json_error('Biometric login is disabled', 403);
                $credId = trim((string)($body['credential_id'] ?? ''));
                if ($credId === '') json_error('credential_id required', 400);
                $userId = BiometricCredential::ownerOf($credId);
                if (!$userId) json_error('This device is not enrolled', 401);

                $user = Profile::firstRaw(' WHERE id = ?', [$userId]);
                if (!$user) json_error('Account not found', 401);
                if (($user['status'] ?? '') === 'inactive') {
                    json_error('Your account is inactive. Please contact the administrator.', 403);
                }
                if (!in_array($user['role'] ?? '', $roles, true)) {
                    json_error('Biometric login is not enabled for your role', 403);
                }

                $token = Jwt::encode([
                    'sub'   => $user['id'],
                    'email' => $user['email'],
                    'role'  => $user['role'],
                ]);
                unset($user['password_hash'], $user['reset_otp_hash'], $user['reset_otp_expires']);
                json_out([
                    'token'   => $token,
                    'user'    => ['id' => $user['id'], 'email' => $user['email']],
                    'profile' => $user,
                ]);
            }
        }

        $claims = $this->requireAuth();
        $userId = $claims['sub'] ?? '';
        $role   = $claims['role'] ?? '';

        switch ($method) {
            case 'GET':
                json_out([
                    'enabled'      => $enabled,
                    'roles'        => $roles,
                    'role_enabled' => $enabled && in_array($role, $roles, true),
                    'enrolled'     => BiometricCredential::isEnrolled($userId),
                    'credentials'  => BiometricCredential::forUser($userId),
                ]);
                break;

            case 'POST':
                $body = $this->body();
                if (($body['action'] ?? '') !== 'register') {
                    json_error('Unsupported action', 400);
                }
                if (!$enabled || !in_array($role, $roles, true)) {
                    json_error('Biometric login is not enabled for your role', 403);
                }
                $credId = trim((string)($body['credential_id'] ?? ''));
                if ($credId === '') json_error('credential_id required', 400);
                $id = BiometricCredential::register(
                    $userId, $credId,
                    isset($body['public_key']) ? (string)$body['public_key'] : null,
                    isset($body['label']) ? (string)$body['label'] : null
                );
                json_out(['ok' => true, 'id' => $id, 'enrolled' => true]);
                break;

            case 'DELETE':
                $id = $_GET['id'] ?? '';
                if ($id === '') json_error('id required', 400);
                BiometricCredential::remove($userId, $id);
                json_out(['ok' => true, 'enrolled' => BiometricCredential::isEnrolled($userId)]);
                break;

            default:
                json_error('Method not allowed', 405);
        }
    }
}
