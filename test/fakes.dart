import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:memo/features/reminders/domain/entities/reminder.dart';
import 'package:memo/features/reminders/domain/entities/repeat_rule.dart';
import 'package:memo/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// The scheduler resolves `tz.local` on every schedule. Without this, any test
/// that persists a reminder still due dies on a LateInitializationError.
void initTestTimeZone() {
  tz_data.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('UTC'));
}

class InMemoryRepository implements ReminderRepository {
  InMemoryRepository([this._reminders = const []]);

  List<Reminder> _reminders;

  @override
  Future<List<Reminder>> getAll() async =>
      [..._reminders]..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  @override
  Future<Reminder?> getById(String id) async =>
      _reminders.where((r) => r.id == id).firstOrNull;

  @override
  Future<void> save(Reminder reminder) async {
    _reminders = [..._reminders.where((r) => r.id != reminder.id), reminder];
  }

  @override
  Future<void> delete(String id) async {
    _reminders = _reminders.where((r) => r.id != id).toList();
  }
}

class NoopPlugin implements FlutterLocalNotificationsPlugin {
  @override
  dynamic noSuchMethod(Invocation invocation) async => null;
}

Reminder reminder(
  String id,
  String title,
  DateTime at, {
  String? tag,
  RepeatRule repeat = RepeatRule.none,
}) => Reminder(
  id: id,
  title: title,
  scheduledAt: at,
  createdAt: DateTime(2026, 8, 1),
  tag: tag,
  repeat: repeat,
);
