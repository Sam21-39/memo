import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/ui/section_label.dart';

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
    final style = sectionLabelStyle(
      context,
    ).copyWith(color: emphasize ? c.accentText : c.ink70);
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
          Text(sectionLabelText(context, label), style: style),
          if (count != null) Text('$count', style: style),
        ],
      ),
    );
  }
}
