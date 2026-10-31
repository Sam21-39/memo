import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/app_prefs.dart';

class SettingsState {
  const SettingsState({
    this.notifications,
    this.exactAlarms,
    this.defaultNagMin,
    this.voiceRingsDefault = true,
  });

  /// Null until read.
  final bool? notifications;

  /// Android only; null elsewhere.
  final bool? exactAlarms;
  final int? defaultNagMin;
  final bool voiceRingsDefault;
}

/// Permission states are read live and refreshed when the app resumes, since
/// the user changes them in the OS settings app.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._prefs) : super(const SettingsState());

  final AppPrefs _prefs;

  Future<void> refresh() async {
    final notifications = await Permission.notification.isGranted;
    final exact = Platform.isAndroid
        ? await Permission.scheduleExactAlarm.isGranted
        : null;
    if (isClosed) return;
    emit(
      SettingsState(
        notifications: notifications,
        exactAlarms: exact,
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
}
