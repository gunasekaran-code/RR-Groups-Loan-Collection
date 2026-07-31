<?php
// Interface language — stored on the settings row (Settings ▸ Language).
//   GET  → { current, supported: [ {code,label,native}, … ] } for any authed user.
//   POST { language } → change the active language (admin only).

class LanguageController extends Controller
{
    public function handle(): void
    {
        $claims = $this->requireAuth();
        $role   = $claims['role'] ?? '';
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

        switch ($method) {
            case 'GET':
                json_out([
                    'current'   => Language::current(),
                    'supported' => Language::SUPPORTED,
                ]);
                break;
            case 'POST':
            case 'PATCH':
            case 'PUT':
                if ($role !== 'admin') {
                    json_error('Only admins can change the language', 403);
                }
                $body = $this->body();
                $code = trim((string)($body['language'] ?? ''));
                if ($code === '') json_error('language required', 400);
                json_out(['ok' => true, 'current' => Language::set($code)]);
                break;
            default:
                json_error('Method not allowed', 405);
        }
    }
}
