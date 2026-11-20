import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/reminders/data/media_store.dart';
import 'package:memo/features/reminders/data/speech_to_text.dart';
import 'package:memo/features/reminders/data/voice_clip.dart';
import 'package:memo/features/reminders/domain/entities/repeat_rule.dart';
import 'package:memo/features/reminders/domain/parser/reminder_parser.dart';
import 'package:memo/features/reminders/domain/usecases/save_reminder.dart';
import 'package:memo/features/reminders/presentation/home/capture_cubit.dart';

import 'fakes.dart';

final now = DateTime(2026, 11, 4, 12);

class _Stt implements SpeechToText {
  _Stt(this.text, {this.up = true, this.gate});
  final String text;

  /// On-device recognition exists; false reads as "unavailable offline".
  final bool up;

  /// Holds the transcript back until the test says so.
  final Completer<void>? gate;
  @override
  Future<bool> available() async => up;
  @override
  Future<String> transcribeFile(String path) async {
    await gate?.future;
    return text;
  }
}

class _BrokenStt implements SpeechToText {
  @override
  Future<bool> available() async => throw StateError('no engine');
  @override
  Future<String> transcribeFile(String path) async =>
      throw StateError('no engine');
}

/// Writes a 2 s silent WAV so clip length reads 0:02.
class _Voice implements VoiceClip {
  bool allowed = true;
  bool cancelled = false;

  /// What the OS prompt answers when asked.
  bool grants = false;
  @override
  Future<bool> hasPermission({bool request = false}) async {
    if (request) allowed = grants;
    return allowed;
  }

  @override
  Future<double> level() async => 0.5;
  String? path;
  @override
  Future<void> start(String path) async => this.path = path;
  @override
  Future<void> stop() async =>
      File(path!).writeAsBytesSync(List.filled(44 + 64000, 0));
  @override
  Future<void> cancel() async => cancelled = true;
  @override
  Future<void> play(String path) async {}
  @override
  Future<void> stopPlaying() async {}
}

