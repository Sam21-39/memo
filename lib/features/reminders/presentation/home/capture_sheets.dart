import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/ui/memo_pickers.dart';
import '../../../../core/ui/memo_sheet.dart';
import '../../../../core/utils/date_format.dart';
import '../../../tags/presentation/tag_color.dart';
import '../../../tags/presentation/widgets/tag_chip.dart';
import '../../domain/entities/repeat_rule.dart';
import '../widgets/key_value_row.dart';
import '../widgets/repeat_segmented_control.dart';
import '../widgets/section_card.dart';
import '../widgets/weekday_selector.dart';
import '../../../../l10n/strings.dart';

/// Time chip: date and time rows over the native pickers.
Future<DateTime?> showWhenSheet(BuildContext context, DateTime initial) {
  var value = initial;
  return showMemoSheet<DateTime>(
    context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHeading(S.fieldWhen),
          SectionCard(
            children: [
              KeyValueRow(
                label: S.fieldTime,
                onTap: () async {
                  final t = await pickTime(context, value);
                  if (t != null) setState(() => value = t);
                },
                child: PillValue(formatTime(value), active: true),
              ),
              KeyValueRow(
                label: S.fieldDate,
                onTap: () async {
                  final d = await pickDate(context, value);
                  if (d != null) setState(() => value = d);
                },
                child: PillValue(dayHeaderLabel(value, DateTime.now())),
              ),
            ],
          ),
          const SizedBox(height: MemoSpace.space6),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(value),
            child: const Text(S.commonDone),
          ),
        ],
      ),
    ),
  );
}

/// Artboard Sheet-Repeat.
Future<RepeatRule?> showRepeatSheet(
  BuildContext context,
  RepeatRule initial,
  DateTime dueAt,
) {
  var rule = initial;
  RepeatOption option() => switch (rule.type) {
    RepeatType.none => RepeatOption.none,
    RepeatType.daily => RepeatOption.daily,
    RepeatType.weekly =>
      rule.weekdays.length == 1 ? RepeatOption.weekly : RepeatOption.custom,
  };
  return showMemoSheet<RepeatRule>(
    context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHeading(S.fieldRepeat, body: S.repeatSheetBody),
          RepeatSegmentedControl(
            value: option(),
            onChanged: (o) => setState(
              () => rule = switch (o) {
                RepeatOption.none => RepeatRule.none,
                RepeatOption.daily => RepeatRule.daily,
                RepeatOption.weekly => RepeatRule(
                  RepeatType.weekly,
                  weekdays: {dueAt.weekday},
                ),
                RepeatOption.custom => RepeatRule(
                  RepeatType.weekly,
                  weekdays: rule.weekdays.length > 1
                      ? rule.weekdays
                      : {dueAt.weekday, dueAt.weekday % 7 + 1},
                ),
              },
            ),
          ),
          if (rule.type == RepeatType.weekly) ...[
            const SizedBox(height: MemoSpace.space3),
            WeekdaySelector(
              selected: rule.weekdays,
              onChanged: (days) {
                if (days.isEmpty) return;
                setState(
                  () => rule = RepeatRule(RepeatType.weekly, weekdays: days),
                );
              },
            ),
          ],
          const SizedBox(height: MemoSpace.space6),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(rule),
            child: const Text(S.commonDone),
          ),
        ],
      ),
    ),
  );
}

/// Artboard Sheet-Tag. Returns the chosen tag, '' for none, null if
/// dismissed.
Future<String?> showTagSheet(
  BuildContext context,
  String? initial,
  List<String> knownTags,
) {
  var selected = initial;
  final tags = [...knownTags];
  return showMemoSheet<String>(
    context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final c = MemoColors.of(context);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHeading(S.fieldTag, body: S.tagSheetBody),
            Wrap(
              spacing: MemoSpace.space2,
              runSpacing: MemoSpace.space2,
              children: [
                for (final tag in tags)
                  TagChip(
                    label: tag,
                    dotColor: tagColor(tag),
                    selected: tag == selected,
                    onTap: () =>
                        setState(() => selected = tag == selected ? null : tag),
                  ),
              ],
            ),
            const SizedBox(height: MemoSpace.space3),
            TextField(
              textCapitalization: TextCapitalization.words,
              style: MemoType.body.copyWith(color: c.ink),
              decoration: const InputDecoration(hintText: S.tagNewHint),
              onSubmitted: (name) {
                final t = name.trim();
                if (t.isEmpty) return;
                setState(() {
                  if (!tags.contains(t)) tags.add(t);
                  selected = t;
                });
              },
            ),
            const SizedBox(height: MemoSpace.space6),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(selected ?? ''),
              child: const Text(S.commonDone),
            ),
          ],
        );
      },
    ),
  );
}
