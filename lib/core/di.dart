import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';

import '../features/onboarding/data/onboarding_repository_impl.dart';
import '../features/onboarding/domain/onboarding_repository.dart';
import '../features/reminders/data/alarm/local_notification_scheduler.dart';
import '../features/reminders/data/media_store.dart';
import '../features/reminders/data/reminder_db.dart';
import '../features/reminders/data/reminder_repository_impl.dart';
import '../features/reminders/domain/alarm/alarm_scheduler.dart';
import '../features/reminders/domain/repositories/reminder_repository.dart';
import '../features/reminders/domain/usecases/delete_reminder.dart';
import '../features/reminders/domain/usecases/save_reminder.dart';
import '../features/reminders/domain/usecases/sync_alarms.dart';
import 'app_prefs.dart';
import 'feature_flags/feature_flags.dart';

final sl = GetIt.instance;

/// ponytail: plain get_it, no injectable codegen — a dozen registrations do
/// not need a build_runner step.
Future<void> configureDependencies() async {
  const flags = RemoteFeatureFlags();
  sl.registerSingleton<FeatureFlags>(flags);

  final prefs = await AppPrefs.open();
  sl.registerSingleton<AppPrefs>(prefs);

  final notifications = LocalNotificationScheduler(
    FlutterLocalNotificationsPlugin(),
    snoozeEnabled: flags.snooze,
  );
  await notifications.initialize();
  sl
    ..registerSingleton<LocalNotificationScheduler>(notifications)
    ..registerSingleton<AlarmScheduler>(notifications)
    ..registerSingleton<OnboardingRepository>(
      OnboardingRepositoryImpl(prefs, notifications),
    );

  final media = await MediaStore.open();
  final repository = ReminderRepositoryImpl(await ReminderDb.open());
  sl
    ..registerSingleton<MediaStore>(media)
    ..registerSingleton<ReminderRepository>(repository)
    ..registerSingleton(SaveReminder(repository, notifications))
    ..registerSingleton(
      DeleteReminder(repository, notifications, media.deleteFor),
    )
    ..registerSingleton(SyncAlarms(repository, notifications));
}