void main() {
  late InMemoryRepository repo;
  late FakeScheduler scheduler;
  late MediaStore media;

  late _Voice voice;

  CaptureCubit build({
    String transcript = '',
    List<String> tags = const [],
    SpeechToText? stt,
  }) => CaptureCubit(
    SaveReminder(repo, scheduler),
    media: media,
    voice: voice,
    stt: stt ?? _Stt(transcript),
    knownTags: () => tags,
    clock: () => now,
  );

  /// A full hold: down, a second and a bit, up.
  Future<void> hold(CaptureCubit cubit) async {
    await cubit.startRecording();
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await cubit.stopRecording();
    await pumpEventQueue();
  }

  setUp(() {
    voice = _Voice();
    repo = InMemoryRepository();
    scheduler = FakeScheduler();
    media = MediaStore(Directory.systemTemp.createTempSync('capture'));
  });

  test('typing parses into chips as you go', () {
    final cubit = build(tags: ['Work'])
      ..setText('Send deck tomorrow 9am for work');
    expect(cubit.state.phase, CapturePhase.typing);
    expect(cubit.state.title, 'Send deck');
    expect(cubit.state.dueAt, DateTime(2026, 11, 5, 9));
    expect(cubit.state.tag, 'Work');
    expect(cubit.state.unsure, isNull);
  });

  test('clearing the text returns to idle', () {
    final cubit = build()
      ..setText('Bins')
      ..setText('');
    expect(cubit.state.phase, CapturePhase.idle);
  });

  test('a corrected chip wins over the parse', () {
    final cubit = build()
      ..setText('Pills at 8pm')
      ..setDueAt(DateTime(2026, 11, 4, 21))
      ..setRepeat(RepeatRule.daily)
      ..setTag('Health');
    // Typing more keeps the corrections.
    cubit.setText('Pills at 8pm with water');
    expect(cubit.state.dueAt, DateTime(2026, 11, 4, 21));
    expect(cubit.state.repeat, RepeatRule.daily);
    expect(cubit.state.tag, 'Health');
    expect(cubit.state.unsure, isNull);
  });

  test('Save writes and schedules once, then resets', () async {
    final cubit = build()
      ..setText('Bins at 7pm')
      ..review();
    await cubit.save();
    expect(repo.all.single.title, 'Bins');
    expect(scheduler.scheduled.single.dueAt, DateTime(2026, 11, 4, 19));
    expect(cubit.state.phase, CapturePhase.idle);
    expect(cubit.state.text, '');
  });

  test('a held clip is transcribed into the title and rings', () async {
    final cubit = build(transcript: 'call mum at 6pm');
    await hold(cubit);
    expect(cubit.state.phase, CapturePhase.confirming);
    expect(cubit.state.spoken, isTrue);
    expect(cubit.state.text, 'call mum at 6pm');
    expect(cubit.state.title, 'Call mum');
    expect(cubit.state.hasClip, isTrue);

    await cubit.save();
    final saved = repo.all.single;
    expect(saved.title, 'Call mum');
    expect(saved.dueAt, DateTime(2026, 11, 4, 18));
    expect(saved.hasVoice, isTrue);
    expect(saved.readAloud, isTrue);
    expect(File(media.voicePath(saved.id)).existsSync(), isTrue);
  });

  test('an empty transcript fails with the clip kept', () async {
    final cubit = build();
    await hold(cubit);
    expect(cubit.state.phase, CapturePhase.voiceFailed);
    expect(cubit.state.failure, VoiceFailure.empty);
    expect(cubit.state.hasClip, isTrue);
    expect(cubit.state.canSave, isFalse);
  });

  test('no on-device recogniser reads as unavailable', () async {
    final cubit = build(stt: _Stt('', up: false));
    await hold(cubit);
    expect(cubit.state.phase, CapturePhase.voiceFailed);
    expect(cubit.state.failure, VoiceFailure.unavailable);
  });

  test('Type instead keeps the clip and returns to the field', () async {
    final cubit = build();
    await hold(cubit);
    cubit.typeInstead();
    expect(cubit.state.phase, CapturePhase.typing);
    expect(cubit.state.hasClip, isTrue);
    expect(cubit.state.failure, isNull);
    expect(cubit.state.canContinue, isTrue);
  });

  test('Save as voice note needs a picked time', () async {
    final cubit = build();
    await hold(cubit);
    cubit.saveAsVoiceNote();
    expect(cubit.state.phase, CapturePhase.confirming);
    expect(cubit.state.unsure?.kinds, {AmbiguityKind.noTime});
    expect(cubit.state.canSave, isFalse);
    await cubit.save();
    expect(repo.all, isEmpty, reason: 'nothing scheduled from a guess');

    cubit.chooseTime(DateTime(2026, 11, 4, 15));
    expect(cubit.state.canSave, isTrue);
    await cubit.save();
    expect(repo.all.single.title, 'Voice note · 0:02');
    expect(repo.all.single.hasVoice, isTrue);
    expect(repo.all.single.dueAt, DateTime(2026, 11, 4, 15));
  });

  test('a voice-only clip saves even as the clock moves on', () async {
    var t = now;
    final cubit = CaptureCubit(
      SaveReminder(repo, scheduler),
      media: media,
      voice: voice,
      stt: _Stt(''),
      knownTags: () => const [],
      clock: () => t = t.add(const Duration(seconds: 1)),
    );
    await hold(cubit);
    cubit
      ..saveAsVoiceNote()
      ..chooseTime(DateTime(2026, 11, 4, 13));
    await cubit.save();
    expect(cubit.state.error, isNull);
    expect(repo.all.single.dueAt, DateTime(2026, 11, 4, 13));
  });

  test('an unsure time blocks Save until one is chosen', () async {
    final cubit = build()
      ..setText('Call mum tomorrow at 8')
      ..review();
    expect(cubit.state.phase, CapturePhase.confirming);
    expect(cubit.state.unsure?.kinds, {AmbiguityKind.amPm});
    expect(cubit.state.canSave, isFalse);
    await cubit.save();
    expect(repo.all, isEmpty);

    cubit.chooseTime(DateTime(2026, 11, 5, 20));
    expect(cubit.state.unsure, isNull);
    expect(cubit.state.canSave, isTrue);
    await cubit.save();
    expect(repo.all.single.dueAt, DateTime(2026, 11, 5, 20));
  });

  test('a stated time saves without a choice', () async {
    final cubit = build()
      ..setText('Call mum tomorrow at 8 AM')
      ..review();
    expect(cubit.state.canSave, isTrue);
  });

  test('no time at all is unsure too', () {
    final cubit = build()
      ..setText('Pay rent')
      ..review();
    expect(cubit.state.unsure?.kinds, {AmbiguityKind.noTime});
    expect(cubit.state.canSave, isFalse);
  });

  test('Continue needs a title or a clip; Back returns to typing', () {
    final cubit = build()..review();
    expect(cubit.state.phase, CapturePhase.idle);
    cubit
      ..setText('Bins at 7pm')
      ..review();
    expect(cubit.state.phase, CapturePhase.confirming);
    cubit.backToTyping();
    expect(cubit.state.phase, CapturePhase.typing);
    expect(cubit.state.text, 'Bins at 7pm');
  });

  test('saved is set for one emit and the bar resets', () async {
    final cubit = build()
      ..setText('Bins at 7pm')
      ..review();
    final seen = <CaptureState>[];
    final sub = cubit.stream.listen(seen.add);
    await cubit.save();
    cubit.setText('Next');
    await pumpEventQueue();
    await sub.cancel();
    final withSaved = seen.where((s) => s.saved != null).toList();
    expect(withSaved, hasLength(1));
    expect(withSaved.single.saved!.title, 'Bins');
    expect(withSaved.single.phase, CapturePhase.idle);
    expect(cubit.state.saved, isNull);
  });

  test('a quick tap latches recording; Stop keeps the clip', () async {
    final cubit = build(transcript: 'Bins at 7pm');
    await cubit.startRecording();
    await cubit.stopRecording(); // up inside 300 ms
    expect(cubit.state.phase, CapturePhase.recording);
    expect(cubit.state.latched, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await cubit.toggleRecording();
    await pumpEventQueue();
    expect(cubit.state.phase, CapturePhase.confirming);
    expect(cubit.state.hasClip, isTrue);
  });

  test('Cancel while recording drops silently', () async {
    final cubit = build(transcript: 'Bins at 7pm');
    await cubit.toggleRecording();
    expect(cubit.state.phase, CapturePhase.recording);
    await cubit.cancelRecording();
    expect(voice.cancelled, isTrue);
    expect(cubit.state.phase, CapturePhase.idle);
    expect(cubit.state.hasClip, isFalse);
    expect(cubit.state.notice, isNull);
    expect(cubit.state.error, isNull);
    expect(cubit.state.latched, isFalse);
  });

  test('a hold that is too short says how to record', () async {
    final cubit = build();
    await cubit.startRecording();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await cubit.stopRecording();
    expect(cubit.state.phase, CapturePhase.idle);
    expect(cubit.state.notice, 'Tap the mic, speak, then tap Stop.');
  });

  test('a refused microphone is flagged with an error', () async {
    voice.allowed = false;
    final cubit = build();
    await cubit.startRecording();
    expect(cubit.state.micDenied, isTrue);
    expect(cubit.state.error, contains('Microphone not allowed'));
    expect(cubit.state.phase, CapturePhase.idle);
  });

  test('Cancel while understanding keeps the clip', () async {
    final gate = Completer<void>();
    final cubit = build(stt: _Stt('Bins at 7pm', gate: gate));
    await hold(cubit);
    expect(cubit.state.phase, CapturePhase.transcribing);
    cubit.cancelTranscription();
    expect(cubit.state.phase, CapturePhase.voiceFailed);
    expect(cubit.state.failure, VoiceFailure.cancelled);
    expect(cubit.state.hasClip, isTrue);
    gate.complete(); // the late transcript must not resurrect the draft
    await pumpEventQueue();
    expect(cubit.state.phase, CapturePhase.voiceFailed);
  });

  test('typed words win over a transcript', () async {
    final cubit = build(transcript: 'call mum at 6pm')..setText('Bins at 7pm');
    await hold(cubit);
    expect(cubit.state.phase, CapturePhase.typing);
    expect(cubit.state.text, 'Bins at 7pm');
    expect(cubit.state.spoken, isFalse);
  });

  test('Try again discards the draft and records anew', () async {
    final cubit = build();
    await hold(cubit);
    expect(cubit.state.phase, CapturePhase.voiceFailed);
    await cubit.tryAgain();
    expect(cubit.state.phase, CapturePhase.recording);
    await cubit.cancelRecording();
  });

  test('a schedule failure is shown, the row kept for retry', () async {
    scheduler.fail = true;
    final cubit = build()
      ..setText('Bins at 7pm')
      ..review();
    await cubit.save();
    expect(cubit.state.error, isNotNull);
    expect(cubit.state.saved, isNull, reason: 'no "Reminder set" toast');
    expect(repo.all.single.needsSchedule, isTrue);
  });

  test('a draft that vanished after More saves without a clip', () async {
    final cubit = build(transcript: 'Bins at 7pm');
    await hold(cubit);
    File(media.draftVoicePath).deleteSync();
    await cubit.save();
    expect(repo.all.single.hasVoice, isFalse);
  });

  test('Settings defaults apply to the next capture without restart', () async {
    int? nag = 10;
    var aloud = true;
    final cubit = CaptureCubit(
      SaveReminder(repo, scheduler),
      media: media,
      voice: voice,
      stt: _Stt(''),
      knownTags: () => const [],
      clock: () => now,
      defaultNagMin: () => nag,
      readAloudDefault: () => aloud,
    );
    nag = null;
    aloud = false;
    cubit
      ..setText('Bins at 7pm')
      ..review();
    await cubit.save();
    expect(repo.all.single.nagMin, isNull);
    expect(repo.all.single.readAloud, isFalse);
  });

  test('a recogniser that throws ends in voiceFailed, not stuck', () async {
    final cubit = build(stt: _BrokenStt());
    await hold(cubit);
    expect(cubit.state.phase, CapturePhase.voiceFailed);
    expect(cubit.state.hasClip, isTrue);
  });

  test('an empty transcript keeps typed text and the clip', () async {
    final cubit = build()..setText('Bins at 7pm');
    await hold(cubit);
    expect(cubit.state.phase, CapturePhase.typing);
    expect(cubit.state.text, 'Bins at 7pm');
    expect(cubit.state.hasClip, isTrue);
  });

  test('Save as voice note never drops typed text', () async {
    final gate = Completer<void>();
    final cubit = build(stt: _Stt('', gate: gate))..setText('Bins');
    await hold(cubit);
    cubit.cancelTranscription();
    cubit.saveAsVoiceNote();
    expect(cubit.state.phase, CapturePhase.confirming);
    expect(cubit.state.text, 'Bins');
    expect(cubit.state.title, 'Bins');
    gate.complete();
  });

  test('recording does not start while transcribing', () async {
    final gate = Completer<void>();
    final cubit = build(stt: _Stt('Bins at 7pm', gate: gate));
    await hold(cubit);
    expect(cubit.state.phase, CapturePhase.transcribing);
    await cubit.startRecording();
    await cubit.toggleRecording();
    expect(cubit.state.phase, CapturePhase.transcribing);
    expect(voice.cancelled, isFalse);
    gate.complete();
    await pumpEventQueue();
  });

  test('picking a time clears the error', () {
    final cubit = build()
      ..setText('Bins at 7pm')
      ..review();
    cubit.emit(cubit.state.copyWith(error: 'Time passed'));
    cubit.setDueAt(DateTime(2026, 11, 5, 9));
    expect(cubit.state.error, isNull);
  });

  test('a granted microphone clears the denied look on resume', () async {
    voice.allowed = false;
    final cubit = build();
    await cubit.startRecording();
    expect(cubit.state.micDenied, isTrue);
    await cubit.recheckMic();
    expect(cubit.state.micDenied, isTrue);
    voice.allowed = true; // granted in Settings
    await cubit.recheckMic();
    expect(cubit.state.micDenied, isFalse);
    expect(cubit.state.error, isNull);
  });
}
