import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/app_prefs.dart';
import '../../../../core/di.dart';
import '../../../../core/feature_flags/feature_flags.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/ui/memo_pickers.dart';
import '../../../../core/ui/memo_sheet.dart';
import '../../../../core/utils/date_format.dart';
import '../../../tags/presentation/tag_color.dart';
import '../../../tags/presentation/widgets/tag_chip.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/repeat_rule.dart';
import '../../domain/usecases/save_reminder.dart';
import '../widgets/day_section_header.dart';
import '../widgets/key_value_row.dart';
import '../widgets/repeat_segmented_control.dart';
import '../widgets/section_card.dart';
import '../widgets/weekday_selector.dart';
import 'edit_cubit.dart';

/// Artboard Edit-Reminder: create or edit in a sheet over Home or Detail.
/// Saves (write + schedule) itself; a schedule failure is shown, then the
/// sheet closes because the row is saved and will retry.
Future<void> showEditSheet(
  BuildContext context, {
  Reminder? existing,
  List<String>? knownTags,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  return showMemoSheet<void>(
    context,
    tall: true,
    builder: (_) => BlocProvider(
      create: (_) => EditCubit(
        sl<SaveReminder>(),
        existing: existing,
        defaultNagMin: sl<AppPrefs>().defaultNagMin,
      ),
      child: BlocListener<EditCubit, EditState>(
        listenWhen: (a, b) => b.status == EditStatus.saved,
        listener: (context, state) {
          if (state.error != null) {
            messenger?.showSnackBar(SnackBar(content: Text(state.error!)));
          }
          Navigator.of(context).pop();
        },
        child: EditForm(knownTags: knownTags ?? const []),
      ),
    ),
  );
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

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    final flags = sl<FeatureFlags>();
    final cubit = context.read<EditCubit>();
    return BlocBuilder<EditCubit, EditState>(
      builder: (context, state) {
        final isNew = state.existing == null;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(foregroundColor: c.ink),
                  child: const Text('Cancel'),
                ),
                Expanded(
                  child: Text(
                    isNew ? 'New reminder' : 'Edit reminder',
                    textAlign: TextAlign.center,
                    style: MemoType.bodyLarge.copyWith(
                      color: c.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: state.canSave ? cubit.save : null,
                  child: const Text('Save'),
                ),
              ],
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(top: MemoSpace.space4),
                children: [
                  TextField(
                    controller: _title,
                    autofocus: isNew,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: cubit.setTitle,
                    style: MemoType.bodyLarge.copyWith(color: c.ink),
                    decoration: const InputDecoration(
                      hintText: 'Remind me to…',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _note,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: cubit.setNote,
                    style: MemoType.body.copyWith(color: c.ink),
                    decoration: const InputDecoration(hintText: 'Add a note'),
                  ),
                  const SizedBox(height: MemoSpace.space6),
                  const DaySectionHeader(label: 'When'),
                  SectionCard(
                    children: [
                      KeyValueRow(
                        label: 'Time',
                        onTap: () async {
                          final t = await pickTime(context, state.dueAt);
                          if (t != null) cubit.setDueAt(t);
                        },
                        child: PillValue(formatTime(state.dueAt), active: true),
                      ),
                      KeyValueRow(
                        label: 'Date',
                        onTap: () async {
                          final d = await pickDate(context, state.dueAt);
                          if (d != null) cubit.setDueAt(d);
                        },
                        child: PillValue(
                          dayHeaderLabel(state.dueAt, DateTime.now()),
                        ),
                      ),
                      if (flags.preAlarm)
                        KeyValueRow(
                          label: 'Pre-alarm',
                          child: PillValue(
                            state.preAlarmMin == null
                                ? 'Off'
                                : '${state.preAlarmMin} min before',
                          ),
                        ),
                      if (flags.nag)
                        KeyValueRow(
                          label: 'Nag until done',
                          child: PillValue(
                            state.nagMin == null
                                ? 'Off'
                                : 'Every ${state.nagMin} min',
                          ),
                        ),
                    ],
                  ),
                  if (state.isPastOneOff(DateTime.now()))
                    Padding(
                      padding: const EdgeInsets.only(top: MemoSpace.space2),
                      child: Text(
                        'That time has passed. It will show as overdue and '
                        'will not ring.',
                        style: MemoType.body.copyWith(color: c.destructive),
                      ),
                    ),
                  if (flags.repeatReminders) ...[
                    const SizedBox(height: MemoSpace.space6),
                    const DaySectionHeader(label: 'Repeat'),
                    _RepeatPicker(state: state),
                  ],
                  if (flags.tags) ...[
                    const SizedBox(height: MemoSpace.space6),
                    const DaySectionHeader(label: 'Tag'),
                    _TagPicker(
                      knownTags: widget.knownTags,
                      selected: state.tag,
                      onChanged: cubit.setTag,
                    ),
                  ],
                  const SizedBox(height: MemoSpace.space4),
                ],
              ),
            ),
          ],
        );
      },
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
        TagChip(label: '+ New', dashed: true, onTap: () => _addTag(context)),
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
      title: const Text('New tag'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(hintText: 'Home, Work, Health…'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
