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
    this.overlay,
    this.dictation,
    this.voiceGender = 'female',
    this.defaultNagMin,
    this.readAloudDefault = true,
  });

  /// Null until read.
  final bool? notifications;

  /// Android only; null elsewhere.
  final bool? exactAlarms;

  /// Android 14+: the alarm may take over the lock screen. Null elsewhere.
  final bool? fullScreen;

  /// Android: may take the screen while unlocked. Null elsewhere.
  final bool? overlay;

  /// On-device speech-to-text exists here. Null until read.
  final bool? dictation;
  final String voiceGender;
  final int? defaultNagMin;
  final bool readAloudDefault;
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
    bool? fullScreen, overlay;
    if (Platform.isAndroid) {
      try {
        fullScreen = await _native.canUseFullScreenIntent();
        overlay = await _native.canDrawOverlays();
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
        overlay: overlay,
        dictation: dictation,
        voiceGender: _prefs.voiceGender,
        defaultNagMin: _prefs.defaultNagMin,
        readAloudDefault: _prefs.readAloudDefault,
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

  Future<void> toggleReadAloud() async {
    await _prefs.setReadAloudDefault(!_prefs.readAloudDefault);
    await refresh();
  }

  Future<void> setDefaultNag(int? minutes) async {
    await _prefs.setDefaultNagMin(minutes);
    await refresh();
  }

  Future<void> openOverlaySettings() async {
    await _native.openOverlaySettings();
    await refresh();
  }

  Future<void> setVoiceGender(String gender) async {
    await _prefs.setVoiceGender(gender);
    await refresh();
  }
}
