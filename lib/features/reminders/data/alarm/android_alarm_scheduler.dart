import 'package:path/path.dart' as p;

import '../../domain/alarm/alarm_ids.dart';
import '../../domain/alarm/alarm_scheduler.dart';
import '../../domain/alarm/fire_plan.dart';
import '../../domain/entities/reminder.dart';
import '../media_store.dart';
import '../spoken_reminder.dart';
import 'native_alarm.dart';
import 'serial.dart';
import '../../../../l10n/l10n.dart';

/// Android: AlarmManager exact alarms and a ringing foreground service, in
/// Kotlin. Dart computes the fires; native stores them, re-arms repeats as
/// they ring and re-arms everything after a reboot.
class AndroidAlarmScheduler implements AlarmScheduler {
  AndroidAlarmScheduler(this._native, this._spoken, this._media);

  final NativeAlarm _native;
  final SpokenReminder _spoken;
  final MediaStore _media;

  /// Render, native call and prune of one call finish before the next starts.
  final _serial = Serial();

  /// The reminder read aloud is rendered first, so the alarm can play it
  /// with the app closed. No voice for the title: the voice note, if any,
  /// rings after the chime instead. [used] collects each render kept.
  Future<List<Map<String, Object?>>> _entries(
    Reminder r,
    DateTime now,
    Map<String, String?> used,
  ) async {
    final speech = await _spoken.soundFor(r);
    used[r.id] = speech;
    final l = l10n();
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
          'missedText': l.missed(r.title), // l10n: native
          'doneLabel': l.commonDone,
          'snoozeLabel': l.commonSnoozeTenMinutes,
          'channelName': l.notifAlarmChannel,
          'channelDescription': l.notifAlarmChannelBody,
          'missedChannelName': l.notifMissedChannel,
          'speech':
              speech ??
              (r.hasVoice && r.readAloud ? _media.voicePath(r.id) : null),
          'snoozeId': AlarmIds.snooze(r.id),
        },
    ];
  }

  /// Only after the native call returned: an armed alarm never points at a
  /// deleted file.
  Future<void> _prune(Map<String, String?> used) async {
    for (final e in used.entries) {
      await _spoken.prune(e.key, e.value == null ? null : p.basename(e.value!));
    }
  }

  @override
  Future<void> schedule(Reminder reminder) => _serial.run(() async {
    final used = <String, String?>{};
    await _native.schedule(
      reminder.id,
      await _entries(reminder, DateTime.now(), used),
    );
    await _prune(used);
  });

  @override
  Future<void> cancel(String reminderId) =>
      _serial.run(() => _native.cancel(reminderId));

  @override
  Future<void> syncAll(List<Reminder> live) => _serial.run(() async {
    final now = DateTime.now();
    final used = <String, String?>{};
    await _native.replaceAll([
      for (final r in live) ...await _entries(r, now, used),
    ]);
    await _prune(used);
  });
}
