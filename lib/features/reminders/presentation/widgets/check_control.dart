import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/ui/motion.dart';
import '../../../../l10n/l10n.dart';

/// The only circle in the system; the logo's ring, made tappable.
enum CheckState { idle, done, overdue }

class CheckControl extends StatelessWidget {
  const CheckControl({
    super.key,
    required this.state,
    this.onTap,
    this.semanticLabel,
  });

  final CheckState state;
  final VoidCallback? onTap;

  /// "Mark {title} done"; falls back to the generic label.
  final String? semanticLabel;

  static const _size = 22.0;

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    final done = state == CheckState.done;
    final d = motion(context, MemoMotion.base);
    return Semantics(
      button: true,
      checked: done,
      label: done
          ? context.l10n.commonDone
          : semanticLabel ?? context.l10n.commonMarkDone,
      child: GestureDetector(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap!();
              },
        behavior: HitTestBehavior.opaque,
        child: SizedBox.square(
          dimension: MemoSpace.hitMin,
          child: Center(
            child: SizedBox.square(
              dimension: _size,
              child: Stack(
                children: [
                  if (!done)
                    CustomPaint(
                      size: const Size.square(_size),
                      painter: _RingPainter(state, c),
                    ),
                  // Disc scales in, tick fades in after it.
                  AnimatedScale(
                    scale: done ? 1 : 0.6,
                    duration: d,
                    curve: MemoMotion.curve,
                    child: AnimatedOpacity(
                      opacity: done ? 1 : 0,
                      duration: d,
                      curve: MemoMotion.curve,
                      child: CustomPaint(
                        size: const Size.square(_size),
                        painter: _DiscPainter(c),
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: done ? 1 : 0,
                    duration: d,
                    curve: MemoMotion.curve,
                    child: CustomPaint(
                      size: const Size.square(_size),
                      painter: _TickPainter(c),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.state, this.c);
  final CheckState state;
  final MemoColors c;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 0.75;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    switch (state) {
      case CheckState.idle:
        canvas.drawCircle(center, radius, stroke..color = c.ink45);
      case CheckState.overdue:
        stroke.color = c.accent;
        const dashes = 12;
        const sweep = 2 * math.pi / dashes;
        for (var i = 0; i < dashes; i++) {
          canvas.drawArc(
            Rect.fromCircle(center: center, radius: radius),
            i * sweep,
            sweep * 0.55,
            false,
            stroke,
          );
        }
      case CheckState.done:
        break;
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.state != state || old.c != c;
}

class _DiscPainter extends CustomPainter {
  _DiscPainter(this.c);
  final MemoColors c;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawCircle(
    size.center(Offset.zero),
    size.width / 2,
    Paint()..color = c.accent,
  );

  @override
  bool shouldRepaint(_DiscPainter old) => old.c != c;
}

class _TickPainter extends CustomPainter {
  _TickPainter(this.c);
  final MemoColors c;

  @override
  void paint(Canvas canvas, Size size) {
    final tick = Path()
      ..moveTo(size.width * 0.3, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.66)
      ..lineTo(size.width * 0.71, size.height * 0.37);
    canvas.drawPath(
      tick,
      Paint()
        ..color = c.onAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_TickPainter old) => old.c != c;
}
