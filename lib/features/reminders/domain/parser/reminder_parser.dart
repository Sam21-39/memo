import '../entities/repeat_rule.dart';

/// Which part of the input a parsed value came from, so its chip can
/// highlight the words. [start] inclusive, [end] exclusive, into the original.
class SourceSpan {
  const SourceSpan(this.start, this.end);
  final int start;
  final int end;

  @override
  bool operator ==(Object other) =>
      other is SourceSpan && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'SourceSpan($start, $end)';
}

class ParsedReminder {
  const ParsedReminder({
    required this.title,
    required this.dueAt,
    required this.timeGuessed,
    this.repeat = RepeatRule.none,
    this.tag,
    this.timeSpans = const [],
    this.repeatSpan,
    this.tagSpan,
  });

  /// What is left once every match is removed, trimmed.
  final String title;
  final DateTime dueAt;

  /// No time was found: [dueAt] is a default the chip shows as dashed.
  final bool timeGuessed;
  final RepeatRule repeat;
  final String? tag;

  /// Every span that fed [dueAt]: a date and a time can be separate words.
  final List<SourceSpan> timeSpans;
  final SourceSpan? repeatSpan;
  final SourceSpan? tagSpan;
}

const _weekdays = {
  'monday': 1,
  'mon': 1,
  'tuesday': 2,
  'tue': 2,
  'tues': 2,
  'wednesday': 3,
  'wed': 3,
  'thursday': 4,
  'thu': 4,
  'thur': 4,
  'thurs': 4,
  'friday': 5,
  'fri': 5,
  'saturday': 6,
  'sat': 6,
  'sunday': 7,
  'sun': 7,
};

const _months = {
  'jan': 1,
  'january': 1,
  'feb': 2,
  'february': 2,
  'mar': 3,
  'march': 3,
  'apr': 4,
  'april': 4,
  'may': 5,
  'jun': 6,
  'june': 6,
  'jul': 7,
  'july': 7,
  'aug': 8,
  'august': 8,
  'sep': 9,
  'sept': 9,
  'september': 9,
  'oct': 10,
  'october': 10,
  'nov': 11,
  'november': 11,
  'dec': 12,
  'december': 12,
};

/// Named times of day. Spec: tonight 20:00, morning 08:00, noon.
const _namedTimes = {
  'noon': (12, 0),
  'midday': (12, 0),
  'midnight': (0, 0),
  'tonight': (20, 0),
  'morning': (8, 0),
  'afternoon': (15, 0),
  'evening': (18, 0),
};

final _dayAlt = _weekdays.keys.join('|');
final _monthAlt = _months.keys.join('|');

