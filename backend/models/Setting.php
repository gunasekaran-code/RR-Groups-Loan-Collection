<?php
class Setting extends Model
{
    protected static string $table = 'settings';

    /**
     * The single settings row as an associative array (or an empty array when
     * none exists yet). Shared by the reminder / group-update / biometric /
     * language controllers so they all read the same live configuration.
     */
    public static function current(): array
    {
        $row = Database::pdo()->query("SELECT * FROM settings LIMIT 1")->fetch(PDO::FETCH_ASSOC);
        return $row ?: [];
    }
}
