import '../entities/reminder.dart';
import '../entities/repeat_rule.dart';

/// Pure: builds the entity. Persisting and scheduling are the caller's job.
class CreateReminder {
  const CreateReminder();

  Reminder call({
    required String title,
    required DateTime scheduledAt,
    required DateTime now,
    String? note,
    RepeatRule repeat = RepeatRule.none,
    String? tag,
  }) {
    return Reminder(
      // ponytail: timestamp id — unique enough for one device, one user.
      // Swap for a real UUID when Phase 2 sync makes collisions possible.
      id: now.microsecondsSinceEpoch.toString(),
      title: title.trim(),
      note: (note == null || note.trim().isEmpty) ? null : note.trim(),
      scheduledAt: scheduledAt,
      repeat: repeat,
      tag: tag,
      createdAt: now,
    );
  }
}