/// English, rules not ML, pure. Sub-millisecond, so it runs on the UI
/// isolate as the user types.
///
/// Every match is blanked out of a working copy (same length, so spans stay
/// valid against the original) and what remains is the title.
///
/// ponytail: English-only regex rules, per the spec. A locale means a second
/// rule table, not a framework.
ParsedReminder parseReminder(
  String input, {
  required DateTime now,
  List<String> knownTags = const [],
}) {
  var work = input.toLowerCase();

  RegExpMatch? take(RegExp re) {
    final m = re.firstMatch(work);
    if (m != null) {
      work = work.replaceRange(m.start, m.end, ' ' * (m.end - m.start));
    }
    return m;
  }

  SourceSpan spanOf(RegExpMatch m, [int group = 0]) =>
      SourceSpan(m.start, m.end);

  // ── Repeat ──────────────────────────────────────────────────────────────
  var repeat = RepeatRule.none;
  SourceSpan? repeatSpan;
  final everyDays = take(
    RegExp(r'\bevery\s+((?:(?:' + _dayAlt + r')\b(?:\s*(?:,|and|&)?\s*)?)+)'),
  );
  if (everyDays != null) {
    final days = RegExp(r'\b(' + _dayAlt + r')\b')
        .allMatches(everyDays.group(1)!)
        .map((d) => _weekdays[d.group(1)]!)
        .toSet();
    repeat = RepeatRule(RepeatType.weekly, weekdays: days);
    repeatSpan = spanOf(everyDays);
  } else if (take(RegExp(r'\b(?:every\s*day|daily|each\s+day)\b'))
      case final m?) {
    repeat = RepeatRule.daily;
    repeatSpan = spanOf(m);
  } else if (take(RegExp(r'\b(?:every\s+)?weekdays?\b')) case final m?) {
    repeat = const RepeatRule(RepeatType.weekly, weekdays: {1, 2, 3, 4, 5});
    repeatSpan = spanOf(m);
  } else if (take(RegExp(r'\b(?:every\s+)?weekends?\b')) case final m?) {
    repeat = const RepeatRule(RepeatType.weekly, weekdays: {6, 7});
    repeatSpan = spanOf(m);
  } else if (take(RegExp(r'\b(?:every\s+week|weekly)\b')) case final m?) {
    repeat = RepeatRule(RepeatType.weekly, weekdays: {now.weekday});
    repeatSpan = spanOf(m);
  }

  // ── Tag ─────────────────────────────────────────────────────────────────
  String? tag;
  SourceSpan? tagSpan;
  if (take(RegExp(r'(?:^|\s)#([\w-]+)')) case final m?) {
    final raw = input.substring(m.end - m.group(1)!.length, m.end);
    tag = _matchTag(raw, knownTags) ?? raw;
    tagSpan = SourceSpan(m.end - raw.length - 1, m.end);
  } else {
    final forTag = RegExp(r'\bfor\s+([\w-]+)\s*$').firstMatch(work.trimRight());
    final known = forTag == null
        ? null
        : _matchTag(forTag.group(1)!, knownTags);
    if (forTag != null && known != null) {
      work = work.replaceRange(
        forTag.start,
        forTag.end,
        ' ' * (forTag.end - forTag.start),
      );
      tag = known;
      tagSpan = SourceSpan(forTag.start, forTag.end);
    }
  }

  // ── Relative: "in 45 min", "in 2 hours" ─────────────────────────────────
  final timeSpans = <SourceSpan>[];
  DateTime? exact;
  if (take(
        RegExp(
          r'\bin\s+(an?|\d+(?:\.\d+)?|half\s+an?)\s*'
          r'(minutes?|mins?|m|hours?|hrs?|h|days?|d|weeks?|w|months?|mos?|years?|yrs?|y)\b',
        ),
      )
      case final m?) {
    final qty = m.group(1)!;
    final amount = qty.startsWith('half')
        ? 0.5
        : (qty == 'a' || qty == 'an')
        ? 1.0
        : double.parse(qty);
    final unit = m.group(2)!;
    final n = amount.round();
    exact = unit.startsWith('mo')
        ? _addMonths(now, n)
        : unit.startsWith('y')
        ? _addMonths(now, 12 * n)
        : switch (unit[0]) {
            'm' => now.add(Duration(minutes: n)),
            'h' => now.add(Duration(minutes: (amount * 60).round())),
            'd' => DateTime(
              now.year,
              now.month,
              now.day + n,
              now.hour,
              now.minute,
            ),
            _ => DateTime(
              now.year,
              now.month,
              now.day + 7 * n,
              now.hour,
              now.minute,
            ),
          };
    timeSpans.add(spanOf(m));
  }

  // ── Date ────────────────────────────────────────────────────────────────
  DateTime? day;
  var fromWeekday = false;
  final today = DateTime(now.year, now.month, now.day);
  if (exact == null) {
    final beforeDate = work;
    if (take(RegExp(r'\b(?:day\s+after\s+tomorrow)\b')) case final m?) {
      day = DateTime(now.year, now.month, now.day + 2);
      timeSpans.add(spanOf(m));
    } else if (take(RegExp(r'\b(?:tomorrow|tmrw|tmr|tomo)\b')) case final m?) {
      day = DateTime(now.year, now.month, now.day + 1);
      timeSpans.add(spanOf(m));
    } else if (take(RegExp(r'\btoday\b')) case final m?) {
      day = today;
      timeSpans.add(spanOf(m));
    } else if (take(
          RegExp(
            r'\b(\d{1,2})(?:st|nd|rd|th)?\s+(' +
                _monthAlt +
                r')(?:\s+(\d{4}))?\b',
          ),
        )
        case final m?) {
      final mo = _months[m.group(2)]!;
      final d = int.parse(m.group(1)!);
      day = m.group(3) == null
          ? _futureDate(d, mo, today)
          : _explicitDate(int.parse(m.group(3)!), mo, d);
      if (day == null) {
        work = beforeDate;
      } else {
        timeSpans.add(spanOf(m));
      }
    } else if (take(
          RegExp(
            r'\b(' +
                _monthAlt +
                r')\s+(\d{1,2})(?:st|nd|rd|th)?(?:\s+(\d{4}))?\b',
          ),
        )
        case final m?) {
      final mo = _months[m.group(1)]!;
      final d = int.parse(m.group(2)!);
      day = m.group(3) == null
          ? _futureDate(d, mo, today)
          : _explicitDate(int.parse(m.group(3)!), mo, d);
      if (day == null) {
        work = beforeDate;
      } else {
        timeSpans.add(spanOf(m));
      }
    } else if (take(RegExp(r'\b(\d{1,2})/(\d{1,2})(?:/(\d{2,4}))?\b'))
        case final m?) {
      // Day first: the owner's locale (India, UK) writes 03/11 for 3 Nov.
      final d = int.parse(m.group(1)!), mo = int.parse(m.group(2)!);
      final y = m.group(3);
      if (mo >= 1 && mo <= 12 && d >= 1 && d <= 31) {
        day = y == null
            ? _futureDate(d, mo, today)
            : _explicitDate(
                y.length == 2 ? 2000 + int.parse(y) : int.parse(y),
                mo,
                d,
              );
      }
      if (day == null) {
        work = beforeDate;
      } else {
        timeSpans.add(spanOf(m));
      }
    } else if (take(RegExp(r'\b(?:on\s+)?the\s+(\d{1,2})(?:st|nd|rd|th)\b'))
        case final m?) {
      day = _nextOrdinal(int.parse(m.group(1)!), today);
      if (day == null) {
        work = beforeDate;
      } else {
        timeSpans.add(spanOf(m));
      }
    }
    // "on friday", "next fri", "friday" — only when it is not a repeat, and
    // no date was taken (a rejected "31/04 friday" still reads friday).
    if (day == null && repeat.type == RepeatType.none) {
      if (take(RegExp(r'\b(?:on\s+|next\s+|this\s+)?(' + _dayAlt + r')\b'))
          case final m?) {
        final target = _weekdays[m.group(1)]!;
        var ahead = (target - now.weekday) % 7;
        if (m.group(0)!.startsWith('next') && ahead == 0) ahead = 7;
        day = DateTime(now.year, now.month, now.day + ahead);
        fromWeekday = true;
        timeSpans.add(spanOf(m));
      }
    }
  }

  // ── Time of day ─────────────────────────────────────────────────────────
  int? hour, minute;
  var ambiguous = false;
  if (exact == null) {
    if (take(
          RegExp(
            r'(?:\b(?:at|by)\s+|@\s*)?\b(\d{1,2})(?:[:.](\d{2}))?\s*'
            r'(a\.?m\.?|p\.?m\.?)(?=\W|$)',
          ),
        )
        case final m?) {
      hour = int.parse(m.group(1)!) % 12;
      if (m.group(3)!.startsWith('p')) hour += 12;
      minute = int.tryParse(m.group(2) ?? '') ?? 0;
      timeSpans.add(spanOf(m));
    } else if (take(
          RegExp(r'(?:\b(?:at|by)\s+|@\s*)?\b([01]?\d|2[0-3])[:.]([0-5]\d)\b'),
        )
        case final m?) {
      hour = int.parse(m.group(1)!);
      minute = int.parse(m.group(2)!);
      // "8:30" with no am/pm is as ambiguous as "at 8"; "20:00" is not.
      ambiguous = hour >= 1 && hour <= 12 && !m.group(1)!.startsWith('0');
      timeSpans.add(spanOf(m));
    } else if (take(RegExp(r'(?:\bat\s+|@\s*)?\b(noon|midday|midnight)\b'))
        case final m?) {
      (hour, minute) = _namedTimes[m.group(1)]!;
      timeSpans.add(spanOf(m));
    } else if (take(
          RegExp(r'(?:\bat\s*|@\s*)(\d{1,2})\b(?!\s*(?:min|hour|h\b))'),
        )
        case final m?) {
      final h = int.parse(m.group(1)!);
      if (h <= 23) {
        hour = h;
        minute = 0;
        ambiguous = h >= 1 && h <= 12;
        timeSpans.add(spanOf(m));
      }
    }
    // "tonight" / "this morning" set both a part of day and, absent a
    // clock time, the time itself. "at 8 tonight" means 20:00.
    if (take(
          RegExp(
            r'\b(?:this\s+|in\s+the\s+)?(tonight|morning|afternoon|evening)\b',
          ),
        )
        case final m?) {
      final part = m.group(1)!;
      timeSpans.add(spanOf(m));
      if (hour == null) {
        (hour, minute) = _namedTimes[part]!;
      } else if (ambiguous) {
        final pm = part != 'morning';
        if (pm && hour < 12) hour += 12;
        if (!pm && hour == 12) hour = 0;
        ambiguous = false;
      }
    }
  }

  // ── Combine ─────────────────────────────────────────────────────────────
  var guessed = false;
  DateTime due;
  if (exact != null) {
    due = exact;
  } else if (hour != null) {
    final base = day ?? today;
    DateTime at(int h) => DateTime(base.year, base.month, base.day, h, minute!);
    if (ambiguous) {
      // "at 8" is the next 8:00 or 20:00 that is still ahead.
      // "at 12" is noon or the midnight that follows it.
      final candidates = [
        at(hour),
        if (hour == 12)
          DateTime(base.year, base.month, base.day + 1, 0, minute!)
        else
          at(hour + 12),
      ]..sort();
      due = candidates.firstWhere(
        (c) => c.isAfter(now),
        orElse: () =>
            DateTime(base.year, base.month, base.day + 1, hour!, minute!),
      );
    } else {
      due = at(hour);
      if (day == null && !due.isAfter(now)) {
        due = DateTime(now.year, now.month, now.day + 1, hour, minute!);
      }
    }
  } else if (day != null) {
    // A date with no time: 09:00, shown as a guess.
    due = DateTime(day.year, day.month, day.day, 9);
    if (!fromWeekday && !due.isAfter(now)) {
      // Today, and 09:00 already passed: the same guess as no date at all.
      final soon = now.add(const Duration(minutes: 30));
      due = DateTime(soon.year, soon.month, soon.day, soon.hour + 1);
    }
    guessed = true;
  } else {
    // Nothing: the next whole hour at least 30 min away, shown as a guess.
    final soon = now.add(const Duration(minutes: 30));
    due = DateTime(soon.year, soon.month, soon.day, soon.hour + 1);
    guessed = true;
  }

  // "friday" said on a Friday after the time means next Friday.
  if (fromWeekday && !due.isAfter(now)) {
    due = DateTime(due.year, due.month, due.day + 7, due.hour, due.minute);
  }

  // A weekly rule with no date starts on its first picked day.
  if (repeat.type == RepeatType.weekly && day == null && exact == null) {
    while (!repeat.weekdays.contains(due.weekday) || !due.isAfter(now)) {
      due = DateTime(due.year, due.month, due.day + 1, due.hour, due.minute);
    }
  } else if (repeat.type == RepeatType.daily && !due.isAfter(now)) {
    due = DateTime(due.year, due.month, due.day + 1, due.hour, due.minute);
  }

  return ParsedReminder(
    title: _title(input, work),
    dueAt: due,
    timeGuessed: guessed,
    repeat: repeat,
    tag: tag,
    timeSpans: timeSpans..sort((a, b) => a.start.compareTo(b.start)),
    repeatSpan: repeatSpan,
    tagSpan: tagSpan,
  );
}

