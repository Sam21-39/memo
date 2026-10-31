import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

/// Mono uppercase section label with an optional faint count. Time is the
/// hierarchy: these headers, not cards, organise the list.
class DaySectionHeader extends StatelessWidget {
  const DaySectionHeader({
    super.key,
    required this.label,
    this.count,
    this.emphasize = false,
  });

  final String label;
  final int? count;

  /// The Overdue header, in accent.
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    final style = MemoType.labelSmall.copyWith(
      color: emphasize ? c.accent : c.ink45,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MemoSpace.space1,
        0,
        MemoSpace.space1,
        MemoSpace.space2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label.toUpperCase(), style: style),
          if (count != null) Text('$count', style: style),
        ],
      ),
    );
  }
}
