import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/media_store.dart';
import '../../data/speech_to_text.dart';
import '../../data/voice_clip.dart';
import '../../domain/alarm/alarm_scheduler.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/repeat_rule.dart';
import '../../domain/parser/reminder_parser.dart';
import '../../domain/usecases/create_reminder.dart';
import '../../domain/usecases/save_reminder.dart';
import '../voice/hold_recorder.dart';
import '../../../../l10n/strings.dart';

enum CapturePhase { idle, typing, recording, transcribing, saving }

class CaptureState {
  const CaptureState({
    this.phase = CapturePhase.idle,
    this.text = '',
    this.parsed,
    this.dueOverride,
    this.repeatOverride,
    this.tagOverride,
    this.tagCleared = false,
    this.hasClip = false,
    this.readAloud = true,
    this.recorded = Duration.zero,
    this.notice,
    this.error,
  });

  final CapturePhase phase;
  final String text;

  /// Null while the field is empty.
  final ParsedReminder? parsed;

  /// A chip the user corrected wins over the parse.
  final DateTime? dueOverride;
  final RepeatRule? repeatOverride;
  final String? tagOverride;
  final bool tagCleared;

  /// A voice clip sits in the draft file.
  final bool hasClip;
  final bool readAloud;
  final Duration recorded;
  final String? notice;
  final String? error;

  DateTime? get dueAt => dueOverride ?? parsed?.dueAt;

  /// The time chip draws dashed: nothing in the text said when.
  bool get timeGuessed => dueOverride == null && (parsed?.timeGuessed ?? true);
  RepeatRule get repeat => repeatOverride ?? parsed?.repeat ?? RepeatRule.none;
  String? get tag => tagCleared ? null : (tagOverride ?? parsed?.tag);
  String get title => parsed?.title ?? '';

  /// The bar shows chips and Save, over a dimmed list.
  bool get expanded => phase != CapturePhase.idle;

  bool get canSave =>
      phase == CapturePhase.typing && (title.isNotEmpty || hasClip);

  CaptureState copyWith({
    CapturePhase? phase,
    String? text,
    ParsedReminder? parsed,
    bool clearParsed = false,
    DateTime? dueOverride,
    RepeatRule? repeatOverride,
    String? tagOverride,
    bool? tagCleared,
    bool? hasClip,
    bool? readAloud,
    Duration? recorded,
    String? notice,
    bool clearNotice = false,
    String? error,
    bool clearError = false,
  }) => CaptureState(
    phase: phase ?? this.phase,
    text: text ?? this.text,
    parsed: clearParsed ? null : (parsed ?? this.parsed),
    dueOverride: dueOverride ?? this.dueOverride,
    repeatOverride: repeatOverride ?? this.repeatOverride,
    tagOverride: tagOverride ?? this.tagOverride,
    tagCleared: tagCleared ?? this.tagCleared,
    hasClip: hasClip ?? this.hasClip,
    readAloud: readAloud ?? this.readAloud,
    recorded: recorded ?? this.recorded,
    notice: clearNotice ? null : (notice ?? this.notice),
    error: clearError ? null : (error ?? this.error),
  );
}

int? _noNag() => null;
bool _yes() => true;

