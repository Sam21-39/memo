import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/ui/motion.dart';
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
    final options = labels.keys.toList();
    final d = motion(context, MemoMotion.base);
    return Container(
      constraints: const BoxConstraints(minHeight: MemoSpace.hitMin),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.ink6,
        borderRadius: BorderRadius.circular(MemoRadius.chip + 3),
      ),
      child: Stack(
        children: [
          // The thumb slides under the labels.
          Positioned.fill(
            child: AnimatedAlign(
              duration: d,
              curve: MemoMotion.curve,
              alignment: Alignment(
                -1 + 2 * options.indexOf(value) / (options.length - 1),
                0,
              ),
              child: FractionallySizedBox(
                widthFactor: 1 / options.length,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(MemoRadius.chip),
                    border: Border.all(color: c.hairline),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final entry in labels.entries)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: entry.key == value,
                    child: GestureDetector(
                      onTap: () {
                        if (entry.key != value) HapticFeedback.selectionClick();
                        onChanged(entry.key);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: MemoSpace.hitMin - 6,
                        ),
                        child: Center(
                          child: Text(
                            entry.value,
                            textAlign: TextAlign.center,
                            style: MemoType.labelMedium.copyWith(
                              color: entry.key == value ? c.ink : c.ink70,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
