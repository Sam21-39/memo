import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/reminder.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../../domain/usecases/complete_reminder.dart';
import '../../domain/usecases/save_reminder.dart';
import '../../domain/usecases/snooze_reminder.dart';

enum AlarmOutcome { ringing, snoozed, done, missing }

class AlarmState {
  const AlarmState({
    this.reminder,
    this.outcome = AlarmOutcome.ringing,
    this.playing = false,
  });

  final Reminder? reminder;
  final AlarmOutcome outcome;

  /// The voice clip is playing in-app.
  final bool playing;

  AlarmState copyWith({
    Reminder? reminder,
    AlarmOutcome? outcome,
    bool? playing,
  }) => AlarmState(
    reminder: reminder ?? this.reminder,
    outcome: outcome ?? this.outcome,
    playing: playing ?? this.playing,
  );
}

/// The ringing screen. Platform work comes in as functions so the Cubit is
/// testable: [ringingNatively] (a native alarm is already sounding),
/// [stopRinging], [speak] (the app's voice), [play] / [stop] for the note.
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
  }) : super(const AlarmState());

  final String id;
  final ReminderRepository _repository;
  final SaveReminder _save;
  final Future<bool> Function(String id) ringingNatively;
  final Future<void> Function() stopRinging;
  final Future<void> Function(String id) play;
  final Future<void> Function() stop;
  final Future<void> Function(Reminder reminder) speak;

  /// Loads the reminder and reads it aloud once — unless a native alarm is
  /// already sounding, which would talk over it. The note plays on tap.
  Future<void> load() async {
    final reminder = await _repository.getById(id);
    if (isClosed) return;
    if (reminder == null) {
      emit(const AlarmState(outcome: AlarmOutcome.missing));
      return;
    }
    emit(AlarmState(reminder: reminder));
    if (reminder.readAloud && !await ringingNatively(id)) await speak(reminder);
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

  Future<void> _finish(
    Reminder Function(Reminder r, DateTime now) change,
    AlarmOutcome outcome,
  ) async {
    final reminder = state.reminder;
    if (reminder == null) return;
    await stopRinging();
    await stop();
    await _save(change(reminder, DateTime.now()));
    emit(state.copyWith(outcome: outcome, playing: false));
  }

  Future<void> done() => _finish(
    (r, now) => const CompleteReminder()(r, now: now),
    AlarmOutcome.done,
  );

  Future<void> snooze(Duration? by) => _finish(
    (r, now) => const SnoozeReminder()(r, now: now, by: by),
    AlarmOutcome.snoozed,
  );
}
