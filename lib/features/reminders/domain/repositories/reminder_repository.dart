import '../entities/reminder.dart';

abstract class ReminderRepository {
  /// All reminders, soonest first.
  Future<List<Reminder>> getAll();

  Future<Reminder?> getById(String id);

  /// Insert or replace.
  Future<void> save(Reminder reminder);

  Future<void> delete(String id);
}
