import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/ui/minutes_sheet.dart';
import 'package:memo/core/utils/date_format.dart';
import 'package:memo/l10n/strings.dart';

void main() {
  test('spot-checked strings are non-empty', () {
    for (final s in [
      S.appName,
      S.commonDone,
      S.homeEmptyTitle,
      S.settingsTitle,
      S.welcomeTitle,
      S.permAllow,
      S.scheduleFailed,
      S.saveFailed,
      S.timePassed,
      S.dateToday,
    ]) {
      expect(s, isNotEmpty);
    }
  });

  test('formatLateness, nagLabel, preAlarmLabel', () {
    expect(formatLateness(const Duration(minutes: 1)), '1 min late');
    expect(formatLateness(const Duration(minutes: 59)), '59 min late');
    expect(formatLateness(const Duration(minutes: 90)), '1h late');
    expect(formatLateness(const Duration(hours: 2)), '2h late');
    expect(formatLateness(const Duration(days: 3)), '3d late');
    expect(nagLabel(1), 'Every 1 min');
    expect(nagLabel(59), 'Every 59 min');
    expect(nagLabel(90), 'Every 90 min');
    expect(preAlarmLabel(1), '1 min before');
    expect(preAlarmLabel(59), '59 min before');
    expect(preAlarmLabel(90), '90 min before');
    expect(preAlarmLabel(120), '2 h before');
    expect(preAlarmLabel(3 * 24 * 60), '72 h before');
  });

  // Guard: user-visible text goes through S. Scans lib/ for string literals
  // passed straight to Text / hintText / label / tooltip.
  test('no hardcoded UI strings outside lib/l10n/strings.dart', () {
    final call = RegExp(
      r'''(?:Text\(|hintText:|label:|tooltip:)\s*['"]([^\n]*)''',
    );
    // Brand mark (logo, not copy), a lone interpolated value ('$count') and
    // glyph-only strings with no words.
    final allowed = RegExp(r'''^(Memō|\$\w+|[^A-Za-z]*)['"]''');
    final hits = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      if (f.path.endsWith('lib/l10n/strings.dart') ||
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
}
