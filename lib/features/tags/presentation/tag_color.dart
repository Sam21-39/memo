import 'package:flutter/material.dart';

/// v1 stores a tag as a bare string (schema §4.4 has no tags table), so the
/// dot colour is derived from the name rather than stored.
///
/// ponytail: deterministic palette pick, not a user choice. Add a tags table
/// when someone actually wants to recolour one.
const tagPalette = [
  Color(0xFFFF5A5F), // accent
  Color(0xFF5C7A6A), // green
  Color(0xFFC9A15F), // gold
  Color(0xFF6F7F9A), // slate
  Color(0xFF8A6F84), // plum
];

Color tagColor(String tag) {
  // Sum of code units, not String.hashCode — that is not stable across runs.
  var sum = 0;
  for (final unit in tag.trim().toLowerCase().codeUnits) {
    sum += unit;
  }
  return tagPalette[sum % tagPalette.length];
}
