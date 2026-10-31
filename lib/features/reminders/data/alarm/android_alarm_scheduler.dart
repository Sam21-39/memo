import '../../domain/alarm/alarm_ids.dart';
import '../../domain/alarm/alarm_scheduler.dart';
import '../../domain/alarm/fire_plan.dart';
import '../../domain/entities/reminder.dart';
import 'native_alarm.dart';

/// Android: AlarmManager exact alarms and a ringing foreground service, in
/// Kotlin. Dart computes the fires; native stores them, re-arms repeats as
/// they ring and re-arms everything after a reboot.
class AndroidAlarmScheduler implements AlarmScheduler {
  AndroidAlarmScheduler(this._native, {required this.voicePath});

  final NativeAlarm _native;

  /// Absolute path of a reminder's clip, used when it rings with the voice.
  final String Function(String reminderId) voicePath;

  List<Map<String, Object?>> _entries(Reminder r, DateTime now) => [
    for (final fire in firesFor(r, now: now))
      {
        'id': fire.id,
        'at': fire.at.millisecondsSinceEpoch,
        'repeat': fire.repeat.name,
        'kind': fire.kind.name,
        'group': fire.group,
        'reminderId': r.id,
        'title': r.title,
        'body': r.note ?? '',
        'sound': r.hasVoice && r.voiceRings ? voicePath(r.id) : null,
        'snoozeId': AlarmIds.snooze(r.id),
      },
  ];

  @override
  Future<void> schedule(Reminder reminder) =>
      _native.schedule(reminder.id, _entries(reminder, DateTime.now()));

  @override
  Future<void> cancel(String reminderId) => _native.cancel(reminderId);

  @override
  Future<void> syncAll(List<Reminder> live) {
    final now = DateTime.now();
    return _native.replaceAll([for (final r in live) ..._entries(r, now)]);
  }
}
