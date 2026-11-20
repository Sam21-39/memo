import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_prefs.dart';

class AppSettings {
  const AppSettings({
    required this.interfaceLocale,
    required this.inputLocale,
    required this.playbackLocale,
    required this.themeMode,
  });

  final String interfaceLocale;
  final String inputLocale;
  final String playbackLocale;
  final String themeMode;

  AppSettings copyWith({
    String? interfaceLocale,
    String? inputLocale,
    String? playbackLocale,
    String? themeMode,
  }) => AppSettings(
    interfaceLocale: interfaceLocale ?? this.interfaceLocale,
    inputLocale: inputLocale ?? this.inputLocale,
    playbackLocale: playbackLocale ?? this.playbackLocale,
    themeMode: themeMode ?? this.themeMode,
  );
}

/// Root state: language prefs and theme. Drives `MaterialApp`.
class AppSettingsCubit extends Cubit<AppSettings> {
  AppSettingsCubit(this._prefs, {this.onLanguageChanged})
    : super(
        AppSettings(
          interfaceLocale: _prefs.interfaceLocale,
          inputLocale: _prefs.inputLocale,
          playbackLocale: _prefs.playbackLocale,
          themeMode: _prefs.themeMode,
        ),
      );

  final AppPrefs _prefs;

  /// V7/V8 pass SyncAlarms so scheduled alarm text follows the language.
  final Future<void> Function()? onLanguageChanged;

  Future<void> setInterfaceLocale(String v) async {
    await _prefs.setInterfaceLocale(v);
    emit(state.copyWith(interfaceLocale: v));
    await onLanguageChanged?.call();
  }

  Future<void> setInputLocale(String v) async {
    await _prefs.setInputLocale(v);
    emit(state.copyWith(inputLocale: v));
  }

  Future<void> setPlaybackLocale(String v) async {
    await _prefs.setPlaybackLocale(v);
    emit(state.copyWith(playbackLocale: v));
    await onLanguageChanged?.call();
  }

  Future<void> setThemeMode(String v) async {
    await _prefs.setThemeMode(v);
    emit(state.copyWith(themeMode: v));
  }
}
