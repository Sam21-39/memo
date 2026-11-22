import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/theme/tokens.dart';
import 'package:memo/core/ui/motion.dart';

void main() {
  Future<Duration> read(WidgetTester tester, {required bool reduce}) async {
    late Duration d;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: reduce),
        child: Builder(
          builder: (c) {
            d = motion(c, MemoMotion.base);
            return const SizedBox();
          },
        ),
      ),
    );
    return d;
  }

  testWidgets('motion keeps the token duration', (tester) async {
    expect(await read(tester, reduce: false), MemoMotion.base);
  });

  testWidgets('motion is zero under Reduce Motion', (tester) async {
    expect(await read(tester, reduce: true), Duration.zero);
  });
}
