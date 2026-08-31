import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/notification_scheduler.dart';
import '../domain/onboarding_repository.dart';

const _completedKey = 'onboarding_completed';

class OnboardingRepositoryImpl implements OnboardingRepository {
  const OnboardingRepositoryImpl(this._scheduler);

  final NotificationScheduler _scheduler;

  @override
  Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completedKey) ?? false;
  }

  @override
  Future<void> complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
  }

  @override
  Future<bool> requestNotificationPermission() async {
    if (Platform.isAndroid) {
      // Notification permission (13+) and the exact-alarm grant — without the
      // latter the OS may defer an alarm well past its time.
      await _scheduler.requestAndroidPermissions();
    } else {
      await _scheduler.requestIosPermissions();
    }
    return Permission.notification.isGranted;
  }
}
