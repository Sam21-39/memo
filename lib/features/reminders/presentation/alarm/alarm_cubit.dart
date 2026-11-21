import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/reminder.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../../domain/usecases/save_reminder.dart';

enum AlarmOutcome { ringing, snoozed, done, missing }

class AlarmState {
  const AlarmState({
    this.reminder,
    this.outcome = AlarmOutcome.ringing,
    this.playing = false,
    this.speakingIn,
  });

  final Reminder? reminder;
  final AlarmOutcome outcome;

  /// The voice clip is playing in-app.
  final bool playing;

  /// Language code the reminder is read aloud in; null when it is not.
  final String? speakingIn;

  AlarmState copyWith({
    Reminder? reminder,
    AlarmOutcome? outcome,
    bool? playing,
    bool clearSpeaking = false,
  }) => AlarmState(
    reminder: reminder ?? this.reminder,
    outcome: outcome ?? this.outcome,
    playing: playing ?? this.playing,
    speakingIn: clearSpeaking ? null : speakingIn,
  );
}

/// The ringing screen. Platform work comes in as functions so the Cubit is
/// testable: [ringingNatively] (a native alarm is already sounding),
/// [stopRinging], [speechLanguage] (the speech plan: null = no voice can read
/// the title), [speak] (the app's voice; false = nothing was spoken),
/// [play] / [stop] for the note.
class AlarmCubit extends Cubit<AlarmState> {
  AlarmCubit(
    this.id,
    this._repository,
    this._save, {
    required this.ringingNatively,
    required this.stopRinging,
    required this.play,
    required this.stop,
    required this.speak,
    this.speechLanguage = _noPlan,
  }) : super(const AlarmState());

  final String id;
  final ReminderRepository _repository;
  final SaveReminder _save;
  final Future<bool> Function(String id) ringingNatively;
  final Future<void> Function() stopRinging;
  final Future<void> Function(String id) play;
  final Future<void> Function() stop;
  final Future<bool> Function(Reminder reminder) speak;
  final Future<String?> Function(Reminder reminder) speechLanguage;

  static Future<String?> _noPlan(Reminder _) async => null;

  /// Loads the reminder and reads it aloud once — unless a native alarm is
  /// already sounding, which would talk over it. With no voice for the title,
  /// the voice note plays instead (nothing native is sounding it then). The
  /// note otherwise plays on tap.
  Future<void> load() async {
    final reminder = await _repository.getById(id);
    if (isClosed) return;
    if (reminder == null) {
      emit(const AlarmState(outcome: AlarmOutcome.missing));
      return;
    }
    final language = reminder.readAloud ? await speechLanguage(reminder) : null;
    if (isClosed) return;
    // speakingIn is the planned language. While a native alarm rings, whether
    // its sound was really rendered is not checked.
    emit(AlarmState(reminder: reminder, speakingIn: language));
    if (!reminder.readAloud || await ringingNatively(id)) return;
    // The line shows only for a voice that really spoke.
    final spoke = language != null && await speak(reminder);
    if (isClosed) return;
    if (!spoke) {
      emit(state.copyWith(clearSpeaking: true));
      if (reminder.hasVoice) await togglePlay();
    }
  }

  Future<void> togglePlay() async {
    if (state.playing) {
      await stop();
      emit(state.copyWith(playing: false));
    } else {
      emit(state.copyWith(playing: true));
      await play(id);
      if (!isClosed) emit(state.copyWith(playing: false));
    }
  }

  bool _finishing = false;

  Future<void> _finish(
    Future<void> Function(Reminder r, DateTime now) write,
    AlarmOutcome outcome,
  ) async {
    final reminder = state.reminder;
    if (reminder == null ||
        _finishing ||
        state.outcome != AlarmOutcome.ringing) {
      return;
    }
    _finishing = true;
    try {
      await stopRinging();
      await stop();
      await write(reminder, DateTime.now());
      if (!isClosed) emit(state.copyWith(outcome: outcome, playing: false));
    } catch (_) {
      _finishing = false; // failed save: let the user retry
      rethrow;
    }
  }

  Future<void> done() => _finish(_save.done, AlarmOutcome.done);

  Future<void> snooze(DateTime until) => _finish(
    (r, now) => _save.snooze(r, now, until: until),
    AlarmOutcome.snoozed,
  );
}
