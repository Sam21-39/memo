import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:memo/core/di.dart';
import 'package:memo/core/theme/memo_theme.dart';
import 'package:memo/l10n/l10n.dart';
import 'package:memo/features/reminders/data/media_store.dart';
import 'package:memo/features/reminders/data/share_inbox.dart';
import 'package:memo/features/reminders/data/speech_to_text.dart';
import 'package:memo/features/reminders/data/voice_clip.dart';
import 'package:memo/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:memo/features/reminders/domain/usecases/delete_reminder.dart';
import 'package:memo/features/reminders/domain/usecases/save_reminder.dart';
import 'package:memo/features/reminders/presentation/home/capture_cubit.dart';
import 'package:memo/features/reminders/presentation/home/home_cubit.dart';
import 'package:memo/features/reminders/presentation/home/home_page.dart';
import 'package:memo/features/reminders/presentation/home/reminder_confirmation.dart';

import 'fakes.dart';

class _Voice implements VoiceClip {
  @override
  Future<bool> hasPermission({bool request = false}) async => true;
  @override
  Future<double> level() async => 0.5;
  @override
  Future<void> start(String path) async => File(path).writeAsBytesSync([1]);
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
  Future<bool> available(String tag) async => true;
  @override
  Future<String> availability(String tag) async => 'installed';
  @override
  Future<String> transcribeFile(String path, String tag) async => '';
}

Future<void> _pump(
  WidgetTester tester, {
  DateTime Function()? clock,
  FakeShares? shares,
}) async {
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
              shares: shares,
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

/// Real file I/O backs the stop: wait in short real hops, bounded, until the
/// recording panel is gone.
Future<void> _untilNotRecording(WidgetTester tester) async {
  for (var i = 0; i < 50; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
    if (find.text('Recording').evaluate().isEmpty) break;
  }
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
  testWidgets('shared text opens the confirmation; Save is the only way in', (
    tester,
  ) async {
    final (repo, _) = await setUpDi();
    final shares = FakeShares(['Dentist Friday 3pm', 'Call the bank']);
    await _pump(tester, shares: shares);
    expect(find.text('SHARED TO MEMŌ'), findsOneWidget);
    expect(find.text('Dentist Friday 3pm'), findsOneWidget);
    expect(
      find.text('Only what you share. Memō never reads your mail.'),
      findsOneWidget,
    );
    expect(shares.acked, ['s0']);
    expect(repo.all, isEmpty);
    expect(_enabled(tester, 'Save reminder'), isTrue);

    await tester.tap(find.text('Save reminder'));
    await tester.pumpAndSettle();
    expect(repo.all, hasLength(1));
    // The next one follows, with no clear time: Save stays off.
    expect(find.text('Call the bank'), findsWidgets);
    expect(_enabled(tester, 'Save reminder'), isFalse);
    expect(_confirmTime, findsWidgets);
    expect(repo.all, hasLength(1));
  });

  testWidgets('a share waits behind an open edit sheet, then shows on Home', (
    tester,
  ) async {
    await setUpDi();
    final shares = FakeShares([]);
    final media = MediaStore(Directory.systemTemp.createTempSync('flow'));
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const HomePage()),
        GoRoute(
          path: '/reminder/:id',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => const Text('EDIT SHEET'),
              ),
              child: const Text('edit'),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
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
              shares: shares,
            ),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          theme: MemoTheme.light.copyWith(platform: TargetPlatform.android),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    unawaited(router.push('/reminder/1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('edit'));
    await tester.pumpAndSettle();
    expect(find.text('EDIT SHEET'), findsOneWidget);

    // Share arrives, app resumes: nothing is pulled while the page is open.
    shares.queue.add(const SharedText('x', 'Pay rent Friday 9am'));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('EDIT SHEET'), findsOneWidget);
    expect(shares.acked, isEmpty);

    // Back to Home: the share shows, then is acked.
    Navigator.of(tester.element(find.text('EDIT SHEET'))).pop();
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('SHARED TO MEMŌ'), findsOneWidget);
    expect(find.text('Pay rent Friday 9am'), findsOneWidget);
    expect(shares.acked, ['x']);
  });

  testWidgets('a share waits while the bar is in use', (tester) async {
    await setUpDi();
    final shares = FakeShares([]);
    await _pump(tester, shares: shares);
    await tester.enterText(find.byType(TextField), 'half a thought');
    await tester.pumpAndSettle();
    shares.queue.add(const SharedText('late', 'Pay rent Friday 9am'));
    final cubit = tester.element(find.byType(TextField)).read<CaptureCubit>();
    expect(await cubit.pullShare(), isFalse);
    expect(find.text('SHARED TO MEMŌ'), findsNothing);
    await cubit.discard();
    await tester.pumpAndSettle();
    expect(find.text('SHARED TO MEMŌ'), findsOneWidget);
    expect(shares.acked, ['late']);
  });

  testWidgets('quick start: chips, prefill, parse, gone once typed', (
    tester,
  ) async {
    await setUpDi();
    await _pump(tester);
    expect(find.text('QUICK START'), findsOneWidget);
    for (final t in [
      'Take medicine',
      'Pay a bill',
      'Call someone',
      'Follow up',
      'Weekly routine',
    ]) {
      expect(find.text(t), findsOneWidget);
    }

    await tester.tap(find.text('Take medicine'));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'Take medicine ');
    expect(field.controller!.selection.baseOffset, 14);
    expect(field.focusNode!.hasFocus, isTrue);
    expect(find.text('QUICK START'), findsNothing);
    expect(find.text('Weekly routine'), findsNothing);
    final cubit = tester.element(find.byType(TextField)).read<CaptureCubit>();
    expect(cubit.state.phase, CapturePhase.typing);

    await tester.enterText(find.byType(TextField), 'Take medicine 8pm');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('You wrote: “Take medicine 8pm”'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ReminderConfirmation),
        matching: find.text('Take medicine'),
      ),
      findsOneWidget,
    );
    await cubit.discard();
    await tester.pumpAndSettle();
    expect(find.text('QUICK START'), findsOneWidget);
  });

  testWidgets('quick start: Weekly routine prefills today\'s weekday', (
    tester,
  ) async {
    await setUpDi();
    await _pump(tester);
    await tester.ensureVisible(find.text('Weekly routine'));
    await tester.tap(find.text('Weekly routine'));
    await tester.pumpAndSettle();
    final day = DateFormat.EEEE('en').format(DateTime.now());
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Every $day ',
    );
  });

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
    await tester.pumpAndSettle();
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
    await _untilNotRecording(tester);
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
    await _untilNotRecording(tester);
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
