import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n.dart';

/// Every shared-preferences key in one place (build spec §4).
class AppPrefs {
  AppPrefs(this._prefs);

  final SharedPreferences _prefs;

  static Future<AppPrefs> open() async {
    final prefs = AppPrefs(await SharedPreferences.getInstance());
    await prefs._seedLocales();
    return prefs;
  }

  /// Once: an existing install keeps English; a fresh one follows the device.
  Future<void> _seedLocales() async {
    if (_prefs.containsKey('interface_locale')) return;
    if (onboardingDone) {
      await setInterfaceLocale('en');
      await setInputLocale('en');
      return;
    }
    await setInterfaceLocale('system');
    await setInputLocale(deviceLanguage());
  }

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

  /// New reminders are read aloud when they ring.
  bool get readAloudDefault => _prefs.getBool('read_aloud_default') ?? true;
  Future<void> setReadAloudDefault(bool value) =>
      _prefs.setBool('read_aloud_default', value);

  /// The app's speaking voice: 'female' or 'male'.
  String get voiceGender => _prefs.getString('voice_gender') ?? 'female';
  Future<void> setVoiceGender(String gender) =>
      _prefs.setString('voice_gender', gender);

  /// The zone repeats were last walled in; a change re-walls them.
  String? get lastTimeZone => _prefs.getString('last_time_zone');
  Future<void> setLastTimeZone(String zone) =>
      _prefs.setString('last_time_zone', zone);

  /// system | en | hi | bn
  String get interfaceLocale => _prefs.getString('interface_locale') ?? 'en';
  Future<void> setInterfaceLocale(String v) =>
      _prefs.setString('interface_locale', v);

  /// en | hi | bn
  String get inputLocale => _prefs.getString('input_locale') ?? 'en';
  Future<void> setInputLocale(String v) => _prefs.setString('input_locale', v);

  /// follow | en | hi | bn
  String get playbackLocale => _prefs.getString('playback_locale') ?? 'follow';
  Future<void> setPlaybackLocale(String v) =>
      _prefs.setString('playback_locale', v);

  /// system | light | dark
  String get themeMode => _prefs.getString('theme_mode') ?? 'system';
  Future<void> setThemeMode(String v) => _prefs.setString('theme_mode', v);

  /// Only 'solid' is honoured in v1.
  String? get chromeModeOverride => _prefs.getString('chrome_mode_override');
}
