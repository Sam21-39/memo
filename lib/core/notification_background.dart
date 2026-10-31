import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../features/reminders/data/alarm/local_notification_scheduler.dart';
import '../features/reminders/domain/usecases/apply_alarm_action.dart';
import '../features/reminders/domain/usecases/sync_alarms.dart';
import 'di.dart';

/// iOS runs Done and Snooze from a delivered alert here, in a background
/// isolate, without opening the app. The isolate has no widget tree, so it
/// builds the same graph and writes through the same use cases.
@pragma('vm:entry-point')
Future<void> onBackgroundNotification(NotificationResponse response) async {
  final tap = tapFromResponse(response);
  if (tap == null || tap.action == NotificationAction.open) return;
  DartPluginRegistrant.ensureInitialized();
  await configureDependencies();
  await sl<ApplyAlarmAction>()(
    tap.reminderId,
    tap.action == NotificationAction.done
        ? AlarmAction.done
        : AlarmAction.snooze,
    DateTime.now(),
  );
  await sl<SyncAlarms>()();
}
