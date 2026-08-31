import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_format.dart';
import '../../domain/entities/repeat_rule.dart';
import '../widgets/weekday_selector.dart';

/// Weekday sheet — memo Screens C · "Custom repeat".
/// Returns the picked weekdays, or null when dismissed.
Future<Set<int>?> showCustomRepeatSheet(
  BuildContext context, {
  required Set<int> initial,
  required DateTime timeOfDay,
}) {
  return showModalBottomSheet<Set<int>>(
    context: context,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.sheet),
      ),
    ),
    builder: (_) => _CustomRepeatSheet(initial: initial, timeOfDay: timeOfDay),
  );
}

class _CustomRepeatSheet extends StatefulWidget {
  const _CustomRepeatSheet({required this.initial, required this.timeOfDay});

  final Set<int> initial;
  final DateTime timeOfDay;

  @override
  State<_CustomRepeatSheet> createState() => _CustomRepeatSheetState();
}

class _CustomRepeatSheetState extends State<_CustomRepeatSheet> {
  late Set<int> _selected = {...widget.initial};

  static const _names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String get _summary {
    if (_selected.isEmpty) return 'Pick at least one day.';
    final days = (_selected.toList()..sort())
        .map((d) => _names[d - 1])
        .join(', ');
    final next = RepeatRule(
      RepeatType.weekly,
      weekdays: _selected,
    ).nextAfter(widget.timeOfDay);
    final nextLabel = next == null ? '—' : formatDate(next);
    return 'Rings at ${formatTime(widget.timeOfDay)} on $days. Next: $nextLabel.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenGutter,
          AppSpacing.md,
          AppSpacing.screenGutter,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('Repeat on', style: theme.textTheme.titleLarge),
                TextButton(
                  onPressed: _selected.isEmpty
                      ? null
                      : () => Navigator.of(context).pop(_selected),
                  child: Text(
                    'Done',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _selected.isEmpty
                          ? scheme.onSurface.withValues(alpha: 0.3)
                          : scheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            WeekdaySelector(
              selected: _selected,
              compact: false,
              onChanged: (next) => setState(() => _selected = next),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border.all(color: scheme.outline),
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
              child: Text(
                _summary,
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
