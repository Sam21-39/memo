import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/reminders/domain/entities/occurrence.dart';
import 'package:memo/features/reminders/domain/entities/repeat_rule.dart';
import 'package:memo/features/reminders/domain/test_reminder.dart';

import 'fakes.dart';

void main() {
  final daily = RepeatRule.daily;
  final d8 = DateTime(2026, 11, 7, 8);

  group('cyclesBetween', () {
    test('daily, from inclusive, before exclusive', () {
      expect(cyclesBetween(daily, d8, DateTime(2026, 11, 10, 8)), [
        d8,
        DateTime(2026, 11, 8, 8),
        DateTime(2026, 11, 9, 8),
      ]);
    });

    test('weekly {Mon, Wed}', () {
      final mon = DateTime(2026, 11, 9, 8);
      expect(
        cyclesBetween(
          const RepeatRule(RepeatType.weekly, weekdays: {1, 3}),
          mon,
          DateTime(2026, 11, 17),
        ),
        [mon, DateTime(2026, 11, 11, 8), DateTime(2026, 11, 16, 8)],
      );
    });

    test('keeps the latest cap', () {
      final out = cyclesBetween(daily, d8, DateTime(2026, 11, 20), cap: 2);
      expect(out, [DateTime(2026, 11, 18, 8), DateTime(2026, 11, 19, 8)]);
    });

    test('a one-off has none', () {
      expect(cyclesBetween(RepeatRule.none, d8, DateTime(2027)), isEmpty);
    });
  });

  group('logs', () {
    final r = reminder('d', 'Pills', d8, repeat: daily);
    final tap = DateTime(2026, 11, 7, 8, 5);

    test('doneLog on time: one done for the old due', () {
      final next = r.copyWith(dueAt: DateTime(2026, 11, 8, 8));
      final log = doneLog(r, next, tap);
      expect(log.single.event, OccurrenceEvent.done);
      expect(log.single.dueAt, d8);
      expect(log.single.at, tap);
    });

    test('doneLog early: still the one due', () {
      final next = r.copyWith(dueAt: DateTime(2026, 11, 8, 8));
      expect(doneLog(r, next, DateTime(2026, 11, 6)).single.dueAt, d8);
    });

    test('doneLog two cycles behind: open then done', () {
      final next = r.copyWith(dueAt: DateTime(2026, 11, 9, 8));
      expect(doneLog(r, next, tap).map((o) => o.event), [
        OccurrenceEvent.open,
        OccurrenceEvent.done,
      ]);
    });

    test('snoozeLog records until', () {
      final until = tap.add(const Duration(minutes: 10));
      final log = snoozeLog(r, r.copyWith(snoozedUntil: until), tap);
      expect(log.single.event, OccurrenceEvent.snoozed);
      expect(log.single.until, until);
    });

    test('one-off and test reminder log nothing', () {
      final once = reminder('o', 'x', d8);
      final test = reminder(testReminderId, 'x', d8, repeat: daily);
      final later = d8.add(const Duration(days: 2));
      for (final x in [once, test]) {
        expect(doneLog(x, x.copyWith(dueAt: later), tap), isEmpty);
        expect(snoozeLog(x, x.copyWith(snoozedUntil: later), tap), isEmpty);
        expect(openLog(x, later, tap), isEmpty);
      }
    });
  });

  group('historyRows', () {
    Occurrence o(
      DateTime due,
      OccurrenceEvent e,
      DateTime at, [
      DateTime? until,
    ]) =>
        Occurrence(reminderId: 'd', dueAt: due, event: e, at: at, until: until);
    final tap = DateTime(2026, 11, 7, 18, 5);

    test('snooze + done merge into one row with minutes', () {
      final rows = historyRows([
        o(
          d8,
          OccurrenceEvent.snoozed,
          tap,
          tap.add(const Duration(minutes: 10)),
        ),
        o(d8, OccurrenceEvent.done, tap.add(const Duration(minutes: 10))),
      ]);
      expect(rows.single.snoozedMinutes, 10);
      expect(rows.single.doneAt, tap.add(const Duration(minutes: 10)));
      expect(rows.single.done, isTrue);
    });

    test('snooze-only group is hidden', () {
      expect(historyRows([o(d8, OccurrenceEvent.snoozed, tap, tap)]), isEmpty);
    });

    test('open group shows as not done; done wins over open', () {
      final d9 = DateTime(2026, 11, 8, 8);
      final rows = historyRows([
        o(d8, OccurrenceEvent.open, tap),
        o(d9, OccurrenceEvent.open, tap),
        o(d9, OccurrenceEvent.done, tap),
      ]);
      expect(rows.map((r) => r.dueAt), [d9, d8]);
      expect(rows.map((r) => r.done), [true, false]);
    });
  });

  test('weekTally counts the Monday-to-Monday week', () {
    OccurrenceRow row(DateTime due, bool done) =>
        OccurrenceRow(dueAt: due, doneAt: done ? due : null);
    final rows = [
      row(DateTime(2026, 11, 8, 23), true), // Sun, previous week
      row(DateTime(2026, 11, 9, 0), true), // Mon 00:00
      row(DateTime(2026, 11, 12, 8), false),
      row(DateTime(2026, 11, 16, 0), true), // next Mon, excluded
    ];
    final t = weekTally(rows, DateTime(2026, 11, 14, 9)); // Sat
    expect((t.done, t.total), (1, 2));
  });

  test('weekTally ignores cycles not yet due', () {
    final rows = [
      OccurrenceRow(
        dueAt: DateTime(2026, 11, 10, 8),
        doneAt: DateTime(2026, 11, 10, 8),
      ),
      OccurrenceRow(
        dueAt: DateTime(2026, 11, 13, 8),
        doneAt: DateTime(2026, 11, 10, 9),
      ),
    ];
    final t = weekTally(rows, DateTime(2026, 11, 11, 9));
    expect((t.done, t.total), (1, 1));
  });
}
