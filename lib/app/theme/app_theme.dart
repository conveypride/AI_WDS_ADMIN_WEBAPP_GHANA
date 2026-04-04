import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// CORE APP THEME
/// ─────────────────────────────────────────────────────────────────────────────
class AppTheme {
  // ── Brand & Status Colors ───────────────────────────────────────────────────
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color infoCyan = Color(0xFF06B6D4);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);

  // ── Light Theme ─────────────────────────────────────────────────────────────
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF4F7FC), // Soft, cool gray-blue background
    primaryColor: accentBlue,
    fontFamily: 'Inter', // Default fallback font, 'Syne' is used explicitly in UI
    textTheme: const TextTheme(
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
      bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF334155)),
      bodySmall: TextStyle(fontSize: 12, color: Color(0xFF475569)),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
    ),
    extensions: const <ThemeExtension<dynamic>>[
      WColors(
        background: Color(0xFFF4F7FC),
        card: Color(0xFFFFFFFF),
        elevated: Color(0xFFF1F5F9),
        border: Color(0xFFE2E8F0),
        borderSoft: Color(0xFFF1F5F9),
        textPrimary: Color(0xFF0F172A),
        textSecondary: Color(0xFF475569),
        textMuted: Color(0xFF94A3B8),
      ),
    ],
  );

  // ── Dark Theme ──────────────────────────────────────────────────────────────
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0B1121), // Deep dashboard background
    primaryColor: accentBlue,
    fontFamily: 'Inter',
    textTheme: const TextTheme(
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFF8FAFC)),
      bodyMedium: TextStyle(fontSize: 14, color: Color(0xFFCBD5E1)),
      bodySmall: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFF8FAFC)),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
    ),
    extensions: const <ThemeExtension<dynamic>>[
      WColors(
        background: Color(0xFF0B1121),
        card: Color(0xFF151E32),
        elevated: Color(0xFF1E293B),
        border: Color(0xFF2A364D), // Subtle dark borders
        borderSoft: Color(0xFF1E293B),
        textPrimary: Color(0xFFF8FAFC),
        textSecondary: Color(0xFF94A3B8),
        textMuted: Color(0xFF64748B),
      ),
    ],
  );
}

