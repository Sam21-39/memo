import '../alarm/alarm_scheduler.dart';
import '../entities/reminder.dart';
import '../repositories/reminder_repository.dart';

/// Run on launch, on resume and after every notification action.
///
/// 1. Roll forward: a live repeat more than one full cycle in the past moves
///    to its next real occurrence. One cycle late stays overdue, so today's
///    missed pills still show.
/// 2. Re-register every live alarm from scratch, which also retries rows a
///    failed schedule flagged `needsSchedule`.
class SyncAlarms {
  const SyncAlarms(this._repository, this._scheduler);

  final ReminderRepository _repository;
  final AlarmScheduler _scheduler;

  Future<void> call({DateTime? now}) async {
    final at = now ?? DateTime.now();
    final live = <Reminder>[];
    for (final reminder in await _repository.getAll()) {
      if (reminder.isDone) continue;
      var current = reminder;
      final oneCycle = reminder.repeat.nextAfter(reminder.dueAt);
      if (oneCycle != null && oneCycle.isBefore(at)) {
        current = reminder.copyWith(
          dueAt: reminder.repeat.nextAfterNow(reminder.dueAt, at),
          nagCount: 0,
        );
      }
      if (current.needsSchedule) {
        current = current.copyWith(needsSchedule: false);
      }
      if (!identical(current, reminder)) await _repository.save(current);
      live.add(current);
    }
    live.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    await _scheduler.syncAll(live);
  }
}
