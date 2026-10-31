import '../../domain/entities/reminder.dart';

sealed class HomeState {
  const HomeState();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

/// The read failed. Reminders are still on the device and alarms already
/// registered keep firing; the screen says so instead of showing "empty".
class HomeFailure extends HomeState {
  const HomeFailure();
}

class HomeReady extends HomeState {
  const HomeReady({
    required this.reminders,
    this.tagFilter,
    this.undo,
    this.error,
  });

  /// Every reminder, soonest first.
  final List<Reminder> reminders;

  /// Null = All.
  final String? tagFilter;

  /// A one-off just completed, as it was before — the Undo toast restores it.
  final Reminder? undo;

  /// Inline error, e.g. a schedule failure.
  final String? error;

  /// Live reminders under the current filter.
  List<Reminder> get upcoming => [
    for (final r in reminders)
      if (!r.isDone && (tagFilter == null || r.tag == tagFilter)) r,
  ];

  List<String> get tagsInUse =>
      ({for (final r in reminders) ?r.tag}.toList()..sort());

  HomeReady copyWith({
    List<Reminder>? reminders,
    String? tagFilter,
    bool clearFilter = false,
    Reminder? undo,
    bool clearUndo = false,
    String? error,
    bool clearError = false,
  }) => HomeReady(
    reminders: reminders ?? this.reminders,
    tagFilter: clearFilter ? null : (tagFilter ?? this.tagFilter),
    undo: clearUndo ? null : (undo ?? this.undo),
    error: clearError ? null : (error ?? this.error),
  );
}
