import '../../l10n/strings.dart';

/// English-only, 24h — matching the design's mono time style and the PRD's
/// v1 "English-only UI" assumption. Swap for `intl` if v1 ever localises.
String two(int value) => value.toString().padLeft(2, '0');

/// "08:30"
String formatTime(DateTime time) => '${two(time.hour)}:${two(time.minute)}';

/// "Wed 26 Aug"
String formatDate(DateTime date) =>
    S.dateShort(date.weekday, date.day, date.month);

/// "14 Jul 2026"
String formatLongDate(DateTime date) =>
    S.dateLong(date.day, date.month, date.year);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// "Today", "Tomorrow", "Yesterday", else "Tue 3 Nov".
String dayHeaderLabel(DateTime day, DateTime now) {
  if (isSameDay(day, now)) return S.dateToday;
  if (isSameDay(day, DateTime(now.year, now.month, now.day + 1))) {
    return S.dateTomorrow;
  }
  if (isSameDay(day, DateTime(now.year, now.month, now.day - 1))) {
    return S.dateYesterday;
  }
  return formatDate(day);
}

/// "Today 20:00", "Tue 3 Nov 09:30".
String formatWhen(DateTime at, DateTime now) => S.dayAtTime(
  isSameDay(at, now) ? S.dateToday : formatDate(at),
  formatTime(at),
);

/// "2h late", "12 min late", "3d late" — the overdue row's trailing phrase.
String formatLateness(Duration late) {
  if (late.inDays >= 1) return S.lateDays(late.inDays);
  if (late.inHours >= 1) return S.lateHours(late.inHours);
  return S.lateMinutes(late.inMinutes.clamp(1, 59));
}
