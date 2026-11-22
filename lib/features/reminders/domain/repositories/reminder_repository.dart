import '../entities/occurrence.dart';
import '../entities/reminder.dart';

abstract class ReminderRepository {
  /// Fires after every write, so each screen's Cubit can reload.
  Stream<void> get changes;

  /// All reminders, soonest first.
  Future<List<Reminder>> getAll();

  Future<Reminder?> getById(String id);

  /// Insert or replace. [log] rows commit with it or not at all.
  Future<void> save(Reminder reminder, {List<Occurrence> log = const []});

  /// History for one reminder, newest occurrence first.
  Future<List<Occurrence>> occurrences(String reminderId);

  /// Drops history due before [before].
  Future<void> pruneOccurrences(DateTime before);

  Future<void> delete(String id);
}
