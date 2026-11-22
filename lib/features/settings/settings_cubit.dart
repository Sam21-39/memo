import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/app_prefs.dart';
import '../../l10n/l10n.dart';
import '../reminders/data/alarm/ios_alarm_scheduler.dart';
import '../reminders/data/alarm/native_alarm.dart';
import '../reminders/domain/alarm/alarm_scheduler.dart';
import '../reminders/domain/entities/reminder.dart';
import '../reminders/domain/test_reminder.dart';
import '../reminders/domain/usecases/delete_reminder.dart';
import '../reminders/domain/usecases/save_reminder.dart';

enum HealthStatus { allowed, ok, fix, off }

class HealthItem {
  const HealthItem(this.id, this.status);
  final String id;
  final HealthStatus status;

  bool get needsFix => status == HealthStatus.fix || status == HealthStatus.off;
}

class SettingsState {
  const SettingsState({
    this.android = false,
    this.ios = false,
    this.notifications,
    this.exactAlarms,
    this.fullScreen,
    this.overlay,
    this.batteryUnrestricted,
    this.maker = '',
    this.alarmKit,
    this.lastTestAt,
    this.testFailed = false,
    this.defaultNagMin,
    this.readAloudDefault = true,
    this.voiceGender = 'female',
  });

  final bool android;
  final bool ios;

  /// Null until read.
  final bool? notifications;

  /// Android only; null elsewhere.
  final bool? exactAlarms;

  /// Android 14+: the alarm may take over the lock screen. Null elsewhere.
  final bool? fullScreen;

  /// Android: may take the screen while unlocked. Null elsewhere.
  final bool? overlay;

  /// Android: null when the OS could not say.
  final bool? batteryUnrestricted;
  final String maker;

  /// iOS 26+: 'authorized', 'denied' or 'notDetermined'. Null where AlarmKit
  /// does not exist.
  final String? alarmKit;
  final DateTime? lastTestAt;

  /// The last test alarm could not be scheduled.
  final bool testFailed;
  final int? defaultNagMin;
  final bool readAloudDefault;
  final String voiceGender;

  /// One item per thing that affects whether a reminder rings.
  List<HealthItem> get health {
    HealthItem granted(String id, bool? v, HealthStatus bad) =>
        HealthItem(id, v == true ? HealthStatus.allowed : bad);
    if (android) {
      return [
        granted('notifications', notifications, HealthStatus.off),
        granted('exactAlarms', exactAlarms, HealthStatus.off),
        if (fullScreen != null)
          granted('fullScreen', fullScreen, HealthStatus.fix),
        if (overlay != null) granted('overlay', overlay, HealthStatus.fix),
        if (batteryUnrestricted != null)
          granted('battery', batteryUnrestricted, HealthStatus.fix),
      ];
    }
    if (ios) {
      final kit = alarmKit;
      return [
        if (kit != null)
          HealthItem(
            'alarms',
            kit == 'authorized'
                ? HealthStatus.allowed
                : kit == 'notDetermined'
                ? HealthStatus.fix
                : HealthStatus.off,
          ),
        granted('notifications', notifications, HealthStatus.off),
        // Before iOS 26 there is no alarm permission to fix: informational.
        HealthItem(
          'focus',
          kit == null
              ? HealthStatus.ok
              : kit == 'authorized'
              ? HealthStatus.allowed
              : HealthStatus.fix,
        ),
        const HealthItem('backgroundRefresh', HealthStatus.ok),
      ];
    }
    return const [];
  }

  int get toFix => health.where((i) => i.needsFix).length;
}

/// Permission states are read live and refreshed when the app resumes, since
/// the user changes them in the OS settings app.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(
    this._prefs,
    this._native,
    this._save,
    this._delete, {
    this._alarms = const AlarmKit(),
    bool? android,
    bool? ios,
  }) : _android = android ?? Platform.isAndroid,
       _ios = ios ?? Platform.isIOS,
       super(const SettingsState());

  final AppPrefs _prefs;
  final NativeAlarm _native;
  final SaveReminder _save;
  final DeleteReminder _delete;
  final AlarmKit _alarms;
  final bool _android;
  final bool _ios;

  Future<void> refresh({bool testFailed = false}) async {
    final notifications = await Permission.notification.isGranted;
    final exact = _android
        ? await Permission.scheduleExactAlarm.isGranted
        : null;
    bool? fullScreen, overlay, battery;
    var maker = '';
    if (_android) {
      try {
        fullScreen = await _native.canUseFullScreenIntent();
        overlay = await _native.canDrawOverlays();
      } on NativeAlarmError {
        fullScreen = overlay = null;
      }
      try {
        final b = await _native.battery();
        battery = b.unrestricted;
        maker = b.maker;
      } on NativeAlarmError {
        battery = null;
      }
    }
    final kit = _ios ? await _alarms.status() : 'unavailable';
    if (isClosed) return;
    emit(
      SettingsState(
        android: _android,
        ios: _ios,
        notifications: notifications,
        exactAlarms: exact,
        fullScreen: fullScreen,
        overlay: overlay,
        batteryUnrestricted: battery,
        maker: maker,
        alarmKit: kit == 'unavailable' ? null : kit,
        lastTestAt: _prefs.lastTestAt,
        testFailed: testFailed,
        defaultNagMin: _prefs.defaultNagMin,
        readAloudDefault: _prefs.readAloudDefault,
        voiceGender: _prefs.voiceGender,
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

  Future<void> openOverlaySettings() async {
    await _native.openOverlaySettings();
    await refresh();
  }

  Future<void> openBatterySettings() async {
    try {
      await _native.openBatterySettings();
    } on NativeAlarmError {
      // The row stays; refresh still reads the real state.
    }
    await refresh();
  }

  Future<void> requestAlarms() async {
    if (await _alarms.status() == 'notDetermined') {
      await _alarms.authorize();
    } else {
      await openAppSettings();
    }
    await refresh();
  }

  /// Opens whichever system screen fixes the health item [id].
  Future<void> fix(String id) => switch (id) {
    'notifications' => requestNotifications(),
    'exactAlarms' => requestExactAlarms(),
    'fullScreen' => openFullScreenSettings(),
    'overlay' => openOverlaySettings(),
    'battery' => openBatterySettings(),
    'alarms' || 'focus' => requestAlarms(),
    _ => Future.value(),
  };

  /// A real reminder with a fixed id, through the normal save path, so the
  /// test rings exactly like production.
  Future<void> ringTest() async {
    final now = DateTime.now();
    try {
      await _save(
        Reminder(
          id: testReminderId,
          title: l10n().testAlarmTitle,
          dueAt: now.add(const Duration(seconds: 10)),
          createdAt: now,
          nagMin: null,
          // The speech plan decides per title and phone; no voice, no speech.
          readAloud: _prefs.readAloudDefault,
        ),
      );
    } on ScheduleFailure {
      await _delete(testReminderId);
      await refresh(testFailed: true);
      return;
    }
    await _prefs.setLastTestAt(now);
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

  Future<void> setVoiceGender(String gender) async {
    await _prefs.setVoiceGender(gender);
    await refresh();
  }
}
