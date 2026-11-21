import 'reminder.dart';
import 'repeat_rule.dart';
import '../test_reminder.dart';

enum OccurrenceEvent { done, snoozed, open }

/// One thing that happened to one cycle of a repeat.
class Occurrence {
  const Occurrence({
    required this.reminderId,
    required this.dueAt,
    required this.event,
    required this.at,
    this.until,
  });

  final String reminderId;

  /// The cycle this is about.
  final DateTime dueAt;
  final OccurrenceEvent event;

  /// When it happened (the tap time, not the time it was applied).
  final DateTime at;

  /// Snooze target; only for [OccurrenceEvent.snoozed].
  final DateTime? until;
}

const historyDays = 90;

/// [from], then each next cycle while it is before [before]; the latest [cap].
/// Empty when [rule] does not repeat.
List<DateTime> cyclesBetween(
  RepeatRule rule,
  DateTime from,
  DateTime before, {
  int cap = historyDays,
}) {
  if (!rule.repeats) return const [];
  final out = <DateTime>[];
  for (
    DateTime? d = from;
    d != null && d.isBefore(before);
    d = rule.nextAfter(d)
  ) {
    out.add(d);
  }
  return out.length > cap ? out.sublist(out.length - cap) : out;
}

bool _logged(Reminder r) => r.repeat.repeats && r.id != testReminderId;

Occurrence _row(Reminder r, DateTime due, OccurrenceEvent e, DateTime at) =>
    Occurrence(reminderId: r.id, dueAt: due, event: e, at: at);

List<Occurrence> doneLog(Reminder was, Reminder next, DateTime at) {
  if (!_logged(was)) return const [];
  final cycles = cyclesBetween(was.repeat, was.dueAt, next.dueAt);
  return [
    for (final (i, d) in cycles.indexed)
      _row(
        was,
        d,
        i == cycles.length - 1 ? OccurrenceEvent.done : OccurrenceEvent.open,
        at,
      ),
  ];
}

List<Occurrence> snoozeLog(Reminder was, Reminder next, DateTime at) {
  if (!_logged(was)) return const [];
  return [
    Occurrence(
      reminderId: was.id,
      dueAt: was.dueAt,
      event: OccurrenceEvent.snoozed,
      at: at,
      until: next.snoozedUntil,
    ),
  ];
}

List<Occurrence> openLog(Reminder was, DateTime newDue, DateTime at) {
  if (!_logged(was)) return const [];
  return [
    for (final d in cyclesBetween(was.repeat, was.dueAt, newDue))
      _row(was, d, OccurrenceEvent.open, at),
  ];
}

/// What Detail shows for one cycle.
class OccurrenceRow {
  const OccurrenceRow({required this.dueAt, this.doneAt, this.snoozedMinutes});

  final DateTime dueAt;
  final DateTime? doneAt;
  final int? snoozedMinutes;

  bool get done => doneAt != null;
}

/// Newest first. A cycle that was only snoozed is still in progress, so it is
/// not a row yet.
List<OccurrenceRow> historyRows(List<Occurrence> log) {
  final groups = <DateTime, List<Occurrence>>{};
  for (final o in log) {
    (groups[o.dueAt] ??= []).add(o);
  }
  final rows = <OccurrenceRow>[];
  for (final MapEntry(key: due, value: events) in groups.entries) {
    final dones = events.where((o) => o.event == OccurrenceEvent.done);
    final snoozes =
        events
            .where((o) => o.event == OccurrenceEvent.snoozed && o.until != null)
            .toList()
          ..sort((a, b) => a.at.compareTo(b.at));
    if (dones.isEmpty && !events.any((o) => o.event == OccurrenceEvent.open)) {
      continue;
    }
    final doneAt = dones.isEmpty
        ? null
        : dones.map((o) => o.at).reduce((a, b) => a.isBefore(b) ? a : b);
    rows.add(
      OccurrenceRow(
        dueAt: due,
        doneAt: doneAt,
        snoozedMinutes: doneAt == null || snoozes.isEmpty
            ? null
            : (snoozes.last.until!.difference(snoozes.first.at).inSeconds / 60)
                  .round(),
      ),
    );
  }
  return rows..sort((a, b) => b.dueAt.compareTo(a.dueAt));
}

/// Cycles due in the Monday-to-Monday local week containing [now].
/// ponytail: week starts Monday; use MaterialLocalizations.firstDayOfWeekIndex if a locale needs Sunday.
({int done, int total}) weekTally(List<OccurrenceRow> rows, DateTime now) {
  final start = DateTime(now.year, now.month, now.day - (now.weekday - 1));
  final end = DateTime(start.year, start.month, start.day + 7);
  final week = rows.where(
    (r) =>
        !r.dueAt.isBefore(start) &&
        r.dueAt.isBefore(end) &&
        !r.dueAt.isAfter(now),
  );
  return (done: week.where((r) => r.done).length, total: week.length);
}
