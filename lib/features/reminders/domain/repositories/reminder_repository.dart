import '../entities/reminder.dart';

abstract class ReminderRepository {
  /// Fires after every write, so each screen's Cubit can reload.
  Stream<void> get changes;

  /// All reminders, soonest first.
  Future<List<Reminder>> getAll();

  Future<Reminder?> getById(String id);

  /// Insert or replace.
  Future<void> save(Reminder reminder);

  Future<void> delete(String id);
}
