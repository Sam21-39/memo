/// Gates optional capabilities at the call site, so a flip never touches a
/// screen. Each milestone turns its own flag on once it ships.
abstract class FeatureFlags {
  bool get repeatReminders;
  bool get snooze;
  bool get tags;
  bool get nag; // M3
  bool get preAlarm; // M3
  bool get voiceCapture; // M1 clip, M2 dictation
  bool get imageCapture; // M4
  bool get cloudSync; // Phase 2
  bool get sharedReminders; // Phase 2
}

/// v1: a const map. Phase 2 may back this with remote config; call sites
/// never change.
///
/// ponytail: hardcoded map, not remote config. Add a fetch only when a flag
/// actually needs toggling without an app update.
class RemoteFeatureFlags implements FeatureFlags {
  const RemoteFeatureFlags([this._flags = const {}]);

  final Map<String, bool> _flags;

  @override
  bool get repeatReminders => _flags['repeat_reminders'] ?? true;
  @override
  bool get snooze => _flags['snooze'] ?? true;
  @override
  bool get tags => _flags['tags'] ?? true;
  @override
  bool get nag => _flags['nag'] ?? false;
  @override
  bool get preAlarm => _flags['pre_alarm'] ?? false;
  @override
  bool get voiceCapture => _flags['voice_capture'] ?? true;
  @override
  bool get imageCapture => _flags['image_capture'] ?? false;
  @override
  bool get cloudSync => _flags['cloud_sync'] ?? false;
  @override
  bool get sharedReminders => _flags['shared_reminders'] ?? false;
}