String? _matchTag(String word, List<String> knownTags) {
  final w = word.toLowerCase();
  for (final t in knownTags) {
    if (t.toLowerCase() == w) return t;
  }
  return null;
}

bool _valid(int y, int m, int d) {
  final t = DateTime(y, m, d);
  return t.month == m && t.day == d;
}

/// The next [d]/[mo] that is today or later; null when none exists within
/// four years (29 Feb 2027 has no 29th, so 29 Feb rolls to 2028).
DateTime? _futureDate(int d, int mo, DateTime today) {
  for (var y = today.year; y <= today.year + 4; y++) {
    if (!_valid(y, mo, d)) continue;
    final t = DateTime(y, mo, d);
    if (!t.isBefore(today)) return t;
  }
  return null;
}

/// A date with its year given: null when the day does not exist (29 Feb 2027).
DateTime? _explicitDate(int y, int mo, int d) =>
    _valid(y, mo, d) ? DateTime(y, mo, d) : null;

/// The next [n]th of a month that is today or later; null for a day no
/// month has (the 31st of a 30-day month is skipped, not rolled).
DateTime? _nextOrdinal(int n, DateTime today) {
  for (var i = 0; i <= 12; i++) {
    final t = DateTime(today.year, today.month + i, n);
    if (t.day == n && !t.isBefore(today)) return t;
  }
  return null;
}

