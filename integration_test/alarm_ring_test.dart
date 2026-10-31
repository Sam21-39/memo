import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:memo/core/di.dart';
import 'package:memo/features/reminders/data/alarm/native_alarm.dart';
import 'package:memo/features/reminders/domain/usecases/create_reminder.dart';
import 'package:memo/features/reminders/domain/usecases/delete_reminder.dart';
import 'package:memo/features/reminders/domain/usecases/save_reminder.dart';

/// Device check for M1 on Android: a saved reminder reaches AlarmManager, the
/// receiver fires, and the foreground service starts ringing it.
///
///   fvm flutter test integration_test -d <android device>
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a reminder due in 15 s rings natively', (tester) async {
    if (!Platform.isAndroid) return;
    await configureDependencies();
    final now = DateTime.now();
    final reminder = const CreateReminder()(
      title: 'Integration ring',
      dueAt: now.add(const Duration(seconds: 15)),
      now: now,
    );
    await sl<SaveReminder>()(reminder);

    final native = sl<NativeAlarm>();
    String? ringing;
    for (var i = 0; i < 40 && ringing != reminder.id; i++) {
      await Future<void>.delayed(const Duration(seconds: 1));
      ringing = await native.ringing();
    }
    expect(ringing, reminder.id);

    await native.stopRinging();
    await sl<DeleteReminder>()(reminder.id);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
