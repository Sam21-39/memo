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
import '../../../../l10n/l10n.dart';

enum CapturePhase {
  idle,
  typing,
  recording,
  transcribing,
  voiceFailed,
  confirming,
  saving,
}

/// Why a recording did not become text.
enum VoiceFailure { unavailable, empty, cancelled }

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
    this.spoken = false,
    this.latched = false,
    this.level = 0,
    this.failure,
    this.micDenied = false,
    this.saved,
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

  /// [text] came from speech, not the keyboard.
  final bool spoken;

  /// Recording goes on after the finger lifted (tap mode).
  final bool latched;

  /// Input level 0..1 while recording.
  final double level;
  final VoiceFailure? failure;
  final bool micDenied;

  /// The reminder just saved. Set for one emit only: [copyWith] drops it.
  final Reminder? saved;

  DateTime? get dueAt => dueOverride ?? parsed?.dueAt;

  /// The parser could not settle the time and the user has not picked one.
  TimeAmbiguity? get unsure => dueOverride == null ? parsed?.ambiguity : null;
  RepeatRule get repeat => repeatOverride ?? parsed?.repeat ?? RepeatRule.none;
  String? get tag => tagCleared ? null : (tagOverride ?? parsed?.tag);
  String get title => parsed?.title ?? '';

  /// The bar shows chips and Continue, over a dimmed list.
  bool get expanded => phase != CapturePhase.idle;

  bool get canContinue =>
      phase == CapturePhase.typing && (title.isNotEmpty || hasClip);

  /// Nothing is scheduled from a guess: an unsure time blocks Save.
  bool get canSave =>
      phase == CapturePhase.confirming &&
      unsure == null &&
      (title.isNotEmpty || hasClip);

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
    bool? spoken,
    bool? latched,
    double? level,
    VoiceFailure? failure,
    bool clearFailure = false,
    bool? micDenied,
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
    spoken: spoken ?? this.spoken,
    latched: latched ?? this.latched,
    level: level ?? this.level,
    failure: clearFailure ? null : (failure ?? this.failure),
    micDenied: micDenied ?? this.micDenied,
  );
}

