import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/reminders/domain/entities/repeat_rule.dart';
import 'package:memo/features/reminders/domain/parser/reminder_parser.dart';

/// Wednesday 4 Nov 2026, 12:00.
final now = DateTime(2026, 11, 4, 12);
DateTime at(int day, int hour, [int minute = 0, int month = 11]) =>
    DateTime(2026, month, day, hour, minute);

const daily = RepeatRule.daily;
RepeatRule weekly(Set<int> days) =>
    RepeatRule(RepeatType.weekly, weekdays: days);

/// (input, title, due, repeat, tag, guessed)
typedef Case = (String, String, DateTime, RepeatRule?, String?, bool);

final List<Case> cases = [
  // ── Clock times ─────────────────────────────────────────────────────────
  ('Pills at 8pm', 'Pills', at(4, 20), null, null, false),
  ('Pills 8pm', 'Pills', at(4, 20), null, null, false),
  ('Pills at 8 pm', 'Pills', at(4, 20), null, null, false),
  ('Pills at 8:30pm', 'Pills', at(4, 20, 30), null, null, false),
  ('Pills at 8.30pm', 'Pills', at(4, 20, 30), null, null, false),
  ('Pills at 8:30 p.m.', 'Pills', at(4, 20, 30), null, null, false),
  ('Call mum 7am', 'Call mum', at(5, 7), null, null, false),
  ('Call mum at 11am', 'Call mum', at(5, 11), null, null, false),
  ('Call mum at 12pm', 'Call mum', at(5, 12), null, null, false),
  ('Lunch at 12am', 'Lunch', at(5, 0), null, null, false),
  ('Bins at 20:00', 'Bins', at(4, 20), null, null, false),
  ('Bins 20:00', 'Bins', at(4, 20), null, null, false),
  ('Bins at 07:15', 'Bins', at(5, 7, 15), null, null, false),
  ('Bins at 23:59', 'Bins', at(4, 23, 59), null, null, false),
  ('Bins at 00:30', 'Bins', at(5, 0, 30), null, null, false),
  ('Bins @ 18:00', 'Bins', at(4, 18), null, null, false),
  ('Standup by 9am', 'Standup', at(5, 9), null, null, false),
  ('Water plants 13:00', 'Water plants', at(4, 13), null, null, false),
  // ── Ambiguous "at 8": next 8:00 or 20:00 ahead ──────────────────────────
  ('Pills at 8', 'Pills', at(4, 20), null, null, false),
  ('Pills at 11', 'Pills', at(4, 23), null, null, false),
  ('Pills at 1', 'Pills', at(4, 13), null, null, false),
  ('Pills at 12', 'Pills', at(5, 0), null, null, false),
  ('Pills at 8:30', 'Pills', at(4, 20, 30), null, null, false),
  ('Pills tomorrow at 8', 'Pills', at(5, 8), null, null, false),
  ('Pills at 8 tonight', 'Pills', at(4, 20), null, null, false),
  ('Pills at 7 in the morning', 'Pills', at(5, 7), null, null, false),
  ('Pills at 3 in the afternoon', 'Pills', at(4, 15), null, null, false),
  ('Pills at 6 this evening', 'Pills', at(4, 18), null, null, false),
  // ── Named times ─────────────────────────────────────────────────────────
  ('Pills tonight', 'Pills', at(4, 20), null, null, false),
  ('Run in the morning', 'Run', at(5, 8), null, null, false),
  ('Run this morning', 'Run', at(5, 8), null, null, false),
  ('Tea this afternoon', 'Tea', at(4, 15), null, null, false),
  ('Walk this evening', 'Walk', at(4, 18), null, null, false),
  ('Lunch at noon', 'Lunch', at(5, 12), null, null, false),
  ('Lunch noon', 'Lunch', at(5, 12), null, null, false),
  ('Backup at midnight', 'Backup', at(5, 0), null, null, false),
  ('Tomorrow morning run', 'Run', at(5, 8), null, null, false),
  ('Call dad tomorrow evening', 'Call dad', at(5, 18), null, null, false),
  // ── Relative ────────────────────────────────────────────────────────────
  ('Tea in 10 min', 'Tea', at(4, 12, 10), null, null, false),
  ('Tea in 10 minutes', 'Tea', at(4, 12, 10), null, null, false),
  ('Tea in 45 mins', 'Tea', at(4, 12, 45), null, null, false),
  ('Tea in 5m', 'Tea', at(4, 12, 5), null, null, false),
  ('Oven in 2 hours', 'Oven', at(4, 14), null, null, false),
  ('Oven in 1 hour', 'Oven', at(4, 13), null, null, false),
  ('Oven in an hour', 'Oven', at(4, 13), null, null, false),
  ('Oven in half an hour', 'Oven', at(4, 12, 30), null, null, false),
  ('Oven in 1.5 hours', 'Oven', at(4, 13, 30), null, null, false),
  ('Oven in 3h', 'Oven', at(4, 15), null, null, false),
  ('Oven in 2 hrs', 'Oven', at(4, 14), null, null, false),
  ('Pay rent in 2 days', 'Pay rent', at(6, 12), null, null, false),
  ('Pay rent in a week', 'Pay rent', at(11, 12), null, null, false),
  // ── Dates ───────────────────────────────────────────────────────────────
  ('Dentist tomorrow at 9:30am', 'Dentist', at(5, 9, 30), null, null, false),
  ('Dentist tomorrow 9am', 'Dentist', at(5, 9), null, null, false),
  ('Dentist tmrw 9am', 'Dentist', at(5, 9), null, null, false),
  ('Dentist tomorrow', 'Dentist', at(5, 9), null, null, true),
  ('Dentist today at 5pm', 'Dentist', at(4, 17), null, null, false),
  ('Dentist day after tomorrow 10am', 'Dentist', at(6, 10), null, null, false),
  ('Dentist on friday at 10am', 'Dentist', at(6, 10), null, null, false),
  ('Dentist friday 10am', 'Dentist', at(6, 10), null, null, false),
  ('Dentist fri 10am', 'Dentist', at(6, 10), null, null, false),
  ('Dentist next friday 10am', 'Dentist', at(6, 10), null, null, false),
  ('Dentist monday 10am', 'Dentist', at(9, 10), null, null, false),
  ('Dentist on wednesday 3pm', 'Dentist', at(4, 15), null, null, false),
  ('Dentist next wednesday 3pm', 'Dentist', at(11, 15), null, null, false),
  ('Dentist sunday', 'Dentist', at(8, 9), null, null, true),
  (
    'Renew passport 3 nov',
    'Renew passport',
    DateTime(2027, 11, 3, 9),
    null,
    null,
    true,
  ),
  ('Renew passport 5 nov 10am', 'Renew passport', at(5, 10), null, null, false),
  (
    'Renew passport 12th dec',
    'Renew passport',
    at(12, 9, 0, 12),
    null,
    null,
    true,
  ),
  (
    'Renew passport dec 12',
    'Renew passport',
    at(12, 9, 0, 12),
    null,
    null,
    true,
  ),
  (
    'Renew passport december 12 at 4pm',
    'Renew passport',
    at(12, 16, 0, 12),
    null,
    null,
    false,
  ),
  (
    'Renew passport 1 jan',
    'Renew passport',
    DateTime(2027, 1, 1, 9),
    null,
    null,
    true,
  ),
  ('Pay bill 05/11', 'Pay bill', at(5, 9), null, null, true),
  ('Pay bill 05/11 6pm', 'Pay bill', at(5, 18), null, null, false),
  ('Pay bill 25/12/2026', 'Pay bill', at(25, 9, 0, 12), null, null, true),
  ('Pay bill 25/12/26 10:00', 'Pay bill', at(25, 10, 0, 12), null, null, false),
  // ── Repeats ─────────────────────────────────────────────────────────────
  ('Pills every day at 8pm', 'Pills', at(4, 20), daily, null, false),
  ('Pills daily 8pm', 'Pills', at(4, 20), daily, null, false),
  ('Pills at 8 tonight, every day', 'Pills', at(4, 20), daily, null, false),
  ('Pills daily at 9am', 'Pills', at(5, 9), daily, null, false),
  ('Pills each day 9am', 'Pills', at(5, 9), daily, null, false),
  ('Gym every monday 7am', 'Gym', at(9, 7), weekly({1}), null, false),
  (
    'Gym every mon wed fri 7am',
    'Gym',
    at(6, 7),
    weekly({1, 3, 5}),
    null,
    false,
  ),
  (
    'Gym every mon, wed and fri at 6pm',
    'Gym',
    at(4, 18),
    weekly({1, 3, 5}),
    null,
    false,
  ),
  (
    'Gym every tuesday and thursday 6pm',
    'Gym',
    at(5, 18),
    weekly({2, 4}),
    null,
    false,
  ),
  (
    'Standup weekdays 9:30am',
    'Standup',
    at(5, 9, 30),
    weekly({1, 2, 3, 4, 5}),
    null,
    false,
  ),
  (
    'Standup every weekday 9:30am',
    'Standup',
    at(5, 9, 30),
    weekly({1, 2, 3, 4, 5}),
    null,
    false,
  ),
  ('Lie in weekends 9am', 'Lie in', at(7, 9), weekly({6, 7}), null, false),
  ('Lie in every weekend 9am', 'Lie in', at(7, 9), weekly({6, 7}), null, false),
  ('Bins every week 7am', 'Bins', at(11, 7), weekly({3}), null, false),
  ('Bins weekly at 7pm', 'Bins', at(4, 19), weekly({3}), null, false),
  ('Call gran every sunday', 'Call gran', at(8, 13), weekly({7}), null, true),
  ('Vitamins every day', 'Vitamins', at(4, 13), daily, null, true),
  // ── Tags ────────────────────────────────────────────────────────────────
  ('Pills 8pm #health', 'Pills', at(4, 20), null, 'Health', false),
  ('#health Pills 8pm', 'Pills', at(4, 20), null, 'Health', false),
  ('Buy nails #diy 6pm', 'Buy nails', at(4, 18), null, 'diy', false),
  ('Send deck 5pm for work', 'Send deck', at(4, 17), null, 'Work', false),
  ('Send deck for work', 'Send deck', at(4, 13), null, 'Work', true),
  (
    'Buy flowers for mum 5pm',
    'Buy flowers for mum',
    at(4, 17),
    null,
    null,
    false,
  ),
  ('Pills every day 8pm #Health', 'Pills', at(4, 20), daily, 'Health', false),
  // ── No time: next whole hour ≥ 30 min away, a guess ─────────────────────
  ('Buy milk', 'Buy milk', at(4, 13), null, null, true),
  ('remind me to buy milk', 'Buy milk', at(4, 13), null, null, true),
  (
    'Remind me to call the bank tomorrow at 10',
    'Call the bank',
    at(5, 10),
    null,
    null,
    false,
  ),
  ('to call the bank at 3pm', 'Call the bank', at(4, 15), null, null, false),
  ('', '', at(4, 13), null, null, true),
  // ── Words that look like times but are not consumed ─────────────────────
  ('Read chapter 8', 'Read chapter 8', at(4, 13), null, null, true),
  ('Buy 2 eggs at 6pm', 'Buy 2 eggs', at(4, 18), null, null, false),
  ('Book table for 4 at 8pm', 'Book table for 4', at(4, 20), null, null, false),
  (
    'Mondays meeting prep at 9am',
    'Mondays meeting prep',
    at(5, 9),
    null,
    null,
    false,
  ),
  ('Call Sam in a bit', 'Call Sam in a bit', at(4, 13), null, null, true),
];

