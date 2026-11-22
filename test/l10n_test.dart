import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/theme/memo_theme.dart';
import 'package:memo/core/ui/minutes_sheet.dart';
import 'package:memo/core/utils/date_format.dart';
import 'package:memo/features/reminders/presentation/widgets/day_section_header.dart';
import 'package:memo/l10n/l10n.dart';

import 'fakes.dart';

Map<String, dynamic> _arb(String code) =>
    jsonDecode(File('lib/l10n/app_$code.arb').readAsStringSync())
        as Map<String, dynamic>;

/// Pumps a MaterialApp in [locale] and returns a context under it.
Future<BuildContext> _context(
  WidgetTester tester,
  String locale, {
  bool h24 = false,
}) async {
  late BuildContext context;
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: h24),
        child: child!,
      ),
      home: Builder(
        builder: (c) {
          context = c;
          return const SizedBox();
        },
      ),
    ),
  );
  return context;
}

void main() {
  test('ARB key parity and placeholders', () {
    final en = _arb('en');
    final keys = en.keys.where((k) => !k.startsWith('@')).toSet();
    for (final code in ['hi', 'bn']) {
      final other = _arb(code);
      expect(
        other.keys.where((k) => !k.startsWith('@')).toSet(),
        keys,
        reason: code,
      );
    }
    for (final k in keys.where((k) => !k.startsWith('@'))) {
      final ph = (en['@$k']?['placeholders'] as Map?)?.keys ?? const [];
      for (final code in ['en', 'hi', 'bn']) {
        final value = _arb(code)[k] as String;
        for (final name in ph) {
          expect(value, contains('{$name}'), reason: '$code.$k');
        }
      }
    }
  });

  // Guard: user-visible text goes through the ARB files. Scans lib/ for string
  // literals passed straight to Text / hintText / label / tooltip.
  test('no hardcoded UI strings outside lib/l10n', () {
    final call = RegExp(
      r'''(?:Text\(|hintText:|label:|tooltip:)\s*['"]([^\n]*)''',
    );
    // A lone interpolated value ('$count') and glyph-only strings.
    final allowed = RegExp(r'''^(\$\w+|[^A-Za-z]*)['"]''');
    final hits = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      if (f.path.contains('lib/l10n/') ||
          f.path.endsWith('lib/core/theme/tokens.dart')) {
        continue;
      }
      final src = f.readAsStringSync();
      for (final m in call.allMatches(src)) {
        if (allowed.hasMatch(m.group(1)!)) continue;
        final line = '\n'.allMatches(src.substring(0, m.start)).length + 1;
        hits.add('${f.path}:$line ${m.group(0)!.replaceAll('\n', ' ')}');
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });

  final native = RegExp('[০-৯०-९]');

  for (final code in ['bn', 'hi']) {
    testWidgets('$code shows Western digits only', (tester) async {
      useWesternDigits();
      final c = await _context(tester, code);
      final d = DateTime(2026, 11, 20, 20, 5);
      for (final s in [
        formatDate(c, d),
        formatLongDate(c, d),
        MaterialLocalizations.of(c).formatDecimal(2026),
        formatTime(c, d),
        formatLateness(c, const Duration(hours: 2)),
        c.l10n.everyMinutes(15),
      ]) {
        expect(native.hasMatch(s), isFalse, reason: '$code: $s');
      }
    });
  }

  for (final code in ['en', 'hi', 'bn']) {
    testWidgets('formatTime follows the device clock in $code', (tester) async {
      useWesternDigits();
      final d = DateTime(2026, 11, 20, 20, 5);
      expect(formatTime(await _context(tester, code), d), '8:05 PM');
      expect(formatTime(await _context(tester, code, h24: true), d), '20:05');
    });
  }

  testWidgets('lateness and minute labels', (tester) async {
    final c = await _context(tester, 'en');
    expect(formatLateness(c, const Duration(minutes: 1)), '1 min late');
    expect(formatLateness(c, const Duration(minutes: 59)), '59 min late');
    expect(formatLateness(c, const Duration(minutes: 90)), '1 h late');
    expect(formatLateness(c, const Duration(hours: 2)), '2 h late');
    expect(formatLateness(c, const Duration(days: 3)), '3 d late');
    final l = c.l10n;
    expect(nagLabel(l, 1), 'Every minute');
    expect(nagLabel(l, 59), 'Every 59 min');
    expect(preAlarmLabel(l, 120), '2 h before');
    expect(preAlarmLabel(l, 3 * 24 * 60), '72 h before');
    expect(preAlarmLabel(l, 90), '90 min before');
  });

  testWidgets('Latin section label is not uppercased or tracked in Hindi', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: MemoTheme.light,
        locale: const Locale('hi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const DaySectionHeader(label: 'Today'),
      ),
    );
    final style = tester.widget<Text>(find.text('Today')).style!;
    expect(style.letterSpacing, isNull);
    expect(style.fontSize, 13);
    // English stays uppercase.
    await tester.pumpWidget(themed(const DaySectionHeader(label: 'Today')));
    expect(find.text('TODAY'), findsOneWidget);
  });
}
