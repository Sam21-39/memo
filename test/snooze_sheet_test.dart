import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/reminders/domain/entities/repeat_rule.dart';
import 'package:memo/features/reminders/domain/usecases/snooze_reminder.dart';
import 'package:memo/features/reminders/presentation/widgets/snooze_sheet.dart';

import 'fakes.dart';

void main() {
  final start = DateTime(2026, 11, 4, 9);

  Future<DateTime? Function()> open(
    WidgetTester tester,
    DateTime Function() clock, {
    RepeatRule repeat = RepeatRule.none,
    double scale = 1,
  }) async {
    DateTime? result;
    var done = false;
    await tester.pumpWidget(
      themed(
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showSnoozeSheet(
                    context,
                    reminder(
                      '1',
                      'Pills',
                      DateTime(2026, 11, 3, 20, 30),
                      repeat: repeat,
                    ),
                    clock: clock,
                  );
                  done = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return () => done ? result : null;
  }

  testWidgets('options are computed at tap, not at open', (tester) async {
    var now = start;
    final result = await open(tester, () => now);
    now = start.add(const Duration(minutes: 30)); // sheet sat open
    await tester.tap(find.text('Snooze 10 minutes'));
    await tester.pumpAndSettle();
    expect(result(), DateTime(2026, 11, 4, 9, 40));
  });

  testWidgets('Tomorrow on a repeat is the series time of day', (tester) async {
    final result = await open(tester, () => start, repeat: RepeatRule.daily);
    await tester.tap(find.text('Tomorrow, same time'));
    await tester.pumpAndSettle();
    final at = result()!;
    expect(at, DateTime(2026, 11, 5, 20, 30));
    final r = reminder(
      '1',
      'Pills',
      DateTime(2026, 11, 3, 20, 30),
      repeat: RepeatRule.daily,
    );
    final s = const SnoozeReminder()(r, now: start, until: at);
    expect(s.dueAt, r.dueAt);
    expect(s.snoozedUntil, at);
  });

  testWidgets('no overflow at 320 wide and 2.0x text', (tester) async {
    tester.view.physicalSize = const Size(320, 690);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await open(tester, () => start, scale: 2);
    expect(tester.takeException(), isNull);
  });
}
