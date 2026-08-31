enum RepeatType { none, daily, weekly }

/// none | daily | weekly(weekdays). Mirrors the `repeat_type` /
/// `repeat_weekdays` columns. Weekdays follow [DateTime.weekday]: Mon = 1.
class RepeatRule {
  const RepeatRule(this.type, {this.weekdays = const {}});

  static const none = RepeatRule(RepeatType.none);
  static const daily = RepeatRule(RepeatType.daily);

  final RepeatType type;
  final Set<int> weekdays;

  bool get repeats => type != RepeatType.none;

  /// First occurrence strictly after [from], keeping [from]'s time of day.
  /// Null when the rule never repeats (or is weekly with no day picked).
  ///
  /// Uses calendar arithmetic, not `Duration`, so the wall-clock time survives
  /// a DST shift — 07:00 stays 07:00, it does not drift to 06:00.
  DateTime? nextAfter(DateTime from) {
    DateTime plusDays(int days) => DateTime(
      from.year,
      from.month,
      from.day + days,
      from.hour,
      from.minute,
      from.second,
    );

    switch (type) {
      case RepeatType.none:
        return null;
      case RepeatType.daily:
        return plusDays(1);
      case RepeatType.weekly:
        if (weekdays.isEmpty) return null;
        for (var i = 1; i <= 7; i++) {
          final candidate = plusDays(i);
          if (weekdays.contains(candidate.weekday)) return candidate;
        }
        return null;
    }
  }

  /// First occurrence strictly after [from] that is also not before [now].
  /// A reminder left untouched for several cycles can be far in the past, so
  /// this rolls forward until it lands in the future rather than one step.
  DateTime? nextAfterNow(DateTime from, DateTime now) {
    var candidate = nextAfter(from);
    while (candidate != null && candidate.isBefore(now)) {
      final following = nextAfter(candidate);
      if (following == null) break;
      candidate = following;
    }
    return candidate;
  }

  @override
  bool operator ==(Object other) =>
      other is RepeatRule &&
      other.type == type &&
      other.weekdays.length == weekdays.length &&
      other.weekdays.containsAll(weekdays);

  @override
  int get hashCode => Object.hash(type, Object.hashAllUnordered(weekdays));
}
