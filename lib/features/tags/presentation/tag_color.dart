import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';

/// A tag is a bare string, so its dot colour is derived from the name.
///
/// ponytail: deterministic palette pick, not a user choice. Add a tags table
/// when someone actually wants to recolour one.
Color tagColor(String tag) {
  // Sum of code units, not String.hashCode — that is not stable across runs.
  var sum = 0;
  for (final unit in tag.trim().toLowerCase().codeUnits) {
    sum += unit;
  }
  return MemoTagPalette.colors[sum % MemoTagPalette.colors.length];
}
