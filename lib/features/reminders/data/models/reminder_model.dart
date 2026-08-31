import '../../domain/entities/reminder.dart';
import '../../domain/entities/repeat_rule.dart';

/// Row <-> entity mapping for the `reminders` table.
extension ReminderRow on Reminder {
  Map<String, Object?> toRow() => {
    'id': id,
    'title': title,
    'note': note,
    'scheduled_at': scheduledAt.millisecondsSinceEpoch,
    'repeat_type': repeat.type.name,
    'repeat_weekdays': repeat.weekdays.isEmpty
        ? null
        : (repeat.weekdays.toList()..sort()).join(','),
    'tag': tag,
    'is_done': isDone ? 1 : 0,
    'created_at': createdAt.millisecondsSinceEpoch,
  };
}

Reminder reminderFromRow(Map<String, Object?> row) {
  final weekdaysRaw = row['repeat_weekdays'] as String?;
  return Reminder(
    id: row['id']! as String,
    title: row['title']! as String,
    note: row['note'] as String?,
    scheduledAt: DateTime.fromMillisecondsSinceEpoch(
      row['scheduled_at']! as int,
    ),
    repeat: RepeatRule(
      RepeatType.values.byName(row['repeat_type']! as String),
      weekdays: (weekdaysRaw == null || weekdaysRaw.isEmpty)
          ? const {}
          : weekdaysRaw.split(',').map(int.parse).toSet(),
    ),
    tag: row['tag'] as String?,
    isDone: (row['is_done']! as int) == 1,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int),
  );
}
