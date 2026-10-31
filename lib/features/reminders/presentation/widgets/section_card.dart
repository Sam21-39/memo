import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

/// Grouped rows on one surface: hairline border, hairline separators, no
/// shadow. [tinted] is the overdue card's accent-soft ground.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.children, this.tinted = false});

  final List<Widget> children;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: tinted ? c.accentSoft : c.surface,
        border: Border.all(color: c.hairline),
        borderRadius: BorderRadius.circular(MemoRadius.card),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(color: c.hairline),
            children[i],
          ],
        ],
      ),
    );
  }
}
