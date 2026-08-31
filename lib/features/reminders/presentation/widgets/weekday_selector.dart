import 'package:flutter/material.dart';

const _shortLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const _longLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// 7-way weekday toggle for custom repeat — memo Design System · 04 Components
/// / "Segmented · repeat" (compact) and Screens · "Custom repeat" sheet (full).
/// Weekdays follow [DateTime.weekday]: Monday = 1 .. Sunday = 7.
class WeekdaySelector extends StatelessWidget {
  const WeekdaySelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.compact = true,
  });

  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  /// Compact: single-letter, 38px tall. Full: 3-letter, 52px tall, wraps
  /// to two rows of four so it stays legible on narrow screens.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final labels = compact ? _shortLabels : _longLabels;
    final tiles = List.generate(
      7,
      (i) => _Tile(
        label: labels[i],
        selected: selected.contains(i + 1),
        compact: compact,
        onTap: () {
          final next = Set<int>.from(selected);
          next.contains(i + 1) ? next.remove(i + 1) : next.add(i + 1);
          onChanged(next);
        },
      ),
    );

    if (compact) {
      return Row(
        children: [
          for (final t in tiles)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: t,
              ),
            ),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 6.0;
        final tileWidth = (constraints.maxWidth - spacing * 3) / 4;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final t in tiles) SizedBox(width: tileWidth, child: t),
          ],
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: compact ? 38 : 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? scheme.onSurface : null,
          borderRadius: BorderRadius.circular(compact ? 9 : 11),
          border: selected
              ? null
              : Border.all(color: scheme.onSurface.withValues(alpha: 0.28)),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontSize: 13,
            color: selected
                ? scheme.surface
                : scheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }
}
