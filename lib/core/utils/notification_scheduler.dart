import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../features/reminders/domain/entities/reminder.dart';
import '../../features/reminders/domain/entities/repeat_rule.dart';

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

/// Thin wrapper over [FlutterLocalNotificationsPlugin]: schedules a reminder's
/// alarm, cancels it, and reports taps. Owns every id and repeat-rule detail
/// so callers only ever pass a [Reminder].
class NotificationScheduler {
  NotificationScheduler(this._plugin, {bool? capPending})
    : _capPending = capPending ?? Platform.isIOS;

  final FlutterLocalNotificationsPlugin _plugin;

  /// iOS only — see [enforcePendingLimit]. Injectable so it can be tested off
  /// a real device.
  final bool _capPending;

  /// Set before [initialize] so a cold start from a notification is not lost.
  void Function(NotificationTap tap)? onTap;

  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(
      tz.getLocation(await FlutterTimezone.getLocalTimezone()),
    );

    await _plugin.initialize(
      InitializationSettings(
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
  Future<void> schedule(Reminder reminder, {bool snoozeEnabled = true}) async {
    await cancel(reminder.id);
    if (reminder.isDone) return;

    final details = _details(snoozeEnabled: snoozeEnabled);
    final base = _baseId(reminder.id);

    switch (reminder.repeat.type) {
      case RepeatType.none:
        // A one-off already in the past has nothing left to fire.
        if (reminder.scheduledAt.isBefore(DateTime.now())) return;
        await _zoned(base, reminder, reminder.scheduledAt, details, null);

      case RepeatType.daily:
        await _zoned(
          base,
          reminder,
          _nextDailyOccurrence(reminder.scheduledAt),
          details,
          DateTimeComponents.time,
        );

      case RepeatType.weekly:
        // One pending notification per picked weekday — the plugin can only
        // match a single day-of-week per schedule.
        final weekdays = reminder.repeat.weekdays.isEmpty
            ? {reminder.scheduledAt.weekday}
            : reminder.repeat.weekdays;
        for (final weekday in weekdays) {
          await _zoned(
            base + weekday,
            reminder,
            _nextWeekdayOccurrence(reminder.scheduledAt, weekday),
            details,
            DateTimeComponents.dayOfWeekAndTime,
          );
        }
    }
  }

  /// iOS keeps only the 64 soonest pending notifications and silently discards
  /// the rest — and never restores a discarded one when earlier alarms fire, so
  /// a reminder past the limit stays permanently silent. Re-register the
  /// soonest that fit whenever [upcoming] asks for more slots than that.
  ///
  /// [upcoming] must be undone reminders, soonest first.
  ///
  /// ponytail: ranks by [Reminder.scheduledAt] alone, so a weekly rule's later
  /// weekdays are counted at its first occurrence. Expand each repeat into real
  /// occurrence times only if a user actually loses an alarm to that.
  Future<void> enforcePendingLimit(
    List<Reminder> upcoming, {
    bool snoozeEnabled = true,
  }) async {
    if (!_capPending) return;

    var needed = 0;
    for (final reminder in upcoming) {
      needed += _slotsFor(reminder);
    }
    if (needed <= _iosPendingLimit) return;

    await _plugin.cancelAll();
    var used = 0;
    for (final reminder in upcoming) {
      final slots = _slotsFor(reminder);
      if (used + slots > _iosPendingLimit) break;
      await schedule(reminder, snoozeEnabled: snoozeEnabled);
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

  Future<void> cancel(String reminderId) async {
    final base = _baseId(reminderId);
    await _plugin.cancel(base);
    for (var weekday = 1; weekday <= 7; weekday++) {
      await _plugin.cancel(base + weekday);
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
      id,
      reminder.title,
      reminder.note,
      tz.TZDateTime.from(when, tz.local),
      details,
      payload: reminder.id,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: matchComponents,
    );
  }

  NotificationDetails _details({required bool snoozeEnabled}) {
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
      iOS: const DarwinNotificationDetails(categoryIdentifier: _iosCategoryId),
    );
  }

  /// Same time of day, today if still ahead, otherwise tomorrow — but never
  /// before the reminder's own start date, so a repeat set to begin next week
  /// does not fire tonight.
  static DateTime _nextDailyOccurrence(DateTime scheduledAt) {
    final now = DateTime.now();
    if (scheduledAt.isAfter(now)) return scheduledAt;

    var next = DateTime(
      now.year,
      now.month,
      now.day,
      scheduledAt.hour,
      scheduledAt.minute,
    );
    if (!next.isAfter(now)) {
      next = DateTime(
        now.year,
        now.month,
        now.day + 1,
        scheduledAt.hour,
        scheduledAt.minute,
      );
    }
    return next;
  }

  static DateTime _nextWeekdayOccurrence(DateTime scheduledAt, int weekday) {
    var next = _nextDailyOccurrence(scheduledAt);
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

  /// Notification ids are ints; reminder ids are strings. Derived, not stored,
  /// and stable across runs — `String.hashCode` is not, so cancel would miss.
  /// Leaves room for `+1..+7` weekday offsets.
  static int _baseId(String reminderId) {
    var hash = 0;
    for (final unit in reminderId.codeUnits) {
      hash = (hash * 31 + unit) % 0x1FFFFFFF;
    }
    return hash * 8 % 0x7FFFFFF0;
  }
}
