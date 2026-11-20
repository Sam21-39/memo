import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/memo_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/ui/section_label.dart';
import '../../../../core/ui/memo_nav_bar.dart';
import '../../../../core/ui/minute_clock.dart';
import '../../../../core/utils/date_format.dart';
import '../../data/media_store.dart';
import '../widgets/day_section_header.dart';
import '../repeat_label.dart';
import '../widgets/snooze_sheet.dart';
import 'alarm_cubit.dart';
import '../../../../l10n/l10n.dart';

/// Artboards Alarm and Android-Alarm: one-handed, readable without glasses,
/// over the lock screen on Android.
class AlarmPage extends StatelessWidget {
  const AlarmPage({super.key, required this.voicePath, required this.onClose});

  final String Function(String id) voicePath;

  /// Leaves the screen once the alarm is dealt with.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    return BlocConsumer<AlarmCubit, AlarmState>(
      listenWhen: (a, b) => a.outcome != b.outcome,
      listener: (context, state) {
        if (state.outcome == AlarmOutcome.done ||
            state.outcome == AlarmOutcome.snoozed) {
          onClose();
        }
      },
      builder: (context, state) {
        final reminder = state.reminder;
        if (state.outcome == AlarmOutcome.missing) {
          return Scaffold(
            body: SafeArea(
              child: Column(
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
              ),
            ),
          );
        }
        if (reminder == null) return const Scaffold();
        final cubit = context.read<AlarmCubit>();
        return ValueListenableBuilder<DateTime>(
          valueListenable: MinuteClock.instance,
          builder: (context, now, _) {
            final late = now.difference(reminder.ringsAt);
            final clock = formatTime(context, reminder.ringsAt).split(' ');
            return Scaffold(
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    MemoSpace.gutter,
                    MemoSpace.space6,
                    MemoSpace.gutter,
                    MemoSpace.space4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  DaySectionHeader(
                                    label: context.l10n.alarmReminder,
                                  ),
                                  if (late.inMinutes >= 1)
                                    Flexible(
                                      child: Text(
                                        formatLateness(context, late),
                                        textAlign: TextAlign.end,
                                        style: sectionLabelStyle(
                                          context,
                                        ).copyWith(color: c.accentText),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: MemoSpace.space6),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: AlignmentDirectional.centerStart,
                                child: Text.rich(
                                  TextSpan(
                                    text: clock.first,
                                    style: MemoType.clock.copyWith(
                                      color: c.ink,
                                    ),
                                    children: [
                                      if (clock.length > 1)
                                        TextSpan(
                                          text: ' ${clock.last}',
                                          style: MemoType.labelMedium.copyWith(
                                            fontSize: 20,
                                            color: c.ink,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: MemoSpace.space3),
                              Semantics(
                                header: true,
                                child: Text(
                                  reminder.title,
                                  style: MemoType.alarmTitle.copyWith(
                                    color: c.ink,
                                  ),
                                ),
                              ),
                              if (reminder.note != null) ...[
                                const SizedBox(height: MemoSpace.space2),
                                Text(
                                  reminder.note!,
                                  style: MemoType.body.copyWith(color: c.ink70),
                                ),
                              ],
                              if (reminder.repeat.repeats) ...[
                                const SizedBox(height: MemoSpace.space3),
                                _InfoLine(
                                  Icons.repeat_rounded,
                                  repeatLabel(
                                    context,
                                    reminder.repeat,
                                    none: '',
                                    everyDay: true,
                                  ),
                                ),
                              ],
                              if (state.speakingIn != null) ...[
                                const SizedBox(height: MemoSpace.space2),
                                _InfoLine(
                                  Icons.volume_up_outlined,
                                  switch (state.speakingIn) {
                                    'hi' => context.l10n.alarmReadingInHi,
                                    'bn' => context.l10n.alarmReadingInBn,
                                    _ => context.l10n.alarmReadingInEn,
                                  },
                                ),
                              ],
                              if (reminder.hasVoice) ...[
                                const SizedBox(height: MemoSpace.gutter),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: cubit.togglePlay,
                                      tooltip: state.playing
                                          ? context.l10n.voiceStop
                                          : context.l10n.voicePlay,
                                      style: IconButton.styleFrom(
                                        fixedSize: const Size.square(
                                          MemoSpace.hitMin,
                                        ),
                                        backgroundColor: c.accentText,
                                        foregroundColor: c.onAccent,
                                      ),
                                      icon: Icon(
                                        state.playing
                                            ? Icons.stop_rounded
                                            : Icons.play_arrow_rounded,
                                      ),
                                    ),
                                    const SizedBox(width: MemoSpace.space3),
                                    Text(
                                      state.playing
                                          ? context.l10n.clipNotePlaying(
                                              MediaStore.clipLength(
                                                voicePath(reminder.id),
                                              ),
                                            )
                                          : context.l10n.clipNote(
                                              MediaStore.clipLength(
                                                voicePath(reminder.id),
                                              ),
                                            ),
                                      style: MemoType.labelMedium.copyWith(
                                        color: c.ink70,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: MemoSpace.space3),
                      ElevatedButton.icon(
                        onPressed: cubit.done,
                        icon: const Icon(Icons.check_rounded),
                        label: Text(context.l10n.commonDone),
                        style: MemoButtons.large(c),
                      ),
                      const SizedBox(height: MemoSpace.space3),
                      OutlinedButton(
                        onPressed: () async {
                          final at = await showSnoozeSheet(context, reminder);
                          if (at != null) cubit.snooze(at);
                        },
                        style: MemoButtons.large(c),
                        child: Text(context.l10n.detailSnooze),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: c.ink70),
        const SizedBox(width: MemoSpace.space2),
        Expanded(
          child: Text(
            text,
            style: MemoType.body.copyWith(fontSize: 13, color: c.ink70),
          ),
        ),
      ],
    );
  }
}
