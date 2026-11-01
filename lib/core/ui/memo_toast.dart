import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The one toast: ink pill, on-ink text, accent action. Positioned by the
/// caller above the bottom bar; only one at a time.
class MemoToast extends StatelessWidget {
  const MemoToast({
    super.key,
    required this.message,
    required this.action,
    required this.onAction,
  });

  final String message;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        height: MemoSpace.hitMin,
        padding: const EdgeInsets.only(
          left: MemoSpace.space4,
          right: MemoSpace.space1,
        ),
        decoration: BoxDecoration(
          color: c.ink,
          borderRadius: BorderRadius.circular(MemoRadius.pill),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: MemoType.body.copyWith(
                  color: c.onInk,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: MemoColors.dark.accent,
              ),
              child: Text(action),
            ),
          ],
        ),
      ),
    );
  }
}
