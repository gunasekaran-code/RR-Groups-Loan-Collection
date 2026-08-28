<?php
// Stores a user's registered WebAuthn / passkey credentials for biometric
// login. The browser performs the fingerprint / Face ID / Windows Hello
// ceremony; the server records the credential id + public key here so the user
// counts as enrolled and can be recognised on later sign-ins.

class BiometricCredential extends Model
{
    protected static string $table = 'biometric_credentials';

    /** All credentials registered for a user (newest first). */
    public static function forUser(string $userId): array
    {
        $stmt = Database::pdo()->prepare(
            "SELECT id, credential_id, label, created_at, last_used_at
               FROM biometric_credentials WHERE user_id = ? ORDER BY created_at DESC"
        );
        $stmt->execute([$userId]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    /** True when the user has at least one credential enrolled. */
    public static function isEnrolled(string $userId): bool
    {
        $stmt = Database::pdo()->prepare(
            "SELECT COUNT(*) FROM biometric_credentials WHERE user_id = ?"
        );
        $stmt->execute([$userId]);
        return (int)$stmt->fetchColumn() > 0;
    }

    /** Register (or upsert) a credential for a user. Returns its row id. */
    public static function register(string $userId, string $credentialId, ?string $publicKey, ?string $label): string
    {
        $pdo = Database::pdo();
        $id  = uuid4();
        $stmt = $pdo->prepare("
            INSERT INTO biometric_credentials (id, user_id, credential_id, public_key, label, created_at)
            VALUES (?, ?, ?, ?, ?, NOW())
            ON DUPLICATE KEY UPDATE public_key = VALUES(public_key), label = VALUES(label), last_used_at = NOW(),
                                    delflag = 0, deleted_at = NULL, deleted_by = NULL
        ");
        $stmt->execute([$id, $userId, $credentialId, $publicKey, $label]);
        return $id;
    }

    /** Look up the owner of a credential id (for biometric sign-in), or null. */
    public static function ownerOf(string $credentialId): ?string
    {
        $stmt = Database::pdo()->prepare(
            "SELECT user_id FROM biometric_credentials WHERE credential_id = ? AND delflag = 0 LIMIT 1"
        );
        $stmt->execute([$credentialId]);
        $uid = $stmt->fetchColumn();
        if ($uid) {
            $upd = Database::pdo()->prepare("UPDATE biometric_credentials SET last_used_at = NOW() WHERE credential_id = ?");
            $upd->execute([$credentialId]);
        }
        return $uid ?: null;
    }

    /** Remove a credential (by row id) belonging to a user. */
    public static function remove(string $userId, string $id): void
    {
        $stmt = Database::pdo()->prepare(
            "DELETE FROM biometric_credentials WHERE id = ? AND user_id = ?"
        );
        $stmt->execute([$id, $userId]);
    }
}
