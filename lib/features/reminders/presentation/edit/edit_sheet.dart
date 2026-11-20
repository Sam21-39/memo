import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/app_prefs.dart';
import '../../../../core/di.dart';
import '../../../../core/feature_flags/feature_flags.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/ui/memo_pickers.dart';
import '../../../../core/ui/motion.dart';
import '../../../../core/ui/option_button.dart';
import '../../../../core/ui/minutes_sheet.dart';
import '../../../../core/ui/memo_sheet.dart';
import '../../../../core/utils/date_format.dart';
import '../../../tags/presentation/tag_color.dart';
import '../../../tags/presentation/widgets/tag_chip.dart';
import '../../data/media_store.dart';
import '../../data/voice_clip.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/repeat_rule.dart';
import '../../domain/usecases/save_reminder.dart';
import '../widgets/day_section_header.dart';
import '../widgets/key_value_row.dart';
import '../widgets/repeat_segmented_control.dart';
import '../widgets/section_card.dart';
import '../widgets/voice_notice.dart';
import '../widgets/weekday_selector.dart';
import 'edit_cubit.dart';
import '../../../../l10n/l10n.dart';

/// Artboard Edit-Reminder: create or edit in a sheet over Home or Detail.
/// Saves (write + schedule) itself; a schedule failure is shown, then the
/// sheet closes because the row is saved and will retry.
///
/// [draft] prefills a new reminder (the capture bar's "More"); [draftClip]
/// says a recorded clip waits in the draft file. Returns true once saved.
Future<bool> showEditSheet(
  BuildContext context, {
  Reminder? existing,
  Reminder? draft,
  bool draftClip = false,
  List<String>? knownTags,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final saved = await showMemoSheet<bool>(
    context,
    tall: true,
    builder: (_) => BlocProvider(
      create: (_) => EditCubit(
        sl<SaveReminder>(),
        existing: existing,
        draft: draft,
        draftClip: draftClip,
        defaultNagMin: sl<AppPrefs>().defaultNagMin,
        readAloudDefault: sl<AppPrefs>().readAloudDefault,
        media: sl<MediaStore>(),
        voice: sl<VoiceClip>(),
      ),
      child: BlocListener<EditCubit, EditState>(
        listenWhen: (a, b) => b.status == EditStatus.saved,
        listener: (context, state) {
          if (state.error != null) {
            messenger?.showSnackBar(SnackBar(content: Text(state.error!)));
          }
          HapticFeedback.lightImpact();
          Navigator.of(context).pop(true);
        },
        child: EditForm(knownTags: knownTags ?? const []),
      ),
    ),
  );
  return saved ?? false;
}

class EditForm extends StatefulWidget {
  const EditForm({super.key, required this.knownTags});

  final List<String> knownTags;

  @override
  State<EditForm> createState() => _EditFormState();
}

class _EditFormState extends State<EditForm> {
  late final _title = TextEditingController(
    text: context.read<EditCubit>().state.title,
  );
  late final _note = TextEditingController(
    text: context.read<EditCubit>().state.note,
  );

  late final _lifecycle = AppLifecycleListener(
    onHide: () => context.read<EditCubit>().cancelRecording(),
    onPause: () => context.read<EditCubit>().cancelRecording(),
  );

  @override
  void initState() {
    super.initState();
    // Built now: each field is off-screen in one of the two views, and a lazy
    // first touch inside dispose() cannot look up the cubit.
    _title;
    _note;
    _lifecycle;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    final flags = sl<FeatureFlags>();
    final cubit = context.read<EditCubit>();
    final l = context.l10n;
    return BlocBuilder<EditCubit, EditState>(
      builder: (context, state) {
        final isNew = state.existing == null;
        final status = [
          if (state.notice != null && state.status == EditStatus.editing)
            Padding(
              padding: const EdgeInsets.only(top: MemoSpace.space2),
              child: Text(
                state.notice!,
                style: MemoType.body.copyWith(color: c.ink70),
              ),
            ),
          if (state.error != null && state.status == EditStatus.editing)
            Padding(
              padding: const EdgeInsets.only(top: MemoSpace.space2),
              child: Text(
                state.error!,
                style: MemoType.body.copyWith(color: c.destructive),
              ),
            ),
        ];
        // Basic and More options are two views of one sheet: same header
        // shape, one cross-fade between them.
        Widget view(
          String key,
          Widget leading,
          String title,
          List<Widget> children,
        ) => Column(
          key: ValueKey(key),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Shares of the width, so scaled buttons wrap rather than overflow.
            Row(
              children: [
                Flexible(flex: 3, child: leading),
                Expanded(
                  flex: 4,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: MemoType.bodyLarge.copyWith(
                      color: c.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Flexible(
                  flex: 3,
                  child: TextButton(
                    onPressed: state.canSave ? cubit.save : null,
                    child: Text(l.commonSave),
                  ),
                ),
              ],
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(top: MemoSpace.space4),
                children: [
                  ...children,
                  ...status,
                  const SizedBox(height: MemoSpace.space4),
                ],
              ),
            ),
          ],
        );
        return AnimatedSwitcher(
          duration: motion(context, MemoMotion.base),
          switchInCurve: MemoMotion.curve,
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.topCenter,
            children: [...previous, ?current],
          ),
          child: state.advanced
              ? view(
                  'advanced',
                  TextButton(
                    onPressed: () => cubit.showAdvanced(false),
                    style: TextButton.styleFrom(foregroundColor: c.ink),
                    child: Text(l.editBackBasic),
                  ),
                  l.editMoreTitle,
                  _advanced(context, c, flags, cubit, state),
                )
              : view(
                  'basic',
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(foregroundColor: c.ink),
                    child: Text(l.commonCancel),
                  ),
                  isNew ? l.editNew : l.editExisting,
                  _basic(context, c, flags, cubit, state, isNew),
                ),
        );
      },
    );
  }

  Widget _label(MemoColors c, String text) => Padding(
    padding: const EdgeInsets.only(bottom: MemoSpace.space2),
    child: Text(
      text,
      style: MemoType.body.copyWith(
        color: c.ink70,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  List<Widget> _basic(
    BuildContext context,
    MemoColors c,
    FeatureFlags flags,
    EditCubit cubit,
    EditState state,
    bool isNew,
  ) {
    final l = context.l10n;
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final today = isSameDay(state.dueAt, now);
    final tmrw = isSameDay(state.dueAt, tomorrow);
    DateTime onDay(DateTime day) => DateTime(
      day.year,
      day.month,
      day.day,
      state.dueAt.hour,
      state.dueAt.minute,
    );
    Future<void> pickDay() async {
      final d = await pickDate(context, state.dueAt);
      if (d != null) cubit.setDueAt(d);
    }

    Future<void> pickClock() async {
      final t = await pickTime(context, state.dueAt);
      if (t != null) cubit.setDueAt(t);
    }

    return [
      _label(c, l.editWhat),
      TextField(
        controller: _title,
        autofocus: isNew,
        textCapitalization: TextCapitalization.sentences,
        onChanged: cubit.setTitle,
        style: MemoType.bodyLarge.copyWith(color: c.ink),
        decoration: InputDecoration(hintText: l.reminderHint),
      ),
      const SizedBox(height: MemoSpace.space6),
      DaySectionHeader(label: l.fieldWhen),
      Wrap(
        spacing: MemoSpace.space2,
        runSpacing: MemoSpace.space2,
        children: [
          OptionButton(
            label: l.dateToday,
            selected: today,
            onTap: () => cubit.setDueAt(onDay(now)),
          ),
          OptionButton(
            label: l.dateTomorrow,
            selected: tmrw,
            onTap: () => cubit.setDueAt(onDay(tomorrow)),
          ),
          OptionButton(
            label: today || tmrw
                ? l.editPickDate
                : formatDate(context, state.dueAt),
            selected: !today && !tmrw,
            onTap: pickDay,
          ),
        ],
      ),
      const SizedBox(height: MemoSpace.space2),
      Wrap(
        spacing: MemoSpace.space2,
        runSpacing: MemoSpace.space2,
        children: [
          OptionButton(
            label: formatTime(context, state.dueAt),
            selected: true,
            onTap: pickClock,
          ),
          OptionButton(label: l.editChangeTime, onTap: pickClock),
        ],
      ),
      if (state.pastBlocked(now))
        Padding(
          padding: const EdgeInsets.only(top: MemoSpace.space2),
          child: Text(
            l.timePassed,
            style: MemoType.body.copyWith(color: c.destructive),
          ),
        ),
      if (flags.repeatReminders) ...[
        const SizedBox(height: MemoSpace.space6),
        DaySectionHeader(label: l.fieldRepeat),
        _RepeatPicker(state: state),
      ],
      const SizedBox(height: MemoSpace.space6),
      OutlinedButton(
        onPressed: () => cubit.showAdvanced(true),
        child: Text(l.editMoreOptions, textAlign: TextAlign.center),
      ),
    ];
  }

  List<Widget> _advanced(
    BuildContext context,
    MemoColors c,
    FeatureFlags flags,
    EditCubit cubit,
    EditState state,
  ) {
    final l = context.l10n;
    return [
      _label(c, l.editNote),
      TextField(
        controller: _note,
        maxLines: null,
        textCapitalization: TextCapitalization.sentences,
        onChanged: cubit.setNote,
        style: MemoType.body.copyWith(color: c.ink),
        decoration: InputDecoration(hintText: l.editNoteHint),
      ),
      const SizedBox(height: MemoSpace.space6),
      SectionCard(
        children: [
          if (flags.tags)
            KeyValueRow(
              label: l.fieldTag,
              onTap: () => showMemoSheet<void>(
                context,
                builder: (_) => BlocProvider.value(
                  value: cubit,
                  child: BlocBuilder<EditCubit, EditState>(
                    builder: (context, s) => SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SheetHeading(l.fieldTag),
                          _TagPicker(
                            knownTags: widget.knownTags,
                            selected: s.tag,
                            onChanged: cubit.setTag,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              child: PillValue(state.tag ?? l.commonNone),
            ),
          if (flags.preAlarm)
            KeyValueRow(
              label: l.editRemindEarlier,
              onTap: () async {
                final m = await showMinutesSheet(
                  context,
                  title: l.editRemindEarlier,
                  body: l.editPreAlarmBody,
                  presets: const [5, 15, 30, 60],
                  current: state.preAlarmMin,
                  label: (m) => preAlarmLabel(l, m),
                );
                if (m != null) cubit.setPreAlarm(m == 0 ? null : m);
              },
              child: PillValue(
                state.preAlarmMin == null
                    ? l.commonOff
                    : preAlarmLabel(l, state.preAlarmMin!),
              ),
            ),
          if (flags.nag)
            KeyValueRow(
              label: l.editNagTitle,
              onTap: () async {
                final m = await showMinutesSheet(
                  context,
                  title: l.editNagTitle,
                  body: l.editNagBody,
                  presets: const [5, 10, 30],
                  current: state.nagMin,
                  label: (m) => nagLabel(l, m),
                );
                if (m != null) cubit.setNag(m == 0 ? null : m);
              },
              child: PillValue(
                state.nagMin == null
                    ? l.commonOff
                    : l.nagSummary(state.nagMin!),
              ),
            ),
        ],
      ),
      if (cubit.media != null && cubit.voice != null) ...[
        const SizedBox(height: MemoSpace.space6),
        DaySectionHeader(label: l.editSound),
        _SoundCard(state: state),
      ],
      const SizedBox(height: MemoSpace.space4),
      Text(l.editOptionalBody, style: MemoType.body.copyWith(color: c.ink70)),
    ];
  }
}

/// Hold the mic to record (30 s cap); the clip rings unless switched off.
class _SoundCard extends StatelessWidget {
  const _SoundCard({required this.state});

  final EditState state;

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    final cubit = context.read<EditCubit>();
    final mono = MemoType.labelMedium.copyWith(color: c.ink70);
    String secs(Duration d) => '0:${d.inSeconds.toString().padLeft(2, '0')}';

    final Widget row;
    if (state.hasClip && !state.recording) {
      final path = cubit.clipPath!;
      row = Row(
        children: [
          IconButton(
            tooltip: context.l10n.voicePlay,
            onPressed: () => sl<VoiceClip>().play(path),
            style: IconButton.styleFrom(
              fixedSize: const Size.square(36),
              backgroundColor: c.ink6,
            ),
            icon: Icon(Icons.play_arrow_rounded, color: c.ink, size: 18),
          ),
          const SizedBox(width: MemoSpace.space3),
          Expanded(
            child: Text(
              context.l10n.clipNote(MediaStore.clipLength(path)),
              style: mono,
            ),
          ),
          IconButton(
            tooltip: context.l10n.voiceDelete,
            onPressed: cubit.deleteClip,
            icon: Icon(Icons.close_rounded, color: c.ink70, size: 18),
          ),
        ],
      );
    } else {
      // One row for idle and recording, the mic in the same slot: rebuilding
      // it mid-hold would lose the release and the clip would run to 30 s.
      row = Row(
        children: [
          Expanded(
            child: state.recording
                ? Row(
                    children: [
                      Text(
                        context.l10n.captureElapsed(secs(state.recorded)),
                        style: mono.copyWith(color: c.accentText),
                      ),
                      Text(
                        context.l10n.editRecordingMax(
                          secs(VoiceClip.maxLength),
                        ),
                        style: mono,
                      ),
                      const SizedBox(width: MemoSpace.space3),
                      Expanded(
                        child: Text(
                          state.latched
                              ? context.l10n.micTapToStop
                              : context.l10n.editReleaseToStop,
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: mono,
                        ),
                      ),
                    ],
                  )
                : Text(context.l10n.editHoldToRecordNote, style: mono),
          ),
          const SizedBox(width: MemoSpace.space3),
          _HoldToRecord(cubit: cubit, active: state.recording),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          children: [
            KeyValueRow(
              label: context.l10n.editReadAloudWhenRings,
              onTap: () => cubit.setReadAloud(!state.readAloud),
              child: PillValue(
                state.readAloud
                    ? context.l10n.commonOn
                    : context.l10n.commonOff,
                active: state.readAloud,
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: MemoSpace.space4,
                ),
                child: Align(alignment: Alignment.centerLeft, child: row),
              ),
            ),
          ],
        ),
        VoiceNotice(
          title: state.title,
          readAloud: state.readAloud,
          hasVoice: state.hasClip,
        ),
      ],
    );
  }
}

class _HoldToRecord extends StatelessWidget {
  const _HoldToRecord({required this.cubit, this.active = false});

  final EditCubit cubit;

  /// Recording: the button grows so the hold reads as live.
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    // Raw pointer events, not a long-press: a long-press waits 500 ms and the
    // sheet's scrolling can cancel it mid-hold. Down records, up stops.
    return Semantics(
      button: true,
      label: context.l10n.micRecord,
      hint: active ? context.l10n.micTapToStop : context.l10n.micTapToStart,
      onTap: cubit.toggleRecording,
      excludeSemantics: true,
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
    );
  }
}

class _RepeatPicker extends StatelessWidget {
  const _RepeatPicker({required this.state});

  final EditState state;

  RepeatOption get _option => switch (state.repeat.type) {
    RepeatType.none => RepeatOption.none,
    RepeatType.daily => RepeatOption.daily,
    RepeatType.weekly =>
      state.repeat.weekdays.length == 1
          ? RepeatOption.weekly
          : RepeatOption.custom,
  };

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EditCubit>();
    final weekday = state.dueAt.weekday;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RepeatSegmentedControl(
          value: _option,
          onChanged: (option) => cubit.setRepeat(switch (option) {
            RepeatOption.none => RepeatRule.none,
            RepeatOption.daily => RepeatRule.daily,
            RepeatOption.weekly => RepeatRule(
              RepeatType.weekly,
              weekdays: {weekday},
            ),
            // Seed custom with this weekday plus the next, so the picker
            // opens on a real multi-day rule, not a duplicate of Weekly.
            RepeatOption.custom => RepeatRule(
              RepeatType.weekly,
              weekdays: state.repeat.weekdays.length > 1
                  ? state.repeat.weekdays
                  : {weekday, weekday % 7 + 1},
            ),
          }),
        ),
        if (_option == RepeatOption.custom) ...[
          const SizedBox(height: MemoSpace.space3),
          WeekdaySelector(
            selected: state.repeat.weekdays,
            onChanged: (days) {
              if (days.isEmpty) return; // Weekly needs at least one day.
              cubit.setRepeat(RepeatRule(RepeatType.weekly, weekdays: days));
            },
          ),
        ],
      ],
    );
  }
}

