import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/reminders/data/reminder_db.dart';
import 'package:memo/features/reminders/data/reminder_repository_impl.dart';
import 'package:memo/features/reminders/domain/entities/occurrence.dart';
import 'package:memo/features/reminders/domain/entities/repeat_rule.dart';
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
    expect(await db.db.getVersion(), ReminderDb.version);
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

  group('occurrences (v4)', () {
    Future<(ReminderDb, ReminderRepositoryImpl)> open() async {
      final db = await ReminderDb.open(
        path: inMemoryDatabasePath,
        factory: factory,
      );
      return (db, ReminderRepositoryImpl(db));
    }

    Occurrence occ(
      String id,
      DateTime due,
      OccurrenceEvent e, {
      DateTime? until,
    }) => Occurrence(
      reminderId: id,
      dueAt: due,
      event: e,
      at: due.add(Duration(minutes: e == OccurrenceEvent.done ? 14 : 4)),
      until: until,
    );

    test(
      'a v3 database with data opens at v4, rows intact, history empty',
      () async {
        final path = '${(await factory.getDatabasesPath())}/v3_seed.db';
        await factory.deleteDatabase(path);
        final v3 = await factory.openDatabase(
          path,
          options: OpenDatabaseOptions(
            version: 3,
            onCreate: (db, _) async {
              for (final m in ReminderDb.migrations.take(3)) {
                for (final sql in m) {
                  await db.execute(sql);
                }
              }
              await db.insert('reminders', {
                'id': 'pills',
                'title': 'Pills',
                'due_at': DateTime(2026, 11, 2, 8).millisecondsSinceEpoch,
                'repeat_type': 'daily',
                'created_at': DateTime(2026, 10, 1).millisecondsSinceEpoch,
                'snoozed_until': DateTime(
                  2026,
                  11,
                  2,
                  8,
                  10,
                ).millisecondsSinceEpoch,
              });
            },
          ),
        );
        await v3.close();

        final db = await ReminderDb.open(path: path, factory: factory);
        expect(db.upgradedFrom, 3);
        expect(await db.db.getVersion(), 4);
        final repo = ReminderRepositoryImpl(db);
        final pills = (await repo.getById('pills'))!;
        expect(pills.title, 'Pills');
        expect(pills.repeat, RepeatRule.daily);
        expect(pills.snoozedUntil, DateTime(2026, 11, 2, 8, 10));
        expect(await repo.occurrences('pills'), isEmpty);
        await db.db.close();
      },
    );

    test('save(log:) round-trips every field, null until included', () async {
      final (db, repo) = await open();
      final due = DateTime(2026, 11, 3, 7);
      await repo.save(
        reminder('r', 'Bins', due, repeat: RepeatRule.daily),
        log: [
          occ(
            'r',
            due,
            OccurrenceEvent.snoozed,
            until: due.add(const Duration(minutes: 10)),
          ),
          occ('r', due, OccurrenceEvent.done),
        ],
      );
      final back = await repo.occurrences('r');
      expect(back.map((o) => o.event), [
        OccurrenceEvent.snoozed,
        OccurrenceEvent.done,
      ]);
      expect(back.first.reminderId, 'r');
      expect(back.first.dueAt, due);
      expect(back.first.at, due.add(const Duration(minutes: 4)));
      expect(back.last.at, due.add(const Duration(minutes: 14)));
      expect(back.first.until, due.add(const Duration(minutes: 10)));
      expect(back.last.until, isNull);
      await db.db.close();
    });

    test('delete removes that reminder history only', () async {
      final (db, repo) = await open();
      final due = DateTime(2026, 11, 3, 7);
      for (final id in ['a', 'b']) {
        await repo.save(
          reminder(id, id, due, repeat: RepeatRule.daily),
          log: [occ(id, due, OccurrenceEvent.done)],
        );
      }
      await repo.delete('a');
      expect(await repo.occurrences('a'), isEmpty);
      expect(await repo.occurrences('b'), hasLength(1));
      await db.db.close();
    });

    test('pruneOccurrences removes only older rows', () async {
      final (db, repo) = await open();
      final old = DateTime(2026, 6, 1, 7);
      final fresh = DateTime(2026, 11, 1, 7);
      await repo.save(
        reminder('r', 'r', fresh, repeat: RepeatRule.daily),
        log: [
          occ('r', old, OccurrenceEvent.done),
          occ('r', fresh, OccurrenceEvent.done),
        ],
      );
      await repo.pruneOccurrences(DateTime(2026, 8, 1));
      expect((await repo.occurrences('r')).single.dueAt, fresh);
      await db.db.close();
    });
  });
}