/// ─────────────────────────────────────────────────────────────────────────────
/// CUSTOM THEME EXTENSION (WColors)
/// ─────────────────────────────────────────────────────────────────────────────
/// Holds semantic colors that adjust automatically between Light and Dark mode.
class WColors extends ThemeExtension<WColors> {
  final Color background;
  final Color card;
  final Color elevated;
  final Color border;
  final Color borderSoft;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  const WColors({
    required this.background,
    required this.card,
    required this.elevated,
    required this.border,
    required this.borderSoft,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  @override
  WColors copyWith({
    Color? background,
    Color? card,
    Color? elevated,
    Color? border,
    Color? borderSoft,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
  }) {
    return WColors(
      background: background ?? this.background,
      card: card ?? this.card,
      elevated: elevated ?? this.elevated,
      border: border ?? this.border,
      borderSoft: borderSoft ?? this.borderSoft,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
    );
  }

  @override
  WColors lerp(ThemeExtension<WColors>? other, double t) {
    if (other is! WColors) {
      return this;
    }
    return WColors(
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      elevated: Color.lerp(elevated, other.elevated, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderSoft: Color.lerp(borderSoft, other.borderSoft, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// BUILD CONTEXT EXTENSIONS
/// ─────────────────────────────────────────────────────────────────────────────
/// Exposes `context.wColors` and `context.isDark` seamlessly to widgets.
extension ThemeContextExtension on BuildContext {
  /// Access the custom semantic dashboard colors.
  WColors get wColors => Theme.of(this).extension<WColors>()!;

  /// Quick check for dark mode status.
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class AppTheme {
//   // ─── BRAND PALETTE ────────────────────────────────────────────
//   static const Color accentBlue = Color(0xFF3B82F6);
//   static const Color accentLight = Color(0xFF60A5FA);
//   static const Color accentGlow = Color(0x403B82F6); 

//   static const Color successGreen = Color(0xFF10B981);
//   static const Color warningAmber = Color(0xFFF59E0B);
//   static const Color dangerRed = Color(0xFFEF4444); 
//   static const Color infoCyan = Color(0xFF06B6D4);

//   static const Color primaryColor = accentBlue;   // was AppTheme.primaryColor
// static const Color successColor = successGreen; // was AppTheme.successColor
//   static const secondaryColor = Color(0xFF50C878); 
//   static const dangerColor = Color(0xFFEF5350);
//   static const warningColor = Color(0xFFFFA726);
//   static const infoColor = Color(0xFF26C6DA);
  
//   static const darkBackground = Color(0xFF1A1D1F);
  

//   // ─── DARK PALETTE ─────────────────────────────────────────────
//   static const Color darkBg = Color(0xFF070D16);
//   static const Color darkSurface = Color(0xFF0C1524);
//   static const Color darkCard = Color(0xFF111D2E);
//   static const Color darkCardHover = Color(0xFF162436);
//   static const Color darkElevated = Color(0xFF1A2B40);
//   static const Color darkBorder = Color(0x14639AE6);
//   static const Color darkBorderSoft = Color(0x22639AE6);
//   static const Color darkTextPrimary = Color(0xFFE4EEFB);
//   static const Color darkTextSecondary = Color(0xFF6B90BC);
//   static const Color darkTextMuted = Color(0xFF2E4A6B);

//   // ─── LIGHT PALETTE ────────────────────────────────────────────
//   static const Color lightBg = Color(0xFFF0F5FC);
//   static const Color lightSurface = Color(0xFFFFFFFF);
//   static const Color lightCard = Color(0xFFFFFFFF);
//   static const Color lightElevated = Color(0xFFF7FAFF);
//   static const Color lightBorder = Color(0xFFDDE8F5);
//   static const Color lightBorderSoft = Color(0xFFE8F0FB);
//   static const Color lightTextPrimary = Color(0xFF0F1E35);
//   static const Color lightTextSecondary = Color(0xFF4A6B92);
//   static const Color lightTextMuted = Color(0xFF8AA5C8);

 

//   // ─── TYPOGRAPHY ───────────────────────────────────────────────
//   static TextTheme _buildTextTheme(bool isDark) {
//     final primaryColor = isDark ? darkTextPrimary : lightTextPrimary;
//     final secondaryColor = isDark ? darkTextSecondary : lightTextSecondary;

//     return TextTheme(
//       // Display - Syne for headings
//       displayLarge: GoogleFonts.syne(
//         fontSize: 48, fontWeight: FontWeight.w800, color: primaryColor, letterSpacing: -1.0,
//       ),
//       displayMedium: GoogleFonts.syne(
//         fontSize: 36, fontWeight: FontWeight.w700, color: primaryColor, letterSpacing: -0.5,
//       ),
//       displaySmall: GoogleFonts.syne(
//         fontSize: 28, fontWeight: FontWeight.w700, color: primaryColor,
//       ),

//       // Headlines
//       headlineLarge: GoogleFonts.syne(
//         fontSize: 24, fontWeight: FontWeight.w700, color: primaryColor,
//       ),
//       headlineMedium: GoogleFonts.syne(
//         fontSize: 20, fontWeight: FontWeight.w700, color: primaryColor,
//       ),
//       headlineSmall: GoogleFonts.syne(
//         fontSize: 18, fontWeight: FontWeight.w600, color: primaryColor,
//       ),

//       // Titles - DM Sans
//       titleLarge: GoogleFonts.dmSans(
//         fontSize: 16, fontWeight: FontWeight.w600, color: primaryColor,
//       ),
//       titleMedium: GoogleFonts.dmSans(
//         fontSize: 15, fontWeight: FontWeight.w600, color: primaryColor,
//       ),
//       titleSmall: GoogleFonts.dmSans(
//         fontSize: 13, fontWeight: FontWeight.w600, color: primaryColor,
//       ),

//       // Body
//       bodyLarge: GoogleFonts.dmSans(
//         fontSize: 15, fontWeight: FontWeight.w400, color: primaryColor,
//       ),
//       bodyMedium: GoogleFonts.dmSans(
//         fontSize: 14, fontWeight: FontWeight.w400, color: primaryColor,
//       ),
//       bodySmall: GoogleFonts.dmSans(
//         fontSize: 12, fontWeight: FontWeight.w400, color: secondaryColor,
//       ),

//       // Labels
//       labelLarge: GoogleFonts.dmSans(
//         fontSize: 13, fontWeight: FontWeight.w600, color: primaryColor, letterSpacing: 0.1,
//       ),
//       labelMedium: GoogleFonts.dmSans(
//         fontSize: 11, fontWeight: FontWeight.w600, color: secondaryColor, letterSpacing: 0.8,
//       ),
//       labelSmall: GoogleFonts.dmSans(
//         fontSize: 10, fontWeight: FontWeight.w700, color: secondaryColor, letterSpacing: 1.2,
//       ),
//     );
//   }

//   // ─── DARK THEME ───────────────────────────────────────────────
//   static ThemeData get darkTheme {
//     return ThemeData(
//       useMaterial3: true,
//       brightness: Brightness.dark,
//       primaryColor: accentBlue,
//       scaffoldBackgroundColor: darkBg,
//       cardColor: darkCard,
//       dividerColor: darkBorder,
//       textTheme: _buildTextTheme(true),

//       colorScheme: ColorScheme.dark(
//         primary: accentBlue,
//         secondary: accentLight,
//         surface: darkSurface,
//         surfaceContainerHighest: darkElevated,
//         error: dangerRed,
//         onPrimary: Colors.white,
//         onSurface: darkTextPrimary,
//         outline: darkBorder,
//       ),

//       iconTheme: const IconThemeData(color: darkTextSecondary, size: 20),

//       appBarTheme: AppBarTheme(
//         backgroundColor: darkSurface,
//         elevation: 0,
//         surfaceTintColor: Colors.transparent,
//         iconTheme: const IconThemeData(color: darkTextPrimary),
//         titleTextStyle: GoogleFonts.syne(
//           color: darkTextPrimary, fontSize: 17, fontWeight: FontWeight.w600,
//         ),
//       ),

//       drawerTheme: const DrawerThemeData(
//         backgroundColor: darkSurface,
//         surfaceTintColor: Colors.transparent,
//       ),

//       inputDecorationTheme: InputDecorationTheme(
//         filled: true,
//         fillColor: darkElevated,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//           borderSide: const BorderSide(color: darkBorder),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//           borderSide: const BorderSide(color: darkBorder),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//           borderSide: const BorderSide(color: accentBlue, width: 1.5),
//         ),
//         hintStyle: GoogleFonts.dmSans(color: darkTextMuted),
//       ),

//       tooltipTheme: TooltipThemeData(
//         decoration: BoxDecoration(
//           color: darkElevated,
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(color: darkBorderSoft),
//           boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12)],
//         ),
//         textStyle: GoogleFonts.dmSans(color: darkTextPrimary, fontSize: 12),
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       ),

//       popupMenuTheme: PopupMenuThemeData(
//         color: darkElevated,
//         surfaceTintColor: Colors.transparent,
//         elevation: 16,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//           side: const BorderSide(color: darkBorderSoft),
//         ),
//         textStyle: GoogleFonts.dmSans(color: darkTextPrimary, fontSize: 13),
//       ),

//       extensions: const [WeatherAdminColors.dark],
//     );
//   }

//   // ─── LIGHT THEME ──────────────────────────────────────────────
//   static ThemeData get lightTheme {
//     return ThemeData(
//       useMaterial3: true,
//       brightness: Brightness.light,
//       primaryColor: accentBlue,
//       scaffoldBackgroundColor: lightBg,
//       cardColor: lightCard,
//       dividerColor: lightBorder,
//       textTheme: _buildTextTheme(false),

//       colorScheme: ColorScheme.light(
//         primary: accentBlue,
//         secondary: accentLight,
//         surface: lightSurface,
//         surfaceContainerHighest: lightElevated,
//         error: dangerRed,
//         onPrimary: Colors.white,
//         onSurface: lightTextPrimary,
//         outline: lightBorder,
//       ),

//       iconTheme: const IconThemeData(color: lightTextSecondary, size: 20),

//       appBarTheme: AppBarTheme(
//         backgroundColor: lightSurface,
//         elevation: 0,
//         surfaceTintColor: Colors.transparent,
//         iconTheme: const IconThemeData(color: lightTextPrimary),
//         titleTextStyle: GoogleFonts.syne(
//           color: lightTextPrimary, fontSize: 17, fontWeight: FontWeight.w600,
//         ),
//       ),

//       drawerTheme: const DrawerThemeData(
//         backgroundColor: lightSurface,
//         surfaceTintColor: Colors.transparent,
//       ),

//       inputDecorationTheme: InputDecorationTheme(
//         filled: true,
//         fillColor: lightElevated,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//           borderSide: const BorderSide(color: lightBorder),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//           borderSide: const BorderSide(color: lightBorder),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//           borderSide: const BorderSide(color: accentBlue, width: 1.5),
//         ),
//         hintStyle: GoogleFonts.dmSans(color: lightTextMuted),
//       ),

//       tooltipTheme: TooltipThemeData(
//         decoration: BoxDecoration(
//           color: lightTextPrimary,
//           borderRadius: BorderRadius.circular(8),
//           boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12)],
//         ),
//         textStyle: GoogleFonts.dmSans(color: Colors.white, fontSize: 12),
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       ),

//       popupMenuTheme: PopupMenuThemeData(
//         color: lightSurface,
//         surfaceTintColor: Colors.transparent,
//         elevation: 12,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//           side: const BorderSide(color: lightBorder),
//         ),
//         textStyle: GoogleFonts.dmSans(color: lightTextPrimary, fontSize: 13),
//       ),

//       extensions: const [WeatherAdminColors.light],
//     );
//   }
// }




// // ─── THEME EXTENSION ──────────────────────────────────────────────
// @immutable
// class WeatherAdminColors extends ThemeExtension<WeatherAdminColors> {
//   final Color textPrimary;
//   final Color textSecondary;
//   final Color textMuted;
//   final Color surface;
//   final Color card;
//   final Color elevated;
//   final Color border;
//   final Color borderSoft;

//   const WeatherAdminColors({
//     required this.textPrimary,
//     required this.textSecondary,
//     required this.textMuted,
//     required this.surface,
//     required this.card,
//     required this.elevated,
//     required this.border,
//     required this.borderSoft,
//   });

//   static const dark = WeatherAdminColors(
//     textPrimary: AppTheme.darkTextPrimary,
//     textSecondary: AppTheme.darkTextSecondary,
//     textMuted: AppTheme.darkTextMuted,
//     surface: AppTheme.darkSurface,
//     card: AppTheme.darkCard,
//     elevated: AppTheme.darkElevated,
//     border: AppTheme.darkBorder,
//     borderSoft: AppTheme.darkBorderSoft,
//   );

//   static const light = WeatherAdminColors(
//     textPrimary: AppTheme.lightTextPrimary,
//     textSecondary: AppTheme.lightTextSecondary,
//     textMuted: AppTheme.lightTextMuted,
//     surface: AppTheme.lightSurface,
//     card: AppTheme.lightCard,
//     elevated: AppTheme.lightElevated,
//     border: AppTheme.lightBorder,
//     borderSoft: AppTheme.lightBorderSoft,
//   );

//   @override
//   WeatherAdminColors copyWith({
//     Color? textPrimary, Color? textSecondary, Color? textMuted,
//     Color? surface, Color? card, Color? elevated, Color? border, Color? borderSoft,
//   }) {
//     return WeatherAdminColors(
//       textPrimary: textPrimary ?? this.textPrimary,
//       textSecondary: textSecondary ?? this.textSecondary,
//       textMuted: textMuted ?? this.textMuted,
//       surface: surface ?? this.surface,
//       card: card ?? this.card,
//       elevated: elevated ?? this.elevated,
//       border: border ?? this.border,
//       borderSoft: borderSoft ?? this.borderSoft,
//     );
//   }

//   @override
//   WeatherAdminColors lerp(WeatherAdminColors? other, double t) {
//     if (other is! WeatherAdminColors) return this;
//     return WeatherAdminColors(
//       textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
//       textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
//       textMuted: Color.lerp(textMuted, other.textMuted, t)!,
//       surface: Color.lerp(surface, other.surface, t)!,
//       card: Color.lerp(card, other.card, t)!,
//       elevated: Color.lerp(elevated, other.elevated, t)!,
//       border: Color.lerp(border, other.border, t)!,
//       borderSoft: Color.lerp(borderSoft, other.borderSoft, t)!,
//     );
//   }
// }

// // Convenience extension on BuildContext
// extension ThemeX on BuildContext {
//   WeatherAdminColors get wColors =>
//       Theme.of(this).extension<WeatherAdminColors>() ??
//     (Theme.of(this).brightness == Brightness.dark
//         ? WeatherAdminColors.dark
//         : WeatherAdminColors.light);
//   bool get isDark => Theme.of(this).brightness == Brightness.dark;
// }

// // import 'package:flutter/material.dart';

// // class AppTheme {
// //   // Colors
// //   static const primaryColor = Color(0xFF4A90E2);
// //   static const secondaryColor = Color(0xFF50C878);
// //   static const successColor = Color(0xFF50C878); // Green - for success states
// //   static const dangerColor = Color(0xFFEF5350);
// //   static const warningColor = Color(0xFFFFA726);
// //   static const infoColor = Color(0xFF26C6DA);
  
// //   static const darkBackground = Color(0xFF1A1D1F);
// //   static const darkSurface = Color(0xFF272B30);
// //   static const darkCard = Color(0xFF2D3135);
  
// //   static final lightTheme = ThemeData(
// //     useMaterial3: true,
// //     brightness: Brightness.light,
// //     colorScheme: ColorScheme.light(
// //       primary: primaryColor,
// //       secondary: secondaryColor,
// //       error: dangerColor,
// //       surface: Colors.white,
// //       background: const Color(0xFFF5F7FA),
// //     ),
// //     scaffoldBackgroundColor: const Color(0xFFF5F7FA),
// //     cardTheme: CardThemeData(
// //       elevation: 2,
// //       shape: RoundedRectangleBorder(
// //         borderRadius: BorderRadius.circular(16),
// //       ),
// //     ),
// //     appBarTheme: const AppBarTheme(
// //       backgroundColor: Colors.white,
// //       elevation: 0,
// //       iconTheme: IconThemeData(color: Colors.black87),
// //       titleTextStyle: TextStyle(
// //         color: Colors.black87,
// //         fontSize: 20,
// //         fontWeight: FontWeight.w600,
// //       ),
// //     ),
// //   );
  
// //   static final darkTheme = ThemeData(
// //     useMaterial3: true,
// //     brightness: Brightness.dark,
// //     colorScheme: ColorScheme.dark(
// //       primary: primaryColor,
// //       secondary: secondaryColor,
// //       error: dangerColor,
// //       surface: darkSurface,
// //       background: darkBackground,
// //     ),
// //     scaffoldBackgroundColor: darkBackground,
// //     cardTheme: CardThemeData(
// //       color: darkCard,
// //       elevation: 4,
// //       shape: RoundedRectangleBorder(
// //         borderRadius: BorderRadius.circular(16),
// //       ),
// //     ),
// //     appBarTheme: AppBarTheme(
// //       backgroundColor: darkSurface,
// //       elevation: 0,
// //       iconTheme: const IconThemeData(color: Colors.white),
// //       titleTextStyle: const TextStyle(
// //         color: Colors.white,
// //         fontSize: 20,
// //         fontWeight: FontWeight.w600,
// //       ),
// //     ),
// //   );

// //   static Color? get backgroundColor => null;
// // }