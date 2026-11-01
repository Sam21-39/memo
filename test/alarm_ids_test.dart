import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/reminders/domain/alarm/alarm_ids.dart';

void main() {
  test('the base is the v1 function, so v1 alarms can still be cancelled', () {
    // Value computed by 0.0.1's NotificationScheduler._baseId.
    var hash = 0;
    for (final unit in 'abc123'.codeUnits) {
      hash = (hash * 31 + unit) % 0x1FFFFFFF;
    }
    expect(AlarmIds.base('abc123'), hash * 8 % 0x7FFFFFF0);
  });

  test('ids are stable across calls', () {
    expect(AlarmIds.all('1793430295000000'), AlarmIds.all('1793430295000000'));
  });

  test('one reminder never reuses an id across fires', () {
    final ids = AlarmIds.all('1793430295000000');
    expect(ids.toSet(), hasLength(ids.length));
    expect(
      ids,
      hasLength(
        1 +
            1 +
            AlarmIds.maxNags +
            7 +
            7 +
            1 +
            7 +
            7 * AlarmIds.maxNags +
            AlarmIds.maxNags +
            1,
      ),
    );
  });

  test('ids stay positive 32-bit ints, as both plugins require', () {
    for (final id in ['a', 'zzzzzzzzzzzzzzzzzz', '9' * 40]) {
      for (final n in AlarmIds.all(id)) {
        expect(n, inInclusiveRange(0, 0x7FFFFFFF));
      }
    }
  });

  test('two reminders created a microsecond apart do not collide', () {
    final a = AlarmIds.all('1793430295000000').toSet();
    final b = AlarmIds.all('1793430295000001').toSet();
    expect(a.intersection(b), isEmpty);
  });
}
