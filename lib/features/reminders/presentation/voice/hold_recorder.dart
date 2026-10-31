import 'dart:async';

import '../../data/voice_clip.dart';

/// What a hold produced.
sealed class HoldResult {
  const HoldResult();
}

/// A clip at least [HoldRecorder.minLength] long sits at the draft path.
class HoldKept extends HoldResult {
  const HoldKept(this.length);
  final Duration length;
}

/// Nothing kept; [notice] says why in one line.
class HoldDropped extends HoldResult {
  const HoldDropped(this.notice, {this.denied = false});
  final String notice;

  /// The microphone is refused, not just a short tap.
  final bool denied;
}

/// Hold-to-record shared by the capture bar and the edit sheet.
///
/// Start and release race: the release can land while the recorder is still
/// starting, so [release] only records the intent and [press] honours it once
/// the start returns. The microphone prompt is shown outside a hold, because
/// a prompt mid-hold swallows the release.
class HoldRecorder {
  HoldRecorder(
    this._voice,
    this._path, {
    required this.onTick,
    required this.onResult,
  });

  final VoiceClip _voice;
  final String _path;

  /// Elapsed time while recording: once at start, then about 4× a second.
  final void Function(Duration elapsed) onTick;

  /// How the hold ended.
  final void Function(HoldResult result) onResult;

  static const minLength = Duration(seconds: 1);

  bool _holding = false;
  bool _recording = false;
  Timer? _ticker;
  final _clock = Stopwatch();

  bool get recording => _recording;

  /// Finger down. Completes once recording has started, or once it is clear
  /// it will not (then [onResult] has already said why).
  Future<void> press() async {
    if (_recording) return;
    _holding = true;
    if (!await _voice.hasPermission()) {
      final granted = await _voice.hasPermission(request: true);
      onResult(
        granted
            ? const HoldDropped('Microphone on. Hold the mic to record.')
            : const HoldDropped(
                'Microphone not allowed. Turn it on in Settings.',
                denied: true,
              ),
      );
      return;
    }
    await _voice.start(_path);
    if (!_holding) {
      await _voice.cancel();
      onResult(const HoldDropped('Hold the mic to record.'));
      return;
    }
    _recording = true;
    _clock
      ..reset()
      ..start();
    onTick(Duration.zero);
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (_clock.elapsed >= VoiceClip.maxLength) {
        release();
      } else {
        onTick(_clock.elapsed);
      }
    });
  }

  /// Finger up (or cancelled).
  Future<void> release() async {
    _holding = false;
    if (!_recording) return;
    _recording = false;
    _ticker?.cancel();
    _clock.stop();
    final elapsed = _clock.elapsed;
    if (elapsed < minLength) {
      await _voice.cancel();
      onResult(const HoldDropped('Hold the mic to record.'));
    } else {
      await _voice.stop();
      onResult(HoldKept(elapsed));
    }
  }

  Future<void> dispose() async {
    _ticker?.cancel();
    if (_recording) await _voice.cancel();
  }
}
