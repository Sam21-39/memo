import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/timezone.dart' as tz;

import 'core/app_prefs.dart';
import 'core/app_settings_cubit.dart';
import 'core/chrome/chrome_mode.dart';
import 'core/di.dart';
import 'core/theme/memo_theme.dart';
import 'features/onboarding/presentation/pages/onboarding_flow.dart';
import 'features/reminders/data/alarm/ios_alarm_scheduler.dart';
import 'features/reminders/data/alarm/local_notification_scheduler.dart';
import 'features/reminders/data/alarm/native_alarm.dart';
import 'features/reminders/data/media_store.dart';
import 'features/reminders/data/rewall_repeats.dart';
import 'features/reminders/data/speech_to_text.dart';
import 'features/reminders/data/spoken_reminder.dart';
import 'features/reminders/data/voice_clip.dart';
import 'features/reminders/domain/repositories/reminder_repository.dart';
import 'features/reminders/domain/usecases/apply_alarm_action.dart';
import 'features/reminders/domain/usecases/delete_reminder.dart';
import 'features/reminders/domain/usecases/save_reminder.dart';
import 'features/reminders/domain/usecases/sync_alarms.dart';
import 'features/reminders/presentation/alarm/alarm_cubit.dart';
import 'features/reminders/presentation/alarm/alarm_page.dart';
import 'features/reminders/presentation/archive/archive_cubit.dart';
import 'features/reminders/presentation/archive/archive_page.dart';
import 'features/reminders/presentation/detail/detail_cubit.dart';
import 'features/reminders/presentation/detail/detail_page.dart';
import 'features/reminders/presentation/home/capture_cubit.dart';
import 'features/reminders/presentation/home/home_cubit.dart';
import 'features/reminders/presentation/home/home_state.dart';
import 'features/reminders/presentation/home/home_page.dart';
import 'features/settings/health_fix_page.dart';
import 'features/settings/health_page.dart';
import 'features/settings/language_page.dart';
import 'features/settings/settings_cubit.dart';
import 'features/settings/settings_page.dart';
import 'l10n/l10n.dart';

SettingsCubit _settingsCubit() => SettingsCubit(
  sl<AppPrefs>(),
  sl<NativeAlarm>(),
  sl<SaveReminder>(),
  sl<DeleteReminder>(),
);

