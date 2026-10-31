import '../entities/reminder.dart';
import '../entities/repeat_rule.dart';
import 'alarm_ids.dart';

/// How the OS should re-arm a fire after it rings.
enum FireRepeat { none, daily, weekly }

/// One alarm the OS will deliver. Native code only ever sees these.
class AlarmFire {
  const AlarmFire({
    required this.id,
    required this.at,
    required this.reminderId,
    required this.repeat,
    this.kind = FireKind.main,
  });

  final int id;

  /// Local wall time of the next delivery.
  final DateTime at;
  final String reminderId;
  final FireRepeat repeat;
  final FireKind kind;

  @override
  String toString() => 'AlarmFire($kind $id @ $at, $repeat)';
}

enum FireKind { main, burst }

/// Every fire a reminder needs, soonest first. Pure, so the 64-slot budget
/// and both platform schedulers agree on the same list.
///
/// [burst]: iOS only. With nag off, a second fire one minute later gives a
/// missed banner one retry. M3 adds pre-alarm and nag fires here.
List<AlarmFire> firesFor(
  Reminder reminder, {
  required DateTime now,
  bool burst = false,
}) {
  if (reminder.isDone) return const [];
  final id = reminder.id;
  final fires = <AlarmFire>[];

  void add(int fireId, DateTime at, FireRepeat repeat) {
    fires.add(AlarmFire(id: fireId, at: at, reminderId: id, repeat: repeat));
    if (burst && reminder.nagMin == null) {
      fires.add(
        AlarmFire(
          id: repeat == FireRepeat.weekly
              ? AlarmIds.burstWeekday(id, at.weekday)
              : AlarmIds.nag(id, 1),
          at: at.add(const Duration(minutes: 1)),
          reminderId: id,
          repeat: repeat,
          kind: FireKind.burst,
        ),
      );
    }
  }

  switch (reminder.repeat.type) {
    case RepeatType.none:
      // A one-off already in the past has nothing left to ring.
      if (reminder.dueAt.isAfter(now)) {
        add(AlarmIds.main(id), reminder.dueAt, FireRepeat.none);
      }
    case RepeatType.daily:
      add(AlarmIds.main(id), nextDaily(reminder.dueAt, now), FireRepeat.daily);
    case RepeatType.weekly:
      // One fire per picked weekday: the OS matches one weekday per alarm.
      final days = reminder.repeat.weekdays.isEmpty
          ? {reminder.dueAt.weekday}
          : reminder.repeat.weekdays;
      for (final day in days) {
        add(
          AlarmIds.weekday(id, day),
          nextWeekday(reminder.dueAt, day, now),
          FireRepeat.weekly,
        );
      }
  }
  fires.sort((a, b) => a.at.compareTo(b.at));
  return fires;
}

/// Same wall time, today if still ahead, else tomorrow — never before the
/// reminder's own start, so a repeat set to begin next week does not ring
/// tonight. Calendar arithmetic, so DST keeps 07:00 at 07:00.
DateTime nextDaily(DateTime dueAt, DateTime now) {
  if (dueAt.isAfter(now)) return dueAt;
  var next = DateTime(now.year, now.month, now.day, dueAt.hour, dueAt.minute);
  if (!next.isAfter(now)) {
    next = DateTime(now.year, now.month, now.day + 1, dueAt.hour, dueAt.minute);
  }
  return next;
}

DateTime nextWeekday(DateTime dueAt, int weekday, DateTime now) {
  var next = nextDaily(dueAt, now);
  while (next.weekday != weekday) {
    next = DateTime(
      next.year,
      next.month,
      next.day + 1,
      next.hour,
      next.minute,
    );
  }
  return next;
}
