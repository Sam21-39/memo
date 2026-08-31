import 'package:flutter/material.dart';

/// Mono, uppercase section label — "Time is the hierarchy": day headers,
/// not cards, organise the list. memo Design System · Principle 01.
class DaySectionHeader extends StatelessWidget {
  const DaySectionHeader({
    super.key,
    required this.label,
    this.count,
    this.emphasize = false,
  });

  final String label;
  final int? count;

  /// True for the "Overdue" header — rendered in accent color.
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = emphasize ? scheme.primary : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(color: color),
          ),
          if (count != null)
            Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.25),
                letterSpacing: 0,
              ),
            ),
        ],
      ),
    );
  }
}
