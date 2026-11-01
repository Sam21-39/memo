import '../entities/reminder.dart';

/// One implementation per platform. Idempotent by construction: [schedule]
/// cancels every alarm for the reminder, then registers the full set.
abstract interface class AlarmScheduler {
  Future<void> schedule(Reminder reminder);

  Future<void> cancel(String reminderId);

  /// Re-register every live reminder from scratch. Called on every app open
  /// and after every notification action: never trust that something
  /// registered yesterday still exists. iOS keeps only the soonest 64.
  Future<void> syncAll(List<Reminder> live);
}

class ScheduleFailure implements Exception {
  const ScheduleFailure(this.cause);
  final Object cause;

  @override
  String toString() => 'ScheduleFailure: $cause';
}
