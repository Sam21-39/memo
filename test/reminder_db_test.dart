import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/reminders/data/reminder_db.dart';
import 'package:memo/features/reminders/data/reminder_repository_impl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'fakes.dart';

void main() {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;

  test('a fresh install lands on the latest schema', () async {
    final db = await ReminderDb.open(
      path: inMemoryDatabasePath,
      factory: factory,
    );
    expect(db.upgradedFrom, 0);
    expect(await db.db.getVersion(), ReminderDb.version);
    await db.db.close();
  });

  test('v1 rows survive the v2 migration', () async {
    // Seed a database exactly as 0.0.1 left it.
    final path = '${(await factory.getDatabasesPath())}/v1_seed.db';
    await factory.deleteDatabase(path);
    final v1 = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          for (final sql in ReminderDb.migrations[0]) {
            await db.execute(sql);
          }
          final due = DateTime(2026, 11, 2, 8).millisecondsSinceEpoch;
          final created = DateTime(2026, 10, 1).millisecondsSinceEpoch;
          await db.insert('reminders', {
            'id': 'pills',
            'title': 'Pills',
            'note': 'Two, with water',
            'scheduled_at': due,
            'repeat_type': 'weekly',
            'repeat_weekdays': '1,3',
            'tag': 'Health',
            'is_done': 0,
            'created_at': created,
          });
          await db.insert('reminders', {
            'id': 'call',
            'title': 'Call the dentist',
            'scheduled_at': due,
            'repeat_type': 'none',
            'is_done': 1,
            'created_at': created,
          });
        },
      ),
    );
    await v1.close();

    final db = await ReminderDb.open(path: path, factory: factory);
    expect(db.upgradedFrom, 1);
    expect(await db.db.getVersion(), 3);
    final repo = ReminderRepositoryImpl(db);

    final pills = (await repo.getById('pills'))!;
    expect(pills.title, 'Pills');
    expect(pills.note, 'Two, with water');
    expect(pills.dueAt, DateTime(2026, 11, 2, 8));
    expect(pills.repeat.weekdays, {1, 3});
    expect(pills.tag, 'Health');
    expect(pills.isDone, isFalse);
    expect(pills.nagMin, isNull);
    expect(pills.nagCount, 0);
    expect(pills.needsSchedule, isFalse);

    final call = (await repo.getById('call'))!;
    expect(call.isDone, isTrue);
    expect(call.doneAt, DateTime(2026, 11, 2, 8));
    await db.db.close();
  });

  test('every v2 field round-trips', () async {
    final db = await ReminderDb.open(
      path: inMemoryDatabasePath,
      factory: factory,
    );
    final repo = ReminderRepositoryImpl(db);
    final original = reminder('r', 'Bins', DateTime(2026, 11, 3, 7)).copyWith(
      preAlarmMin: 15,
      nagMin: 10,
      nagCount: 2,
      hasVoice: true,
      readAloud: true,
      hasImage: true,
      needsSchedule: true,
      doneAt: DateTime(2026, 11, 3, 7, 5),
      snoozedUntil: DateTime(2026, 11, 3, 7, 10),
    );
    await repo.save(original);
    final back = (await repo.getById('r'))!;
    expect(
      [
        back.preAlarmMin,
        back.nagMin,
        back.nagCount,
        back.doneAt,
        back.snoozedUntil,
      ],
      [15, 10, 2, DateTime(2026, 11, 3, 7, 5), DateTime(2026, 11, 3, 7, 10)],
    );
    expect([
      back.hasVoice,
      back.readAloud,
      back.hasImage,
      back.needsSchedule,
    ], everyElement(isTrue));
    await db.db.close();
  });
}
