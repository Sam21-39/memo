import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/chrome/memo_chrome.dart';
import '../../../../core/di.dart';
import '../../../../core/feature_flags/feature_flags.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/ui/memo_loader.dart';
import '../../../../core/ui/memo_nav_bar.dart';
import '../../../../core/utils/date_format.dart';
import '../../../tags/presentation/tag_color.dart';
import '../../data/media_store.dart';
import '../../data/voice_clip.dart';
import '../../domain/entities/repeat_rule.dart';
import '../edit/edit_sheet.dart';
import 'capture_cubit.dart';
import 'capture_sheets.dart';
import '../../../../l10n/strings.dart';

/// Artboards Home-* (idle), Capture-Parsed, Capture-Recording, Loaders.
///
/// Idle it is glass. Expanded (typed, recording, transcribing) it goes
/// solid so the chips read over the dimmed list. A canvas fade sits under
/// it so the list disappears rather than ends.
class CaptureBar extends StatefulWidget {
  const CaptureBar({super.key, required this.knownTags});

  final List<String> knownTags;

  @override
  State<CaptureBar> createState() => _CaptureBarState();
}

class _CaptureBarState extends State<CaptureBar> {
  final _text = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _more(CaptureCubit cubit) async {
    final saved = await showEditSheet(
      context,
      draft: cubit.draft().copyWith(
        title: cubit.state.title,
        readAloud: cubit.state.readAloud,
      ),
      draftClip: cubit.state.hasClip,
      knownTags: widget.knownTags,
    );
    if (saved) {
      await cubit.discard();
    } else {
      cubit.syncClip();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    final cubit = context.read<CaptureCubit>();
    return BlocConsumer<CaptureCubit, CaptureState>(
      // A transcript, or a reset after Save, changes the text under us.
      listenWhen: (a, b) => b.text != _text.text,
      listener: (context, state) {
        _text.value = TextEditingValue(
          text: state.text,
          selection: TextSelection.collapsed(offset: state.text.length),
        );
        if (state.phase == CapturePhase.idle) _focus.unfocus();
      },
      builder: (context, state) {
        final message = state.error ?? state.notice;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0, 0.6],
              colors: [c.canvas.withValues(alpha: 0), c.canvas],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              MemoSpace.space3,
              MemoSpace.space6,
              MemoSpace.space3,
              MediaQuery.paddingOf(context).bottom + MemoSpace.space3,
            ),
            child: MemoChrome(
              shape: ChromeShape.bar,
              solid: state.expanded,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.phase == CapturePhase.typing ||
                      state.phase == CapturePhase.saving)
                    _Chips(
                      state: state,
                      knownTags: widget.knownTags,
                      onMore: () => _more(cubit),
                    ),
                  if (message != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        MemoSpace.space4,
                        MemoSpace.space3,
                        MemoSpace.space4,
                        0,
                      ),
                      child: Text(
                        message,
                        style: MemoType.body.copyWith(
                          color: state.error != null ? c.destructive : c.ink70,
                        ),
                      ),
                    ),
                  SizedBox(
                    height: MemoSpace.barHeight,
                    child: Row(
                      children: [
                        Expanded(child: _main(context, state, cubit)),
                        if (sl<FeatureFlags>().imageCapture &&
                            state.phase == CapturePhase.idle)
                          const MemoIconButton(
                            icon: Icons.photo_camera_outlined,
                            label: S.captureAddPhoto,
                          ),
                        // The mic keeps one slot from idle through recording:
                        // rebuilding it mid-hold would lose the release.
                        if (state.phase == CapturePhase.recording ||
                            (!state.canSave &&
                                state.phase != CapturePhase.transcribing &&
                                state.phase != CapturePhase.saving))
                          _Mic(
                            cubit: cubit,
                            active: state.phase == CapturePhase.recording,
                          )
                        else if (state.canSave)
                          TextButton(
                            onPressed: cubit.save,
                            child: const Text(S.commonSave),
                          ),
                        const SizedBox(width: MemoSpace.space1),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _main(BuildContext context, CaptureState state, CaptureCubit cubit) {
    final c = MemoColors.of(context);
    final mono = MemoType.labelMedium.copyWith(color: c.ink70);
    String secs(Duration d) => '0:${d.inSeconds.toString().padLeft(2, '0')}';
    final pad = const EdgeInsets.only(left: MemoSpace.space4);
    switch (state.phase) {
      case CapturePhase.recording:
        // From 20 s the timer turns to a countdown in accent.
        final left = VoiceClip.maxLength - state.recorded;
        final late = state.recorded >= const Duration(seconds: 20);
        return Padding(
          padding: pad,
          child: Row(
            children: [
              Text(
                late
                    ? S.captureLeft(secs(left))
                    : S.captureElapsed(secs(state.recorded)),
                style: mono.copyWith(color: c.accent),
              ),
              const SizedBox(width: MemoSpace.space3),
              Expanded(
                child: Text(
                  S.captureReleaseToStop,
                  maxLines: 2,
                  style: MemoType.body.copyWith(fontSize: 13, color: c.ink70),
                ),
              ),
            ],
          ),
        );
      case CapturePhase.transcribing:
        return Padding(
          padding: pad,
          child: Row(
            children: [
              MemoLoader(label: S.captureListening(secs(state.recorded))),
              const Spacer(),
              TextButton(
                onPressed: cubit.cancelTranscription,
                style: TextButton.styleFrom(foregroundColor: c.ink70),
                child: const Text(S.commonCancel),
              ),
            ],
          ),
        );
      case CapturePhase.saving:
        return Padding(
          padding: pad,
          child: const Align(
            alignment: Alignment.centerLeft,
            child: MemoLoader(label: S.captureSaving),
          ),
        );
      case CapturePhase.idle || CapturePhase.typing:
        return TextField(
          controller: _text,
          focusNode: _focus,
          onChanged: cubit.setText,
          onSubmitted: (_) => cubit.save(),
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.sentences,
          style: MemoType.bodyLarge.copyWith(color: c.ink),
          decoration: InputDecoration(
            hintText: S.reminderHint,
            hintStyle: MemoType.bodyLarge.copyWith(color: c.ink45),
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: pad,
          ),
        );
    }
  }
}

/// Time, Repeat, Tag, voice and More. A wrong chip is tapped to fix.
class _Chips extends StatelessWidget {
  const _Chips({
    required this.state,
    required this.knownTags,
    required this.onMore,
  });

  final CaptureState state;
  final List<String> knownTags;
  final VoidCallback onMore;

  static String _repeat(RepeatRule r) {
    const names = S.weekdaysShort;
    return switch (r.type) {
      RepeatType.none => S.captureRepeatNone,
      RepeatType.daily => S.repeatDaily,
      RepeatType.weekly when r.weekdays.length == 1 => S.captureEveryDay(
        names[r.weekdays.first - 1],
      ),
      RepeatType.weekly
          when r.weekdays.containsAll({1, 2, 3, 4, 5}) &&
              r.weekdays.length == 5 =>
        S.captureRepeatWeekdays,
      RepeatType.weekly =>
        (r.weekdays.toList()..sort()).map((d) => names[d - 1]).join(' '),
    };
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CaptureCubit>();
    final due = state.dueAt!;
    final now = DateTime.now();
    final when =
        '${dayHeaderLabel(due, now) == S.dateToday ? '' : '${dayHeaderLabel(due, now)} '}'
        '${formatTime(due)}';
    final tag = state.tag;
    final media = cubit.media;
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          MemoSpace.space3,
          MemoSpace.space3,
          MemoSpace.space3,
          0,
        ),
        children: [
          _Chip(
            label: when,
            dashed: state.timeGuessed,
            semantics: state.timeGuessed
                ? S.captureTimeGuess(when)
                : S.captureTime(when),
            onTap: () async {
              final at = await showWhenSheet(context, due);
              if (at != null) cubit.setDueAt(at);
            },
          ),
          _Chip(
            label: _repeat(state.repeat),
            dashed: !state.repeat.repeats,
            onTap: () async {
              final r = await showRepeatSheet(context, state.repeat, due);
              if (r != null) cubit.setRepeat(r);
            },
          ),
          _Chip(
            label: tag ?? S.captureTagNone,
            dot: tag == null ? null : tagColor(tag),
            dashed: tag == null,
            onTap: () async {
              final t = await showTagSheet(context, tag, knownTags);
              if (t != null) cubit.setTag(t.isEmpty ? null : t);
            },
          ),
          _Chip(
            label: state.readAloud ? S.captureReadAloud : S.captureSilent,
            dashed: !state.readAloud,
            semantics: state.readAloud
                ? S.captureReadAloudOn
                : S.captureReadAloudOff,
            onTap: () => cubit.setReadAloud(!state.readAloud),
          ),
          if (state.hasClip && media != null)
            _Chip(
              label: S.clipNote(MediaStore.clipLength(media.draftVoicePath)),
              onTap: () => sl<VoiceClip>().play(media.draftVoicePath),
            ),
          _Chip(label: S.commonMore, dashed: true, onTap: onMore),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.onTap,
    this.dashed = false,
    this.dot,
    this.semantics,
  });

  final String label;
  final VoidCallback onTap;

  /// A guess or an empty slot: outlined, not filled.
  final bool dashed;
  final Color? dot;
  final String? semantics;

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: MemoSpace.space2),
      child: Semantics(
        button: true,
        label: semantics ?? label,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: MemoSpace.space3),
            decoration: BoxDecoration(
              color: dashed ? null : c.ink6,
              borderRadius: BorderRadius.circular(MemoRadius.chip),
              border: dashed ? Border.all(color: c.ink45) : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dot != null) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: dot,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: MemoType.labelMedium.copyWith(
                    color: dashed ? c.ink70 : c.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Hold to record. Raw pointer events: down records, up stops.
class _Mic extends StatelessWidget {
  const _Mic({required this.cubit, required this.active});

  final CaptureCubit cubit;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    return Semantics(
      button: true,
      label: S.captureHoldToRecord,
      child: Listener(
        onPointerDown: (_) {
          HapticFeedback.selectionClick();
          cubit.startRecording();
        },
        onPointerUp: (_) => cubit.stopRecording(),
        onPointerCancel: (_) => cubit.stopRecording(),
        child: AnimatedContainer(
          duration: MemoMotion.fast,
          width: MemoSpace.hitMin,
          height: MemoSpace.hitMin,
          decoration: BoxDecoration(
            color: active ? c.accentPressed : c.accent,
            shape: BoxShape.circle,
            border: active ? Border.all(color: c.accentSoft, width: 4) : null,
          ),
          child: Icon(Icons.mic_none_rounded, color: c.onAccent, size: 20),
        ),
      ),
    );
  }
}
