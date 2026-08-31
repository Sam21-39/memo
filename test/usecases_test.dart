import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/reminders/domain/entities/reminder.dart';
import 'package:memo/features/reminders/domain/entities/repeat_rule.dart';
import 'package:memo/features/reminders/domain/usecases/complete_reminder.dart';
import 'package:memo/features/reminders/domain/usecases/create_reminder.dart';
import 'package:memo/features/reminders/domain/usecases/snooze_reminder.dart';

Reminder _reminder({
  DateTime? scheduledAt,
  RepeatRule repeat = RepeatRule.none,
  bool isDone = false,
}) {
  final at = scheduledAt ?? DateTime(2026, 8, 26, 8, 30);
  return Reminder(
    id: '1',
    title: 'Water the fig tree',
    scheduledAt: at,
    createdAt: DateTime(2026, 8, 1),
    repeat: repeat,
    isDone: isDone,
  );
}

void main() {
  group('CreateReminder', () {
    const create = CreateReminder();

    test('trims the title and drops a blank note', () {
      final result = create(
        title: '  Renew passport  ',
        scheduledAt: DateTime(2026, 8, 27, 9, 30),
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
      expect(result.scheduledAt, DateTime(2026, 8, 26, 10, 10));
    });

    test('tomorrow keeps the reminder own time of day', () {
      final result = snooze(
        _reminder(scheduledAt: DateTime(2026, 8, 26, 8, 30)),
        now: DateTime(2026, 8, 26, 10),
      );
      expect(result.scheduledAt, DateTime(2026, 8, 27, 8, 30));
    });

    test('reopens a completed reminder', () {
      final result = snooze(
        _reminder(isDone: true),
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
      expect(result.scheduledAt, DateTime(2026, 8, 27, 8, 30));
    });

    test('a stale repeat rolls forward past now, not just one step', () {
      // Scheduled three days ago; completing it today must land in the future.
      final result = complete(
        _reminder(
          scheduledAt: DateTime(2026, 8, 23, 8, 30),
          repeat: RepeatRule.daily,
        ),
        now: DateTime(2026, 8, 26, 9),
      );
      expect(result.scheduledAt.isAfter(DateTime(2026, 8, 26, 9)), isTrue);
      expect(result.scheduledAt, DateTime(2026, 8, 27, 8, 30));
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
}
