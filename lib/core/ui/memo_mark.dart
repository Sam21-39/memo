import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The logo: a ring in ink with the dot at two o'clock in accent. Drawn, not
/// an image, so it follows the theme. Geometry from mark-light.svg (100 box).
class MemoMark extends StatelessWidget {
  const MemoMark({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    return Semantics(
      label: 'Memō',
      image: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: _MarkPainter(c.ink, c.accent),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.ring, this.dot);
  final Color ring;
  final Color dot;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100;
    canvas
      ..drawCircle(
        Offset(50 * u, 50 * u),
        21 * u,
        Paint()
          ..color = ring
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5 * u,
      )
      ..drawCircle(Offset(64.85 * u, 35.15 * u), 7.6 * u, Paint()..color = dot);
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.ring != ring || old.dot != dot;
}

/// The empty-state ring: the logo ring at 2px, no dot, "00" in mono.
class EmptyRing extends StatelessWidget {
  const EmptyRing({super.key});

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: c.ink45, width: 2),
      ),
      child: Text(
        '00',
        style: MemoType.labelMedium.copyWith(fontSize: 20, color: c.ink45),
      ),
    );
  }
}
