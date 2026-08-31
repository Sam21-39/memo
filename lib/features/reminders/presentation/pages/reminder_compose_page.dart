import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/feature_flags/feature_flags.dart';
import '../../../../core/feature_flags/feature_gate.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_format.dart';
import '../../../tags/presentation/tag_color.dart';
import '../../../tags/presentation/widgets/tag_chip.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/repeat_rule.dart';
import '../../domain/usecases/create_reminder.dart';
import '../widgets/key_value_row.dart';
import '../widgets/repeat_segmented_control.dart';
import '../widgets/section_card.dart';
import 'custom_repeat_sheet.dart';

/// Create or edit. Returns the composed [Reminder] via `Navigator.pop`, or
/// null when cancelled — the caller persists it.
class ReminderComposePage extends StatefulWidget {
  const ReminderComposePage({
    super.key,
    this.existing,
    this.knownTags = const [],
  });

  final Reminder? existing;
  final List<String> knownTags;

  @override
  State<ReminderComposePage> createState() => _ReminderComposePageState();
}

class _ReminderComposePageState extends State<ReminderComposePage> {
  late final TextEditingController _title;
  late final TextEditingController _note;
  late DateTime _scheduledAt;
  late RepeatRule _repeat;
  late String? _tag;

  final _flags = sl<FeatureFlags>();

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _title = TextEditingController(text: existing?.title ?? '');
    _note = TextEditingController(text: existing?.note ?? '');
    _repeat = existing?.repeat ?? RepeatRule.none;
    _tag = existing?.tag;
    _scheduledAt = existing?.scheduledAt ?? _defaultTime();
  }

  /// Next round hour, so the common case needs no time edit at all.
  static DateTime _defaultTime() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, now.hour + 1);
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  bool get _canSave => _title.text.trim().isNotEmpty;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    // showDatePicker asserts initialDate is within range, so an old reminder
    // being edited has to be able to widen it.
    final firstDate = DateTime(now.year - 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: _scheduledAt.isBefore(firstDate) ? _scheduledAt : firstDate,
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() {
      _scheduledAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _scheduledAt.hour,
        _scheduledAt.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (picked == null) return;
    setState(() {
      _scheduledAt = DateTime(
        _scheduledAt.year,
        _scheduledAt.month,
        _scheduledAt.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _onRepeatChanged(RepeatOption option) async {
    if (option != RepeatOption.custom) {
      setState(() {
        _repeat = switch (option) {
          RepeatOption.none => RepeatRule.none,
          RepeatOption.daily => RepeatRule.daily,
          RepeatOption.weekly => RepeatRule(
            RepeatType.weekly,
            weekdays: {_scheduledAt.weekday},
          ),
          RepeatOption.custom => _repeat,
        };
      });
      return;
    }
    final picked = await showCustomRepeatSheet(
      context,
      initial: _repeat.weekdays.isEmpty
          ? {_scheduledAt.weekday}
          : _repeat.weekdays,
      timeOfDay: _scheduledAt,
    );
    if (picked == null || picked.isEmpty) return;
    setState(() => _repeat = RepeatRule(RepeatType.weekly, weekdays: picked));
  }

  RepeatOption get _repeatOption => switch (_repeat.type) {
    RepeatType.none => RepeatOption.none,
    RepeatType.daily => RepeatOption.daily,
    RepeatType.weekly =>
      _repeat.weekdays.length == 1 ? RepeatOption.weekly : RepeatOption.custom,
  };

  void _save() {
    final note = _note.text.trim();
    final existing = widget.existing;
    final result =
        existing?.copyWith(
          title: _title.text.trim(),
          note: note.isEmpty ? null : note,
          clearNote: note.isEmpty,
          scheduledAt: _scheduledAt,
          repeat: _repeat,
          tag: _tag,
          clearTag: _tag == null,
        ) ??
        const CreateReminder()(
          title: _title.text,
          scheduledAt: _scheduledAt,
          now: DateTime.now(),
          note: note,
          repeat: _repeat,
          tag: _tag,
        );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TopBar(
              label: widget.existing == null ? 'New' : 'Edit',
              onCancel: () => Navigator.of(context).pop(),
              onSave: _canSave ? _save : null,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenGutter,
                  22,
                  AppSpacing.screenGutter,
                  AppSpacing.xxl,
                ),
                children: [
                  TextField(
                    controller: _title,
                    autofocus: widget.existing == null,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setState(() {}),
                    style: theme.textTheme.displayLarge?.copyWith(fontSize: 26),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: 'Remind me to…',
                      hintStyle: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 26,
                        color: scheme.onSurface.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _note,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: null,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: 'Add a note…',
                      hintStyle: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: scheme.onSurface.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SectionCard(
                    children: [
                      KeyValueRow(
                        label: 'Date',
                        onTap: _pickDate,
                        child: PillValue(formatDate(_scheduledAt)),
                      ),
                      KeyValueRow(
                        label: 'Time',
                        onTap: _pickTime,
                        child: PillValue(
                          formatTime(_scheduledAt),
                          emphasized: true,
                        ),
                      ),
                    ],
                  ),
                  FeatureGate(
                    enabled: _flags.repeatReminders,
                    child: _Labelled(
                      label: 'Repeat',
                      child: RepeatSegmentedControl(
                        value: _repeatOption,
                        onChanged: _onRepeatChanged,
                      ),
                    ),
                  ),
                  FeatureGate(
                    enabled: _flags.tags,
                    child: _Labelled(
                      label: 'Tag',
                      child: _TagPicker(
                        knownTags: widget.knownTags,
                        selected: _tag,
                        onChanged: (tag) => setState(() => _tag = tag),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.label, required this.onCancel, this.onSave});

  final String label;
  final VoidCallback onCancel;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenGutter,
        6,
        AppSpacing.screenGutter,
        0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: onCancel,
            child: Text(
              'Cancel',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: scheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Text(label.toUpperCase(), style: theme.textTheme.labelSmall),
          TextButton(
            onPressed: onSave,
            child: Text(
              'Save',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: onSave == null
                    ? scheme.onSurface.withValues(alpha: 0.3)
                    : scheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Labelled extends StatelessWidget {
  const _Labelled({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontSize: 10),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
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
    // A tag just typed into the dialog is not in knownTags yet — without it
    // here the new tag is selected but nothing on screen shows that.
    final tags = [
      ...knownTags,
      if (selected != null && !knownTags.contains(selected)) selected!,
    ];

    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        for (final tag in tags)
          TagChip(
            label: tag,
            dotColor: tagColor(tag),
            selected: tag == selected,
            // Tapping the selected tag clears it — one flat tag, optional.
            onTap: () => onChanged(tag == selected ? null : tag),
          ),
        TagChip(label: '+ New', dashed: true, onTap: () => _addTag(context)),
      ],
    );
  }
}

/// Owns its own controller so the controller's lifetime matches the dialog's.
/// Disposing it at the `showDialog` call site instead would kill it while the
/// route is still animating out, and the field would rebuild against it.
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
