import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/reminders/domain/alarm/alarm_scheduler.dart';
import 'package:memo/features/reminders/domain/entities/repeat_rule.dart';
import 'package:memo/features/reminders/domain/usecases/complete_reminder.dart';
import 'package:memo/features/reminders/domain/usecases/delete_reminder.dart';
import 'package:memo/features/reminders/domain/usecases/save_reminder.dart';
import 'package:memo/features/reminders/domain/usecases/snooze_reminder.dart';
import 'package:memo/features/reminders/domain/usecases/sync_alarms.dart';

import 'fakes.dart';

void main() {
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
