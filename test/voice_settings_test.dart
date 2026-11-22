import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memo/core/app_prefs.dart';
import 'package:memo/core/app_settings_cubit.dart';
import 'package:memo/core/di.dart';
import 'package:memo/features/reminders/data/alarm/native_alarm.dart';
import 'package:memo/features/reminders/data/spoken_reminder.dart';
import 'package:memo/features/reminders/domain/usecases/delete_reminder.dart';
import 'package:memo/features/reminders/domain/usecases/save_reminder.dart';
import 'package:memo/features/reminders/presentation/widgets/voice_notice.dart';
import 'package:memo/features/settings/language_page.dart';
import 'package:memo/features/settings/settings_cubit.dart';
import 'package:memo/features/settings/settings_page.dart';
import 'package:memo/features/settings/voice_page.dart';

import 'fakes.dart';

const _stt = MethodChannel('memo/stt');
const _tts = MethodChannel('memo/tts');
final _messenger =
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

/// The phone: STT answer per language, offline TTS voices; calls recorded.
final _spoke = <Map>[];
var _syncs = 0;

void _phone({
  Map<String, String> stt = const {},
  List<String> voices = const ['en'],
}) {
  _spoke.clear();
  _messenger.setMockMethodCallHandler(_stt, (c) async {
    final tag = (c.arguments as Map)['locale'] as String;
    return stt[tag.split('-').first] ?? 'unavailable';
  });
  _messenger.setMockMethodCallHandler(_tts, (c) async {
    switch (c.method) {
      case 'voices':
        return voices;
      case 'preview':
        _spoke.add(c.arguments as Map);
        return voices.contains((c.arguments as Map)['language']);
      default:
        return null;
    }
  });
  addTearDown(() {
    _messenger.setMockMethodCallHandler(_stt, null);
    _messenger.setMockMethodCallHandler(_tts, null);
  });
}

Future<AppSettingsCubit> _setUp({String playback = 'follow'}) async {
  await setUpDi();
  final prefs = sl<AppPrefs>();
  await prefs.setPlaybackLocale(playback);
  _syncs = 0;
  sl.registerSingleton(
    SpokenReminder(
      gender: () => prefs.voiceGender,
      playback: () => prefs.playbackLocale,
    ),
  );
  final app = AppSettingsCubit(prefs, onLanguageChanged: () async => _syncs++);
  addTearDown(app.close);
  return app;
}

SettingsCubit _settings() => SettingsCubit(
  sl<AppPrefs>(),
  const NativeAlarm(),
  sl<SaveReminder>(),
  sl<DeleteReminder>(),
  android: false,
  ios: false,
);

