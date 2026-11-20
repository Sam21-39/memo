import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';
import 'memo_sheet.dart';
import '../../l10n/l10n.dart';

/// Pick a number of minutes from presets, Off, or any custom number.
/// Returns 0 for Off, the minutes otherwise, null when dismissed.
Future<int?> showMinutesSheet(
  BuildContext context, {
  required String title,
  required String body,
  required List<int> presets,
  required int? current,
  required String Function(int minutes) label,
}) {
  return showMemoSheet<int>(
    context,
    builder: (context) => _MinutesPicker(
      title: title,
      body: body,
      presets: presets,
      current: current,
      label: label,
    ),
  );
}

class _MinutesPicker extends StatefulWidget {
  const _MinutesPicker({
    required this.title,
    required this.body,
    required this.presets,
    required this.current,
    required this.label,
  });

  final String title;
  final String body;
  final List<int> presets;
  final int? current;
  final String Function(int minutes) label;

  @override
  State<_MinutesPicker> createState() => _MinutesPickerState();
}

class _MinutesPickerState extends State<_MinutesPicker> {
  late final _custom = TextEditingController(
    text: widget.current != null && !widget.presets.contains(widget.current)
        ? '${widget.current}'
        : '',
  );

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  void _submitCustom() {
    final v = int.tryParse(_custom.text);
    if (v != null && v > 0 && v <= 24 * 60) Navigator.of(context).pop(v);
  }

  @override
  Widget build(BuildContext context) {
    final c = MemoColors.of(context);
    Widget option(String text, int value) {
      final selected = (widget.current ?? 0) == value;
      return Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          onTap: () => Navigator.of(context).pop(value),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    text,
                    style: MemoType.bodyLarge.copyWith(
                      color: c.ink,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                if (selected) Icon(Icons.check_rounded, color: c.accentText),
              ],
            ),
          ),
        ),
      );
    }

    return ListView(
      shrinkWrap: true,
      children: [
        SheetHeading(widget.title, body: widget.body),
        option(context.l10n.commonOff, 0),
        for (final m in widget.presets) option(widget.label(m), m),
        const SizedBox(height: MemoSpace.space2),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _custom,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: MemoType.body.copyWith(color: c.ink),
                decoration: InputDecoration(
                  hintText: context.l10n.minutesCustomHint,
                ),
                onSubmitted: (_) => _submitCustom(),
              ),
            ),
            TextButton(
              onPressed: _submitCustom,
              child: Text(context.l10n.commonSet),
            ),
          ],
        ),
      ],
    );
  }
}

String nagLabel(AppLocalizations l, int m) => l.everyMinutes(m);
String preAlarmLabel(AppLocalizations l, int m) =>
    m % 60 == 0 ? l.hoursBefore(m ~/ 60) : l.minutesBefore(m);
