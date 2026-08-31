import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';

import '../../features/onboarding/data/onboarding_repository_impl.dart';
import '../../features/onboarding/domain/onboarding_repository.dart';
import '../../features/reminders/data/datasources/app_database.dart';
import '../../features/reminders/data/datasources/reminder_local_datasource.dart';
import '../../features/reminders/data/repositories/reminder_repository_impl.dart';
import '../../features/reminders/domain/repositories/reminder_repository.dart';
import '../feature_flags/feature_flags.dart';
import '../utils/notification_scheduler.dart';

final sl = GetIt.instance;

/// ponytail: plain get_it, no injectable codegen — a dozen registrations do
/// not need a build_runner step.
Future<void> configureDependencies() async {
  sl.registerSingleton<FeatureFlags>(const RemoteFeatureFlags());

  final scheduler = NotificationScheduler(FlutterLocalNotificationsPlugin());
  await scheduler.initialize();
  sl.registerSingleton<NotificationScheduler>(scheduler);

  sl.registerSingleton<OnboardingRepository>(
    OnboardingRepositoryImpl(scheduler),
  );

  final database = await AppDatabase.open();
  sl.registerSingleton<AppDatabase>(database);
  sl.registerSingleton<ReminderRepository>(
    ReminderRepositoryImpl(ReminderLocalDatasource(database)),
  );
}
