import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/reminders/domain/parser/reminder_parser.dart'
    as n;
import 'legacy_english_parser.dart' as o;
import 'reminder_parser_test.dart' as src;

const collisions = [
  'Call AJ at 5pm',
  'Call Kal at 5pm',
  'call Kal tomorrow',
  'meet Roz at 6pm',
  'call Roj tomorrow',
  'parson street at 5',
  'send 5 me the report',
  'Sham Sui Po trip',
  'Raat Records',
  'Section 8 TA meeting',
  'Lunch with Raj aaj',
  'Kal Penn movie at 9pm',
  'Kal Penn',
  'meet Sham at 7pm',
  'Sham and Raat are friends',
  'Roz is coming at 5pm',
  'ask Roz about tomorrow',
  'buy 2 ta',
  'meet at 8 ta',
  'share 9 ta',
  'give 2 me',
  'the raat pack',
  'Bad Bunny tickets tomorrow',
  'bad day at 9',
  'din din at 6pm',
  'par 3 golf at 8am',
  'me time at 9pm',
  'call me at 6pm',
  'text me tomorrow',
  'Ask Dio about the 3 din',
  'text Har at 9am',
  'Har Gobind visit',
  'pick up Ta at 4pm',
  'Ta and Kal at the station 6pm',
  'Shaam at the cafe 7pm',
  'Subah called at 10am',
  'ko and ki at 5pm',
  'dinner with Mone at 7pm',
  'Mein Kampf book club at 9',
  'Baje Foods order Friday',
  'pay Aaj Tak subscription tomorrow',
  'Kaal is a name, call at 6pm',
  'por favor at 3',
  'the ek tara band at 8pm',
  'do the dishes at 9',
  'char siu dinner tomorrow',
  'das boot film at 8pm',
  'nau monday',
  'meet Dedh at 5pm',
  'Arai Ta at 5pm',
  'Roj Ta at 5pm',
  'May Day at 6pm',
  'call May at 4pm',
  'Mai is late, meet at 6pm',
  'Sare at 9 sharp',
];

void same(n.ParsedReminder x, o.OldParsed a, String i) {
  expect(x.title, a.title, reason: i);
  expect(x.dueAt, a.dueAt, reason: i);
  expect(x.repeat, a.repeat, reason: i);
  expect(x.tag, a.tag, reason: i);
  expect(x.timeGuessed, a.timeGuessed, reason: i);
  expect(
    '${x.timeSpans}${x.repeatSpan}${x.tagSpan}'.replaceAll(
      'SourceSpan',
      'OldSpan',
    ),
    '${a.timeSpans}${a.repeatSpan}${a.tagSpan}',
    reason: i,
  );
  expect(
    x.ambiguity?.kinds.map((k) => k.name).toList(),
    a.ambiguity?.kinds.map((k) => k.name).toList(),
    reason: i,
  );
  expect(x.ambiguity?.choices, a.ambiguity?.choices, reason: i);
  expect(x.ambiguity?.span?.start, a.ambiguity?.span?.start, reason: i);
  expect(x.ambiguity?.span?.end, a.ambiguity?.span?.end, reason: i);
}

// English inputs: old vs new parser, several clocks, identical results.
void main() {
  test('english identical', () {
    final inputs = [
      for (final c in src.cases) c.$1,
      'call mum tomorrow at 8',
      'pay rent',
      'pills at 8pm',
      'at 8 tonight',
      'İstanbul at 8pm',
      'every mon and fri gym at 7',
      'remind me to sleep in 2 hours #home',
      'friday',
      '29 feb',
      'buy rat poison',
      'sham marriage talk kal 8 baje',
    ];
    final clocks = [
      DateTime(2026, 11, 4, 12),
      DateTime(2026, 11, 20, 14, 30),
      DateTime(2026, 12, 31, 23, 59),
      DateTime(2027, 2, 28, 0, 5),
      DateTime(2026, 11, 6, 8),
    ];
    for (final now in clocks) {
      for (final i in inputs) {
        final a = o.parseReminder(i, now: now, knownTags: ['home', 'work']);
        final langs = [
          (language: 'en', latin: false),
          (language: 'bn', latin: false),
          // Latin packs on: English-only input must not change either.
          if (!i.contains('kal 8 baje')) (language: 'hi', latin: true),
        ];
        for (final l in langs) {
          same(
            n.parseReminder(
              i,
              now: now,
              knownTags: ['home', 'work'],
              language: l.language,
              latinPacks: l.latin,
            ),
            a,
            i,
          );
        }
      }
    }
  });

  // Names and words that are also Latin Hindi/Bengali: with `latinPacks` on
  // (the user speaks hi/bn) none of these may change.
  test('english sentences ignore Latin packs', () {
    final now = DateTime(2026, 11, 20, 14, 30);
    for (final lang in ['en', 'hi', 'bn']) {
      for (final i in collisions) {
        same(
          n.parseReminder(
            i,
            now: now,
            knownTags: ['home', 'work'],
            language: lang,
            latinPacks: true,
          ),
          o.parseReminder(i, now: now, knownTags: ['home', 'work']),
          '$lang: $i',
        );
      }
    }
    expect(collisions.length, greaterThanOrEqualTo(45));
  });

  // The "#café" side effect: the tag now keeps its accent, where the old
  // parser stopped at "caf". ASCII tags are covered by the runs above.
  test('unicode tag', () {
    final p = n.parseReminder('x #café', now: DateTime(2026, 11, 20, 14, 30));
    expect(p.tag, 'café');
  });
}
