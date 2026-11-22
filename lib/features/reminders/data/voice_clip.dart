import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';

/// Records and plays voice clips: WAV, 16 kHz mono, so iOS can ring it as a
/// notification sound and its length is a file-size sum.
class VoiceClip {
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();

  /// iOS rings custom sounds only under 30 s; capped here for both.
  static const maxLength = Duration(seconds: 30);

  /// [request] shows the OS prompt when not yet decided.
  Future<bool> hasPermission({bool request = false}) =>
      _recorder.hasPermission(request: request);

  /// Call only once [hasPermission] is true: a prompt mid-hold would swallow
  /// the release.
  Future<void> start(String path) async {
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );
  }

  Future<void> stop() async {
    if (await _recorder.isRecording()) await _recorder.stop();
  }

  /// Input level 0..1 from the recorder's dBFS reading (-45..0); 0 on error.
  Future<double> level() async {
    try {
      final db = (await _recorder.getAmplitude()).current;
      return ((db + 45) / 45).clamp(0.0, 1.0);
    } catch (_) {
      return 0;
    }
  }

  /// Stops and deletes what was recorded.
  Future<void> cancel() => _recorder.cancel();

  /// Completes when playback ends or is stopped.
  Future<void> play(String path) async {
    final ended = Future.any([
      _player.onPlayerComplete.first,
      _player.onPlayerStateChanged.firstWhere((s) => s == PlayerState.stopped),
    ]);
    await _player.play(DeviceFileSource(path));
    await ended;
  }

  Future<void> stopPlaying() => _player.stop();
}
