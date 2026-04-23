import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design System Color Tokens
class FemoraColors {
  // Primary Palette
  static const primary = Color(0xFFA66CFF);
  static const primaryDark = Color(0xFF8F4DFF);
  static const primaryLight = Color(0xFFC59DFF);

  // Secondary / Accent
  static const lavenderWhisper = Color(0xFFE9D8FD);
  static const softLilac = Color(0xFFD8B4FE);
  static const lightBackgroundTint = Color(0xFFF6F0FF);

  // Text Colors
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF6B7280);
  static const textLight = Color(0xFFFFFFFF);

  // Semantic
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);

  // Legacy colors (for backwards compatibility)
  static const lavenderMid = Color(0xFFB5A2D8);
  static const lilacSoft = Color(0xFFC8BDD9);
  static const lavenderPale = Color(0xFFD6CFDC);
  static const neutralLight = Color(0xFFD9D9DC);

  // Semantic mapping
  static const background = lightBackgroundTint;
  static const splashCircle = Color(0x2EFFFFFF);
  static const progressActive = primary;
  static const progressTrack = lavenderPale;

  // ── Dark Mode Palette ───────────────────────────────────────────────────────
  // Used when ThemeMode.dark is active.
  // Slight purple tint to feel like Femora, not generic dark mode.
  static const darkBackground    = Color(0xFF0F0F14);  // page background
  static const darkSurface       = Color(0xFF1A1A24);  // card / sheet surface
  static const darkSurfaceRaised = Color(0xFF222232);  // elevated cards
  static const darkBorder        = Color(0xFF2D2D3A);  // dividers, borders
  static const darkTextPrimary   = Color(0xFFF0F0F5);  // main text
  static const darkTextSecondary = Color(0xFF9CA3AF);  // secondary text
  static const darkLavender      = Color(0xFF2A2040);  // lavenderWhisper equivalent
  static const darkNeutral       = Color(0xFF2D2D3A);  // neutralLight equivalent
}

/// Spacing System (8pt Grid)
class FemoraSpacing {
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 16.0;
  static const double lg   = 24.0;
  static const double xl   = 32.0;
  static const double xxl  = 40.0;
  static const double xxxl = 48.0;
}

/// Border Radius Tokens
class FemoraBorderRadius {
  static const double small    = 8.0;
  static const double medium   = 16.0;
  static const double large    = 24.0;
  static const double circular = 999.0;
}

/// Animation Duration Constants
class FemoraAnimations {
  static const Duration fast            = Duration(milliseconds: 150);
  static const Duration normal          = Duration(milliseconds: 300);
  static const Duration slow            = Duration(milliseconds: 600);
  static const Duration splashAnimation = Duration(milliseconds: 900);

  static const Curve easeOut     = Curves.easeOut;
  static const Curve easeOutBack = Curves.easeOutBack;
  static const Curve easeInOut   = Curves.easeInOut;
}

/// Typography Scale (Nunito)
class FemoraTextStyles {
  static TextStyle displayLarge = GoogleFonts.nunito(
    fontSize: 38, fontWeight: FontWeight.w700, height: 1.2);

  static TextStyle headlineLarge = GoogleFonts.nunito(
    fontSize: 28, fontWeight: FontWeight.w600, height: 1.3);

  static TextStyle headlineMedium = GoogleFonts.nunito(
    fontSize: 22, fontWeight: FontWeight.w600, height: 1.3);

  static TextStyle titleLarge = GoogleFonts.nunito(
    fontSize: 18, fontWeight: FontWeight.w500, height: 1.4);

  static TextStyle bodyLarge = GoogleFonts.nunito(
    fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);

  static TextStyle bodyMedium = GoogleFonts.nunito(
    fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);

  static TextStyle bodySmall = GoogleFonts.nunito(
    fontSize: 12, fontWeight: FontWeight.w400, height: 1.4);

  static TextStyle caption = GoogleFonts.nunito(
    fontSize: 12, fontWeight: FontWeight.w400, height: 1.4);
}

class AppTheme {
  // ── Light Theme ───────────────────────────────────────────────────────────
  static ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: FemoraColors.lightBackgroundTint,
    primaryColor: FemoraColors.primary,
    colorScheme: const ColorScheme.light(
      primary:   FemoraColors.primary,
      secondary: FemoraColors.softLilac,
      surface:   Colors.white,
      onPrimary: Colors.white,
      onSurface: FemoraColors.textPrimary,
    ),
    cardColor: Colors.white,
    dividerColor: FemoraColors.lavenderWhisper,
    textTheme: TextTheme(
      displayLarge:  FemoraTextStyles.displayLarge,
      headlineLarge: FemoraTextStyles.headlineLarge,
      bodyMedium:    FemoraTextStyles.bodyMedium,
      bodySmall:     FemoraTextStyles.bodySmall,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: FemoraColors.textPrimary,
      elevation: 0,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? FemoraColors.primary
              : Colors.white),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? FemoraColors.primary.withValues(alpha: 0.4)
              : FemoraColors.neutralLight),
    ),
  );

  // ── Dark Theme ────────────────────────────────────────────────────────────
  static ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: FemoraColors.darkBackground,
    primaryColor: FemoraColors.primary,
    colorScheme: const ColorScheme.dark(
      primary:   FemoraColors.primary,
      secondary: FemoraColors.primaryLight,
      surface:   FemoraColors.darkSurface,
      onPrimary: Colors.white,
      onSurface: FemoraColors.darkTextPrimary,
    ),
    cardColor: FemoraColors.darkSurface,
    dividerColor: FemoraColors.darkBorder,
    textTheme: TextTheme(
      displayLarge:  FemoraTextStyles.displayLarge
          .copyWith(color: FemoraColors.darkTextPrimary),
      headlineLarge: FemoraTextStyles.headlineLarge
          .copyWith(color: FemoraColors.darkTextPrimary),
      bodyMedium:    FemoraTextStyles.bodyMedium
          .copyWith(color: FemoraColors.darkTextPrimary),
      bodySmall:     FemoraTextStyles.bodySmall
          .copyWith(color: FemoraColors.darkTextPrimary),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: FemoraColors.darkSurface,
      foregroundColor: FemoraColors.darkTextPrimary,
      elevation: 0,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? FemoraColors.primary
              : FemoraColors.darkTextSecondary),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? FemoraColors.primary.withValues(alpha: 0.4)
              : FemoraColors.darkBorder),
    ),
  );
}
