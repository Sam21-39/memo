import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import 'check_control.dart';
import '../../../../l10n/strings.dart';

/// One reminder: check, title, optional mono sub-line (tag dot + name, or a
/// note), repeat glyph and mono time on the right. No border of its own.
class ReminderRow extends StatelessWidget {
  const ReminderRow({
    super.key,
    required this.title,
    required this.state,
    required this.trailing,
    this.subtitle,
    this.tagColor,
    this.repeats = false,
    this.onCheckTap,
    this.onTap,
  });

  final String title;
  final CheckState state;

  /// Mono text on the right: "20:00", "2h late", "Done".
  final String trailing;

  /// Tag name (with [tagColor] dot) or a short note.
  final String? subtitle;
  final Color? tagColor;
  final bool repeats;
  final VoidCallback? onCheckTap;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    final done = state == CheckState.done;
    final overdue = state == CheckState.overdue;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: MemoSpace.rowMin),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            MemoSpace.space1,
            MemoSpace.space1,
            MemoSpace.space4,
            MemoSpace.space1,
          ),
          child: Row(
            children: [
              CheckControl(state: state, onTap: onCheckTap),
              const SizedBox(width: MemoSpace.space1),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: MemoType.bodyLarge.copyWith(
                        color: done ? c.ink45 : c.ink,
                        decoration: done ? TextDecoration.lineThrough : null,
                        decorationColor: c.ink45,
                      ),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            if (tagColor != null) ...[
                              _Dot(tagColor!),
                              const SizedBox(width: MemoSpace.space1),
                            ],
                            Flexible(
                              child: Text(
                                subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: MemoType.labelMedium.copyWith(
                                  color: c.ink70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (repeats && !done) ...[
                const SizedBox(width: MemoSpace.space2),
                Icon(
                  Icons.repeat_rounded,
                  size: 14,
                  color: c.ink45,
                  semanticLabel: S.repeatsSemantic,
                ),
              ],
              const SizedBox(width: MemoSpace.space2),
              Text(
                trailing,
                style: MemoType.labelMedium.copyWith(
                  color: overdue ? c.accent : c.ink70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.color);
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 6,
    height: 6,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
