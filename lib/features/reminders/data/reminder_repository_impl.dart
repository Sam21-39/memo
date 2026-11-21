import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../domain/entities/occurrence.dart';
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
  Future<void> save(
    Reminder reminder, {
    List<Occurrence> log = const [],
  }) async {
    Future<void> put(DatabaseExecutor e) => e.insert(
      'reminders',
      reminder.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    if (log.isEmpty) {
      await put(_db.db);
    } else {
      await _db.db.transaction((t) async {
        await put(t);
        for (final o in log) {
          await t.insert('occurrences', o.toRow());
        }
      });
    }
    _changes.add(null);
  }

  @override
  Future<List<Occurrence>> occurrences(String reminderId) async {
    final rows = await _db.db.query(
      'occurrences',
      where: 'reminder_id = ?',
      whereArgs: [reminderId],
      orderBy: 'due_at DESC, at ASC',
      limit: 400, // ponytail: 90 days of a daily with snoozes fits
    );
    return rows.map(occurrenceFromRow).toList();
  }

  @override
  Future<void> pruneOccurrences(DateTime before) => _db.db.delete(
    'occurrences',
    where: 'due_at < ?',
    whereArgs: [before.millisecondsSinceEpoch],
  );

  @override
  Future<void> delete(String id) async {
    await _db.db.transaction((t) async {
      await t.delete('occurrences', where: 'reminder_id = ?', whereArgs: [id]);
      await t.delete('reminders', where: 'id = ?', whereArgs: [id]);
    });
    _changes.add(null);
  }
}
