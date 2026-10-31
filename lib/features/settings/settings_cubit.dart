import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/app_prefs.dart';
import '../reminders/data/alarm/native_alarm.dart';
import '../reminders/data/speech_to_text.dart';

class SettingsState {
  const SettingsState({
    this.notifications,
    this.exactAlarms,
    this.fullScreen,
    this.dictation,
    this.defaultNagMin,
    this.voiceRingsDefault = true,
  });

  /// Null until read.
  final bool? notifications;

  /// Android only; null elsewhere.
  final bool? exactAlarms;

  /// Android 14+: the alarm may take over the lock screen. Null elsewhere.
  final bool? fullScreen;

  /// On-device speech-to-text exists here. Null until read.
  final bool? dictation;
  final int? defaultNagMin;
  final bool voiceRingsDefault;
}

/// Permission states are read live and refreshed when the app resumes, since
/// the user changes them in the OS settings app.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._prefs, this._native, [this._stt = const SpeechToText()])
    : super(const SettingsState());

  final AppPrefs _prefs;
  final NativeAlarm _native;
  final SpeechToText _stt;

  Future<void> refresh() async {
    final notifications = await Permission.notification.isGranted;
    final exact = Platform.isAndroid
        ? await Permission.scheduleExactAlarm.isGranted
        : null;
    bool? fullScreen;
    if (Platform.isAndroid) {
      try {
        fullScreen = await _native.canUseFullScreenIntent();
      } on NativeAlarmError {
        fullScreen = null;
      }
    }
    final dictation = await _stt.available();
    if (isClosed) return;
    emit(
      SettingsState(
        notifications: notifications,
        exactAlarms: exact,
        fullScreen: fullScreen,
        dictation: dictation,
        defaultNagMin: _prefs.defaultNagMin,
        voiceRingsDefault: _prefs.voiceRingsDefault,
      ),
    );
  }

  Future<void> requestNotifications() async {
    if (state.notifications == true) {
      await openAppSettings();
    } else if (await Permission.notification.request().isPermanentlyDenied) {
      await openAppSettings();
    }
    await refresh();
  }

  Future<void> requestExactAlarms() async {
    await Permission.scheduleExactAlarm.request();
    await refresh();
  }

  Future<void> openFullScreenSettings() async {
    await _native.openFullScreenSettings();
    await refresh();
  }

  Future<void> toggleVoiceRings() async {
    await _prefs.setVoiceRingsDefault(!_prefs.voiceRingsDefault);
    await refresh();
  }

  Future<void> setDefaultNag(int? minutes) async {
    await _prefs.setDefaultNagMin(minutes);
    await refresh();
  }
}
