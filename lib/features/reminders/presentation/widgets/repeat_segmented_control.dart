import 'package:flutter/material.dart';

enum RepeatOption { none, daily, weekly, custom }

/// Segmented control — memo Design System · 04 Components / "Segmented · repeat".
/// Gated by the repeat_reminders flag at the call site (omit the widget when off).
class RepeatSegmentedControl extends StatelessWidget {
  const RepeatSegmentedControl({
    super.key,
    required this.value,
    required this.onChanged,
    this.labels = const {
      RepeatOption.none: 'None',
      RepeatOption.daily: 'Daily',
      RepeatOption.weekly: 'Weekly',
      RepeatOption.custom: 'Custom',
    },
  });

  final RepeatOption value;
  final ValueChanged<RepeatOption> onChanged;
  final Map<RepeatOption, String> labels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: labels.entries.map((entry) {
          final selected = entry.key == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(entry.key),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 36,
                alignment: Alignment.center,
                decoration: selected
                    ? BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: scheme.outline),
                      )
                    : null,
                child: Text(
                  entry.value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected
                        ? scheme.onSurface
                        : scheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
