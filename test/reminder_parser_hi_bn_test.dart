import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/reminders/domain/entities/repeat_rule.dart';
import 'package:memo/features/reminders/domain/parser/reminder_parser.dart';

/// Friday 20 Nov 2026, 14:30. No DST in play: every due is plain wall-clock.
final now = DateTime(2026, 11, 20, 14, 30);
DateTime d(int day, int h, [int m = 0, int mo = 11]) =>
    DateTime(2026, mo, day, h, m);
RepeatRule wk(Set<int> days) => RepeatRule(RepeatType.weekly, weekdays: days);
const daily = RepeatRule.daily;
const dw = AmbiguityKind.dayWord;
const ap = AmbiguityKind.amPm;
const nt = AmbiguityKind.noTime;

/// (input, title, due, ambiguity kinds or null, repeat, choices)
typedef Case = (
  String,
  String,
  DateTime,
  Set<AmbiguityKind>?,
  RepeatRule?,
  List<DateTime>?,
);

Case c(
  String input,
  String title,
  DateTime due,
  Set<AmbiguityKind>? kinds, [
  RepeatRule? repeat,
  List<DateTime>? choices,
]) => (input, title, due, kinds, repeat, choices);

final List<Case> hi = [
  // (input, title, due, kinds, repeat)
  c('kal subah 8 baje dawai', 'Dawai', d(21, 8), {dw}),
  c('कल सुबह 8 बजे दवाई', 'दवाई', d(21, 8), {dw}),
  c('कल सुबह आठ बजे दवाई लेना', 'दवाई लेना', d(21, 8), {dw}),
  c('कल सुबह आठ बजे दवाई लेने की याद दिलाना', 'दवाई लेने', d(21, 8), {dw}),
  c('आज शाम छह बजे मम्मी को फोन करना', 'मम्मी को फोन करना', d(20, 18), null),
  c(
    'हर सोमवार सुबह नौ बजे मीटिंग याद दिलाना',
    'मीटिंग',
    d(23, 9),
    null,
    wk({1}),
  ),
  c('दो घंटे बाद पानी पीने की याद दिलाना', 'पानी पीने', d(20, 16, 30), null),
  c('kal 8 baje', '', d(21, 8), {dw, ap}, null, [d(21, 8), d(21, 20)]),
  c('आज शाम साढ़े 6 बजे', '', d(20, 18, 30), null),
  c('आज शाम साढ़े 6 बजे', '', d(20, 18, 30), null),
  c('पौने 9 बजे सुबह', '', d(21, 8, 45), null),
  c('ढाई बजे', '', d(21, 2, 30), {ap}, null, [d(21, 2, 30), d(21, 14, 30)]),
  c('dedh baje', '', d(21, 1, 30), {ap}, null, [d(21, 1, 30), d(21, 13, 30)]),
  c('2 ghante baad call', 'Call', d(20, 16, 30), null),
  c('har somvar gym', 'Gym', d(23, 16), {nt}, wk({1})),
  c('रोज़ रात 9 बजे दवाई', 'दवाई', d(20, 21), null, daily),
  c('rozana raat 9 baje dawai', 'Dawai', d(20, 21), null, daily),
  c('har roz subah 7 baje', '', d(21, 7), null, daily),
  c('हर दिन सुबह 6 बजे योग', 'योग', d(21, 6), null, daily),
  c('हर सोमवार और शुक्रवार सुबह 7 बजे जिम', 'जिम', d(23, 7), null, wk({1, 5})),
  c('हर रविवार शाम 6 बजे पूजा', 'पूजा', d(22, 18), null, wk({7})),
  c('buy rat poison', 'Buy rat poison', d(20, 16), {nt}),
  c('परसों शाम 5 बजे', '', d(22, 17), {dw}),
  c('parso shaam 6 baje gas', 'Gas', d(22, 18), {dw}),
  c('parso subah 9 baje', '', d(22, 9), {dw}),
  c('kal raat 9 baje', '', d(21, 21), {dw}),
  c('कल gym', 'Gym', d(21, 9), {dw, nt}),
  c('कल', '', d(21, 9), {dw, nt}),
  c('आज रात 11 बजे', '', d(20, 23), null),
  c('raat 10 baje', '', d(20, 22), null),
  c('रात 12 बजे', '', d(21, 0), null),
  c('रात 2 बजे', '', d(21, 2), null),
  c('दोपहर 12 बजे', '', d(21, 12), null),
  c('सुबह 11 बजे', '', d(21, 11), null),
  c('शाम 4 बजे अलार्म', 'अलार्म', d(20, 16), null),
  c('आज शाम 7:30 बजे', '', d(20, 19, 30), null),
  c('सुबह 8:30 बजे दवाई', 'दवाई', d(21, 8, 30), null),
  c('१० बजे रात', '', d(20, 22), null),
  c('कल सुबह ८ बजे दवाई', 'दवाई', d(21, 8), {dw}),
  c('सवा 5 बजे शाम', '', d(20, 17, 15), null),
  c('sadhe 6 baje shaam ko dawai', 'Dawai', d(20, 18, 30), null),
  c('aaj shaam 6 baje', '', d(20, 18), null),
  c('21 बजे', '', d(20, 21), null),
  c('8.45 baje', '', d(20, 20, 45), {ap}, null, [d(20, 20, 45), d(21, 8, 45)]),
  c('25 नवंबर को शाम 6 बजे बिल', 'बिल', d(25, 18), null),
  c('5 दिसंबर सुबह 10 बजे', '', d(5, 10, 0, 12), null),
  c('शुक्रवार', '', d(27, 9), {nt}),
  c('शनिवार सुबह 7 बजे', '', d(21, 7), null),
  c('रविवार को शाम 5 बजे', '', d(22, 17), null),
  c('3 दिन बाद बिल भरना', 'बिल भरना', d(23, 14, 30), null),
  c('10 मिनट बाद चाय', 'चाय', d(20, 14, 40), null),
  c('1 हफ्ते बाद', '', d(27, 14, 30), null),
  c('2 महीने बाद', '', DateTime(2027, 1, 20, 14, 30), null),
  c('call mom कल 8pm', 'Call mom', d(21, 20), {dw}),
  // Night after midnight belongs to the spoken day's night.
  c('आज रात 12 बजे', '', d(21, 0), null),
  c('aaj raat 2 baje', '', d(21, 2), null),
  c('कल रात 12 बजे', '', d(22, 0), {dw}),
  c('कल रात 3 बजे', '', d(22, 3), {dw}),
  c('आज रात 9 बजे', '', d(20, 21), null),
  c('अगले सोमवार सुबह 9 बजे', '', d(23, 9), null),
  c('अगले शुक्रवार शाम 6 बजे', '', d(27, 18), null),
  c('शुक्रवार शाम 6 बजे', '', d(20, 18), null),
  c('agle somvar gym', 'Gym', d(23, 9), {nt}),
  c('हर रोज रात 9 बजे दवाई', 'दवाई', d(20, 21), null, daily),
  c('रोजाना सुबह 7 बजे', '', d(21, 7), null, daily),
  c('डेढ़ घंटे बाद चाय', 'चाय', d(20, 16), null),
  c('ढाई घंटे बाद', '', d(20, 17), null),
  c('आधे घंटे बाद', '', d(20, 15), null),
  c('dedh ghante baad', '', d(20, 16), null),
  // The owner's Hinglish: two anchors, or one touching a number.
  c('Kal 8 baje medicine lena', 'Medicine lena', d(21, 8), {dw, ap}),
  c(
    'aaj shaam 6 baje mummy ko phone karna',
    'Mummy ko phone karna',
    d(20, 18),
    null,
  ),
  c('har somvar subah 9 baje meeting', 'Meeting', d(23, 9), null, wk({1})),
];
final List<Case> bn = [
  c('কাল সকাল আটটায় ওষুধ খেতে মনে করিয়ে দিও', 'ওষুধ খেতে', d(21, 8), {dw}),
  c(
    'আজ সন্ধ্যা ছয়টায় মাকে ফোন করতে হবে',
    'মাকে ফোন করতে হবে',
    d(20, 18),
    null,
  ),
  c(
    'প্রতি সোমবার সকাল নয়টায় মিটিং আছে',
    'মিটিং আছে',
    d(23, 9),
    null,
    wk({1}),
  ),
  c('দুই ঘণ্টা পরে জল খেতে মনে করিয়ে দিও', 'জল খেতে', d(20, 16, 30), null),
  c('কাল সকাল আটটার সময় ওষুধ', 'ওষুধ', d(21, 8), {dw}),
  c('কাল সকাল আটটা ওষুধ', 'ওষুধ', d(21, 8), {dw}),
  c('কাল সকাল ৮টায় ওষুধ', 'ওষুধ', d(21, 8), {dw}),
  c('আগামীকাল সকাল আটটায় ওষুধ', 'ওষুধ', d(21, 8), null),
  c("আজ রাত ন'টা ওষুধ", 'ওষুধ', d(20, 21), null),
  c('আজ রাত ন’টা ওষুধ', 'ওষুধ', d(20, 21), null),
  c('সাড়ে ৫টায় বিকেলে', '', d(20, 17, 30), null),
  c('সোয়া ৬টায় সন্ধ্যায়', '', d(20, 18, 15), null),
  c('পৌনে ৯টায় সকালে', '', d(21, 8, 45), null),
  c('দেড়টায়', '', d(21, 1, 30), {ap}, null, [d(21, 1, 30), d(21, 13, 30)]),
  c('আড়াইটায়', '', d(21, 2, 30), {ap}, null, [d(21, 2, 30), d(21, 14, 30)]),
  c('kal shokal 8 ta oshudh', 'Oshudh', d(21, 8), {dw}),
  c('kaal bikel 4 ta', '', d(21, 16), {dw}),
  c('protidin raat 9 ta', '', d(20, 21), null, daily),
  c('প্রতিদিন সকাল ৭টায় ব্যায়াম', 'ব্যায়াম', d(21, 7), null, daily),
  c('proti shukrobar bikel 5 ta bazar', 'Bazar', d(20, 17), null, wk({5})),
  c('প্রতি শুক্রবার বিকেল ৫টায় বাজার', 'বাজার', d(20, 17), null, wk({5})),
  c('প্রতি সোমবার ও বৃহস্পতিবার সকাল ৯টায়', '', d(23, 9), null, wk({1, 4})),
  c(
    'প্রতি রবিবার ৫টায় মাকে ফোন',
    'মাকে ফোন',
    d(22, 17),
    {ap},
    wk({7}),
    [d(22, 5), d(22, 17)],
  ),
  c('3 din pore', '', d(23, 14, 30), null),
  c('৩ দিন পরে', '', d(23, 14, 30), null),
  c('১০ মিনিট পরে চা', 'চা', d(20, 14, 40), null),
  c('১ সপ্তাহ পরে', '', d(27, 14, 30), null),
  c('২ মাস পরে', '', DateTime(2027, 1, 20, 14, 30), null),
  c('porshu shondhya 6 ta', '', d(22, 18), {dw}),
  c('আজ রাত ১২টায়', '', d(21, 0), null),
  c('কাল রাত ১২টায়', '', d(22, 0), {dw}),
  c('কালকে সকালে ওষুধ', 'ওষুধ', d(21, 8), {dw}),
  c('কালকে সকাল ৮টায় ওষুধ', 'ওষুধ', d(21, 8), {dw}),
  c('আজকে রাতে ৯টায়', '', d(20, 21), null),
  c('পরশুদিন সকাল ৯টায়', '', d(22, 9), {dw}),
  c('আগামীকালকে সকাল ৮টায়', '', d(21, 8), null),
  c('সোমবারে সকাল ৯টায়', '', d(23, 9), null),
  c('আগামী সোমবার সকাল ৯টায়', '', d(23, 9), null),
  c('আগামী শুক্রবার বিকেল ৫টায়', '', d(27, 17), null),
  c('agami robibar', '', d(22, 9), {nt}),
  c('প্রতি দিন সকাল ৭টায় ব্যায়াম', 'ব্যায়াম', d(21, 7), null, daily),
  c('দু ঘণ্টা পরে', '', d(20, 16, 30), null),
  c('ভোর ৫টায়', '', d(21, 5), null),
  c('বিকালে ৪টায়', '', d(20, 16), null),
  c('দেড় ঘণ্টা পরে', '', d(20, 16), null),
  c('আড়াই ঘণ্টা পরে', '', d(20, 17), null),
  c('আধ ঘণ্টা পরে', '', d(20, 15), null),
  // A bare টা/ta counts beside a part of day or বাজে, not as "five eggs".
  c('৫টা ডিম কিনো', '৫টা ডিম কিনো', d(20, 16), {nt}),
  c('তিনটা বই আনো', 'তিনটা বই আনো', d(20, 16), {nt}),
  c('5 ta dim kinbo', '5 ta dim kinbo', d(20, 16), {nt}),
  c('৯টা বাজে', '', d(20, 21), {ap}, null, [d(20, 21), d(21, 9)]),
  c('রাত ৯টা', '', d(20, 21), null),
  c('৫টায় ডিম', 'ডিম', d(20, 17), {ap}, null, [d(20, 17), d(21, 5)]),
  c('পরশু সন্ধ্যা ৬টায়', '', d(22, 18), {dw}),
  c('porshu', '', d(22, 9), {dw, nt}),
  c('কাল', '', d(21, 9), {dw, nt}),
  c('আজ বিকেল ৫টায়', '', d(20, 17), null),
  c('aaj raat 10 ta', '', d(20, 22), null),
  c('রাত ১০টায়', '', d(20, 22), null),
  c('রাত ১২টায়', '', d(21, 0), null),
  c('রাত ২টায়', '', d(21, 2), null),
  c('সকাল ১০টায়', '', d(21, 10), null),
  c('দুপুর ১২টায়', '', d(21, 12), null),
  c('সকাল ৮:৩০টায়', '', d(21, 8, 30), null),
  c('শনিবার সকাল ৭টায়', '', d(21, 7), null),
  c('রবিবার', '', d(22, 9), {nt}),
  c('২৫ নভেম্বর সন্ধ্যা ৭টায় বিল', 'বিল', d(25, 19), null),
  c('৫ ডিসেম্বর', '', d(5, 9, 0, 12), {nt}),
  c('Tomorrow সকাল আটটায় medicine', 'Medicine', d(21, 8), null),
  c('মাকে call করব tomorrow at 6 PM', 'মাকে call করব', d(21, 18), null),
];

