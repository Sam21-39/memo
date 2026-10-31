import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/app_prefs.dart';
import 'core/chrome/chrome_mode.dart';
import 'core/di.dart';
import 'core/theme/memo_theme.dart';
import 'features/onboarding/presentation/pages/onboarding_flow.dart';
import 'features/reminders/data/alarm/local_notification_scheduler.dart';
import 'features/reminders/data/alarm/native_alarm.dart';
import 'features/reminders/data/media_store.dart';
import 'features/reminders/data/speech_to_text.dart';
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
import 'features/settings/settings_cubit.dart';
import 'features/settings/settings_page.dart';

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
                defaultNagMin: sl<AppPrefs>().defaultNagMin,
                voiceRingsDefault: sl<AppPrefs>().voiceRingsDefault,
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
          create: (_) =>
              SettingsCubit(sl<AppPrefs>(), sl<NativeAlarm>())..refresh(),
          child: const SettingsPage(),
        ),
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
        final reduce = await native.reduceTransparency();
        if (mounted && reduce != _reduceTransparency) {
          setState(() => _reduceTransparency = reduce);
        }
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
    return MaterialApp.router(
      title: 'Memō',
      debugShowCheckedModeBanner: false,
      theme: MemoTheme.light,
      darkTheme: MemoTheme.dark,
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
    );
  }
}
