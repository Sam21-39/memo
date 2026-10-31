import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/reminders/data/media_store.dart';
import 'package:memo/features/reminders/data/voice_clip.dart';
import 'package:memo/features/reminders/domain/usecases/save_reminder.dart';
import 'package:memo/features/reminders/presentation/edit/edit_cubit.dart';
import 'package:memo/features/reminders/presentation/edit/edit_sheet.dart';

import 'fakes.dart';

class _FakeVoice implements VoiceClip {
  bool allowed = true;
  bool asked = false;
  bool recording = false;
  bool cancelled = false;

  /// Completes the recorder's start when the test says so.
  Completer<void>? startGate;

  @override
  Future<bool> hasPermission({bool request = false}) async {
    if (request) {
      asked = true;
      allowed = true;
    }
    return allowed;
  }

  @override
  Future<void> start(String path) async {
    await startGate?.future;
    recording = true;
  }

  @override
  Future<void> stop() async => recording = false;

  @override
  Future<void> cancel() async {
    recording = false;
    cancelled = true;
  }

  @override
  Future<void> play(String path) async {}

  @override
  Future<void> stopPlaying() async {}
}

void main() {
  late _FakeVoice voice;
  late EditCubit cubit;

  setUp(() {
    final repo = InMemoryRepository();
    voice = _FakeVoice();
    cubit = EditCubit(
      SaveReminder(repo, FakeScheduler()),
      media: MediaStore(Directory.systemTemp.createTempSync('media')),
      voice: voice,
    );
  });

  tearDown(() => cubit.close());

  test('a full hold records a clip', () async {
    await cubit.startRecording();
    expect(cubit.state.recording, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await cubit.stopRecording();
    expect(cubit.state.recording, isFalse);
    expect(cubit.state.hasClip, isTrue);
    expect(cubit.state.canSave, isTrue); // a clip alone is enough
  });

  test('a release while the recorder is starting cancels it', () async {
    voice.startGate = Completer();
    final starting = cubit.startRecording();
    await cubit.stopRecording(); // finger up before start returns
    voice.startGate!.complete();
    await starting;
    expect(voice.cancelled, isTrue);
    expect(cubit.state.recording, isFalse);
    expect(cubit.state.hasClip, isFalse);
  });

  test('a tap shorter than a second keeps nothing', () async {
    await cubit.startRecording();
    await cubit.stopRecording();
    expect(voice.cancelled, isTrue);
    expect(cubit.state.hasClip, isFalse);
    expect(cubit.state.notice, 'Hold the mic to record.');
  });

  test('first use asks for the mic and does not record yet', () async {
    voice.allowed = false;
    await cubit.startRecording();
    expect(voice.asked, isTrue);
    expect(voice.recording, isFalse);
    expect(cubit.state.recording, isFalse);
    expect(cubit.state.notice, contains('Hold the mic'));
  });

  testWidgets('releasing the real mic button stops the recording', (
    tester,
  ) async {
    await setUpDi();
    await tester.pumpWidget(
      themed(
        Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: const EditForm(knownTags: []),
          ),
        ),
      ),
    );
    final mic = find.byIcon(Icons.mic_none_rounded);
    await tester.ensureVisible(mic);
    await tester.pumpAndSettle();

    final finger = await tester.startGesture(tester.getCenter(mic));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1100)),
    );
    await tester.pump();
    expect(cubit.state.recording, isTrue);
    expect(mic, findsOneWidget, reason: 'the mic must stay under the finger');

    await finger.up();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(cubit.state.recording, isFalse);
    expect(cubit.state.hasClip, isTrue);
  });
}
