import 'package:flutter/material.dart';

import '../../../../core/theme/memo_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/ui/memo_pickers.dart';
import '../../../../core/ui/memo_sheet.dart';
import '../../../../core/utils/date_format.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/usecases/snooze_reminder.dart';
import '../../../../l10n/l10n.dart';

/// Asks when [r] should ring again; null when dismissed. The instants come
/// from [SnoozeReminder], the one place that computes them, and are taken at
/// tap time so a sheet left open does not offer a past instant. [clock] is
/// injectable for tests.
Future<DateTime?> showSnoozeSheet(
  BuildContext context,
  Reminder r, {
  DateTime Function() clock = DateTime.now,
}) {
  DateTime at(DateTime now, {Duration? by}) =>
      const SnoozeReminder()(r, now: now, by: by).ringsAt;
  final l = context.l10n;
  var pastTime = false;
  return showMemoSheet<DateTime>(
    context,
    builder: (sheet) => StatefulBuilder(
      builder: (sheet, setState) {
        final now = clock();
        Widget option(String label, Duration? by) => _Option(
          label,
          at(now, by: by),
          now,
          () => Navigator.pop(sheet, at(clock(), by: by)),
        );
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetHeading(l.snoozeTitle, body: l.snoozeBody),
              option(l.snooze10, const Duration(minutes: 10)),
              const SizedBox(height: MemoSpace.space2),
              option(l.snooze1h, const Duration(hours: 1)),
              const SizedBox(height: MemoSpace.space2),
              option(l.snoozeTomorrow, null),
              const SizedBox(height: MemoSpace.space2),
              if (pastTime)
                Text(
                  l.snoozePastTime,
                  textAlign: TextAlign.center,
                  style: MemoType.body.copyWith(
                    color: MemoColors.of(sheet).accentText,
                  ),
                ),
              TextButton(
                onPressed: () async {
                  final date = await pickDate(sheet, now);
                  if (date == null || !sheet.mounted) return;
                  final picked = await pickTime(sheet, date);
                  if (picked == null || !sheet.mounted) return;
                  if (picked.isAfter(clock())) {
                    Navigator.pop(sheet, picked);
                  } else {
                    setState(() => pastTime = true);
                  }
                },
                child: Text(l.snoozePick),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _Option extends StatelessWidget {
  const _Option(this.label, this.at, this.now, this.onTap);

  final String label;
  final DateTime at;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    final sameDay = DateUtils.isSameDay(at, now);
    return OutlinedButton(
      onPressed: onTap,
      style: MemoButtons.large(c),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: MemoSpace.space3),
          Flexible(
            child: Text(
              sameDay ? formatTime(context, at) : formatWhen(context, at, now),
              textAlign: TextAlign.end,
              style: MemoType.labelMedium.copyWith(color: c.ink70),
            ),
          ),
        ],
      ),
    );
  }
}
