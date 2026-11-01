import '../domain/entities/reminder.dart';
import '../domain/entities/repeat_rule.dart';

/// Row <-> entity mapping for the `reminders` table (schema v2).
extension ReminderRow on Reminder {
  Map<String, Object?> toRow() => {
    'id': id,
    'title': title,
    'note': note,
    'due_at': dueAt.millisecondsSinceEpoch,
    'repeat_type': repeat.type.name,
    'repeat_weekdays': repeat.weekdays.isEmpty
        ? null
        : (repeat.weekdays.toList()..sort()).join(','),
    'tag': tag,
    'done_at': doneAt?.millisecondsSinceEpoch,
    'created_at': createdAt.millisecondsSinceEpoch,
    'pre_alarm_min': preAlarmMin,
    'nag_min': nagMin,
    'nag_count': nagCount,
    'has_voice': hasVoice ? 1 : 0,
    'voice_rings': readAloud ? 1 : 0,
    'has_image': hasImage ? 1 : 0,
    'needs_schedule': needsSchedule ? 1 : 0,
    'snoozed_until': snoozedUntil?.millisecondsSinceEpoch,
  };
}

DateTime? _time(Object? ms) =>
    ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms as int);

Reminder reminderFromRow(Map<String, Object?> row) {
  final weekdays = row['repeat_weekdays'] as String?;
  return Reminder(
    id: row['id']! as String,
    title: row['title']! as String,
    note: row['note'] as String?,
    dueAt: _time(row['due_at'])!,
    repeat: RepeatRule(
      RepeatType.values.byName(row['repeat_type']! as String),
      weekdays: (weekdays == null || weekdays.isEmpty)
          ? const {}
          : weekdays.split(',').map(int.parse).toSet(),
    ),
    tag: row['tag'] as String?,
    doneAt: _time(row['done_at']),
    createdAt: _time(row['created_at'])!,
    preAlarmMin: row['pre_alarm_min'] as int?,
    nagMin: row['nag_min'] as int?,
    nagCount: row['nag_count']! as int,
    hasVoice: row['has_voice'] == 1,
    readAloud: row['voice_rings'] == 1,
    hasImage: row['has_image'] == 1,
    needsSchedule: row['needs_schedule'] == 1,
    snoozedUntil: _time(row['snoozed_until']),
  );
}
