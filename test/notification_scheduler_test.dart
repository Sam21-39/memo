import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/utils/notification_scheduler.dart';
import 'package:memo/features/reminders/domain/entities/reminder.dart';
import 'package:memo/features/reminders/domain/entities/repeat_rule.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class _ScheduledCall {
  _ScheduledCall(this.id, this.when, this.matchComponents, this.payload);
  final int id;
  final tz.TZDateTime when;
  final DateTimeComponents? matchComponents;
  final String? payload;

  /// The scheduler picks occurrences in host-local time and hands the plugin
  /// the same instant in `tz.local` (UTC here). Assert on this, not on [when]:
  /// otherwise every date check flips a day whenever the host's offset pushes
  /// the UTC equivalent over midnight, and the suite passes or fails by the
  /// hour it is run at. `when.toLocal()` will not do — on a `TZDateTime` that
  /// means `tz.local`, which is the UTC we are converting back out of.
  DateTime get localWhen =>
      DateTime.fromMillisecondsSinceEpoch(when.millisecondsSinceEpoch);
}

/// Records calls instead of touching a platform channel. `noSuchMethod`
/// absorbs the rest of the plugin surface, so no mocking package is needed.
class _FakePlugin implements FlutterLocalNotificationsPlugin {
  final scheduled = <_ScheduledCall>[];
  final cancelled = <int>[];

  @override
  Future<void> zonedSchedule(
    int id,
    String? title,
    String? body,
    tz.TZDateTime scheduledDate,
    NotificationDetails notificationDetails, {
    required UILocalNotificationDateInterpretation
    uiLocalNotificationDateInterpretation,
    required AndroidScheduleMode androidScheduleMode,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    scheduled.add(
      _ScheduledCall(id, scheduledDate, matchDateTimeComponents, payload),
    );
  }

  @override
  Future<void> cancel(int id, {String? tag}) async => cancelled.add(id);

  @override
  Future<void> cancelAll() async => scheduled.clear();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Reminder _reminder({
  required DateTime scheduledAt,
  RepeatRule repeat = RepeatRule.none,
  bool isDone = false,
  String id = 'abc123',
}) => Reminder(
  id: id,
  title: 'Water the fig tree',
  scheduledAt: scheduledAt,
  createdAt: DateTime(2026, 8, 1),
  repeat: repeat,
  isDone: isDone,
);

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));
  });

  late _FakePlugin plugin;
  late NotificationScheduler scheduler;

  setUp(() {
    plugin = _FakePlugin();
    scheduler = NotificationScheduler(plugin);
  });

  DateTime future() => DateTime.now().add(const Duration(days: 2));
  DateTime past() => DateTime.now().subtract(const Duration(days: 2));

  test('a future one-off schedules once, with no repeat matching', () async {
    await scheduler.schedule(_reminder(scheduledAt: future()));

    expect(plugin.scheduled, hasLength(1));
    expect(plugin.scheduled.single.matchComponents, isNull);
    expect(plugin.scheduled.single.payload, 'abc123');
  });

  test('a one-off already in the past schedules nothing', () async {
    await scheduler.schedule(_reminder(scheduledAt: past()));
    expect(plugin.scheduled, isEmpty);
  });

  test('a completed reminder schedules nothing', () async {
    await scheduler.schedule(_reminder(scheduledAt: future(), isDone: true));
    expect(plugin.scheduled, isEmpty);
  });

  test('a daily repeat matches on time of day', () async {
    await scheduler.schedule(
      _reminder(scheduledAt: past(), repeat: RepeatRule.daily),
    );

    expect(plugin.scheduled, hasLength(1));
    expect(plugin.scheduled.single.matchComponents, DateTimeComponents.time);
  });

  test('a daily repeat starting later waits for its start date', () async {
    final start = future();
    await scheduler.schedule(
      _reminder(scheduledAt: start, repeat: RepeatRule.daily),
    );

    // Must not fire tonight just because the time of day has passed.
    expect(plugin.scheduled.single.localWhen.day, start.day);
  });

  test('a weekly repeat schedules one notification per picked day', () async {
    await scheduler.schedule(
      _reminder(
        scheduledAt: past(),
        repeat: const RepeatRule(RepeatType.weekly, weekdays: {1, 3, 5}),
      ),
    );

    expect(plugin.scheduled, hasLength(3));
    expect(plugin.scheduled.map((c) => c.localWhen.weekday).toSet(), {1, 3, 5});
    for (final call in plugin.scheduled) {
      expect(call.matchComponents, DateTimeComponents.dayOfWeekAndTime);
    }
  });

  test(
    'scheduling replaces any previous alarms for the same reminder',
    () async {
      await scheduler.schedule(_reminder(scheduledAt: future()));
      // Base id plus the seven weekday slots.
      expect(plugin.cancelled, hasLength(8));
    },
  );

  test('ids are stable across scheduler instances so cancel matches', () async {
    await scheduler.schedule(_reminder(scheduledAt: future()));
    final scheduledId = plugin.scheduled.single.id;

    final other = _FakePlugin();
    await NotificationScheduler(other).cancel('abc123');

    expect(other.cancelled, contains(scheduledId));
  });

  group('iOS pending limit', () {
    late NotificationScheduler capped;

    setUp(() => capped = NotificationScheduler(plugin, capPending: true));

    List<Reminder> oneOffs(int count) => [
      for (var i = 1; i <= count; i++)
        _reminder(
          id: 'r$i',
          scheduledAt: DateTime.now().add(Duration(days: i)),
        ),
    ];

    test('under the limit nothing is re-registered', () async {
      await capped.enforcePendingLimit(oneOffs(64));
      expect(plugin.scheduled, isEmpty);
    });

    test('over the limit the soonest 64 are kept', () async {
      await capped.enforcePendingLimit(oneOffs(70));

      expect(plugin.scheduled, hasLength(64));
      expect(plugin.scheduled.map((c) => c.payload), [
        for (var i = 1; i <= 64; i++) 'r$i',
      ]);
    });

    test('a weekly repeat is charged one slot per picked weekday', () async {
      final weekly = _reminder(
        id: 'weekly',
        scheduledAt: DateTime.now().add(const Duration(minutes: 5)),
        repeat: const RepeatRule(RepeatType.weekly, weekdays: {1, 2, 3, 4, 5}),
      );

      await capped.enforcePendingLimit([weekly, ...oneOffs(62)]);

      // 5 weekday slots + 59 one-offs, not 1 + 63.
      expect(plugin.scheduled, hasLength(64));
      expect(plugin.scheduled.map((c) => c.payload), isNot(contains('r60')));
    });

    test('off iOS the limit is not enforced', () async {
      await NotificationScheduler(
        plugin,
        capPending: false,
      ).enforcePendingLimit(oneOffs(70));
      expect(plugin.scheduled, isEmpty);
    });
  });

  test('different reminders do not share notification ids', () async {
    await scheduler.schedule(_reminder(scheduledAt: future()));

    final otherPlugin = _FakePlugin();
    final otherReminder = Reminder(
      id: 'xyz789',
      title: 'Bins out',
      scheduledAt: future(),
      createdAt: DateTime(2026, 8, 1),
    );
    await NotificationScheduler(otherPlugin).schedule(otherReminder);

    expect(plugin.scheduled.single.id, isNot(otherPlugin.scheduled.single.id));
  });
}
