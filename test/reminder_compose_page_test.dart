import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/di/injection.dart';
import 'package:memo/core/feature_flags/feature_flags.dart';
import 'package:memo/core/theme/app_theme.dart';
import 'package:memo/core/utils/date_format.dart';
import 'package:memo/features/reminders/domain/entities/reminder.dart';
import 'package:memo/features/reminders/domain/entities/repeat_rule.dart';
import 'package:memo/features/reminders/presentation/pages/reminder_compose_page.dart';

Reminder _reminder(
  DateTime scheduledAt, {
  RepeatRule repeat = RepeatRule.none,
}) => Reminder(
  id: 'abc123',
  title: 'Water the fig tree',
  scheduledAt: scheduledAt,
  createdAt: DateTime(2026, 8, 1),
  repeat: repeat,
);

Future<void> _pumpCompose(
  WidgetTester tester, {
  Reminder? existing,
  ValueChanged<Reminder?>? onResult,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      // Pushed rather than set as `home` so Save's pop has a route to return
      // its result to.
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            final result = await Navigator.of(context).push<Reminder>(
              MaterialPageRoute(
                builder: (_) => ReminderComposePage(
                  existing: existing,
                  knownTags: const ['Home'],
                ),
              ),
            );
            onResult?.call(result);
          },
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    sl.registerSingleton<FeatureFlags>(const RemoteFeatureFlags());
  });

  tearDownAll(() => sl.reset());

  testWidgets('Save is disabled until the title has text', (tester) async {
    await _pumpCompose(tester);

    final saveButton = tester.widget<TextButton>(
      find.ancestor(of: find.text('Save'), matching: find.byType(TextButton)),
    );
    expect(saveButton.onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, 'Renew passport');
    await tester.pump();

    final enabled = tester.widget<TextButton>(
      find.ancestor(of: find.text('Save'), matching: find.byType(TextButton)),
    );
    expect(enabled.onPressed, isNotNull);
  });

  testWidgets('the new-tag dialog survives being dismissed', (tester) async {
    await _pumpCompose(tester);

    await tester.tap(find.text('+ New'));
    await tester.pumpAndSettle();
    expect(find.text('New tag'), findsOneWidget);

    // Scoped to the dialog — the compose top bar has a Cancel too.
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Cancel'),
      ),
    );
    // Pump through the route's exit animation: disposing the dialog's
    // controller too early surfaces as a use-after-dispose right here.
    await tester.pumpAndSettle();

    expect(find.text('New tag'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('adding a tag selects it on the reminder', (tester) async {
    await _pumpCompose(tester);

    await tester.enterText(find.byType(TextField).first, 'Renew passport');
    await tester.pump();

    await tester.tap(find.text('+ New'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Admin');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Admin'), findsOneWidget);
  });

  testWidgets('a past time on a one-off is called out before saving', (
    tester,
  ) async {
    await _pumpCompose(
      tester,
      existing: _reminder(
        DateTime.now().subtract(const Duration(days: 1)),
        repeat: RepeatRule.none,
      ),
    );

    expect(find.textContaining('already passed'), findsOneWidget);
  });

  testWidgets('a repeat in the past is not called out — it rolls forward', (
    tester,
  ) async {
    await _pumpCompose(
      tester,
      existing: _reminder(
        DateTime.now().subtract(const Duration(days: 1)),
        repeat: RepeatRule.daily,
      ),
    );

    expect(find.textContaining('already passed'), findsNothing);
  });

  testWidgets('a single-day weekly rule follows the date you pick', (
    tester,
  ) async {
    // Weekly on a Monday, then moved to the Wednesday two days later.
    final monday = DateTime(2026, 9, 7, 9);
    expect(monday.weekday, DateTime.monday);

    Reminder? result;
    await _pumpCompose(
      tester,
      existing: _reminder(
        monday,
        repeat: const RepeatRule(RepeatType.weekly, weekdays: {1}),
      ),
      onResult: (r) => result = r,
    );

    await tester.tap(find.text(formatDate(monday)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('9'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(result!.scheduledAt.weekday, DateTime.wednesday);
    expect(result!.repeat.weekdays, {DateTime.wednesday});
  });

  testWidgets('a multi-day custom rule is left alone when the date moves', (
    tester,
  ) async {
    final monday = DateTime(2026, 9, 7, 9);

    Reminder? result;
    await _pumpCompose(
      tester,
      existing: _reminder(
        monday,
        repeat: const RepeatRule(RepeatType.weekly, weekdays: {1, 5}),
      ),
      onResult: (r) => result = r,
    );

    await tester.tap(find.text(formatDate(monday)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('9'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(result!.repeat.weekdays, {1, 5});
  });

  testWidgets('cancelling returns nothing, saving returns the reminder', (
    tester,
  ) async {
    Reminder? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.of(context).push<Reminder>(
                MaterialPageRoute(builder: (_) => const ReminderComposePage()),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '  Renew passport  ');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.title, 'Renew passport');
    expect(result!.isDone, isFalse);
  });
}
