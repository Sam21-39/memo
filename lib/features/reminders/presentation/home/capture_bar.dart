import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/chrome/memo_chrome.dart';
import '../../../../core/di.dart';
import '../../../../core/feature_flags/feature_flags.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/ui/motion.dart';
import '../../../../core/ui/memo_nav_bar.dart';
import '../../../../core/utils/date_format.dart';
import '../../data/media_store.dart';
import '../../data/voice_clip.dart';
import '../repeat_label.dart';
import '../edit/edit_sheet.dart';
import 'capture_cubit.dart';
import 'capture_sheets.dart';
import '../../../../l10n/l10n.dart';

/// Artboards Home-* (idle), Capture-Parsed, Capture-Recording.
///
/// Idle it is glass; once something is typed it goes solid so the chips read
/// over the dimmed list. Recording, transcribing, failure and confirmation
/// are panels drawn above this bar by the home page: the bar stays mounted
/// underneath, and the mic keeps its tree slot from idle through recording.
class CaptureBar extends StatefulWidget {
  const CaptureBar({super.key, required this.knownTags});

  final List<String> knownTags;

  @override
  State<CaptureBar> createState() => _CaptureBarState();
}

class _CaptureBarState extends State<CaptureBar> {
  final _text = TextEditingController();
  final _focus = FocusNode();

  // The mic must survive any rebuild above it (chrome swap, a sibling
  // appearing): a remount mid-press loses the release.
  final _micKey = GlobalKey();

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    final cubit = context.read<CaptureCubit>();
    return BlocConsumer<CaptureCubit, CaptureState>(
      // A transcript, or a reset after Save, changes the text under us.
      listenWhen: (a, b) => b.text != _text.text || a.phase != b.phase,
      listener: (context, state) {
        if (state.text != _text.text) {
          _text.value = TextEditingValue(
            text: state.text,
            selection: TextSelection.collapsed(offset: state.text.length),
          );
        }
        if (state.phase != CapturePhase.typing) _focus.unfocus();
      },
      builder: (context, state) {
        final l = context.l10n;
        final typing = state.phase == CapturePhase.typing;
        final fieldVisible = typing || state.phase == CapturePhase.idle;
        final message = state.error ?? state.notice;
        return ExcludeSemantics(
          // The panel above covers the bar; keep it out of the reading order.
          excluding: !fieldVisible,
          child: DecoratedBox(
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Solid follows the text, not the phase: the chrome must not
                  // swap under a finger that is recording.
                  MemoChrome(
                    shape: ChromeShape.bar,
                    solid: state.text.trim().isNotEmpty || state.hasClip,
                    child: AnimatedSize(
                      alignment: Alignment.bottomCenter,
                      duration: motion(context, MemoMotion.base),
                      curve: MemoMotion.curve,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Fixed slots: a slot may be empty, never absent, so
                          // the row below keeps its index.
                          typing
                              ? Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    MemoSpace.space4,
                                    MemoSpace.space3,
                                    MemoSpace.space4,
                                    0,
                                  ),
                                  child: Text(
                                    l.reminderHint,
                                    style: MemoType.body.copyWith(
                                      fontSize: 13,
                                      height: 18 / 13,
                                      color: c.ink70,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              minHeight: MemoSpace.barHeight,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Visibility(
                                    maintainState: true,
                                    visible: fieldVisible,
                                    child: _field(context, cubit),
                                  ),
                                ),
                                if (sl<FeatureFlags>().imageCapture &&
                                    state.phase == CapturePhase.idle)
                                  MemoIconButton(
                                    icon: Icons.photo_camera_outlined,
                                    label: l.captureAddPhoto,
                                  ),
                                _Mic(key: _micKey, cubit: cubit, state: state),
                                const SizedBox(width: MemoSpace.space1),
                              ],
                            ),
                          ),
                          message != null && fieldVisible
                              ? _Message(state: state, message: message)
                              : const SizedBox.shrink(),
                          typing
                              ? _Chips(state: state)
                              : const SizedBox.shrink(),
                          typing
                              ? Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    MemoSpace.space4,
                                    0,
                                    MemoSpace.space4,
                                    MemoSpace.space4,
                                  ),
                                  child: ElevatedButton(
                                    onPressed: state.canContinue
                                        ? cubit.review
                                        : null,
                                    child: Text(l.commonContinue),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ],
                      ),
                    ),
                  ),
                  state.phase == CapturePhase.idle
                      ? Padding(
                          padding: const EdgeInsets.only(top: MemoSpace.space2),
                          child: Text(
                            l.captureHintLine,
                            textAlign: TextAlign.center,
                            style: MemoType.body.copyWith(
                              fontSize: 13,
                              height: 18 / 13,
                              color: c.ink70,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _field(BuildContext context, CaptureCubit cubit) {
    final c = MemoColors.of(context);
    return TextField(
      controller: _text,
      focusNode: _focus,
      onChanged: cubit.setText,
      onSubmitted: (_) => cubit.review(),
      textInputAction: TextInputAction.done,
      textCapitalization: TextCapitalization.sentences,
      style: MemoType.bodyLarge.copyWith(color: c.ink),
      decoration: InputDecoration(
        hintText: context.l10n.reminderHint,
        hintStyle: MemoType.bodyLarge.copyWith(color: c.ink70),
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.only(left: MemoSpace.space4),
      ),
    );
  }
}

/// A mic error or hint; a refused microphone also offers Settings.
class _Message extends StatelessWidget {
  const _Message({required this.state, required this.message});

  final CaptureState state;
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MemoSpace.space4,
        0,
        MemoSpace.space4,
        MemoSpace.space2,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: MemoType.body.copyWith(
                color: state.error != null ? c.destructive : c.ink70,
              ),
            ),
          ),
          if (state.micDenied && state.error != null)
            TextButton(
              onPressed: openAppSettings,
              child: Text(context.l10n.openSettings),
            ),
        ],
      ),
    );
  }
}

