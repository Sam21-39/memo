import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';

import '../features/onboarding/data/onboarding_repository_impl.dart';
import '../features/onboarding/domain/onboarding_repository.dart';
import '../features/reminders/data/alarm/android_alarm_scheduler.dart';
import '../features/reminders/data/alarm/local_notification_scheduler.dart';
import '../features/reminders/data/alarm/native_alarm.dart';
import '../features/reminders/data/media_store.dart';
import '../features/reminders/data/reminder_db.dart';
import '../features/reminders/data/reminder_repository_impl.dart';
import '../features/reminders/data/spoken_reminder.dart';
import '../features/reminders/data/voice_clip.dart';
import '../features/reminders/domain/alarm/alarm_scheduler.dart';
import '../features/reminders/domain/repositories/reminder_repository.dart';
import '../features/reminders/domain/usecases/apply_alarm_action.dart';
import '../features/reminders/domain/usecases/delete_reminder.dart';
import '../features/reminders/domain/usecases/save_reminder.dart';
import '../features/reminders/domain/usecases/sync_alarms.dart';
import 'app_prefs.dart';
import 'feature_flags/feature_flags.dart';
import 'notification_background.dart';

final sl = GetIt.instance;

/// ponytail: plain get_it, no injectable codegen — a dozen registrations do
/// not need a build_runner step.
///
/// Also runs in the iOS background isolate that applies Done / Snooze, so it
/// must not touch anything that needs a widget tree.
Future<void> configureDependencies() async {
  const flags = RemoteFeatureFlags();
  const native = NativeAlarm();
  sl
    ..registerSingleton<FeatureFlags>(flags)
    ..registerSingleton<NativeAlarm>(native);

  final prefs = await AppPrefs.open();
  sl.registerSingleton<AppPrefs>(prefs);

  final media = await MediaStore.open(
    installSound: Platform.isIOS ? native.installSound : null,
    removeSound: Platform.isIOS ? native.removeSound : null,
  );
  sl
    ..registerSingleton<MediaStore>(media)
    ..registerLazySingleton(VoiceClip.new);

  // flutter_local_notifications still owns permission prompts and tap
  // delivery on both platforms; it rings only on iOS.
  final spoken = SpokenReminder(gender: () => prefs.voiceGender);
  sl.registerSingleton(spoken);
  final notifications = LocalNotificationScheduler(
    FlutterLocalNotificationsPlugin(),
    snoozeEnabled: flags.snooze,
    // Read aloud: the rendered chime + voice; else the Memō chime.
    soundFor: (r) async => await spoken.soundFor(r) ?? 'memo_ring.caf',
  );
  await notifications.initialize(onBackground: onBackgroundNotification);
  final AlarmScheduler scheduler = Platform.isAndroid
      ? AndroidAlarmScheduler(native, spoken)
      : notifications;

  final repository = ReminderRepositoryImpl(await ReminderDb.open());
  final save = SaveReminder(repository, scheduler);
  sl
    ..registerSingleton<LocalNotificationScheduler>(notifications)
    ..registerSingleton<AlarmScheduler>(scheduler)
    ..registerSingleton<OnboardingRepository>(
      OnboardingRepositoryImpl(prefs, notifications),
    )
    ..registerSingleton<ReminderRepository>(repository)
    ..registerSingleton(save)
    ..registerSingleton(
      DeleteReminder(repository, scheduler, (id) async {
        await media.deleteFor(id);
        await spoken.forget(id);
      }),
    )
    ..registerSingleton(SyncAlarms(repository, scheduler))
    ..registerSingleton(ApplyAlarmAction(repository, save));
}
