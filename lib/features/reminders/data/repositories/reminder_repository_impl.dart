import '../../domain/entities/reminder.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../datasources/reminder_local_datasource.dart';

/// v1: local only. Phase 2 sync arrives as a second impl swapped in DI —
/// domain and presentation stay untouched.
class ReminderRepositoryImpl implements ReminderRepository {
  const ReminderRepositoryImpl(this._local);

  final ReminderLocalDatasource _local;

  @override
  Future<List<Reminder>> getAll() => _local.getAll();

  @override
  Future<Reminder?> getById(String id) => _local.getById(id);

  @override
  Future<void> save(Reminder reminder) => _local.save(reminder);

  @override
  Future<void> delete(String id) => _local.delete(id);
}
