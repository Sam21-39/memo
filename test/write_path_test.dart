import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/reminders/domain/alarm/alarm_scheduler.dart';
import 'package:memo/features/reminders/domain/entities/occurrence.dart';
import 'package:memo/features/reminders/domain/entities/repeat_rule.dart';
import 'package:memo/features/reminders/domain/test_reminder.dart';
import 'package:memo/features/reminders/domain/usecases/apply_alarm_action.dart';
import 'package:memo/features/reminders/domain/usecases/complete_reminder.dart';
import 'package:memo/features/reminders/domain/usecases/delete_reminder.dart';
import 'package:memo/features/reminders/domain/usecases/save_reminder.dart';
import 'package:memo/features/reminders/domain/usecases/snooze_reminder.dart';
import 'package:memo/features/reminders/domain/usecases/sync_alarms.dart';

import 'fakes.dart';

void main() {
  historyTests();
  group('SaveReminder', () {
    test('writes, then schedules the same reminder', () async {
      final repo = InMemoryRepository();
      final scheduler = FakeScheduler();
      await SaveReminder(repo, scheduler)(
        reminder('a', 'Bins', DateTime(2026, 11, 3, 7)),
      );
      expect(repo.all.single.id, 'a');
      expect(scheduler.scheduled.single.id, 'a');
    });

    test('a schedule failure flags the row and tells the caller', () async {
      final repo = InMemoryRepository();
      final scheduler = FakeScheduler()..fail = true;
      await expectLater(
        SaveReminder(repo, scheduler)(
          reminder('a', 'Bins', DateTime(2026, 11, 3, 7)),
        ),
        throwsA(isA<ScheduleFailure>()),
      );
      expect(repo.all.single.needsSchedule, isTrue);
    });

    test('a successful save clears an old needs_schedule flag', () async {
      final repo = InMemoryRepository();
      await SaveReminder(repo, FakeScheduler())(
        reminder(
          'a',
          'Bins',
          DateTime(2026, 11, 3, 7),
        ).copyWith(needsSchedule: true),
      );
      expect(repo.all.single.needsSchedule, isFalse);
    });
  });

  test(
    'DeleteReminder cancels alarms, removes the row and its media',
    () async {
      final repo = InMemoryRepository([
        reminder('a', 'Bins', DateTime(2026, 11, 3, 7)),
      ]);
      final scheduler = FakeScheduler();
      final mediaDeleted = <String>[];
      await DeleteReminder(repo, scheduler, (id) async => mediaDeleted.add(id))(
        'a',
      );
      expect(repo.all, isEmpty);
      expect(scheduler.cancelled, ['a']);
      expect(mediaDeleted, ['a']);
    },
  );

  group('SyncAlarms', () {
    final now = DateTime(2026, 11, 10, 9);

    test('a repeat one cycle late stays overdue', () async {
      final repo = InMemoryRepository([
        reminder(
          'd',
          'Pills',
          DateTime(2026, 11, 10, 8),
          repeat: RepeatRule.daily,
        ),
      ]);
      await SyncAlarms(repo, FakeScheduler())(now: now);
      expect(repo.all.single.dueAt, DateTime(2026, 11, 10, 8));
    });

    test('a repeat 3 cycles behind rolls to its next real time', () async {
      final repo = InMemoryRepository([
        reminder(
          'd',
          'Pills',
          DateTime(2026, 11, 7, 8),
          repeat: RepeatRule.daily,
        ),
      ]);
      await SyncAlarms(repo, FakeScheduler())(now: now);
      expect(repo.all.single.dueAt, DateTime(2026, 11, 11, 8));
    });

    test('re-registers every live reminder, soonest first', () async {
      final repo = InMemoryRepository([
        reminder('late', 'B', DateTime(2026, 11, 12)),
        reminder('soon', 'A', DateTime(2026, 11, 11)),
        reminder(
          'done',
          'C',
          DateTime(2026, 11, 1),
          doneAt: DateTime(2026, 11, 1),
        ),
      ]);
      final scheduler = FakeScheduler();
      await SyncAlarms(repo, scheduler)(now: now);
      expect(scheduler.synced!.map((r) => r.id), ['soon', 'late']);
    });

    test('clears needs_schedule once re-registered', () async {
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

  test('completing a repeat resets nags and never sets done_at', () {
    final r = reminder(
      'd',
      'Pills',
      DateTime(2026, 11, 10, 8),
      repeat: RepeatRule.daily,
    ).copyWith(nagMin: 10, nagCount: 4);
    final next = const CompleteReminder()(
      r,
      now: DateTime(2026, 11, 10, 8, 30),
    );
    expect(next.doneAt, isNull);
    expect(next.nagCount, 0);
    expect(next.dueAt, DateTime(2026, 11, 11, 8));
  });

  group('snoozing a repeat', () {
    final r = reminder(
      'd',
      'Pills',
      DateTime(2026, 11, 10, 20),
      repeat: RepeatRule.daily,
    );
    final now = DateTime(2026, 11, 10, 20, 2);

    test('keeps the series time and sets a snooze', () {
      final s = const SnoozeReminder()(
        r,
        now: now,
        by: const Duration(minutes: 10),
      );
      expect(s.dueAt, DateTime(2026, 11, 10, 20));
      expect(s.snoozedUntil, DateTime(2026, 11, 10, 20, 12));
      expect(s.ringsAt, DateTime(2026, 11, 10, 20, 12));
    });

    test('Done after a snooze clears it and moves to tomorrow', () {
      final s = const SnoozeReminder()(
        r,
        now: now,
        by: const Duration(minutes: 10),
      );
      final done = const CompleteReminder()(
        s,
        now: DateTime(2026, 11, 10, 20, 13),
      );
      expect(done.snoozedUntil, isNull);
      expect(done.dueAt, DateTime(2026, 11, 11, 20));
    });

    test('a one-off snooze still moves its own time', () {
      final one = reminder('o', 'Bins', DateTime(2026, 11, 10, 20));
      final s = const SnoozeReminder()(
        one,
        now: now,
        by: const Duration(minutes: 10),
      );
      expect(s.dueAt, DateTime(2026, 11, 10, 20, 12));
      expect(s.snoozedUntil, isNull);
    });
  });
}

class _PruneFails extends InMemoryRepository {
  _PruneFails(super.reminders);

  @override
  Future<void> pruneOccurrences(DateTime before) async =>
      throw StateError('prune');
}

void historyTests() {
  final due = DateTime(2026, 11, 9, 8);
  final tap = DateTime(2026, 11, 9, 8, 5);
  final daily = reminder('d', 'Pills', due, repeat: RepeatRule.daily);

  group('history: Done and Snooze', () {
    test('done on a daily writes one done row keyed by the old due', () async {
      final repo = InMemoryRepository([daily]);
      await SaveReminder(repo, FakeScheduler()).done(daily, tap);
      expect(repo.log.single.event, OccurrenceEvent.done);
      expect(repo.log.single.dueAt, due);
      expect(repo.log.single.at, tap);
      expect(repo.all.single.dueAt, DateTime(2026, 11, 10, 8));
    });

    test('a failed schedule does not duplicate the history', () async {
      final repo = InMemoryRepository([daily]);
      final scheduler = FakeScheduler()..fail = true;
      await expectLater(
        SaveReminder(repo, scheduler).done(daily, tap),
        throwsA(isA<ScheduleFailure>()),
      );
      expect(repo.log, hasLength(1));
      expect(repo.all.single.needsSchedule, isTrue);
    });

    test('one-off and memo-test write nothing', () async {
      final once = reminder('o', 'x', due);
      final test = reminder(testReminderId, 'x', due, repeat: RepeatRule.daily);
      final repo = InMemoryRepository([once, test]);
      final save = SaveReminder(repo, FakeScheduler());
      await save.done(once, tap);
      await save.done(test, tap);
      await save.snooze(test, tap, by: const Duration(minutes: 10));
      expect(repo.log, isEmpty);
    });

    test('snooze on a repeat records until', () async {
      final repo = InMemoryRepository([daily]);
      await SaveReminder(
        repo,
        FakeScheduler(),
      ).snooze(daily, tap, by: const Duration(minutes: 10));
      expect(repo.log.single.event, OccurrenceEvent.snoozed);
      expect(repo.log.single.until, tap.add(const Duration(minutes: 10)));
    });

    test('ApplyAlarmAction stores the tap time of a day-old Done', () async {
      final repo = InMemoryRepository([daily]);
      await ApplyAlarmAction(repo, SaveReminder(repo, FakeScheduler()))(
        'd',
        AlarmAction.done,
        tap,
      );
      expect(repo.log.single.dueAt, due);
      expect(repo.log.single.at, tap);
    });
  });

  test('Done and Snooze only go through the SaveReminder funnel', () {
    const allowed = [
      'save_reminder.dart',
      'detail_page.dart',
      'snooze_sheet.dart',
    ];
    final offenders = [
      for (final f in Directory('lib').listSync(recursive: true))
        if (f is File &&
            f.path.endsWith('.dart') &&
            !allowed.any(f.path.endsWith) &&
            RegExp(
              r'(CompleteReminder|SnoozeReminder)\(\)\(',
            ).hasMatch(f.readAsStringSync()))
          f.path,
    ];
    expect(offenders, isEmpty);
  });

  group('history: SyncAlarms', () {
    final now = DateTime(2026, 11, 10, 9);

    test('three cycles behind writes open rows once', () async {
      final behind = daily.copyWith(dueAt: DateTime(2026, 11, 7, 8));
      final repo = InMemoryRepository([behind]);
      final sync = SyncAlarms(repo, FakeScheduler());
      await sync(now: now);
      expect(repo.log.map((o) => o.event), everyElement(OccurrenceEvent.open));
      expect(repo.log.map((o) => o.dueAt), [
        DateTime(2026, 11, 7, 8),
        DateTime(2026, 11, 8, 8),
        DateTime(2026, 11, 9, 8),
        DateTime(2026, 11, 10, 8),
      ]);
      await sync(now: now);
      expect(repo.log, hasLength(4));
    });

    test('one cycle behind writes none', () async {
      final repo = InMemoryRepository([
        daily.copyWith(dueAt: DateTime(2026, 11, 10, 8)),
      ]);
      await SyncAlarms(repo, FakeScheduler())(now: now);
      expect(repo.log, isEmpty);
    });

    test('rows older than 90 days are pruned', () async {
      final repo = InMemoryRepository([
        daily.copyWith(dueAt: DateTime(2026, 11, 11, 8)),
      ]);
      repo.log.addAll([
        Occurrence(
          reminderId: 'd',
          dueAt: now.subtract(const Duration(days: 91)),
          event: OccurrenceEvent.done,
          at: now,
        ),
        Occurrence(
          reminderId: 'd',
          dueAt: now.subtract(const Duration(days: 89)),
          event: OccurrenceEvent.done,
          at: now,
        ),
      ]);
      await SyncAlarms(repo, FakeScheduler())(now: now);
      expect(repo.log, hasLength(1));
    });

    test('a throwing prune still reaches syncAll', () async {
      final scheduler = FakeScheduler();
      await SyncAlarms(_PruneFails([daily]), scheduler)(now: now);
      expect(scheduler.synced, isNotNull);
    });
  });
}
