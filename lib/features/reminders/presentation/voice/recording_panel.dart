import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/chrome/memo_chrome.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/ui/memo_loader.dart';
import '../../../../core/ui/memo_nav_bar.dart';
import '../../../../core/ui/memo_sheet.dart';
import '../../../../l10n/l10n.dart';
import '../../data/voice_clip.dart';
import '../home/capture_cubit.dart';
import '../widgets/key_value_row.dart';
import '../widgets/section_card.dart';

String _mmss(Duration d) =>
    '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

/// Recording, understanding and "couldn't" in one sheet-shaped panel. Drawn
/// by the Home stack above the capture bar, never as a route: the mic under
/// it keeps its tree slot and its pointer.
class RecordingPanel extends StatelessWidget {
  const RecordingPanel({super.key, required this.state});

  final CaptureState state;

  @override
  Widget build(BuildContext context) {
    return MemoChrome(
      shape: ChromeShape.sheet,
      solid: true,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          MemoSpace.gutter,
          MemoSpace.space6,
          MemoSpace.gutter,
          MediaQuery.paddingOf(context).bottom + MemoSpace.space4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: switch (state.phase) {
            CapturePhase.recording => _recording(context),
            CapturePhase.transcribing => _transcribing(context),
            _ => _failed(context),
          },
        ),
      ),
    );
  }

  List<Widget> _recording(BuildContext context) {
    final c = MemoColors.of(context);
    final l = context.l10n;
    final cubit = context.read<CaptureCubit>();
    return [
      Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: c.accentText,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: MemoSpace.space2),
          Semantics(
            liveRegion: true,
            child: Text(
              l.recRecording,
              style: MemoType.bodyLarge.copyWith(
                color: c.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          Text(
            l.recTimer(_mmss(state.recorded), _mmss(VoiceClip.maxLength)),
            style: MemoType.labelMedium.copyWith(color: c.ink70),
          ),
        ],
      ),
      const SizedBox(height: MemoSpace.space2),
      Text(l.recHint, style: MemoType.body.copyWith(color: c.ink70)),
      const SizedBox(height: MemoSpace.space4),
      _LevelMeter(level: state.level),
      const SizedBox(height: MemoSpace.space4),
      Row(
        children: [
          // The theme's buttons are full width: let Cancel take the rest.
          Expanded(
            child: OutlinedButton(
              onPressed: cubit.cancelRecording,
              child: Text(l.commonCancel),
            ),
          ),
          const SizedBox(width: MemoSpace.space4),
          Semantics(
            button: true,
            label: l.recStopLabel,
            onTap: cubit.toggleRecording,
            excludeSemantics: true,
            child: GestureDetector(
              onTap: cubit.toggleRecording,
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: c.accentText,
                  shape: BoxShape.circle,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: c.onAccent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: MemoSpace.space1),
                    Text(
                      l.recStop,
                      style: MemoType.labelMedium.copyWith(color: c.onAccent),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: MemoSpace.space3),
      Text(
        state.latched ? l.recTipHold : l.recReleaseToStop,
        textAlign: TextAlign.center,
        style: MemoType.body.copyWith(
          fontSize: 13,
          height: 18 / 13,
          color: c.ink70,
        ),
      ),
    ];
  }

  List<Widget> _transcribing(BuildContext context) {
    final c = MemoColors.of(context);
    final l = context.l10n;
    return [
      Row(
        children: [
          const MemoLoader(),
          const SizedBox(width: MemoSpace.space3),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                l.recUnderstanding,
                style: MemoType.bodyLarge.copyWith(
                  color: c.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: MemoSpace.space2),
      Text(
        l.recOnThisPhone(endonyms[context.read<CaptureCubit>().inputLocale()]!),
        style: MemoType.body.copyWith(color: c.ink70),
      ),
      const SizedBox(height: MemoSpace.space4),
      SectionCard(
        children: [
          KeyValueRow(
            label: l.recRecording,
            child: PillValue(_mmss(state.recorded)),
          ),
        ],
      ),
      const SizedBox(height: MemoSpace.space4),
      OutlinedButton(
        onPressed: context.read<CaptureCubit>().cancelTranscription,
        child: Text(l.commonCancel),
      ),
    ];
  }

  List<Widget> _failed(BuildContext context) {
    final c = MemoColors.of(context);
    final l = context.l10n;
    final cubit = context.read<CaptureCubit>();
    final failure = state.failure;
    final language = endonyms[context.read<CaptureCubit>().inputLocale()]!;
    return [
      Semantics(
        liveRegion: true,
        child: SheetHeading(
          failure == VoiceFailure.cancelled ? l.recKeptTitle : l.recFailedTitle,
          body: switch (failure) {
            VoiceFailure.unavailable => l.recFailedUnavailable(language),
            VoiceFailure.empty => l.recFailedEmpty,
            _ => l.recKeptBody,
          },
        ),
      ),
      SectionCard(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: MemoSpace.space2),
              child: Row(
                children: [
                  MemoIconButton(
                    icon: Icons.play_arrow_rounded,
                    label: l.voicePlay,
                    onPressed: () {
                      final path = cubit.media?.draftVoicePath;
                      if (path != null) cubit.voice?.play(path);
                    },
                  ),
                  const SizedBox(width: MemoSpace.space2),
                  Expanded(
                    child: Text(
                      _mmss(state.recorded),
                      style: MemoType.labelMedium.copyWith(color: c.ink),
                    ),
                  ),
                  PillValue(l.recKept),
                  const SizedBox(width: MemoSpace.space2),
                ],
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: MemoSpace.space4),
      ElevatedButton(
        onPressed: cubit.typeInstead,
        child: Text(l.recTypeInstead),
      ),
      const SizedBox(height: MemoSpace.space2),
      OutlinedButton(
        onPressed: cubit.saveAsVoiceNote,
        child: Text(l.recSaveAsNote),
      ),
      const SizedBox(height: MemoSpace.space1),
      TextButton(onPressed: cubit.tryAgain, child: Text(l.commonTryAgain)),
    ];
  }
}

/// Seven bars from the real input level; no implicit animation, the level
/// itself arrives about four times a second.
class _LevelMeter extends StatelessWidget {
  const _LevelMeter({required this.level});

  final double level;

  static const _weights = [.5, .8, 1, .7, 1, .6, .4];

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    return ExcludeSemantics(
      child: SizedBox(
        height: 20,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < _weights.length; i++) ...[
              if (i > 0) const SizedBox(width: MemoSpace.space1),
              Container(
                width: 6,
                height: 4 + 16 * level * _weights[i],
                decoration: BoxDecoration(
                  color: c.accentText,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
