import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/notification_scheduler.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../../domain/usecases/complete_reminder.dart';
import '../../domain/usecases/snooze_reminder.dart';
import 'reminders_state.dart';

class RemindersCubit extends Cubit<RemindersState> {
  RemindersCubit(
    this._repository,
    this._scheduler, {
    required this.snoozeEnabled,
  }) : super(const RemindersState());

  final ReminderRepository _repository;
  final NotificationScheduler _scheduler;

  /// Mirrors `FeatureFlags.snooze` — drives the notification's Snooze action.
  final bool snoozeEnabled;

  static const _snooze = SnoozeReminder();
  static const _complete = CompleteReminder();

  /// Persist and (re)schedule together — a saved reminder that never rings is
  /// the one failure this app cannot have.
  Future<void> _persist(Reminder reminder) async {
    await _repository.save(reminder);
    await _scheduler.schedule(reminder, snoozeEnabled: snoozeEnabled);
  }

  Future<void> load() async {
    try {
      final reminders = await _repository.getAll();
      emit(state.copyWith(status: RemindersStatus.ready, reminders: reminders));
    } catch (_) {
      emit(state.copyWith(status: RemindersStatus.failure));
    }
  }

  /// Insert or update — the compose page builds the entity (via
  /// [CreateReminder] for a new one) and hands it back.
  Future<void> save(Reminder reminder) async {
    await _persist(reminder);
    await load();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    await _scheduler.cancel(id);
    await load();
  }

  Future<void> complete(Reminder reminder) async {
    await _persist(_complete(reminder, now: DateTime.now()));
    await load();
  }

  /// Reopen a completed one-off — backs the Undo action on the list.
  Future<void> uncomplete(Reminder reminder) async {
    await _persist(reminder.copyWith(isDone: false));
    await load();
  }

  Future<void> snooze(Reminder reminder, {Duration? by}) async {
    await _persist(_snooze(reminder, now: DateTime.now(), by: by));
    await load();
  }

  /// Applies a notification action, then returns the reminder it belongs to.
  Future<Reminder?> applyNotificationAction(
    String reminderId,
    NotificationAction action,
  ) async {
    final reminder = await _repository.getById(reminderId);
    if (reminder == null) return null;
    switch (action) {
      case NotificationAction.open:
        break;
      case NotificationAction.done:
        await complete(reminder);
      case NotificationAction.snooze:
        await snooze(reminder, by: const Duration(minutes: 10));
    }
    return reminder;
  }

  void filterByTag(String? tag) {
    emit(
      tag == null
          ? state.copyWith(clearTagFilter: true)
          : state.copyWith(tagFilter: tag),
    );
  }
}
