import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide language state, mirroring [ThemeController]'s ValueNotifier
/// pattern. MaterialApp listens to [locale] in main.dart, so setting a new
/// value anywhere in the app (e.g. from the Settings language picker)
/// rebuilds the whole widget tree in the new language — no navigation or
/// per-screen wiring required.
///
/// Persistence is per signed-in user, not per device: each user's choice is
/// cached locally under a key that includes their user id
/// (`_prefsKeyFor(userId)`), so on a shared device User A picking Tamil never
/// changes what User B sees. SessionService calls [loadForUser] right after
/// login (and when a saved session is restored on app start) and
/// [resetToDefault] on logout — see the notes there. Because this is a local
/// cache only (no backend column exists for it), an uninstall/reinstall or
/// clearing app data wipes it, and the app falls back to English until the
/// user picks their language again.
class LocaleController {
  LocaleController._();

  static final ValueNotifier<Locale> locale =
      ValueNotifier<Locale>(const Locale('en'));

  /// Display label -> Locale, in the order they should appear in the
  /// language picker. Add a new entry here (+ a matching app_XX.arb file)
  /// to support another language.
  static const Map<String, Locale> supported = {
    'English': Locale('en'),
    'हिन्दी': Locale('hi'),
    'தமிழ்': Locale('ta'),
  };

  static const String _prefsKeyPrefix = 'lang_pref_';

  /// Display label for whatever locale is currently active — used to show
  /// e.g. "தமிழ்" as the trailing text on the Language settings tile.
  static String labelFor(Locale locale) {
    for (final entry in supported.entries) {
      if (entry.value.languageCode == locale.languageCode) return entry.key;
    }
    return supported.keys.first;
  }

  /// Applies [newLocale] immediately and remembers it as [userId]'s
  /// preference, so it's restored the next time this user logs in (on this
  /// device). Call this from the language picker instead of setting
  /// `locale.value` directly.
  static Future<void> setForUser(String userId, Locale newLocale) async {
    locale.value = newLocale; // update the UI immediately, don't wait on I/O
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyPrefix + userId, newLocale.languageCode);
  }

  /// Loads and applies [userId]'s saved language, or falls back to English
  /// if they've never picked one (new user / first login on this device).
  /// Called by SessionService right after login and when a persisted
  /// session is restored on app start.
  static Future<void> loadForUser(String userId) async {
    if (userId.isEmpty) {
      locale.value = const Locale('en');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKeyPrefix + userId);
    locale.value = _localeForCode(code) ?? const Locale('en');
  }

  /// Resets the active language to English without touching any saved
  /// preference. Call on logout so the login screen — and whichever user
  /// signs in next — never inherits the previous user's language.
  static void resetToDefault() {
    locale.value = const Locale('en');
  }

  static Locale? _localeForCode(String? code) {
    if (code == null) return null;
    for (final candidate in supported.values) {
      if (candidate.languageCode == code) return candidate;
    }
    return null;
  }
}
