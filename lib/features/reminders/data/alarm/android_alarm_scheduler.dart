import '../../domain/alarm/alarm_ids.dart';
import '../../domain/alarm/alarm_scheduler.dart';
import '../../domain/alarm/fire_plan.dart';
import '../../domain/entities/reminder.dart';
import '../spoken_reminder.dart';
import 'native_alarm.dart';
import '../../../../l10n/l10n.dart';

/// Android: AlarmManager exact alarms and a ringing foreground service, in
/// Kotlin. Dart computes the fires; native stores them, re-arms repeats as
/// they ring and re-arms everything after a reboot.
class AndroidAlarmScheduler implements AlarmScheduler {
  AndroidAlarmScheduler(this._native, this._spoken);

  final NativeAlarm _native;
  final SpokenReminder _spoken;

  /// The reminder read aloud is rendered first, so the alarm can play it
  /// with the app closed.
  Future<List<Map<String, Object?>>> _entries(Reminder r, DateTime now) async {
    final speech = await _spoken.soundFor(r);
    return [
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
          'missedText': l10n().missed(r.title), // l10n: native
          'speech': speech,
          'snoozeId': AlarmIds.snooze(r.id),
        },
    ];
  }

  @override
  Future<void> schedule(Reminder reminder) async =>
      _native.schedule(reminder.id, await _entries(reminder, DateTime.now()));

  @override
  Future<void> cancel(String reminderId) => _native.cancel(reminderId);

  @override
  Future<void> syncAll(List<Reminder> live) async {
    final now = DateTime.now();
    await _native.replaceAll([for (final r in live) ...await _entries(r, now)]);
  }
}
