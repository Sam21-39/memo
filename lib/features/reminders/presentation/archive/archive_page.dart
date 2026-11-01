import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/ui/memo_nav_bar.dart';
import '../../../../core/utils/date_format.dart';
import '../../../tags/presentation/widgets/tag_chip.dart';
import '../../domain/entities/reminder.dart';
import '../widgets/check_control.dart';
import '../widgets/day_section_header.dart';
import '../widgets/section_card.dart';
import 'archive_cubit.dart';

/// Artboard Done-Archive: completed one-offs by day, searchable.
class ArchivePage extends StatelessWidget {
  const ArchivePage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    final cubit = context.read<ArchiveCubit>();
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<ArchiveCubit, ArchiveState>(
          builder: (context, state) {
            final now = DateTime.now();
            final weekStart = DateTime(now.year, now.month, now.day - 6);
            final groups = <DateTime, List<Reminder>>{};
            for (final r in state.visible) {
              final d = r.doneAt!;
              groups
                  .putIfAbsent(DateTime(d.year, d.month, d.day), () => [])
                  .add(r);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const MemoNavBar(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      MemoSpace.gutter,
                      MemoSpace.space6,
                      MemoSpace.gutter,
                      MemoSpace.space8,
                    ),
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          'Done',
                          style: MemoType.display.copyWith(color: c.ink),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${state.completedSince(weekStart)} this week'
                            .toUpperCase(),
                        style: MemoType.labelSmall.copyWith(color: c.ink45),
                      ),
                      const SizedBox(height: MemoSpace.gutter),
                      TextField(
                        onChanged: cubit.search,
                        style: MemoType.body.copyWith(color: c.ink),
                        decoration: const InputDecoration(
                          hintText: 'Search done',
                        ),
                      ),
                      if (state.visible.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: MemoSpace.space8),
                          child: Text(
                            state.query.isEmpty
                                ? 'Nothing completed yet.'
                                : 'Nothing matches.',
                            textAlign: TextAlign.center,
                            style: MemoType.body.copyWith(color: c.ink70),
                          ),
                        ),
                      for (final entry in groups.entries) ...[
                        const SizedBox(height: MemoSpace.space6),
                        DaySectionHeader(label: dayHeaderLabel(entry.key, now)),
                        SectionCard(
                          children: [
                            for (final r in entry.value)
                              _DoneRow(reminder: r, onReopen: cubit.reopen),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DoneRow extends StatelessWidget {
  const _DoneRow({required this.reminder, required this.onReopen});

  final Reminder reminder;
  final ValueChanged<Reminder> onReopen;

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: MemoSpace.rowMin),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          MemoSpace.space1,
          MemoSpace.space1,
          MemoSpace.space4,
          MemoSpace.space1,
        ),
        child: Row(
          children: [
            const CheckControl(state: CheckState.done),
            const SizedBox(width: MemoSpace.space1),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    reminder.title,
                    style: MemoType.bodyLarge.copyWith(color: c.ink),
                  ),
                  Text(
                    formatTime(reminder.doneAt!),
                    style: MemoType.labelMedium.copyWith(color: c.ink70),
                  ),
                ],
              ),
            ),
            TagChip(label: 'Reopen', onTap: () => onReopen(reminder)),
          ],
        ),
      ),
    );
  }
}
