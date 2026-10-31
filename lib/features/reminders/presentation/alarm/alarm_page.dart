import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/ui/memo_nav_bar.dart';
import '../../../../core/utils/date_format.dart';
import '../../data/media_store.dart';
import '../widgets/day_section_header.dart';
import '../widgets/snooze_preset_row.dart';
import 'alarm_cubit.dart';

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
                        'This reminder no longer exists.',
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
        final now = DateTime.now();
        final late = now.difference(reminder.dueAt);
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const DaySectionHeader(label: 'Reminder'),
                      if (late.inMinutes >= 1)
                        Text(
                          formatLateness(late),
                          style: MemoType.labelSmall.copyWith(color: c.accent),
                        ),
                    ],
                  ),
                  const SizedBox(height: MemoSpace.space6),
                  Text(
                    formatTime(reminder.dueAt),
                    style: MemoType.clock.copyWith(color: c.ink),
                  ),
                  const SizedBox(height: MemoSpace.space3),
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
                    const SizedBox(height: MemoSpace.gutter),
                    Row(
                      children: [
                        IconButton(
                          onPressed: cubit.togglePlay,
                          tooltip: state.playing
                              ? 'Stop voice note'
                              : 'Play voice note',
                          style: IconButton.styleFrom(
                            fixedSize: const Size.square(MemoSpace.hitMin),
                            backgroundColor: c.accent,
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
                          '${MediaStore.clipLength(voicePath(reminder.id))}'
                          ' · your voice${state.playing ? ' · playing' : ''}',
                          style: MemoType.labelMedium.copyWith(color: c.ink70),
                        ),
                      ],
                    ),
                  ],
                  const Spacer(),
                  SnoozePresetRow(
                    onSelect: (preset) => cubit.snooze(preset.duration),
                  ),
                  const SizedBox(height: MemoSpace.space3),
                  SlideToDone(onDone: cubit.done),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A 56-high accent-soft track; drag the accent knob to the end to finish.
/// Screen readers get a plain button instead of a drag.
class SlideToDone extends StatefulWidget {
  const SlideToDone({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<SlideToDone> createState() => _SlideToDoneState();
}

class _SlideToDoneState extends State<SlideToDone> {
  double _dx = 0;
  static const _knob = 48.0;
  static const _height = 56.0;

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    return Semantics(
      button: true,
      label: 'Mark done',
      onTap: widget.onDone,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final travel = constraints.maxWidth - _knob - 8;
          return Container(
            height: _height,
            padding: const EdgeInsets.all(MemoSpace.space1),
            decoration: BoxDecoration(
              color: c.accentSoft,
              borderRadius: BorderRadius.circular(MemoRadius.pill),
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Center(
                  child: Text(
                    'Slide to mark done',
                    style: MemoType.button.copyWith(color: c.accentPressed),
                  ),
                ),
                Transform.translate(
                  offset: Offset(_dx, 0),
                  child: GestureDetector(
                    onHorizontalDragUpdate: (d) => setState(
                      () => _dx = (_dx + d.delta.dx).clamp(0, travel),
                    ),
                    onHorizontalDragEnd: (_) {
                      if (_dx >= travel * 0.85) {
                        widget.onDone();
                      } else {
                        setState(() => _dx = 0);
                      }
                    },
                    child: Container(
                      width: _knob,
                      height: _knob,
                      decoration: BoxDecoration(
                        color: c.accent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_rounded, color: c.onAccent),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
