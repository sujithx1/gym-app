import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GymTheme {
  // Soft, Editorial Light Theme Palette
  static const Color background = Color(0xFFF6F6F4); // Warm Off-White
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF0F0ED);
  static const Color border = Color(0xFFE8E8E5);

  // Soft Pastel Card Accents
  static const Color mint = Color(0xFFDDF3EC);
  static const Color lavender = Color(0xFFE8DDF5);
  static const Color peach = Color(0xFFF7DDD0);
  static const Color blue = Color(0xFFDCEAF5);
  static const Color yellow = Color(0xFFF4E9C8);

  // Primary & Secondary Brand Colors
  static const Color primary = Color(0xFF171717); // Rich Dark Charcoal
  static const Color primaryGlow = Color(0x1A171717);
  static const Color secondary = Color(0xFF777777);

  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFF5A623);
  static const Color danger = Color(0xFFE53935);

  static const Color textPrimary = Color(0xFF171717); // Dark Charcoal Text
  static const Color textSecondary = Color(0xFF777777);
  static const Color textMuted = Color(0xFF999999);

  static ThemeData get lightTheme {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: danger,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w800, fontSize: 36, letterSpacing: -0.5),
          titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w800, fontSize: 24, letterSpacing: -0.3),
          titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 17),
          bodyLarge: TextStyle(color: textPrimary, fontSize: 15, height: 1.4),
          bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
          labelSmall: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(color: textPrimary, fontWeight: FontWeight.w800, fontSize: 20),
      ),
    );
  }
}

