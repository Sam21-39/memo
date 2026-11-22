import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/reminders/data/speech_to_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('memo/stt');
  final messenger = TestDefaultBinaryMessengerBinding.instance;
  final calls = <MethodCall>[];

  void answer(Future<Object?> Function(MethodCall) handler) {
    calls.clear();
    messenger.defaultBinaryMessenger.setMockMethodCallHandler(channel, (c) {
      calls.add(c);
      return handler(c);
    });
  }

  tearDown(
    () => messenger.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      null,
    ),
  );

  test('sttTag: hi-IN, bn-IN, device English else en-IN', () {
    expect(sttTag('hi'), 'hi-IN');
    expect(sttTag('bn'), 'bn-IN');
    expect(
      sttTag('en', const [Locale('hi', 'IN'), Locale('en', 'GB')]),
      'en-GB',
    );
    expect(sttTag('en', const [Locale('hi', 'IN')]), 'en-IN');
    expect(sttTag('en', const []), 'en-IN');
  });

  test('availability matrix, one answer per tag', () async {
    answer((c) async {
      expect(c.method, 'availability');
      return switch ((c.arguments as Map)['locale']) {
        'en-IN' => 'installed',
        'hi-IN' => 'downloadable',
        'bn-IN' => 'unavailable',
        _ => 'weird',
      };
    });
    const stt = SpeechToText();
    expect(await stt.availability('en-IN'), 'installed');
    expect(await stt.availability('hi-IN'), 'downloadable');
    expect(await stt.availability('bn-IN'), 'unavailable');
    expect(await stt.availability('xx'), 'unavailable');
    expect(await stt.available('en-IN'), isTrue);
    expect(await stt.available('hi-IN'), isFalse);
  });

  test('a failing or missing channel reads as unavailable', () async {
    const stt = SpeechToText();
    expect(await stt.availability('hi-IN'), 'unavailable'); // no handler
    answer((_) async => throw PlatformException(code: 'x'));
    expect(await stt.availability('hi-IN'), 'unavailable');
    expect(await stt.available('hi-IN'), isFalse);
    expect(await stt.transcribeFile('/a.wav', 'hi-IN'), '');
  });

  test('transcribeFile sends the path and the locale', () async {
    answer((_) async => ' नमस्ते ');
    expect(
      await const SpeechToText().transcribeFile('/a.wav', 'hi-IN'),
      'नमस्ते',
    );
    expect(calls.single.arguments, {'path': '/a.wav', 'locale': 'hi-IN'});
  });
}
