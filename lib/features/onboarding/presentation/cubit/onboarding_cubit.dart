import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/onboarding_repository.dart';

enum OnboardingStatus { inProgress, finished }

class OnboardingState {
  const OnboardingState(this.status, {this.notificationsGranted = false});
  final OnboardingStatus status;
  final bool notificationsGranted;
}

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit(this._repository)
    : super(const OnboardingState(OnboardingStatus.inProgress));

  final OnboardingRepository _repository;

  Future<void> requestPermissionAndFinish() async {
    final granted = await _repository.requestNotificationPermission();
    await _repository.complete();
    emit(
      OnboardingState(OnboardingStatus.finished, notificationsGranted: granted),
    );
  }

  Future<void> skip() async {
    await _repository.complete();
    emit(const OnboardingState(OnboardingStatus.finished));
  }
}
