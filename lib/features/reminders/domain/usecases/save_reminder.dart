import '../alarm/alarm_scheduler.dart';
import '../entities/reminder.dart';
import '../repositories/reminder_repository.dart';

/// The one write path. A saved reminder that never rings is the failure this
/// app cannot have, so the row and its alarms change together: if scheduling
/// throws, the row is flagged `needsSchedule` for the next launch and the
/// caller gets a [ScheduleFailure] to show inline.
class SaveReminder {
  const SaveReminder(this._repository, this._scheduler);

  final ReminderRepository _repository;
  final AlarmScheduler _scheduler;

  Future<void> call(Reminder reminder) async {
    final clean = reminder.copyWith(needsSchedule: false);
    await _repository.save(clean);
    try {
      await _scheduler.schedule(clean);
    } catch (error) {
      await _repository.save(clean.copyWith(needsSchedule: true));
      throw ScheduleFailure(error);
    }
  }
}
