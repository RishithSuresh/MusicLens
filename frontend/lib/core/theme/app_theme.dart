import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Provided brand palette
  static const Color tan = Color(0xFFD6AC88);
  static const Color antiqueBrass = Color(0xFFC58D69);
  static const Color capePalliser = Color(0xFF9A6449);
  static const Color buccaneer = Color(0xFF63342D);
  static const Color cocoaBrown = Color(0xFF322525);

  static const Color paper = Color(0xFFF7EBDD);
  static const Color ivory = Color(0xFFFFF8EF);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [antiqueBrass, capePalliser],
  );

  static const LinearGradient vibrantGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [tan, antiqueBrass, capePalliser],
  );

  static const LinearGradient stageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [cocoaBrown, buccaneer],
  );

  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.spaceGroteskTextTheme().apply(
      bodyColor: paper,
      displayColor: ivory,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: cocoaBrown,
      colorScheme: const ColorScheme.dark(
        primary: antiqueBrass,
        secondary: tan,
        tertiary: capePalliser,
        surface: buccaneer,
        inverseSurface: paper,
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
        color: buccaneer.withValues(alpha: 0.78),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: antiqueBrass,
          foregroundColor: cocoaBrown,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 8,
          shadowColor: capePalliser.withValues(alpha: 0.4),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cocoaBrown.withValues(alpha: 0.65),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: tan.withValues(alpha: 0.35)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: tan.withValues(alpha: 0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: antiqueBrass, width: 1.5),
        ),
        labelStyle: TextStyle(color: tan.withValues(alpha: 0.9)),
        hintStyle: TextStyle(color: tan.withValues(alpha: 0.75)),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: antiqueBrass,
        inactiveTrackColor: capePalliser,
        thumbColor: tan,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStatePropertyAll(tan.withValues(alpha: 0.95)),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return antiqueBrass.withValues(alpha: 0.55);
          }
          return buccaneer.withValues(alpha: 0.8);
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cocoaBrown.withValues(alpha: 0.96),
        contentTextStyle: const TextStyle(color: paper),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
