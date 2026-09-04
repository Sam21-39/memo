import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/feature_flags/feature_flags.dart';
import '../../../../core/feature_flags/feature_gate.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_format.dart';
import '../../../tags/presentation/tag_color.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/repeat_rule.dart';
import '../cubit/reminders_cubit.dart';
import '../cubit/reminders_state.dart';
import '../widgets/key_value_row.dart';
import '../widgets/section_card.dart';
import '../widgets/snooze_preset_row.dart';
import 'reminder_compose_page.dart';

/// memo Screens C · "Detail" — reached from a row or a notification tap.
class ReminderDetailPage extends StatelessWidget {
  const ReminderDetailPage({super.key, required this.reminderId});

  final String reminderId;

  @override
  Widget build(BuildContext context) {
    final flags = sl<FeatureFlags>();

    return BlocBuilder<RemindersCubit, RemindersState>(
      builder: (context, state) {
        final reminder = state.reminders
            .where((r) => r.id == reminderId)
            .firstOrNull;

        // Deleted from under us (or a stale notification payload).
        if (reminder == null) {
          return const Scaffold(
            body: Center(child: Text('This reminder no longer exists.')),
          );
        }

        final theme = Theme.of(context);
        final scheme = theme.colorScheme;

        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
              children: [
                _TopBar(reminder: reminder),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenGutter,
                    28,
                    AppSpacing.screenGutter,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FeatureGate(
                        enabled: flags.tags && reminder.tag != null,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: tagColor(reminder.tag ?? ''),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                (reminder.tag ?? '').toUpperCase(),
                                style: theme.textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        reminder.title,
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 32,
                          height: 1.12,
                        ),
                      ),
                      if (reminder.note != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          reminder.note!,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontSize: 16,
                            height: 1.55,
                            fontWeight: FontWeight.w400,
                            color: scheme.onSurface.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                      const SizedBox(height: 26),
                      SectionCard(
                        children: [
                          KeyValueRow(
                            label: 'Next',
                            child: Text(
                              _nextLabel(reminder),
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontSize: 15,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                          if (flags.repeatReminders)
                            KeyValueRow(
                              label: 'Repeat',
                              child: Text(
                                _repeatLabel(reminder.repeat),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontSize: 15,
                                  color: scheme.onSurface,
                                ),
                              ),
                            ),
                          KeyValueRow(
                            label: 'Created',
                            child: Text(
                              formatLongDate(reminder.createdAt),
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      FeatureGate(
                        enabled: flags.snooze && !reminder.isDone,
                        child: Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SNOOZE',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              SnoozePresetRow(
                                onSelect: (preset) => context
                                    .read<RemindersCubit>()
                                    .snooze(reminder, by: preset.duration),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      OutlinedButton(
                        onPressed: () => _confirmDelete(context, reminder),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFA33A2A),
                        ),
                        child: const Text('Delete reminder'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _nextLabel(Reminder reminder) {
    if (reminder.isDone) return 'Done';
    final now = DateTime.now();
    final at = reminder.scheduledAt;
    if (isSameDay(at, now)) return 'Today · ${formatTime(at)}';
    return '${formatDate(at)} · ${formatTime(at)}';
  }

  static String _repeatLabel(RepeatRule repeat) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    switch (repeat.type) {
      case RepeatType.none:
        return 'Never';
      case RepeatType.daily:
        return 'Daily';
      case RepeatType.weekly:
        final days = (repeat.weekdays.toList()..sort())
            .map((d) => names[d - 1])
            .join(', ');
        return days.isEmpty ? 'Weekly' : days;
    }
  }

  static Future<void> _confirmDelete(
    BuildContext context,
    Reminder reminder,
  ) async {
    final cubit = context.read<RemindersCubit>();
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete reminder?'),
        content: Text(
          '"${reminder.title}" will be removed. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await cubit.delete(reminder.id);
    navigator.pop();
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.reminder});

  final Reminder reminder;

  Future<void> _edit(BuildContext context) async {
    final cubit = context.read<RemindersCubit>();
    final edited = await Navigator.of(context).push<Reminder>(
      MaterialPageRoute(
        builder: (_) => ReminderComposePage(
          existing: reminder,
          knownTags: cubit.state.tagsInUse,
        ),
      ),
    );
    if (edited != null) await cubit.save(edited);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        6,
        AppSpacing.screenGutter,
        0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Upcoming'),
            style: TextButton.styleFrom(
              foregroundColor: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          TextButton(
            onPressed: () => _edit(context),
            child: Text(
              'Edit',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
