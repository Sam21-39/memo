import 'package:flutter/material.dart';

/// Wraps an optional capability so a flag flip never touches call sites.
/// Off-states collapse — they never leave an empty slot.
class FeatureGate extends StatelessWidget {
  const FeatureGate({
    required this.enabled,
    required this.child,
    this.fallback,
    super.key,
  });

  final bool enabled;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) =>
      enabled ? child : (fallback ?? const SizedBox.shrink());
}
