import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../widgets/voice_notice.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/usecases/complete_reminder.dart';
import '../repeat_label.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../edit/edit_sheet.dart';
import '../widgets/day_section_header.dart';
import '../widgets/key_value_row.dart';
import '../widgets/section_card.dart';
import '../widgets/snooze_sheet.dart';
import 'detail_cubit.dart';
import '../../../../l10n/l10n.dart';

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
              context.l10n.reminderMissing,
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

  Future<void> _delete(BuildContext context) async {
    final cubit = context.read<DetailCubit>();
    final navigator = Navigator.of(context);
    final confirmed = await showMemoConfirm(
      context,
      title: context.l10n.detailDeleteTitle,
      body: context.l10n.detailDeleteBody,
      confirm: context.l10n.commonDelete,
      destructive: true,
    );
    if (!confirmed) return;
    if (await cubit.delete()) {
      HapticFeedback.mediumImpact();
      navigator.pop();
    }
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
            actionLabel: context.l10n.commonEdit,
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
                      ? context.l10n.commonDone
                      : reminder.isOverdue(now)
                      ? context.l10n.whenLate(
                          formatWhen(context, reminder.ringsAt, now),
                          formatLateness(
                            context,
                            now.difference(reminder.ringsAt),
                          ),
                        )
                      : reminder.repeat.repeats
                      ? context.l10n.detailRepeatNext(
                          repeatLabel(
                            context,
                            reminder.repeat,
                            none: '',
                            everyDay: true,
                          ),
                          formatWhen(context, reminder.ringsAt, now),
                        )
                      : formatWhen(context, reminder.ringsAt, now),
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
                VoiceNotice(
                  title: reminder.title,
                  readAloud: reminder.readAloud,
                  hasVoice: reminder.hasVoice,
                ),
                if (reminder.hasVoice) ...[
                  const SizedBox(height: MemoSpace.space4),
                  Row(
                    children: [
                      IconButton(
                        tooltip: context.l10n.voicePlay,
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
                        context.l10n.clipNote(
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
                      label: context.l10n.detailNext,
                      child: PillValue(
                        reminder.isDone
                            ? context.l10n.commonDone
                            : formatWhen(context, reminder.ringsAt, now),
                      ),
                    ),
                    if (flags.repeatReminders)
                      KeyValueRow(
                        label: context.l10n.fieldRepeat,
                        child: PillValue(
                          repeatLabel(
                            context,
                            reminder.repeat,
                            none: context.l10n.repeatNever,
                            everyDay: true,
                          ),
                        ),
                      ),
                    if (flags.nag)
                      KeyValueRow(
                        label: context.l10n.detailNag,
                        child: PillValue(
                          reminder.nagMin == null
                              ? context.l10n.commonOff
                              : nagLabel(context.l10n, reminder.nagMin!),
                        ),
                      ),
                    if (flags.preAlarm && reminder.preAlarmMin != null)
                      KeyValueRow(
                        label: context.l10n.fieldPreAlarm,
                        child: PillValue(
                          preAlarmLabel(context.l10n, reminder.preAlarmMin!),
                        ),
                      ),
                    if (tag != null)
                      KeyValueRow(
                        label: context.l10n.fieldTag,
                        child: TagChip(label: tag, dotColor: tagColor(tag)),
                      ),
                    KeyValueRow(
                      label: context.l10n.detailCreated,
                      child: PillValue(formatDate(context, reminder.createdAt)),
                    ),
                  ],
                ),
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
                if (reminder.isDone)
                  ElevatedButton(
                    onPressed: cubit.reopen,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.accentText,
                      foregroundColor: c.onAccent,
                    ),
                    child: Text(context.l10n.commonReopen),
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: cubit.complete,
                          icon: const Icon(Icons.check_rounded),
                          label: Text(
                            reminder.repeat.repeats &&
                                    (reminder.isOverdue(now) ||
                                        DateUtils.isSameDay(
                                          reminder.ringsAt,
                                          now,
                                        ))
                                ? context.l10n.detailDoneToday
                                : context.l10n.commonMarkDone,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: c.accentText,
                            foregroundColor: c.onAccent,
                          ),
                        ),
                      ),
                      if (flags.snooze) ...[
                        const SizedBox(width: MemoSpace.space3),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final at = await showSnoozeSheet(
                                context,
                                reminder,
                              );
                              if (at != null) cubit.snooze(at);
                            },
                            child: Text(context.l10n.detailSnooze),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (reminder.repeat.repeats) ...[
                    const SizedBox(height: MemoSpace.space2),
                    Text(
                      context.l10n.detailMovesTo(
                        formatWhen(
                          context,
                          const CompleteReminder()(reminder, now: now).dueAt,
                          now,
                        ),
                      ),
                      textAlign: TextAlign.center,
                      style: MemoType.body.copyWith(
                        fontSize: 13,
                        color: c.ink70,
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => _delete(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.destructive,
                  ),
                  child: Text(context.l10n.detailDelete),
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
