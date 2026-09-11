import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GymTheme {
  // Soft, Editorial Light Theme Palette (Inspired by Reference Design)
  static const Color background = Color(0xFFF4EFEA); // Warm Editorial Ivory
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFEFE8E1);
  static const Color border = Color(0xFFE5DDD3);

  // Soft Pastel Card Tokens (Matching Reference Image)
  static const Color periwinkle = Color(0xFFC5C6F6); // Soft Periwinkle Blue
  static const Color yellow = Color(0xFFF5DE82);     // Warm Golden Yellow
  static const Color mint = Color(0xFFC2E2D2);       // Botanical Sage Mint
  static const Color peach = Color(0xFFF5DCD1);      // Soft Blush Peach
  static const Color lavender = Color(0xFFE3D8F5);   // Editorial Soft Lavender
  static const Color blue = Color(0xFFC5C6F6);       // Alias for periwinkle

  // Dark Accent Colors for badges/arrows inside pastel cards
  static const Color periwinkleDark = Color(0xFF8688E2);
  static const Color yellowDark = Color(0xFFDDB43D);
  static const Color mintDark = Color(0xFF7CB699);
  static const Color peachDark = Color(0xFFD49983);

  // Primary & Secondary Brand Colors
  static const Color primary = Color(0xFF191919); // Rich Dark Charcoal
  static const Color primaryGlow = Color(0x1A191919);
  static const Color secondary = Color(0xFF7A7A7A);

  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFF5A623);
  static const Color danger = Color(0xFFE53935);

  static const Color textPrimary = Color(0xFF191919); // Dark Charcoal Text
  static const Color textSecondary = Color(0xFF7A7A7A);
  static const Color textMuted = Color(0xFF9E9E9E);

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
          borderRadius: BorderRadius.circular(28),
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

