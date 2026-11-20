import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di.dart';
import '../../../../core/feature_flags/feature_flags.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/ui/memo_dialog.dart';
import '../../../../core/ui/memo_nav_bar.dart';
import '../../../../core/ui/minute_clock.dart';
import '../../../../core/ui/minutes_sheet.dart';
import '../../../../core/utils/date_format.dart';
import '../../../tags/presentation/tag_color.dart';
import '../../../tags/presentation/widgets/tag_chip.dart';
import '../../data/media_store.dart';
import '../../data/voice_clip.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/repeat_rule.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../edit/edit_sheet.dart';
import '../widgets/day_section_header.dart';
import '../widgets/key_value_row.dart';
import '../widgets/section_card.dart';
import '../widgets/snooze_preset_row.dart';
import 'detail_cubit.dart';
import '../../../../l10n/strings.dart';

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
              S.reminderMissing,
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
    const names = S.weekdaysShort;
    return switch (repeat.type) {
      RepeatType.none => S.repeatNever,
      RepeatType.daily => S.repeatDaily,
      RepeatType.weekly when repeat.weekdays.isEmpty => S.repeatWeekly,
      RepeatType.weekly =>
        (repeat.weekdays.toList()..sort()).map((d) => names[d - 1]).join(', '),
    };
  }

  Future<void> _delete(BuildContext context) async {
    final cubit = context.read<DetailCubit>();
    final navigator = Navigator.of(context);
    final confirmed = await showMemoConfirm(
      context,
      title: S.detailDeleteTitle,
      body: S.detailDeleteBody,
      confirm: S.commonDelete,
      destructive: true,
    );
    if (!confirmed) return;
    if (await cubit.delete()) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    final flags = sl<FeatureFlags>();
    final cubit = context.read<DetailCubit>();
    final tag = flags.tags ? reminder.tag : null;
    return ValueListenableBuilder<DateTime>(
      valueListenable: MinuteClock.instance,
      builder: (context, now, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MemoNavBar(
            actionLabel: S.commonEdit,
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
                      ? S.commonDone
                      : reminder.isOverdue(now)
                      ? S.whenLate(
                          formatWhen(reminder.ringsAt, now),
                          formatLateness(now.difference(reminder.ringsAt)),
                        )
                      : formatWhen(reminder.ringsAt, now),
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
                if (reminder.hasVoice) ...[
                  const SizedBox(height: MemoSpace.space4),
                  Row(
                    children: [
                      IconButton(
                        tooltip: S.voicePlay,
                        onPressed: () => sl<VoiceClip>().play(
                          sl<MediaStore>().voicePath(reminder.id),
                        ),
                        style: IconButton.styleFrom(
                          fixedSize: const Size.square(36),
                          backgroundColor: c.ink6,
                        ),
                        icon: Icon(
                          Icons.play_arrow_rounded,
                          color: c.ink,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: MemoSpace.space3),
                      Text(
                        S.clipNote(
                          MediaStore.clipLength(
                            sl<MediaStore>().voicePath(reminder.id),
                          ),
                        ),
                        style: MemoType.labelMedium.copyWith(color: c.ink70),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: MemoSpace.space6),
                SectionCard(
                  children: [
                    KeyValueRow(
                      label: S.detailNext,
                      child: PillValue(
                        reminder.isDone
                            ? S.commonDone
                            : formatWhen(reminder.ringsAt, now),
                      ),
                    ),
                    if (flags.repeatReminders)
                      KeyValueRow(
                        label: S.fieldRepeat,
                        child: PillValue(_repeatLabel(reminder.repeat)),
                      ),
                    if (flags.nag)
                      KeyValueRow(
                        label: S.detailNag,
                        child: PillValue(
                          reminder.nagMin == null
                              ? S.commonOff
                              : nagLabel(reminder.nagMin!),
                        ),
                      ),
                    if (flags.preAlarm && reminder.preAlarmMin != null)
                      KeyValueRow(
                        label: S.fieldPreAlarm,
                        child: PillValue(preAlarmLabel(reminder.preAlarmMin!)),
                      ),
                    if (tag != null)
                      KeyValueRow(
                        label: S.fieldTag,
                        child: TagChip(label: tag, dotColor: tagColor(tag)),
                      ),
                    KeyValueRow(
                      label: S.detailCreated,
                      child: PillValue(formatDate(reminder.createdAt)),
                    ),
                  ],
                ),
                if (flags.snooze && !reminder.isDone) ...[
                  const SizedBox(height: MemoSpace.space6),
                  const DaySectionHeader(label: S.detailSnooze),
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
                    backgroundColor: c.accentText,
                    foregroundColor: c.onAccent,
                  ),
                  child: Text(
                    reminder.isDone ? S.commonReopen : S.commonMarkDone,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => _delete(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.destructive,
                  ),
                  child: const Text(S.commonDelete),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<List<String>> _knownTags() async {
  final all = await sl<ReminderRepository>().getAll();
  return {for (final r in all) ?r.tag}.toList()..sort();
}
