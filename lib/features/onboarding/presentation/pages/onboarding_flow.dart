import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/app_prefs.dart';
import '../../../../core/di.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/ui/motion.dart';
import '../../../reminders/data/alarm/native_alarm.dart';
import '../../domain/onboarding_repository.dart';
import '../cubit/onboarding_cubit.dart';
import 'battery_page.dart';
import 'permission_primer_page.dart';
import 'welcome_page.dart';

/// Hosts the two first-run screens and calls [onDone] once the flag is
/// persisted and the notification permission has been asked for.
class OnboardingFlow extends StatelessWidget {
  const OnboardingFlow({super.key, required this.onDone, this.android});

  final VoidCallback onDone;

  /// Null reads the platform; tests force it.
  final bool? android;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingCubit(
        sl<OnboardingRepository>(),
        sl<NativeAlarm>(),
        sl<AppPrefs>(),
        android: android,
      ),
      child: BlocListener<OnboardingCubit, OnboardingState>(
        listener: (context, state) {
          if (state.status == OnboardingStatus.finished) onDone();
        },
        child: const _OnboardingPages(),
      ),
    );
  }
}

class _OnboardingPages extends StatefulWidget {
  const _OnboardingPages();

  @override
  State<_OnboardingPages> createState() => _OnboardingPagesState();
}

class _OnboardingPagesState extends State<_OnboardingPages> {
  final _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    return BlocListener<OnboardingCubit, OnboardingState>(
      listenWhen: (_, s) => s.status == OnboardingStatus.battery,
      listener: (context, _) {
        final d = motion(context, MemoMotion.slow);
        d == Duration.zero
            ? _controller.jumpToPage(2)
            : _controller.nextPage(duration: d, curve: MemoMotion.curve);
      },
      child: PageView(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          WelcomePage(
            onContinue: () {
              final d = motion(context, MemoMotion.slow);
              d == Duration.zero
                  ? _controller.jumpToPage(1)
                  : _controller.nextPage(duration: d, curve: MemoMotion.curve);
            },
            onSkip: cubit.skip,
          ),
          PermissionPrimerPage(
            onContinue: cubit.requestPermissionAndFinish,
            onSkip: cubit.skip,
          ),
          BlocBuilder<OnboardingCubit, OnboardingState>(
            builder: (context, s) => BatteryPage(
              maker: s.maker,
              onOpen: cubit.openBatterySettings,
              onDone: cubit.finishBattery,
              onSkip: cubit.finishBattery,
            ),
          ),
        ],
      ),
    );
  }
}
