import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'chrome_mode.dart';
import 'glass_backend.dart';

enum ChromeShape { bar, pill, circle, sheet }

/// The only surface for anything that floats over content: bars, pills,
/// round buttons on chrome, sheets. Glass or solid comes from
/// [ChromeModeScope]; shape, radius and layout never change between them.
class MemoChrome extends StatelessWidget {
  const MemoChrome({
    super.key,
    required this.shape,
    required this.child,
    this.solid = false,
  });

  final ChromeShape shape;
  final Widget child;

  /// Force solid: an expanded capture bar carries chips that must read over
  /// the dimmed list.
  final bool solid;

  BorderRadius get _radius => switch (shape) {
    ChromeShape.bar => BorderRadius.circular(MemoRadius.chrome),
    ChromeShape.pill ||
    ChromeShape.circle => BorderRadius.circular(MemoRadius.pill),
    ChromeShape.sheet => const BorderRadius.vertical(
      top: Radius.circular(MemoRadius.sheet),
    ),
  };

  @override
  Widget build(BuildContext context) {
    if (!solid && ChromeModeScope.of(context) == ChromeMode.glass) {
      return GlassSurface(borderRadius: _radius, child: child);
    }
    final c = MemoColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.chromeFill,
        borderRadius: _radius,
        border: shape == ChromeShape.sheet
            ? Border(top: BorderSide(color: c.hairline))
            : Border.all(color: c.hairline),
      ),
      child: ClipRRect(borderRadius: _radius, child: child),
    );
  }
}
