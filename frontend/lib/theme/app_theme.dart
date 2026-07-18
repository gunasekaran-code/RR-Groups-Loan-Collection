// import 'package:flutter/material.dart';

// // FinCollect design tokens — White & Gold theme.
// class AppColors {
//   AppColors._();
//   static const Color kGold = Color.fromARGB(255, 255, 174, 0);       // Classic Shining Gold
//   static const Color kGoldDark = Color(0xFFFFA000);   // Deep Vibrant Gold (keeps it bright, not muddy)
//   static const Color kGoldLight = Color(0xFFFFE066);  // Brilliant Light Gold
//   static const Color kBackground = Color(0xFFFAF9F6);
//   static const Color kSurface = Color(0xFFFFFFFF);
//   static const Color kBorder = Color(0xFFE7E1D0);
//   static const Color kTextDark = Color(0xFF1F2A37);
//   static const Color kTextMuted = Color(0xFF6B7280);
//   static const Color kSuccess = Color(0xFF16A34A);
//   static const Color kWarning = Color(0xFFD97706);
//   static const Color kDanger = Color(0xFFDC2626);
//   static const Color kInfo = Color(0xFF2563EB);
// }

// class AppTheme {
//   AppTheme._();

//   static ThemeData get light {
//     return ThemeData(
//       useMaterial3: true,
//       scaffoldBackgroundColor: AppColors.kBackground,
//       colorScheme: ColorScheme.fromSeed(
//         seedColor: AppColors.kGold,
//         primary: AppColors.kGold,
//         secondary: AppColors.kGoldDark,
//         surface: AppColors.kSurface,
//         brightness: Brightness.light,
//       ),
//       appBarTheme: const AppBarTheme(
//         backgroundColor: AppColors.kSurface,
//         foregroundColor: AppColors.kTextDark,
//         elevation: 0,
//         surfaceTintColor: Colors.transparent,
//         iconTheme: IconThemeData(color: AppColors.kTextDark),
//       ),
//       elevatedButtonTheme: ElevatedButtonThemeData(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: AppColors.kGold,
//           foregroundColor: Colors.white,
//           elevation: 0,
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//       ),
//       outlinedButtonTheme: OutlinedButtonThemeData(
//         style: OutlinedButton.styleFrom(
//           foregroundColor: AppColors.kTextDark,
//           side: const BorderSide(color: AppColors.kBorder),
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//       ),
//       inputDecorationTheme: InputDecorationTheme(
//         filled: true,
//         fillColor: AppColors.kSurface,
//         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(color: AppColors.kBorder),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(color: AppColors.kBorder),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(color: AppColors.kGold, width: 1.5),
//         ),
//       ),
//       dividerTheme: const DividerThemeData(color: AppColors.kBorder, thickness: 1),
//     );
//   }
// }



import 'package:flutter/material.dart';