void main() {
  test('the table holds 100+ phrases', () {
    expect(cases.length, greaterThanOrEqualTo(100));
  });

  for (final (input, title, due, repeat, tag, guessed) in cases) {
    test('"$input"', () {
      final p = parseReminder(
        input,
        now: now,
        knownTags: const ['Health', 'Work'],
      );
      expect(p.title, title, reason: 'title');
      expect(p.dueAt, due, reason: 'due');
      expect(p.repeat, repeat ?? RepeatRule.none, reason: 'repeat');
      expect(p.tag, tag, reason: 'tag');
      expect(p.timeGuessed, guessed, reason: 'guessed');
    });
  }

  test('space before punctuation is tidied, not left as a literal \$1', () {
    for (final (input, title) in [
      ('buy milk , eggs tomorrow', 'Buy milk, eggs'),
      ('call Sam ! tomorrow', 'Call Sam!'),
    ]) {
      expect(parseReminder(input, now: now).title, title, reason: input);
    }
  });

  test('hi/bn: Devanagari ? tidied, danda left alone', () {
    final q = parseReminder('दवाई ? कल सुबह 8 बजे', now: now);
    expect(q.title, 'दवाई?', reason: 'hi question mark');
    final d = parseReminder('दवाई । मसाला कल सुबह 8 बजे', now: now);
    expect(d.title, 'दवाई । मसाला', reason: 'danda kept as is');
  });

  group('source spans', () {
    test('point at the words each chip came from', () {
      const input = 'Pills at 8 tonight every day #health';
      final p = parseReminder(input, now: now, knownTags: const ['Health']);
      final words = [
        for (final s in p.timeSpans) input.substring(s.start, s.end).trim(),
      ];
      expect(words, ['at 8', 'tonight']);
      expect(
        input.substring(p.repeatSpan!.start, p.repeatSpan!.end),
        'every day',
      );
      expect(input.substring(p.tagSpan!.start, p.tagSpan!.end), '#health');
    });

    test('are empty when nothing matched', () {
      final p = parseReminder('Buy milk', now: now);
      expect(p.timeSpans, isEmpty);
      expect(p.repeatSpan, isNull);
      expect(p.tagSpan, isNull);
    });
  });

  test('a time already passed today moves to tomorrow', () {
    final p = parseReminder('Pills 9am', now: now);
    expect(p.dueAt, at(5, 9));
  });

  test('a repeat in the past starts at its next occurrence', () {
    final p = parseReminder('Pills daily 7am', now: now);
    expect(p.dueAt, at(5, 7));
  });

  group('calendar rules, Fri 20 Nov 2026 14:30', () {
    final fri = DateTime(2026, 11, 20, 14, 30);
    DateTime parsed(String input) => parseReminder(input, now: fri).dueAt;

    test('a weekday already passed today rolls a week', () {
      expect(parsed('bins by friday'), DateTime(2026, 11, 27, 9));
      expect(parsed('this friday at 9am'), DateTime(2026, 11, 27, 9));
    });

    test('an impossible date is ignored and stays in the title', () {
      final p = parseReminder('dentist 29 feb 2027', now: fri);
      expect(p.title, 'Dentist 29 feb 2027');
      expect(p.timeSpans, isEmpty);
      expect(parseReminder('31/04', now: fri).timeSpans, isEmpty);
    });

    test('29 Feb with no year goes to the next leap year', () {
      expect(parsed('dentist 29 feb'), DateTime(2028, 2, 29, 9));
    });

    test('in N months and years keep the wall-clock time', () {
      expect(parsed('in 2 months'), DateTime(2027, 1, 20, 14, 30));
      expect(parsed('in 1 year'), DateTime(2027, 11, 20, 14, 30));
    });

    test('a month-end date clamps to the end of a short month', () {
      final jan31 = DateTime(2027, 1, 31, 14, 30);
      expect(
        parseReminder('in 1 month', now: jan31).dueAt,
        DateTime(2027, 2, 28, 14, 30),
      );
    });

    test('a bare ordinal means the next such day', () {
      final p = parseReminder('pay rent the 5th', now: fri);
      expect(p.dueAt, DateTime(2026, 12, 5, 9));
      expect(p.timeGuessed, isTrue);
    });
  });

  group('today and rejected dates', () {
    final fri = DateTime(2026, 11, 20, 14, 30);

    test('a date that is today, 09:00 gone, guesses the next hour', () {
      final p = parseReminder('meet on 20 nov', now: fri);
      expect(p.dueAt, DateTime(2026, 11, 20, 16));
      expect(p.timeGuessed, isTrue);
      expect(
        parseReminder('today', now: fri).dueAt,
        DateTime(2026, 11, 20, 16),
      );
      expect(
        parseReminder('the 20th', now: fri).dueAt,
        DateTime(2026, 11, 20, 16),
      );
    });

    test('today before 09:00 keeps 09:00', () {
      final early = DateTime(2026, 11, 20, 8);
      expect(
        parseReminder('today', now: early).dueAt,
        DateTime(2026, 11, 20, 9),
      );
    });

    test('late night today guesses the next hour, rolling into tomorrow', () {
      final late = DateTime(2026, 11, 4, 23, 45);
      final p = parseReminder('meet 4 nov', now: late);
      // 23:45 + 30 min is 00:15 on the 5th, so the guess is 01:00 tomorrow.
      // Accepted: the date said "today", but the next hour is a guess anyway.
      expect(p.dueAt, DateTime(2026, 11, 5, 1));
      expect(p.timeGuessed, isTrue);
    });

    test('a rejected date does not drop a following weekday', () {
      final p = parseReminder('31/04 friday', now: fri);
      expect(p.title, '31/04');
      expect(p.dueAt, DateTime(2026, 11, 27, 9));
    });
  });

  group('ambiguity', () {
    test('a bare hour asks morning or evening', () {
      const input = 'call mum tomorrow at 8';
      final p = parseReminder(input, now: now);
      final a = p.ambiguity!;
      expect(a.kinds, {AmbiguityKind.amPm});
      expect(a.choices, [at(5, 8), at(5, 20)]);
      expect(input.substring(a.span!.start, a.span!.end), 'at 8');
    });

    test('no bare-hour choice is in the past', () {
      final a = parseReminder('call mum at 8', now: now).ambiguity!;
      expect(a.choices, [at(4, 20), at(5, 8)]);
      expect(a.choices.every((c) => c.isAfter(now)), isTrue);
    });

    test('a bare 8:30 is ambiguous, 20:30 is not', () {
      expect(parseReminder('call at 8:30', now: now).ambiguity, isNotNull);
      expect(parseReminder('call at 20:30', now: now).ambiguity, isNull);
    });

    test('no time at all is a noTime guess', () {
      final p = parseReminder('pay rent', now: now);
      expect(p.ambiguity!.kinds, {AmbiguityKind.noTime});
      expect(p.ambiguity!.choices, [p.dueAt]);
    });

    test('a date with no time is a noTime guess', () {
      final p = parseReminder('pay rent tomorrow', now: now);
      expect(p.ambiguity!.kinds, {AmbiguityKind.noTime});
    });

    test('stated times are not ambiguous', () {
      expect(parseReminder('pills at 8pm', now: now).ambiguity, isNull);
      expect(parseReminder('pills at 8 tonight', now: now).ambiguity, isNull);
      expect(parseReminder('pills in 2 hours', now: now).ambiguity, isNull);
    });

    group('a named day keeps only readings that are ahead', () {
      DateTime on(int h) => DateTime(2026, 11, 4, h);

      test('today at 8, 09:00: only the evening is left, nothing to ask', () {
        final p = parseReminder('call today at 8', now: on(9));
        expect(p.ambiguity, isNull);
        expect(p.dueAt, at(4, 20));
      });

      test('today at 8, 12:00: only the evening is left, nothing to ask', () {
        final p = parseReminder('call today at 8', now: on(12));
        expect(p.ambiguity, isNull);
        expect(p.dueAt, at(4, 20));
      });

      test('today at 8, 21:00: both roll to tomorrow and are asked', () {
        final p = parseReminder('call today at 8', now: on(21));
        expect(p.ambiguity!.choices, [at(5, 8), at(5, 20)]);
        expect(p.dueAt, at(5, 8));
      });

      test(
        'friday at 8 on a Friday afternoon: only 20:00 is left, nothing to ask',
        () {
          final fri = DateTime(2026, 11, 27, 15);
          final p = parseReminder('call friday at 8', now: fri);
          expect(p.ambiguity, isNull);
          expect(p.dueAt, DateTime(2026, 11, 27, 20));
        },
      );
    });

    test('dueAt is unchanged by ambiguity', () {
      expect(parseReminder('call mum at 8', now: now).dueAt, at(4, 20));
    });

    test('a weekly rule keeps every choice on a picked day', () {
      final a = parseReminder('gym every monday at 8', now: now).ambiguity!;
      expect(a.choices.every((c) => c.weekday == DateTime.monday), isTrue);
    });

    test('non-ASCII input keeps spans on the original string', () {
      const input = 'İstanbul at 8pm';
      final p = parseReminder(input, now: now);
      final s = p.timeSpans.single;
      expect(input.substring(s.start, s.end), 'at 8pm');
      expect(p.title, 'İstanbul');
    });
  });
}
