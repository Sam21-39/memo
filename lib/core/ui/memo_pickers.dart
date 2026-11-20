import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'memo_sheet.dart';
import '../../l10n/l10n.dart';

/// Native pickers: CupertinoDatePicker inside a Memō sheet on iOS, Material
/// date and time pickers on Android. Returns null when dismissed.
Future<DateTime?> pickDate(BuildContext context, DateTime initial) async {
  final now = DateTime.now();
  // An old reminder being edited must stay pickable.
  final first = initial.isBefore(now) ? initial : DateTime(now.year - 1);
  final last = DateTime(now.year + 5);
  if (Theme.of(context).platform == TargetPlatform.iOS) {
    return _cupertino(
      context,
      initial,
      CupertinoDatePickerMode.date,
      first,
      last,
    );
  }
  final picked = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: first,
    lastDate: last,
  );
  return picked == null
      ? null
      : DateTime(
          picked.year,
          picked.month,
          picked.day,
          initial.hour,
          initial.minute,
        );
}

Future<DateTime?> pickTime(BuildContext context, DateTime initial) async {
  if (Theme.of(context).platform == TargetPlatform.iOS) {
    return _cupertino(context, initial, CupertinoDatePickerMode.time);
  }
  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
  );
  return picked == null
      ? null
      : DateTime(
          initial.year,
          initial.month,
          initial.day,
          picked.hour,
          picked.minute,
        );
}

Future<DateTime?> _cupertino(
  BuildContext context,
  DateTime initial,
  CupertinoDatePickerMode mode, [
  DateTime? first,
  DateTime? last,
]) {
  var value = initial;
  return showMemoSheet<DateTime>(
    context,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 216,
          child: CupertinoDatePicker(
            mode: mode,
            use24hFormat: MediaQuery.alwaysUse24HourFormatOf(context),
            initialDateTime: initial,
            minimumDate: first,
            maximumDate: last,
            onDateTimeChanged: (v) => value = v,
          ),
        ),
        const SizedBox(height: MemoSpace.space4),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(value),
          child: Text(context.l10n.commonDone),
        ),
      ],
    ),
  );
}
