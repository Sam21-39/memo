import 'package:sqflite/sqflite.dart';

import '../../domain/entities/reminder.dart';
import '../models/reminder_model.dart';
import 'app_database.dart';

class ReminderLocalDatasource {
  const ReminderLocalDatasource(this._database);

  final AppDatabase _database;

  Future<List<Reminder>> getAll() async {
    final rows = await _database.db.query(
      'reminders',
      orderBy: 'scheduled_at ASC',
    );
    return rows.map(reminderFromRow).toList();
  }

  Future<Reminder?> getById(String id) async {
    final rows = await _database.db.query(
      'reminders',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : reminderFromRow(rows.first);
  }

  Future<void> save(Reminder reminder) async {
    await _database.db.insert(
      'reminders',
      reminder.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    await _database.db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }
}
