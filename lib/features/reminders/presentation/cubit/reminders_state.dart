import '../../domain/entities/reminder.dart';

enum RemindersStatus { loading, ready, failure }

class RemindersState {
  const RemindersState({
    this.status = RemindersStatus.loading,
    this.reminders = const [],
    this.tagFilter,
  });

  final RemindersStatus status;

  /// Every reminder, soonest first.
  final List<Reminder> reminders;

  /// Null means "All".
  final String? tagFilter;

  List<Reminder> get _visible => tagFilter == null
      ? reminders
      : reminders.where((r) => r.tag == tagFilter).toList();

  List<Reminder> get upcoming => _visible.where((r) => !r.isDone).toList();

  /// Filtered — used for the list screen's counts.
  List<Reminder> get done => _visible.where((r) => r.isDone).toList();

  /// Unfiltered — the Done archive is its own screen and must not inherit the
  /// list's tag filter.
  List<Reminder> get allDone => reminders.where((r) => r.isDone).toList();

  /// Every tag currently in use, for the filter bar.
  List<String> get tagsInUse {
    final tags = reminders
        .map((r) => r.tag)
        .whereType<String>()
        .toSet()
        .toList();
    tags.sort();
    return tags;
  }

  RemindersState copyWith({
    RemindersStatus? status,
    List<Reminder>? reminders,
    String? tagFilter,
    bool clearTagFilter = false,
  }) {
    return RemindersState(
      status: status ?? this.status,
      reminders: reminders ?? this.reminders,
      tagFilter: clearTagFilter ? null : (tagFilter ?? this.tagFilter),
    );
  }
}