/// Every part of day against every spoken hour 1-12: the window's reading,
/// or unsure where the part has none. (part word, spoken hour → 24h hour)
typedef Windows = (String, Map<int, int>);
Map<int, int> hrs(int from, int to, int plus) => {
  for (var h = from; h <= to; h++) h: h % 12 + plus,
};
final hiParts = <Windows>[
  ('सुबह', hrs(4, 11, 0)),
  ('दोपहर', {...hrs(12, 12, 12), ...hrs(1, 4, 12)}),
  ('शाम', hrs(3, 11, 12)),
  ('रात', {...hrs(7, 11, 12), 12: 0, ...hrs(1, 5, 0)}),
];
final bnParts = <Windows>[
  ('সকাল', hrs(4, 11, 0)),
  ('ভোর', hrs(3, 7, 0)),
  ('দুপুর', {...hrs(12, 12, 12), ...hrs(1, 4, 12)}),
  ('বিকেল', hrs(3, 6, 12)),
  ('বিকাল', hrs(3, 6, 12)),
  ('সন্ধ্যা', hrs(5, 9, 12)),
  ('রাত', {...hrs(7, 11, 12), 12: 0, ...hrs(1, 5, 0)}),
];

void windowTests(String language, List<Windows> parts, String clock) {
  for (final (word, table) in parts) {
    for (var h = 1; h <= 12; h++) {
      test('$language: $word $h', () {
        final p = parseReminder('$word $h$clock', now: now, language: language);
        if (table[h] case final want?) {
          expect(p.ambiguity, isNull);
          expect(p.dueAt.hour, want);
        } else {
          expect(p.ambiguity?.kinds, {ap});
          expect(
            p.ambiguity!.choices.map((c) => c.hour % 12),
            everyElement(h % 12),
          );
        }
      });
    }
  }
}

