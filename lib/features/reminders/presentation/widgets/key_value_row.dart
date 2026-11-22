import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

/// Label left in body, value right in a mono pill. Card owns the border.
class KeyValueRow extends StatelessWidget {
  const KeyValueRow({
    super.key,
    required this.label,
    required this.child,
    this.onTap,
    this.destructive = false,
  });

  final String label;

  /// Label in the destructive colour, e.g. Delete.
  final bool destructive;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MemoSpace.space4,
            vertical: MemoSpace.space2,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: MemoType.bodyLarge.copyWith(
                    color: destructive ? c.destructive : c.ink,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              child is Flexible ? child : Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// A mono value in a pill. [active] inverts it: the field being edited, or a
/// switch that is on.
class PillValue extends StatelessWidget {
  const PillValue(this.text, {super.key, this.active = false});

  final String text;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 30),
      padding: const EdgeInsets.symmetric(
        horizontal: MemoSpace.space3,
        vertical: MemoSpace.space1,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? c.ink : c.ink6,
        borderRadius: BorderRadius.circular(MemoRadius.pill),
      ),
      child: Text(
        text,
        style: MemoType.labelMedium.copyWith(color: active ? c.onInk : c.ink),
      ),
    );
  }
}
