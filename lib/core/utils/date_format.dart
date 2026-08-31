/// English-only, 24h — matching the design's mono time style and the PRD's
/// v1 "English-only UI" assumption. Swap for `intl` if v1 ever localises.
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String two(int value) => value.toString().padLeft(2, '0');

/// "08:30"
String formatTime(DateTime time) => '${two(time.hour)}:${two(time.minute)}';

/// "Wed 26 Aug"
String formatDate(DateTime date) =>
    '${_weekdays[date.weekday - 1]} ${date.day} ${_months[date.month - 1]}';

/// "14 Jul 2026"
String formatLongDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// "Today · Wed 26 Aug", "Tomorrow · Thu 27 Aug", else "Fri 28 Aug".
String dayHeaderLabel(DateTime day, DateTime now) {
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  if (isSameDay(day, now)) return 'Today · ${formatDate(day)}';
  if (isSameDay(day, tomorrow)) return 'Tomorrow · ${formatDate(day)}';
  return formatDate(day);
}

/// "2h late", "15m late", "3d late" — the overdue row's trailing phrase.
String formatLateness(Duration late) {
  if (late.inDays >= 1) return '${late.inDays}d late';
  if (late.inHours >= 1) return '${late.inHours}h late';
  return '${late.inMinutes.clamp(1, 59)}m late';
}
