import '../entities/reminder.dart';

/// Pure: completing a repeating reminder advances it to its next occurrence
/// and resets its nags; it never sets `doneAt`. A one-off is marked done.
///
/// ponytail: one row per reminder, so a repeat's past completions are not
/// recorded. Add an occurrences table when per-occurrence history is wanted.
class CompleteReminder {
  const CompleteReminder();

  Reminder call(Reminder reminder, {required DateTime now}) {
    final next = reminder.repeat.nextAfterNow(reminder.dueAt, now);
    if (next == null) return reminder.copyWith(doneAt: now, nagCount: 0);
    return reminder.copyWith(dueAt: next, clearDone: true, nagCount: 0);
  }
}
