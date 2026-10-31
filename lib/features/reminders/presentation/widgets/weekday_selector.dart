import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

const _labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Seven tiles, Mon = 1 .. Sun = 7 ([DateTime.weekday]); selected inverts.
class WeekdaySelector extends StatelessWidget {
  const WeekdaySelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    return Row(
      children: [
        for (var day = 1; day <= 7; day++) ...[
          if (day > 1) const SizedBox(width: 6),
          Expanded(
            child: Semantics(
              button: true,
              selected: selected.contains(day),
              child: GestureDetector(
                onTap: () => onChanged(
                  selected.contains(day)
                      ? ({...selected}..remove(day))
                      : {...selected, day},
                ),
                child: Container(
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected.contains(day) ? c.ink : c.ink6,
                    borderRadius: BorderRadius.circular(MemoRadius.chip),
                  ),
                  child: Text(
                    _labels[day - 1],
                    style: MemoType.labelMedium.copyWith(
                      fontWeight: FontWeight.w500,
                      color: selected.contains(day) ? c.onInk : c.ink70,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
