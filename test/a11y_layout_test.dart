import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/app_prefs.dart';
import 'package:memo/core/app_settings_cubit.dart';
import 'package:memo/core/di.dart';
import 'package:memo/core/theme/memo_theme.dart';
import 'package:memo/core/ui/option_button.dart';
import 'package:memo/features/reminders/data/alarm/native_alarm.dart';
import 'package:memo/features/reminders/data/media_store.dart';
import 'package:memo/features/settings/settings_cubit.dart';
import 'package:memo/features/settings/settings_page.dart';
import 'package:memo/features/reminders/data/speech_to_text.dart';
import 'package:memo/features/reminders/data/voice_clip.dart';
import 'package:memo/features/reminders/domain/entities/repeat_rule.dart';
import 'package:memo/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:memo/features/reminders/domain/usecases/delete_reminder.dart';
import 'package:memo/features/reminders/domain/usecases/save_reminder.dart';
import 'package:memo/features/reminders/presentation/alarm/alarm_cubit.dart';
import 'package:memo/features/reminders/presentation/alarm/alarm_page.dart';
import 'package:memo/features/reminders/presentation/archive/archive_cubit.dart';
import 'package:memo/features/reminders/presentation/archive/archive_page.dart';
import 'package:memo/features/reminders/presentation/detail/detail_cubit.dart';
import 'package:memo/features/reminders/presentation/detail/detail_page.dart';
import 'package:memo/features/reminders/presentation/edit/edit_cubit.dart';
import 'package:memo/features/reminders/presentation/edit/edit_sheet.dart';
import 'package:memo/features/reminders/presentation/home/capture_cubit.dart';
import 'package:memo/features/reminders/presentation/home/home_cubit.dart';
import 'package:memo/features/reminders/presentation/home/home_page.dart';
import 'package:memo/features/reminders/presentation/widgets/check_control.dart';
import 'package:memo/features/tags/presentation/widgets/tag_chip.dart';
import 'package:memo/l10n/l10n.dart';

import 'fakes.dart';

/// (a) text at 2.0x on a 390x844 phone, (b) 320x690 at normal text.
const _cases = [(Size(390, 844), 2.0), (Size(320, 690), 1.0)];

class _Voice implements VoiceClip {
  @override
  Future<bool> hasPermission({bool request = false}) async => true;
  @override
  Future<double> level() async => 0.5;
  @override
  Future<void> start(String path) async => File(path).writeAsBytesSync([1]);
  @override
  Future<void> stop() async {}
  @override
  Future<void> cancel() async {}
  @override
  Future<void> play(String path) async {}
  @override
  Future<void> stopPlaying() async {}
}

class _EmptyStt implements SpeechToText {
  @override
  Future<bool> available(String tag) async => true;
  @override
  Future<String> availability(String tag) async => 'installed';
  @override
  Future<String> transcribeFile(String path, String tag) async => '';
}

