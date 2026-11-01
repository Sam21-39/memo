import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/alarm/alarm_scheduler.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../../domain/usecases/complete_reminder.dart';
import '../../domain/usecases/delete_reminder.dart';
import '../../domain/usecases/save_reminder.dart';
import '../../domain/usecases/snooze_reminder.dart';
import 'home_state.dart';

const scheduleFailedMessage =
    'Saved, but the alarm could not be set. Memō retries when you next open it.';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._repository, this._save, this._delete)
    : super(const HomeLoading()) {
    _changes = _repository.changes.listen((_) => load());
  }

  final ReminderRepository _repository;
  final SaveReminder _save;
  final DeleteReminder _delete;
  late final StreamSubscription<void> _changes;
  Timer? _undoTimer;

  static const undoWindow = Duration(seconds: 5);

  Future<void> load() async {
    try {
      final reminders = await _repository.getAll();
      final current = state;
      emit(
        current is HomeReady
            ? current.copyWith(reminders: reminders)
            : HomeReady(reminders: reminders),
      );
    } catch (_) {
      emit(const HomeFailure());
    }
  }

  Future<void> _write(Future<void> Function() action) async {
    try {
      await action();
    } on ScheduleFailure {
      final current = state;
      if (current is HomeReady) {
        emit(current.copyWith(error: scheduleFailedMessage));
      }
    }
  }

  /// A one-off gets a 5 s Undo; a repeat moves forward with no toast, since
  /// restoring its old time would only roll forward again.
  Future<void> complete(Reminder reminder) async {
    await _write(
      () => _save(const CompleteReminder()(reminder, now: DateTime.now())),
    );
    if (reminder.repeat.repeats) return;
    final current = state;
    if (current is! HomeReady) return;
    _undoTimer?.cancel();
    emit(current.copyWith(undo: reminder));
    _undoTimer = Timer(undoWindow, dismissUndo);
  }

  Future<void> undo() async {
    final current = state;
    if (current is! HomeReady || current.undo == null) return;
    final original = current.undo!;
    dismissUndo();
    await _write(() => _save(original));
  }

  void dismissUndo() {
    _undoTimer?.cancel();
    final current = state;
    if (current is HomeReady && current.undo != null) {
      emit(current.copyWith(clearUndo: true));
    }
  }

  Future<void> snooze(Reminder reminder, {Duration? by}) => _write(
    () => _save(const SnoozeReminder()(reminder, now: DateTime.now(), by: by)),
  );

  Future<void> delete(String id) => _delete(id);

  void filterByTag(String? tag) {
    final current = state;
    if (current is! HomeReady) return;
    emit(
      tag == null
          ? current.copyWith(clearFilter: true)
          : current.copyWith(tagFilter: tag),
    );
  }

  void clearError() {
    final current = state;
    if (current is HomeReady) emit(current.copyWith(clearError: true));
  }

  @override
  Future<void> close() {
    _undoTimer?.cancel();
    _changes.cancel();
    return super.close();
  }
}
