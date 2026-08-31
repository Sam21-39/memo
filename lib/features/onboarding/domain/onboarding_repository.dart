abstract class OnboardingRepository {
  Future<bool> isCompleted();
  Future<void> complete();

  /// Requests the OS notification permission (the "alarm" permission).
  /// Returns true if granted.
  Future<bool> requestNotificationPermission();
}
