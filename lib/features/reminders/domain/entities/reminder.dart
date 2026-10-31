import 'repeat_rule.dart';

class Reminder {
  const Reminder({
    required this.id,
    required this.title,
    required this.dueAt,
    required this.createdAt,
    this.note,
    this.repeat = RepeatRule.none,
    this.tag,
    this.doneAt,
    this.preAlarmMin,
    this.nagMin,
    this.nagCount = 0,
    this.hasVoice = false,
    this.voiceRings = false,
    this.hasImage = false,
    this.needsSchedule = false,
  });

  final String id;
  final String title;
  final String? note;
  final DateTime dueAt;
  final RepeatRule repeat;

  /// Null when the tags feature is off or the reminder is untagged.
  final String? tag;

  /// Set when a one-off is completed. A repeat never gets one: completing it
  /// moves [dueAt] forward instead.
  final DateTime? doneAt;
  final DateTime createdAt;

  /// Minutes before [dueAt] for an early alert. Null = off.
  final int? preAlarmMin;

  /// Minutes between re-alerts until done. Null = off.
  final int? nagMin;

  /// Nags already delivered for the current occurrence.
  final int nagCount;

  /// A voice clip exists at `media/<id>.wav`.
  final bool hasVoice;

  /// The clip is the alarm sound.
  final bool voiceRings;

  /// A photo exists at `media/<id>.jpg`.
  final bool hasImage;

  /// The last schedule attempt failed; retried on next launch.
  final bool needsSchedule;

  bool get isDone => doneAt != null;

  bool isOverdue(DateTime now) => !isDone && dueAt.isBefore(now);

  Reminder copyWith({
    String? title,
    String? note,
    bool clearNote = false,
    DateTime? dueAt,
    RepeatRule? repeat,
    String? tag,
    bool clearTag = false,
    DateTime? doneAt,
    bool clearDone = false,
    int? preAlarmMin,
    bool clearPreAlarm = false,
    int? nagMin,
    bool clearNag = false,
    int? nagCount,
    bool? hasVoice,
    bool? voiceRings,
    bool? hasImage,
    bool? needsSchedule,
  }) {
    return Reminder(
      id: id,
      title: title ?? this.title,
      note: clearNote ? null : (note ?? this.note),
      dueAt: dueAt ?? this.dueAt,
      repeat: repeat ?? this.repeat,
      tag: clearTag ? null : (tag ?? this.tag),
      doneAt: clearDone ? null : (doneAt ?? this.doneAt),
      createdAt: createdAt,
      preAlarmMin: clearPreAlarm ? null : (preAlarmMin ?? this.preAlarmMin),
      nagMin: clearNag ? null : (nagMin ?? this.nagMin),
      nagCount: nagCount ?? this.nagCount,
      hasVoice: hasVoice ?? this.hasVoice,
      voiceRings: voiceRings ?? this.voiceRings,
      hasImage: hasImage ?? this.hasImage,
      needsSchedule: needsSchedule ?? this.needsSchedule,
    );
  }
}
