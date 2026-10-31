import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di.dart';
import '../../../../core/feature_flags/feature_flags.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/ui/memo_dialog.dart';
import '../../../../core/ui/memo_nav_bar.dart';
import '../../../../core/utils/date_format.dart';
import '../../../tags/presentation/tag_color.dart';
import '../../../tags/presentation/widgets/tag_chip.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/repeat_rule.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../edit/edit_sheet.dart';
import '../widgets/day_section_header.dart';
import '../widgets/key_value_row.dart';
import '../widgets/section_card.dart';
import '../widgets/snooze_preset_row.dart';
import 'detail_cubit.dart';

/// Artboard Detail. Reached from a row or a notification tap.
class DetailPage extends StatelessWidget {
  const DetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DetailCubit, DetailState>(
      listenWhen: (a, b) => b is DetailReady && b.error != null,
      listener: (context, state) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text((state as DetailReady).error!))),
      builder: (context, state) => Scaffold(
        body: SafeArea(
          child: switch (state) {
            DetailLoading() => const SizedBox.shrink(),
            DetailMissing() => const _Missing(),
            DetailReady(:final reminder) => _Body(reminder: reminder),
          },
        ),
      ),
    );
  }
}

class _Missing extends StatelessWidget {
  const _Missing();

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MemoNavBar(),
        Expanded(
          child: Center(
            child: Text(
              'This reminder no longer exists.',
              style: MemoType.body.copyWith(color: c.ink70),
            ),
          ),
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.reminder});

  final Reminder reminder;

  static String _repeatLabel(RepeatRule repeat) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return switch (repeat.type) {
      RepeatType.none => 'Never',
      RepeatType.daily => 'Daily',
      RepeatType.weekly when repeat.weekdays.isEmpty => 'Weekly',
      RepeatType.weekly =>
        (repeat.weekdays.toList()..sort()).map((d) => names[d - 1]).join(', '),
    };
  }

  Future<void> _delete(BuildContext context) async {
    final cubit = context.read<DetailCubit>();
    final navigator = Navigator.of(context);
    final confirmed = await showMemoConfirm(
      context,
      title: 'Delete this reminder?',
      body: 'It will not ring. There is no undo.',
      confirm: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;
    await cubit.delete();
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    final flags = sl<FeatureFlags>();
    final cubit = context.read<DetailCubit>();
    final now = DateTime.now();
    final tag = flags.tags ? reminder.tag : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MemoNavBar(
          actionLabel: 'Edit',
          onAction: () async {
            final tags = await _knownTags();
            if (!context.mounted) return;
            await showEditSheet(context, existing: reminder, knownTags: tags);
          },
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              MemoSpace.gutter,
              MemoSpace.space6,
              MemoSpace.gutter,
              MemoSpace.space6,
            ),
            children: [
              DaySectionHeader(
                label: reminder.isDone
                    ? 'Done'
                    : reminder.isOverdue(now)
                    ? '${formatWhen(reminder.dueAt, now)} · '
                          '${formatLateness(now.difference(reminder.dueAt))}'
                    : formatWhen(reminder.dueAt, now),
                emphasize: reminder.isOverdue(now),
              ),
              Semantics(
                header: true,
                child: Text(
                  reminder.title,
                  style: MemoType.display.copyWith(color: c.ink),
                ),
              ),
              if (reminder.note != null) ...[
                const SizedBox(height: MemoSpace.space2),
                Text(
                  reminder.note!,
                  style: MemoType.body.copyWith(color: c.ink70),
                ),
              ],
              const SizedBox(height: MemoSpace.space6),
              SectionCard(
                children: [
                  KeyValueRow(
                    label: 'Next',
                    child: PillValue(
                      reminder.isDone
                          ? 'Done'
                          : formatWhen(reminder.dueAt, now),
                    ),
                  ),
                  if (flags.repeatReminders)
                    KeyValueRow(
                      label: 'Repeat',
                      child: PillValue(_repeatLabel(reminder.repeat)),
                    ),
                  if (flags.nag)
                    KeyValueRow(
                      label: 'Nag',
                      child: PillValue(
                        reminder.nagMin == null
                            ? 'Off'
                            : 'Every ${reminder.nagMin} min',
                      ),
                    ),
                  if (tag != null)
                    KeyValueRow(
                      label: 'Tag',
                      child: TagChip(label: tag, dotColor: tagColor(tag)),
                    ),
                  KeyValueRow(
                    label: 'Created',
                    child: PillValue(formatDate(reminder.createdAt)),
                  ),
                ],
              ),
              if (flags.snooze && !reminder.isDone) ...[
                const SizedBox(height: MemoSpace.space6),
                const DaySectionHeader(label: 'Snooze'),
                SnoozePresetRow(
                  onSelect: (preset) => cubit.snooze(preset.duration),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            MemoSpace.gutter,
            0,
            MemoSpace.gutter,
            MemoSpace.space4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: reminder.isDone ? cubit.reopen : cubit.complete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.accent,
                  foregroundColor: c.onAccent,
                ),
                child: Text(reminder.isDone ? 'Reopen' : 'Mark done'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => _delete(context),
                style: OutlinedButton.styleFrom(foregroundColor: c.destructive),
                child: const Text('Delete'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Future<List<String>> _knownTags() async {
  final all = await sl<ReminderRepository>().getAll();
  return {for (final r in all) ?r.tag}.toList()..sort();
}
