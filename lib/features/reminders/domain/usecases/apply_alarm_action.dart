import '../repositories/reminder_repository.dart';
import 'complete_reminder.dart';
import 'save_reminder.dart';
import 'snooze_reminder.dart';

enum AlarmAction { done, snooze }

/// Done or Snooze 10m from an alert, wherever it was tapped: a notification,
/// the native alarm (via its queue), the Alarm screen, an iOS background
/// isolate. [at] is when it was tapped, so a queued snooze counts from then.
class ApplyAlarmAction {
  const ApplyAlarmAction(this._repository, this._save);

  final ReminderRepository _repository;
  final SaveReminder _save;

  static const snoozeBy = Duration(minutes: 10);

  Future<void> call(String reminderId, AlarmAction action, DateTime at) async {
    final reminder = await _repository.getById(reminderId);
    if (reminder == null || reminder.isDone) return;
    await _save(switch (action) {
      AlarmAction.done => const CompleteReminder()(reminder, now: at),
      AlarmAction.snooze => const SnoozeReminder()(
        reminder,
        now: at,
        by: snoozeBy,
      ),
    });
  }
}