Future<void> _show(
  WidgetTester tester,
  Size size,
  double scale,
  Widget home, {
  Locale? locale,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: MemoTheme.light.copyWith(platform: TargetPlatform.android),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (c) => MediaQuery(
          data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
          child: home,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _home() => MultiBlocProvider(
  providers: [
    BlocProvider(
      create: (_) => HomeCubit(
        sl<ReminderRepository>(),
        sl<SaveReminder>(),
        sl<DeleteReminder>(),
      )..load(),
    ),
    BlocProvider(
      create: (_) => CaptureCubit(
        sl<SaveReminder>(),
        media: MediaStore(Directory.systemTemp.createTempSync('a11y')),
        voice: _Voice(),
        stt: _EmptyStt(),
        knownTags: () => const ['Health'],
        clock: () => DateTime(2026, 11, 4, 12),
      ),
    ),
  ],
  child: const HomePage(),
);

/// No overflow or layout error; says where when there is one.
void _fits(WidgetTester tester) {
  final e = tester.takeException();
  if (e != null) fail(e is FlutterError ? e.toStringDeep() : '$e');
}

void main() {
  final now = DateTime.now();
  DateTime inDays(int d, int h) =>
      DateTime(now.year, now.month, now.day + d, h);
  final long =
      'Collect the signed forms from the ward office and post them ' * 2;

  Future<void> seed() => setUpDi([
    reminder('1', 'Pills', inDays(1, 8), tag: 'Health'),
    reminder('2', long.substring(0, 80), inDays(1, 9)),
    reminder('3', 'Bins', now.subtract(const Duration(hours: 3))),
    reminder('4', 'Dentist', inDays(3, 9), note: 'Bring the X-ray'),
    reminder('5', 'Call mum', inDays(4, 18)),
  ]);

  for (final (size, scale) in _cases) {
    final tag = '${size.width.toInt()}x${size.height.toInt()} @ ${scale}x';

    testWidgets('Home, long title, filter bar: $tag', (tester) async {
      await seed();
      await _show(tester, size, scale, _home());
      _fits(tester);
    });

    testWidgets('Home row menu: $tag', (tester) async {
      await setUpDi([reminder('1', 'Pills', inDays(1, 8))]);
      await _show(tester, size, scale, _home());
      await tester.longPress(find.text('Pills').last);
      await tester.pumpAndSettle();
      expect(find.text('Mark done'), findsOneWidget);
      _fits(tester);
    });

    testWidgets('Home swipe actions: $tag', (tester) async {
      await setUpDi([reminder('1', 'Pills', inDays(1, 8))]);
      await _show(tester, size, scale, _home());
      await tester.drag(find.text('Pills').last, const Offset(-300, 0));
      await tester.pumpAndSettle();
      _fits(tester);
      for (final label in ['Snooze\n10 min', 'Delete']) {
        final action = find.ancestor(
          of: find.text(label),
          matching: find.byType(InkWell),
        );
        final s = tester.getSize(action.first);
        expect(s.width, greaterThanOrEqualTo(44));
        expect(s.height, greaterThanOrEqualTo(44));
      }
    });

    testWidgets('capture bar typing and ambiguous confirmation (bn): $tag', (
      tester,
    ) async {
      await seed();
      await _show(tester, size, scale, _home(), locale: const Locale('bn'));
      await tester.enterText(find.byType(TextField), 'Call mum tomorrow at 8');
      await tester.pumpAndSettle();
      _fits(tester);
      await tester.tap(find.byType(ElevatedButton).last);
      await tester.pumpAndSettle();
      _fits(tester);
      for (final f in find.byType(OptionButton).evaluate()) {
        final s = tester.getSize(find.byWidget(f.widget));
        expect(s.height, greaterThanOrEqualTo(44));
        expect(s.width, greaterThanOrEqualTo(44));
      }
    });

    testWidgets('Detail: $tag', (tester) async {
      await setUpDi([reminder('1', long.substring(0, 80), inDays(2, 9))]);
      await _show(
        tester,
        size,
        scale,
        BlocProvider(
          create: (_) => DetailCubit(
            '1',
            sl<ReminderRepository>(),
            sl<SaveReminder>(),
            sl<DeleteReminder>(),
          )..load(),
          child: const DetailPage(),
        ),
      );
      _fits(tester);
    });

    testWidgets('Alarm: $tag', (tester) async {
      final repo = InMemoryRepository([
        reminder(
          'p',
          long.substring(0, 80),
          now.subtract(const Duration(hours: 2)),
        ),
      ]);
      await _show(
        tester,
        size,
        scale,
        BlocProvider(
          create: (_) => AlarmCubit(
            'p',
            repo,
            SaveReminder(repo, FakeScheduler()),
            ringingNatively: (_) async => true,
            stopRinging: () async {},
            play: (_) async {},
            stop: () async {},
            speak: (_) async => true,
          )..load(),
          child: AlarmPage(voicePath: (id) => id, onClose: () {}),
        ),
      );
      _fits(tester);
    });

    testWidgets('Archive: $tag', (tester) async {
      await setUpDi([
        reminder(
          '1',
          long.substring(0, 80),
          inDays(-1, 9),
          doneAt: inDays(0, 9),
        ),
        reminder('2', 'Bins', inDays(-2, 9), doneAt: inDays(-1, 9)),
      ]);
      await _show(
        tester,
        size,
        scale,
        BlocProvider(
          create: (_) =>
              ArchiveCubit(sl<ReminderRepository>(), sl<SaveReminder>())
                ..load(),
          child: const ArchivePage(),
        ),
      );
      _fits(tester);
      for (final chip in tester.widgetList<TagChip>(find.byType(TagChip))) {
        final s = tester.getSize(find.byWidget(chip));
        expect(s.height, greaterThanOrEqualTo(44));
        expect(s.width, greaterThanOrEqualTo(44));
      }
    });

    testWidgets('Settings: $tag', (tester) async {
      await setUpDi();
      await _show(
        tester,
        size,
        scale,
        MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => SettingsCubit(
                sl<AppPrefs>(),
                NativeAlarm(),
                sl<SaveReminder>(),
                sl<DeleteReminder>(),
              ),
            ),
            BlocProvider(create: (_) => AppSettingsCubit(sl<AppPrefs>())),
          ],
          child: const SettingsPage(),
        ),
      );
      _fits(tester);
    });

    testWidgets('Archive empty: $tag', (tester) async {
      await setUpDi();
      await _show(
        tester,
        size,
        scale,
        BlocProvider(
          create: (_) =>
              ArchiveCubit(sl<ReminderRepository>(), sl<SaveReminder>())
                ..load(),
          child: const ArchivePage(),
        ),
      );
      expect(find.text('Nothing done yet'), findsOneWidget);
      _fits(tester);
    });

    for (final advanced in [false, true]) {
      testWidgets('Editor ${advanced ? 'more options' : 'basic'}: $tag', (
        tester,
      ) async {
        await setUpDi();
        final cubit = EditCubit(sl<SaveReminder>())
          ..setTitle(long.substring(0, 80))
          ..setRepeat(const RepeatRule(RepeatType.weekly, weekdays: {1, 3}))
          ..showAdvanced(advanced);
        await _show(
          tester,
          size,
          scale,
          Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: BlocProvider.value(
                  value: cubit,
                  child: const EditForm(knownTags: ['Health', 'Home']),
                ),
              ),
            ),
          ),
        );
        _fits(tester);
        for (final b in find.byType(OptionButton).evaluate()) {
          expect(
            tester.getSize(find.byWidget(b.widget)).height,
            greaterThanOrEqualTo(44),
          );
        }
      });
    }

    testWidgets('check control hit area: $tag', (tester) async {
      await seed();
      await _show(tester, size, scale, _home());
      final s = tester.getSize(find.byType(CheckControl).first);
      expect(s.width, greaterThanOrEqualTo(44));
      expect(s.height, greaterThanOrEqualTo(44));
      final mic = find.ancestor(
        of: find.byIcon(Icons.mic_none_rounded),
        matching: find.byType(AnimatedContainer),
      );
      expect(tester.getSize(mic.first).width, greaterThanOrEqualTo(44));
      expect(tester.getSize(mic.first).height, greaterThanOrEqualTo(44));
      for (final chip in find.byType(TagChip).evaluate()) {
        expect(
          tester.getSize(find.byWidget(chip.widget)).height,
          greaterThanOrEqualTo(44),
        );
      }
    });
  }
}
