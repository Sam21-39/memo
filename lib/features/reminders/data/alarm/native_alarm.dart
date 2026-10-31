import 'dart:convert';

import 'package:flutter/services.dart';

/// A platform channel call failed or timed out.
class NativeAlarmError implements Exception {
  const NativeAlarmError(this.method, this.cause);
  final String method;
  final Object cause;

  @override
  String toString() => 'NativeAlarmError($method): $cause';
}

/// A Done or Snooze tapped on a native alarm while Dart was not running.
class QueuedAction {
  const QueuedAction(this.reminderId, this.action, this.at);
  final String reminderId;

  /// 'done' or 'snooze'.
  final String action;
  final DateTime at;
}

/// `memo/alarm`. Every call has a timeout and a typed error.
class NativeAlarm {
  const NativeAlarm([this._channel = const MethodChannel('memo/alarm')]);

  final MethodChannel _channel;
  static const _timeout = Duration(seconds: 5);

  Future<T?> _call<T>(String method, [Map<String, Object?>? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args).timeout(_timeout);
    } catch (error) {
      throw NativeAlarmError(method, error);
    }
  }

  Future<void> schedule(String reminderId, List<Map<String, Object?>> fires) =>
      _call<void>('schedule', {
        'reminderId': reminderId,
        'fires': jsonEncode(fires),
      });

  Future<void> cancel(String reminderId) =>
      _call<void>('cancel', {'reminderId': reminderId});

  Future<void> replaceAll(List<Map<String, Object?>> fires) =>
      _call<void>('replaceAll', {'fires': jsonEncode(fires)});

  Future<List<QueuedAction>> drainActions() async {
    final json = await _call<String>('drainActions') ?? '[]';
    return [
      for (final e in (jsonDecode(json) as List).cast<Map<String, dynamic>>())
        QueuedAction(
          e['reminderId'] as String,
          e['action'] as String,
          DateTime.fromMillisecondsSinceEpoch(e['at'] as int),
        ),
    ];
  }

  /// The reminder ringing right now, if any.
  Future<String?> ringing() => _call<String>('ringing');

  Future<void> stopRinging([String? reminderId]) =>
      _call<void>('stopRinging', {'reminderId': reminderId});

  /// Android 14 asks the user before full-screen alarms are allowed.
  Future<bool> canUseFullScreenIntent() async =>
      await _call<bool>('canUseFullScreenIntent') ?? true;

  Future<void> openFullScreenSettings() =>
      _call<void>('openFullScreenSettings');

  /// iOS: copy a clip into Library/Sounds so a notification can ring it.
  Future<void> installSound(String path, String id) =>
      _call<void>('installSound', {'path': path, 'id': id});

  Future<void> removeSound(String id) => _call<void>('removeSound', {'id': id});

  /// iOS Reduce Transparency: chrome goes solid.
  Future<bool> reduceTransparency() async =>
      await _call<bool>('reduceTransparency') ?? false;
}
