import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/reminders/domain/entities/repeat_rule.dart';
import 'package:memo/features/reminders/domain/usecases/save_reminder.dart';
import 'package:memo/features/reminders/presentation/edit/edit_cubit.dart';
import 'package:memo/features/reminders/presentation/edit/edit_sheet.dart';
import 'package:memo/core/di.dart';

import 'fakes.dart';

Future<EditCubit> _pump(WidgetTester tester, {EditCubit? cubit}) async {
  final c = cubit ?? EditCubit(sl<SaveReminder>());
  await tester.pumpWidget(
    themed(
      Scaffold(
        body: BlocProvider.value(
          value: c,
          child: const EditForm(knownTags: ['Home']),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return c;
}

void main() {
  testWidgets('Save is disabled until the title has text', (tester) async {
    final (repo, _) = await setUpDi();
    await _pump(tester);
    final save = find.widgetWithText(TextButton, 'Save');
    expect(tester.widget<TextButton>(save).onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, 'Water the fig');
    await tester.pump();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(repo.all.single.title, 'Water the fig');
  });

  testWidgets('a past one-off is called out before saving', (tester) async {
    await setUpDi();
    final cubit = EditCubit(sl<SaveReminder>())
      ..setDueAt(DateTime.now().subtract(const Duration(hours: 1)));
    await _pump(tester, cubit: cubit);
    expect(find.textContaining('will not ring'), findsOneWidget);

    cubit.setRepeat(RepeatRule.daily);
    await tester.pumpAndSettle();
    expect(find.textContaining('will not ring'), findsNothing);
  });

  testWidgets('a new tag is selected and shown', (tester) async {
    await setUpDi();
    final cubit = await _pump(tester);
    await tester.tap(find.text('+ New'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Garden');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(cubit.state.tag, 'Garden');
    expect(find.text('Garden'), findsOneWidget);
  });

  test('a single-day weekly rule follows the date', () async {
    await setUpDi();
    final cubit = EditCubit(sl<SaveReminder>())
      ..setDueAt(DateTime(2026, 11, 2, 8)) // Monday
      ..setRepeat(const RepeatRule(RepeatType.weekly, weekdays: {1}))
      ..setDueAt(DateTime(2026, 11, 4, 8)); // Wednesday
    expect(cubit.state.repeat.weekdays, {3});
  });

  test('a multi-day custom rule stays when the date moves', () async {
    await setUpDi();
    final cubit = EditCubit(sl<SaveReminder>())
      ..setRepeat(const RepeatRule(RepeatType.weekly, weekdays: {1, 3}))
      ..setDueAt(DateTime(2026, 11, 6, 8));
    expect(cubit.state.repeat.weekdays, {1, 3});
  });

  test('a schedule failure still saves and reports inline', () async {
    final (repo, scheduler) = await setUpDi();
    scheduler.fail = true;
    final cubit = EditCubit(sl<SaveReminder>())..setTitle('Bins');
    await cubit.save();
    expect(cubit.state.status, EditStatus.saved);
    expect(cubit.state.error, isNotNull);
    expect(repo.all.single.needsSchedule, isTrue);
  });
}
