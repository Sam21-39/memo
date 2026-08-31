import '../entities/reminder.dart';

/// Pure: returns the reminder re-timed. Presets are 10m / 1h / tomorrow —
/// `by: null` means tomorrow at the reminder's own time of day.
class SnoozeReminder {
  const SnoozeReminder();

  Reminder call(Reminder reminder, {required DateTime now, Duration? by}) {
    final next = by == null
        ? DateTime(
            now.year,
            now.month,
            now.day + 1,
            reminder.scheduledAt.hour,
            reminder.scheduledAt.minute,
          )
        : now.add(by);
    return reminder.copyWith(scheduledAt: next, isDone: false);
  }
}