GoRouter buildRouter(AppPrefs prefs) {
  late final GoRouter router;
  router = GoRouter(
    redirect: (context, state) =>
        !prefs.onboardingDone && state.matchedLocation != '/onboarding'
        ? '/onboarding'
        : null,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => HomeCubit(
                sl<ReminderRepository>(),
                sl<SaveReminder>(),
                sl<DeleteReminder>(),
              )..load(),
            ),
            BlocProvider(
              create: (context) => CaptureCubit(
                sl<SaveReminder>(),
                media: sl<MediaStore>(),
                voice: sl<VoiceClip>(),
                stt: const SpeechToText(),
                knownTags: () {
                  final home = context.read<HomeCubit>().state;
                  return home is HomeReady ? home.tagsInUse : const [];
                },
                defaultNagMin: () => sl<AppPrefs>().defaultNagMin,
                readAloudDefault: () => sl<AppPrefs>().readAloudDefault,
              ),
            ),
          ],
          child: const HomePage(),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, _) => OnboardingFlow(onDone: () => router.go('/')),
      ),
      GoRoute(
        path: '/reminder/:id',
        builder: (_, state) => BlocProvider(
          create: (_) => DetailCubit(
            state.pathParameters['id']!,
            sl<ReminderRepository>(),
            sl<SaveReminder>(),
            sl<DeleteReminder>(),
          )..load(),
          child: const DetailPage(),
        ),
      ),
      GoRoute(
        path: '/alarm/:id',
        builder: (_, state) {
          final voice = sl<VoiceClip>();
          final media = sl<MediaStore>();
          final native = sl<NativeAlarm>();
          return BlocProvider(
            create: (_) => AlarmCubit(
              state.pathParameters['id']!,
              sl<ReminderRepository>(),
              sl<SaveReminder>(),
              ringingNatively: (id) async =>
                  Platform.isAndroid && await native.ringing() == id,
              stopRinging: () async {
                if (Platform.isAndroid) {
                  await native.stopRinging(state.pathParameters['id']);
                }
              },
              play: (id) => voice.play(media.voicePath(id)),
              stop: voice.stopPlaying,
              speak: sl<SpokenReminder>().say,
            )..load(),
            child: AlarmPage(
              voicePath: media.voicePath,
              onClose: () => router.canPop() ? router.pop() : router.go('/'),
            ),
          );
        },
      ),
      GoRoute(
        path: '/done',
        builder: (_, _) => BlocProvider(
          create: (_) =>
              ArchiveCubit(sl<ReminderRepository>(), sl<SaveReminder>())
                ..load(),
          child: const ArchivePage(),
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, _) => BlocProvider(
          create: (_) => _settingsCubit()..refresh(),
          child: const SettingsPage(),
        ),
        routes: [
          GoRoute(path: 'language', builder: (_, _) => const LanguagePage()),
          GoRoute(
            path: 'health',
            builder: (_, _) => BlocProvider(
              create: (_) => _settingsCubit()..refresh(),
              child: const HealthPage(),
            ),
            routes: [
              GoRoute(
                path: 'fix/:id',
                builder: (_, state) => BlocProvider(
                  create: (_) => _settingsCubit()..refresh(),
                  child: HealthFixPage(
                    id: state.pathParameters['id']!,
                    step: state.extra as ({int n, int total})?,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  return router;
}

class MemoApp extends StatefulWidget {
  const MemoApp({super.key});

  @override
  State<MemoApp> createState() => _MemoAppState();
}

class _MemoAppState extends State<MemoApp> {
  late final GoRouter _router = buildRouter(sl<AppPrefs>());
  late final AppLifecycleListener _lifecycle;
  final _handled = <String, DateTime>{};
  bool _reduceTransparency = false;

  @override
  void initState() {
    super.initState();
    final notifications = sl<LocalNotificationScheduler>();
    notifications.onTap = _handleTap;
    _lifecycle = AppLifecycleListener(onResume: _catchUp);
    _catchUp();
    // A tap that cold-started the app is not delivered to onTap.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final tap = await notifications.launchTap();
      if (tap != null) await _handleTap(tap);
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  /// On launch and resume: apply Done/Snooze tapped on a native alarm while
  /// Dart was not running, then re-register every alarm — never trust that a
  /// request registered yesterday still exists.
  Future<void> _catchUp() async {
    final native = sl<NativeAlarm>();
    try {
      if (Platform.isAndroid) {
        for (final queued in await native.drainActions()) {
          await sl<ApplyAlarmAction>()(
            queued.reminderId,
            queued.action == 'done' ? AlarmAction.done : AlarmAction.snooze,
            queued.at,
          );
        }
      }
      if (Platform.isIOS) {
        // Done / Snooze tapped on an AlarmKit alarm while the app was closed.
        for (final queued in await sl<AlarmKit>().drainActions()) {
          await sl<ApplyAlarmAction>()(
            queued.reminderId,
            queued.action == 'done' ? AlarmAction.done : AlarmAction.snooze,
            queued.at,
          );
        }
        final reduce = await native.reduceTransparency();
        if (mounted && reduce != _reduceTransparency) {
          setState(() => _reduceTransparency = reduce);
        }
      }
      try {
        final zone = (await FlutterTimezone.getLocalTimezone()).identifier;
        final last = sl<AppPrefs>().lastTimeZone;
        // Saved before the re-wall: a half-done re-wall must never run again
        // from the old zone, which would shift the rows that already moved.
        if (last != zone) await sl<AppPrefs>().setLastTimeZone(zone);
        if (last != null && last != zone) {
          tz.setLocalLocation(tz.getLocation(zone));
          await sl<RewallRepeats>()(last, zone);
        }
      } catch (_) {
        // Repeats keep their old wall clock until the next launch; sync goes on.
      }
    } on NativeAlarmError {
      // The queue stays native-side; the next resume tries again.
    } finally {
      await sl<SyncAlarms>()();
    }
  }

  /// Done and Snooze apply against the DB; a body tap opens the alarm
  /// screen. The launch-details path and the live callback can both deliver
  /// one tap, and a snooze applied twice is silently 20 minutes, so each
  /// `<id>:<action>:<due_at>` is honoured once per 10 s.
  Future<void> _handleTap(NotificationTap tap) async {
    final reminder = await sl<ReminderRepository>().getById(tap.reminderId);
    if (reminder == null) return;
    final key = '${tap.reminderId}:${tap.action.name}:${reminder.dueAt}';
    final now = DateTime.now();
    _handled.removeWhere((_, at) => now.difference(at).inSeconds >= 10);
    if (_handled.containsKey(key)) return;
    _handled[key] = now;

    switch (tap.action) {
      case NotificationAction.open:
        unawaited(_router.push('/alarm/${reminder.id}'));
      case NotificationAction.done || NotificationAction.snooze:
        await sl<ApplyAlarmAction>()(
          reminder.id,
          tap.action == NotificationAction.done
              ? AlarmAction.done
              : AlarmAction.snooze,
          now,
        );
        await sl<SyncAlarms>()();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<AppSettingsCubit>(),
      child: BlocBuilder<AppSettingsCubit, AppSettings>(
        builder: (context, s) => MaterialApp.router(
          onGenerateTitle: (_) => appName,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // Unsupported device language -> English, same as l10n().
          localeListResolutionCallback: (locales, _) =>
              Locale(deviceLanguage(locales)),
          locale: s.interfaceLocale == 'system'
              ? null
              : Locale(s.interfaceLocale),
          debugShowCheckedModeBanner: false,
          theme: MemoTheme.light,
          darkTheme: MemoTheme.dark,
          themeMode: switch (s.themeMode) {
            'light' => ThemeMode.light,
            'dark' => ThemeMode.dark,
            _ => ThemeMode.system,
          },
          routerConfig: _router,
          builder: (context, child) => ChromeModeScope(
            mode: sl<AppPrefs>().chromeModeOverride == 'solid'
                ? ChromeMode.solid
                : ChromeModeScope.resolve(
                    platform: Theme.of(context).platform,
                    highContrast: MediaQuery.highContrastOf(context),
                    reduceTransparency: _reduceTransparency,
                  ),
            child: child!,
          ),
        ),
      ),
    );
  }
}
