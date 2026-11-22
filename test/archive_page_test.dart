import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/di.dart';
import 'package:memo/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:memo/features/reminders/domain/usecases/save_reminder.dart';
import 'package:memo/features/reminders/presentation/archive/archive_cubit.dart';
import 'package:memo/features/reminders/presentation/archive/archive_page.dart';
import 'package:memo/features/tags/presentation/widgets/tag_chip.dart';

import 'fakes.dart';

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    themed(
      BlocProvider(
        create: (_) =>
            ArchiveCubit(sl<ReminderRepository>(), sl<SaveReminder>())..load(),
        child: const ArchivePage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final now = DateTime.now();
  DateTime day(int d, int h) => DateTime(now.year, now.month, now.day + d, h);

  testWidgets('empty archive explains itself', (tester) async {
    await setUpDi();
    await _pump(tester);
    expect(find.text('Nothing done yet'), findsOneWidget);
    expect(
      find.text('Reminders you mark done show up here. You can reopen them.'),
      findsOneWidget,
    );
  });

  testWidgets('search has a visible label and done items group by day', (
    tester,
  ) async {
    await setUpDi([
      reminder('1', 'Pills', day(-1, 8), doneAt: day(0, 9)),
      reminder('2', 'Bins', day(-2, 8), doneAt: day(-1, 9)),
    ]);
    await _pump(tester);
    expect(find.text('Search done reminders'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget); // the hint
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('YESTERDAY'), findsOneWidget);
  });

  testWidgets('Reopen puts a reminder back and the chip is 44 high', (
    tester,
  ) async {
    final (repo, _) = await setUpDi([
      reminder('1', 'Pills', day(-1, 8), doneAt: day(0, 9)),
    ]);
    await _pump(tester);
    expect(
      tester.getSize(find.widgetWithText(TagChip, 'Reopen')).height,
      greaterThanOrEqualTo(44),
    );
    expect(
      tester.getSemantics(find.byType(TextField)).label,
      contains('Search done reminders'),
    );
    await tester.tap(find.text('Reopen'));
    await tester.pumpAndSettle();
    expect(repo.all.single.isDone, isFalse);
    expect(find.text('Nothing done yet'), findsOneWidget);
  });
}
