import 'package:flutter/material.dart';

import 'check_control.dart';

/// Reminder row content — memo Design System · 04 Components / "Reminder row".
/// No outer card, border, or divider: the list screen owns grouping.
class ReminderRow extends StatelessWidget {
  const ReminderRow({
    super.key,
    required this.title,
    required this.state,
    this.time,
    this.overdueLabel,
    this.doneLabel,
    this.tagLabel,
    this.tagColor,
    this.repeats = false,
    this.onCheckTap,
    this.onTap,
  });

  final String title;
  final CheckState state;

  /// Mono time text, e.g. "08:30". Ignored when [state] is overdue/done and
  /// [overdueLabel]/[doneLabel] is set.
  final String? time;

  /// e.g. "Yesterday 17:00 · 2h late".
  final String? overdueLabel;

  /// e.g. "Done just now".
  final String? doneLabel;

  /// Null when the tags feature is off or the reminder is untagged.
  final String? tagLabel;
  final Color? tagColor;

  /// Null/false when the repeat_reminders feature is off.
  final bool repeats;

  final VoidCallback? onCheckTap;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDone = state == CheckState.done;
    final isOverdue = state == CheckState.overdue;

    final titleStyle = theme.textTheme.bodyLarge?.copyWith(
      decoration: isDone ? TextDecoration.lineThrough : null,
      color: isDone ? scheme.onSurface.withValues(alpha: 0.45) : null,
    );

    Widget meta;
    if (isOverdue && overdueLabel != null) {
      meta = Text(
        overdueLabel!,
        style: theme.textTheme.labelMedium?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w500,
        ),
      );
    } else if (isDone && doneLabel != null) {
      meta = Text(
        doneLabel!,
        style: theme.textTheme.labelMedium?.copyWith(
          color: scheme.onSurface.withValues(alpha: 0.35),
        ),
      );
    } else {
      meta = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (time != null) Text(time!, style: theme.textTheme.labelMedium),
          if (time != null && tagLabel != null) ...[
            const SizedBox(width: 8),
            Container(width: 1, height: 10, color: scheme.outline),
            const SizedBox(width: 8),
          ],
          if (tagLabel != null) ...[
            Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(
                color: tagColor ?? scheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            Text(
              tagLabel!,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
            ),
          ],
        ],
      );
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckControl(state: state, onTap: onCheckTap),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 5, bottom: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: titleStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    meta,
                  ],
                ),
              ),
            ),
            if (repeats && !isDone)
              Padding(
                padding: const EdgeInsets.only(top: 9, left: 8),
                child: Icon(
                  Icons.repeat,
                  size: 15,
                  color: scheme.onSurface.withValues(alpha: 0.35),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