/// FinCollect design tokens — RR Groups palette.
/// Gold-on-navy fintech identity: metallic gold accent, crest-navy ink.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------
  // BRAND — GOLD RAMP (buttons, active nav, accents, highlights)
  // ---------------------------------------------------------------------
  static const Color gold50 = Color(0xFFFDF8EC);
  static const Color gold100 = Color(0xFFFAEDC4);
  static const Color gold200 = Color(0xFFF3DA88);
  static const Color gold300 = Color(0xFFEAC765);
  static const Color gold400 = Color(0xFFDCAA3C);
  static const Color gold500 = Color(0xFFC3901F);
  static const Color gold600 = Color(0xFFA87615); // brand-600 · signature
  static const Color gold700 = Color(0xFF8A5F13);
  static const Color gold800 = Color(0xFF6B4A12);
  static const Color gold900 = Color(0xFF4A3306);
  static const Color gold950 = Color(0xFF2E1F04);

  // ---------------------------------------------------------------------
  // INK — NAVY RAMP (text, surfaces, borders, dark panels)
  // ---------------------------------------------------------------------
  static const Color ink50 = Color(0xFFF7F8FB);
  static const Color ink100 = Color(0xFFEEF0F6);
  static const Color ink200 = Color(0xFFDBE0EB);
  static const Color ink300 = Color(0xFFB6BFD6);
  static const Color ink400 = Color(0xFF8891B3);
  static const Color ink500 = Color(0xFF5F6890);
  static const Color ink600 = Color(0xFF454E70);
  static const Color ink700 = Color(0xFF2F3654);
  static const Color ink800 = Color(0xFF1A2038);
  static const Color ink900 = Color(0xFF0D1226); // ink-900 · signature
  static const Color ink950 = Color(0xFF050813);

  // ---------------------------------------------------------------------
  // SEMANTIC / STATUS — kept separate from the gold accent
  // ---------------------------------------------------------------------
  static const Color emerald = Color(0xFF10B981); // Paid · success
  static const Color rose = Color(0xFFF43F5E); // Overdue · error
  static const Color amber = Color(0xFFF59E0B); // Partial · pending
  static const Color violet = Color(0xFF8B5CF6); // Chit · feature
  static const Color cyan = Color(0xFF06B6D4); // Info · feature

  // ---------------------------------------------------------------------
  // SEMANTIC ALIASES — how it maps onto the app's existing token names
  // Accent = brand-600. Body text = ink-900, muted = ink-500.
  // Page ground = ink-50. Dark panels run ink-800 → ink-950.
  // ---------------------------------------------------------------------
  static const Color kGold = gold600;
  static const Color kGoldDark = gold700;
  static const Color kGoldLight = gold300;

  static const Color kBackground = ink50;
  static const Color kSurface = Color(0xFFFFFFFF);
  static const Color kBorder = ink200;

  static const Color kTextDark = ink900;
  static const Color kTextMuted = ink500;

  // static const Color kSuccess = emerald;
  // static const Color kWarning = amber;
  // static const Color kDanger = rose;
  // static const Color kInfo = cyan;

    static const Color kSuccess = Color(0xFF16A34A);
  static const Color kWarning = Color(0xFFD97706);
  static const Color kDanger = Color(0xFFDC2626);
  static const Color kInfo = Color(0xFF2563EB);

  // Dark-panel tokens (sidebars, headers, chart cards, etc.)
  static const Color kPanelDark = ink900;
  static const Color kPanelDarkAlt = ink800;
  static const Color kPanelDarkBorder = ink700;
  static const Color kTextOnDark = ink50;
  static const Color kTextOnDarkMuted = ink300;
}

class AppTheme {
  AppTheme._();

  // Plus Jakarta Sans → Inter → system-ui fallback stack.
  // Add the `google_fonts` package (or bundle the font in pubspec.yaml)
  // and swap `fontFamily` for GoogleFonts.plusJakartaSans().fontFamily
  // if you want it pulled automatically instead of bundling.
  static const String fontFamily = 'PlusJakartaSans';
  static const List<String> fontFamilyFallback = ['Inter', 'system-ui'];

  // Hex codes / figures use a tabular-nums monospace stack.
  static const String monoFontFamily = 'RobotoMono';
  static const List<String> monoFontFamilyFallback = ['SFMono-Regular', 'monospace'];

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.kBackground,
      fontFamily: fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.kGold,
        primary: AppColors.kGold,
        secondary: AppColors.kGoldDark,
        surface: AppColors.kSurface,
        error: AppColors.kDanger,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.kSurface,
        foregroundColor: AppColors.kTextDark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppColors.kTextDark),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.kTextDark),
        bodyMedium: TextStyle(color: AppColors.kTextDark),
        bodySmall: TextStyle(color: AppColors.kTextMuted),
      ).apply(fontFamily: fontFamily),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.kGold,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.kTextDark,
          side: const BorderSide(color: AppColors.kBorder),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.kSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.kGold, width: 1.5),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.kBorder, thickness: 1),
    );
  }

  /// Optional dark-panel theme for sidebars / chart cards that should
  /// stay on the ink-800→950 range per the "dark panels" mapping rule.
  static ThemeData get darkPanel {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.kPanelDark,
      fontFamily: fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.kGold,
        primary: AppColors.kGold,
        secondary: AppColors.kGoldLight,
        surface: AppColors.kPanelDarkAlt,
        brightness: Brightness.dark,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.kPanelDarkBorder, thickness: 1),
    );
  }
}