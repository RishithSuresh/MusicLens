import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color baseWhite = Color(0xFFF8FAFC);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFFEEF2F7);

  static const Color electricBlue = Color(0xFF3B82F6);
  static const Color neonPurple = Color(0xFF8B5CF6);
  static const Color softPink = Color(0xFFEC4899);

  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.spaceGroteskTextTheme().apply(
      bodyColor: const Color(0xFF111827),
      displayColor: const Color(0xFF0F172A),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: baseWhite,
      colorScheme: const ColorScheme.light(
        primary: electricBlue,
        secondary: neonPurple,
        tertiary: softPink,
        surface: pureWhite,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: pureWhite.withValues(alpha: 0.75),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: pureWhite.withValues(alpha: 0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD8E2F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD8E2F0)),
        ),
      ),
    );
  }
}
