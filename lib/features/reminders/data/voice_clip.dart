import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';

/// Records and plays voice clips: WAV, 16 kHz mono, so iOS can ring it as a
/// notification sound and its length is a file-size sum.
class VoiceClip {
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();

  /// iOS rings custom sounds only under 30 s; capped here for both.
  static const maxLength = Duration(seconds: 30);

  Future<bool> start(String path) async {
    if (!await _recorder.hasPermission()) return false;
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );
    return true;
  }

  Future<void> stop() async {
    if (await _recorder.isRecording()) await _recorder.stop();
  }

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
