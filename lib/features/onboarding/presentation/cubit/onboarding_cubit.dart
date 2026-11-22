import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/app_prefs.dart';
import '../../../reminders/data/alarm/native_alarm.dart';
import '../../domain/onboarding_repository.dart';

enum OnboardingStatus { inProgress, battery, finished }

class OnboardingState {
  const OnboardingState(
    this.status, {
    this.notificationsGranted = false,
    this.maker = '',
  });
  final OnboardingStatus status;
  final bool notificationsGranted;

  /// Phone maker, so the battery step can mention autostart lists.
  final String maker;
}

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit(this._repository, this._native, this._prefs, {bool? android})
    : _android = android ?? Platform.isAndroid,
      super(const OnboardingState(OnboardingStatus.inProgress));

  final OnboardingRepository _repository;
  final NativeAlarm _native;
  final AppPrefs _prefs;
  final bool _android;

  Future<void> requestPermissionAndFinish() async {
    final granted = await _repository.requestNotificationPermission();
    if (_android && !_prefs.batteryStepDone) {
      try {
        final battery = await _native.battery();
        if (!battery.unrestricted) {
          emit(
            OnboardingState(
              OnboardingStatus.battery,
              notificationsGranted: granted,
              maker: battery.maker,
            ),
          );
          return;
        }
      } on NativeAlarmError {
        // Cannot tell: do not block first run on it.
      }
    }
    await _repository.complete();
    emit(
      OnboardingState(OnboardingStatus.finished, notificationsGranted: granted),
    );
  }

  /// "Open battery settings" is not here: the user comes back and taps
  /// "I did this" or "Skip".
  Future<void> finishBattery() async {
    await _prefs.setBatteryStepDone();
    await _repository.complete();
    emit(
      OnboardingState(
        OnboardingStatus.finished,
        notificationsGranted: state.notificationsGranted,
      ),
    );
  }

  Future<void> openBatterySettings() async {
    try {
      await _native.openBatterySettings();
    } on NativeAlarmError {
      // Nothing to open; the step stays so the user can skip.
    }
  }

  Future<void> skip() async {
    await _repository.complete();
    emit(const OnboardingState(OnboardingStatus.finished));
  }
}
