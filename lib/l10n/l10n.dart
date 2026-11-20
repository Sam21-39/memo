import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:intl/number_symbols.dart';
import 'package:intl/number_symbols_data.dart';

import '../core/app_prefs.dart';
import '../core/di.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

const appName = 'Memō';
const supportedLanguages = ['en', 'hi', 'bn'];
const endonyms = {'en': 'English', 'hi': 'हिन्दी', 'bn': 'বাংলা'};

/// The first device locale Memō supports, else English.
String deviceLanguage([List<Locale>? locales]) {
  for (final l in locales ?? PlatformDispatcher.instance.locales) {
    if (supportedLanguages.contains(l.languageCode)) return l.languageCode;
  }
  return 'en';
}

/// The interface language code in force: the pref, else the device's.
String interfaceLanguage() {
  final pref = sl.isRegistered<AppPrefs>()
      ? sl<AppPrefs>().interfaceLocale
      : 'en';
  return pref == 'system' ? deviceLanguage() : pref;
}

/// For cubits, schedulers and the iOS background isolate (no BuildContext).
AppLocalizations l10n([String? language]) =>
    lookupAppLocalizations(Locale(language ?? interfaceLanguage()));

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Digits stay 0-9 in every language. Must run before any DateFormat,
/// NumberFormat or localisation delegate is created.
void useWesternDigits() {
  DateFormat.useNativeDigitsByDefaultFor('bn', false);
  final bn = numberFormatSymbols['bn'] as NumberSymbols;
  numberFormatSymbols['bn'] = NumberSymbols(
    NAME: bn.NAME,
    DECIMAL_SEP: bn.DECIMAL_SEP,
    GROUP_SEP: bn.GROUP_SEP,
    PERCENT: bn.PERCENT,
    ZERO_DIGIT: '0',
    PLUS_SIGN: bn.PLUS_SIGN,
    MINUS_SIGN: bn.MINUS_SIGN,
    EXP_SYMBOL: bn.EXP_SYMBOL,
    PERMILL: bn.PERMILL,
    INFINITY: bn.INFINITY,
    NAN: bn.NAN,
    DECIMAL_PATTERN: bn.DECIMAL_PATTERN,
    SCIENTIFIC_PATTERN: bn.SCIENTIFIC_PATTERN,
    PERCENT_PATTERN: bn.PERCENT_PATTERN,
    CURRENCY_PATTERN: bn.CURRENCY_PATTERN,
    DEF_CURRENCY_CODE: bn.DEF_CURRENCY_CODE,
  );
}
