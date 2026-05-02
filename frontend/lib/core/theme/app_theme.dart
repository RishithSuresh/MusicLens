import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Refined color palette with better depth
  static const Color baseWhite = Color(0xFFFAFBFC);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFFEEF2F7);

  // Premium accent colors
  static const Color electricBlue = Color(0xFF3B82F6);
  static const Color deepBlue = Color(0xFF1E40AF);
  static const Color neonPurple = Color(0xFF8B5CF6);
  static const Color deepPurple = Color(0xFF6D28D9);
  static const Color softPink = Color(0xFFEC4899);
  static const Color brightCyan = Color(0xFF06B6D4);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [electricBlue, neonPurple],
  );

  static const LinearGradient vibrantGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [softPink, electricBlue, neonPurple],
  );

  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.spaceGroteskTextTheme().apply(
      bodyColor: const Color(0xFF0F172A),
      displayColor: const Color(0xFF000814),
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
        inverseSurface: Color(0xFF1E293B),
        scrim: Color(0xFF000000),
      ),
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -1.0,
        ),
        displayMedium: textTheme.displayMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: pureWhite.withValues(alpha: 0.75),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: electricBlue,
          foregroundColor: pureWhite,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 8,
          shadowColor: electricBlue.withValues(alpha: 0.4),
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