void run(String language, List<Case> cases) {
  for (final (input, title, due, kinds, repeat, choices) in cases) {
    test('$language: $input', () {
      final p = parseReminder(
        input,
        now: now,
        language: language,
        latinPacks: true,
      );
      expect(p.title, title);
      expect(p.dueAt, due);
      expect(p.ambiguity?.kinds, kinds);
      expect(p.repeat, repeat ?? RepeatRule.none);
      if (choices != null) expect(p.ambiguity!.choices, choices);
      if (kinds != null) {
        expect(
          p.ambiguity!.choices,
          everyElement(predicate<DateTime>((c) => c.isAfter(now))),
        );
      }
      // Spans index the original text and never cut a surrogate pair.
      for (final s in [...p.timeSpans, ?p.repeatSpan, ?p.ambiguity?.span]) {
        expect(s.start, lessThan(s.end), reason: '$s');
        expect(s.end, lessThanOrEqualTo(input.length));
        final text = input.substring(s.start, s.end);
        expect(text.trim(), isNotEmpty);
        expect(String.fromCharCodes(text.codeUnits), text);
        // Whole pairs only: no leading low or trailing high surrogate.
        expect(text.codeUnits.first & 0xFC00, isNot(0xDC00), reason: '$s');
        expect(text.codeUnits.last & 0xFC00, isNot(0xD800), reason: '$s');
      }
    });
  }
}

