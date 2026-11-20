import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/di.dart';
import 'package:memo/features/reminders/data/media_store.dart';
import 'package:memo/features/reminders/data/speech_to_text.dart';
import 'package:memo/features/reminders/data/voice_clip.dart';
import 'package:memo/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:memo/features/reminders/domain/usecases/delete_reminder.dart';
import 'package:memo/features/reminders/domain/usecases/save_reminder.dart';
import 'package:memo/features/reminders/presentation/home/capture_cubit.dart';
import 'package:memo/features/reminders/presentation/home/home_cubit.dart';
import 'package:memo/features/reminders/presentation/home/home_page.dart';

import 'fakes.dart';

class _Voice implements VoiceClip {
  @override
  Future<bool> hasPermission({bool request = false}) async => true;
  @override
  Future<double> level() async => 0.5;
  @override
  Future<void> start(String path) async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> cancel() async {}
  @override
  Future<void> play(String path) async {}
  @override
  Future<void> stopPlaying() async {}
}

class _EmptyStt implements SpeechToText {
  @override
  Future<bool> available() async => true;
  @override
  Future<String> transcribeFile(String path) async => '';
}

Future<void> _pump(WidgetTester tester, {DateTime Function()? clock}) async {
  final media = MediaStore(Directory.systemTemp.createTempSync('flow'));
  await tester.pumpWidget(
    themed(
      MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => HomeCubit(
              sl<ReminderRepository>(),
              sl<SaveReminder>(),
              sl<DeleteReminder>(),
            )..load(),
          ),
          BlocProvider(
            create: (_) => CaptureCubit(
              sl<SaveReminder>(),
              media: media,
              voice: _Voice(),
              stt: _EmptyStt(),
              knownTags: () => const [],
              clock: clock,
            ),
          ),
        ],
        child: const HomePage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

bool _enabled(WidgetTester tester, String label) =>
    tester
        .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, label))
        .onPressed !=
    null;

final _confirmTime = find.textContaining(
  RegExp('confirm time', caseSensitive: false),
);
final _mic = find.byIcon(Icons.mic_none_rounded);

void main() {
  testWidgets('an unsure time blocks Save until one is picked', (tester) async {
    final (repo, scheduler) = await setUpDi();
    // Noon today, fixed: "tomorrow" must not move with the wall clock.
    final t = DateTime.now();
    final noon = DateTime(t.year, t.month, t.day, 12);
    await _pump(tester, clock: () => noon);
    await tester.enterText(find.byType(TextField), 'Call mum tomorrow at 8');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('You wrote: “Call mum tomorrow at 8”'), findsOneWidget);
    expect(_confirmTime, findsOneWidget);
    expect(_enabled(tester, 'Save reminder'), isFalse);

    await tester.tap(find.text('8:00 PM'));
    await tester.pumpAndSettle();
    expect(_confirmTime, findsNothing);
    expect(_enabled(tester, 'Save reminder'), isTrue);

    await tester.tap(find.text('Save reminder'));
    await tester.pumpAndSettle();
    final expected = DateTime(noon.year, noon.month, noon.day + 1, 20);
    expect(scheduler.scheduled.single.dueAt, expected);
    expect(repo.all.single.title, 'Call mum');
    expect(find.text('Reminder set for tomorrow at 8:00 PM.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    expect(find.textContaining('Reminder set for'), findsNothing);
  });

  testWidgets('a stated time saves in two taps', (tester) async {
    final (repo, _) = await setUpDi();
    await _pump(tester);
    await tester.enterText(find.byType(TextField), 'Call mum tomorrow at 8 AM');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(_confirmTime, findsNothing);
    expect(_enabled(tester, 'Save reminder'), isTrue);
    await tester.tap(find.text('Save reminder'));
    await tester.pumpAndSettle();
    expect(repo.all.single.dueAt.hour, 8);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('tap the mic: Recording and Stop, same mic element', (
    tester,
  ) async {
    await setUpDi();
    await _pump(tester);
    final before = tester.element(_mic);

    await tester.tap(_mic); // down and up inside 300 ms: latches
    await tester.pump();
    await tester.pump();

    expect(find.text('Recording'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);
    expect(identical(tester.element(_mic), before), isTrue);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Recording'), findsNothing);
    expect(identical(tester.element(_mic), before), isTrue);
  });

  testWidgets('the mic keeps its element from typing through recording', (
    tester,
  ) async {
    await setUpDi();
    await _pump(tester);
    final before = tester.element(_mic);
    await tester.enterText(find.byType(TextField), 'Bins');
    await tester.pumpAndSettle();
    expect(identical(tester.element(_mic), before), isTrue);
    await tester.tap(_mic);
    await tester.pump();
    await tester.pump();
    expect(find.text('Recording'), findsOneWidget);
    expect(identical(tester.element(_mic), before), isTrue);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('hold still works: the panel opens over the mic, release stops', (
    tester,
  ) async {
    await setUpDi();
    await _pump(tester);
    final before = tester.element(_mic);
    final finger = await tester.startGesture(tester.getCenter(_mic));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1100)),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Recording'), findsOneWidget);
    expect(identical(tester.element(_mic), before), isTrue);

    await finger.up(); // lands on the mic, not the panel above it
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.text('Recording'), findsNothing);
    expect(find.text('Type it instead'), findsOneWidget);
  });

  testWidgets('an empty transcript offers the three ways out', (tester) async {
    await setUpDi();
    await _pump(tester);
    await tester.tap(_mic);
    await tester.pump();
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1100)),
    );
    await tester.tap(find.text('Stop'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    expect(find.text('Couldn’t turn that into text'), findsOneWidget);
    expect(find.text('Type it instead'), findsOneWidget);
    expect(find.text('Save as voice note, pick a time'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    await tester.tap(find.text('Save as voice note, pick a time'));
    await tester.pumpAndSettle();
    expect(_confirmTime, findsOneWidget);
    expect(find.text('Voice note · 0:00'), findsOneWidget);
    expect(_enabled(tester, 'Save reminder'), isFalse);
  });

  testWidgets('the mic exposes a tap action to screen readers', (tester) async {
    await setUpDi();
    await _pump(tester);
    final handle = tester.ensureSemantics();
    final node = tester.getSemantics(
      find.bySemanticsLabel('Record a reminder'),
    );
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    handle.dispose();
  });

  testWidgets('Edit details waits for a picked time', (tester) async {
    await setUpDi();
    await _pump(tester);
    await tester.enterText(find.byType(TextField), 'Call mum tomorrow at 8');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    OutlinedButton edit() => tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Edit details'),
    );
    expect(edit().onPressed, isNull);
    await tester.tap(find.text('8:00 PM'));
    await tester.pumpAndSettle();
    expect(edit().onPressed, isNotNull);
  });

  testWidgets('backgrounding stops a latched recording', (tester) async {
    await setUpDi();
    await _pump(tester);
    await tester.tap(_mic);
    await tester.pump();
    await tester.pump();
    expect(find.text('Recording'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    // Frames are off while paused: resume to draw the result.
    for (final s in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(s);
    }
    await tester.pumpAndSettle();
    expect(find.text('Recording'), findsNothing);
  });
}
