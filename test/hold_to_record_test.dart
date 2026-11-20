import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/reminders/data/media_store.dart';
import 'package:memo/features/reminders/data/voice_clip.dart';
import 'package:memo/features/reminders/presentation/voice/hold_recorder.dart';
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
  int starts = 0;
  bool stopThrows = false;

  /// Writes the take, as a real recorder does.
  void Function(String path)? onStart;

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
    starts++;
    await startGate?.future;
    recording = true;
    onStart?.call(path);
  }

  @override
  Future<void> stop() async {
    if (stopThrows) throw StateError('recorder died');
    recording = false;
  }

  @override
  Future<void> cancel() async {
    recording = false;
    cancelled = true;
  }

  @override
  Future<double> level() async => 0.5;

  @override
  Future<void> play(String path) async {}

  @override
  Future<void> stopPlaying() async {}
}

class _GatedPermission extends _FakeVoice {
  _GatedPermission(this.gate);
  final Completer<bool> gate;
  @override
  Future<bool> hasPermission({bool request = false}) =>
      request ? gate.future : Future.value(false);
}

void main() {
  late _FakeVoice voice;
  late EditCubit cubit;

  setUp(() {
    final repo = InMemoryRepository();
    voice = _FakeVoice()..onStart = (path) => File(path).writeAsBytesSync([1]);
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
    // A held finger, not a tap: a quick release would latch instead.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    await cubit.stopRecording(); // finger up before start returns
    voice.startGate!.complete();
    await starting;
    expect(voice.cancelled, isTrue);
    expect(cubit.state.recording, isFalse);
    expect(cubit.state.hasClip, isFalse);
  });

  test('a hold shorter than a second keeps nothing', () async {
    await cubit.startRecording();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await cubit.stopRecording();
    expect(voice.cancelled, isTrue);
    expect(cubit.state.hasClip, isFalse);
    expect(cubit.state.notice, 'Tap the mic, speak, then tap Stop.');
  });

  test('a quick tap latches; the second tap keeps the clip', () async {
    await cubit.startRecording();
    await cubit.stopRecording(); // up inside 300 ms
    expect(cubit.state.recording, isTrue);
    expect(cubit.state.latched, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await cubit.startRecording(); // second tap
    expect(cubit.state.recording, isFalse);
    expect(cubit.state.hasClip, isTrue);
  });

  test('toggle starts and stops for screen readers', () async {
    await cubit.toggleRecording();
    expect(cubit.state.recording, isTrue);
    expect(cubit.state.latched, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await cubit.toggleRecording();
    expect(cubit.state.hasClip, isTrue);
  });

  testWidgets('hiding the app stops a latched edit recording', (tester) async {
    await setUpDi();
    tester.view.physicalSize = const Size(1200, 4000);
    addTearDown(tester.view.resetPhysicalSize);
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
    await tester.runAsync(() => cubit.toggleRecording());
    expect(cubit.state.recording, isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    expect(cubit.state.recording, isFalse);
    expect(cubit.state.hasClip, isFalse);
    expect(voice.recording, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  test('cancelRecording discards a latched edit take', () async {
    await cubit.toggleRecording();
    await cubit.cancelRecording();
    expect(cubit.state.recording, isFalse);
    expect(cubit.state.hasClip, isFalse);
    expect(voice.cancelled, isTrue);
  });

  test(
    'leaving the recording view drops a latched take, Save stays live',
    () async {
      cubit.setTitle('Bins');
      await cubit.toggleRecording();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(cubit.state.recording, isTrue);
      cubit.showAdvanced(true);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.recording, isFalse);
      expect(cubit.state.canSave, isTrue);
    },
  );

  group('HoldRecorder', () {
    late List<HoldResult> results;
    late HoldRecorder recorder;

    setUp(() {
      voice.onStart = null;
      results = [];
      recorder = HoldRecorder(
        voice,
        Directory.systemTemp.createTempSync('rec').path,
        onTick: (_, _) {},
        onResult: results.add,
        maxLength: const Duration(milliseconds: 1200),
      );
    });

    tearDown(() => recorder.dispose());

    test('cancel drops without a notice and without a clip', () async {
      await recorder.press();
      await recorder.release(); // quick: latched
      await recorder.cancel();
      expect(voice.cancelled, isTrue);
      expect(recorder.recording, isFalse);
      expect(recorder.latched, isFalse);
      final r = results.single as HoldDropped;
      expect(r.notice, isNull);
      expect(r.denied, isFalse);
    });

    test(
      'a second tap while the recorder starts is a stop, not a restart',
      () async {
        voice.startGate = Completer<void>();
        final ticks = <Duration>[];
        final r = HoldRecorder(
          voice,
          Directory.systemTemp.createTempSync('rec').path,
          onTick: (e, _) => ticks.add(e),
          onResult: results.add,
        );
        final first = r.press();
        await r.press(); // returns at once: no second start
        voice.startGate!.complete();
        await first;
        expect(voice.starts, 1);
        expect(r.recording, isFalse);
        expect(ticks, isEmpty);
        expect((results.single as HoldDropped).notice, isNull);
        await r.dispose();
      },
    );

    test('toggle while the recorder starts is a stop too', () async {
      voice.startGate = Completer<void>();
      final first = recorder.toggle();
      await recorder.toggle();
      voice.startGate!.complete();
      await first;
      expect(voice.starts, 1);
      expect(recorder.recording, isFalse);
      expect((results.single as HoldDropped).notice, isNull);
    });

    test('cancel while the recorder starts drops without a notice', () async {
      voice.startGate = Completer<void>();
      final first = recorder.press();
      await recorder.cancel();
      voice.startGate!.complete();
      await first;
      expect(recorder.recording, isFalse);
      expect((results.single as HoldDropped).notice, isNull);
    });

    test('a press after a cancel mid-start starts one fresh take', () async {
      voice.startGate = Completer<void>();
      final first = recorder.press();
      await recorder.cancel();
      await recorder.press(); // re-arms; no second start
      voice.startGate!.complete();
      await first;
      expect(voice.starts, 1);
      expect(recorder.recording, isTrue);
      expect(results, isEmpty);
    });

    test('cancel during the permission prompt still reports denied', () async {
      final gate = Completer<bool>();
      final v = _GatedPermission(gate);
      final r = HoldRecorder(
        v,
        Directory.systemTemp.createTempSync('rec').path,
        onTick: (_, _) {},
        onResult: results.add,
      );
      final first = r.press();
      await pumpEventQueue();
      await r.cancel();
      gate.complete(false);
      await first;
      expect((results.single as HoldDropped).denied, isTrue);
    });

    test('a take that never reached disk is dropped, not kept', () async {
      final dir = Directory.systemTemp.createTempSync('rec');
      final r = HoldRecorder(
        voice,
        '${dir.path}/draft.wav',
        tempPath: '${dir.path}/draft.rec.wav',
        onTick: (_, _) {},
        onResult: results.add,
      );
      await r.toggle();
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      await r.toggle();
      expect(results.single, isA<HoldDropped>());
      await r.dispose();
    });

    test('a recorder that fails on stop still ends the take', () async {
      await recorder.press();
      await recorder.release();
      voice.stopThrows = true;
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      await recorder.toggle();
      expect(recorder.recording, isFalse);
      expect(results.single, isA<HoldDropped>());
    });

    test('a take replaces the clip only when kept', () async {
      final dir = Directory.systemTemp.createTempSync('rec');
      final draft = File('${dir.path}/draft.wav')..writeAsBytesSync([1]);
      voice.onStart = (path) => File(path).writeAsBytesSync([2]);
      final r = HoldRecorder(
        voice,
        draft.path,
        tempPath: '${dir.path}/draft.rec.wav',
        onTick: (_, _) {},
        onResult: results.add,
      );
      await r.toggle();
      await r.cancel();
      expect(draft.readAsBytesSync(), [1]);
      await r.toggle();
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      await r.toggle();
      expect(results.last, isA<HoldKept>());
      expect(draft.readAsBytesSync(), [2]);
      await r.dispose();
    });

    test('the cap ends a latched recording as a kept clip', () async {
      await recorder.press();
      await recorder.release();
      expect(recorder.latched, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 1600));
      expect(results.single, isA<HoldKept>());
      expect(recorder.recording, isFalse);
    });
  });

  test('first use asks for the mic and does not record yet', () async {
    voice.allowed = false;
    await cubit.startRecording();
    expect(voice.asked, isTrue);
    expect(voice.recording, isFalse);
    expect(cubit.state.recording, isFalse);
    expect(cubit.state.notice, contains('Tap the mic'));
  });

  testWidgets('releasing the real mic button stops the recording', (
    tester,
  ) async {
    await setUpDi();
    // Tall enough that the lazily built list includes the Sound row.
    tester.view.physicalSize = const Size(1200, 4000);
    addTearDown(tester.view.resetPhysicalSize);
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
    cubit.showAdvanced(true); // the Sound row lives under More options
    await tester.pumpAndSettle();

    final finger = await tester.startGesture(tester.getCenter(mic));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1100)),
    );
    await tester.pump();
    expect(cubit.state.recording, isTrue);
    expect(mic, findsOneWidget, reason: 'the mic must stay under the finger');

    await finger.up();
    for (var i = 0; i < 50 && cubit.state.recording; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
    }
    await tester.pump();
    expect(cubit.state.recording, isFalse);
    expect(cubit.state.hasClip, isTrue);
  });
}
