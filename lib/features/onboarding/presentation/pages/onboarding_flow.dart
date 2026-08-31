import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../domain/onboarding_repository.dart';
import '../cubit/onboarding_cubit.dart';
import 'permission_primer_page.dart';
import 'welcome_page.dart';

/// Hosts the two first-run screens and calls [onDone] once the flag is
/// persisted and the notification permission has been asked for.
class OnboardingFlow extends StatelessWidget {
  const OnboardingFlow({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingCubit(sl<OnboardingRepository>()),
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
    return PageView(
      controller: _controller,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        WelcomePage(
          onGetStarted: () => _controller.nextPage(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
          ),
        ),
        PermissionPrimerPage(
          onContinue: cubit.requestPermissionAndFinish,
          onSkip: cubit.skip,
        ),
      ],
    );
  }
}
