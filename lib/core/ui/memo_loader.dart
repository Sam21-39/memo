import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../../l10n/l10n.dart';

/// The logo ring, spinning: ink-45 ring with an accent arc. 22 inline, 44 on
/// an empty screen. Paired with one mono word ("Listening", "Saving").
class MemoLoader extends StatefulWidget {
  const MemoLoader({super.key, this.size = 22, this.label});

  final double size;
  final String? label;

  @override
  State<MemoLoader> createState() => _MemoLoaderState();
}

class _MemoLoaderState extends State<MemoLoader>
    with SingleTickerProviderStateMixin {
  late final _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    final ring = RotationTransition(
      turns: _spin,
      child: SizedBox.square(
        dimension: widget.size,
        child: CircularProgressIndicator(
          value: 0.25,
          strokeWidth: widget.size > 30 ? 2 : 1.5,
          color: c.accent,
          backgroundColor: c.ink45,
        ),
      ),
    );
    final label = widget.label;
    return Semantics(
      label: label ?? context.l10n.commonWorking,
      liveRegion: true,
      child: label == null
          ? ring
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ring,
                const SizedBox(width: MemoSpace.space2),
                Text(
                  label,
                  style: MemoType.labelMedium.copyWith(color: c.ink70),
                ),
              ],
            ),
    );
  }
}
