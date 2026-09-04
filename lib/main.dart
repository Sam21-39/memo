import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart';
import 'core/feature_flags/feature_flags.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/notification_scheduler.dart';
import 'features/onboarding/domain/onboarding_repository.dart';
import 'features/onboarding/presentation/pages/onboarding_flow.dart';
import 'features/reminders/domain/repositories/reminder_repository.dart';
import 'features/reminders/presentation/cubit/reminders_cubit.dart';
import 'features/reminders/presentation/pages/reminder_detail_page.dart';
import 'features/reminders/presentation/pages/reminder_list_page.dart';

/// Lets a notification tap push a route from outside the widget tree.
final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const MemoApp());
}

class MemoApp extends StatelessWidget {
  const MemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RemindersCubit(
        sl<ReminderRepository>(),
        sl<NotificationScheduler>(),
        snoozeEnabled: sl<FeatureFlags>().snooze,
      )..load(),
      child: MaterialApp(
        title: 'memo',
        navigatorKey: navigatorKey,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: const StartupGate(),
      ),
    );
  }
}

/// Routes to onboarding on first run, otherwise straight to the list, and
/// forwards notification taps to the detail page.
class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  late final Future<bool> _completed = sl<OnboardingRepository>().isCompleted();
  bool _onboarded = false;
  late final AppLifecycleListener _lifecycle;

  NotificationTap? _lastTap;
  DateTime? _lastTapAt;

  @override
  void initState() {
    super.initState();
    final scheduler = sl<NotificationScheduler>();
    scheduler.onTap = _handleTap;
    // A tap that cold-started the app is not delivered to onTap.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final launchTap = await scheduler.launchTap();
      if (launchTap != null) _handleTap(launchTap);
    });
    // Alarms keep firing and repeats keep rolling while the app is backgrounded
    // — without this the list is however stale it was when the user left.
    _lifecycle = AppLifecycleListener(
      onResume: () => context.read<RemindersCubit>().load(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  /// The launch-details path and the [NotificationScheduler.onTap] callback are
  /// separate deliveries of the same tap. Today only one of them can fire, but
  /// a snooze applied twice is silently 20 minutes — so make it idempotent
  /// rather than depend on that ordering.
  bool _alreadyHandled(NotificationTap tap) {
    final at = _lastTapAt;
    return at != null &&
        _lastTap?.reminderId == tap.reminderId &&
        _lastTap?.action == tap.action &&
        DateTime.now().difference(at) < const Duration(seconds: 3);
  }

  Future<void> _handleTap(NotificationTap tap) async {
    if (_alreadyHandled(tap)) return;
    _lastTap = tap;
    _lastTapAt = DateTime.now();

    final cubit = context.read<RemindersCubit>();
    final reminder = await cubit.applyNotificationAction(
      tap.reminderId,
      tap.action,
    );
    // Done and Snooze are complete in themselves — only a plain tap navigates.
    if (reminder == null || tap.action != NotificationAction.open) return;

    await navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: ReminderDetailPage(reminderId: reminder.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_onboarded) return const ReminderListPage();
    return FutureBuilder<bool>(
      future: _completed,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: SizedBox.shrink());
        if (snapshot.data!) return const ReminderListPage();
        return OnboardingFlow(onDone: () => setState(() => _onboarded = true));
      },
    );
  }
}
