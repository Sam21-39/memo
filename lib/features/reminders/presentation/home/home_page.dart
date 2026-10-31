import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di.dart';
import '../../../../core/feature_flags/feature_flags.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/ui/memo_mark.dart';
import '../../../../core/ui/memo_nav_bar.dart';
import '../../../../core/ui/memo_toast.dart';
import '../../../../core/utils/date_format.dart';
import '../../../tags/presentation/tag_color.dart';
import '../../../tags/presentation/widgets/tag_chip.dart';
import '../../domain/entities/reminder.dart';
import '../day_grouping.dart';
import '../widgets/check_control.dart';
import '../widgets/day_section_header.dart';
import '../widgets/reminder_row.dart';
import '../widgets/section_card.dart';
import '../widgets/swipeable_reminder_row.dart';
import 'capture_bar.dart';
import 'capture_cubit.dart';
import 'home_cubit.dart';
import 'home_state.dart';

/// Artboards Home-Empty, Home-List, Home-Filter-Toast, Home-Dark,
/// Swipe-States.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Time moves while the app sleeps: overdue sections and "2h late" are
  // only as fresh as the last build.
  late final _lifecycle = AppLifecycleListener(
    onResume: () => context.read<HomeCubit>().load(),
  );

  @override
  void initState() {
    super.initState();
    _lifecycle;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flags = sl<FeatureFlags>();
    return BlocConsumer<HomeCubit, HomeState>(
      listenWhen: (a, b) => b is HomeReady && b.error != null,
      listener: (context, state) {
        final error = (state as HomeReady).error!;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error)));
        context.read<HomeCubit>().clearError();
      },
      builder: (context, state) {
        final now = DateTime.now();
        final ready = state is HomeReady ? state : null;
        final grouped = groupByDay(ready?.upcoming ?? const [], now);
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(ready: ready, overdue: grouped.overdue.length),
                    if (flags.tags && (ready?.tagsInUse.isNotEmpty ?? false))
                      _TagFilterBar(state: ready!),
                    Expanded(
                      child: switch (state) {
                        HomeLoading() => const SizedBox.shrink(),
                        HomeFailure() => const _FailureState(),
                        HomeReady() when grouped.isEmpty => const _EmptyState(),
                        HomeReady() => _ReminderList(
                          grouped: grouped,
                          now: now,
                        ),
                      },
                    ),
                  ],
                ),
                if (ready?.undo != null)
                  Positioned(
                    left: MemoSpace.gutter,
                    right: MemoSpace.gutter,
                    bottom:
                        MediaQuery.paddingOf(context).bottom +
                        MemoSpace.barHeight +
                        MemoSpace.space8,
                    child: MemoToast(
                      message: '${ready!.undo!.title} done',
                      action: 'Undo',
                      onAction: context.read<HomeCubit>().undo,
                    ),
                  ),
                // Expanded capture dims the list; a tap outside closes the
                // keyboard, or the bar itself when nothing was typed.
                BlocBuilder<CaptureCubit, CaptureState>(
                  buildWhen: (a, b) => a.expanded != b.expanded,
                  builder: (context, capture) => capture.expanded
                      ? Positioned.fill(
                          child: GestureDetector(
                            onTap: () {
                              FocusScope.of(context).unfocus();
                              final cubit = context.read<CaptureCubit>();
                              if (cubit.state.text.trim().isEmpty &&
                                  !cubit.state.hasClip) {
                                cubit.discard();
                              }
                            },
                            child: ColoredBox(color: MemoColors.scrim),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: CaptureBar(knownTags: ready?.tagsInUse ?? const []),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.ready, required this.overdue});

  final HomeReady? ready;
  final int overdue;

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    final scheduled = ready?.upcoming.length ?? 0;
    final summary = ready == null
        ? ''
        : scheduled == 0
        ? 'Nothing scheduled'
        : [
            '$scheduled scheduled',
            if (overdue > 0) '$overdue overdue',
          ].join(' · ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MemoSpace.gutter,
        MemoSpace.space4,
        MemoSpace.space3,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Memō',
                    style: MemoType.display.copyWith(color: c.ink),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  summary.toUpperCase(),
                  style: MemoType.labelSmall.copyWith(color: c.ink45),
                ),
              ],
            ),
          ),
          MemoIconButton(
            icon: Icons.check_rounded,
            label: 'Done',
            onPressed: () => context.push('/done'),
          ),
          MemoIconButton(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
    );
  }
}

