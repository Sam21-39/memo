import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Owns schema creation and migration. Phase 2 adds columns here via
/// `onUpgrade` + a bumped [_version] — never by editing [_createRemindersV1].
class AppDatabase {
  AppDatabase._(this._db);

  static const _version = 1;
  static const _fileName = 'memo.db';

  final Database _db;
  Database get db => _db;

  static Future<AppDatabase> open() async {
    final path = p.join(await getDatabasesPath(), _fileName);
    final db = await openDatabase(
      path,
      version: _version,
      onCreate: (db, version) => db.execute(_createRemindersV1),
      onUpgrade: (db, oldVersion, newVersion) async {
        // Phase 2: ALTER TABLE steps, guarded by oldVersion, go here.
      },
    );
    return AppDatabase._(db);
  }

  static const _createRemindersV1 = '''
    CREATE TABLE reminders (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      note TEXT,
      scheduled_at INTEGER NOT NULL,
      repeat_type TEXT NOT NULL,
      repeat_weekdays TEXT,
      tag TEXT,
      is_done INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL
    )
  ''';
}
