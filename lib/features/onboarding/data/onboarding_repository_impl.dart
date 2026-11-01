import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

import '../../../core/app_prefs.dart';
import '../../reminders/data/alarm/ios_alarm_scheduler.dart';
import '../../reminders/data/alarm/local_notification_scheduler.dart';
import '../domain/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  const OnboardingRepositoryImpl(this._prefs, this._scheduler, this._alarmKit);

  final AppPrefs _prefs;
  final LocalNotificationScheduler _scheduler;
  final AlarmKit _alarmKit;

  @override
  Future<bool> isCompleted() async => _prefs.onboardingDone;

  @override
  Future<void> complete() => _prefs.setOnboardingDone();

  @override
  Future<bool> requestNotificationPermission() async {
    if (Platform.isAndroid) {
      // Notification permission (13+) and the exact-alarm grant — without the
      // latter the OS may defer an alarm well past its time.
      await _scheduler.requestAndroidPermissions();
    } else {
      await _scheduler.requestIosPermissions();
      // iOS 26+: real alarms, full screen, through silent and Focus.
      if (await _alarmKit.status() == 'notDetermined') {
        await _alarmKit.authorize();
      }
    }
    return Permission.notification.isGranted;
  }
}
