import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Owns the schema. Migrations are numbered SQL lists applied in order and
/// never edited after shipping: add a new entry instead. A fresh install runs
/// the same list as an upgrade, so there is one path to test.
class ReminderDb {
  ReminderDb._(this.db, this.upgradedFrom);

  final Database db;

  /// The version an existing file was opened at, 0 for a fresh install, or
  /// [version] when nothing changed. A jump from 1 means alarm ids changed
  /// scheme, so every alarm must be re-registered.
  final int upgradedFrom;

  static const _fileName = 'memo.db';

  static const migrations = <List<String>>[
    // v1 — shipped in 0.0.1.
    [
      '''
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
      ''',
    ],
    // v2 — due_at, done_at, nag, pre-alarm, media flags, needs_schedule.
    // Rebuilt rather than ALTERed: RENAME COLUMN needs SQLite 3.25, and
    // Android 8 ships 3.18.
    [
      '''
      CREATE TABLE reminders_v2 (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        note TEXT,
        due_at INTEGER NOT NULL,
        repeat_type TEXT NOT NULL,
        repeat_weekdays TEXT,
        tag TEXT,
        done_at INTEGER,
        created_at INTEGER NOT NULL,
        pre_alarm_min INTEGER,
        nag_min INTEGER,
        nag_count INTEGER NOT NULL DEFAULT 0,
        has_voice INTEGER NOT NULL DEFAULT 0,
        voice_rings INTEGER NOT NULL DEFAULT 0,
        has_image INTEGER NOT NULL DEFAULT 0,
        needs_schedule INTEGER NOT NULL DEFAULT 0
      )
      ''',
      // v1 never recorded when a one-off was completed; its due time is the
      // closest honest answer.
      '''
      INSERT INTO reminders_v2
        (id, title, note, due_at, repeat_type, repeat_weekdays, tag,
         done_at, created_at)
      SELECT id, title, note, scheduled_at, repeat_type, repeat_weekdays, tag,
             CASE is_done WHEN 1 THEN scheduled_at END, created_at
      FROM reminders
      ''',
      'DROP TABLE reminders',
      'ALTER TABLE reminders_v2 RENAME TO reminders',
    ],
    // v3 — snoozed_until: a repeat's snooze no longer moves its series.
    ['ALTER TABLE reminders ADD COLUMN snoozed_until INTEGER'],
  ];

  static int get version => migrations.length;

  static Future<ReminderDb> open({
    String? path,
    DatabaseFactory? factory,
  }) async {
    final f = factory ?? databaseFactory;
    final file = path ?? p.join(await f.getDatabasesPath(), _fileName);
    var from = version;
    final db = await f.openDatabase(
      file,
      options: OpenDatabaseOptions(
        version: version,
        onCreate: (db, v) async {
          from = 0;
          await _migrate(db, 0, v);
        },
        onUpgrade: (db, oldV, newV) async {
          from = oldV;
          await _migrate(db, oldV, newV);
        },
      ),
    );
    return ReminderDb._(db, from);
  }

  static Future<void> _migrate(Database db, int from, int to) async {
    for (var v = from; v < to; v++) {
      for (final sql in migrations[v]) {
        await db.execute(sql);
      }
    }
  }
}
