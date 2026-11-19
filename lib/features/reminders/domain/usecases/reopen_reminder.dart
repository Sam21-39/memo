import '../entities/reminder.dart';

class ReopenReminder {
  const ReopenReminder();

  /// A one-off whose time passed moves to the next whole hour so it rings.
  Reminder call(Reminder r, {required DateTime now}) => r.copyWith(
    clearDone: true,
    nagCount: 0,
    clearSnooze: true,
    dueAt: r.repeat.repeats || r.dueAt.isAfter(now)
        ? r.dueAt
        : DateTime(now.year, now.month, now.day, now.hour + 1),
  );
}
