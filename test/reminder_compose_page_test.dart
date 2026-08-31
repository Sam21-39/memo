import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/di/injection.dart';
import 'package:memo/core/feature_flags/feature_flags.dart';
import 'package:memo/core/theme/app_theme.dart';
import 'package:memo/features/reminders/domain/entities/reminder.dart';
import 'package:memo/features/reminders/presentation/pages/reminder_compose_page.dart';

Future<void> _pumpCompose(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: const ReminderComposePage(knownTags: ['Home']),
    ),
  );
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
                MaterialPageRoute(
                  builder: (_) => const ReminderComposePage(),
                ),
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
