import 'package:shared_preferences/shared_preferences.dart';

/// Every shared-preferences key in one place (build spec §4).
class AppPrefs {
  AppPrefs(this._prefs);

  final SharedPreferences _prefs;

  static Future<AppPrefs> open() async =>
      AppPrefs(await SharedPreferences.getInstance());

  /// 0.0.1 wrote `onboarding_completed`; honour it so testers are not asked
  /// again after the update.
  bool get onboardingDone =>
      _prefs.getBool('onboarding_done') ??
      _prefs.getBool('onboarding_completed') ??
      false;
  Future<void> setOnboardingDone() => _prefs.setBool('onboarding_done', true);

  bool get batteryStepDone => _prefs.getBool('battery_step_done') ?? false;
  Future<void> setBatteryStepDone() =>
      _prefs.setBool('battery_step_done', true);

  /// Nag interval new reminders start with. Null = off. Owner's default:
  /// every 10 min; stored 0 means the user turned it off.
  int? get defaultNagMin {
    final v = _prefs.getInt('default_nag_min') ?? 10;
    return v == 0 ? null : v;
  }

  Future<void> setDefaultNagMin(int? minutes) =>
      _prefs.setInt('default_nag_min', minutes ?? 0);

  bool get voiceRingsDefault => _prefs.getBool('voice_rings_default') ?? true;
  Future<void> setVoiceRingsDefault(bool value) =>
      _prefs.setBool('voice_rings_default', value);

  /// Only 'solid' is honoured in v1.
  String? get chromeModeOverride => _prefs.getString('chrome_mode_override');
}
