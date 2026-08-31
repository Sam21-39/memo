import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_format.dart';
import '../../domain/entities/reminder.dart';
import '../cubit/reminders_cubit.dart';
import '../cubit/reminders_state.dart';
import '../widgets/section_card.dart';

/// memo Screens B · "Done" archive.
class RemindersDonePage extends StatelessWidget {
  const RemindersDonePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RemindersCubit, RemindersState>(
      builder: (context, state) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final done = state.allDone.reversed.toList();

        return Scaffold(
          appBar: AppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            title: Text('Done', style: theme.textTheme.titleLarge),
          ),
          body: SafeArea(
            child: done.isEmpty
                ? Center(
                    child: Text(
                      'Nothing completed yet.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenGutter,
                      AppSpacing.sm,
                      AppSpacing.screenGutter,
                      AppSpacing.xxl,
                    ),
                    children: [
                      SectionCard(
                        children: [
                          for (final reminder in done)
                            _DoneRow(reminder: reminder),
                        ],
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _DoneRow extends StatelessWidget {
  const _DoneRow({required this.reminder});

  final Reminder reminder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.45);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.onSurface.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, size: 12, color: scheme.surface),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              reminder.title,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: muted,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ),
          Text(
            formatTime(reminder.scheduledAt),
            style: theme.textTheme.labelMedium?.copyWith(
              fontSize: 12,
              color: scheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
          IconButton(
            onPressed: () =>
                context.read<RemindersCubit>().uncomplete(reminder),
            icon: const Icon(Icons.undo, size: 16),
            color: muted,
            tooltip: 'Reopen',
          ),
        ],
      ),
    );
  }
}
