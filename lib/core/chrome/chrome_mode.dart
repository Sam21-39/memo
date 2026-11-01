import 'package:flutter/material.dart';

/// Glass or solid, decided once at the root. Screens never branch on
/// platform: they place chrome, and [MemoChrome] asks this scope.
enum ChromeMode { glass, solid }

class ChromeModeScope extends InheritedWidget {
  const ChromeModeScope({super.key, required this.mode, required super.child});

  final ChromeMode mode;

  /// iOS and macOS glass, Android solid; high contrast or Reduce
  /// Transparency force solid everywhere.
  static ChromeMode resolve({
    required TargetPlatform platform,
    required bool highContrast,
    required bool reduceTransparency,
  }) {
    if (highContrast || reduceTransparency) return ChromeMode.solid;
    return switch (platform) {
      TargetPlatform.iOS || TargetPlatform.macOS => ChromeMode.glass,
      _ => ChromeMode.solid,
    };
  }

  static ChromeMode of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ChromeModeScope>()?.mode ??
      ChromeMode.solid;

  @override
  bool updateShouldNotify(ChromeModeScope old) => old.mode != mode;
}
