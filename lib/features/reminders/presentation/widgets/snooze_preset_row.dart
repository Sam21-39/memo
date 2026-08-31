import 'package:flutter/material.dart';

class SnoozePreset {
  const SnoozePreset(this.label, this.duration);
  final String label;

  /// Null for "Tomorrow" — caller resolves it to the next day's local time.
  final Duration? duration;
}

const defaultSnoozePresets = [
  SnoozePreset('10m', Duration(minutes: 10)),
  SnoozePreset('1h', Duration(hours: 1)),
  SnoozePreset('Tomorrow', null),
];

/// memo Design System · 04 Components / "Snooze presets".
/// Gated by the snooze flag at the call site.
class SnoozePresetRow extends StatelessWidget {
  const SnoozePresetRow({
    super.key,
    required this.onSelect,
    this.presets = defaultSnoozePresets,
  });

  final List<SnoozePreset> presets;
  final ValueChanged<SnoozePreset> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      children: [
        for (final preset in presets)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: preset == presets.last ? 0 : 8),
              child: OutlinedButton(
                onPressed: () => onSelect(preset),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
                child: Text(
                  preset.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontSize: 14,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
