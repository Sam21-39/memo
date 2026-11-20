import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memo/core/app_prefs.dart';
import 'package:memo/core/app_settings_cubit.dart';
import 'package:memo/app.dart';
import 'package:memo/core/di.dart';
import 'package:memo/features/reminders/data/alarm/local_notification_scheduler.dart';
import 'package:memo/features/reminders/data/alarm/native_alarm.dart';
import 'package:memo/features/reminders/data/media_store.dart';
import 'package:memo/features/reminders/data/voice_clip.dart';
import 'package:memo/l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

class _Voice extends Fake implements VoiceClip {}

class _Plugin extends Fake implements FlutterLocalNotificationsPlugin {}

class _Notifications extends LocalNotificationScheduler {
  _Notifications() : super(_Plugin());
  @override
  Future<NotificationTap?> launchTap() async => null;
}

/// The real shell (MemoApp, real router, real locale resolution) over fakes.
Future<void> _pumpApp(WidgetTester tester, String pref, String route) async {
  await setUpDi();
  SharedPreferences.setMockInitialValues({
    'onboarding_done': true,
    'interface_locale': pref,
  });
  final prefs = await AppPrefs.open();
  sl
    ..unregister<AppPrefs>()
    ..registerSingleton<AppPrefs>(prefs)
    ..registerSingleton(AppSettingsCubit(prefs))
    ..registerSingleton<LocalNotificationScheduler>(_Notifications())
    ..registerSingleton(const NativeAlarm())
    ..registerSingleton(MediaStore(Directory.systemTemp.createTempSync('app')))
    ..registerSingleton<VoiceClip>(_Voice());
  await tester.pumpWidget(const MemoApp());
  await tester.pumpAndSettle();
  final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
  router.go('/settings');
  await tester.pumpAndSettle();
  if (route != '/settings') {
    unawaited(router.push(route));
    await tester.pumpAndSettle();
  }
}

Future<AppPrefs> _open(Map<String, Object> initial) async {
  SharedPreferences.setMockInitialValues(initial);
  return AppPrefs.open();
}

void main() {
  test('existing install keeps English', () async {
    final prefs = await _open({'onboarding_done': true});
    expect(prefs.interfaceLocale, 'en');
    expect(prefs.inputLocale, 'en');
    expect(prefs.playbackLocale, 'follow');
    expect(prefs.themeMode, 'system');
  });

  test('fresh install follows the device, seeded once', () async {
    final prefs = await _open({});
    expect(prefs.interfaceLocale, 'system');
    expect(['en', 'hi', 'bn'], contains(prefs.inputLocale));
    await prefs.setInterfaceLocale('hi');
    await prefs.setInputLocale('bn');
    final again = await AppPrefs.open(); // seeding runs again, must not clobber
    expect(again.interfaceLocale, 'hi');
    expect(again.inputLocale, 'bn');
  });

  test('stored locales survive even before onboarding is done', () async {
    final prefs = await _open({'interface_locale': 'bn', 'input_locale': 'hi'});
    expect(prefs.onboardingDone, false);
    expect(prefs.interfaceLocale, 'bn');
    expect(prefs.inputLocale, 'hi');
  });

  test('setters persist and emit; language changes resync', () async {
    final prefs = await _open({'onboarding_done': true});
    var resyncs = 0;
    final cubit = AppSettingsCubit(
      prefs,
      onLanguageChanged: () async => resyncs++,
    );
    await cubit.setInterfaceLocale('bn');
    await cubit.setInputLocale('hi');
    await cubit.setPlaybackLocale('en');
    await cubit.setThemeMode('dark');
    expect(cubit.state.interfaceLocale, 'bn');
    expect(cubit.state.inputLocale, 'hi');
    expect(cubit.state.playbackLocale, 'en');
    expect(cubit.state.themeMode, 'dark');
    expect(resyncs, 2);
    expect(prefs.interfaceLocale, 'bn');
    expect(prefs.inputLocale, 'hi');
    expect(prefs.playbackLocale, 'en');
    expect(prefs.themeMode, 'dark');
  });

  group('system locale resolution', () {
    tearDown(() {
      TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher
          .clearLocalesTestValue();
    });

    testWidgets('unsupported device language shows English', (tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('ta', 'IN')];
      await _pumpApp(tester, 'system', '/settings');
      expect(find.text('Settings'), findsWidgets);
    });

    testWidgets('Hindi device shows Hindi, follows changes', (tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('hi', 'IN')];
      await _pumpApp(tester, 'system', '/settings');
      expect(find.text('सेटिंग्स'), findsWidgets);
      tester.platformDispatcher.localesTestValue = const [Locale('bn', 'BD')];
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsNothing);
      expect(find.text('সেটিংস'), findsWidgets);
    });
  });

  testWidgets('picking Hindi re-renders, navigation survives', (tester) async {
    await _pumpApp(tester, 'en', '/settings/language');
    await tester.tap(find.text('हिन्दी'));
    await tester.pumpAndSettle();
    expect(sl<AppPrefs>().interfaceLocale, 'hi');
    expect(find.text('हिन्दी'), findsWidgets);
    await tester.tap(find.text(l10n('hi').commonBack));
    await tester.pumpAndSettle();
    expect(find.text('सेटिंग्स'), findsWidgets);
    expect(find.text('Settings'), findsNothing);
  });
}
