import 'package:flutter/material.dart';

/// Label/value row for grouped cards — Date, Time, Next, Repeat, Created.
/// memo Design System · Screens "New reminder" / "Detail".
class KeyValueRow extends StatelessWidget {
  const KeyValueRow({
    super.key,
    required this.label,
    required this.child,
    this.onTap,
  });

  final String label;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

/// The dark/light rounded pill wrapping a mono value — e.g. "09:30", "Thu 27 Aug".
class PillValue extends StatelessWidget {
  const PillValue(this.text, {super.key, this.emphasized = false});

  final String text;

  /// True for the currently-active field (e.g. Time while editing).
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: emphasized
            ? scheme.onSurface
            : scheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          fontSize: 14,
          color: emphasized ? scheme.surface : scheme.onSurface,
        ),
      ),
    );
  }
}
