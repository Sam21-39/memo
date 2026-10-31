import 'dart:async';

import 'package:flutter/material.dart';
import 'package:memo/core/app_prefs.dart';
import 'package:memo/core/di.dart';
import 'package:memo/core/feature_flags/feature_flags.dart';
import 'package:memo/core/theme/memo_theme.dart';
import 'package:memo/features/reminders/domain/alarm/alarm_scheduler.dart';
import 'package:memo/features/reminders/domain/entities/reminder.dart';
import 'package:memo/features/reminders/domain/entities/repeat_rule.dart';
import 'package:memo/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:memo/features/reminders/domain/usecases/delete_reminder.dart';
import 'package:memo/features/reminders/domain/usecases/save_reminder.dart';
import 'package:memo/features/reminders/domain/usecases/sync_alarms.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// The scheduler resolves `tz.local` on every schedule.
void initTestTimeZone() {
  tz_data.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('UTC'));
}

class InMemoryRepository implements ReminderRepository {
  InMemoryRepository([List<Reminder> reminders = const []])
    : _reminders = [...reminders];

  List<Reminder> _reminders;
  final _changes = StreamController<void>.broadcast();

  List<Reminder> get all => List.unmodifiable(_reminders);

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<List<Reminder>> getAll() async =>
      [..._reminders]..sort((a, b) => a.dueAt.compareTo(b.dueAt));

  @override
  Future<Reminder?> getById(String id) async =>
      _reminders.where((r) => r.id == id).firstOrNull;

  @override
  Future<void> save(Reminder reminder) async {
    _reminders = [..._reminders.where((r) => r.id != reminder.id), reminder];
    _changes.add(null);
  }

  @override
  Future<void> delete(String id) async {
    _reminders = _reminders.where((r) => r.id != id).toList();
    _changes.add(null);
  }
}

/// Records what the use cases asked for; [fail] makes [schedule] throw.
class FakeScheduler implements AlarmScheduler {
  final scheduled = <Reminder>[];
  final cancelled = <String>[];
  List<Reminder>? synced;
  bool fail = false;

  @override
  Future<void> schedule(Reminder reminder) async {
    if (fail) throw StateError('platform said no');
    scheduled.add(reminder);
  }

  @override
  Future<void> cancel(String reminderId) async => cancelled.add(reminderId);

  @override
  Future<void> syncAll(List<Reminder> live) async => synced = live;
}

Reminder reminder(
  String id,
  String title,
  DateTime at, {
  String? tag,
  String? note,
  RepeatRule repeat = RepeatRule.none,
  DateTime? doneAt,
}) => Reminder(
  id: id,
  title: title,
  dueAt: at,
  createdAt: DateTime(2026, 8, 1),
  tag: tag,
  note: note,
  repeat: repeat,
  doneAt: doneAt,
);

/// Registers the same graph as `configureDependencies`, over fakes.
Future<(InMemoryRepository, FakeScheduler)> setUpDi([
  List<Reminder> reminders = const [],
]) async {
  await sl.reset();
  SharedPreferences.setMockInitialValues({'onboarding_done': true});
  final repo = InMemoryRepository(reminders);
  final scheduler = FakeScheduler();
  sl
    ..registerSingleton<FeatureFlags>(const RemoteFeatureFlags())
    ..registerSingleton<AppPrefs>(await AppPrefs.open())
    ..registerSingleton<ReminderRepository>(repo)
    ..registerSingleton<AlarmScheduler>(scheduler)
    ..registerSingleton(SaveReminder(repo, scheduler))
    ..registerSingleton(DeleteReminder(repo, scheduler, (_) async {}))
    ..registerSingleton(SyncAlarms(repo, scheduler));
  return (repo, scheduler);
}

/// Wraps a screen in the real theme. Android so dialogs and pickers take the
/// Material path and chrome is solid.
Widget themed(Widget child) => MaterialApp(
  theme: MemoTheme.light.copyWith(platform: TargetPlatform.android),
  home: child,
);