void main() {
  group('hi', () => run('hi', hi));
  group('bn', () => run('bn', bn));

  group('part-of-day windows', () {
    windowTests('hi', hiParts, ' बजे');
    windowTests('bn', bnParts, 'টায়');
  });

  test('corpus size', () {
    expect(hi.length, greaterThanOrEqualTo(40));
    expect(bn.length, greaterThanOrEqualTo(40));
  });

  test('spans quote the original words, native digits included', () {
    const text = 'कल सुबह ८ बजे दवाई';
    final p = parseReminder(text, now: now, language: 'hi');
    expect(
      [for (final s in p.timeSpans) text.substring(s.start, s.end)],
      ['कल', 'सुबह', '८ बजे'],
    );
    expect(
      text.substring(p.ambiguity!.span!.start, p.ambiguity!.span!.end),
      'कल',
    );
  });

  test('mixed scripts: spans stay on the original string', () {
    const text = 'মাকে call করব tomorrow at 6 PM';
    final p = parseReminder(text, now: now, language: 'bn');
    expect(
      [for (final s in p.timeSpans) text.substring(s.start, s.end)],
      ['tomorrow', 'at 6 PM'],
    );
    // A day word after a Bengali word; the span covers the pack word only.
    const t2 = 'মাকে ফোন কাল ৮টায়';
    final q = parseReminder(t2, now: now, language: 'bn');
    expect(
      t2.substring(q.ambiguity!.span!.start, q.ambiguity!.span!.end),
      'কাল ৮টায়',
    );
  });

  test('a surrogate pair beside a pack word does not shift spans', () {
    const text = '\u{1F600} kal 8 baje';
    final p = parseReminder(text, now: now, language: 'hi', latinPacks: true);
    final s = p.ambiguity!.span!;
    expect(text.substring(s.start, s.end), 'kal 8 baje');
    expect(p.title, '\u{1F600}');
  });

  test('"kal 8 baje" only parses when Latin packs are on', () {
    final off = parseReminder('kal 8 baje', now: now, language: 'hi');
    expect(off.timeGuessed, isTrue);
    expect(off.title, 'Kal 8 baje');
    final on = parseReminder('kal 8 baje', now: now, latinPacks: true);
    expect(on.timeGuessed, isFalse);
  });

  test('"sham marriage talk" stays text unless Latin packs are on', () {
    final p = parseReminder('sham marriage talk', now: now, language: 'hi');
    expect(p.timeGuessed, isTrue);
    expect(p.title, 'Sham marriage talk');
    expect(p.timeSpans, isEmpty);
  });

  test('native script works with Latin packs off, in either language', () {
    for (final lang in ['en', 'hi', 'bn']) {
      final h = parseReminder('कल सुबह आठ बजे', now: now, language: lang);
      expect(h.dueAt, d(21, 8));
      final b = parseReminder('কাল সকাল আটটায়', now: now, language: lang);
      expect(b.dueAt, d(21, 8));
    }
  });

  test('a day word never picks silently', () {
    for (final t in ['कल 9 बजे', 'কাল ৯টায়', 'परसों', 'পরশু']) {
      expect(
        parseReminder(t, now: now).ambiguity?.kinds,
        contains(AmbiguityKind.dayWord),
        reason: t,
      );
    }
  });

  test('Latin words that are also English stay text, even with packs on', () {
    for (final (t, word) in [
      ('Call Kal at 5pm', 'kal'),
      ('Raat Records', 'raat'),
      ('Section 8 TA meeting', 'ta'),
      ('kal gym', 'kal'),
    ]) {
      final p = parseReminder(t, now: now, language: 'hi', latinPacks: true);
      expect(p.ambiguity?.kinds.contains(dw), isNot(true), reason: t);
      expect(p.title.toLowerCase(), contains(word), reason: t);
    }
  });

  test('a lone ZWNJ or ZWJ is not a title', () {
    for (final z in ['\u200C', '\u200D']) {
      final p = parseReminder('কাল $z সকাল ৮টায়', now: now);
      expect(p.title, '');
    }
  });

  test('unicode tags', () {
    final p = parseReminder('দবা #দবা', now: now, knownTags: ['দবা']);
    expect(p.tag, 'দবা');
    expect(p.title, 'দবা');
    final h = parseReminder('milk #दवा', now: now);
    expect(h.tag, 'दवा');
    expect(parseReminder('milk #home-1', now: now).tag, 'home-1');
  });
}
