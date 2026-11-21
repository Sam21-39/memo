import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/di.dart';
import 'package:memo/core/theme/memo_theme.dart';
import 'package:memo/l10n/l10n.dart';
import 'package:memo/features/reminders/domain/entities/occurrence.dart';
import 'package:memo/features/reminders/domain/entities/reminder.dart';
import 'package:memo/features/reminders/domain/entities/repeat_rule.dart';
import 'package:memo/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:memo/features/reminders/domain/usecases/delete_reminder.dart';
import 'package:memo/features/reminders/domain/usecases/save_reminder.dart';
import 'package:memo/features/reminders/presentation/home/capture_cubit.dart';
import 'package:memo/features/reminders/presentation/home/home_cubit.dart';
import 'package:memo/features/reminders/presentation/home/home_page.dart';
import 'package:memo/features/reminders/presentation/widgets/check_control.dart';
import 'package:memo/features/reminders/presentation/widgets/key_value_row.dart';
import 'package:memo/features/reminders/presentation/widgets/reminder_row.dart';
import 'package:memo/features/reminders/presentation/widgets/swipeable_reminder_row.dart';
import 'package:memo/features/tags/presentation/widgets/tag_chip.dart';

import 'fakes.dart';

/// Fails the first read, then behaves — so "Try again" has something to
/// recover to.
class _FailingRepository extends InMemoryRepository {
  _FailingRepository(super.reminders);
  bool _failed = false;

  @override
  Future<List<Reminder>> getAll() {
    if (_failed) return super.getAll();
    _failed = true;
    throw Exception('database unavailable');
  }
}

