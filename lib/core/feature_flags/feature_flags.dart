abstract class FeatureFlags {
  bool get repeatReminders;
  bool get snooze;
  bool get tags;
  bool get cloudSync; // Phase 2
  bool get sharedReminders; // Phase 2
  bool get locationTrigger; // Phase 3
  bool get voiceInput; // Phase 3
}

/// v1: reads a hardcoded const map. Phase 2 swaps this impl for one backed by
/// remote config — call sites never change.
///
/// ponytail: hardcoded map, not remote config. Add a remote fetch only when a
/// Phase 2 feature actually needs toggling without an app update.
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
  bool get cloudSync => _flags['cloud_sync'] ?? false;
  @override
  bool get sharedReminders => _flags['shared_reminders'] ?? false;
  @override
  bool get locationTrigger => _flags['location_trigger'] ?? false;
  @override
  bool get voiceInput => _flags['voice_input'] ?? false;
}
