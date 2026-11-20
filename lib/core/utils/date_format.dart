import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';

String two(int value) => value.toString().padLeft(2, '0');

String _lang(BuildContext c) => Localizations.localeOf(c).languageCode;

/// "8:30 PM" or "20:30". Latin digits and AM/PM in every language; the
/// device decides 12 or 24 hours.
String formatTime(BuildContext c, DateTime t) => DateFormat(
  MediaQuery.alwaysUse24HourFormatOf(c) ? 'HH:mm' : 'h:mm a',
  'en',
).format(t);

/// "Wed 26 Aug"
String formatDate(BuildContext c, DateTime d) =>
    DateFormat('EEE d MMM', _lang(c)).format(d);

/// "14 Jul 2026"
String formatLongDate(BuildContext c, DateTime d) =>
    DateFormat('d MMM y', _lang(c)).format(d);

/// "Mon" for 1 .. "Sun" for 7.
String weekdayShort(BuildContext c, int weekday) => DateFormat.E(
  _lang(c),
).format(DateTime(2024, 1, weekday)); // 1 Jan 2024 is a Monday

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// "Today", "Tomorrow", "Yesterday", else "Tue 3 Nov".
String dayHeaderLabel(BuildContext c, DateTime day, DateTime now) {
  if (isSameDay(day, now)) return c.l10n.dateToday;
  if (isSameDay(day, DateTime(now.year, now.month, now.day + 1))) {
    return c.l10n.dateTomorrow;
  }
  if (isSameDay(day, DateTime(now.year, now.month, now.day - 1))) {
    return c.l10n.dateYesterday;
  }
  return formatDate(c, day);
}

/// "Today · 8:00 PM", "Tue 3 Nov · 9:30 AM".
String formatWhen(BuildContext c, DateTime at, DateTime now) =>
    c.l10n.whenDayTime(dayHeaderLabel(c, at, now), formatTime(c, at));

/// "2 h late", "12 min late", "3 d late" — the overdue row's trailing phrase.
String formatLateness(BuildContext c, Duration late) {
  final l = c.l10n;
  if (late.inDays >= 1) return l.lateDays(late.inDays);
  if (late.inHours >= 1) return l.lateHours(late.inHours);
  return l.lateMinutes(late.inMinutes.clamp(1, 59));
}
