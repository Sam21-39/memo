import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/reminders/domain/entities/repeat_rule.dart';
import 'package:memo/features/reminders/domain/usecases/apply_alarm_action.dart';
import 'package:memo/features/reminders/domain/usecases/save_reminder.dart';
import 'package:memo/features/reminders/presentation/alarm/alarm_cubit.dart';
import 'package:memo/features/reminders/presentation/alarm/alarm_page.dart';

import 'fakes.dart';

void main() {
  final due = DateTime(2026, 11, 4, 20);

  group('AlarmCubit', () {
    late InMemoryRepository repo;
    late List<String> played;
    late int stops;

    AlarmCubit build({bool ringing = false}) => AlarmCubit(
      'p',
      repo,
      SaveReminder(repo, FakeScheduler()),
      ringingNatively: (_) async => ringing,
      stopRinging: () async => stops++,
      play: (id) async => played.add(id),
      stop: () async {},
      speak: (r) async => played.add('say:${r.id}'),
    );

    setUp(() {
      repo = InMemoryRepository([
        reminder('p', 'Pills', due).copyWith(hasVoice: true, readAloud: true),
      ]);
      played = [];
      stops = 0;
    });

    test('reads it aloud once when nothing native is sounding', () async {
      await build().load();
      expect(played, ['say:p']);
    });

    test('does not talk over a native alarm already sounding', () async {
      await build(ringing: true).load();
      expect(played, isEmpty);
    });

    test('Done stops the ring and completes the reminder', () async {
      final cubit = build();
      await cubit.load();
      await cubit.done();
      expect(stops, 1);
      expect(cubit.state.outcome, AlarmOutcome.done);
      expect(repo.all.single.isDone, isTrue);
    });

    test('a snooze preset re-times it from now', () async {
      final cubit = build();
      await cubit.load();
      final before = DateTime.now();
      await cubit.snooze(before.add(const Duration(hours: 1)));
      expect(cubit.state.outcome, AlarmOutcome.snoozed);
      expect(
        repo.all.single.dueAt.difference(before).inMinutes,
        inInclusiveRange(59, 61),
      );
    });

    test('Done twice saves once', () async {
      final cubit = build();
      await cubit.load();
      await Future.wait([cubit.done(), cubit.done()]);
      await cubit.done();
      expect(stops, 1);
    });

    test('finishing after close does not throw', () async {
      final cubit = build();
      await cubit.load();
      final f = cubit.done();
      await cubit.close();
      await f;
    });

    test('a failed save can be retried', () async {
      final cubit = build();
      await cubit.load();
      repo.failSave = true;
      await expectLater(cubit.done(), throwsStateError);
      repo.failSave = false;
      await cubit.done();
      expect(cubit.state.outcome, AlarmOutcome.done);
    });

    test('a missing reminder says so', () async {
      repo = InMemoryRepository();
      final cubit = build();
      await cubit.load();
      expect(cubit.state.outcome, AlarmOutcome.missing);
    });
  });

  group('AlarmPage', () {
    late InMemoryRepository repo;

    Future<void> pump(
      WidgetTester tester, {
      bool readAloud = false,
      Duration offset = const Duration(hours: 2),
      double scale = 1,
    }) async {
      repo = InMemoryRepository([
        reminder(
          'p',
          'Pills',
          DateTime.now().add(offset),
        ).copyWith(readAloud: readAloud),
      ]);
      await tester.pumpWidget(
        themed(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 690),
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: BlocProvider(
              create: (_) => AlarmCubit(
                'p',
                repo,
                SaveReminder(repo, FakeScheduler()),
                ringingNatively: (_) async => true,
                stopRinging: () async {},
                play: (_) async {},
                stop: () async {},
                speak: (_) async {},
              )..load(),
              child: AlarmPage(voicePath: (id) => id, onClose: () {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a late reminder does not overflow at 2.0x on 320 px', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 690);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pump(tester, offset: const Duration(days: -3), scale: 2);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Done and Snooze are labelled buttons at least 64 high', (
      tester,
    ) async {
      await pump(tester);
      for (final label in ['Done', 'Snooze']) {
        final button = find.ancestor(
          of: find.text(label),
          matching: find.bySubtype<ButtonStyleButton>(),
        );
        expect(button, findsOneWidget, reason: label);
        expect(tester.getSize(button).height, greaterThanOrEqualTo(64));
      }
    });

    testWidgets('the spoken-reminder status shows when it reads aloud', (
      tester,
    ) async {
      await pump(tester, readAloud: true);
      expect(find.text('Reading aloud in English'), findsOneWidget);
    });

    testWidgets('no spoken-reminder status when it does not', (tester) async {
      await pump(tester);
      expect(find.text('Reading aloud in English'), findsNothing);
    });

    testWidgets('Snooze offers three timed options; 1 hour re-rings in 1 h', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.text('Snooze'));
      await tester.pumpAndSettle();
      for (final label in [
        'Snooze 10 minutes',
        'Snooze 1 hour',
        'Tomorrow, same time',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      final before = DateTime.now();
      await tester.tap(find.text('Snooze 1 hour'));
      await tester.pumpAndSettle();
      final ringsAt = repo.all.single.ringsAt;
      expect(
        ringsAt.difference(before.add(const Duration(hours: 1))).abs(),
        lessThan(const Duration(minutes: 1)),
      );
    });
  });

  group('ApplyAlarmAction', () {
    test('a queued snooze counts from when it was tapped', () async {
      final repo = InMemoryRepository([reminder('p', 'Pills', due)]);
      final tappedAt = DateTime(2026, 11, 4, 20, 2);
      await ApplyAlarmAction(repo, SaveReminder(repo, FakeScheduler()))(
        'p',
        AlarmAction.snooze,
        tappedAt,
      );
      expect(repo.all.single.dueAt, DateTime(2026, 11, 4, 20, 12));
    });

    test('Done on a repeat moves it to the next occurrence', () async {
      final repo = InMemoryRepository([
        reminder('p', 'Pills', due, repeat: RepeatRule.daily),
      ]);
      await ApplyAlarmAction(repo, SaveReminder(repo, FakeScheduler()))(
        'p',
        AlarmAction.done,
        due,
      );
      expect(repo.all.single.dueAt, DateTime(2026, 11, 5, 20));
      expect(repo.all.single.isDone, isFalse);
    });

    test('a reminder deleted meanwhile is ignored', () async {
      final repo = InMemoryRepository();
      await ApplyAlarmAction(repo, SaveReminder(repo, FakeScheduler()))(
        'gone',
        AlarmAction.done,
        due,
      );
      expect(repo.all, isEmpty);
    });
  });
}
