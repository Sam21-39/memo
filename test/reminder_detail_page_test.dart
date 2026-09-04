import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/di/injection.dart';
import 'package:memo/core/feature_flags/feature_flags.dart';
import 'package:memo/core/theme/app_theme.dart';
import 'package:memo/core/utils/date_format.dart';
import 'package:memo/core/utils/notification_scheduler.dart';
import 'package:memo/features/reminders/domain/entities/reminder.dart';
import 'package:memo/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:memo/features/reminders/presentation/pages/reminder_detail_page.dart';

import 'fakes.dart';

late InMemoryRepository repository;

Future<void> _pumpDetail(WidgetTester tester, Reminder existing) async {
  repository = InMemoryRepository([existing]);
  await tester.pumpWidget(
    BlocProvider(
      create: (_) => RemindersCubit(
        repository,
        NotificationScheduler(NoopPlugin()),
        snoozeEnabled: true,
      )..load(),
      child: MaterialApp(
        theme: AppTheme.light,
        home: ReminderDetailPage(reminderId: existing.id),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<Reminder> _stored() async => (await repository.getById('1'))!;

void main() {
  setUpAll(() {
    initTestTimeZone();
    sl.registerSingleton<FeatureFlags>(const RemoteFeatureFlags());
  });

  tearDownAll(() => sl.reset());

  final tomorrowAt9 = DateTime(2026, 12, 1, 9);

  testWidgets('all three snooze presets are offered', (tester) async {
    await _pumpDetail(tester, reminder('1', 'Water the fig tree', tomorrowAt9));

    expect(find.text('10m'), findsOneWidget);
    expect(find.text('1h'), findsOneWidget);
    expect(find.text('Tomorrow'), findsOneWidget);
  });

  testWidgets('a duration preset offsets from now, not from the reminder', (
    tester,
  ) async {
    await _pumpDetail(tester, reminder('1', 'Water the fig tree', tomorrowAt9));
    final before = DateTime.now();

    await tester.tap(find.text('1h'));
    await tester.pumpAndSettle();

    final at = (await _stored()).scheduledAt;
    expect(at.difference(before).inMinutes, closeTo(60, 1));
  });

  testWidgets('Tomorrow keeps the reminder own time of day', (tester) async {
    await _pumpDetail(tester, reminder('1', 'Water the fig tree', tomorrowAt9));

    await tester.tap(find.text('Tomorrow'));
    await tester.pumpAndSettle();

    final at = (await _stored()).scheduledAt;
    final expected = DateTime.now().add(const Duration(days: 1));
    expect(formatTime(at), '09:00');
    expect(isSameDay(at, expected), isTrue);
  });
}
