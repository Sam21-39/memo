import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/reminders/data/spoken_reminder.dart';

import 'fakes.dart';

void main() {
  test('concurrent renders never overlap on the channel', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('memo/tts');
    final messenger = TestDefaultBinaryMessengerBinding.instance;
    var active = 0;
    var maxActive = 0;
    messenger.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      active++;
      maxActive = max(maxActive, active);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      active--;
      return 'say.wav';
    });
    addTearDown(
      () => messenger.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );

    final tts = SpokenReminder(gender: () => 'female');
    final r = reminder(
      'a',
      'Bins',
      DateTime(2026, 11, 20),
    ).copyWith(readAloud: true);
    final sounds = await Future.wait([
      tts.soundFor(r),
      tts.soundFor(r),
      tts.soundFor(r),
    ]);
    expect(sounds, everyElement('say.wav'));
    expect(maxActive, 1);
  });
}
