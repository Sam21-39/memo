/// Notification / AlarmManager ids for one reminder. Pure, stable across runs
/// and processes (`String.hashCode` is neither), so cancel always finds what
/// schedule registered — on both sides of a method channel.
///
/// Base is a multiple of 8, so every derived id below differs from its base
/// only in bits the base never sets for small offsets.
abstract final class AlarmIds {
  /// Max nags per occurrence. After the sixth the reminder sits overdue.
  static const maxNags = 6;

  /// The v1 id function, kept so a v1 alarm can still be cancelled.
  static int base(String reminderId) {
    var hash = 0;
    for (final unit in reminderId.codeUnits) {
      hash = (hash * 31 + unit) % 0x1FFFFFFF;
    }
    return hash * 8 % 0x7FFFFFF0;
  }

  static int main(String id) => base(id);

  static int preAlarm(String id) => base(id) ^ 0x1;

  /// k = 1..[maxNags]. On iOS with nag off, nag(1) is the +1 min burst.
  static int nag(String id, int k) => base(id) ^ (0x100 + k);

  /// Weekly rules: one main per weekday, Mon = 1 .. Sun = 7.
  static int weekday(String id, int weekday) => base(id) ^ (0x200 + weekday);

  /// iOS burst for a weekly rule's weekday fire.
  static int burstWeekday(String id, int weekday) =>
      base(id) ^ (0x300 + weekday);

  /// A repeat snoozed for one occurrence (also Android's native snooze).
  static int snooze(String id) => base(id) ^ 0x400;

  /// Pre-alarm for a weekly rule's weekday fire.
  static int preWeekday(String id, int weekday) => base(id) ^ (0x500 + weekday);

  /// Nag k after a weekly rule's weekday fire.
  static int nagWeekday(String id, int weekday, int k) =>
      base(id) ^ (0x1000 + weekday * 16 + k);

  /// Nag k after a snooze; k = 0 is the snooze's iOS burst.
  static int snoozeNag(String id, int k) => base(id) ^ (0x2000 + k);

  /// Every id this reminder could own — cancel sweeps them all.
  static List<int> all(String id) => [
    main(id),
    preAlarm(id),
    for (var k = 1; k <= maxNags; k++) nag(id, k),
    for (var d = 1; d <= 7; d++) weekday(id, d),
    for (var d = 1; d <= 7; d++) burstWeekday(id, d),
    snooze(id),
    for (var d = 1; d <= 7; d++) preWeekday(id, d),
    for (var d = 1; d <= 7; d++)
      for (var k = 1; k <= maxNags; k++) nagWeekday(id, d, k),
    for (var k = 0; k <= maxNags; k++) snoozeNag(id, k),
  ];
}
