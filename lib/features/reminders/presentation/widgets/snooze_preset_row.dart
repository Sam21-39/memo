import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../l10n/l10n.dart';

class SnoozePreset {
  SnoozePreset(this.label, this.duration);
  final String Function(AppLocalizations) label;

  /// Null for "Tomorrow": the next day at the reminder's own time.
  final Duration? duration;
}

final defaultSnoozePresets = [
  SnoozePreset((l) => l.snoozeTenMinutes, const Duration(minutes: 10)),
  SnoozePreset((l) => l.snoozeOneHour, const Duration(hours: 1)),
  SnoozePreset((l) => l.dateTomorrow, null),
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
                preset.label(context.l10n),
                style: MemoType.labelMedium.copyWith(color: c.ink),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
