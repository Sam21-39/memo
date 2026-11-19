import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/reminders/data/media_store.dart';
import 'package:memo/features/reminders/data/speech_to_text.dart';
import 'package:memo/features/reminders/data/voice_clip.dart';
import 'package:memo/features/reminders/domain/entities/repeat_rule.dart';
import 'package:memo/features/reminders/domain/usecases/save_reminder.dart';
import 'package:memo/features/reminders/presentation/home/capture_cubit.dart';

import 'fakes.dart';

final now = DateTime(2026, 11, 4, 12);

class _Stt implements SpeechToText {
  _Stt(this.text);
  final String text;
  @override
  Future<bool> available() async => true;
  @override
  Future<String> transcribeFile(String path) async => text;
}

/// Writes a 2 s silent WAV so clip length reads 0:02.
class _Voice implements VoiceClip {
  @override
  Future<bool> hasPermission({bool request = false}) async => true;
  String? path;
  @override
  Future<void> start(String path) async => this.path = path;
  @override
  Future<void> stop() async =>
      File(path!).writeAsBytesSync(List.filled(44 + 64000, 0));
  @override
  Future<void> cancel() async {}
  @override
  Future<void> play(String path) async {}
  @override
  Future<void> stopPlaying() async {}
}

void main() {
  late InMemoryRepository repo;
  late FakeScheduler scheduler;
  late MediaStore media;

  CaptureCubit build({String transcript = '', List<String> tags = const []}) =>
      CaptureCubit(
        SaveReminder(repo, scheduler),
        media: media,
        voice: _Voice(),
        stt: _Stt(transcript),
        knownTags: () => tags,
        clock: () => now,
      );

  setUp(() {
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
    expect(cubit.state.timeGuessed, isFalse);
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
    expect(cubit.state.timeGuessed, isFalse);
  });

  test('Save writes and schedules once, then resets', () async {
    final cubit = build()..setText('Bins at 7pm');
    await cubit.save();
    expect(repo.all.single.title, 'Bins');
    expect(scheduler.scheduled.single.dueAt, DateTime(2026, 11, 4, 19));
    expect(cubit.state.phase, CapturePhase.idle);
    expect(cubit.state.text, '');
  });

  test('a held clip is transcribed into the title and rings', () async {
    final cubit = build(transcript: 'call mum at 6pm');
    await cubit.startRecording();
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await cubit.stopRecording();
    await pumpEventQueue();
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

  test('an empty transcript still saves, as a voice note', () async {
    final cubit = build();
    await cubit.startRecording();
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await cubit.stopRecording();
    await pumpEventQueue();
    expect(cubit.state.canSave, isTrue);
    expect(cubit.state.notice, contains('voice note'));

    await cubit.save();
    expect(repo.all.single.title, 'Voice note · 0:02');
    expect(repo.all.single.hasVoice, isTrue);
  });

  test('a voice-only clip saves even as the clock moves on', () async {
    var t = now;
    final cubit = CaptureCubit(
      SaveReminder(repo, scheduler),
      media: media,
      voice: _Voice(),
      stt: _Stt(''),
      knownTags: () => const [],
      clock: () => t = t.add(const Duration(seconds: 1)),
    );
    await cubit.startRecording();
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await cubit.stopRecording();
    await pumpEventQueue();
    await cubit.save();
    expect(cubit.state.error, isNull);
    expect(repo.all.single.dueAt.minute, 0);
    expect(repo.all.single.dueAt.isAfter(now), isTrue);
  });

  test('a schedule failure is shown, the row kept for retry', () async {
    scheduler.fail = true;
    final cubit = build()..setText('Bins at 7pm');
    await cubit.save();
    expect(cubit.state.error, isNotNull);
    expect(repo.all.single.needsSchedule, isTrue);
  });

  test('a draft that vanished after More saves without a clip', () async {
    final cubit = build(transcript: 'Bins at 7pm');
    await cubit.startRecording();
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await cubit.stopRecording();
    await pumpEventQueue();
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
      voice: _Voice(),
      stt: _Stt(''),
      knownTags: () => const [],
      clock: () => now,
      defaultNagMin: () => nag,
      readAloudDefault: () => aloud,
    );
    nag = null;
    aloud = false;
    cubit.setText('Bins at 7pm');
    await cubit.save();
    expect(repo.all.single.nagMin, isNull);
    expect(repo.all.single.readAloud, isFalse);
  });
}
