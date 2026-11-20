import '../entities/reminder.dart';

/// Pure: returns the reminder re-timed, nags restarting from the new time.
/// [until] is an exact instant and wins; else `by: null` means tomorrow at
/// the reminder's own time of day.
///
/// A one-off moves its [Reminder.dueAt]. A repeat keeps its series time and
/// gets [Reminder.snoozedUntil] instead, so snoozing daily pills by 10 min
/// does not make them daily at 20:10 forever.
class SnoozeReminder {
  const SnoozeReminder();

  Reminder call(
    Reminder reminder, {
    required DateTime now,
    Duration? by,
    DateTime? until,
  }) {
    final wanted =
        until ??
        (by == null
            ? DateTime(
                now.year,
                now.month,
                now.day + 1,
                reminder.dueAt.hour,
                reminder.dueAt.minute,
              )
            : now.add(by));
    // A past instant would ring at once; clamp to a minute from now.
    final next = wanted.isAfter(now)
        ? wanted
        : now.add(const Duration(minutes: 1));
    if (reminder.repeat.repeats) {
      return reminder.copyWith(snoozedUntil: next, nagCount: 0);
    }
    return reminder.copyWith(dueAt: next, clearDone: true, nagCount: 0);
  }
}
