import '../entities/reminder.dart';

/// Pure: returns the reminder re-timed, nags restarting from the new time.
/// Presets are 10m / 1h / tomorrow — `by: null` means tomorrow at the
/// reminder's own time of day.
class SnoozeReminder {
  const SnoozeReminder();

  Reminder call(Reminder reminder, {required DateTime now, Duration? by}) {
    final next = by == null
        ? DateTime(
            now.year,
            now.month,
            now.day + 1,
            reminder.dueAt.hour,
            reminder.dueAt.minute,
          )
        : now.add(by);
    return reminder.copyWith(dueAt: next, clearDone: true, nagCount: 0);
  }
}
