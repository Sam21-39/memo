import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Pure-Flutter glass: tint over a backdrop blur, a stroke hairline and a
/// specular along the top edge. M6 may swap this body for native glass after
/// a device test; the signature stays.
///
/// Only [MemoChrome] may use this. Never place it inside a scrollable.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.borderRadius,
    required this.child,
  });

  final BorderRadius borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: MemoGlass.blurChrome,
          sigmaY: MemoGlass.blurChrome,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.chromeTint,
            borderRadius: borderRadius,
            border: Border.all(
              color: c.chromeStroke,
              width: MemoGlass.strokeChrome,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: FractionallySizedBox(
                    alignment: Alignment.topCenter,
                    heightFactor: 0.35,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            c.chromeHighlight.withValues(
                              alpha: c.chromeHighlight.a / 2,
                            ),
                            c.chromeHighlight.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
