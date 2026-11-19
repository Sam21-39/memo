import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../l10n/strings.dart';

class SnoozePreset {
  const SnoozePreset(this.label, this.duration);
  final String label;

  /// Null for "Tomorrow": the next day at the reminder's own time.
  final Duration? duration;
}

const defaultSnoozePresets = [
  SnoozePreset(S.snoozeTenMinutes, Duration(minutes: 10)),
  SnoozePreset(S.snoozeOneHour, Duration(hours: 1)),
  SnoozePreset(S.dateTomorrow, null),
];

/// Three equal outlined buttons, 44 high, mono values. Order is fixed.
class SnoozePresetRow extends StatelessWidget {
  const SnoozePresetRow({super.key, required this.onSelect});

  final ValueChanged<SnoozePreset> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    return Row(
      children: [
        for (final preset in defaultSnoozePresets) ...[
          if (preset != defaultSnoozePresets.first)
            const SizedBox(width: MemoSpace.space2),
          Expanded(
            child: OutlinedButton(
              onPressed: () => onSelect(preset),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(MemoSpace.hitMin),
                padding: EdgeInsets.zero,
              ),
              child: Text(
                preset.label,
                style: MemoType.labelMedium.copyWith(color: c.ink),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
