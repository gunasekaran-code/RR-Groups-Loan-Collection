<?php
// Base controller: request body + JWT auth guards.

abstract class Controller
{
    protected function body(): array
    {
        return read_json_body();
    }

    /** Returns JWT claims or exits 401. */
    protected function requireAuth(): array
    {
        $token = bearer_token();
        if (!$token) {
            json_error('Missing authorization token', 401);
        }
        $claims = Jwt::decode($token);
        if (!$claims) {
            json_error('Invalid or expired token', 401);
        }
        if (!empty($claims['sub'])) {
            $p = Profile::firstRaw(' WHERE id = ?', [$claims['sub']]);
            if ($p && !empty($p['role'])) {
                $claims['role'] = strtolower(trim($p['role']));
            }
        }
        $claims['role'] = strtolower(trim($claims['role'] ?? ''));
        return $claims;
    }

    /** Attempts auth but returns null instead of dying if no/invalid token. */
    protected function tryAuth(): ?array
    {
        $token = bearer_token();
        if (!$token) {
            return null;
        }
        $claims = Jwt::decode($token);
        if (!$claims) {
            return null;
        }
        if (!empty($claims['sub'])) {
            $p = Profile::firstRaw(' WHERE id = ?', [$claims['sub']]);
            if ($p && !empty($p['role'])) {
                $claims['role'] = strtolower(trim($p['role']));
            }
        }
        $claims['role'] = strtolower(trim($claims['role'] ?? ''));
        return $claims;
    }

    /** Requires an authenticated admin, or exits 401/403. */
    protected function requireAdmin(): array
    {
        $claims = $this->requireAuth();
        if (($claims['role'] ?? '') !== 'admin') {
            json_error('Admin access required', 403);
        }
        return $claims;
    }
}
