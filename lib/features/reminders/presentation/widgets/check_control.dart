import 'package:flutter/material.dart';

/// "The only circle in the system" — memo Design System · 04 Components.
enum CheckState { idle, done, overdue }

class CheckControl extends StatelessWidget {
  const CheckControl({
    super.key,
    required this.state,
    this.onTap,
    this.size = 26,
  });

  final CheckState state;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.35);

    Widget circle;
    switch (state) {
      case CheckState.done:
        circle = DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check, size: size * 0.54, color: scheme.onPrimary),
        );
      case CheckState.overdue:
        circle = _DashedCircle(
          diameter: size,
          color: scheme.primary.withValues(alpha: 0.45),
        );
      case CheckState.idle:
        circle = DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: muted, width: 1.5),
          ),
        );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size + 18,
        height: size + 18,
        child: Center(
          child: SizedBox(width: size, height: size, child: circle),
        ),
      ),
    );
  }
}

class _DashedCircle extends StatelessWidget {
  const _DashedCircle({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(diameter),
      painter: _DashedCirclePainter(color),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final radius = size.width / 2 - 1;
    final center = size.center(Offset.zero);
    const dashCount = 10;
    const gapFraction = 0.45;
    for (var i = 0; i < dashCount; i++) {
      final startAngle = (i / dashCount) * 2 * 3.14159265;
      final sweep = (2 * 3.14159265 / dashCount) * (1 - gapFraction);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter old) => old.color != color;
}
