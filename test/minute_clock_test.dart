import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/ui/minute_clock.dart';

void main() {
  testWidgets('listeners rebuild each minute and free the ticker on unmount', (
    tester,
  ) async {
    var builds = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<DateTime>(
          valueListenable: MinuteClock.instance,
          builder: (context, now, _) {
            builds++;
            return Text('${now.minute}');
          },
        ),
      ),
    );
    final first = builds;
    await tester.pump(const Duration(minutes: 1, seconds: 1));
    expect(builds, greaterThan(first));
    // ignore: invalid_use_of_protected_member
    expect(MinuteClock.instance.hasListeners, isTrue);

    await tester.pumpWidget(const SizedBox());
    // ignore: invalid_use_of_protected_member
    expect(MinuteClock.instance.hasListeners, isFalse);
  });
}
