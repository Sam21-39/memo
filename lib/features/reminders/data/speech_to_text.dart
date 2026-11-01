import 'package:flutter/services.dart';

/// `memo/stt`: on-device transcription of a recorded clip. Returns "" when no
/// on-device model exists, permission is refused, or it times out — the clip
/// still saves and rings, titled "Voice note · 0:08".
class SpeechToText {
  const SpeechToText([this._channel = const MethodChannel('memo/stt')]);

  final MethodChannel _channel;

  Future<bool> available() async {
    try {
      return await _channel
              .invokeMethod<bool>('available')
              .timeout(const Duration(seconds: 3)) ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<String> transcribeFile(String path) async {
    try {
      final text = await _channel
          .invokeMethod<String>('transcribeFile', {'path': path})
          .timeout(const Duration(seconds: 20));
      return text?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }
}
