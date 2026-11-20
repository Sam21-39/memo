import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/theme/tokens.dart';
import 'package:memo/features/reminders/presentation/widgets/day_section_header.dart';

import 'fakes.dart';

void main() {
  test('every type style carries the Noto fallback', () {
    expect(MemoType.body.fontFamilyFallback, MemoType.fallback);
    expect(MemoType.labelMedium.fontFamilyFallback, MemoType.fallback);
  });

  test('Noto font files and licence are bundled', () {
    for (final s in ['Devanagari', 'Bengali']) {
      for (final w in ['Regular', 'Medium', 'SemiBold']) {
        expect(File('assets/fonts/NotoSans$s-$w.ttf').existsSync(), isTrue);
      }
    }
    expect(File('assets/fonts/OFL-Noto.txt').existsSync(), isTrue);
  });

  test('new colour tokens exist and differ from accent', () {
    final c = MemoColors.light;
    for (final t in [c.accentText, c.caution, c.cautionSoft, c.ok]) {
      expect(t, isNot(c.accent));
    }
  });

  testWidgets('section label is uppercase for en', (tester) async {
    await tester.pumpWidget(themed(const DaySectionHeader(label: 'Today')));
    expect(find.text('TODAY'), findsOneWidget);
  });

  testWidgets('section label works without Localizations ancestor', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: Theme(
            data: ThemeData(extensions: const [MemoColors.light]),
            child: const DaySectionHeader(label: 'Today'),
          ),
        ),
      ),
    );
    expect(find.text('TODAY'), findsOneWidget);
  });
}
