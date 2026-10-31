import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:memo/core/di.dart';
import 'package:memo/features/reminders/data/alarm/ios_alarm_scheduler.dart';
import 'package:memo/features/reminders/data/spoken_reminder.dart';
import 'package:memo/features/reminders/domain/usecases/create_reminder.dart';
import 'package:memo/features/reminders/domain/usecases/save_reminder.dart';

/// Device check on iPhone: both voices render into an alarm sound, AlarmKit
/// is allowed, and a read-aloud reminder is scheduled for 60 s from now.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders voices and schedules a real alarm', (tester) async {
    if (!Platform.isIOS) return;
    await configureDependencies();
    final now = DateTime.now();
    final reminder = const CreateReminder()(
      title: 'Take your pills',
      dueAt: now.add(const Duration(seconds: 60)),
      now: now,
    ).copyWith(readAloud: true, note: 'Two with water');

    for (final g in ['female', 'male']) {
      final name = await SpokenReminder(gender: () => g).soundFor(reminder);
      // ignore: avoid_print
      print('VOICE $g -> $name');
      expect(name, isNotNull, reason: '$g render');
    }

    final kit = sl<AlarmKit>();
    if (await kit.status() == 'notDetermined') await kit.authorize();
    final status = await kit.status();
    // ignore: avoid_print
    print('ALARMKIT $status');
    expect(status, 'authorized', reason: 'tap Allow on the phone');

    await sl<SaveReminder>()(reminder);
    // ignore: avoid_print
    print('SCHEDULED ${reminder.dueAt} — lock the phone now');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
