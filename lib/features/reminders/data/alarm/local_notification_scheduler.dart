import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/alarm/alarm_ids.dart';
import '../../domain/alarm/alarm_scheduler.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/repeat_rule.dart';

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

/// [AlarmScheduler] over [FlutterLocalNotificationsPlugin]: the iOS
/// implementation, and Android's until the native AlarmManager one lands.
/// Also reports notification taps. Owns every repeat-rule detail so callers
/// only ever pass a [Reminder].
class LocalNotificationScheduler implements AlarmScheduler {
  LocalNotificationScheduler(
    this._plugin, {
    bool? capPending,
    this.snoozeEnabled = true,
  }) : _capPending = capPending ?? Platform.isIOS;

  /// Mirrors `FeatureFlags.snooze` — drives the alert's Snooze action.
  final bool snoozeEnabled;

  final FlutterLocalNotificationsPlugin _plugin;

  /// iOS only — see [syncAll]. Injectable so it can be tested off a device.
  final bool _capPending;

  /// Set before [initialize] so a cold start from a notification is not lost.
  void Function(NotificationTap tap)? onTap;

  Future<void> initialize() async {
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
                DarwinNotificationAction.plain(_snoozeActionId, 'Snooze'),
              ],
            ),
          ],
        ),
      ),
      onDidReceiveNotificationResponse: _handleResponse,
    );
  }

  void _handleResponse(NotificationResponse response) {
    final reminderId = response.payload;
    if (reminderId == null || reminderId.isEmpty) return;
    onTap?.call(
      NotificationTap(reminderId, switch (response.actionId) {
        _doneActionId => NotificationAction.done,
        _snoozeActionId => NotificationAction.snooze,
        _ => NotificationAction.open,
      }),
    );
  }

  /// A notification that launched the app from cold, if any.
  Future<NotificationTap?> launchTap() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    final response = details?.notificationResponse;
    if (details?.didNotificationLaunchApp != true ||
        response?.payload == null) {
      return null;
    }
    return NotificationTap(response!.payload!, switch (response.actionId) {
      _doneActionId => NotificationAction.done,
      _snoozeActionId => NotificationAction.snooze,
      _ => NotificationAction.open,
    });
  }

  /// Android 13+ notification permission and the exact-alarm grant. Call after
  /// the in-app primer has explained why.
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
    await _register(reminder);
  }

  Future<void> _register(Reminder reminder) async {
    if (reminder.isDone) return;
    final details = _details();
    final id = reminder.id;

    switch (reminder.repeat.type) {
      case RepeatType.none:
        // A one-off already in the past has nothing left to fire.
        if (reminder.dueAt.isBefore(DateTime.now())) return;
        await _zoned(
          AlarmIds.main(id),
          reminder,
          reminder.dueAt,
          details,
          null,
        );

      case RepeatType.daily:
        await _zoned(
          AlarmIds.main(id),
          reminder,
          _nextDailyOccurrence(reminder.dueAt),
          details,
          DateTimeComponents.time,
        );

      case RepeatType.weekly:
        // One pending notification per picked weekday — the plugin can only
        // match a single day-of-week per schedule.
        final weekdays = reminder.repeat.weekdays.isEmpty
            ? {reminder.dueAt.weekday}
            : reminder.repeat.weekdays;
        for (final weekday in weekdays) {
          await _zoned(
            AlarmIds.weekday(id, weekday),
            reminder,
            _nextWeekdayOccurrence(reminder.dueAt, weekday),
            details,
            DateTimeComponents.dayOfWeekAndTime,
          );
        }
    }
  }

  /// Re-registers every live alarm. iOS keeps only the 64 soonest pending
  /// notifications and silently discards the rest — and never restores a
  /// discarded one when earlier alarms fire — so only the soonest that fit
  /// are registered there.
  ///
  /// [live] must be undone reminders, soonest first.
  ///
  /// ponytail: ranks by [Reminder.dueAt] alone, so a weekly rule's later
  /// weekdays are counted at its first occurrence. Expand each repeat into
  /// real fire times when nag lands (M3), which needs that list anyway.
  @override
  Future<void> syncAll(List<Reminder> live) async {
    await _plugin.cancelAll();
    var used = 0;
    for (final reminder in live) {
      final slots = _slotsFor(reminder);
      if (_capPending && used + slots > _iosPendingLimit) break;
      await _register(reminder);
      used += slots;
    }
  }

  /// A weekly rule costs one pending notification per picked weekday — the
  /// plugin can only match a single day-of-week per schedule.
  int _slotsFor(Reminder reminder) =>
      reminder.repeat.type == RepeatType.weekly &&
          reminder.repeat.weekdays.isNotEmpty
      ? reminder.repeat.weekdays.length
      : 1;

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

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<void> _zoned(
    int id,
    Reminder reminder,
    DateTime when,
    NotificationDetails details,
    DateTimeComponents? matchComponents,
  ) async {
    await _plugin.zonedSchedule(
      id: id,
      title: reminder.title,
      body: reminder.note,
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      notificationDetails: details,
      payload: reminder.id,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: matchComponents,
    );
  }

  NotificationDetails _details() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'Reminders',
        channelDescription: 'Scheduled reminder alarms',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        actions: [
          // showsUserInterface brings the app up so the action runs against the
          // real database.
          // ponytail: no background isolate handler — Done/Snooze open the app
          // to apply. Add one only if acting without launching matters.
          const AndroidNotificationAction(
            _doneActionId,
            'Done',
            showsUserInterface: true,
          ),
          if (snoozeEnabled)
            const AndroidNotificationAction(
              _snoozeActionId,
              'Snooze',
              showsUserInterface: true,
            ),
        ],
      ),
      iOS: const DarwinNotificationDetails(
        categoryIdentifier: _iosCategoryId,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
  }

  /// Same time of day, today if still ahead, otherwise tomorrow — but never
  /// before the reminder's own start date, so a repeat set to begin next week
  /// does not fire tonight.
  static DateTime _nextDailyOccurrence(DateTime dueAt) {
    final now = DateTime.now();
    if (dueAt.isAfter(now)) return dueAt;

    var next = DateTime(now.year, now.month, now.day, dueAt.hour, dueAt.minute);
    if (!next.isAfter(now)) {
      next = DateTime(
        now.year,
        now.month,
        now.day + 1,
        dueAt.hour,
        dueAt.minute,
      );
    }
    return next;
  }

  static DateTime _nextWeekdayOccurrence(DateTime dueAt, int weekday) {
    var next = _nextDailyOccurrence(dueAt);
    while (next.weekday != weekday) {
      next = DateTime(
        next.year,
        next.month,
        next.day + 1,
        next.hour,
        next.minute,
      );
    }
    return next;
  }
}
