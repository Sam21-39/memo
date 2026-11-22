import 'dart:ui';

import 'package:flutter/services.dart';

/// The recogniser tag for an input language: `hi-IN`, `bn-IN`; English is the
/// device's own English (en-GB, en-IN…), else `en-IN`.
String sttTag(String language, [List<Locale>? locales]) {
  if (language == 'hi') return 'hi-IN';
  if (language == 'bn') return 'bn-IN';
  for (final l in locales ?? PlatformDispatcher.instance.locales) {
    if (l.languageCode == 'en') return l.toLanguageTag();
  }
  return 'en-IN';
}

/// `memo/stt`: on-device transcription of a recorded clip. Returns "" when no
/// on-device model exists, permission is refused, or it times out — the clip
/// still saves and rings, titled "Voice note · 0:08".
class SpeechToText {
  const SpeechToText([this._channel = const MethodChannel('memo/stt')]);

  final MethodChannel _channel;

  /// `installed | downloadable | unavailable` for [tag], on this phone.
  Future<String> availability(String tag) async {
    try {
      final v = await _channel
          .invokeMethod<String>('availability', {'locale': tag})
          .timeout(const Duration(seconds: 3));
      return v == 'installed' || v == 'downloadable' ? v! : 'unavailable';
    } catch (_) {
      return 'unavailable';
    }
  }

  Future<bool> available(String tag) async =>
      await availability(tag) == 'installed';

  Future<String> transcribeFile(String path, String tag) async {
    try {
      final text = await _channel
          .invokeMethod<String>('transcribeFile', {'path': path, 'locale': tag})
          .timeout(const Duration(seconds: 20));
      return text?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }
}