class _TagFilterBar extends StatelessWidget {
  const _TagFilterBar({required this.state});

  final HomeReady state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HomeCubit>();
    final selected = state.tagFilter;
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          MemoSpace.gutter,
          MemoSpace.space4,
          MemoSpace.gutter,
          0,
        ),
        children: [
          TagChip(
            label: 'All',
            selected: selected == null,
            onTap: () => cubit.filterByTag(null),
          ),
          for (final tag in state.tagsInUse) ...[
            const SizedBox(width: MemoSpace.space2),
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
    final c = MemoColors.of(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(
        MemoSpace.gutter,
        MemoSpace.space6,
        MemoSpace.gutter,
        // Clears the capture bar and its fade.
        MemoSpace.barHeight * 2 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        if (grouped.overdue.isNotEmpty) ...[
          DaySectionHeader(
            label: 'Overdue',
            count: grouped.overdue.length,
            emphasize: true,
          ),
          SectionCard(
            tinted: true,
            children: [
              for (final r in grouped.overdue)
                _Row(
                  key: ValueKey(r.id),
                  reminder: r,
                  now: now,
                  background: c.accentSoft,
                ),
            ],
          ),
          const SizedBox(height: MemoSpace.space6),
        ],
        for (final group in grouped.days) ...[
          DaySectionHeader(
            label: dayHeaderLabel(group.day, now),
            count: group.reminders.length,
          ),
          SectionCard(
            children: [
              for (final r in group.reminders)
                _Row(key: ValueKey(r.id), reminder: r, now: now),
            ],
          ),
          const SizedBox(height: MemoSpace.space6),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.reminder,
    required this.now,
    this.background,
  });

  final Reminder reminder;
  final DateTime now;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final flags = sl<FeatureFlags>();
    final cubit = context.read<HomeCubit>();
    final overdue = reminder.isOverdue(now);
    final tag = flags.tags ? reminder.tag : null;
    return SwipeableReminderRow(
      background: background,
      onComplete: () => cubit.complete(reminder),
      onSnooze: flags.snooze
          ? () => cubit.snooze(reminder, by: const Duration(minutes: 10))
          : null,
      onDelete: () => cubit.delete(reminder.id),
      child: ReminderRow(
        title: reminder.title,
        state: overdue ? CheckState.overdue : CheckState.idle,
        trailing: overdue
            ? formatLateness(now.difference(reminder.dueAt))
            : formatTime(reminder.dueAt),
        subtitle: tag ?? reminder.note?.split('\n').first,
        tagColor: tag == null ? null : tagColor(tag),
        repeats: flags.repeatReminders && reminder.repeat.repeats,
        onCheckTap: () => cubit.complete(reminder),
        onTap: () => context.push('/reminder/${reminder.id}'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 0, 40, MemoSpace.barHeight * 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EmptyRing(),
            const SizedBox(height: MemoSpace.space4),
            Text(
              'Nothing scheduled',
              style: MemoType.title.copyWith(color: c.ink),
            ),
            const SizedBox(height: MemoSpace.space1),
            Text(
              'Bins, pills, that call.\nType below to add one.',
              textAlign: TextAlign.center,
              style: MemoType.body.copyWith(color: c.ink70),
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
    final c = MemoColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 0, 40, MemoSpace.barHeight * 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Couldn't load your reminders",
              style: MemoType.title.copyWith(color: c.ink),
            ),
            const SizedBox(height: MemoSpace.space2),
            Text(
              'They are still saved on this device. '
              'Alarms already scheduled keep firing.',
              textAlign: TextAlign.center,
              style: MemoType.body.copyWith(color: c.ink70),
            ),
            const SizedBox(height: MemoSpace.space6),
            OutlinedButton(
              onPressed: () => context.read<HomeCubit>().load(),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
