import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/alarm/alarm_ids.dart';
import '../../domain/alarm/alarm_scheduler.dart';
import '../../domain/alarm/fire_plan.dart';
import '../../domain/entities/reminder.dart';

/// What the user tapped on a delivered notification.
enum NotificationAction { open, done, snooze }

class NotificationTap {
  const NotificationTap(this.reminderId, this.action);
  final String reminderId;
  final NotificationAction action;
}

const _doneActionId = 'memo_done';
const _snoozeActionId = 'memo_snooze';
const _channelId = 'memo_reminders';
const _iosPendingLimit = 64;
const _iosCategoryId = 'memo_reminder';

/// Reads a tap out of a plugin response; null when it carries no reminder.
NotificationTap? tapFromResponse(NotificationResponse? response) {
  final reminderId = response?.payload;
  if (reminderId == null || reminderId.isEmpty) return null;
  return NotificationTap(reminderId, switch (response!.actionId) {
    _doneActionId => NotificationAction.done,
    _snoozeActionId => NotificationAction.snooze,
    _ => NotificationAction.open,
  });
}

/// [AlarmScheduler] over [FlutterLocalNotificationsPlugin]: the iOS
/// implementation (Time Sensitive, burst, voice clip as the sound, 64-slot
/// budget). Android rings through the native AlarmManager scheduler instead.
class LocalNotificationScheduler implements AlarmScheduler {
  LocalNotificationScheduler(
    this._plugin, {
    bool? capPending,
    bool? burst,
    this.snoozeEnabled = true,
    this.soundFor,
  }) : _capPending = capPending ?? Platform.isIOS,
       _burst = burst ?? Platform.isIOS;

  final FlutterLocalNotificationsPlugin _plugin;

  /// Mirrors `FeatureFlags.snooze` — drives the alert's Snooze action.
  final bool snoozeEnabled;

  /// The sound file name to ring with (installed in Library/Sounds), or null
  /// for the default.
  final String? Function(Reminder reminder)? soundFor;

  /// iOS only — see [syncAll]. Injectable so it can be tested off a device.
  final bool _capPending;
  final bool _burst;

  /// Set before [initialize] so a cold start from a notification is not lost.
  void Function(NotificationTap tap)? onTap;

  /// [onBackground] must be a top-level `@pragma('vm:entry-point')` function:
  /// iOS runs Done and Snooze in a background isolate without opening the app.
  Future<void> initialize({
    DidReceiveBackgroundNotificationResponseCallback? onBackground,
  }) async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(
      tz.getLocation((await FlutterTimezone.getLocalTimezone()).identifier),
    );

    await _plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          // Onboarding asks first; this must not prompt on its own.
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          notificationCategories: [
            DarwinNotificationCategory(
              _iosCategoryId,
              actions: [
                DarwinNotificationAction.plain(_doneActionId, 'Done'),
                if (snoozeEnabled)
                  DarwinNotificationAction.plain(_snoozeActionId, 'Snooze 10m'),
              ],
            ),
          ],
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final tap = tapFromResponse(response);
        if (tap != null) onTap?.call(tap);
      },
      onDidReceiveBackgroundNotificationResponse: onBackground,
    );
  }

  /// A notification that launched the app from cold, if any.
  Future<NotificationTap?> launchTap() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return null;
    return tapFromResponse(details!.notificationResponse);
  }

  /// Android 13+ notification permission and the exact-alarm grant. Call
  /// after the in-app primer has explained why.
  Future<void> requestAndroidPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
  }

  Future<void> requestIosPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Replaces any previously scheduled alarms for this reminder.
  @override
  Future<void> schedule(Reminder reminder) async {
    await cancel(reminder.id);
    for (final fire in firesFor(reminder, now: DateTime.now(), burst: _burst)) {
      await _zoned(fire, reminder);
    }
  }

  /// Re-registers every live alarm. iOS keeps only the 64 soonest pending
  /// notifications, silently drops the rest and never restores a dropped one
  /// when earlier alarms fire — so collect every fire across all reminders,
  /// sort by time, register the soonest 64.
  @override
  Future<void> syncAll(List<Reminder> live) async {
    await _plugin.cancelAll();
    final now = DateTime.now();
    final byId = {for (final r in live) r.id: r};
    final fires = [
      for (final r in live) ...firesFor(r, now: now, burst: _burst),
    ]..sort((a, b) => a.at.compareTo(b.at));
    final kept = _capPending ? fires.take(_iosPendingLimit) : fires;
    for (final fire in kept) {
      await _zoned(fire, byId[fire.reminderId]!);
    }
  }

  @override
  Future<void> cancel(String reminderId) async {
    for (final id in AlarmIds.all(reminderId)) {
      await _plugin.cancel(id: id);
    }
    // v1 ids were base + weekday; sweep them so an upgraded install never
    // keeps a stray alarm.
    final base = AlarmIds.base(reminderId);
    for (var weekday = 1; weekday <= 7; weekday++) {
      await _plugin.cancel(id: base + weekday);
    }
  }

  Future<void> _zoned(AlarmFire fire, Reminder reminder) async {
    await _plugin.zonedSchedule(
      id: fire.id,
      title: reminder.title,
      body: reminder.note,
      scheduledDate: tz.TZDateTime.from(fire.at, tz.local),
      notificationDetails: _details(soundFor?.call(reminder)),
      payload: reminder.id,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: switch (fire.repeat) {
        FireRepeat.none => null,
        FireRepeat.daily => DateTimeComponents.time,
        FireRepeat.weekly => DateTimeComponents.dayOfWeekAndTime,
      },
    );
  }

  NotificationDetails _details(String? sound) => NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      'Reminders',
      channelDescription: 'Scheduled reminder alarms',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      actions: [
        const AndroidNotificationAction(
          _doneActionId,
          'Done',
          showsUserInterface: true,
        ),
        if (snoozeEnabled)
          const AndroidNotificationAction(
            _snoozeActionId,
            'Snooze 10m',
            showsUserInterface: true,
          ),
      ],
    ),
    iOS: DarwinNotificationDetails(
      categoryIdentifier: _iosCategoryId,
      interruptionLevel: InterruptionLevel.timeSensitive,
      sound: sound,
    ),
  );
}
