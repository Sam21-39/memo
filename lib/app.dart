import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/app_prefs.dart';
import 'core/chrome/chrome_mode.dart';
import 'core/di.dart';
import 'core/theme/memo_theme.dart';
import 'features/onboarding/presentation/pages/onboarding_flow.dart';
import 'features/reminders/data/alarm/local_notification_scheduler.dart';
import 'features/reminders/domain/repositories/reminder_repository.dart';
import 'features/reminders/domain/usecases/complete_reminder.dart';
import 'features/reminders/domain/usecases/delete_reminder.dart';
import 'features/reminders/domain/usecases/save_reminder.dart';
import 'features/reminders/domain/usecases/snooze_reminder.dart';
import 'features/reminders/domain/usecases/sync_alarms.dart';
import 'features/reminders/presentation/archive/archive_cubit.dart';
import 'features/reminders/presentation/archive/archive_page.dart';
import 'features/reminders/presentation/detail/detail_cubit.dart';
import 'features/reminders/presentation/detail/detail_page.dart';
import 'features/reminders/presentation/home/home_cubit.dart';
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
        builder: (_, _) => BlocProvider(
          create: (_) => HomeCubit(
            sl<ReminderRepository>(),
            sl<SaveReminder>(),
            sl<DeleteReminder>(),
          )..load(),
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
          create: (_) => SettingsCubit(sl<AppPrefs>())..refresh(),
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

  @override
  void initState() {
    super.initState();
    final notifications = sl<LocalNotificationScheduler>();
    notifications.onTap = _handleTap;
    // Alarms keep firing and repeats keep rolling while backgrounded; never
    // trust that a request registered yesterday still exists.
    _lifecycle = AppLifecycleListener(onResume: () => sl<SyncAlarms>()());
    sl<SyncAlarms>()();
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

  /// Done and Snooze apply against the DB; a body tap opens the reminder.
  /// The launch-details path and the live callback can both deliver one tap,
  /// and a snooze applied twice is silently 20 minutes, so each
  /// `<id>:<action>:<due_at>` is honoured once per 10 s.
  Future<void> _handleTap(NotificationTap tap) async {
    final reminder = await sl<ReminderRepository>().getById(tap.reminderId);
    if (reminder == null) return;
    final key = '${tap.reminderId}:${tap.action.name}:${reminder.dueAt}';
    final now = DateTime.now();
    _handled.removeWhere((_, at) => now.difference(at).inSeconds >= 10);
    if (_handled.containsKey(key)) return;
    _handled[key] = now;

    final save = sl<SaveReminder>();
    try {
      switch (tap.action) {
        case NotificationAction.open:
          await _router.push('/reminder/${reminder.id}');
          return;
        case NotificationAction.done:
          await save(const CompleteReminder()(reminder, now: now));
        case NotificationAction.snooze:
          await save(
            const SnoozeReminder()(
              reminder,
              now: now,
              by: const Duration(minutes: 10),
            ),
          );
      }
    } finally {
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
                // M1: read UIAccessibility.isReduceTransparencyEnabled.
                reduceTransparency: false,
              ),
        child: child!,
      ),
    );
  }
}
