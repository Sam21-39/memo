import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/di.dart';
import 'package:memo/features/reminders/domain/entities/repeat_rule.dart';
import 'package:memo/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:memo/features/reminders/domain/usecases/delete_reminder.dart';
import 'package:memo/features/reminders/domain/usecases/save_reminder.dart';
import 'package:memo/features/reminders/presentation/detail/detail_cubit.dart';
import 'package:memo/features/reminders/presentation/detail/detail_page.dart';

import 'fakes.dart';

Future<void> _pump(WidgetTester tester, String id) async {
  await tester.pumpWidget(
    themed(
      BlocProvider(
        create: (_) => DetailCubit(
          id,
          sl<ReminderRepository>(),
          sl<SaveReminder>(),
          sl<DeleteReminder>(),
        )..load(),
        child: const DetailPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final due = DateTime.now().add(const Duration(days: 2));

  testWidgets('Snooze opens the sheet with all three options', (tester) async {
    await setUpDi([reminder('1', 'Pills', due)]);
    await _pump(tester, '1');
    await tester.tap(find.text('Snooze'));
    await tester.pumpAndSettle();
    for (final label in [
      'Snooze 10 minutes',
      'Snooze 1 hour',
      'Tomorrow, same time',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('a duration option offsets from now', (tester) async {
    final (repo, _) = await setUpDi([reminder('1', 'Pills', due)]);
    await _pump(tester, '1');
    await tester.tap(find.text('Snooze'));
    await tester.pumpAndSettle();
    final before = DateTime.now();
    await tester.tap(find.text('Snooze 1 hour'));
    await tester.pumpAndSettle();
    final moved = repo.all.single.dueAt.difference(before);
    expect(moved.inMinutes, inInclusiveRange(59, 61));
  });

  testWidgets('Tomorrow keeps the reminder own time of day', (tester) async {
    final (repo, _) = await setUpDi([reminder('1', 'Pills', due)]);
    await _pump(tester, '1');
    await tester.tap(find.text('Snooze'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tomorrow, same time'));
    await tester.pumpAndSettle();
    final at = repo.all.single.dueAt;
    expect([at.hour, at.minute], [due.hour, due.minute]);
  });

  testWidgets('an overdue repeat says Mark done for today and where it moves', (
    tester,
  ) async {
    final late = DateTime.now().subtract(const Duration(minutes: 5));
    await setUpDi([reminder('1', 'Pills', late, repeat: RepeatRule.daily)]);
    await _pump(tester, '1');
    expect(find.text('Mark done for today'), findsOneWidget);
    expect(find.textContaining('Marking done moves it to'), findsOneWidget);
    expect(find.text('Mark done'), findsNothing);
  });

  testWidgets('a repeat not due today says plain Mark done', (tester) async {
    await setUpDi([reminder('1', 'Pills', due, repeat: RepeatRule.daily)]);
    await _pump(tester, '1');
    expect(find.text('Mark done'), findsOneWidget);
    expect(find.text('Mark done for today'), findsNothing);
  });

  testWidgets('a one-off has no moves-to line', (tester) async {
    await setUpDi([reminder('1', 'Pills', due)]);
    await _pump(tester, '1');
    expect(find.textContaining('Marking done moves it to'), findsNothing);
  });

  testWidgets('Mark done completes it', (tester) async {
    final (repo, _) = await setUpDi([reminder('1', 'Pills', due)]);
    await _pump(tester, '1');
    await tester.tap(find.text('Mark done'));
    await tester.pumpAndSettle();
    expect(repo.all.single.isDone, isTrue);
    expect(find.text('Reopen'), findsOneWidget);
  });

  testWidgets('Delete asks first, then removes it', (tester) async {
    final (repo, scheduler) = await setUpDi([reminder('1', 'Pills', due)]);
    await _pump(tester, '1');
    await tester.tap(find.text('Delete reminder'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this reminder?'), findsOneWidget);
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(repo.all, isEmpty);
    expect(scheduler.cancelled, ['1']);
  });

  testWidgets('a missing reminder says so', (tester) async {
    await setUpDi();
    await _pump(tester, 'gone');
    expect(find.text('This reminder no longer exists.'), findsOneWidget);
  });
}
