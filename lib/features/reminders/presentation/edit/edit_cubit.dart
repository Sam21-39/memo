import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/alarm/alarm_scheduler.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/repeat_rule.dart';
import '../../domain/usecases/create_reminder.dart';
import '../../domain/usecases/save_reminder.dart';
import '../home/home_cubit.dart' show scheduleFailedMessage;

enum EditStatus { editing, saving, saved }

class EditState {
  const EditState({
    required this.title,
    required this.note,
    required this.dueAt,
    required this.repeat,
    this.tag,
    this.preAlarmMin,
    this.nagMin,
    this.existing,
    this.status = EditStatus.editing,
    this.error,
  });

  final String title;
  final String note;
  final DateTime dueAt;
  final RepeatRule repeat;
  final String? tag;
  final int? preAlarmMin;
  final int? nagMin;

  /// Null for a new reminder.
  final Reminder? existing;
  final EditStatus status;
  final String? error;

  bool get canSave => title.trim().isNotEmpty && status == EditStatus.editing;

  /// A repeat rolls forward, so only a one-off can sit in the past — and it
  /// would never ring.
  bool isPastOneOff(DateTime now) => !repeat.repeats && dueAt.isBefore(now);

  EditState copyWith({
    String? title,
    String? note,
    DateTime? dueAt,
    RepeatRule? repeat,
    String? tag,
    bool clearTag = false,
    int? preAlarmMin,
    bool clearPreAlarm = false,
    int? nagMin,
    bool clearNag = false,
    EditStatus? status,
    String? error,
    bool clearError = false,
  }) => EditState(
    title: title ?? this.title,
    note: note ?? this.note,
    dueAt: dueAt ?? this.dueAt,
    repeat: repeat ?? this.repeat,
    tag: clearTag ? null : (tag ?? this.tag),
    preAlarmMin: clearPreAlarm ? null : (preAlarmMin ?? this.preAlarmMin),
    nagMin: clearNag ? null : (nagMin ?? this.nagMin),
    existing: existing,
    status: status ?? this.status,
    error: clearError ? null : (error ?? this.error),
  );
}

class EditCubit extends Cubit<EditState> {
  EditCubit(this._save, {Reminder? existing, int? defaultNagMin, DateTime? now})
    : super(
        existing == null
            ? EditState(
                title: '',
                note: '',
                dueAt: _nextHour(now ?? DateTime.now()),
                repeat: RepeatRule.none,
                nagMin: defaultNagMin,
              )
            : EditState(
                title: existing.title,
                note: existing.note ?? '',
                dueAt: existing.dueAt,
                repeat: existing.repeat,
                tag: existing.tag,
                preAlarmMin: existing.preAlarmMin,
                nagMin: existing.nagMin,
                existing: existing,
              ),
      );

  final SaveReminder _save;

  /// Next whole hour, so the common case needs no time edit at all.
  static DateTime _nextHour(DateTime now) =>
      DateTime(now.year, now.month, now.day, now.hour + 1);

  void setTitle(String value) => emit(state.copyWith(title: value));
  void setNote(String value) => emit(state.copyWith(note: value));
  void setTag(String? tag) => emit(
    tag == null ? state.copyWith(clearTag: true) : state.copyWith(tag: tag),
  );
  void setRepeat(RepeatRule repeat) => emit(state.copyWith(repeat: repeat));
  void setNag(int? minutes) => emit(
    minutes == null
        ? state.copyWith(clearNag: true)
        : state.copyWith(nagMin: minutes),
  );
  void setPreAlarm(int? minutes) => emit(
    minutes == null
        ? state.copyWith(clearPreAlarm: true)
        : state.copyWith(preAlarmMin: minutes),
  );

  /// Plain "Weekly" means this weekday every week, so it follows the date. A
  /// multi-day custom rule was picked deliberately — leave it.
  void setDueAt(DateTime value) {
    var repeat = state.repeat;
    if (repeat.type == RepeatType.weekly && repeat.weekdays.length == 1) {
      repeat = RepeatRule(RepeatType.weekly, weekdays: {value.weekday});
    }
    emit(state.copyWith(dueAt: value, repeat: repeat));
  }

  Future<void> save() async {
    if (!state.canSave) return;
    emit(state.copyWith(status: EditStatus.saving, clearError: true));
    final note = state.note.trim();
    final existing = state.existing;
    final reminder =
        existing?.copyWith(
          title: state.title.trim(),
          note: note.isEmpty ? null : note,
          clearNote: note.isEmpty,
          dueAt: state.dueAt,
          repeat: state.repeat,
          tag: state.tag,
          clearTag: state.tag == null,
          preAlarmMin: state.preAlarmMin,
          clearPreAlarm: state.preAlarmMin == null,
          nagMin: state.nagMin,
          clearNag: state.nagMin == null,
          // A new time is a new occurrence.
          clearDone: true,
          nagCount: 0,
        ) ??
        const CreateReminder()(
          title: state.title,
          dueAt: state.dueAt,
          now: DateTime.now(),
          note: note,
          repeat: state.repeat,
          tag: state.tag,
          nagMin: state.nagMin,
        ).copyWith(preAlarmMin: state.preAlarmMin);
    try {
      await _save(reminder);
      emit(state.copyWith(status: EditStatus.saved));
    } on ScheduleFailure {
      // The row is saved and flagged for retry; say so, then close.
      emit(
        state.copyWith(status: EditStatus.saved, error: scheduleFailedMessage),
      );
    }
  }
}
