import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/reminders/domain/alarm/alarm_ids.dart';
import 'package:memo/features/reminders/domain/alarm/fire_plan.dart';
import 'package:memo/features/reminders/domain/entities/repeat_rule.dart';

import 'fakes.dart';

void main() {
  final now = DateTime(2026, 11, 4, 12); // Wednesday noon

  test('a future one-off fires once at its time', () {
    final fires = firesFor(
      reminder('a', 'Bins', DateTime(2026, 11, 5, 7)),
      now: now,
    );
    expect(fires.single.at, DateTime(2026, 11, 5, 7));
    expect(fires.single.repeat, FireRepeat.none);
    expect(fires.single.id, AlarmIds.main('a'));
  });

  test('a past one-off and a done reminder fire nothing', () {
    expect(
      firesFor(reminder('a', 'B', DateTime(2026, 11, 4, 7)), now: now),
      isEmpty,
    );
    expect(
      firesFor(
        reminder('a', 'B', DateTime(2026, 11, 5), doneAt: now),
        now: now,
      ),
      isEmpty,
    );
  });

  test('a daily repeat in the past fires at its next wall time', () {
    final fires = firesFor(
      reminder(
        'd',
        'Pills',
        DateTime(2026, 10, 1, 8),
        repeat: RepeatRule.daily,
      ),
      now: now,
    );
    expect(fires.single.at, DateTime(2026, 11, 5, 8));
    expect(fires.single.repeat, FireRepeat.daily);
  });

  test('a daily repeat starting next week waits for its start', () {
    final start = DateTime(2026, 11, 11, 8);
    final fires = firesFor(
      reminder('d', 'Pills', start, repeat: RepeatRule.daily),
      now: now,
    );
    expect(fires.single.at, start);
  });

  test('a weekly rule fires once per picked weekday, soonest first', () {
    final fires = firesFor(
      reminder(
        'w',
        'Gym',
        DateTime(2026, 10, 1, 18),
        repeat: const RepeatRule(RepeatType.weekly, weekdays: {1, 3, 5}),
      ),
      now: now,
    );
    expect(fires.map((f) => f.at), [
      DateTime(2026, 11, 4, 18), // Wed, still ahead today
      DateTime(2026, 11, 6, 18), // Fri
      DateTime(2026, 11, 9, 18), // Mon
    ]);
    expect(fires.map((f) => f.id).toSet(), {
      AlarmIds.weekday('w', 1),
      AlarmIds.weekday('w', 3),
      AlarmIds.weekday('w', 5),
    });
  });

  group('iOS burst', () {
    test('with nag off a second fire follows one minute later', () {
      final fires = firesFor(
        reminder('a', 'Bins', DateTime(2026, 11, 5, 7)),
        now: now,
        burst: true,
      );
      expect(fires.map((f) => f.at), [
        DateTime(2026, 11, 5, 7),
        DateTime(2026, 11, 5, 7, 1),
      ]);
      expect(fires.last.kind, FireKind.burst);
    });

    test('with nag on there is no burst: nag is the retry', () {
      final fires = firesFor(
        reminder('a', 'Bins', DateTime(2026, 11, 5, 7)).copyWith(nagMin: 10),
        now: now,
        burst: true,
      );
      expect(fires.where((f) => f.kind == FireKind.burst), isEmpty);
      expect(fires, hasLength(1 + AlarmIds.maxNags));
    });

    test('weekly bursts get their own ids', () {
      final fires = firesFor(
        reminder(
          'w',
          'Gym',
          DateTime(2026, 10, 1, 18),
          repeat: const RepeatRule(RepeatType.weekly, weekdays: {1, 3}),
        ),
        now: now,
        burst: true,
      );
      expect(fires.map((f) => f.id).toSet(), hasLength(4));
    });
  });

  group('DST keeps wall time', () {
    // Europe/London falls back 25 Oct 2026; America/New_York on 1 Nov 2026.
    // Run with TZ set to either (CI does) and 07:00 must stay 07:00.
    for (final day in [DateTime(2026, 10, 24, 7), DateTime(2026, 10, 31, 7)]) {
      test('daily across ${day.month}/${day.day}', () {
        final next = nextDaily(day, day.add(const Duration(hours: 1)));
        expect(next, DateTime(day.year, day.month, day.day + 1, 7));
      });
    }

    test('weekly across both shifts', () {
      final next = nextWeekday(
        DateTime(2026, 10, 20, 7),
        2,
        DateTime(2026, 10, 20, 8),
      );
      expect([next.month, next.day, next.hour], [10, 27, 7]);
    });
  });

  group('nag and pre-alarm', () {
    test('a one-off nags 6 times then stops', () {
      final fires = firesFor(
        reminder('a', 'Bins', DateTime(2026, 11, 5, 7)).copyWith(nagMin: 10),
        now: now,
      );
      expect(fires.map((f) => f.at), [
        for (var k = 0; k <= 6; k++) DateTime(2026, 11, 5, 7, 10 * k),
      ]);
      expect(fires.skip(1).every((f) => f.kind == FireKind.nag), isTrue);
      expect(fires.map((f) => f.id).toSet(), hasLength(7));
    });

    test('a custom nag interval is honoured', () {
      final fires = firesFor(
        reminder('a', 'Bins', DateTime(2026, 11, 5, 7)).copyWith(nagMin: 7),
        now: now,
      );
      expect(fires[1].at, DateTime(2026, 11, 5, 7, 7));
      expect(fires.last.at, DateTime(2026, 11, 5, 7, 42));
    });

    test('a pre-alarm rings before the main', () {
      final fires = firesFor(
        reminder(
          'a',
          'Bins',
          DateTime(2026, 11, 5, 7),
        ).copyWith(preAlarmMin: 15),
        now: now,
      );
      expect(fires.first.kind, FireKind.pre);
      expect(fires.first.at, DateTime(2026, 11, 5, 6, 45));
      expect(fires.first.id, AlarmIds.preAlarm('a'));
    });

    test('an overdue repeat keeps nagging today while its main moves on', () {
      final fires = firesFor(
        reminder(
          'd',
          'Pills',
          DateTime(2026, 11, 4, 11, 55),
          repeat: RepeatRule.daily,
        ).copyWith(nagMin: 10),
        now: now, // 12:00, five minutes late
      );
      final nags = fires.where((f) => f.kind == FireKind.nag).toList();
      expect(nags.first.at, DateTime(2026, 11, 4, 12, 5));
      expect(nags.every((f) => f.repeat == FireRepeat.daily), isTrue);
      expect(
        fires.firstWhere((f) => f.kind == FireKind.main).at,
        DateTime(2026, 11, 5, 11, 55),
      );
    });

    test('a snoozed repeat nags from the snooze, not from today', () {
      final fires = firesFor(
        reminder(
          'd',
          'Pills',
          DateTime(2026, 11, 4, 11, 55),
          repeat: RepeatRule.daily,
        ).copyWith(nagMin: 10, snoozedUntil: DateTime(2026, 11, 4, 12, 15)),
        now: now,
      );
      final today = fires.where((f) => f.at.day == 4).toList();
      expect(today.first.kind, FireKind.snooze);
      expect(today.first.at, DateTime(2026, 11, 4, 12, 15));
      expect(today.skip(1).map((f) => f.at), [
        for (var k = 1; k <= 6; k++) DateTime(2026, 11, 4, 12, 15 + 10 * k),
      ]);
      // The series is untouched: tomorrow at 11:55, nags from there.
      expect(
        fires.firstWhere((f) => f.kind == FireKind.main).at,
        DateTime(2026, 11, 5, 11, 55),
      );
      expect(
        fires.where((f) => f.kind == FireKind.nag && f.at.day == 5).first.at,
        DateTime(2026, 11, 5, 12, 5),
      );
    });

    test('a weekly nag after midnight lands on the next weekday', () {
      final fires = firesFor(
        reminder(
          'w',
          'Late call',
          DateTime(2026, 10, 1, 23, 50),
          repeat: const RepeatRule(RepeatType.weekly, weekdays: {5}),
        ).copyWith(nagMin: 30),
        now: now,
      );
      final mainFire = fires.firstWhere((f) => f.kind == FireKind.main);
      final firstNag = fires.firstWhere((f) => f.kind == FireKind.nag);
      expect(mainFire.at, DateTime(2026, 11, 6, 23, 50)); // Friday
      expect(firstNag.at, DateTime(2026, 11, 7, 0, 20)); // Saturday 00:20
      expect(firstNag.group, mainFire.id);
    });
  });
}