/// Same wall-clock time, [n] months on; the day clamps to the month's end.
DateTime _addMonths(DateTime t, int n) {
  final month = t.month + n;
  final lastDay = DateTime(t.year, month + 1, 0).day;
  return DateTime(t.year, month, t.day.clamp(1, lastDay), t.hour, t.minute);
}

/// Characters of [input] that survived in [work], with leftover glue words
/// and a "remind me to" prefix trimmed.
String _title(String input, String work) {
  final kept = StringBuffer();
  for (var i = 0; i < input.length; i++) {
    kept.write(work[i] == ' ' && input[i] != ' ' ? ' ' : input[i]);
  }
  var t = kept.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  const glue = r'(?:at|on|by|to|for|and|every|this|the|next|,|-)';
  t = t.replaceFirst(
    RegExp(r'^(?:remind\s+me\s+(?:to\s+)?)', caseSensitive: false),
    '',
  );
  t = t.replaceFirst(RegExp(r'^(?:to\s+)', caseSensitive: false), '');
  for (var i = 0; i < 3; i++) {
    t = t
        .replaceFirst(RegExp('\\s*\\b$glue\\s*\$', caseSensitive: false), '')
        .replaceFirst(RegExp(r'[\s,.;:-]+$'), '')
        .trim();
  }
  t = t.replaceAll(RegExp(r'\s+([,.!?])'), r'$1');
  if (t.isEmpty) return t;
  return t[0].toUpperCase() + t.substring(1);
}
