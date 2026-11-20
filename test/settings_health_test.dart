import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memo/core/app_prefs.dart';
import 'package:memo/core/app_settings_cubit.dart';
import 'package:memo/core/di.dart';
import 'package:memo/core/theme/memo_theme.dart';
import 'package:memo/features/onboarding/domain/onboarding_repository.dart';
import 'package:memo/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:memo/features/onboarding/presentation/pages/battery_page.dart';
import 'package:memo/features/reminders/data/alarm/native_alarm.dart';
import 'package:memo/features/reminders/domain/entities/reminder.dart';
import 'package:memo/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:memo/features/reminders/domain/usecases/delete_reminder.dart';
import 'package:memo/features/reminders/domain/usecases/save_reminder.dart';
import 'package:memo/features/reminders/domain/usecases/sync_alarms.dart';
import 'package:memo/features/onboarding/presentation/pages/onboarding_flow.dart';
import 'package:memo/features/settings/health_fix_page.dart';
import 'package:memo/features/settings/health_page.dart';
import 'package:memo/features/settings/settings_cubit.dart';
import 'package:memo/features/settings/settings_page.dart';
import 'package:memo/l10n/l10n.dart';

import 'fakes.dart';

const _permissions = MethodChannel('flutter.baseflow.com/permissions/methods');
const _alarmChannel = MethodChannel('memo/alarm');
const _kitChannel = MethodChannel('memo/alarmkit');

/// What the "phone" answers; tests flip these between refreshes.
var _unrestricted = false;
var _overlay = true;
var _kit = 'authorized';
var _maker = 'samsung';
final _calls = <String>[];

void _mockPlatform() {
  _unrestricted = false;
  _overlay = true;
  _kit = 'authorized';
  _maker = 'samsung';
  _calls.clear();
  final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  m.setMockMethodCallHandler(
    _permissions,
    (c) async => c.method == 'checkPermissionStatus' ? 1 : null,
  );
  m.setMockMethodCallHandler(_alarmChannel, (c) async {
    _calls.add(c.method);
    return switch (c.method) {
      'canUseFullScreenIntent' => true,
      'canDrawOverlays' => _overlay,
      'battery' => {'unrestricted': _unrestricted, 'maker': _maker},
      _ => null,
    };
  });
  m.setMockMethodCallHandler(_kitChannel, (c) async => _kit);
  addTearDown(() {
    m.setMockMethodCallHandler(_permissions, null);
    m.setMockMethodCallHandler(_alarmChannel, null);
    m.setMockMethodCallHandler(_kitChannel, null);
  });
}

Future<(SettingsCubit, FakeScheduler)> _cubit({
  bool android = true,
  bool ios = false,
}) async {
  final (_, scheduler) = await setUpDi();
  _mockPlatform();
  final cubit = SettingsCubit(
    sl<AppPrefs>(),
    const NativeAlarm(),
    sl<SaveReminder>(),
    sl<DeleteReminder>(),
    android: android,
    ios: ios,
  );
  addTearDown(cubit.close);
  return (cubit, scheduler);
}

Map<String, HealthStatus> _byId(SettingsCubit c) => {
  for (final i in c.state.health) i.id: i.status,
};

class _Repo implements OnboardingRepository {
  bool completed = false;
  @override
  Future<bool> isCompleted() async => completed;
  @override
  Future<void> complete() async => completed = true;
  @override
  Future<bool> requestNotificationPermission() async => true;
}

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  Size size = const Size(390, 844),
  double scale = 1,
  String? locale,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: MemoTheme.light.copyWith(platform: TargetPlatform.android),
      locale: locale == null ? null : Locale(locale),
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

