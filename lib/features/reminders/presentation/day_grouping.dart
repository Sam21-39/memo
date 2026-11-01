import '../domain/entities/reminder.dart';

class DayGroup {
  const DayGroup(this.day, this.reminders);
  final DateTime day;
  final List<Reminder> reminders;
}

class GroupedReminders {
  const GroupedReminders(this.overdue, this.days);
  final List<Reminder> overdue;
  final List<DayGroup> days;

  bool get isEmpty => overdue.isEmpty && days.isEmpty;
}

/// Splits upcoming reminders into an overdue bucket and day-ordered groups.
/// "Time is the hierarchy" — day headers, not cards, organise the list.
GroupedReminders groupByDay(List<Reminder> upcoming, DateTime now) {
  final overdue = <Reminder>[];
  final byDay = <DateTime, List<Reminder>>{};

  for (final reminder in upcoming) {
    if (reminder.ringsAt.isBefore(now)) {
      overdue.add(reminder);
      continue;
    }
    final day = DateTime(
      reminder.ringsAt.year,
      reminder.ringsAt.month,
      reminder.ringsAt.day,
    );
    byDay.putIfAbsent(day, () => []).add(reminder);
  }

  final days = byDay.keys.toList()..sort();
  return GroupedReminders(
    overdue,
    days.map((day) => DayGroup(day, byDay[day]!)).toList(),
  );
}
