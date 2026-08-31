import 'package:flutter/material.dart';

/// One flat tag chip — memo Design System · 04 Components / "Tags".
/// Used both in the list's filter bar (with [selected]) and compose's
/// tag picker (with [dashed] for "+ New").
class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.label,
    this.dotColor,
    this.selected = false,
    this.dashed = false,
    this.onTap,
  });

  final String label;
  final Color? dotColor;
  final bool selected;
  final bool dashed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final bg = selected
        ? scheme.onSurface
        : (dashed
              ? Colors.transparent
              : scheme.onSurface.withValues(alpha: 0.06));
    final fg = selected
        ? scheme.surface
        : (dashed
              ? scheme.onSurface.withValues(alpha: 0.45)
              : scheme.onSurface.withValues(alpha: 0.7));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: dashed
              ? Border.all(color: scheme.onSurface.withValues(alpha: 0.28))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
