import '../entities/occurrence.dart';
import '../repositories/reminder_repository.dart';
import 'save_reminder.dart';

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
    // Same tap replayed (native queue + background isolate): already applied.
    final replay = (await _repository.occurrences(
      reminderId,
    )).any((o) => o.at == at && o.event != OccurrenceEvent.open);
    if (replay) return;
    await switch (action) {
      AlarmAction.done => _save.done(reminder, at),
      AlarmAction.snooze => _save.snooze(reminder, at, by: snoozeBy),
    };
  }
}
