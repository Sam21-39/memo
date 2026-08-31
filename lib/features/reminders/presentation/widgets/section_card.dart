import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Grouped rows on one surface, hairline-separated. No drop shadow —
/// elevation is a hairline and a change of surface.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.children,
    this.background,
    this.borderColor,
  });

  final List<Widget> children;
  final Color? background;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: background ?? scheme.surface,
        border: Border.all(color: borderColor ?? scheme.outline),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: scheme.outline.withValues(alpha: 0.6),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}
