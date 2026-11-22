import 'package:timezone/timezone.dart' as tz;

import '../domain/repositories/reminder_repository.dart';

/// A repeat keeps its wall-clock time across a time-zone change: a 07:00
/// pill stays 07:00 local. One-offs keep their instant (not touched here).
class RewallRepeats {
  const RewallRepeats(this._repository);

  final ReminderRepository _repository;

  Future<void> call(String from, String to) async {
    final target = tz.getLocation(to);
    for (final r in await _repository.getAll()) {
      if (!r.repeat.repeats) continue;
      final old = tz.TZDateTime.from(r.dueAt, tz.getLocation(from));
      final moved = tz.TZDateTime(
        target,
        old.year,
        old.month,
        old.day,
        old.hour,
        old.minute,
      );
      await _repository.save(
        r.copyWith(
          dueAt: DateTime.fromMillisecondsSinceEpoch(
            moved.millisecondsSinceEpoch,
          ),
          clearSnooze: true,
        ),
      );
    }
  }
}
