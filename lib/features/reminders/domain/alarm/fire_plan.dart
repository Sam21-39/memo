import '../entities/reminder.dart';
import '../entities/repeat_rule.dart';
import 'alarm_ids.dart';

/// How the OS should re-arm a fire after it rings.
enum FireRepeat { none, daily, weekly }

enum FireKind { main, pre, nag, burst, snooze }

/// One alarm the OS will deliver. Native code only ever sees these.
class AlarmFire {
  const AlarmFire({
    required this.id,
    required this.at,
    required this.reminderId,
    required this.repeat,
    this.kind = FireKind.main,
    int? group,
  }) : group = group ?? id;

  final int id;

  /// Local wall time of the next delivery.
  final DateTime at;
  final String reminderId;
  final FireRepeat repeat;
  final FireKind kind;

  /// The main fire this one belongs to: its pre-alarm and nags share it, so
  /// native code can quiet one occurrence's nags on Done or Snooze.
  final int group;

  @override
  String toString() => 'AlarmFire($kind $id @ $at, $repeat)';
}

/// Every fire a reminder needs, soonest first. Pure, so the iOS 64-slot
/// budget and both platform schedulers agree on one list.
///
/// Per occurrence: the main fire; a pre-alarm [Reminder.preAlarmMin] before;
/// up to [AlarmIds.maxNags] nags every [Reminder.nagMin] after; and on iOS,
/// with nag off, a [burst] one minute later so a missed banner gets a retry.
/// Repeats re-arm each of these on the same rule.
///
/// Each fire's next time is computed from its own base (due ± offset), so an
/// overdue repeat still nags for today while its main has moved on.
List<AlarmFire> firesFor(
  Reminder reminder, {
  required DateTime now,
  bool burst = false,
}) {
  if (reminder.isDone) return const [];
  final id = reminder.id;
  final nag = reminder.nagMin;
  final pre = reminder.preAlarmMin;
  final fires = <AlarmFire>[];

  // A snoozed repeat skips this occurrence's nags: the snooze nags instead.
  final snooze = reminder.snoozedUntil;
  final seriesFrom = snooze == null
      ? now
      : _latest(now, reminder.dueAt.add(_nagWindow(nag)));

  /// The next time after [seriesFrom] that base due+[offset] lands on.
  DateTime next(Duration offset, FireRepeat repeat, int? weekday) {
    final base = reminder.dueAt.add(offset);
    return switch (repeat) {
      FireRepeat.none => base,
      FireRepeat.daily => nextDaily(base, seriesFrom),
      FireRepeat.weekly => nextWeekday(
        base,
        _shiftWeekday(weekday!, base, reminder.dueAt),
        seriesFrom,
      ),
    };
  }

  void occurrence(int mainId, FireRepeat repeat, int? weekday) {
    void add(int fireId, Duration offset, FireKind kind) {
      final at = next(offset, repeat, weekday);
      if (repeat == FireRepeat.none && !at.isAfter(seriesFrom)) return;
      fires.add(
        AlarmFire(
          id: fireId,
          at: at,
          reminderId: id,
          repeat: repeat,
          kind: kind,
          group: mainId,
        ),
      );
    }

    add(mainId, Duration.zero, FireKind.main);
    if (pre != null && pre > 0) {
      add(
        weekday == null
            ? AlarmIds.preAlarm(id)
            : AlarmIds.preWeekday(id, weekday),
        Duration(minutes: -pre),
        FireKind.pre,
      );
    }
    if (nag != null && nag > 0) {
      for (var k = 1; k <= AlarmIds.maxNags; k++) {
        add(
          weekday == null
              ? AlarmIds.nag(id, k)
              : AlarmIds.nagWeekday(id, weekday, k),
          Duration(minutes: nag * k),
          FireKind.nag,
        );
      }
    } else if (burst) {
      add(
        weekday == null
            ? AlarmIds.nag(id, 1)
            : AlarmIds.burstWeekday(id, weekday),
        const Duration(minutes: 1),
        FireKind.burst,
      );
    }
  }

  switch (reminder.repeat.type) {
    case RepeatType.none:
      occurrence(AlarmIds.main(id), FireRepeat.none, null);
    case RepeatType.daily:
      occurrence(AlarmIds.main(id), FireRepeat.daily, null);
    case RepeatType.weekly:
      // One main per picked weekday: the OS matches one weekday per alarm.
      final days = reminder.repeat.weekdays.isEmpty
          ? {reminder.dueAt.weekday}
          : reminder.repeat.weekdays;
      for (final day in days) {
        occurrence(AlarmIds.weekday(id, day), FireRepeat.weekly, day);
      }
  }

  // A repeat's snooze: one-off fires at the snooze time, then its own nags.
  if (snooze != null) {
    void add(int fireId, DateTime at, FireKind kind) {
      if (!at.isAfter(now)) return;
      fires.add(
        AlarmFire(
          id: fireId,
          at: at,
          reminderId: id,
          repeat: FireRepeat.none,
          kind: kind,
          group: AlarmIds.snooze(id),
        ),
      );
    }

    add(AlarmIds.snooze(id), snooze, FireKind.snooze);
    if (nag != null && nag > 0) {
      for (var k = 1; k <= AlarmIds.maxNags; k++) {
        add(
          AlarmIds.snoozeNag(id, k),
          snooze.add(Duration(minutes: nag * k)),
          FireKind.nag,
        );
      }
    } else if (burst) {
      add(
        AlarmIds.snoozeNag(id, 0),
        snooze.add(const Duration(minutes: 1)),
        FireKind.burst,
      );
    }
  }

  fires.sort((a, b) => a.at.compareTo(b.at));
  return fires;
}

/// How long one occurrence keeps nagging.
Duration _nagWindow(int? nag) =>
    Duration(minutes: (nag ?? 0) * AlarmIds.maxNags + 1);

DateTime _latest(DateTime a, DateTime b) => a.isAfter(b) ? a : b;

/// A pre-alarm or nag can cross midnight, landing on the weekday before or
/// after its main fire's.
int _shiftWeekday(int weekday, DateTime shifted, DateTime due) {
  final days = DateTime(
    shifted.year,
    shifted.month,
    shifted.day,
  ).difference(DateTime(due.year, due.month, due.day)).inDays;
  return (weekday - 1 + days) % 7 + 1;
}

/// Same wall time, today if still ahead, else tomorrow — never before the
/// base's own start, so a repeat set to begin next week does not ring
/// tonight. Calendar arithmetic, so DST keeps 07:00 at 07:00.
DateTime nextDaily(DateTime base, DateTime now) {
  if (base.isAfter(now)) return base;
  var next = DateTime(now.year, now.month, now.day, base.hour, base.minute);
  if (!next.isAfter(now)) {
    next = DateTime(now.year, now.month, now.day + 1, base.hour, base.minute);
  }
  return next;
}

DateTime nextWeekday(DateTime base, int weekday, DateTime now) {
  var next = nextDaily(base, now);
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
