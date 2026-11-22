import 'dart:async';
import 'dart:io';

import '../../data/voice_clip.dart';
import '../../../../l10n/l10n.dart';

/// What a hold produced.
sealed class HoldResult {
  const HoldResult();
}

/// A clip at least [HoldRecorder.minLength] long sits at the draft path.
class HoldKept extends HoldResult {
  const HoldKept(this.length);
  final Duration length;
}

/// Nothing kept; [notice] says why in one line (null: say nothing).
class HoldDropped extends HoldResult {
  const HoldDropped(this.notice, {this.denied = false});
  final String? notice;

  /// The microphone is refused, not just a short tap.
  final bool denied;
}

/// Tap or hold to record, shared by the capture bar and the edit sheet.
///
/// A press shorter than [tapThreshold] latches: recording goes on until the
/// next tap ([press] again) or [toggle]. A longer press stops on release.
///
/// Start and release race: the release can land while the recorder is still
/// starting, so [release] only records the intent and [press] honours it once
/// the start returns. The microphone prompt is shown outside a press, because
/// a prompt mid-hold swallows the release.
class HoldRecorder {
  HoldRecorder(
    this._voice,
    this._path, {
    String? tempPath,
    required this.onTick,
    required this.onResult,
    this.maxLength = VoiceClip.maxLength,
  }) : _temp = tempPath ?? _path;

  final VoiceClip _voice;
  final String _path;

  /// Where a take records. It replaces [_path] only when kept, so a dropped
  /// or cancelled take never destroys the clip already there.
  final String _temp;

  /// Elapsed time and input level while recording: once at start, then about
  /// 4× a second.
  final void Function(Duration elapsed, double level) onTick;

  /// How the recording ended.
  final void Function(HoldResult result) onResult;

  /// The recording stops by itself here; a parameter so a test need not wait.
  final Duration maxLength;

  static const minLength = Duration(seconds: 1);
  static const tapThreshold = Duration(milliseconds: 300);

  bool _holding = false;
  bool _starting = false;
  bool _stopAfterStart = false;
  bool _cancelled = false;
  bool _recording = false;
  bool _latched = false;
  DateTime? _downAt;
  Timer? _ticker;
  final _clock = Stopwatch();

  bool get recording => _recording;
  bool get latched => _latched;

  /// Finger down. Completes once recording has started, or once it is clear
  /// it will not (then [onResult] has already said why).
  Future<void> press() async {
    if (_recording && _latched) {
      await _finish();
      return;
    }
    if (_recording) return;
    if (_starting) {
      _pressWhileStarting();
      return;
    }
    _starting = true;
    _stopAfterStart = false;
    _cancelled = false;
    try {
      await _start();
    } finally {
      _starting = false;
    }
  }

  /// A tap while the recorder is still starting is a stop, unless a cancel
  /// came first: then it re-arms the pending start, so the new press records
  /// (one start, no stale result).
  void _pressWhileStarting() {
    if (_cancelled) {
      _cancelled = false;
      _stopAfterStart = false;
      _holding = true;
      _downAt = DateTime.now();
    } else {
      _stopAfterStart = true;
    }
  }

  Future<void> _start() async {
    _holding = true;
    _downAt = DateTime.now();
    if (!await _voice.hasPermission()) {
      final granted = await _voice.hasPermission(request: true);
      _holding = false;
      _latched = false;
      onResult(
        !granted
            ? HoldDropped(l10n().holdMicDenied, denied: true)
            : HoldDropped(_cancelled ? null : l10n().holdMicOn),
      );
      return;
    }
    await _voice.start(_temp);
    if (_cancelled || _stopAfterStart || (!_holding && !_latched)) {
      _downAt = null;
      _holding = false;
      _latched = false;
      await _voice.cancel();
      onResult(
        _cancelled || _stopAfterStart
            ? const HoldDropped(null)
            : HoldDropped(l10n().holdHint),
      );
      return;
    }
    _recording = true;
    _clock
      ..reset()
      ..start();
    onTick(Duration.zero, 0);
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) async {
      if (_clock.elapsed >= maxLength) {
        _finish();
      } else {
        final level = await _voice.level();
        if (_recording) onTick(_clock.elapsed, level);
      }
    });
  }

  /// Finger up (or cancelled).
  Future<void> release() async {
    final quick =
        _downAt != null && DateTime.now().difference(_downAt!) < tapThreshold;
    _holding = false;
    if (quick) {
      _latched = true;
      return;
    }
    if (!_recording || _latched) return;
    await _finish();
  }

  /// Screen readers and the Stop button: start, or stop.
  Future<void> toggle() async {
    if (_recording) return _finish();
    if (_starting) {
      _pressWhileStarting();
      if (!_stopAfterStart) _latched = true;
      return;
    }
    _latched = true;
    await press();
  }

  /// Throws the recording away.
  Future<void> cancel() async {
    final was = _recording;
    if (_starting) _cancelled = true;
    _ticker?.cancel();
    _clock.stop();
    _recording = false;
    _holding = false;
    _latched = false;
    _downAt = null;
    if (!was) return;
    await _voice.cancel();
    onResult(const HoldDropped(null));
  }

  Future<void> _finish() async {
    if (!_recording) return;
    _recording = false;
    _latched = false;
    _downAt = null;
    _ticker?.cancel();
    _clock.stop();
    final elapsed = _clock.elapsed;
    try {
      if (elapsed < minLength) {
        await _voice.cancel();
        onResult(HoldDropped(l10n().holdHint));
      } else {
        await _voice.stop();
        final take = File(_temp);
        if (_temp != _path) {
          if (!await take.exists()) {
            onResult(HoldDropped(l10n().holdHint));
            return;
          }
          await take.rename(_path);
        }
        onResult(HoldKept(elapsed));
      }
    } catch (_) {
      // No stuck "recording": the take is lost, the caller is told.
      onResult(HoldDropped(l10n().holdHint));
    }
  }

  Future<void> dispose() async {
    if (_starting) _cancelled = true;
    _ticker?.cancel();
    if (_recording) await _voice.cancel();
  }
}
