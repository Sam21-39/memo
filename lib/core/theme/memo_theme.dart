import 'package:flutter/material.dart';

import 'tokens.dart';

/// ThemeData from the generated tokens. Widgets read colours through
/// `MemoColors.of(context)` and type through [MemoType]; this only wires the
/// Material defaults (scaffold, buttons, inputs, dialogs) so stock widgets
/// already look like Memō.
abstract final class MemoTheme {
  static ThemeData get light => _build(MemoColors.light, Brightness.light);
  static ThemeData get dark => _build(MemoColors.dark, Brightness.dark);

  static ThemeData _build(MemoColors c, Brightness brightness) {
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(MemoRadius.card),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: MemoType.sans,
      scaffoldBackgroundColor: c.canvas,
      canvasColor: c.canvas,
      splashFactory: NoSplash.splashFactory,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: c.accent,
        onPrimary: c.onAccent,
        secondary: c.ink,
        onSecondary: c.onInk,
        error: c.destructive,
        onError: c.onAccent,
        surface: c.surface,
        onSurface: c.ink,
        outline: c.hairline,
        surfaceContainerHighest: c.ink6,
      ),
      textTheme: TextTheme(
        displayLarge: MemoType.display.copyWith(color: c.ink),
        titleLarge: MemoType.title.copyWith(color: c.ink),
        bodyLarge: MemoType.bodyLarge.copyWith(color: c.ink),
        bodyMedium: MemoType.body.copyWith(color: c.ink70),
        labelLarge: MemoType.button.copyWith(color: c.ink),
        labelMedium: MemoType.labelMedium.copyWith(color: c.ink70),
        labelSmall: MemoType.labelSmall.copyWith(color: c.ink45),
      ),
      dividerTheme: DividerThemeData(color: c.hairline, thickness: 1, space: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: c.ink,
          foregroundColor: c.onInk,
          minimumSize: const Size.fromHeight(50),
          shape: cardShape,
          textStyle: MemoType.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.ink,
          side: BorderSide(color: c.hairline),
          minimumSize: const Size.fromHeight(50),
          shape: cardShape,
          textStyle: MemoType.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.accent,
          minimumSize: const Size(MemoSpace.hitMin, MemoSpace.hitMin),
          textStyle: MemoType.button.copyWith(fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        hintStyle: MemoType.body.copyWith(color: c.ink45),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: MemoSpace.space4,
          vertical: MemoSpace.space3,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MemoRadius.card),
          borderSide: BorderSide(color: c.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MemoRadius.card),
          borderSide: BorderSide(color: c.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MemoRadius.card),
          borderSide: BorderSide(color: c.ink45),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(cursorColor: c.accent),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: MemoType.title.copyWith(color: c.ink),
        contentTextStyle: MemoType.body.copyWith(color: c.ink70),
      ),
      extensions: [c],
    );
  }
}