Future<void> _pump(WidgetTester tester, [ReminderRepository? repo]) async {
  await tester.pumpWidget(
    themed(
      MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => HomeCubit(
              repo ?? sl<ReminderRepository>(),
              sl<SaveReminder>(),
              sl<DeleteReminder>(),
            )..load(),
          ),
          BlocProvider(
            create: (_) => CaptureCubit(
              sl<SaveReminder>(),
              media: null,
              voice: null,
              stt: null,
              knownTags: () => const ['Health'],
              clock: () => DateTime(2026, 11, 4, 12),
            ),
          ),
        ],
        child: const HomePage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Counts saves; [gate] holds each one until completed.
class _SlowRepository extends InMemoryRepository {
  _SlowRepository(super.reminders);
  int saves = 0;
  Completer<void>? gate;

  @override
  Future<void> save(
    Reminder reminder, {
    List<Occurrence> log = const [],
  }) async {
    saves++;
    await gate?.future;
    return super.save(reminder, log: log);
  }
}

/// [setUpDi] with [repo] as the repository the use cases write to.
Future<void> _useRepo(_SlowRepository repo) async {
  await setUpDi();
  sl
    ..unregister<ReminderRepository>()
    ..unregister<SaveReminder>()
    ..registerSingleton<ReminderRepository>(repo)
    ..registerSingleton(SaveReminder(repo, FakeScheduler()));
}

double _shown(WidgetTester tester) => tester
    .widget<SizeTransition>(
      find
          .ancestor(
            of: find.byType(SwipeableReminderRow),
            matching: find.byType(SizeTransition),
          )
          .first,
    )
    .sizeFactor
    .value;

/// The title in its list row, not in the header's Next line.
Finder _inRow(String title) =>
    find.descendant(of: find.byType(ReminderRow), matching: find.text(title));

void main() {
  final now = DateTime.now();
  DateTime inDays(int d, int hour) =>
      DateTime(now.year, now.month, now.day + d, hour);

  testWidgets('empty state invites the first reminder', (tester) async {
    await setUpDi();
    await _pump(tester);
    expect(find.text('Nothing scheduled'), findsOneWidget);
    expect(find.text('Remind me to…'), findsOneWidget);
  });

  testWidgets('groups reminders under day headers', (tester) async {
    await setUpDi([
      reminder('1', 'Pills', inDays(1, 20), tag: 'Health'),
      reminder('2', 'Dentist', inDays(3, 9)),
    ]);
    await _pump(tester);
    expect(find.text('TOMORROW'), findsOneWidget);
    expect(_inRow('Pills'), findsOneWidget);
    expect(find.text('Health'), findsWidgets);
    expect(find.text('2 SCHEDULED'), findsOneWidget);
  });

  testWidgets('an overdue reminder gets its own accent section', (
    tester,
  ) async {
    await setUpDi([
      reminder('1', 'Bins', now.subtract(const Duration(hours: 2, minutes: 5))),
    ]);
    await _pump(tester);
    expect(find.text('OVERDUE'), findsOneWidget);
    expect(find.text('2 h late'), findsOneWidget);
    expect(find.text('1 SCHEDULED · 1 OVERDUE'), findsOneWidget);
  });

  testWidgets('a failed load says so instead of showing an empty list', (
    tester,
  ) async {
    await setUpDi();
    await _pump(
      tester,
      _FailingRepository([reminder('1', 'Pills', inDays(1, 8))]),
    );
    expect(find.text("Couldn't load your reminders"), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(_inRow('Pills'), findsOneWidget);
  });

  testWidgets('completing a one-off offers Undo, which restores it', (
    tester,
  ) async {
    final (repo, _) = await setUpDi([
      reminder('1', 'Call the dentist', inDays(1, 9)),
    ]);
    await _pump(tester);
    await tester.tap(find.byType(CheckControl));
    await tester.pumpAndSettle(); // the row folds away, then the write
    expect(find.text('Call the dentist done'), findsOneWidget);
    expect(repo.all.single.isDone, isTrue);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(repo.all.single.isDone, isFalse);
    expect(find.text('Undo'), findsNothing);
  });

  testWidgets('a completed row stays folded while a slow write lands', (
    tester,
  ) async {
    final repo = _SlowRepository([reminder('1', 'Pills', inDays(1, 9))])
      ..gate = Completer();
    await _useRepo(repo);
    await _pump(tester, repo);
    await tester.tap(find.byType(CheckControl));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(_shown(tester), 0);
    await tester.pump(const Duration(seconds: 1));
    expect(_shown(tester), 0); // still waiting on the write: no flash back
    repo.gate!.complete();
    await tester.pumpAndSettle();
    expect(repo.all.single.isDone, isTrue);
    expect(_inRow('Pills'), findsNothing);
  });

  testWidgets('a failed complete brings the row back', (tester) async {
    final (repo, _) = await setUpDi([reminder('1', 'Pills', inDays(1, 9))]);
    repo.failSave = true;
    await _pump(tester);
    await tester.tap(find.byType(CheckControl));
    await tester.pumpAndSettle();
    expect(_shown(tester), 1);
    expect(_inRow('Pills'), findsOneWidget);
  });

  testWidgets('the row is disposed mid-fold: the complete still happens once', (
    tester,
  ) async {
    final repo = _SlowRepository([
      reminder('1', 'Pills', inDays(1, 9), tag: 'Health'),
      reminder('2', 'Bins', inDays(1, 10), tag: 'Home'),
    ]);
    await _useRepo(repo);
    await _pump(tester, repo);
    await tester.tap(find.byType(CheckControl).first);
    await tester.tap(find.byType(CheckControl).first); // double tap mid-fold
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.widgetWithText(TagChip, 'Home'));
    await tester.pumpAndSettle();
    expect(_inRow('Pills'), findsNothing);
    expect(repo.saves, 1);
    expect(repo.all.firstWhere((r) => r.id == '1').isDone, isTrue);
  });

  testWidgets('the Undo toast leaves after 5 s', (tester) async {
    await setUpDi([reminder('1', 'Call the dentist', inDays(1, 9))]);
    await _pump(tester);
    await tester.tap(find.byType(CheckControl));
    await tester.pumpAndSettle();
    await tester.pump(HomeCubit.undoWindow);
    await tester.pumpAndSettle();
    expect(find.text('Undo'), findsNothing);
  });

  testWidgets('completing a repeat moves it forward with no toast', (
    tester,
  ) async {
    final (repo, _) = await setUpDi([
      reminder('1', 'Pills', inDays(0, 23), repeat: RepeatRule.daily),
    ]);
    await _pump(tester);
    await tester.tap(find.byType(CheckControl));
    await tester.pumpAndSettle();
    expect(find.text('Undo'), findsNothing);
    expect(repo.all.single.dueAt, inDays(1, 23));
  });

  testWidgets('the Next line names the soonest reminder and how far off', (
    tester,
  ) async {
    await setUpDi([
      reminder('1', 'Dentist', inDays(3, 9)),
      reminder('2', 'Pills', now.add(const Duration(hours: 3, minutes: 5))),
    ]);
    await _pump(tester);
    final next = find.ancestor(
      of: find.text('Next'),
      matching: find.byType(Wrap),
    );
    expect(
      find.descendant(of: next, matching: find.text('Pills')),
      findsOneWidget,
    );
    expect(find.textContaining('in 3 h'), findsOneWidget);
  });

  testWidgets('long-press opens every row action without a swipe', (
    tester,
  ) async {
    final (repo, _) = await setUpDi([reminder('1', 'Pills', inDays(1, 20))]);
    await _pump(tester);
    await tester.longPress(_inRow('Pills'));
    await tester.pumpAndSettle();
    for (final label in ['Mark done', 'Snooze 10 minutes', 'Edit', 'Delete']) {
      expect(find.widgetWithText(KeyValueRow, label), findsOneWidget);
    }
    await tester.tap(find.text('Mark done'));
    await tester.pumpAndSettle();
    expect(repo.all.single.isDone, isTrue);
  });

  testWidgets('the row menu can delete and snooze', (tester) async {
    final (repo, _) = await setUpDi([reminder('1', 'Pills', inDays(1, 20))]);
    await _pump(tester);
    await tester.longPress(_inRow('Pills'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Snooze 10 minutes'));
    await tester.pumpAndSettle();
    // A one-off snooze moves its time to about ten minutes from now.
    expect(
      repo.all.single.dueAt.difference(DateTime.now()).inMinutes,
      inInclusiveRange(8, 10),
    );

    await tester.longPress(_inRow('Pills'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(KeyValueRow, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Pills deleted'), findsOneWidget);
  });

  testWidgets('swiping left reveals snooze and delete as full words', (
    tester,
  ) async {
    await setUpDi([reminder('1', 'Pills', inDays(1, 20))]);
    await _pump(tester);
    await tester.drag(_inRow('Pills'), const Offset(-200, 0));
    await tester.pumpAndSettle();
    expect(find.text('Snooze\n10 min'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('swipe delete hides the row, Undo restores it', (tester) async {
    final (repo, _) = await setUpDi([reminder('1', 'Pills', inDays(1, 20))]);
    await _pump(tester);
    await tester.drag(_inRow('Pills'), const Offset(-200, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(_inRow('Pills'), findsNothing);
    expect(find.text('Pills deleted'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(_inRow('Pills'), findsOneWidget);
    expect(repo.all.single.id, '1');
  });

  testWidgets('swipe delete is final once the Undo window ends', (
    tester,
  ) async {
    final (repo, _) = await setUpDi([reminder('1', 'Pills', inDays(1, 20))]);
    await _pump(tester);
    await tester.drag(_inRow('Pills'), const Offset(-200, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.pump(HomeCubit.undoWindow);
    await tester.pumpAndSettle();
    expect(repo.all, isEmpty);
    expect(find.text('Pills deleted'), findsNothing);
  });

  testWidgets(
    'typing in the bar shows parsed chips, Continue then Save writes it',
    (tester) async {
      final (repo, scheduler) = await setUpDi();
      await _pump(tester);
      await tester.enterText(
        find.byType(TextField),
        'Pills at 8 tonight every day',
      );
      await tester.pumpAndSettle();
      expect(find.text('8:00 PM'), findsOneWidget);
      expect(find.text('Repeat: Daily'), findsOneWidget);
      expect(find.text('OVERDUE'), findsNothing);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(
        find.text('You wrote: “Pills at 8 tonight every day”'),
        findsOneWidget,
      );
      await tester.tap(find.text('Save reminder'));
      await tester.pumpAndSettle();
      expect(repo.all.single.title, 'Pills');
      expect(repo.all.single.dueAt, DateTime(2026, 11, 4, 20));
      expect(repo.all.single.repeat.repeats, isTrue);
      expect(scheduler.scheduled.single.title, 'Pills');
      expect(find.text('Save reminder'), findsNothing); // back to idle
    },
  );

  testWidgets('an overdue row is opaque in dark mode, hiding its actions', (
    tester,
  ) async {
    await setUpDi([
      reminder('1', 'Bins', DateTime.now().subtract(const Duration(hours: 2))),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        theme: MemoTheme.dark,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
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
                media: null,
                voice: null,
                stt: null,
                knownTags: () => const [],
              ),
            ),
          ],
          child: const HomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final row = find.ancestor(
      of: find.text('Bins'),
      matching: find.byType(ColoredBox),
    );
    final colors = tester.widgetList<ColoredBox>(row).map((b) => b.color);
    expect(colors.any((c) => c.a == 1.0), isTrue);
    expect(colors.where((c) => c.a > 0 && c.a < 1.0), isEmpty);
  });
}
