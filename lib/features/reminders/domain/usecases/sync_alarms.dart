import '../alarm/alarm_scheduler.dart';
import '../entities/occurrence.dart';
import '../entities/reminder.dart';
import '../test_reminder.dart';
import '../repositories/reminder_repository.dart';

/// Run on launch, on resume and after every notification action.
///
/// 1. Roll forward: a live repeat more than one full cycle in the past moves
///    to its next real occurrence. One cycle late stays overdue, so today's
///    missed pills still show.
///    Each cycle stepped over is logged as `open` (never marked done).
/// 2. Drop history older than 90 days. Never allowed to stop the sync.
/// 3. Delete a leftover test alarm (done, or due over 2 minutes ago).
/// 4. Re-register every live alarm from scratch, which also retries rows a
///    failed schedule flagged `needsSchedule`.
class SyncAlarms {
  const SyncAlarms(this._repository, this._scheduler);

  final ReminderRepository _repository;
  final AlarmScheduler _scheduler;

  Future<void> call({DateTime? now}) async {
    final at = now ?? DateTime.now();
    final live = <Reminder>[];
    for (final reminder in await _repository.getAll()) {
      if (reminder.id == testReminderId &&
          (reminder.isDone ||
              reminder.dueAt.isBefore(
                at.subtract(const Duration(minutes: 2)),
              ))) {
        await _scheduler.cancel(reminder.id);
        await _repository.delete(reminder.id);
        continue;
      }
      if (reminder.isDone) continue;
      var current = reminder;
      final oneCycle = reminder.repeat.nextAfter(reminder.dueAt);
      if (oneCycle != null && oneCycle.isBefore(at)) {
        current = reminder.copyWith(
          dueAt: reminder.repeat.nextAfterNow(reminder.dueAt, at),
          nagCount: 0,
          clearSnooze: true,
        );
      }
      if (!identical(current, reminder)) {
        await _repository.save(
          current,
          log: openLog(reminder, current.dueAt, at),
        );
      }
      live.add(current);
    }
    live.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    // Alarms matter more than tidiness: a failed prune must not stop the sync.
    try {
      await _repository.pruneOccurrences(
        at.subtract(const Duration(days: historyDays)),
      );
    } catch (_) {}
    await _scheduler.syncAll(live);
    // Re-read: an edit saved while syncAll ran must not be overwritten.
    for (final r in live) {
      if (!r.needsSchedule) continue;
      final fresh = await _repository.getById(r.id);
      if (fresh != null && fresh.needsSchedule) {
        await _repository.save(fresh.copyWith(needsSchedule: false));
      }
    }
  }
}