/// Health page and fix page on a real router, sharing one cubit.
Future<void> _pumpRouter(WidgetTester tester, SettingsCubit cubit) async {
  final router = GoRouter(
    initialLocation: '/settings/health',
    routes: [
      GoRoute(
        path: '/settings/health',
        builder: (_, _) =>
            BlocProvider.value(value: cubit, child: const HealthPage()),
        routes: [
          GoRoute(
            path: 'fix/:id',
            builder: (_, s) => BlocProvider.value(
              value: cubit,
              child: HealthFixPage(
                id: s.pathParameters['id']!,
                step: s.extra as ({int n, int total})?,
              ),
            ),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(
      theme: MemoTheme.light.copyWith(platform: TargetPlatform.android),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
  await cubit.refresh();
  await tester.pumpAndSettle();
}

void main() {
  group('SettingsCubit health', () {
    test('Android items, statuses and toFix', () async {
      final (cubit, _) = await _cubit();
      await cubit.refresh();
      expect(_byId(cubit), {
        'notifications': HealthStatus.allowed,
        'exactAlarms': HealthStatus.allowed,
        'fullScreen': HealthStatus.allowed,
        'overlay': HealthStatus.allowed,
        'battery': HealthStatus.fix,
      });
      expect(cubit.state.toFix, 1);
      expect(cubit.state.maker, 'samsung');
      _overlay = false;
      _unrestricted = true;
      await cubit.refresh();
      expect(_byId(cubit)['overlay'], HealthStatus.fix);
      expect(_byId(cubit)['battery'], HealthStatus.allowed);
    });

    test('a battery read that fails drops the item, not the screen', () async {
      final (cubit, _) = await _cubit();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            _alarmChannel,
            (c) async => c.method == 'battery'
                ? throw PlatformException(code: 'x')
                : true,
          );
      await cubit.refresh();
      expect(_byId(cubit).containsKey('battery'), isFalse);
      expect(_byId(cubit)['notifications'], HealthStatus.allowed);
    });

    test('iOS items follow AlarmKit', () async {
      final (cubit, _) = await _cubit(android: false, ios: true);
      await cubit.refresh();
      expect(_byId(cubit), {
        'alarms': HealthStatus.allowed,
        'notifications': HealthStatus.allowed,
        'focus': HealthStatus.allowed,
        'backgroundRefresh': HealthStatus.ok,
      });
      expect(cubit.state.toFix, 0);
      _kit = 'notDetermined';
      await cubit.refresh();
      expect(_byId(cubit)['alarms'], HealthStatus.fix);
      expect(_byId(cubit)['focus'], HealthStatus.fix);
      expect(cubit.state.toFix, 2);
      _kit = 'denied';
      await cubit.refresh();
      expect(_byId(cubit)['alarms'], HealthStatus.off);
      _kit = 'unavailable';
      await cubit.refresh();
      expect(_byId(cubit).containsKey('alarms'), isFalse);
      // Before iOS 26: Focus is informational, never "to fix".
      expect(_byId(cubit)['focus'], HealthStatus.ok);
      expect(cubit.state.toFix, 0);
    });

    test('fix("battery") opens the app settings page', () async {
      final (cubit, _) = await _cubit();
      await cubit.fix('battery');
      expect(_calls, contains('openBatterySettings'));
    });

    test('ringTest saves memo-test due in ~10 s and remembers when', () async {
      final (cubit, scheduler) = await _cubit();
      final before = DateTime.now();
      await cubit.ringTest();
      final r = scheduler.scheduled.single;
      expect(r.id, 'memo-test');
      expect(r.title, 'Test alarm');
      final lead = r.dueAt.difference(before).inMicroseconds;
      expect(lead, inInclusiveRange(9000000, 12000000));
      expect(cubit.state.lastTestAt, isNotNull);
      expect(cubit.state.testFailed, isFalse);
    });

    test(
      'ringTest that cannot schedule reports it and keeps no last test',
      () async {
        final (cubit, scheduler) = await _cubit();
        scheduler.fail = true;
        await cubit.ringTest();
        expect(cubit.state.testFailed, isTrue);
        expect(cubit.state.lastTestAt, isNull);
        expect(await sl<ReminderRepository>().getById('memo-test'), isNull);
      },
    );

    test('ringTest reads aloud only in English', () async {
      final (cubit, _) = await _cubit();
      await cubit.ringTest();
      expect(
        (await sl<ReminderRepository>().getById('memo-test'))!.readAloud,
        isTrue,
      );
      await sl<AppPrefs>().setInterfaceLocale('hi');
      await cubit.ringTest();
      expect(
        (await sl<ReminderRepository>().getById('memo-test'))!.readAloud,
        isFalse,
      );
    });

    test('a failed battery open still refreshes', () async {
      final (cubit, _) = await _cubit();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            _alarmChannel,
            (c) async => c.method == 'openBatterySettings'
                ? throw PlatformException(code: 'x')
                : c.method == 'battery'
                ? {'unrestricted': false, 'maker': 'x'}
                : true,
          );
      await cubit.openBatterySettings();
      expect(cubit.state.android, isTrue);
    });
  });

  group('SyncAlarms test reminder', () {
    final now = DateTime(2026, 5, 1, 12);
    Future<(ReminderRepository, FakeScheduler)> run(Reminder r) async {
      final (repo, scheduler) = await setUpDi([r]);
      await SyncAlarms(repo, scheduler)(now: now);
      return (repo, scheduler);
    }

    test('stale or done memo-test is deleted and cancelled', () async {
      var (repo, s) = await run(
        reminder(
          'memo-test',
          'Test alarm',
          now.subtract(const Duration(minutes: 3)),
        ),
      );
      expect(await repo.getById('memo-test'), isNull);
      expect(s.cancelled, contains('memo-test'));
      (repo, s) = await run(
        reminder(
          'memo-test',
          'Test alarm',
          now.add(const Duration(minutes: 5)),
          doneAt: now,
        ),
      );
      expect(await repo.getById('memo-test'), isNull);
    });

    test('fresh memo-test and ordinary overdue reminders stay', () async {
      var (repo, _) = await run(
        reminder(
          'memo-test',
          'Test alarm',
          now.subtract(const Duration(seconds: 30)),
        ),
      );
      expect(await repo.getById('memo-test'), isNotNull);
      (repo, _) = await run(
        reminder('x', 'Pills', now.subtract(const Duration(hours: 3))),
      );
      expect(await repo.getById('x'), isNotNull);
    });
  });

  group('OnboardingCubit battery step', () {
    Future<(OnboardingCubit, _Repo, AppPrefs)> make({
      required bool android,
      bool stepDone = false,
    }) async {
      await setUpDi();
      _mockPlatform();
      if (stepDone) await sl<AppPrefs>().setBatteryStepDone();
      final repo = _Repo();
      final cubit = OnboardingCubit(
        repo,
        const NativeAlarm(),
        sl<AppPrefs>(),
        android: android,
      );
      addTearDown(cubit.close);
      return (cubit, repo, sl<AppPrefs>());
    }

    test('Android + restricted goes to the battery step', () async {
      _mockPlatform();
      final (cubit, repo, prefs) = await make(android: true);
      _maker = 'xiaomi';
      _unrestricted = false;
      await cubit.requestPermissionAndFinish();
      expect(cubit.state.status, OnboardingStatus.battery);
      expect(cubit.state.maker, 'xiaomi');
      expect(repo.completed, isFalse);
      await cubit.finishBattery();
      expect(cubit.state.status, OnboardingStatus.finished);
      expect(repo.completed, isTrue);
      expect(prefs.batteryStepDone, isTrue);
    });

    test('Android + unrestricted, or step already done, finishes', () async {
      var (cubit, repo, _) = await make(android: true);
      _unrestricted = true;
      await cubit.requestPermissionAndFinish();
      expect(cubit.state.status, OnboardingStatus.finished);
      (cubit, repo, _) = await make(android: true, stepDone: true);
      _unrestricted = false;
      await cubit.requestPermissionAndFinish();
      expect(cubit.state.status, OnboardingStatus.finished);
      expect(repo.completed, isTrue);
    });

    test('iOS never shows it', () async {
      final (cubit, _, _) = await make(android: false);
      _unrestricted = false;
      await cubit.requestPermissionAndFinish();
      expect(cubit.state.status, OnboardingStatus.finished);
      expect(_calls, isNot(contains('battery')));
    });
  });

  group('pages', () {
    testWidgets('health page shows Fix, fix page advances once fixed', (
      tester,
    ) async {
      final (cubit, _) = await _cubit();
      _overlay = false;
      _unrestricted = false;
      await _pumpRouter(tester, cubit);
      expect(find.text('Fix'), findsNWidgets(2));
      expect(find.textContaining('2 settings may stop'), findsOneWidget);

      await tester.tap(find.text('Fix: Take over the screen'));
      await tester.pumpAndSettle();
      expect(find.text('Fix 1 of 2'), findsOneWidget);
      expect(find.text('Detected: samsung.'), findsOneWidget);

      _overlay = true;
      await tester.tap(find.text('I changed it, check again'));
      await tester.pumpAndSettle();
      expect(find.text('Fix 2 of 2'), findsOneWidget);
      expect(find.text('Open battery settings'), findsOneWidget);

      _unrestricted = true;
      await tester.tap(find.text('I changed it, check again'));
      await tester.pumpAndSettle();
      expect(find.byType(HealthFixPage), findsNothing);
      expect(find.textContaining('No phone can promise'), findsOneWidget);
    });

    testWidgets('fix n of m follows the remaining items', (tester) async {
      final (cubit, _) = await _cubit();
      _overlay = false;
      await _pumpRouter(tester, cubit);
      await tester.tap(find.text('Battery'));
      await tester.pumpAndSettle();
      expect(find.text('Fix 2 of 2'), findsOneWidget);
      _unrestricted = true;
      await tester.tap(find.text('I changed it, check again'));
      await tester.pumpAndSettle();
      expect(find.text('Fix 2 of 2'), findsOneWidget);
      expect(find.text('Detected: samsung.'), findsOneWidget);
    });

    testWidgets('onboarding reaches step 3 and I did this finishes', (
      tester,
    ) async {
      await setUpDi();
      _mockPlatform();
      var done = false;
      sl.registerSingleton<OnboardingRepository>(_Repo());
      sl.registerSingleton(const NativeAlarm());
      await _pump(
        tester,
        OnboardingFlow(android: true, onDone: () => done = true),
      );
      for (final label in ['Continue', 'Allow notifications']) {
        final f = find.text(label);
        if (f.evaluate().isNotEmpty) {
          await tester.tap(f);
          await tester.pumpAndSettle();
        }
      }
      expect(find.text('Step 3 of 3'), findsOneWidget);
      await tester.tap(find.text('I did this'));
      await tester.pumpAndSettle();
      expect(done, isTrue);
    });

    testWidgets('battery step lists autostart only for some makers', (
      tester,
    ) async {
      await setUpDi();
      for (final (maker, autostart) in [('Xiaomi', true), ('samsung', false)]) {
        await _pump(
          tester,
          BatteryPage(
            maker: maker,
            onOpen: () {},
            onDone: () {},
            onSkip: () {},
          ),
        );
        expect(find.textContaining('Battery · Memō'), findsOneWidget);
        expect(
          find.textContaining('autostart'),
          autostart ? findsOneWidget : findsNothing,
        );
        expect(find.text('Step 3 of 3'), findsOneWidget);
      }
    });

    testWidgets('theme row switches the root theme mode', (tester) async {
      final (cubit, _) = await _cubit();
      final app = AppSettingsCubit(sl<AppPrefs>());
      addTearDown(app.close);
      await _pump(
        tester,
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: cubit),
            BlocProvider.value(value: app),
          ],
          child: const SettingsPage(),
        ),
      );
      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(app.state.themeMode, 'dark');
      expect(sl<AppPrefs>().themeMode, 'dark');
      expect(find.text('Phase 2'), findsNothing);
    });

    testWidgets('test alarm row schedules memo-test and toasts', (
      tester,
    ) async {
      final (cubit, scheduler) = await _cubit();
      final app = AppSettingsCubit(sl<AppPrefs>());
      addTearDown(app.close);
      await _pump(
        tester,
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: cubit),
            BlocProvider.value(value: app),
          ],
          child: const SettingsPage(),
        ),
      );
      await tester.tap(find.text('Test alarm'));
      await tester.pump();
      await tester.pump();
      expect(scheduler.scheduled.single.id, 'memo-test');
      expect(
        find.text('Lock the phone. It rings in about 10 seconds.'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 5));
      expect(find.textContaining('Lock the phone'), findsNothing);
    });
  });

  // 320x690 at 2.0x text is the narrowest, largest case the plan names.
  const cases = [(Size(320, 690), 2.0), (Size(390, 844), 2.0)];
  for (final (size, scale) in cases) {
    final tag = '${size.width.toInt()}x${size.height.toInt()} @ ${scale}x';
    for (final locale in ['en', 'hi', 'bn']) {
      testWidgets('Settings, Health, Fix, Battery fit: $tag $locale', (
        tester,
      ) async {
        final (cubit, _) = await _cubit();
        _overlay = false;
        await cubit.refresh();
        final app = AppSettingsCubit(sl<AppPrefs>());
        addTearDown(app.close);
        final pages = <Widget>[
          MultiBlocProvider(
            providers: [
              BlocProvider.value(value: cubit),
              BlocProvider.value(value: app),
            ],
            child: const SettingsPage(),
          ),
          BlocProvider.value(value: cubit, child: const HealthPage()),
          BlocProvider.value(
            value: cubit,
            child: const HealthFixPage(id: 'battery'),
          ),
          BatteryPage(
            maker: 'xiaomi',
            onOpen: () {},
            onDone: () {},
            onSkip: () {},
          ),
        ];
        for (final page in pages) {
          await _pump(tester, page, size: size, scale: scale, locale: locale);
          final e = tester.takeException();
          if (e != null) {
            fail(
              '${page.runtimeType}: ${e is FlutterError ? e.diagnostics.map((d) => d.toStringDeep()).join() : e}',
            );
          }
        }
      });
    }
  }
}
