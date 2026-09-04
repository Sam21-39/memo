import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/di/injection.dart';
import 'package:memo/core/feature_flags/feature_flags.dart';
import 'package:memo/core/theme/app_theme.dart';
import 'package:memo/core/utils/notification_scheduler.dart';
import 'package:memo/features/reminders/domain/entities/reminder.dart';
import 'package:memo/features/reminders/domain/entities/repeat_rule.dart';
import 'package:memo/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:memo/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:memo/features/reminders/presentation/pages/reminder_list_page.dart';
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

Future<void> _pumpList(WidgetTester tester, ReminderRepository repo) async {
  await tester.pumpWidget(
    BlocProvider(
      create: (_) => RemindersCubit(
        repo,
        NotificationScheduler(NoopPlugin()),
        snoozeEnabled: true,
      )..load(),
      child: MaterialApp(theme: AppTheme.light, home: const ReminderListPage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    initTestTimeZone();
    sl.registerSingleton<FeatureFlags>(const RemoteFeatureFlags());
  });

  tearDownAll(() => sl.reset());

  testWidgets('empty state invites the first reminder', (tester) async {
    await _pumpList(tester, InMemoryRepository());

    expect(find.text('Nothing scheduled'), findsOneWidget);
    expect(find.text('New reminder'), findsOneWidget);
  });

  testWidgets('loaded state groups reminders under day headers', (
    tester,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 23, 59);
    final nextWeek = today.add(const Duration(days: 7));

    await _pumpList(
      tester,
      InMemoryRepository([
        reminder('1', 'Water the fig tree', today),
        reminder('2', 'Renew passport', nextWeek),
      ]),
    );

    expect(find.text('Nothing scheduled'), findsNothing);
    expect(find.text('Water the fig tree'), findsOneWidget);
    expect(find.text('Renew passport'), findsOneWidget);
    expect(find.textContaining('TODAY'), findsOneWidget);
  });

  testWidgets('an overdue reminder gets its own section', (tester) async {
    final overdueAt = DateTime.now().subtract(const Duration(hours: 2));

    await _pumpList(
      tester,
      InMemoryRepository([reminder('1', 'Call the pharmacy', overdueAt)]),
    );

    expect(find.text('OVERDUE'), findsOneWidget);
    expect(find.textContaining('2h late'), findsOneWidget);
    expect(find.textContaining('1 overdue'), findsOneWidget);
  });

  testWidgets('a failed load says so instead of showing an empty list', (
    tester,
  ) async {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      23,
      59,
    );
    await _pumpList(
      tester,
      _FailingRepository([reminder('1', 'Water the fig tree', today)]),
    );

    expect(find.text("Couldn't load your reminders"), findsOneWidget);
    expect(find.text('Nothing scheduled'), findsNothing);
    // The header count would otherwise claim "0 scheduled" over real data.
    expect(find.textContaining('0 scheduled'), findsNothing);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Water the fig tree'), findsOneWidget);
  });

  testWidgets('completing a reminder moves it out of the list', (tester) async {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      23,
      59,
    );
    await _pumpList(
      tester,
      InMemoryRepository([reminder('1', 'Water the fig tree', today)]),
    );

    await tester.tap(find.byType(CheckControl));
    await tester.pumpAndSettle();

    expect(find.text('Water the fig tree'), findsNothing);
    expect(find.text('Nothing scheduled'), findsOneWidget);
    expect(find.text('Marked done'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
  });

  testWidgets('completing a repeat offers no Undo — it would do nothing', (
    tester,
  ) async {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      23,
      59,
    );
    await _pumpList(
      tester,
      InMemoryRepository([
        reminder('1', 'Water the fig tree', today, repeat: RepeatRule.daily),
      ]),
    );

    await tester.tap(find.byType(CheckControl));
    await tester.pumpAndSettle();

    expect(find.text('Moved to next occurrence'), findsOneWidget);
    expect(find.text('Undo'), findsNothing);
    // Still listed, one day on — completing a repeat archives nothing.
    expect(find.text('Water the fig tree'), findsOneWidget);
  });
}
