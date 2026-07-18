<?php
class Profile extends Model
{
    protected static string $table = 'profiles';
    protected static array $hidden = ['password_hash', 'reset_otp_hash', 'reset_otp_expires'];

    public static function findByEmail(string $email): ?array
    {
        return static::firstRaw(' WHERE email = ?', [$email]);
    }

    public static function emailTaken(string $email, ?string $exceptId = null): bool
    {
        if ($exceptId) {
            $stmt = Database::pdo()->prepare('SELECT COUNT(*) FROM profiles WHERE email = ? AND id <> ?');
            $stmt->execute([$email, $exceptId]);
        } else {
            $stmt = Database::pdo()->prepare('SELECT COUNT(*) FROM profiles WHERE email = ?');
            $stmt->execute([$email]);
        }
        return (int)$stmt->fetchColumn() > 0;
    }

    public static function findPublic(string $id): ?array
    {
        $rows = static::select(' WHERE id = ?', [$id], '', ' LIMIT 1');
        return $rows[0] ?? null;
    }

    /** The login profile linked to a customers row, if any. */
    public static function findByCustomerId(string $customerId): ?array
    {
        return static::firstRaw(' WHERE customer_id = ? AND role = ?', [$customerId, 'customer']);
    }
}
