import 'repeat_rule.dart';

class Reminder {
  const Reminder({
    required this.id,
    required this.title,
    required this.scheduledAt,
    required this.createdAt,
    this.note,
    this.repeat = RepeatRule.none,
    this.tag,
    this.isDone = false,
  });

  final String id;
  final String title;
  final String? note;
  final DateTime scheduledAt;
  final RepeatRule repeat;

  /// Null when the tags feature is off or the reminder is untagged.
  final String? tag;
  final bool isDone;
  final DateTime createdAt;

  bool isOverdue(DateTime now) => !isDone && scheduledAt.isBefore(now);

  Reminder copyWith({
    String? title,
    String? note,
    bool clearNote = false,
    DateTime? scheduledAt,
    RepeatRule? repeat,
    String? tag,
    bool clearTag = false,
    bool? isDone,
  }) {
    return Reminder(
      id: id,
      title: title ?? this.title,
      note: clearNote ? null : (note ?? this.note),
      scheduledAt: scheduledAt ?? this.scheduledAt,
      repeat: repeat ?? this.repeat,
      tag: clearTag ? null : (tag ?? this.tag),
      isDone: isDone ?? this.isDone,
      createdAt: createdAt,
    );
  }
}
