import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../../l10n/strings.dart';

/// "‹ Back" on the left, an optional accent text action on the right.
class MemoNavBar extends StatelessWidget {
  const MemoNavBar({super.key, this.actionLabel, this.onAction});

  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MemoSpace.space2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text(S.commonBack),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

/// A round ink-6 icon button, 36 visual, 44 hit. [accent] fills it.
class MemoIconButton extends StatelessWidget {
  const MemoIconButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.accent = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    return IconButton(
      onPressed: onPressed,
      tooltip: label,
      icon: Icon(icon, size: 18),
      style: IconButton.styleFrom(
        fixedSize: const Size.square(36),
        minimumSize: const Size.square(MemoSpace.hitMin),
        tapTargetSize: MaterialTapTargetSize.padded,
        backgroundColor: accent ? c.accentText : c.ink6,
        foregroundColor: accent ? c.onAccent : c.ink,
      ),
    );
  }
}
