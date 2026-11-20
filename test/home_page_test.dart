import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/di.dart';
import 'package:memo/core/theme/memo_theme.dart';
import 'package:memo/l10n/l10n.dart';
import 'package:memo/features/reminders/domain/entities/reminder.dart';
import 'package:memo/features/reminders/domain/entities/repeat_rule.dart';
import 'package:memo/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:memo/features/reminders/domain/usecases/delete_reminder.dart';
import 'package:memo/features/reminders/domain/usecases/save_reminder.dart';
import 'package:memo/features/reminders/presentation/home/capture_cubit.dart';
import 'package:memo/features/reminders/presentation/home/home_cubit.dart';
import 'package:memo/features/reminders/presentation/home/home_page.dart';
import 'package:memo/features/reminders/presentation/widgets/check_control.dart';

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
    expect(find.text('Pills'), findsOneWidget);
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
    expect(find.text('Pills'), findsOneWidget);
  });

  testWidgets('completing a one-off offers Undo, which restores it', (
    tester,
  ) async {
    final (repo, _) = await setUpDi([
      reminder('1', 'Call the dentist', inDays(1, 9)),
    ]);
    await _pump(tester);
    await tester.tap(find.byType(CheckControl));
    await tester.pump();
    expect(find.text('Call the dentist done'), findsOneWidget);
    expect(repo.all.single.isDone, isTrue);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(repo.all.single.isDone, isFalse);
    expect(find.text('Undo'), findsNothing);
  });

  testWidgets('the Undo toast leaves after 5 s', (tester) async {
    await setUpDi([reminder('1', 'Call the dentist', inDays(1, 9))]);
    await _pump(tester);
    await tester.tap(find.byType(CheckControl));
    await tester.pump();
    await tester.pump(HomeCubit.undoWindow);
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

  testWidgets('swiping left reveals snooze and delete as words', (
    tester,
  ) async {
    await setUpDi([reminder('1', 'Pills', inDays(1, 20))]);
    await _pump(tester);
    await tester.drag(find.text('Pills'), const Offset(-200, 0));
    await tester.pumpAndSettle();
    expect(find.text('10m'), findsOneWidget);
    expect(find.text('Del'), findsOneWidget);
  });

  testWidgets('swipe delete hides the row, Undo restores it', (tester) async {
    final (repo, _) = await setUpDi([reminder('1', 'Pills', inDays(1, 20))]);
    await _pump(tester);
    await tester.drag(find.text('Pills'), const Offset(-200, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Del'));
    await tester.pumpAndSettle();
    expect(find.text('Pills'), findsNothing);
    expect(find.text('Pills deleted'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Pills'), findsOneWidget);
    expect(repo.all.single.id, '1');
  });

  testWidgets('swipe delete is final once the Undo window ends', (
    tester,
  ) async {
    final (repo, _) = await setUpDi([reminder('1', 'Pills', inDays(1, 20))]);
    await _pump(tester);
    await tester.drag(find.text('Pills'), const Offset(-200, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Del'));
    await tester.pump(HomeCubit.undoWindow);
    await tester.pumpAndSettle();
    expect(repo.all, isEmpty);
    expect(find.text('Pills deleted'), findsNothing);
  });

  testWidgets('typing in the bar shows parsed chips, Save writes it', (
    tester,
  ) async {
    final (repo, scheduler) = await setUpDi();
    await _pump(tester);
    await tester.enterText(
      find.byType(TextField),
      'Pills at 8 tonight every day',
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('8:00 PM'), findsOneWidget);
    expect(find.text('Daily'), findsOneWidget);
    expect(find.text('OVERDUE'), findsNothing);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repo.all.single.title, 'Pills');
    expect(repo.all.single.dueAt, DateTime(2026, 11, 4, 20));
    expect(repo.all.single.repeat.repeats, isTrue);
    expect(scheduler.scheduled.single.title, 'Pills');
    expect(find.text('Save'), findsNothing); // back to idle
  });

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
