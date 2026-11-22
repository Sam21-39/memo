import '../entities/repeat_rule.dart';
import 'parser_packs.dart';

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

enum AmbiguityKind { amPm, noTime, dayWord }

/// A time the parser could not settle. [choices] are complete date-times,
/// soonest first, all in the future; the UI makes the user pick one.
class TimeAmbiguity {
  const TimeAmbiguity(this.kinds, this.choices, {this.span});
  final Set<AmbiguityKind> kinds;
  final List<DateTime> choices;

  /// The words that were unclear, for the reason line.
  final SourceSpan? span;
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
    this.ambiguity,
  });

  /// What is left once every match is removed, trimmed.
  final String title;
  final DateTime dueAt;

  /// No time was found: [dueAt] is a default the chip shows as dashed.
  // kept: read by tests only, true exactly when the noTime ambiguity is set
  final bool timeGuessed;
  final RepeatRule repeat;
  final String? tag;

  /// Every span that fed [dueAt]: a date and a time can be separate words.
  final List<SourceSpan> timeSpans;
  final SourceSpan? repeatSpan;
  final SourceSpan? tagSpan;

  /// Set when [dueAt] is a guess; [dueAt] itself is unchanged by it.
  final TimeAmbiguity? ambiguity;
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

/// English, Hindi and Bengali; rules not ML, pure. Sub-millisecond, so it
/// runs on the UI isolate as the user types.
///
/// English rules run first. Hindi and Bengali tables (`parser_packs.dart`)
/// only fill what English found nothing for, [language] first, so mixed
/// input works. [latinPacks] turns on their Latin spellings ("kal", "baje")
/// when the input shows intent (see [_latinIntent]); off, only native script
/// matches and English input is unaffected.
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
  String language = 'en',
  bool latinPacks = false,
}) {
  // ASCII-only lowering and Devanagari/Bengali digits to 0-9, one code unit
  // each: length never changes, so spans stay valid.
  var work = input.replaceAllMapped(RegExp('[A-Z\u0966-\u096F\u09E6-\u09EF]'), (
    m,
  ) {
    final c = m[0]!.codeUnitAt(0);
    return c < 0x80
        ? m[0]!.toLowerCase()
        : String.fromCharCode(0x30 + (c >= 0x9E6 ? c - 0x9E6 : c - 0x966));
  });

  final rules = _rulesFor(language, latinPacks && _latinIntent(work, language));

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
  } else {
    for (final r in rules) {
      if (take(r.every) case final m?) {
        repeat = RepeatRule(
          RepeatType.weekly,
          weekdays: {
            for (final d in r.weekday.allMatches(m.group(1)!))
              r.weekdays[_canon(d[0]!)]!,
          },
        );
        repeatSpan = spanOf(m);
        break;
      } else if (take(r.daily) case final m?) {
        repeat = RepeatRule.daily;
        repeatSpan = spanOf(m);
        break;
      }
    }
  }

  // ── Tag ─────────────────────────────────────────────────────────────────
  String? tag;
  SourceSpan? tagSpan;
  // Unicode letters so "#दवा" works. English side effect: "#café" is the tag
  // "café", not "caf" plus a stray "é". ASCII tags are unchanged.
  if (take(RegExp(r'(?:^|\s)#([\p{L}\p{M}\p{N}_-]+)', unicode: true))
      case final m?) {
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
  // [unit]: English word or a pack code (m, h, d, w, mo, y).
  DateTime ahead(double amount, String unit) {
    final n = amount.round();
    return unit.startsWith('mo')
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
  }

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
    exact = ahead(amount, m.group(2)!);
    timeSpans.add(spanOf(m));
  } else {
    for (final r in rules) {
      if (take(r.relative) case final m?) {
        exact = ahead(r.amount(m.group(1)!)!, r.units[_canon(m[2]!)]!);
        timeSpans.add(spanOf(m));
        break;
      }
    }
  }

  // ── Date ────────────────────────────────────────────────────────────────
  DateTime? day;
  var fromWeekday = false;
  SourceSpan? dayWordSpan;
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
    for (final r in rules) {
      if (day != null) break;
      final before = work;
      int? plus;
      RegExpMatch? dm;
      if (take(r.dayAfter) case final m?) {
        (plus, dm) = (2, m);
      } else if (take(r.tomorrow) case final m?) {
        (plus, dm) = (1, m);
      } else if (take(r.today) case final m?) {
        (plus, dm) = (0, m);
      }
      if (dm != null) {
        day = DateTime(now.year, now.month, now.day + plus!);
        timeSpans.add(spanOf(dm));
        // "कल" is yesterday or tomorrow: the future reading, then ask.
        if (r.ambiguous.contains(_canon(dm[0]!))) dayWordSpan = spanOf(dm);
      } else if (take(r.month) case final m?) {
        day = _futureDate(
          int.parse(m.group(1)!),
          r.months[_canon(m.group(2)!)]!,
          today,
        );
        if (day == null) {
          work = before;
        } else {
          timeSpans.add(spanOf(m));
        }
      } else if ((repeat.type == RepeatType.none ? take(r.weekdayNext) : null)
          case final m?) {
        var ahead = (r.weekdays[_canon(m[2]!)]! - now.weekday) % 7;
        if (m[1] != null && ahead == 0) ahead = 7;
        day = DateTime(now.year, now.month, now.day + ahead);
        fromWeekday = true;
        timeSpans.add(spanOf(m));
      }
    }
  }

  // ── Time of day ─────────────────────────────────────────────────────────
  int? hour, minute;
  var ambiguous = false, nightWrap = false;
  SourceSpan? clockSpan;
  // "8 बजे", "साढ़े 6 बजे", "ढाई बजे": (hour, minute, ambiguous, match).
  (int, int, bool, RegExpMatch)? takeClock() {
    for (final r in rules) {
      if (take(r.special) case final m?) {
        final (h, mi) = r.specials[_canon(m.group(1)!)]!;
        return (h, mi, true, m);
      }
      for (final m in r.clock.allMatches(work)) {
        final raw = m.group(2)!;
        var h = r.number(raw)!;
        var mi = int.tryParse(m.group(3) ?? '') ?? 0;
        final frac = m.group(1) == null
            ? null
            : r.fractions[_canon(m.group(1)!)]!;
        if (h > 23 || mi > 59 || (frac != null && (h < 1 || h > 12))) continue;
        // "৫টা ডিম" is five eggs: a bare টা/ta needs a part of day beside it.
        if (r.weakClock.contains(_canon(m.group(4)!)) &&
            m.group(5) == null &&
            !(r.partBefore.hasMatch(work.substring(0, m.start)) ||
                r.partAfter.hasMatch(work.substring(m.end)))) {
          continue;
        }
        final amb = h >= 1 && h <= 12 && !raw.startsWith('0');
        if (frac != null) {
          // "पौने 9" is 8:45; "पौने 1" is 12:45.
          if (frac < 0) h = h == 1 ? 12 : h - 1;
          mi = frac < 0 ? 60 + frac : frac;
        }
        work = work.replaceRange(m.start, m.end, ' ' * (m.end - m.start));
        return (h, mi, amb, m);
      }
    }
    return null;
  }

  if (exact == null) {
    if (takeClock() case (final h, final mi, final amb, final m)?) {
      hour = h;
      minute = mi;
      ambiguous = amb;
      timeSpans.add(clockSpan = spanOf(m));
    } else if (take(
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
      timeSpans.add(clockSpan = spanOf(m));
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
        timeSpans.add(clockSpan = spanOf(m));
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
    } else {
      for (final r in rules) {
        if (take(r.part) case final m?) {
          timeSpans.add(spanOf(m));
          final (ph, pm, windows) = r.parts[_canon(m[0]!)]!;
          if (hour == null) {
            (hour, minute) = (ph, pm);
          } else if (ambiguous) {
            // Only the part's own hours settle it: "raat 12" is 00:00,
            // "shaam 6" 18:00. Any other ("subah 1") stays unsure.
            for (final (lo, hi, isPm) in windows) {
              if (hour! >= lo && hour <= hi) {
                hour = hour % 12 + (isPm ? 12 : 0);
                ambiguous = false;
                // The night that starts today ends after midnight.
                nightWrap = hour < 5 && ph >= 18;
                break;
              }
            }
          }
          break;
        }
      }
    }
  }

  // ── Combine ─────────────────────────────────────────────────────────────
  var guessed = false;
  TimeAmbiguity? ambiguity;
  DateTime due;
  if (exact != null) {
    due = exact;
  } else if (hour != null) {
    var base = day ?? today;
    // "कल रात 12 बजे" is the end of the 21st's night: 22 Nov 00:00. With no
    // day word the roll-forward below already finds the next one.
    if (nightWrap && day != null) {
      base = DateTime(base.year, base.month, base.day + 1);
    }
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
      // Same candidates as [due], every one in the future. With no date a
      // passed one rolls to tomorrow; a dated day keeps only what is ahead
      // (or, when none is, rolls as [due] does).
      DateTime next(DateTime c) =>
          DateTime(c.year, c.month, c.day + 1, c.hour, c.minute);
      var choices = day == null
          ? [for (final c in candidates) c.isAfter(now) ? c : next(c)]
          : candidates.where((c) => c.isAfter(now)).toList();
      if (choices.isEmpty) choices = [for (final c in candidates) next(c)];
      // One reading left (a dated day, the other already passed): [due] is
      // that reading, nothing to ask.
      if (choices.length > 1) {
        ambiguity = TimeAmbiguity(
          const {AmbiguityKind.amPm},
          (choices..sort()),
          span: clockSpan,
        );
      }
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
  // "friday" said on a Friday after the time means next Friday; a weekly
  // rule with no date starts on its first picked day; a daily one on the
  // next time that is ahead. Applied to the choices too, so a pick is valid.
  DateTime settle(DateTime d) {
    if (fromWeekday && !d.isAfter(now)) {
      d = DateTime(d.year, d.month, d.day + 7, d.hour, d.minute);
    }
    if (repeat.type == RepeatType.weekly && day == null && exact == null) {
      while (!repeat.weekdays.contains(d.weekday) || !d.isAfter(now)) {
        d = DateTime(d.year, d.month, d.day + 1, d.hour, d.minute);
      }
    } else if (repeat.type == RepeatType.daily && !d.isAfter(now)) {
      d = DateTime(d.year, d.month, d.day + 1, d.hour, d.minute);
    }
    return d;
  }

  due = settle(due);
  if (guessed) {
    ambiguity = TimeAmbiguity(const {AmbiguityKind.noTime}, [due]);
  } else if (ambiguity != null) {
    ambiguity = TimeAmbiguity(
      ambiguity.kinds,
      ({for (final c in ambiguity.choices) settle(c)}.toList()..sort()),
      span: ambiguity.span,
    );
  }
  if (dayWordSpan case final w?) {
    // The future reading is [due]; the user confirms it.
    final a = ambiguity;
    final s = a?.span;
    ambiguity = TimeAmbiguity(
      {AmbiguityKind.dayWord, ...?a?.kinds},
      a?.choices ?? [due],
      span: s == null
          ? w
          : SourceSpan(
              s.start < w.start ? s.start : w.start,
              s.end > w.end ? s.end : w.end,
            ),
    );
  }

  return ParsedReminder(
    title: _title(input, work, rules),
    dueAt: due,
    timeGuessed: guessed,
    repeat: repeat,
    tag: tag,
    timeSpans: timeSpans..sort((a, b) => a.start.compareTo(b.start)),
    repeatSpan: repeatSpan,
    tagSpan: tagSpan,
    ambiguity: ambiguity,
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
String _title(String input, String work, List<_Rules> rules) {
  final kept = StringBuffer();
  for (var i = 0; i < input.length; i++) {
    kept.write(work[i] == ' ' && input[i] != ' ' ? ' ' : input[i]);
  }
  // A lone ZWNJ/ZWJ left beside a removed word is not a title.
  var t = kept
      .toString()
      .replaceAll(RegExp(r'(?<=^|\s)[\u200C\u200D]+(?=\s|$)'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  const glue = r'(?:at|on|by|to|for|and|every|this|the|next|,|-)';
  t = t.replaceFirst(
    RegExp(r'^(?:remind\s+me\s+(?:to\s+)?)', caseSensitive: false),
    '',
  );
  t = t.replaceFirst(RegExp(r'^(?:to\s+)', caseSensitive: false), '');
  for (var i = 0; i < 3; i++) {
    t = t
        .replaceFirst(RegExp('\\s*\\b$glue\\s*\$', caseSensitive: false), '')
        .replaceFirst(RegExp(r'[\s,.;:\u0964-]+$'), '')
        .trim();
    for (final r in rules) {
      t = t.replaceFirst(r.glueEnd, '').replaceFirst(r.glueStart, '').trim();
    }
  }
  t = t.replaceAllMapped(RegExp(r'\s+([,.!?])'), (m) => m[1]!);
  if (t.isEmpty) return t;
  final first = t.codeUnitAt(0);
  // Only a-z: upper-casing anything else can change the length.
  return first >= 0x61 && first <= 0x7a
      ? String.fromCharCode(first - 32) + t.substring(1)
      : t;
}

// Word boundaries that work for Devanagari and Bengali (`\b` is ASCII-only).
// A match starts and ends between letters/marks/digits, so it never splits a
// conjunct or a surrogate pair.
const _l = r'(?<![\p{L}\p{M}\p{N}])';
const _r = r'(?![\p{L}\p{M}\p{N}])';

// Precomposed nukta letters and their base + nukta spelling. Tables use the
// second; text may use either, so lookups and regexes accept both.
const _nukta = {
  '\u0958': '\u0915\u093C',
  '\u0959': '\u0916\u093C',
  '\u095A': '\u0917\u093C',
  '\u095B': '\u091C\u093C',
  '\u095C': '\u0921\u093C',
  '\u095D': '\u0922\u093C',
  '\u095E': '\u092B\u093C',
  '\u095F': '\u092F\u093C',
  '\u09DC': '\u09A1\u09BC',
  '\u09DD': '\u09A2\u09BC',
  '\u09DF': '\u09AF\u09BC',
};

String _canon(String s) {
  for (final e in _nukta.entries) {
    s = s.replaceAll(e.key, e.value);
  }
  return s;
}

/// Regex alternation of [words], longest first so "har roz" beats "har".
String _alt(Iterable<String> words) {
  final w = [for (final x in words) _canon(x)]
    ..sort((a, b) => b.length - a.length);
  return w
      .map((x) {
        var e = RegExp.escape(x);
        for (final n in _nukta.entries) {
          e = e.replaceAll(n.value, '(?:${n.value}|${n.key})');
        }
        return e;
      })
      .join('|');
}

/// One [ParserPack] compiled to regexes. Latin spellings are dropped unless
/// [latin]: they start with an ASCII letter, native words never do.
class _Rules {
  _Rules(ParserPack p, bool latin) {
    bool keep(String w) => latin || w.codeUnitAt(0) >= 0x80;
    Map<String, V> table<V>(Map<String, V> m) => {
      for (final e in m.entries)
        if (keep(e.key)) _canon(e.key): e.value,
    };
    String word(Iterable<String> ws) => '$_l(?:${_alt(ws.where(keep))})$_r';
    RegExp re(String s) => RegExp(s, unicode: true);
    weekdays = table(p.weekdays);
    months = table(p.months);
    parts = table(p.parts);
    numbers = table(p.numbers);
    units = table(p.units);
    fractions = table(p.fractions);
    specials = table(p.specials);
    quantities = table(p.quantities);
    weakClock = {for (final w in p.weakClock.where(keep)) _canon(w)};
    ambiguous = {for (final w in p.ambiguousDays.where(keep)) _canon(w)};
    final num = '(\\d{1,3}|${_alt(numbers.keys)})';
    final clockWord = '(${_alt(p.clock.where(keep))})';
    weekday = re(word(weekdays.keys));
    final nextWord = _alt(p.next.where(keep));
    weekdayNext = re(
      '(?:$_l(${nextWord.isEmpty ? '(?!)' : nextWord})\\s+)?(${weekday.pattern})',
    );
    partBefore = re('$_l(?:${_alt(parts.keys)})\\s*\$');
    // "৯টা বাজে": the clock word after a bare টা is consumed with it.
    final baje = _alt([
      for (final w in p.clock)
        if (keep(w) && p.weakClock.isNotEmpty && (w == 'baje' || w == 'বাজে'))
          w,
    ]);
    partAfter = re('^\\s*(?:${_alt(parts.keys)})$_r');
    // Intent probes for Latin words, built whatever [latin] says.
    String latinWord(Iterable<String> ws) {
      final l = ws.where((w) => w.codeUnitAt(0) < 0x80).toList();
      return l.isEmpty ? '(?!)' : '$_l(?:${_alt(l)})$_r';
    }

    final latinNum = latinWord([...p.numbers.keys, ...p.quantities.keys]);
    strong = re(
      [
        latinWord(p.weekdays.keys),
        latinWord(p.dayAfter),
        // "dedh baje": a half hour word then the clock word.
        '${latinWord(p.specials.keys)}\\s*'
            '${latinWord(p.clock.where((w) => !p.weakClock.contains(w)))}',
        // "2 ghante baad": three Latin words in a row, never English.
        '(?:\\d{1,3}|$latinNum)\\s*${latinWord(p.units.keys)}\\s+${latinWord(p.after)}',
      ].join('|'),
    );
    anchor = re(
      latinWord([
        ...p.today,
        ...p.tomorrow,
        ...p.parts.keys,
        ...p.clock.where((w) => !p.weakClock.contains(w)),
        ...p.daily,
        ...p.every,
        ...p.next,
      ]),
    );
    final join = _alt([
      'और',
      'ও',
      'আর',
      if (latin) ...['aur', 'o', 'ar'],
    ]);
    every = re(
      '$_l(?:${_alt(p.every.where(keep))})\\s+'
      '(${weekday.pattern}(?:(?:\\s*,\\s*|\\s+(?:$join)\\s+|\\s+)${weekday.pattern})*)',
    );
    daily = re(word(p.daily));
    today = re(word(p.today));
    tomorrow = re(word(p.tomorrow));
    dayAfter = re(word(p.dayAfter));
    month = re('$_l(\\d{1,2})\\s*(${_alt(months.keys)})$_r');
    part = re(word(parts.keys));
    // "2 ghante baad": a bare "2 ghante" can be a length ("2 घंटे की
    // मीटिंग"), so the postposition is required.
    relative = re(
      '$_l(\\d{1,3}|${_alt([...numbers.keys, ...quantities.keys])})\\s*'
      '(${_alt(units.keys)})\\s+(?:${_alt(p.after.where(keep))})$_r',
    );
    clock = re(
      '$_l(?:(${_alt(fractions.keys)})\\s+)?$num(?:[:.](\\d{2}))?\\s*'
      '$clockWord(?:\\s+(${baje.isEmpty ? '(?!)' : baje}))?$_r',
    );
    special = re('$_l(${_alt(specials.keys)})\\s*$clockWord$_r');
    final glue = _alt(p.glue.where(keep));
    glueEnd = re('$_l(?:$glue)$_r[\\s,.;:!?\\u0964-]*\$');
    glueStart = re('^\\s*(?:$glue)$_r\\s*');
  }

  late final Map<String, int> weekdays, months, numbers, fractions;
  late final Map<String, PartRule> parts;
  late final Map<String, (int, int)> specials;
  late final Map<String, double> quantities;
  late final Map<String, String> units;
  late final Set<String> ambiguous, weakClock;
  late final RegExp weekday, weekdayNext, every, daily, today, tomorrow;
  late final RegExp dayAfter, month, part, partBefore, partAfter, relative;
  late final RegExp clock, special, glueEnd, glueStart, strong, anchor;

  int? number(String s) => int.tryParse(s) ?? numbers[_canon(s)];

  double? amount(String s) => number(s)?.toDouble() ?? quantities[_canon(s)];
}

/// A Latin pack word is often an English word or name ("Kal", "Raat", "ta"),
/// so [latinPacks] alone is not enough. Latin is read only when [work] shows
/// Hindi/Bengali intent: a word that is never English (a weekday, "parso",
/// "2 ghante baad"), OR two different anchor words ("kal ... baje"), OR one
/// anchor touching a digit or a native-script word ("kal 8", "8 baje").
/// Everything else ("Call Kal at 5pm", "Raat Records") stays plain text.
bool _latinIntent(String work, String language) {
  final rules = _rulesFor(language, false);
  if (rules.any((r) => r.strong.hasMatch(work))) return true;
  final seen = <String>{};
  for (final r in rules) {
    for (final m in r.anchor.allMatches(work)) {
      seen.add(m[0]!);
      if (seen.length > 1 ||
          _touchesBefore.hasMatch(work.substring(0, m.start)) ||
          _touchesAfter.hasMatch(work.substring(m.end))) {
        return true;
      }
    }
  }
  return false;
}

final _touchesBefore = RegExp(
  r'(?:(?<![\p{L}\p{M}\p{N}])\d{1,3}(?:[:.]\d{1,2})?|[\u0900-\u09FF])\s*$',
  unicode: true,
);
final _touchesAfter = RegExp(
  r'^\s*(?:\d{1,3}(?:[:.]\d{1,2})?(?![\p{L}\p{M}\p{N}])|[\u0900-\u09FF])',
  unicode: true,
);

final _rulesCache = <String, List<_Rules>>{};

/// [language] first, the other pack after it; both always run.
List<_Rules> _rulesFor(String language, bool latin) =>
    _rulesCache['$language/$latin'] ??= [
      for (final p in language == 'bn' ? [bengali, hindi] : [hindi, bengali])
        _Rules(p, latin),
    ];
