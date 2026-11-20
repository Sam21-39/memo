import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/media_store.dart';
import '../../data/voice_clip.dart';
import '../../domain/alarm/alarm_scheduler.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/repeat_rule.dart';
import '../../domain/usecases/create_reminder.dart';
import '../../domain/usecases/save_reminder.dart';
import '../voice/hold_recorder.dart';
import '../../../../l10n/l10n.dart';

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
    this.notice,
    this.hasClip = false,
    this.draftClip = false,
    this.removeClip = false,
    this.readAloud = true,
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

  /// A neutral hint, e.g. "Hold the mic to record".
  final String? notice;

  /// A clip will exist after save: the reminder's own, or a new recording.
  final bool hasClip;

  /// A new recording sits in the draft file.
  final bool draftClip;

  /// The saved clip should be deleted on save.
  final bool removeClip;
  final bool readAloud;
  final bool recording;
  final Duration recorded;

  /// A clip alone is enough: it saves as "Voice note · 0:08" and still rings.
  bool get canSave =>
      (title.trim().isNotEmpty || hasClip) &&
      !recording &&
      status == EditStatus.editing &&
      !pastBlocked(DateTime.now());

  /// A repeat rolls forward, so only a one-off can sit in the past — and it
  /// would never ring. An unchanged old one-off may still be saved.
  bool isPastOneOff(DateTime now) => !repeat.repeats && dueAt.isBefore(now);

  bool pastBlocked(DateTime now) =>
      isPastOneOff(now) && (existing == null || dueAt != existing!.dueAt);

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
    String? notice,
    bool clearNotice = false,
    bool? hasClip,
    bool? draftClip,
    bool? removeClip,
    bool? readAloud,
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
    notice: clearNotice ? null : (notice ?? this.notice),
    hasClip: hasClip ?? this.hasClip,
    draftClip: draftClip ?? this.draftClip,
    removeClip: removeClip ?? this.removeClip,
    readAloud: readAloud ?? this.readAloud,
    recording: recording ?? this.recording,
    recorded: recorded ?? this.recorded,
  );
}

class EditCubit extends Cubit<EditState> {
  EditCubit(
    this._save, {
    Reminder? existing,
    Reminder? draft,
    bool draftClip = false,
    int? defaultNagMin,
    bool readAloudDefault = true,
    DateTime? now,
    this.media,
    this.voice,
  }) : _inheritedDraft = draftClip,
       super(
         existing == null
             ? EditState(
                 title: draft?.title ?? '',
                 note: draft?.note ?? '',
                 dueAt: draft?.dueAt ?? _nextHour(now ?? DateTime.now()),
                 repeat: draft?.repeat ?? RepeatRule.none,
                 tag: draft?.tag,
                 nagMin: draft == null ? defaultNagMin : draft.nagMin,
                 readAloud: draft?.readAloud ?? readAloudDefault,
                 hasClip: draftClip,
                 draftClip: draftClip,
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
                 readAloud: existing.hasVoice
                     ? existing.readAloud
                     : readAloudDefault,
               ),
       );

  final SaveReminder _save;

  /// Null hides the voice section (tests, or no recorder on the platform).
  final MediaStore? media;
  final VoiceClip? voice;
  bool _saved = false;

  /// The clip came from the capture bar; its draft is that bar's to clean up.
  final bool _inheritedDraft;

  /// Where the clip shown in the sheet lives right now.
  String? get clipPath {
    final m = media;
    if (m == null || !state.hasClip) return null;
    if (state.draftClip) return m.draftVoicePath;
    return m.voicePath(state.existing!.id);
  }

  late final HoldRecorder? _hold = (voice == null || media == null)
      ? null
      : HoldRecorder(
          voice!,
          media!.draftVoicePath,
          onTick: (elapsed) {
            if (!isClosed) {
              emit(
                state.copyWith(
                  recording: true,
                  recorded: elapsed,
                  clearError: true,
                  clearNotice: true,
                ),
              );
            }
          },
          onResult: (result) {
            if (isClosed) return;
            emit(switch (result) {
              HoldKept(:final length) => state.copyWith(
                recording: false,
                hasClip: true,
                draftClip: true,
                removeClip: false,
                recorded: length,
              ),
              HoldDropped(:final notice, :final denied) =>
                denied
                    ? state.copyWith(recording: false, error: notice)
                    : state.copyWith(recording: false, notice: notice),
            });
          },
        );

  Future<void> startRecording() async => _hold?.press();

  Future<void> stopRecording() async => _hold?.release();

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

  void setReadAloud(bool value) => emit(state.copyWith(readAloud: value));

  @override
  Future<void> close() async {
    await _hold?.dispose();
    if (!_saved && !_inheritedDraft) await media?.discardDraft();
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
        : l10n().voiceNoteTitle(MediaStore.clipLength(clipPath ?? ''));
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
          clearSnooze: true,
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
    var committed = false;
    try {
      // Media first, so the scheduler sees the clip it should ring.
      final m = media;
      if (m != null && state.draftClip) {
        committed = await m.commitVoice(reminder.id);
        reminder = reminder.copyWith(hasVoice: committed);
      } else if (m != null && state.removeClip) {
        // The file goes only after the row is saved.
        reminder = reminder.copyWith(hasVoice: false);
      }
      reminder = reminder.copyWith(readAloud: state.readAloud);
      _saved = true;
      await _save(reminder);
      await media?.dropBackup(reminder.id);
      if (state.removeClip && !state.draftClip) {
        await media?.deleteVoice(reminder.id);
      }
      emit(state.copyWith(status: EditStatus.saved));
    } on ScheduleFailure {
      // The row is saved and flagged for retry; say so, then close.
      await media?.dropBackup(reminder.id);
      if (state.removeClip && !state.draftClip) {
        await media?.deleteVoice(reminder.id);
      }
      emit(
        state.copyWith(status: EditStatus.saved, error: l10n().scheduleFailed),
      );
    } catch (_) {
      if (committed) await media!.uncommitVoice(reminder.id);
      _saved = false;
      if (!isClosed) {
        emit(
          state.copyWith(status: EditStatus.editing, error: l10n().saveFailed),
        );
      }
    }
  }
}
