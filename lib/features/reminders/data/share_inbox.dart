import 'dart:convert';

import 'alarm/native_alarm.dart';

/// Longest text that reaches the parser and the title.
const sharedTextMax = 200;

final _lineBreaks = RegExp(r'[\r\n\t\u2028\u2029]');
// Keeps U+200C / U+200D: Hindi and Bengali conjuncts need them.
final _unsafe = RegExp(
  r'[\u0000-\u001F\u007F-\u009F\u061C\u200B\u200E\u200F\u202A-\u202E\u2060-\u2069\uFEFF]',
);

/// Text from another app is untrusted: strip control and bidi characters,
/// collapse whitespace, cap the length.
String sanitizeShared(String raw) {
  var text = raw.length > 4000 ? raw.substring(0, 4000) : raw;
  text = text
      .replaceAll(_lineBreaks, ' ')
      .replaceAll(_unsafe, '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  // ponytail: cuts by code point, may split a grapheme cluster at the cap; use package:characters if that shows.
  return String.fromCharCodes(text.runes.take(sharedTextMax)).trimRight();
}

class SharedText {
  const SharedText(this.id, this.text);
  final String id, text;
}

/// Shares another app handed to Memō, waiting natively until put on screen.
class ShareInbox {
  const ShareInbox(this._native);
  final NativeAlarm _native;

  /// The first share with something left after sanitising, or null.
  Future<SharedText?> next() async {
    try {
      final list = jsonDecode(await _native.pendingShares());
      if (list is! List) return null;
      for (final e in list) {
        final id = e is Map ? e['id'] : null;
        final raw = e is Map ? e['text'] : null;
        if (id is! String) continue;
        final text = raw is String ? sanitizeShared(raw) : '';
        if (text.isEmpty) {
          await ack(id);
          continue;
        }
        return SharedText(id, text);
      }
    } on NativeAlarmError {
      return null;
    } on FormatException {
      return null;
    }
    return null;
  }

  Future<void> ack(String id) async {
    try {
      await _native.ackShare(id);
    } on NativeAlarmError {
      // Shown again next time rather than lost.
    }
  }
}
