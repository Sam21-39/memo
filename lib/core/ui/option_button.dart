import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// One choice among a few, e.g. "8:00 AM" or "8:00 PM": hairline outline,
/// ink fill when [selected]. 44 px high at least.
class OptionButton extends StatelessWidget {
  const OptionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: MemoSpace.hitMin,
            minWidth: MemoSpace.hitMin,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: selected ? c.ink : null,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.hairline),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MemoSpace.space4,
                vertical: MemoSpace.space2,
              ),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: MemoType.labelMedium.copyWith(
                    fontSize: 15,
                    color: selected ? c.onInk : c.ink,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