class _TagPicker extends StatelessWidget {
  const _TagPicker({
    required this.knownTags,
    required this.selected,
    required this.onChanged,
  });

  final List<String> knownTags;
  final String? selected;
  final ValueChanged<String?> onChanged;

  Future<void> _addTag(BuildContext context) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _NewTagDialog(),
    );
    if (name != null && name.isNotEmpty) onChanged(name);
  }

  @override
  Widget build(BuildContext context) {
    // A tag just typed is not in knownTags yet; show it so the selection is
    // visible.
    final tags = [
      ...knownTags,
      if (selected != null && !knownTags.contains(selected)) selected!,
    ];
    return Wrap(
      spacing: MemoSpace.space2,
      runSpacing: MemoSpace.space2,
      children: [
        for (final tag in tags)
          TagChip(
            label: tag,
            dotColor: tagColor(tag),
            selected: tag == selected,
            // Tapping the selected tag clears it: one flat tag, optional.
            onTap: () => onChanged(tag == selected ? null : tag),
          ),
        TagChip(
          label: context.l10n.editNewTagChip,
          dashed: true,
          onTap: () => _addTag(context),
        ),
      ],
    );
  }
}

/// Owns its controller so its lifetime matches the dialog's route.
class _NewTagDialog extends StatefulWidget {
  const _NewTagDialog();

  @override
  State<_NewTagDialog> createState() => _NewTagDialogState();
}

class _NewTagDialogState extends State<_NewTagDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.editNewTagTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(hintText: context.l10n.editTagHint),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.commonCancel),
        ),
        TextButton(onPressed: _submit, child: Text(context.l10n.commonAdd)),
      ],
    );
  }
}
