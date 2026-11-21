import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/alarm/alarm_scheduler.dart';
import '../../domain/entities/occurrence.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../../domain/usecases/delete_reminder.dart';
import '../../domain/usecases/reopen_reminder.dart';
import '../../domain/usecases/save_reminder.dart';
import '../../../../l10n/l10n.dart';

sealed class DetailState {
  const DetailState();
}

class DetailLoading extends DetailState {
  const DetailLoading();
}

/// Deleted from under us, or a stale notification payload.
class DetailMissing extends DetailState {
  const DetailMissing();
}

class DetailReady extends DetailState {
  const DetailReady(this.reminder, {this.error, this.history = const []});
  final Reminder reminder;
  final String? error;

  /// Repeats only; empty for a one-off.
  final List<Occurrence> history;

  DetailReady copyWith({String? error}) =>
      DetailReady(reminder, error: error, history: history);
}

class DetailCubit extends Cubit<DetailState> {
  DetailCubit(this.id, this._repository, this._save, this._delete)
    : super(const DetailLoading()) {
    _changes = _repository.changes.listen((_) => load());
  }

  final String id;
  final ReminderRepository _repository;
  final SaveReminder _save;
  final DeleteReminder _delete;
  late final StreamSubscription<void> _changes;

  Future<void> load() async {
    final reminder = await _repository.getById(id);
    if (isClosed) return;
    if (reminder == null) return emit(const DetailMissing());
    var history = const <Occurrence>[];
    if (reminder.repeat.repeats) {
      try {
        history = await _repository.occurrences(id);
      } catch (_) {} // history is extra; keep the reminder shown
    }
    if (isClosed) return;
    emit(DetailReady(reminder, history: history));
  }

  Future<void> _write(
    Future<void> Function(Reminder r, DateTime now) write,
  ) async {
    final current = state;
    if (current is! DetailReady) return;
    try {
      await write(current.reminder, DateTime.now());
    } on ScheduleFailure {
      final now = state;
      if (now is DetailReady) emit(now.copyWith(error: l10n().scheduleFailed));
    } catch (_) {
      final now = state;
      if (now is DetailReady) emit(now.copyWith(error: l10n().saveFailed));
    }
  }

  Future<void> complete() => _write(_save.done);

  Future<void> reopen() =>
      _write((r, now) => _save(const ReopenReminder()(r, now: now)));

  Future<void> snooze(DateTime until) =>
      _write((r, now) => _save.snooze(r, now, until: until));

  /// False when the row is still there, so the page stays open.
  Future<bool> delete() async {
    try {
      await _delete(id);
      return true;
    } catch (_) {
      final now = state;
      if (now is DetailReady) emit(now.copyWith(error: l10n().deleteFailed));
      return false;
    }
  }

  @override
  Future<void> close() {
    _changes.cancel();
    return super.close();
  }
}
