import '../alarm/alarm_scheduler.dart';
import '../entities/occurrence.dart';
import '../entities/reminder.dart';
import '../repositories/reminder_repository.dart';
import 'complete_reminder.dart';
import 'snooze_reminder.dart';

/// The one write path. A saved reminder that never rings is the failure this
/// app cannot have, so the row and its alarms change together: if scheduling
/// throws, the row is flagged `needsSchedule` for the next launch and the
/// caller gets a [ScheduleFailure] to show inline.
class SaveReminder {
  const SaveReminder(this._repository, this._scheduler);

  final ReminderRepository _repository;
  final AlarmScheduler _scheduler;

  Future<void> call(
    Reminder reminder, {
    List<Occurrence> log = const [],
  }) async {
    final clean = reminder.copyWith(needsSchedule: false);
    await _repository.save(clean, log: log);
    try {
      await _scheduler.schedule(clean);
    } catch (error) {
      await _repository.save(clean.copyWith(needsSchedule: true));
      throw ScheduleFailure(error);
    }
  }

  /// Done at [at], and the cycle it closes goes in the history.
  Future<void> done(Reminder reminder, DateTime at) {
    final next = const CompleteReminder()(reminder, now: at);
    return call(next, log: doneLog(reminder, next, at));
  }

  /// Snooze at [at]; a repeat's snooze is recorded for that cycle.
  Future<void> snooze(
    Reminder reminder,
    DateTime at, {
    Duration? by,
    DateTime? until,
  }) {
    final next = const SnoozeReminder()(
      reminder,
      now: at,
      by: by,
      until: until,
    );
    return call(next, log: snoozeLog(reminder, next, at));
  }
}
