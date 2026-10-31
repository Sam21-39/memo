import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../domain/entities/reminder.dart';
import '../domain/repositories/reminder_repository.dart';
import 'reminder_db.dart';
import 'reminder_row.dart';

/// v1: local only. Phase 2 sync arrives as a second implementation swapped in
/// DI — domain and presentation stay untouched.
class ReminderRepositoryImpl implements ReminderRepository {
  ReminderRepositoryImpl(this._db);

  final ReminderDb _db;
  final _changes = StreamController<void>.broadcast();

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<List<Reminder>> getAll() async {
    final rows = await _db.db.query('reminders', orderBy: 'due_at ASC');
    return rows.map(reminderFromRow).toList();
  }

  @override
  Future<Reminder?> getById(String id) async {
    final rows = await _db.db.query(
      'reminders',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : reminderFromRow(rows.first);
  }

  @override
  Future<void> save(Reminder reminder) async {
    await _db.db.insert(
      'reminders',
      reminder.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _changes.add(null);
  }

  @override
  Future<void> delete(String id) async {
    await _db.db.delete('reminders', where: 'id = ?', whereArgs: [id]);
    _changes.add(null);
  }
}
