import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

/// The only circle in the system; the logo's ring, made tappable.
enum CheckState { idle, done, overdue }

class CheckControl extends StatelessWidget {
  const CheckControl({super.key, required this.state, this.onTap});

  final CheckState state;
  final VoidCallback? onTap;

  static const _size = 22.0;

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    return Semantics(
      button: true,
      checked: state == CheckState.done,
      label: state == CheckState.done ? 'Done' : 'Mark done',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.square(
          dimension: MemoSpace.hitMin,
          child: Center(
            child: CustomPaint(
              size: const Size.square(_size),
              painter: _RingPainter(state, c),
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
        canvas.drawCircle(center, radius + 0.75, Paint()..color = c.accent);
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
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.state != state || old.c != c;
}
