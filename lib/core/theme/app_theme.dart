import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// ThemeData built from "memo Design System.dc.html" · 02 Type / 04 Components.
/// Instrument Sans for anything a person reads; IBM Plex Mono for anything a
/// clock produces (times, dates, counts, section labels).
class AppTheme {
  AppTheme._();

  /// Bundled in assets/fonts, declared in pubspec.yaml.
  static const sansFamily = 'Instrument Sans';
  static const monoFamily = 'IBM Plex Mono';

  static TextTheme _textTheme(
    Brightness brightness,
    Color ink,
    Color ink70,
    Color ink45,
  ) {
    final typography = Typography.material2021();
    final sans =
        (brightness == Brightness.light ? typography.black : typography.white)
            .apply(fontFamily: sansFamily);
    const mono = TextStyle(fontFamily: monoFamily);
    return sans.copyWith(
      displayLarge: sans.displayLarge?.copyWith(
        fontSize: 34,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.02 * 34,
        color: ink,
      ),
      titleLarge: sans.titleLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.015 * 22,
        color: ink,
      ),
      bodyLarge: sans.bodyLarge?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        color: ink,
      ),
      bodyMedium: sans.bodyMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: ink70,
      ),
      labelMedium: mono.copyWith(fontSize: 13, color: ink70),
      labelSmall: mono.copyWith(
        fontSize: 11,
        letterSpacing: 0.12 * 11,
        color: ink45,
      ),
    );
  }

  static ThemeData get light {
    const ink = AppColors.ink;
    const ink70 = AppColors.ink70;
    const ink45 = AppColors.ink45;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.canvas,
      canvasColor: AppColors.canvas,
      colorScheme: const ColorScheme.light(
        surface: AppColors.surface,
        primary: AppColors.accent,
        onPrimary: AppColors.surface,
        secondary: AppColors.accentSoft,
        onSecondary: AppColors.accentPressed,
        outline: AppColors.hairline,
        onSurface: ink,
      ),
      textTheme: _textTheme(Brightness.light, ink, ink70, ink45),
      dividerColor: AppColors.hairline,
      dividerTheme: const DividerThemeData(
        color: AppColors.hairline,
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: AppColors.surface,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          textStyle: const TextStyle(
            fontFamily: sansFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: const BorderSide(color: Color(0xFFD8D5CE)),
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          textStyle: const TextStyle(
            fontFamily: sansFamily,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.accent
              : const Color(0xFFE0DED7),
        ),
      ),
    );
  }

  static ThemeData get dark {
    const ink = AppColors.inkDark;
    final ink70 = AppColors.inkDark.withValues(alpha: 0.7);
    final ink45 = AppColors.inkDark.withValues(alpha: 0.45);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.canvasDark,
      canvasColor: AppColors.canvasDark,
      colorScheme: ColorScheme.dark(
        surface: AppColors.surfaceDark,
        primary: AppColors.accentDark,
        onPrimary: AppColors.canvasDark,
        secondary: AppColors.accentDark.withValues(alpha: 0.16),
        onSecondary: AppColors.accentDark,
        outline: AppColors.hairlineDark,
        onSurface: ink,
      ),
      textTheme: _textTheme(Brightness.dark, ink, ink70, ink45),
      dividerColor: AppColors.hairlineDark,
      dividerTheme: const DividerThemeData(
        color: AppColors.hairlineDark,
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: AppColors.canvasDark,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          textStyle: const TextStyle(
            fontFamily: sansFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: const BorderSide(color: Color(0xFF3A3936)),
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          textStyle: const TextStyle(
            fontFamily: sansFamily,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.accentDark
              : const Color(0xFF3A3936),
        ),
      ),
    );
  }
}
