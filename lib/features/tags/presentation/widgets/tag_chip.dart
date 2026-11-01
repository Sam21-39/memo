import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

/// One flat tag chip: 30 high, radius-chip, mono label. Idle ink-6 with a
/// colour dot, selected inverts, [dashed] is "+ New".
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
    final c = MemoColors.of(context);
    final fg = selected ? c.onInk : (dashed ? c.ink70 : c.ink);
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: MemoSpace.space3),
          decoration: BoxDecoration(
            color: selected ? c.ink : (dashed ? null : c.ink6),
            borderRadius: BorderRadius.circular(MemoRadius.chip),
            border: dashed ? Border.all(color: c.ink45) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dotColor != null) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: selected ? c.onInk : dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(label, style: MemoType.labelMedium.copyWith(color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}