/// Opens the full editor from the confirmation or the bar.
Future<void> openEditDetails(
  BuildContext context,
  CaptureCubit cubit,
  List<String> knownTags,
) async {
  final saved = await showEditSheet(
    context,
    draft: cubit.draft().copyWith(
      title: cubit.state.title,
      readAloud: cubit.state.readAloud,
    ),
    draftClip: cubit.state.hasClip,
    knownTags: knownTags,
  );
  if (saved) {
    await cubit.discard();
  } else {
    cubit.syncClip();
  }
}

/// Date, Time, Repeat and the clip. A wrong chip is tapped to fix; Date and
/// Time are dashed while the time is still a guess.
class _Chips extends StatelessWidget {
  const _Chips({required this.state});

  final CaptureState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CaptureCubit>();
    final l = context.l10n;
    final due = state.dueAt!;
    final now = DateTime.now();
    final unsure = state.unsure != null;
    final day = dayHeaderLabel(context, due, now);
    final time = formatTime(context, due);
    final media = cubit.media;
    Future<void> editWhen() async {
      final at = await showWhenSheet(context, due);
      if (at != null) cubit.setDueAt(at);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MemoSpace.space3,
        0,
        MemoSpace.space3,
        MemoSpace.space3,
      ),
      child: Wrap(
        spacing: MemoSpace.space2,
        runSpacing: MemoSpace.space2,
        children: [
          _Chip(label: day, dashed: unsure, onTap: editWhen),
          _Chip(
            label: time,
            dashed: unsure,
            semantics: unsure ? l.captureTimeGuess(time) : l.captureTime(time),
            onTap: editWhen,
          ),
          _Chip(
            label: l.repeatChip(
              repeatLabel(context, state.repeat, none: l.repeatNone),
            ),
            dashed: !state.repeat.repeats,
            onTap: () async {
              final r = await showRepeatSheet(context, state.repeat, due);
              if (r != null) cubit.setRepeat(r);
            },
          ),
          if (state.hasClip && media != null)
            _Chip(
              label: l.clipNote(MediaStore.clipLength(media.draftVoicePath)),
              onTap: () => sl<VoiceClip>().play(media.draftVoicePath),
            ),
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
    this.semantics,
  });

  final String label;
  final VoidCallback onTap;

  /// A guess or an empty slot: outlined, not filled.
  final bool dashed;
  final String? semantics;

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    return Semantics(
      button: true,
      label: semantics ?? label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: MemoSpace.hitMin),
          child: Center(
            widthFactor: 1,
            child: Container(
              constraints: const BoxConstraints(minHeight: 34),
              padding: const EdgeInsets.symmetric(
                horizontal: MemoSpace.space3,
                vertical: MemoSpace.space1,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: dashed ? null : c.ink6,
                borderRadius: BorderRadius.circular(MemoRadius.chip),
                border: dashed ? Border.all(color: c.ink45) : null,
              ),
              child: Text(
                label,
                style: MemoType.labelMedium.copyWith(
                  color: dashed ? c.ink70 : c.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tap to start, tap Stop to end; or hold and release. Raw pointer events:
/// down starts, a quick up latches, a late up stops.
class _Mic extends StatelessWidget {
  const _Mic({super.key, required this.cubit, required this.state});

  final CaptureCubit cubit;
  final CaptureState state;

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    final active = state.phase == CapturePhase.recording;
    return Semantics(
      button: true,
      label: context.l10n.micRecord,
      hint: active ? context.l10n.micTapToStop : context.l10n.micTapToStart,
      onTap: cubit.toggleRecording,
      excludeSemantics: true,
      child: Opacity(
        opacity: state.micDenied ? 0.4 : 1,
        child: Listener(
          onPointerDown: (_) {
            HapticFeedback.selectionClick();
            cubit.startRecording();
          },
          onPointerUp: (_) => cubit.stopRecording(),
          onPointerCancel: (_) => cubit.stopRecording(),
          child: AnimatedContainer(
            duration: motion(context, MemoMotion.fast),
            width: MemoSpace.hitMin,
            height: MemoSpace.hitMin,
            decoration: BoxDecoration(
              color: active ? c.accentPressed : c.accentText,
              shape: BoxShape.circle,
              border: active ? Border.all(color: c.accentSoft, width: 4) : null,
            ),
            child: Icon(Icons.mic_none_rounded, color: c.onAccent, size: 20),
          ),
        ),
      ),
    );
  }
}
