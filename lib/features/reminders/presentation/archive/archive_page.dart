import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/ui/memo_nav_bar.dart';
import '../../../../core/ui/section_label.dart';
import '../../../../core/utils/date_format.dart';
import '../../../tags/presentation/widgets/tag_chip.dart';
import '../../domain/entities/reminder.dart';
import '../widgets/check_control.dart';
import '../widgets/day_section_header.dart';
import '../widgets/section_card.dart';
import 'archive_cubit.dart';
import '../../../../l10n/l10n.dart';

/// Artboard Done-Archive: completed one-offs by day, searchable.
class ArchivePage extends StatelessWidget {
  const ArchivePage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    final cubit = context.read<ArchiveCubit>();
    return Scaffold(
      body: BlocListener<ArchiveCubit, ArchiveState>(
        listenWhen: (a, b) => b.error != null,
        listener: (context, state) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.error!)));
          context.read<ArchiveCubit>().clearError();
        },
        child: SafeArea(
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
                            context.l10n.commonDone,
                            style: MemoType.display.copyWith(color: c.ink),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          sectionLabelText(
                            context,
                            context.l10n.archiveThisWeek(
                              state.completedSince(weekStart),
                            ),
                          ),
                          style: sectionLabelStyle(
                            context,
                          ).copyWith(color: c.ink70),
                        ),
                        const SizedBox(height: MemoSpace.gutter),
                        TextField(
                          onChanged: cubit.search,
                          style: MemoType.body.copyWith(color: c.ink),
                          decoration: InputDecoration(
                            hintText: context.l10n.archiveSearchHint,
                          ),
                        ),
                        if (state.visible.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: MemoSpace.space8,
                            ),
                            child: Text(
                              state.query.isEmpty
                                  ? context.l10n.archiveEmpty
                                  : context.l10n.archiveNoMatch,
                              textAlign: TextAlign.center,
                              style: MemoType.body.copyWith(color: c.ink70),
                            ),
                          ),
                        for (final entry in groups.entries) ...[
                          const SizedBox(height: MemoSpace.space6),
                          DaySectionHeader(
                            label: dayHeaderLabel(context, entry.key, now),
                          ),
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
                    formatTime(context, reminder.doneAt!),
                    style: MemoType.labelMedium.copyWith(color: c.ink70),
                  ),
                ],
              ),
            ),
            TagChip(
              label: context.l10n.commonReopen,
              onTap: () => onReopen(reminder),
            ),
          ],
        ),
      ),
    );
  }
}
