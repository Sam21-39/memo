import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../l10n/l10n.dart';

enum RepeatOption { none, daily, weekly, custom }

/// Repeat selector: ink-6 track, selected segment a surface tile with a
/// hairline ring, mono labels.
class RepeatSegmentedControl extends StatelessWidget {
  const RepeatSegmentedControl({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final RepeatOption value;
  final ValueChanged<RepeatOption> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    final l = context.l10n;
    final labels = {
      RepeatOption.none: l.repeatNone,
      RepeatOption.daily: l.repeatDaily,
      RepeatOption.weekly: l.repeatWeekly,
      RepeatOption.custom: l.repeatCustom,
    };
    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.ink6,
        borderRadius: BorderRadius.circular(MemoRadius.chip + 3),
      ),
      child: Row(
        children: [
          for (final entry in labels.entries)
            Expanded(
              child: Semantics(
                button: true,
                selected: entry.key == value,
                child: GestureDetector(
                  onTap: () => onChanged(entry.key),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: MemoMotion.fast,
                    curve: MemoMotion.curve,
                    alignment: Alignment.center,
                    decoration: entry.key == value
                        ? BoxDecoration(
                            color: c.surface,
                            borderRadius: BorderRadius.circular(
                              MemoRadius.chip,
                            ),
                            border: Border.all(color: c.hairline),
                          )
                        : null,
                    child: Text(
                      entry.value,
                      style: MemoType.labelMedium.copyWith(
                        color: entry.key == value ? c.ink : c.ink70,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
