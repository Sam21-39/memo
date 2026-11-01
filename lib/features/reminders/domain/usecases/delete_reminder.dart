import '../alarm/alarm_scheduler.dart';
import '../repositories/reminder_repository.dart';

/// Removes the row, every alarm it owns and its media files.
class DeleteReminder {
  const DeleteReminder(this._repository, this._scheduler, this._deleteMedia);

  final ReminderRepository _repository;
  final AlarmScheduler _scheduler;
  final Future<void> Function(String reminderId) _deleteMedia;

  Future<void> call(String reminderId) async {
    await _scheduler.cancel(reminderId);
    await _repository.delete(reminderId);
    await _deleteMedia(reminderId);
  }
}
