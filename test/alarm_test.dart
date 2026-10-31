import 'package:flutter_test/flutter_test.dart';
import 'package:memo/features/reminders/domain/entities/repeat_rule.dart';
import 'package:memo/features/reminders/domain/usecases/apply_alarm_action.dart';
import 'package:memo/features/reminders/domain/usecases/save_reminder.dart';
import 'package:memo/features/reminders/presentation/alarm/alarm_cubit.dart';

import 'fakes.dart';

void main() {
  final due = DateTime(2026, 11, 4, 20);

  group('AlarmCubit', () {
    late InMemoryRepository repo;
    late List<String> played;
    late int stops;

    AlarmCubit build({bool ringing = false}) => AlarmCubit(
      'p',
      repo,
      SaveReminder(repo, FakeScheduler()),
      ringingNatively: (_) async => ringing,
      stopRinging: () async => stops++,
      play: (id) async => played.add(id),
      stop: () async {},
    );

    setUp(() {
      repo = InMemoryRepository([
        reminder('p', 'Pills', due).copyWith(hasVoice: true, voiceRings: true),
      ]);
      played = [];
      stops = 0;
    });

    test('plays the clip once when nothing native is ringing', () async {
      await build().load();
      expect(played, ['p']);
    });

    test('does not play over a native alarm that is already looping', () async {
      await build(ringing: true).load();
      expect(played, isEmpty);
    });

    test('Done stops the ring and completes the reminder', () async {
      final cubit = build();
      await cubit.load();
      await cubit.done();
      expect(stops, 1);
      expect(cubit.state.outcome, AlarmOutcome.done);
      expect(repo.all.single.isDone, isTrue);
    });

    test('a snooze preset re-times it from now', () async {
      final cubit = build();
      await cubit.load();
      final before = DateTime.now();
      await cubit.snooze(const Duration(hours: 1));
      expect(cubit.state.outcome, AlarmOutcome.snoozed);
      expect(
        repo.all.single.dueAt.difference(before).inMinutes,
        inInclusiveRange(59, 61),
      );
    });

    test('a missing reminder says so', () async {
      repo = InMemoryRepository();
      final cubit = build();
      await cubit.load();
      expect(cubit.state.outcome, AlarmOutcome.missing);
    });
  });

  group('ApplyAlarmAction', () {
    test('a queued snooze counts from when it was tapped', () async {
      final repo = InMemoryRepository([reminder('p', 'Pills', due)]);
      final tappedAt = DateTime(2026, 11, 4, 20, 2);
      await ApplyAlarmAction(repo, SaveReminder(repo, FakeScheduler()))(
        'p',
        AlarmAction.snooze,
        tappedAt,
      );
      expect(repo.all.single.dueAt, DateTime(2026, 11, 4, 20, 12));
    });

    test('Done on a repeat moves it to the next occurrence', () async {
      final repo = InMemoryRepository([
        reminder('p', 'Pills', due, repeat: RepeatRule.daily),
      ]);
      await ApplyAlarmAction(repo, SaveReminder(repo, FakeScheduler()))(
        'p',
        AlarmAction.done,
        due,
      );
      expect(repo.all.single.dueAt, DateTime(2026, 11, 5, 20));
      expect(repo.all.single.isDone, isFalse);
    });

    test('a reminder deleted meanwhile is ignored', () async {
      final repo = InMemoryRepository();
      await ApplyAlarmAction(repo, SaveReminder(repo, FakeScheduler()))(
        'gone',
        AlarmAction.done,
        due,
      );
      expect(repo.all, isEmpty);
    });
  });
}
