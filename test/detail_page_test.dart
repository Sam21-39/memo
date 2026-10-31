import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/di.dart';
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

  testWidgets('all three snooze presets are offered', (tester) async {
    await setUpDi([reminder('1', 'Pills', due)]);
    await _pump(tester, '1');
    for (final label in ['10m', '1h', 'Tomorrow']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('a duration preset offsets from now', (tester) async {
    final (repo, _) = await setUpDi([reminder('1', 'Pills', due)]);
    await _pump(tester, '1');
    final before = DateTime.now();
    await tester.tap(find.text('1h'));
    await tester.pumpAndSettle();
    final moved = repo.all.single.dueAt.difference(before);
    expect(moved.inMinutes, inInclusiveRange(59, 61));
  });

  testWidgets('Tomorrow keeps the reminder own time of day', (tester) async {
    final (repo, _) = await setUpDi([reminder('1', 'Pills', due)]);
    await _pump(tester, '1');
    await tester.tap(find.text('Tomorrow'));
    await tester.pumpAndSettle();
    final at = repo.all.single.dueAt;
    expect([at.hour, at.minute], [due.hour, due.minute]);
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
    await tester.tap(find.text('Delete'));
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
