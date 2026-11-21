import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/reminders/data/rewall_repeats.dart';
import 'package:memo/features/reminders/domain/entities/occurrence.dart';
import 'package:memo/features/reminders/domain/entities/reminder.dart';
import 'package:memo/features/reminders/domain/entities/repeat_rule.dart';
import 'package:memo/features/reminders/domain/usecases/complete_reminder.dart';
import 'package:memo/features/reminders/domain/usecases/reopen_reminder.dart';
import 'package:memo/features/reminders/domain/usecases/create_reminder.dart';
import 'package:memo/features/reminders/domain/usecases/snooze_reminder.dart';
import 'package:memo/features/reminders/domain/usecases/sync_alarms.dart';

import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'fakes.dart';

Reminder _reminder({
  DateTime? dueAt,
  RepeatRule repeat = RepeatRule.none,
  DateTime? doneAt,
}) {
  final at = dueAt ?? DateTime(2026, 8, 26, 8, 30);
  return Reminder(
    id: '1',
    title: 'Water the fig tree',
    dueAt: at,
    createdAt: DateTime(2026, 8, 1),
    repeat: repeat,
    doneAt: doneAt,
  );
}

void main() {
  group('CreateReminder', () {
    const create = CreateReminder();

    test('trims the title and drops a blank note', () {
      final result = create(
        title: '  Renew passport  ',
        dueAt: DateTime(2026, 8, 27, 9, 30),
        now: DateTime(2026, 8, 26, 12),
        note: '   ',
      );
      expect(result.title, 'Renew passport');
      expect(result.note, isNull);
      expect(result.isDone, isFalse);
    });
  });

  group('SnoozeReminder', () {
    const snooze = SnoozeReminder();

    test('a duration preset offsets from now', () {
      final now = DateTime(2026, 8, 26, 10);
      final result = snooze(
        _reminder(),
        now: now,
        by: const Duration(minutes: 10),
      );
      expect(result.dueAt, DateTime(2026, 8, 26, 10, 10));
    });

    test('tomorrow keeps the reminder own time of day', () {
      final result = snooze(
        _reminder(dueAt: DateTime(2026, 8, 26, 8, 30)),
        now: DateTime(2026, 8, 26, 10),
      );
      expect(result.dueAt, DateTime(2026, 8, 27, 8, 30));
    });

    test('until wins over by; a repeat only gets snoozedUntil', () {
      final now = DateTime(2026, 8, 26, 10);
      final at = DateTime(2026, 8, 26, 15, 5);
      expect(
        snooze(
          _reminder(),
          now: now,
          by: const Duration(hours: 1),
          until: at,
        ).dueAt,
        at,
      );
      final r = snooze(
        _reminder(repeat: RepeatRule.daily),
        now: now,
        until: at,
      );
      expect(r.snoozedUntil, at);
      expect(r.dueAt, _reminder(repeat: RepeatRule.daily).dueAt);
    });

    test('a past until clamps to a minute from now', () {
      final now = DateTime(2026, 8, 26, 10);
      final result = snooze(
        _reminder(),
        now: now,
        until: DateTime(2026, 8, 26, 9, 50),
      );
      expect(result.dueAt, DateTime(2026, 8, 26, 10, 1));
    });

    test('reopens a completed reminder', () {
      final result = snooze(
        _reminder(doneAt: DateTime(2026, 8, 20)),
        now: DateTime(2026, 8, 26, 10),
        by: const Duration(hours: 1),
      );
      expect(result.isDone, isFalse);
    });
  });

  group('CompleteReminder', () {
    const complete = CompleteReminder();

    test('a one-off is marked done', () {
      final result = complete(_reminder(), now: DateTime(2026, 8, 26, 9));
      expect(result.isDone, isTrue);
    });

    test('a daily repeat advances instead of archiving', () {
      final result = complete(
        _reminder(repeat: RepeatRule.daily),
        now: DateTime(2026, 8, 26, 9),
      );
      expect(result.isDone, isFalse);
      expect(result.dueAt, DateTime(2026, 8, 27, 8, 30));
    });

    test('a stale repeat rolls forward past now, not just one step', () {
      // Scheduled three days ago; completing it today must land in the future.
      final result = complete(
        _reminder(
          dueAt: DateTime(2026, 8, 23, 8, 30),
          repeat: RepeatRule.daily,
        ),
        now: DateTime(2026, 8, 26, 9),
      );
      expect(result.dueAt.isAfter(DateTime(2026, 8, 26, 9)), isTrue);
      expect(result.dueAt, DateTime(2026, 8, 27, 8, 30));
    });
  });

  group('RepeatRule.nextAfter', () {
    test('weekly picks the next selected weekday', () {
      // 26 Aug 2026 is a Wednesday; repeat on Mon/Wed/Fri.
      const rule = RepeatRule(RepeatType.weekly, weekdays: {1, 3, 5});
      final next = rule.nextAfter(DateTime(2026, 8, 26, 7));
      expect(next, DateTime(2026, 8, 28, 7)); // Friday
    });

    test('weekly wraps around the week when only one day is picked', () {
      const rule = RepeatRule(RepeatType.weekly, weekdays: {3});
      final next = rule.nextAfter(DateTime(2026, 8, 26, 7));
      expect(next, DateTime(2026, 9, 2, 7));
    });

    test('weekly with no day picked never fires again', () {
      const rule = RepeatRule(RepeatType.weekly);
      expect(rule.nextAfter(DateTime(2026, 8, 26)), isNull);
    });

    test('none never fires again', () {
      expect(RepeatRule.none.nextAfter(DateTime(2026, 8, 26)), isNull);
    });
  });

  group('ReopenReminder', () {
    const reopen = ReopenReminder();

    test('a past one-off moves to the next whole hour and is not done', () {
      final result = reopen(
        _reminder(
          dueAt: DateTime(2026, 8, 20, 8),
          doneAt: DateTime(2026, 8, 20, 9),
        ),
        now: DateTime(2026, 8, 26, 14, 30),
      );
      expect(result.isDone, isFalse);
      expect(result.dueAt, DateTime(2026, 8, 26, 15));
    });

    test('a future one-off keeps its dueAt', () {
      final due = DateTime(2026, 8, 30, 9);
      final result = reopen(
        _reminder(dueAt: due, doneAt: DateTime(2026, 8, 20)),
        now: DateTime(2026, 8, 26, 14, 30),
      );
      expect(result.isDone, isFalse);
      expect(result.dueAt, due);
    });
  });

  group('SyncAlarms', () {
    final now = DateTime(2026, 11, 10, 9);

    test('a failing scheduler leaves needsSchedule set', () async {
      final repo = InMemoryRepository([
        reminder(
          'a',
          'A',
          DateTime(2026, 11, 11),
        ).copyWith(needsSchedule: true),
      ]);
      final scheduler = FakeScheduler()..failSync = true;
      await expectLater(
        SyncAlarms(repo, scheduler)(now: now),
        throwsA(isA<StateError>()),
      );
      expect(repo.all.single.needsSchedule, isTrue);
    });

    test('an edit saved during syncAll is not overwritten', () async {
      final repo = InMemoryRepository([
        reminder(
          'a',
          'A',
          DateTime(2026, 11, 11),
        ).copyWith(needsSchedule: true),
      ]);
      final scheduler = _EditingScheduler(repo);
      await SyncAlarms(repo, scheduler)(now: now);
      expect(repo.all.single.title, 'Edited');
      expect(repo.all.single.needsSchedule, isFalse);
    });

    test('a successful sync clears needsSchedule', () async {
      final repo = InMemoryRepository([
        reminder(
          'a',
          'A',
          DateTime(2026, 11, 11),
        ).copyWith(needsSchedule: true),
      ]);
      await SyncAlarms(repo, FakeScheduler())(now: now);
      expect(repo.all.single.needsSchedule, isFalse);
    });
  });

  group('RewallRepeats', () {
    test('a daily 07:00 keeps 07:00 wall time in the new zone', () async {
      tz_data.initializeTimeZones();
      final kolkata = tz.getLocation('Asia/Kolkata');
      final london = tz.getLocation('Europe/London');
      final at = DateTime.fromMillisecondsSinceEpoch(
        tz.TZDateTime(kolkata, 2026, 11, 20, 7).millisecondsSinceEpoch,
      );
      final repo = InMemoryRepository([
        reminder('d', 'Pills', at, repeat: RepeatRule.daily),
      ]);
      await RewallRepeats(repo)('Asia/Kolkata', 'Europe/London');
      expect(
        repo.all.single.dueAt.millisecondsSinceEpoch,
        tz.TZDateTime(london, 2026, 11, 20, 7).millisecondsSinceEpoch,
      );
    });

    test(
      'a 02:30 repeat in a spring-forward gap still lands near 02:30',
      () async {
        tz_data.initializeTimeZones();
        final london = tz.getLocation('Europe/London');
        final ny = tz.getLocation('America/New_York');
        final at = DateTime.fromMillisecondsSinceEpoch(
          tz.TZDateTime(london, 2026, 3, 8, 2, 30).millisecondsSinceEpoch,
        );
        final repo = InMemoryRepository([
          reminder('g', 'Gap', at, repeat: RepeatRule.daily),
        ]);
        await RewallRepeats(repo)('Europe/London', 'America/New_York');
        final moved = repo.all.single.dueAt;
        // 02:30 does not exist in New York that morning; the package picks an
        // instant, and it must still be within an hour of the wall time.
        expect(
          moved.millisecondsSinceEpoch,
          tz.TZDateTime(ny, 2026, 3, 8, 2, 30).millisecondsSinceEpoch,
        );
        final nearby = tz.TZDateTime(ny, 2026, 3, 8, 3, 30);
        expect(moved.difference(nearby.toLocal()).inHours.abs() <= 1, isTrue);
      },
    );

    test('one-offs keep their instant', () async {
      tz_data.initializeTimeZones();
      final kolkata = tz.getLocation('Asia/Kolkata');
      final at = DateTime.fromMillisecondsSinceEpoch(
        tz.TZDateTime(kolkata, 2026, 11, 20, 7).millisecondsSinceEpoch,
      );
      final repo = InMemoryRepository([reminder('o', 'Once', at)]);
      await RewallRepeats(repo)('Asia/Kolkata', 'Europe/London');
      expect(repo.all.single.dueAt, at);
    });

    test(
      'a failure midway leaves earlier rows moved, the rest untouched',
      () async {
        tz_data.initializeTimeZones();
        final kolkata = tz.getLocation('Asia/Kolkata');
        final london = tz.getLocation('Europe/London');
        DateTime at(int hour) => DateTime.fromMillisecondsSinceEpoch(
          tz.TZDateTime(kolkata, 2026, 11, 20, hour).millisecondsSinceEpoch,
        );
        final repo = _FlakyRepository([
          reminder('a', 'A', at(7), repeat: RepeatRule.daily),
          reminder('b', 'B', at(8), repeat: RepeatRule.daily),
        ]);
        await expectLater(
          RewallRepeats(repo)('Asia/Kolkata', 'Europe/London'),
          throwsA(isA<StateError>()),
        );
        final byId = {for (final r in repo.all) r.id: r};
        expect(
          byId['a']!.dueAt.millisecondsSinceEpoch,
          tz.TZDateTime(london, 2026, 11, 20, 7).millisecondsSinceEpoch,
        );
        expect(byId['b']!.dueAt, at(8));
      },
    );
  });
}

/// Fails its second save, so a re-wall stops halfway.
class _FlakyRepository extends InMemoryRepository {
  _FlakyRepository(super.reminders);
  int _saves = 0;

  @override
  Future<void> save(
    Reminder reminder, {
    List<Occurrence> log = const [],
  }) async {
    if (++_saves == 2) throw StateError('db');
    await super.save(reminder, log: log);
  }
}

/// Saves the user's edit while the native sync is still running.
class _EditingScheduler extends FakeScheduler {
  _EditingScheduler(this._repo);
  final InMemoryRepository _repo;

  @override
  Future<void> syncAll(List<Reminder> live) async {
    await super.syncAll(live);
    await _repo.save(reminder('a', 'Edited', DateTime(2026, 11, 11)));
  }
}
