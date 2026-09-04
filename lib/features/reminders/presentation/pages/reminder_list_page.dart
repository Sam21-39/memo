import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/feature_flags/feature_flags.dart';
import '../../../../core/feature_flags/feature_gate.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_format.dart';
import '../../../tags/presentation/tag_color.dart';
import '../../../tags/presentation/widgets/tag_chip.dart';
import '../../domain/entities/reminder.dart';
import '../cubit/reminders_cubit.dart';
import '../cubit/reminders_state.dart';
import '../day_grouping.dart';
import '../widgets/check_control.dart';
import '../widgets/day_section_header.dart';
import '../widgets/reminder_row.dart';
import '../widgets/section_card.dart';
import '../widgets/swipeable_reminder_row.dart';
import 'reminder_compose_page.dart';
import 'reminder_detail_page.dart';
import 'reminders_done_page.dart';
import 'settings_page.dart';

/// memo Screens B · "Upcoming", with the first-run empty state from A.
class ReminderListPage extends StatelessWidget {
  const ReminderListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final flags = sl<FeatureFlags>();

    return BlocBuilder<RemindersCubit, RemindersState>(
      builder: (context, state) {
        final now = DateTime.now();
        final grouped = groupByDay(state.upcoming, now);

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(
                      scheduled: state.upcoming.length,
                      overdue: grouped.overdue.length,
                      // "0 scheduled" would contradict both other states.
                      showCounts: state.status == RemindersStatus.ready,
                    ),
                    FeatureGate(
                      enabled: flags.tags && state.tagsInUse.isNotEmpty,
                      child: _TagFilterBar(
                        tags: state.tagsInUse,
                        selected: state.tagFilter,
                      ),
                    ),
                    Expanded(
                      child: switch (state.status) {
                        // An empty list and a failed read look identical
                        // otherwise — for a reminder app that reads as
                        // "nothing scheduled" when reminders exist.
                        RemindersStatus.loading => const SizedBox.shrink(),
                        RemindersStatus.failure => const _FailureState(),
                        RemindersStatus.ready when grouped.isEmpty =>
                          const _EmptyState(),
                        RemindersStatus.ready => _ReminderList(
                          grouped: grouped,
                          now: now,
                        ),
                      },
                    ),
                  ],
                ),
                const _BottomBar(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.scheduled,
    required this.overdue,
    required this.showCounts,
  });

  final int scheduled;
  final int overdue;
  final bool showCounts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final parts = <String>[
      if (showCounts) ...[
        '$scheduled scheduled',
        if (overdue > 0) '$overdue overdue',
      ],
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenGutter,
        AppSpacing.sm,
        AppSpacing.screenGutter,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Upcoming', style: theme.textTheme.displayLarge),
                const SizedBox(height: 2),
                Text(
                  parts.join(' · '),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontSize: 12,
                    color: scheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsPage())),
            icon: const Icon(Icons.settings_outlined, size: 18),
            style: IconButton.styleFrom(
              fixedSize: const Size.square(38),
              side: BorderSide(color: scheme.outline),
              foregroundColor: scheme.onSurface.withValues(alpha: 0.7),
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagFilterBar extends StatelessWidget {
  const _TagFilterBar({required this.tags, required this.selected});

  final List<String> tags;
  final String? selected;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RemindersCubit>();
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenGutter,
          18,
          AppSpacing.screenGutter,
          0,
        ),
        children: [
          TagChip(
            label: 'All',
            selected: selected == null,
            onTap: () => cubit.filterByTag(null),
          ),
          for (final tag in tags) ...[
            const SizedBox(width: 7),
            TagChip(
              label: tag,
              dotColor: tagColor(tag),
              selected: tag == selected,
              onTap: () => cubit.filterByTag(tag == selected ? null : tag),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReminderList extends StatelessWidget {
  const _ReminderList({required this.grouped, required this.now});

  final GroupedReminders grouped;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Opaque, not translucent: each row paints this behind itself so it can
    // slide over the swipe actions without them showing through.
    final overdueSurface = Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.06),
      scheme.surface,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenGutter,
        26,
        AppSpacing.screenGutter,
        120, // clears the floating compose bar
      ),
      children: [
        if (grouped.overdue.isNotEmpty) ...[
          const DaySectionHeader(label: 'Overdue', emphasize: true),
          SectionCard(
            background: overdueSurface,
            borderColor: scheme.primary.withValues(alpha: 0.22),
            children: [
              for (final reminder in grouped.overdue)
                _Row(reminder: reminder, now: now, background: overdueSurface),
            ],
          ),
          const SizedBox(height: 26),
        ],
        for (final group in grouped.days) ...[
          DaySectionHeader(
            label: dayHeaderLabel(group.day, now),
            count: group.reminders.length,
          ),
          SectionCard(
            children: [
              for (final reminder in group.reminders)
                _Row(reminder: reminder, now: now),
            ],
          ),
          const SizedBox(height: 26),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.reminder, required this.now, this.background});

  final Reminder reminder;
  final DateTime now;
  final Color? background;

  Future<void> _openDetail(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<RemindersCubit>(),
          child: ReminderDetailPage(reminderId: reminder.id),
        ),
      ),
    );
  }

  void _complete(BuildContext context) {
    final cubit = context.read<RemindersCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final wasRepeating = reminder.repeat.repeats;
    cubit.complete(reminder);

    // ponytail: SnackBar instead of the design's inline 5s Undo band — same
    // affordance and timeout, none of the custom row state.
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          wasRepeating ? 'Moved to next occurrence' : 'Marked done',
        ),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => cubit.save(reminder),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final flags = sl<FeatureFlags>();
    final cubit = context.read<RemindersCubit>();
    final isOverdue = reminder.isOverdue(now);

    return SwipeableReminderRow(
      background: background,
      onComplete: () => _complete(context),
      onSnooze: flags.snooze
          ? () => cubit.snooze(reminder, by: const Duration(minutes: 10))
          : null,
      onDelete: () => cubit.delete(reminder.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: ReminderRow(
          title: reminder.title,
          state: isOverdue ? CheckState.overdue : CheckState.idle,
          time: formatTime(reminder.scheduledAt),
          overdueLabel: isOverdue
              ? '${formatDate(reminder.scheduledAt)} ${formatTime(reminder.scheduledAt)} · '
                    '${formatLateness(now.difference(reminder.scheduledAt))}'
              : null,
          tagLabel: flags.tags ? reminder.tag : null,
          tagColor: reminder.tag == null ? null : tagColor(reminder.tag!),
          repeats: flags.repeatReminders && reminder.repeat.repeats,
          onCheckTap: () => _complete(context),
          onTap: () => _openDetail(context),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(38, 0, 38, 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: scheme.onSurface.withValues(alpha: 0.28),
                  width: 1.5,
                ),
              ),
              child: Text(
                '00',
                style: theme.textTheme.labelMedium?.copyWith(fontSize: 13),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Nothing scheduled',
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 20),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add the first thing you keep forgetting. '
              'Bins, pills, that call.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                height: 1.55,
                color: scheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FailureState extends StatelessWidget {
  const _FailureState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(38, 0, 38, 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Couldn't load your reminders",
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 20),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'They are still saved on this device. '
              'Alarms already scheduled keep firing.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                height: 1.55,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton(
              onPressed: () => context.read<RemindersCubit>().load(),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar();

  Future<void> _compose(BuildContext context) async {
    final cubit = context.read<RemindersCubit>();
    final created = await Navigator.of(context).push<Reminder>(
      MaterialPageRoute(
        builder: (_) => ReminderComposePage(knownTags: cubit.state.tagsInUse),
      ),
    );
    if (created != null) await cubit.save(created);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canvas = Theme.of(context).scaffoldBackgroundColor;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenGutter,
          AppSpacing.lg,
          AppSpacing.screenGutter,
          MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [canvas, canvas, canvas.withValues(alpha: 0)],
            stops: const [0, 0.62, 1],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _compose(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('New reminder'),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 52,
              height: 52,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<RemindersCubit>(),
                      child: const RemindersDonePage(),
                    ),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: scheme.surface,
                  minimumSize: const Size.square(52),
                ),
                child: Icon(
                  Icons.check,
                  size: 20,
                  color: scheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