int? _noNag() => null;
String _en() => 'en';
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
    this.inputLocale = _en,
    this.interfaceLanguage = _en,
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
  final String Function() inputLocale, interfaceLanguage;
  final DateTime Function() _clock;

  late final HoldRecorder? _hold = (voice == null || media == null)
      ? null
      : HoldRecorder(
          voice!,
          media!.draftVoicePath,
          tempPath: media!.draftTempPath,
          onTick: (elapsed, level) {
            if (isClosed || !_canRecord) return;
            emit(
              state.copyWith(
                phase: CapturePhase.recording,
                recorded: elapsed,
                level: level,
                latched: _hold?.latched ?? false,
                micDenied: false,
                clearNotice: true,
                clearError: true,
              ),
            );
          },
          onResult: _onHold,
        );

  /// The input language is the preferred rule pack; Latin Hindi/Bengali
  /// ("kal", "baje") is on only when the user speaks one of them.
  ParsedReminder _parse(String text) => parseReminder(
    text,
    now: _clock(),
    knownTags: knownTags(),
    language: inputLocale(),
    latinPacks: {
      'hi',
      'bn',
    }.intersection({inputLocale(), interfaceLanguage()}).isNotEmpty,
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
        parsed: _parse(text),
        readAloud: state.phase == CapturePhase.idle ? readAloudDefault() : null,
        spoken: false,
        clearError: true,
        clearNotice: true,
        clearFailure: true,
      ),
    );
  }

  void setDueAt(DateTime at) =>
      emit(state.copyWith(dueOverride: at, clearError: true));
  void setRepeat(RepeatRule repeat) =>
      emit(state.copyWith(repeatOverride: repeat));
  void setTag(String? tag) => emit(
    tag == null
        ? state.copyWith(tagCleared: true)
        : state.copyWith(tagOverride: tag, tagCleared: false),
  );
  void setReadAloud(bool value) => emit(state.copyWith(readAloud: value));

  /// Not while transcribing, confirming or saving: a take then would race
  /// the clip those steps hold.
  bool get _canRecord =>
      state.phase == CapturePhase.idle ||
      state.phase == CapturePhase.typing ||
      state.phase == CapturePhase.recording;

  Future<void> startRecording() async {
    if (_canRecord) await _hold?.press();
  }

  Future<void> stopRecording() async {
    await _hold?.release();
    // A quick release latches: show it now, not on the next tick.
    final latched = _hold?.latched ?? false;
    if (!isClosed &&
        state.phase == CapturePhase.recording &&
        state.latched != latched) {
      emit(state.copyWith(latched: latched));
    }
  }

  /// Screen readers and the Stop button.
  Future<void> toggleRecording() async {
    if (_canRecord) await _hold?.toggle();
  }

  Future<void> cancelRecording() async => _hold?.cancel();

  /// Back from Settings: a granted microphone clears the denied look.
  Future<void> recheckMic() async {
    if (!state.micDenied) return;
    var granted = false;
    try {
      granted = await voice?.hasPermission() ?? false;
    } catch (_) {
      // Still denied.
    }
    if (granted && !isClosed) {
      emit(state.copyWith(micDenied: false, clearError: true));
    }
  }

  /// Typing → confirmation.
  void review() {
    if (!state.canContinue) return;
    // A start still in flight must not land on the confirmation.
    _hold?.cancel();
    emit(state.copyWith(phase: CapturePhase.confirming));
  }

  void backToTyping() {
    if (state.phase == CapturePhase.confirming) {
      emit(state.copyWith(phase: CapturePhase.typing));
    }
  }

  void chooseTime(DateTime at) => setDueAt(at);

  Future<void> _onHold(HoldResult result) async {
    if (isClosed || !_canRecord) return;
    switch (result) {
      case HoldDropped(:final notice, :final denied):
        final hasClip = media?.hasDraft ?? false;
        emit(
          state.copyWith(
            phase: state.text.trim().isEmpty && !hasClip
                ? CapturePhase.idle
                : CapturePhase.typing,
            hasClip: hasClip,
            latched: false,
            level: 0,
            micDenied: denied ? true : null,
            notice: denied ? null : notice,
            error: denied ? notice : null,
            clearNotice: notice == null,
            clearError: notice == null,
          ),
        );
      case HoldKept(:final length):
        emit(
          state.copyWith(
            phase: CapturePhase.transcribing,
            hasClip: true,
            recorded: length,
            latched: false,
            level: 0,
          ),
        );
        String? transcript;
        try {
          transcript = (await stt?.transcribeFile(
            media!.draftVoicePath,
          ))?.trim();
        } catch (_) {
          // Same as "heard nothing": never stuck on transcribing.
        }
        if (isClosed || state.phase != CapturePhase.transcribing) return;
        if ((transcript == null || transcript.isEmpty) &&
            state.text.trim().isNotEmpty) {
          // Typed words win; the clip stays attached.
          emit(state.copyWith(phase: CapturePhase.typing));
        } else if (transcript == null || transcript.isEmpty) {
          bool up;
          try {
            up = await stt?.available() ?? false;
          } catch (_) {
            up = false;
          }
          if (isClosed || state.phase != CapturePhase.transcribing) return;
          emit(
            state.copyWith(
              phase: CapturePhase.voiceFailed,
              failure: up ? VoiceFailure.empty : VoiceFailure.unavailable,
            ),
          );
        } else if (state.text.trim().isEmpty) {
          setText(transcript);
          emit(state.copyWith(phase: CapturePhase.confirming, spoken: true));
        } else {
          // Typed words win, as before.
          emit(state.copyWith(phase: CapturePhase.typing));
        }
    }
  }

  /// Stop transcribing; the clip stays.
  void cancelTranscription() {
    if (state.phase == CapturePhase.transcribing) {
      emit(
        state.copyWith(
          phase: CapturePhase.voiceFailed,
          failure: VoiceFailure.cancelled,
        ),
      );
    }
  }

  /// Failure panel: keep the clip, go back to the field.
  void typeInstead() {
    if (state.phase == CapturePhase.voiceFailed) setText(state.text);
  }

  /// Failure panel: the clip is the reminder, so a time must be picked.
  void saveAsVoiceNote() {
    if (state.phase != CapturePhase.voiceFailed) return;
    emit(
      state.copyWith(
        phase: CapturePhase.confirming,
        parsed: _parse(state.text),
        spoken: false,
        clearFailure: true,
      ),
    );
  }

  Future<void> tryAgain() async {
    await discard();
    await toggleRecording();
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
    await _hold?.cancel();
    if (state.hasClip) await media?.discardDraft();
    emit(CaptureState(readAloud: readAloudDefault()));
  }

  /// The reminder the chips describe, unsaved: for Save, and for "More".
  Reminder draft() {
    final title = state.title.isNotEmpty
        ? state.title
        : l10n().voiceNoteTitle(
            MediaStore.clipLength(media?.draftVoicePath ?? ''),
          );
    return const CreateReminder()(
      title: title,
      // Never invented: canSave guarantees a parse, and an unsure time is
      // picked first.
      dueAt: state.dueAt!,
      now: _clock(),
      repeat: state.repeat,
      tag: state.tag,
      nagMin: defaultNagMin(),
    );
  }

  Future<void> save() async {
    if (!state.canSave) return;
    final candidate = draft();
    if (!candidate.repeat.repeats && candidate.dueAt.isBefore(_clock())) {
      emit(state.copyWith(error: l10n().timePassed));
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
      error = l10n().scheduleFailed;
    } catch (_) {
      if (committed) await media!.uncommitVoice(reminder.id);
      if (!isClosed) {
        emit(
          state.copyWith(
            phase: CapturePhase.confirming,
            error: l10n().saveFailed,
          ),
        );
      }
      return;
    }
    if (isClosed) return;
    emit(
      CaptureState(
        readAloud: readAloudDefault(),
        // A toast "Reminder set" only when the alarm was.
        saved: error == null ? reminder : null,
        error: error,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _hold?.dispose();
    if (state.hasClip) await media?.discardDraft();
    return super.close();
  }
}
