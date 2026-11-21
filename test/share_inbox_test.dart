import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/reminders/data/alarm/native_alarm.dart';
import 'package:memo/features/reminders/data/share_inbox.dart';

String _c(List<int> codes) => String.fromCharCodes(codes);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('sanitizeShared', () {
    test('line breaks and tabs become one space', () {
      expect(sanitizeShared('a\r\n\t b\n\nc'), 'a b c');
      expect(sanitizeShared('a${_c([0x2028, 0x2029])}b'), 'a b');
    });

    test('control, C1, zero-width and bidi characters are removed', () {
      expect(sanitizeShared('a${_c([0, 0x1B, 0x7F, 0x85, 0x9F])}b'), 'ab');
      expect(
        sanitizeShared('a${_c([0x202E, 0x2066, 0x200E, 0xFEFF, 0x061C])}b'),
        'ab',
      );
    });

    test('ZWJ and ZWNJ stay for Hindi and Bengali conjuncts', () {
      final hi = 'क्${_c([0x200D])}ष';
      final bn = 'র${_c([0x200C])}ক';
      expect(sanitizeShared(hi), hi);
      expect(sanitizeShared(bn), bn);
    });

    test('capped at 200 code points, an emoji is not split', () {
      expect(sanitizeShared('a' * 50000).length, sharedTextMax);
      final cut = sanitizeShared('${'a' * 199}😀tail');
      expect(cut, '${'a' * 199}😀');
      expect(cut.runes.length, sharedTextMax);
    });

    test('only control characters leave nothing', () {
      expect(sanitizeShared(_c([0, 1, 2, 0x202E, 0x20, 0x0A])), '');
    });
  });

  group('ShareInbox.next', () {
    const channel = MethodChannel('memo/alarm');
    final acked = <String>[];

    void answer(Object? Function() pending) {
      acked.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'ackShare') {
              acked.add((call.arguments as Map)['id'] as String);
              return null;
            }
            return pending();
          });
    }

    tearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    const inbox = ShareInbox(NativeAlarm());

    test('skips and acks an empty entry, returns the first real one', () async {
      answer(
        () => jsonEncode([
          {
            'id': 'a',
            'text': _c([0, 0x202E]),
          },
          {'id': 'b', 'text': 'Dentist  Friday\n3pm'},
        ]),
      );
      final next = await inbox.next();
      expect(next?.id, 'b');
      expect(next?.text, 'Dentist Friday 3pm');
      expect(acked, ['a']);
    });

    test('null when nothing is pending', () async {
      answer(() => '[]');
      expect(await inbox.next(), isNull);
    });

    test('null on malformed JSON or wrong shape', () async {
      answer(() => '{not json');
      expect(await inbox.next(), isNull);
      answer(() => '{"id": "a"}');
      expect(await inbox.next(), isNull);
      answer(
        () => jsonEncode([
          1,
          'x',
          {'text': 5},
        ]),
      );
      expect(await inbox.next(), isNull);
    });

    test('null on a platform error', () async {
      answer(() => throw PlatformException(code: 'boom'));
      expect(await inbox.next(), isNull);
    });

    test('null when the method is not implemented (iOS before S2)', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      expect(await inbox.next(), isNull);
    });
  });
}
