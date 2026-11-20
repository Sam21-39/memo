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
import '../../../../l10n/l10n.dart';

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
  Timer? _deleteTimer;
  String? _inFlight;

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
        emit(current.copyWith(error: l10n().scheduleFailed));
      }
    } catch (_) {
      final current = state;
      if (current is HomeReady) {
        emit(current.copyWith(error: l10n().saveFailed));
      }
    }
  }

  /// A one-off gets a 5 s Undo; a repeat moves forward with no toast, since
  /// restoring its old time would only roll forward again.
  Future<void> complete(Reminder reminder) async {
    await commitPendingDelete();
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

  /// Hides the row now; the delete runs when the Undo window ends.
  Future<void> delete(Reminder reminder) async {
    await commitPendingDelete();
    dismissUndo();
    final current = state;
    if (current is! HomeReady) return;
    emit(current.copyWith(pendingDelete: reminder));
    _deleteTimer = Timer(undoWindow, commitPendingDelete);
  }

  void undoDelete() {
    final current = state;
    // Already deleting: undo would flash the row back, then drop it.
    if (current is HomeReady && current.pendingDelete?.id == _inFlight) return;
    _deleteTimer?.cancel();
    if (current is HomeReady) emit(current.copyWith(clearPendingDelete: true));
  }

  /// Also run when the app goes to the background, so a kill cannot lose it.
  Future<void> commitPendingDelete() async {
    final current = state;
    if (current is! HomeReady || current.pendingDelete == null) return;
    final id = current.pendingDelete!.id;
    // A commit still awaiting its delete: a second one would delete it twice.
    if (_inFlight == id) return;
    _inFlight = id;
    _deleteTimer?.cancel();
    try {
      await _delete(id);
    } catch (_) {
      final now = state;
      if (!isClosed && now is HomeReady) {
        emit(now.copyWith(error: l10n().deleteFailed));
      }
    } finally {
      _inFlight = null;
    }
    // A newer swipe may have replaced the pending row while this awaited.
    final now = state;
    if (!isClosed && now is HomeReady && now.pendingDelete?.id == id) {
      emit(now.copyWith(clearPendingDelete: true));
    }
  }

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
  Future<void> close() async {
    _undoTimer?.cancel();
    _deleteTimer?.cancel();
    _changes.cancel();
    final current = state;
    if (current is HomeReady &&
        current.pendingDelete != null &&
        current.pendingDelete!.id != _inFlight) {
      try {
        await _delete(current.pendingDelete!.id);
      } catch (_) {
        // Still on disk; the next launch shows it again.
      }
    }
    return super.close();
  }
}
