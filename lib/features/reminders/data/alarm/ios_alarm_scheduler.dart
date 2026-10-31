import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/alarm/alarm_ids.dart';
import '../../domain/alarm/alarm_scheduler.dart';
import '../../domain/alarm/fire_plan.dart';
import '../../domain/entities/reminder.dart';
import '../spoken_reminder.dart';
import 'local_notification_scheduler.dart';
import 'native_alarm.dart' show QueuedAction;

/// `memo/alarmkit`, iOS 26+: real alarms — full screen on the lock screen,
/// through silent and Focus, Done and Snooze on the alert.
class AlarmKit {
  const AlarmKit([this._channel = const MethodChannel('memo/alarmkit')]);

  final MethodChannel _channel;

  /// 'authorized', 'denied', 'notDetermined' or 'unavailable' (iOS < 26).
  Future<String> status() async {
    try {
      return await _channel.invokeMethod<String>('status') ?? 'unavailable';
    } catch (_) {
      return 'unavailable';
    }
  }

  Future<bool> authorize() async {
    try {
      return await _channel.invokeMethod<bool>('authorize') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> schedule(String reminderId, List<Map<String, Object?>> fires) =>
      _channel.invokeMethod('schedule', {
        'reminderId': reminderId,
        'fires': jsonEncode(fires),
      });

  Future<void> cancel(String reminderId) =>
      _channel.invokeMethod('cancel', {'reminderId': reminderId});

  Future<void> replaceAll(List<Map<String, Object?>> fires) =>
      _channel.invokeMethod('replaceAll', {'fires': jsonEncode(fires)});

  /// Done / Snooze tapped on an alarm while the app was closed.
  Future<List<QueuedAction>> drainActions() async {
    try {
      final json = await _channel.invokeMethod<String>('drainActions') ?? '[]';
      return [
        for (final e in (jsonDecode(json) as List).cast<Map<String, dynamic>>())
          QueuedAction(
            e['reminderId'] as String,
            e['action'] as String,
            DateTime.fromMillisecondsSinceEpoch((e['at'] as num).toInt()),
          ),
      ];
    } catch (_) {
      return const [];
    }
  }
}

/// iOS: AlarmKit when the user allowed it (iOS 26+), else Time Sensitive
/// notifications. Decided per call, so granting the permission takes effect
/// at the next sync without a restart.
class IosAlarmScheduler implements AlarmScheduler {
  IosAlarmScheduler(this._alarmKit, this._notifications, this._spoken);

  final AlarmKit _alarmKit;
  final LocalNotificationScheduler _notifications;
  final SpokenReminder _spoken;

  /// Same budget as notifications: AlarmKit also caps how many it holds.
  static const _limit = 64;

  Future<bool> get _useAlarmKit async =>
      await _alarmKit.status() == 'authorized';

  Future<List<Map<String, Object?>>> _entries(
    Reminder r,
    DateTime now, {
    List<AlarmFire>? only,
  }) async {
    final sound = await _spoken.soundFor(r) ?? 'memo_ring.caf';
    return [
      for (final fire in only ?? firesFor(r, now: now))
        {
          'id': fire.id,
          'at': fire.at.millisecondsSinceEpoch.toDouble(),
          'repeat': fire.repeat.name,
          'kind': fire.kind.name,
          'reminderId': r.id,
          'title': r.title,
          'sound': sound,
          'snoozeId': AlarmIds.snooze(r.id),
        },
    ];
  }

  @override
  Future<void> schedule(Reminder reminder) async {
    if (!await _useAlarmKit) return _notifications.schedule(reminder);
    await _notifications.cancel(reminder.id);
    await _alarmKit.schedule(
      reminder.id,
      await _entries(reminder, DateTime.now()),
    );
  }

  @override
  Future<void> cancel(String reminderId) async {
    await _notifications.cancel(reminderId);
    if (await _useAlarmKit) await _alarmKit.cancel(reminderId);
  }

  @override
  Future<void> syncAll(List<Reminder> live) async {
    if (!await _useAlarmKit) return _notifications.syncAll(live);
    await _notifications.syncAll(const []); // clears any older notifications
    final now = DateTime.now();
    final byId = {for (final r in live) r.id: r};
    final fires = [for (final r in live) ...firesFor(r, now: now)]
      ..sort((a, b) => a.at.compareTo(b.at));
    final kept = fires.take(_limit);
    final entries = <Map<String, Object?>>[];
    for (final id in {for (final f in kept) f.reminderId}) {
      entries.addAll(
        await _entries(
          byId[id]!,
          now,
          only: kept.where((f) => f.reminderId == id).toList(),
        ),
      );
    }
    await _alarmKit.replaceAll(entries);
  }
}
