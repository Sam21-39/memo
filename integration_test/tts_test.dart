import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:memo/core/di.dart';
import 'package:memo/features/reminders/data/alarm/native_alarm.dart';
import 'package:memo/features/reminders/data/spoken_reminder.dart';
import 'package:memo/features/reminders/domain/usecases/create_reminder.dart';
import 'package:memo/features/reminders/domain/usecases/delete_reminder.dart';
import 'package:memo/features/reminders/domain/usecases/save_reminder.dart';

/// Device check: the app's own voice renders offline in both genders, and a
/// read-aloud reminder rings natively.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders the reminder in both voices and rings', (tester) async {
    if (!Platform.isAndroid) return;
    await configureDependencies();
    final now = DateTime.now();
    final reminder = const CreateReminder()(
      title: 'Take your pills',
      dueAt: now.add(const Duration(seconds: 12)),
      now: now,
    ).copyWith(readAloud: true, note: 'Two with water');

    final sizes = <String, int>{};
    for (final g in ['female', 'male']) {
      final path = await SpokenReminder(gender: () => g).soundFor(reminder);
      expect(path, isNotNull, reason: '$g render');
      sizes[g] = File(path!).lengthSync();
      // 22 kHz 16-bit speech of ~2.5 s is well over 50 KB.
      expect(sizes[g], greaterThan(50000), reason: '$g has audio');
    }
    // ignore: avoid_print
    print('TTS sizes: $sizes');

    // Hindi and Bengali render only where the phone has an offline voice.
    final spoken = SpokenReminder(gender: () => 'female');
    final voices = (await spoken.refreshVoices()) ?? <String>{};
    // ignore: avoid_print
    print('TTS voices: $voices');
    for (final (lang, title) in [('hi', 'दवा लो'), ('bn', 'ওষুধ খান')]) {
      final r = reminder.copyWith(title: title, note: null);
      final path = await spoken.soundFor(r);
      if (voices.contains(lang)) {
        expect(path, isNotNull, reason: '$lang render');
        expect(File(path!).lengthSync(), greaterThan(20000));
      } else {
        expect(path, isNull, reason: 'no $lang voice: never an English one');
      }
    }

    await sl<SaveReminder>()(reminder);
    final native = sl<NativeAlarm>();
    String? ringing;
    for (var i = 0; i < 40 && ringing == null; i++) {
      await Future<void>.delayed(const Duration(seconds: 1));
      ringing = await native.ringing();
    }
    expect(ringing, reminder.id);
    // Let it speak once so a person beside the phone can hear it.
    await Future<void>.delayed(const Duration(seconds: 12));
    await native.stopRinging(reminder.id);
    await sl<DeleteReminder>()(reminder.id);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
