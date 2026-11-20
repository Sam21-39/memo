import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:memo/features/reminders/data/speech_to_text.dart';
import 'package:path_provider/path_provider.dart';

import 'fixtures/pills_wav.dart';

/// Device check for M2: a recorded clip is transcribed on the phone.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a spoken clip comes back as text, on device', (tester) async {
    const stt = SpeechToText();
    // The matrix for the phone under test: read it in the test log.
    for (final lang in ['en', 'hi', 'bn']) {
      // ignore: avoid_print
      print('STT $lang: ${await stt.availability(sttTag(lang))}');
    }
    final tag = sttTag('en');
    if (!await stt.available(tag)) {
      markTestSkipped('No on-device speech model on this device.');
      return;
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/pills.wav')
      ..writeAsBytesSync(base64Decode(pillsWavBase64));
    final text = (await stt.transcribeFile(file.path, tag)).toLowerCase();
    // Synthetic speech: exact words vary, but both sides of the pause must
    // arrive — speech after a pause is a new segment.
    expect(text, anyOf(contains('mum'), contains('mom'), contains('call')));
    expect(text, contains('every'));
  }, timeout: const Timeout(Duration(minutes: 1)));
}
