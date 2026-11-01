import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:memo/core/di.dart';
import 'package:memo/features/reminders/data/alarm/native_alarm.dart';
import 'package:memo/features/reminders/domain/usecases/apply_alarm_action.dart';
import 'package:memo/features/reminders/domain/usecases/create_reminder.dart';
import 'package:memo/features/reminders/domain/usecases/delete_reminder.dart';
import 'package:memo/features/reminders/domain/usecases/save_reminder.dart';

/// Device check for M3 on Android: a nag rings again until Done, then stops.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<String?> waitForRing(NativeAlarm native, Duration within) async {
    final end = DateTime.now().add(within);
    while (DateTime.now().isBefore(end)) {
      final ringing = await native.ringing();
      if (ringing != null) return ringing;
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    return null;
  }

  testWidgets('nag re-rings, Done silences the rest', (tester) async {
    if (!Platform.isAndroid) return;
    await configureDependencies();
    final native = sl<NativeAlarm>();
    final now = DateTime.now();
    final reminder = const CreateReminder()(
      title: 'Nag check',
      dueAt: now.add(const Duration(seconds: 10)),
      now: now,
      nagMin: 1,
    );
    await sl<SaveReminder>()(reminder);

    expect(await waitForRing(native, const Duration(seconds: 40)), reminder.id);
    await native.stopRinging(); // ignored, not done
    expect(
      await waitForRing(native, const Duration(seconds: 75)),
      reminder.id,
      reason: 'the first nag rings a minute later',
    );

    await native.stopRinging(reminder.id);
    await sl<ApplyAlarmAction>()(reminder.id, AlarmAction.done, DateTime.now());
    expect(
      await waitForRing(native, const Duration(seconds: 75)),
      isNull,
      reason: 'after Done no further nag rings',
    );
    await sl<DeleteReminder>()(reminder.id);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
