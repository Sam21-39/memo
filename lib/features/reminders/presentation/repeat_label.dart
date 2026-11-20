import 'package:flutter/widgets.dart';

import '../../../core/utils/date_format.dart';
import '../../../l10n/l10n.dart';
import '../domain/entities/repeat_rule.dart';

/// One-line repeat summary shared by the capture chips and the detail page.
/// [none] is what an absent rule reads as in that place.
String repeatLabel(BuildContext c, RepeatRule r, {required String none}) {
  final l = c.l10n;
  return switch (r.type) {
    RepeatType.none => none,
    RepeatType.daily => l.repeatDaily,
    RepeatType.weekly when r.weekdays.isEmpty => l.repeatWeekly,
    RepeatType.weekly when r.weekdays.length == 1 => l.repeatEveryDay(
      weekdayShort(c, r.weekdays.first),
    ),
    RepeatType.weekly
        when r.weekdays.containsAll({1, 2, 3, 4, 5}) &&
            r.weekdays.length == 5 =>
      l.captureRepeatWeekdays,
    RepeatType.weekly =>
      (r.weekdays.toList()..sort()).map((d) => weekdayShort(c, d)).join(' '),
  };
}
