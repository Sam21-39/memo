import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/reminder.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../../domain/usecases/save_reminder.dart';

class ArchiveState {
  const ArchiveState({this.done = const [], this.query = ''});

  /// Completed one-offs, most recently completed first.
  final List<Reminder> done;
  final String query;

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

  Future<void> reopen(Reminder reminder) =>
      _save(reminder.copyWith(clearDone: true));

  @override
  Future<void> close() {
    _changes.cancel();
    return super.close();
  }
}
