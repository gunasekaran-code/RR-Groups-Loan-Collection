import 'package:flutter/material.dart';

/// App-wide language state, mirroring [ThemeController]'s ValueNotifier
/// pattern. MaterialApp listens to [locale] in main.dart, so setting a new
/// value anywhere in the app (e.g. from the Settings language picker)
/// rebuilds the whole widget tree in the new language — no navigation or
/// per-screen wiring required.
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

  /// Display label for whatever locale is currently active — used to show
  /// e.g. "தமிழ்" as the trailing text on the Language settings tile.
  static String labelFor(Locale locale) {
    for (final entry in supported.entries) {
      if (entry.value.languageCode == locale.languageCode) return entry.key;
    }
    return supported.keys.first;
  }

  // TODO(persistence): currently in-memory only, same as ThemeController.
  // When you wire this to shared_preferences, read the saved language code
  // in main() before runApp() (same spot SessionService.restoreFromStorage()
  // and BrandingService.initialize() are awaited) and set `locale.value`
  // there before the widget tree builds.
}