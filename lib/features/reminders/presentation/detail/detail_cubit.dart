import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/alarm/alarm_scheduler.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../../domain/usecases/complete_reminder.dart';
import '../../domain/usecases/delete_reminder.dart';
import '../../domain/usecases/save_reminder.dart';
import '../../domain/usecases/snooze_reminder.dart';
import '../home/home_cubit.dart' show scheduleFailedMessage;

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
  const DetailReady(this.reminder, {this.error});
  final Reminder reminder;
  final String? error;

  DetailReady copyWith({String? error}) => DetailReady(reminder, error: error);
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
    emit(reminder == null ? const DetailMissing() : DetailReady(reminder));
  }

  Future<void> _write(
    Reminder Function(Reminder r, DateTime now) change,
  ) async {
    final current = state;
    if (current is! DetailReady) return;
    try {
      await _save(change(current.reminder, DateTime.now()));
    } on ScheduleFailure {
      final now = state;
      if (now is DetailReady) emit(now.copyWith(error: scheduleFailedMessage));
    }
  }

  Future<void> complete() =>
      _write((r, now) => const CompleteReminder()(r, now: now));

  Future<void> reopen() => _write((r, _) => r.copyWith(clearDone: true));

  Future<void> snooze(Duration? by) =>
      _write((r, now) => const SnoozeReminder()(r, now: now, by: by));

  Future<void> delete() => _delete(id);

  @override
  Future<void> close() {
    _changes.cancel();
    return super.close();
  }
}
