import '../entities/reminder.dart';

/// Pure: completing a repeating reminder advances it to its next occurrence
/// instead of archiving it. A one-off is simply marked done.
///
/// ponytail: v1 stores one row per reminder, so a repeat's past completions
/// are not recorded — the Done archive lists one-offs only. Add an
/// `occurrences` table when per-occurrence history is actually wanted.
class CompleteReminder {
  const CompleteReminder();

  Reminder call(Reminder reminder, {required DateTime now}) {
    final next = reminder.repeat.nextAfterNow(reminder.scheduledAt, now);
    if (next == null) return reminder.copyWith(isDone: true);
    return reminder.copyWith(scheduledAt: next, isDone: false);
  }
}
