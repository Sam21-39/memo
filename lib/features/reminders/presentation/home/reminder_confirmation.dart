import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/ui/option_button.dart';
import '../../../../core/ui/section_label.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../l10n/l10n.dart';
import '../../data/media_store.dart';
import '../../domain/parser/reminder_parser.dart';
import '../repeat_label.dart';
import '../widgets/key_value_row.dart';
import '../widgets/section_card.dart';
import 'capture_bar.dart';
import 'capture_cubit.dart';
import 'capture_sheets.dart';

/// The step between typing (or speaking) and scheduling: what you said, how
/// Memō read it, and, when the time was a guess, a choice that blocks Save.
class ReminderConfirmation extends StatelessWidget {
  const ReminderConfirmation({
    super.key,
    required this.state,
    required this.knownTags,
  });

  final CaptureState state;
  final List<String> knownTags;

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    final l = context.l10n;
    final cubit = context.read<CaptureCubit>();
    final due = state.dueAt!;
    final now = DateTime.now();
    final voiceOnly = state.title.isEmpty;
    final mono15 = MemoType.labelMedium.copyWith(fontSize: 15, color: c.ink);
    final tag = state.tag;
    return Container(
      margin: EdgeInsets.fromLTRB(
        MemoSpace.space3,
        0,
        MemoSpace.space3,
        MediaQuery.paddingOf(context).bottom + MemoSpace.space3,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.hairline),
        borderRadius: BorderRadius.circular(MemoRadius.sheet),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!voiceOnly) ...[
            // Verbatim: never re-cased or trimmed of what the user said.
            Text(
              state.spoken
                  ? l.confirmYouSaid(state.text)
                  : l.confirmYouWrote(state.text),
              style: MemoType.body.copyWith(height: 22 / 15, color: c.ink70),
            ),
            const SizedBox(height: MemoSpace.space2),
          ],
          Semantics(
            header: true,
            child: Text(
              voiceOnly
                  ? l.voiceNoteTitle(
                      MediaStore.clipLength(cubit.media?.draftVoicePath ?? ''),
                    )
                  : state.title,
              style: MemoType.title.copyWith(height: 28 / 22, color: c.ink),
            ),
          ),
          const SizedBox(height: MemoSpace.space4),
          if (state.unsure case final unsure?)
            UnsureTimeBlock(state: state, unsure: unsure, now: now)
          else
            SectionCard(
              children: [
                KeyValueRow(
                  label: l.fieldWhen,
                  onTap: () async {
                    final at = await showWhenSheet(context, due);
                    if (at != null) cubit.chooseTime(at);
                  },
                  child: Text(formatWhen(context, due, now), style: mono15),
                ),
              ],
            ),
          const SizedBox(height: MemoSpace.space3),
          SectionCard(
            children: [
              KeyValueRow(
                label: l.fieldRepeat,
                onTap: () async {
                  final r = await showRepeatSheet(context, state.repeat, due);
                  if (r != null) cubit.setRepeat(r);
                },
                child: Text(
                  repeatLabel(context, state.repeat, none: l.repeatNone),
                  style: mono15,
                ),
              ),
              if (tag != null)
                KeyValueRow(
                  label: l.fieldTag,
                  onTap: () async {
                    final t = await showTagSheet(context, tag, knownTags);
                    if (t != null) cubit.setTag(t.isEmpty ? null : t);
                  },
                  child: Text(tag, style: mono15),
                ),
            ],
          ),
          if (state.error != null) ...[
            const SizedBox(height: MemoSpace.space3),
            Semantics(
              liveRegion: true,
              child: Text(
                state.error!,
                style: MemoType.body.copyWith(color: c.accentText),
              ),
            ),
          ],
          const SizedBox(height: MemoSpace.space4),
          ElevatedButton(
            onPressed: state.canSave ? cubit.save : null,
            child: Text(l.confirmSave),
          ),
          const SizedBox(height: MemoSpace.space2),
          OutlinedButton(
            onPressed:
                state.phase == CapturePhase.confirming && state.unsure == null
                ? () => openEditDetails(context, cubit, knownTags)
                : null,
            child: Text(l.confirmEdit),
          ),
        ],
      ),
    );
  }
}

/// "Is this the right time?" with the readings the parser could not choose
/// between. Save stays off until one is picked.
class UnsureTimeBlock extends StatelessWidget {
  const UnsureTimeBlock({
    super.key,
    required this.state,
    required this.unsure,
    required this.now,
  });

  final CaptureState state;
  final TimeAmbiguity unsure;
  final DateTime now;

  String _reason(BuildContext context) {
    final l = context.l10n;
    final span = unsure.span;
    final quoted = span != null && span.end <= state.text.length
        ? state.text.substring(span.start, span.end).trim()
        : '';
    if (unsure.kinds.contains(AmbiguityKind.dayWord) && quoted.isNotEmpty) {
      return l.confirmReasonDayWord(quoted);
    }
    if (unsure.kinds.contains(AmbiguityKind.amPm) && quoted.isNotEmpty) {
      return l.confirmReasonAmPm(quoted);
    }
    return l.confirmReasonNoTime;
  }

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    final l = context.l10n;
    final cubit = context.read<CaptureCubit>();
    final choices = unsure.choices;
    final sameDay = choices.every((t) => isSameDay(t, choices.first));
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(MemoSpace.space4),
        decoration: BoxDecoration(
          color: c.cautionSoft,
          border: Border.all(color: c.caution, width: 1.5),
          borderRadius: BorderRadius.circular(MemoRadius.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MemoSpace.space2,
                    vertical: MemoSpace.space1,
                  ),
                  decoration: BoxDecoration(
                    color: c.caution,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    sectionLabelText(context, l.confirmTimeBadge),
                    style: sectionLabelStyle(
                      context,
                    ).copyWith(fontWeight: FontWeight.w500, color: c.onAccent),
                  ),
                ),
                const SizedBox(width: MemoSpace.space2),
                Expanded(
                  child: Text(
                    l.confirmTimeQuestion,
                    style: MemoType.bodyLarge.copyWith(
                      color: c.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: MemoSpace.space2),
            Text(
              _reason(context),
              style: MemoType.body.copyWith(
                fontSize: 13,
                height: 18 / 13,
                color: c.ink70,
              ),
            ),
            const SizedBox(height: MemoSpace.space3),
            Wrap(
              spacing: MemoSpace.space2,
              runSpacing: MemoSpace.space2,
              children: [
                for (final choice in choices)
                  OptionButton(
                    label: sameDay
                        ? formatTime(context, choice)
                        : formatWhen(context, choice, now),
                    onTap: () => cubit.chooseTime(choice),
                  ),
                OptionButton(
                  label: l.confirmOtherTime,
                  onTap: () async {
                    final at = await showWhenSheet(context, choices.first);
                    if (at != null) cubit.chooseTime(at);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
