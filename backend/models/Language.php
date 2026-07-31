<?php
// Interface / messaging language, stored on the settings row. This model owns
// the list of supported languages and reads/writes the active choice so both
// the frontend UI and backend SMS/WhatsApp messages share one source of truth.

class Language extends Model
{
    protected static string $table = 'settings';

    public const SUPPORTED = [
        ['code' => 'en', 'label' => 'English', 'native' => 'English'],
        ['code' => 'ta', 'label' => 'Tamil',   'native' => 'தமிழ்'],
        ['code' => 'hi', 'label' => 'Hindi',    'native' => 'हिन्दी'],
    ];

    /** Currently selected language code (defaults to 'en'). */
    public static function current(): string
    {
        $s = Setting::current();
        $code = $s['language'] ?? 'en';
        return self::isSupported($code) ? $code : 'en';
    }

    public static function isSupported(string $code): bool
    {
        foreach (self::SUPPORTED as $l) {
            if ($l['code'] === $code) return true;
        }
        return false;
    }

    /** Persist a new language on the settings row. Returns the saved code. */
    public static function set(string $code): string
    {
        if (!self::isSupported($code)) {
            json_error('Unsupported language: ' . $code, 400);
        }
        $pdo = Database::pdo();
        $id  = $pdo->query("SELECT id FROM settings LIMIT 1")->fetchColumn();
        if ($id) {
            $stmt = $pdo->prepare("UPDATE settings SET language = ?, updated_at = NOW() WHERE id = ?");
            $stmt->execute([$code, $id]);
        } else {
            $stmt = $pdo->prepare("INSERT INTO settings (id, language, updated_at) VALUES (?, ?, NOW())");
            $stmt->execute([uuid4(), $code]);
        }
        return $code;
    }
}