/// The capture bar: type, say or (M4) snap → one string → one parser → chips
/// the user confirms → Save writes and schedules in one use case.
class CaptureCubit extends Cubit<CaptureState> {
  CaptureCubit(
    this._save, {
    required this.media,
    required this.voice,
    required this.stt,
    required this.knownTags,
    this.defaultNagMin = _noNag,
    this.readAloudDefault = _yes,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(CaptureState(readAloud: readAloudDefault()));

  final SaveReminder _save;
  final MediaStore? media;
  final VoiceClip? voice;
  final SpeechToText? stt;

  /// Read on every parse, so a tag added a moment ago matches "for work".
  final List<String> Function() knownTags;
  // Getters, not values: Settings can change them while the bar lives.
  final int? Function() defaultNagMin;
  final bool Function() readAloudDefault;
  final DateTime Function() _clock;

  late final HoldRecorder? _hold = (voice == null || media == null)
      ? null
      : HoldRecorder(
          voice!,
          media!.draftVoicePath,
          onTick: (elapsed) {
            if (isClosed) return;
            emit(
              state.copyWith(
                phase: CapturePhase.recording,
                recorded: elapsed,
                clearNotice: true,
                clearError: true,
              ),
            );
          },
          onResult: _onHold,
        );

  /// The parse runs on every keystroke; it is sub-millisecond.
  void setText(String text) {
    if (text.trim().isEmpty && !state.hasClip) {
      emit(const CaptureState().copyWith(readAloud: state.readAloud));
      return;
    }
    emit(
      state.copyWith(
        phase: CapturePhase.typing,
        text: text,
        parsed: parseReminder(text, now: _clock(), knownTags: knownTags()),
        readAloud: state.phase == CapturePhase.idle ? readAloudDefault() : null,
        clearError: true,
        clearNotice: true,
      ),
    );
  }

  void setDueAt(DateTime at) => emit(state.copyWith(dueOverride: at));
  void setRepeat(RepeatRule repeat) =>
      emit(state.copyWith(repeatOverride: repeat));
  void setTag(String? tag) => emit(
    tag == null
        ? state.copyWith(tagCleared: true)
        : state.copyWith(tagOverride: tag, tagCleared: false),
  );
  void setReadAloud(bool value) => emit(state.copyWith(readAloud: value));

  Future<void> startRecording() async => _hold?.press();

  Future<void> stopRecording() async => _hold?.release();

  Future<void> _onHold(HoldResult result) async {
    if (isClosed) return;
    switch (result) {
      case HoldDropped(:final notice, :final denied):
        emit(
          state.copyWith(
            phase: state.text.trim().isEmpty && !state.hasClip
                ? CapturePhase.idle
                : CapturePhase.typing,
            notice: denied ? null : notice,
            error: denied ? notice : null,
          ),
        );
      case HoldKept(:final length):
        emit(
          state.copyWith(
            phase: CapturePhase.transcribing,
            hasClip: true,
            recorded: length,
          ),
        );
        final transcript = await stt?.transcribeFile(media!.draftVoicePath);
        if (isClosed || state.phase != CapturePhase.transcribing) return;
        // Typed words win; a transcript fills an empty field.
        final text = state.text.trim().isNotEmpty
            ? state.text
            : (transcript ?? '');
        emit(state.copyWith(phase: CapturePhase.typing));
        setText(text);
        if (text.trim().isEmpty) {
          emit(
            state.copyWith(
              phase: CapturePhase.typing,
              notice: S.captureVoiceSaved,
            ),
          );
        }
    }
  }

  /// Stop transcribing; the clip stays.
  void cancelTranscription() {
    if (state.phase == CapturePhase.transcribing) {
      emit(state.copyWith(phase: CapturePhase.typing));
    }
  }

  /// The draft can vanish while the edit sheet had it ("More"); drop the chip.
  void syncClip() {
    if (state.hasClip && !(media?.hasDraft ?? false)) {
      emit(state.copyWith(hasClip: false));
      if (state.text.trim().isEmpty) {
        emit(CaptureState(readAloud: state.readAloud));
      }
    }
  }

  Future<void> discard() async {
    await _hold?.release();
    if (state.hasClip) await media?.discardDraft();
    emit(CaptureState(readAloud: readAloudDefault()));
  }

  /// The reminder the chips describe, unsaved: for Save, and for "More".
  Reminder draft() {
    final title = state.title.isNotEmpty
        ? state.title
        : S.voiceNoteTitle(MediaStore.clipLength(media?.draftVoicePath ?? ''));
    final now = _clock();
    // Voice-only: the next whole hour at least 30 min away, as the parser guesses.
    final soon = now.add(const Duration(minutes: 30));
    return const CreateReminder()(
      title: title,
      dueAt:
          state.dueAt ??
          DateTime(soon.year, soon.month, soon.day, soon.hour + 1),
      now: now,
      repeat: state.repeat,
      tag: state.tag,
      nagMin: defaultNagMin(),
    );
  }

  Future<void> save() async {
    if (!state.canSave) return;
    final candidate = draft();
    if (state.dueAt != null &&
        !candidate.repeat.repeats &&
        candidate.dueAt.isBefore(_clock())) {
      emit(state.copyWith(error: S.timePassed));
      return;
    }
    emit(state.copyWith(phase: CapturePhase.saving));
    var reminder = candidate.copyWith(readAloud: state.readAloud);
    var committed = false;
    String? error;
    try {
      if (state.hasClip && media != null) {
        committed = await media!.commitVoice(reminder.id);
        reminder = reminder.copyWith(hasVoice: committed);
      }
      await _save(reminder);
    } on ScheduleFailure {
      error = S.scheduleFailed;
    } catch (_) {
      if (committed) await media!.uncommitVoice(reminder.id);
      if (!isClosed) {
        emit(state.copyWith(phase: CapturePhase.typing, error: S.saveFailed));
      }
      return;
    }
    if (isClosed) return;
    emit(CaptureState(readAloud: readAloudDefault(), error: error));
  }

  @override
  Future<void> close() async {
    await _hold?.dispose();
    if (state.hasClip) await media?.discardDraft();
    return super.close();
  }
}