Future<void> _show(
  WidgetTester tester,
  AppSettingsCubit app,
  Widget page,
) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final settings = _settings();
  addTearDown(settings.close);
  await tester.pumpWidget(
    themed(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: app),
          BlocProvider.value(value: settings),
        ],
        child: page,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Speaking language shows per-language offline availability', (
    tester,
  ) async {
    _phone(stt: {'en': 'installed', 'hi': 'downloadable'});
    final app = await _setUp();
    await _show(tester, app, const LanguagePage());
    expect(find.text('SPEAKING LANGUAGE'), findsOneWidget);
    expect(find.text('Offline on this phone'), findsOneWidget);
    expect(find.text('Needs a download in phone settings'), findsOneWidget);
    expect(find.text('Not available on this phone'), findsOneWidget);
    expect(find.textContaining('one language at a time'), findsOneWidget);

    // An unavailable language stays selectable; the failure panel explains.
    await tester.ensureVisible(find.text('বাংলা').last);
    await tester.tap(find.text('বাংলা').last);
    await tester.pumpAndSettle();
    expect(app.state.inputLocale, 'bn');
    expect(sl<AppPrefs>().inputLocale, 'bn');
  });

  testWidgets('Read-aloud voice: missing voices are honest, not hidden', (
    tester,
  ) async {
    _phone(voices: ['en']);
    final app = await _setUp();
    await _show(tester, app, const VoicePage());
    expect(find.text('Read-aloud voice'), findsOneWidget);
    expect(find.text('Follow reminder language'), findsOneWidget);
    expect(find.text('No offline Hindi voice on this phone'), findsOneWidget);
    expect(find.text('No offline Bengali voice on this phone'), findsOneWidget);
    expect(find.text('No offline English voice on this phone'), findsNothing);
    expect(find.text('Not installed'), findsNWidgets(2));
    expect(find.text('English voices'), findsOneWidget);
  });

  testWidgets('choosing a playback language saves it and syncs alarms once', (
    tester,
  ) async {
    _phone(voices: ['en', 'hi']);
    final app = await _setUp();
    await _show(tester, app, const VoicePage());
    await tester.tap(find.text('हिन्दी').last);
    await tester.pumpAndSettle();
    expect(app.state.playbackLocale, 'hi');
    expect(sl<AppPrefs>().playbackLocale, 'hi');
    expect(_syncs, 1);
  });

  testWidgets('preview speaks the chosen language, says so when it cannot', (
    tester,
  ) async {
    _phone(voices: ['en']);
    final app = await _setUp();
    await _show(tester, app, const VoicePage());
    await tester.tap(find.textContaining('Preview'));
    await tester.pumpAndSettle();
    expect(_spoke.single['language'], 'en');
    expect(_spoke.single['text'], 'Reminder. Take your pills.');
    expect(find.textContaining('nothing was played'), findsNothing);

    await app.setPlaybackLocale('bn');
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Preview'));
    await tester.pumpAndSettle();
    expect(_spoke.last['language'], 'bn');
    expect(_spoke.last['text'], 'রিমাইন্ডার। ওষুধ খান।');
    expect(find.textContaining('nothing was played'), findsOneWidget);
  });

  testWidgets('changing the voice gender syncs alarms', (tester) async {
    _phone();
    const permissions = MethodChannel(
      'flutter.baseflow.com/permissions/methods',
    );
    _messenger.setMockMethodCallHandler(permissions, (_) async => 1);
    addTearDown(() => _messenger.setMockMethodCallHandler(permissions, null));
    final app = await _setUp();
    await _show(tester, app, const VoicePage());
    await tester.tap(find.text('Female'));
    await tester.pumpAndSettle();
    expect(sl<AppPrefs>().voiceGender, 'male');
    expect(_syncs, 1);
  });

  testWidgets('Settings: Speaking language and Read-aloud voice rows', (
    tester,
  ) async {
    _phone();
    final app = await _setUp(playback: 'bn');
    await sl<AppPrefs>().setInputLocale('hi');
    final fresh = AppSettingsCubit(sl<AppPrefs>());
    addTearDown(fresh.close);
    await _show(tester, fresh, const SettingsPage());
    expect(find.text('Speaking language'), findsOneWidget);
    expect(find.text('Read-aloud voice'), findsOneWidget);
    expect(find.text('हिन्दी'), findsOneWidget);
    expect(find.text('বাংলা'), findsOneWidget);
    // The temporary one-row Voice toggle is gone.
    expect(find.text('Voice'), findsNothing);
    expect(app.state.playbackLocale, 'bn');
  });

  for (final page in [const LanguagePage(), const VoicePage()]) {
    testWidgets('${page.runtimeType} fits 320 px at 2.0x text', (tester) async {
      _phone(stt: {'en': 'installed'}, voices: ['en']);
      final app = await _setUp();
      await tester.binding.setSurfaceSize(const Size(320, 690));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      await _show(tester, app, page);
      expect(tester.takeException(), isNull);
    });
  }

  group('VoiceNotice', () {
    Future<void> pump(
      WidgetTester tester, {
      String title = 'ওষুধ খান',
      bool hasVoice = false,
      bool readAloud = true,
      String playback = 'follow',
    }) async {
      await _setUp(playback: playback);
      await tester.pumpWidget(
        themed(
          Scaffold(
            body: VoiceNotice(
              title: title,
              readAloud: readAloud,
              hasVoice: hasVoice,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('names the language and the chime', (tester) async {
      _phone(voices: ['en']);
      await pump(tester);
      expect(
        find.text('No Bengali voice on this phone. It rings with the chime.'),
        findsOneWidget,
      );
    });

    testWidgets('a Latin title with a missing chosen voice says so too', (
      tester,
    ) async {
      _phone(voices: ['en']);
      await pump(tester, title: 'Pills', playback: 'hi');
      expect(find.textContaining('No Hindi voice'), findsOneWidget);
    });

    testWidgets('nothing when a voice exists or read aloud is off', (
      tester,
    ) async {
      _phone(voices: ['en', 'bn']);
      await pump(tester);
      expect(find.textContaining('No Bengali'), findsNothing);
      _phone(voices: ['en']);
      await pump(tester, readAloud: false);
      expect(find.textContaining('No Bengali'), findsNothing);
    });
  });
}
