import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/media_store.dart';
import '../../data/voice_clip.dart';
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
    this.hasClip = false,
    this.draftClip = false,
    this.removeClip = false,
    this.voiceRings = true,
    this.recording = false,
    this.recorded = Duration.zero,
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

  /// A clip will exist after save: the reminder's own, or a new recording.
  final bool hasClip;

  /// A new recording sits in the draft file.
  final bool draftClip;

  /// The saved clip should be deleted on save.
  final bool removeClip;
  final bool voiceRings;
  final bool recording;
  final Duration recorded;

  /// A clip alone is enough: it saves as "Voice note · 0:08" and still rings.
  bool get canSave =>
      (title.trim().isNotEmpty || hasClip) &&
      !recording &&
      status == EditStatus.editing;

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
    bool? hasClip,
    bool? draftClip,
    bool? removeClip,
    bool? voiceRings,
    bool? recording,
    Duration? recorded,
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
    hasClip: hasClip ?? this.hasClip,
    draftClip: draftClip ?? this.draftClip,
    removeClip: removeClip ?? this.removeClip,
    voiceRings: voiceRings ?? this.voiceRings,
    recording: recording ?? this.recording,
    recorded: recorded ?? this.recorded,
  );
}

class EditCubit extends Cubit<EditState> {
  EditCubit(
    this._save, {
    Reminder? existing,
    int? defaultNagMin,
    bool voiceRingsDefault = true,
    DateTime? now,
    this.media,
    this.voice,
  }) : super(
         existing == null
             ? EditState(
                 title: '',
                 note: '',
                 dueAt: _nextHour(now ?? DateTime.now()),
                 repeat: RepeatRule.none,
                 nagMin: defaultNagMin,
                 voiceRings: voiceRingsDefault,
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
                 hasClip: existing.hasVoice,
                 voiceRings: existing.hasVoice
                     ? existing.voiceRings
                     : voiceRingsDefault,
               ),
       );

  final SaveReminder _save;

  /// Null hides the voice section (tests, or no recorder on the platform).
  final MediaStore? media;
  final VoiceClip? voice;
  Timer? _ticker;
  bool _saved = false;

  /// Where the clip shown in the sheet lives right now.
  String? get clipPath {
    final m = media;
    if (m == null || !state.hasClip) return null;
    if (state.draftClip) return m.draftVoicePath;
    return m.voicePath(state.existing!.id);
  }

  Future<void> startRecording() async {
    final v = voice, m = media;
    if (v == null || m == null || state.recording) return;
    if (!await v.start(m.draftVoicePath)) {
      emit(
        state.copyWith(
          error: 'Microphone not allowed. Turn it on in Settings to record.',
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        recording: true,
        recorded: Duration.zero,
        clearError: true,
      ),
    );
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      final elapsed = Duration(seconds: t.tick);
      emit(state.copyWith(recorded: elapsed));
      if (elapsed >= VoiceClip.maxLength) stopRecording();
    });
  }

  Future<void> stopRecording() async {
    if (!state.recording) return;
    _ticker?.cancel();
    await voice?.stop();
    emit(
      state.copyWith(
        recording: false,
        hasClip: true,
        draftClip: true,
        removeClip: false,
      ),
    );
  }

  Future<void> deleteClip() async {
    await media?.discardDraft();
    emit(
      state.copyWith(
        hasClip: false,
        draftClip: false,
        removeClip: state.existing?.hasVoice ?? false,
      ),
    );
  }

  void setVoiceRings(bool value) => emit(state.copyWith(voiceRings: value));

  @override
  Future<void> close() async {
    _ticker?.cancel();
    await voice?.stop();
    if (!_saved) await media?.discardDraft();
    return super.close();
  }

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
    final title = state.title.trim().isNotEmpty
        ? state.title
        : 'Voice note · ${MediaStore.clipLength(clipPath ?? '')}';
    var reminder =
        existing?.copyWith(
          title: title.trim(),
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
          title: title,
          dueAt: state.dueAt,
          now: DateTime.now(),
          note: note,
          repeat: state.repeat,
          tag: state.tag,
          nagMin: state.nagMin,
        ).copyWith(preAlarmMin: state.preAlarmMin);
    // Media first, so the scheduler sees the clip it should ring.
    final m = media;
    if (m != null && state.draftClip) {
      await m.commitVoice(reminder.id);
      reminder = reminder.copyWith(hasVoice: true);
    } else if (m != null && state.removeClip) {
      await m.deleteVoice(reminder.id);
      reminder = reminder.copyWith(hasVoice: false);
    }
    reminder = reminder.copyWith(
      voiceRings: reminder.hasVoice && state.voiceRings,
    );
    _saved = true;
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
