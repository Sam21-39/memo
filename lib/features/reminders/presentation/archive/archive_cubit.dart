import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/alarm/alarm_scheduler.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../../domain/usecases/reopen_reminder.dart';
import '../../domain/usecases/save_reminder.dart';
import '../../../../l10n/l10n.dart';

class ArchiveState {
  const ArchiveState({this.done = const [], this.query = '', this.error});

  /// Completed one-offs, most recently completed first.
  final List<Reminder> done;
  final String query;
  final String? error;

  /// ponytail: in-memory match over title and note. A personal archive is
  /// hundreds of rows; add an index when someone's is not.
  List<Reminder> get visible {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return done;
    return [
      for (final r in done)
        if (r.title.toLowerCase().contains(q) ||
            (r.note?.toLowerCase().contains(q) ?? false))
          r,
    ];
  }

  int completedSince(DateTime since) =>
      done.where((r) => !r.doneAt!.isBefore(since)).length;
}

class ArchiveCubit extends Cubit<ArchiveState> {
  ArchiveCubit(this._repository, this._save) : super(const ArchiveState()) {
    _changes = _repository.changes.listen((_) => load());
  }

  final ReminderRepository _repository;
  final SaveReminder _save;
  late final StreamSubscription<void> _changes;

  Future<void> load() async {
    final done = (await _repository.getAll()).where((r) => r.isDone).toList()
      ..sort((a, b) => b.doneAt!.compareTo(a.doneAt!));
    if (!isClosed) emit(ArchiveState(done: done, query: state.query));
  }

  void search(String query) =>
      emit(ArchiveState(done: state.done, query: query));

  Future<void> reopen(Reminder reminder) async {
    try {
      await _save(const ReopenReminder()(reminder, now: DateTime.now()));
    } on ScheduleFailure {
      _fail(l10n().scheduleFailed);
    } catch (_) {
      _fail(l10n().saveFailed);
    }
  }

  void _fail(String message) {
    if (!isClosed) {
      emit(ArchiveState(done: state.done, query: state.query, error: message));
    }
  }

  void clearError() => emit(ArchiveState(done: state.done, query: state.query));

  @override
  Future<void> close() {
    _changes.cancel();
    return super.close();
  }
}
