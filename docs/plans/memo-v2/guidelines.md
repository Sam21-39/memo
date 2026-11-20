# Memō v2 — implementation guidelines

Read `prd.md` first. One phase = one branch off `dev` = one PR. Do the steps in order. Do not start a phase whose "Depends on" is not merged. Kotlin
lives in `android/app/src/main/kotlin/in/appamania/memo/` (package line is ``package `in`.appamania.memo``).

## 0. Rules for every phase

Hard rules
- Do not touch: `AlarmIds`, `fire_plan.dart`, `repeat_rule.dart`, existing DB migrations, the meaning of existing native entry fields (`id, at,
  repeat, kind, group, reminderId, title, body, speech, sound, snoozeId`). New native fields are optional with an English fallback.
- Reuse before writing: `showMemoSheet`, `SheetHeading`, `SectionCard`, `KeyValueRow`, `PillValue`, `DaySectionHeader`, `MemoToast`, `MemoLoader`,
  `EmptyRing`, `MemoChrome`, `MemoIconButton`, `pickDate` / `pickTime`, `showMemoDialog`, `HoldRecorder`, `MinuteClock`, `SnoozeReminder`,
  `CompleteReminder`, `SaveReminder`. Grep before adding a widget.
- No colour literal outside `lib/core/theme/tokens.dart`. No user-visible literal outside ARB.
- State changes go through Cubits. `StatefulBuilder` inside an existing sheet may stay.
- Motion: only `MemoMotion.fast/base/slow` + `MemoMotion.curve`; every animated widget reads `MediaQuery.disableAnimationsOf(context)` and uses
  `Duration.zero` when true. Nothing bounces.
- Mic invariant (real bug once): the mic `Listener` stays in the same tree slot from idle through recording. Never wrap it in a widget that appears
  only while recording.
- STT/TTS: on-device only. Never add a network recogniser or network voice path.
- Commit messages and code comments in normal prose. Mark deliberate ceilings with `// ponytail:`.

Shared verify (run all, every phase)
```
fvm dart format --output=none --set-exit-if-changed .
fvm flutter analyze
fvm dart run tool/gen_tokens.dart --check
! grep -rn 'Color(0x' lib | grep -v lib/core/theme/tokens.dart
fvm flutter test
JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home fvm flutter build apk --debug
```
From V1 on also: `fvm flutter gen-l10n && git diff --exit-code lib/l10n`.

Design → Flutter map (extend these, do not duplicate)

| Design component | Flutter | Phase |
|---|---|---|
| FloatingBar | `core/chrome/memo_chrome.dart` `MemoChrome` | — |
| Sheet | `core/ui/memo_sheet.dart` `showMemoSheet` (made solid in V0) | V0 |
| Dialog | `core/ui/memo_dialog.dart` | — |
| Toast | `core/ui/memo_toast.dart` `MemoToast` (action becomes optional in V2) | V2 |
| CaptureBar | `presentation/home/capture_bar.dart` | V2 |
| VoiceCaptureButton | `_Mic` in `capture_bar.dart`, `_HoldToRecord` in `edit_sheet.dart` | V2 |
| RecordingIndicator | new `presentation/voice/recording_panel.dart` | V2 |
| DateTimeChip | `_Chip` in `capture_bar.dart` + new `UnsureTimeBlock` | V2 |
| ReminderConfirmation | new `presentation/home/reminder_confirmation.dart` | V2 |
| AlarmOverlay | `presentation/alarm/alarm_page.dart` | V3 |
| AlarmActionButton | `ElevatedButton` / `OutlinedButton` with `MemoButtons.large` | V3 |
| ReminderRow | `widgets/reminder_row.dart`, `widgets/swipeable_reminder_row.dart` | V4 |
| LanguageSelector | new `core/ui/memo_radio_list.dart` `MemoRadioList<T>` | V1 |
| PermissionStatusRow | new `features/settings/permission_status_row.dart` | V5 |
| EscalationSelector | not built | — |

---------------------------------------------------------------------------------------------------
## V0 — Tokens, fonts, contrast

Owner first: font files (Owner steps 1).

### V0.1 `design/tokens.json`
Add to `color.tokens` (after `accent`, and at the end):
```
{"name": "accent-text", "value": {"light": "#c2363c", "dark": "#ff7e82"}, "usage": "Accent as text or icon ground: overdue times, text buttons, links, mic and recording fill with white icon. 4.7:1 on canvas."},
{"name": "caution", "value": {"light": "#b26a00", "dark": "#e0a040"}, "usage": "Needs your decision: the Confirm time border and badge, health warnings. Never for overdue or delete."},
{"name": "caution-soft", "value": {"light": "#fff4e5", "dark": "#2e2412"}, "usage": "Ground behind an unsure field and warning pills."},
{"name": "ok", "value": {"light": "#2e7d4f", "dark": "#7cc79a"}, "usage": "Alarm health only: allowed, ready."}
```
Change usage text: `ink-45` → "Idle check ring, hairline-weight icons, decorative strokes only. Never text: 2.95:1 on canvas. Labels and placeholders
use ink-70."; `accent` → "The logo dot. Done disc, overdue ring, complete band, large non-text marks. Never small text (3.05:1); use accent-text.";
`label-small` usage → append "Latin only: Hindi and Bengali headers use body 13/500 sentence case, no tracking." `type.families.sans` → `"\"Instrument
Sans\", \"Noto Sans Devanagari\", \"Noto Sans Bengali\", system-ui, -apple-system, sans-serif"`. Add to the sans group styles:
```
{"name": "alarm-title", "fontSize": "40px", "lineHeight": "46px", "fontWeight": 600, "letterSpacing": "-0.8px", "sample": "Take medicine", "usage": "Reminder title on the alarm screen only."},
{"name": "button-large", "fontSize": "20px", "lineHeight": "20px", "fontWeight": 600, "sample": "Done", "usage": "Alarm Done and Snooze, 64 px high."}
```

### V0.2 `tool/gen_tokens.dart`
- `_type`: after the `mono` line write `static const fallback = ['Noto Sans Devanagari', 'Noto Sans Bengali'];` and in every style, after
  `fontFamily:`, write `fontFamilyFallback: fallback,`.
- `_fixed` `MemoMotion`: no change. Run `fvm dart run tool/gen_tokens.dart`; commit `tokens.dart`. Colours `accentText`, `caution`, `cautionSoft`,
  `ok` and styles `alarmTitle`, `buttonLarge` appear by themselves (the generator loops).

### V0.3 `pubspec.yaml`
Add families `Noto Sans Devanagari` and `Noto Sans Bengali`, weights 400/500/600, files
`assets/fonts/NotoSansDevanagari-{Regular,Medium,SemiBold}.ttf`, `assets/fonts/NotoSansBengali-{...}.ttf`. Add `assets: [assets/fonts/OFL-Noto.txt]`.
`lib/main.dart` before `runApp`: `LicenseRegistry.addLicense(() async* { yield LicenseEntryWithLineBreaks(['Noto Sans'], await
rootBundle.loadString('assets/fonts/OFL-Noto.txt')); });`

### V0.4 `lib/core/theme/memo_theme.dart`
- `ThemeData(fontFamilyFallback: MemoType.fallback, …)`.
- `labelSmall` colour `ink45 → ink70`; `inputDecorationTheme.hintStyle` `ink45 → ink70`; `textButtonTheme.foregroundColor` `accent → accentText`;
  `textSelectionTheme.cursorColor` → `accentText`.
- Add `abstract final class MemoButtons { static ButtonStyle large(MemoColors c) … }` returning a style with `minimumSize: Size.fromHeight(64)`,
  `textStyle: MemoType.buttonLarge`, `shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))` → use `MemoRadius.card + 2`; no new
  literal colour. Used by V3.

### V0.5 Contrast sweep (exact sites; re-run the two greps after)
`ink45 → ink70` where it colours text or a meaningful icon: `core/ui/memo_mark.dart:67` (the "00" text; the ring border at :63 stays),
`home/capture_bar.dart:228` (hint), `home/home_page.dart:202`, `archive/archive_page.dart:69`, `widgets/day_section_header.dart:25`,
`widgets/reminder_row.dart:65,67` (done title and its strike colour), `widgets/reminder_row.dart:100` (repeat glyph), `edit/edit_sheet.dart:305`
(close icon).
Keep `ink45` for: grabber, loader track, dashed chip borders, focused input border, idle check ring.
`accent → accentText` where it is
text, an icon on paper, or the mic fill: `core/ui/minutes_sheet.dart:90`, `home/capture_bar.dart:181` (timer) and `_Mic` fill (`active ?
c.accentPressed : c.accentText`), `edit/edit_sheet.dart:320` and `_HoldToRecord` fill, `alarm/alarm_page.dart:82`,
`widgets/day_section_header.dart:25` (overdue header), `widgets/reminder_row.dart` overdue trailing time, `core/ui/memo_nav_bar.dart` back/action text
if it uses `accent`.
Keep `accent` for: check disc and dashed overdue ring, complete band, loader arc, logo dot, alarm play button ground → change
that ground to `accentText` (white icon on it).
Greps: `grep -rn "ink45" lib | grep -v theme/tokens.dart` and `grep -rn "c\.accent\b" lib` — every
remaining hit must be a stroke, ring, disc or band.

### V0.6 Section label rule — new `lib/core/ui/section_label.dart`
```dart
/// label-small is uppercase and tracked for Latin only; Devanagari and Bengali
/// have no case and tracking breaks conjuncts.
bool _latin(BuildContext c) => Localizations.localeOf(c).languageCode == 'en';
String sectionLabelText(BuildContext c, String s) => _latin(c) ? s.toUpperCase() : s;
TextStyle sectionLabelStyle(BuildContext c) => _latin(c)
    ? MemoType.labelSmall
    : MemoType.body.copyWith(fontSize: 13, fontWeight: FontWeight.w500, height: 18 / 13);
```
Replace the three `toUpperCase()` + `MemoType.labelSmall` pairs (`home_page.dart:201`, `archive_page.dart:68`, `day_section_header.dart:37`) with
these two calls. Caller keeps `.copyWith(color:)`.

### V0.7 Sheets are solid
`core/ui/memo_sheet.dart`: `MemoChrome(shape: ChromeShape.sheet, solid: true, …)` (design principle 5; glass stays on the floating bar only).

### V0.8 Tests — `test/tokens_test.dart`
- `MemoType.body.fontFamilyFallback` and `MemoType.labelMedium.fontFamilyFallback` equal `MemoType.fallback`.
- The six Noto files and `OFL-Noto.txt` exist (`File(...).existsSync()`).
- `MemoColors.light.accentText`, `.caution`, `.cautionSoft`, `.ok` are non-null and differ from `accent`.
- Pump `DaySectionHeader(label: 'Today')`: text is `TODAY` (the `en` branch). V1.9 adds the `hi` case (sentence case, 13/500, no letter spacing) once
  the delegates exist.

Verify V0: shared verify. Visual check on device: mic and "Save" are the darker red.

---------------------------------------------------------------------------------------------------
## V1 — Localisation infrastructure

### V1.1 Dependencies and config
`pubspec.yaml` dependencies (exact pins, same style as the others):
```
  flutter_localizations:
    sdk: flutter
  intl: 0.20.3
```
Under `flutter:` add `generate: true`. New `l10n.yaml`:
```
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
nullable-getter: false
format: true
```
Generated `lib/l10n/app_localizations*.dart` is committed.

### V1.2 ARB files — mechanical migration from `S`
Create `lib/l10n/app_en.arb`, `app_hi.arb`, `app_bn.arb` (`"@@locale"` set). Rules:
1. Key = `S` member name, unchanged (`S.commonDone` → `"commonDone": "Done"`).
2. A function becomes a message with placeholders named like its parameters: `S.homeDeleted(title)` → `"homeDeleted": "{title} deleted"` +
   `"@homeDeleted": {"placeholders": {"title": {"type": "String"}}}`. `int` placeholders: `"type": "int"` and **no** `format` (keeps 0-9).
3. Descriptions (`"description"`) only in `app_en.arb`, one line each, saying where it shows.
4. Not migrated 1:1 (replace as listed):
   - `appName` → stays Dart: `const appName = 'Memō';` in `lib/l10n/l10n.dart` (brand, never translated).
   - `weekdaysShort`, `monthsShort`, `dateShort`, `dateLong`, `dayAtTime` → deleted; `intl` (V1.6).
   - `lateMinutes` → `{count, plural, =1{1 min late} other{{count} min late}}`; `lateHours` → `{count} h late`; `lateDays` → `{count} d late` (design
     writes "2 h late" with a space).
   - `homeSummary(scheduled, overdue)` → two keys: `homeScheduled` = `{count} scheduled`, `homeScheduledOverdue` = `{scheduled} scheduled · {overdue}
     overdue`.
   - `everyMinutes` → `{minutes, plural, =1{Every minute} other{Every {minutes} min}}`.
   - `alarmClip(length, playing)` → `clipNote` (exists) and `clipNotePlaying` = `{length} · your note · playing`.
   - `spokenReminder(title, note)` → `spokenReminder` = `Reminder. {title}.` and `spokenReminderNote` = `Reminder. {title}. {note}.`
   - `captureEveryDay(day)` → `repeatEveryDay` = `Every {day}` (day comes from `intl`).
   - Delete with no replacement: `settingsPhase2`, `settingsCloudSync`, `settingsShared`, `settingsSoon` (their rows go in V5; until then keep the
     keys, delete them in V5).
5. hi/bn values: natural everyday Hindi/Bengali, Western digits, brand stays "Memō". Use the design copy below verbatim where a key matches; draft the
   rest; put `"@@x-review": "pending"` at the top of both files (removed in V9 after native review).

Design-provided copy (key → hi · bn): settingsTitle सेटिंग्स · সেটিংস — dateToday आज · আজ — dateTomorrow कल · কাল — homeOverdue देर हो गई · দেরি হয়ে
গেছে — homeScheduledOverdue `{scheduled} बाकी · {overdue} देर से` · `{scheduled}টি বাকি · {overdue}টি দেরিতে` — lateHours `{count} घंटे देर` ·
`{count} ঘণ্টা দেরি` — lateMinutes `{count} मिनट देर` · `{count} মিনিট দেরি` — reminderHint मुझे याद दिलाना… · মনে করিয়ে দাও… — fieldWhen कब · কখন —
fieldRepeat दोहराना · পুনরাবৃত্তি — repeatNone नहीं · নেই — repeatDaily रोज़ · প্রতিদিন — alarmReminder रिमाइंडर · রিমাইন্ডার — commonDone हो गया ·
হয়ে গেছে. Later-phase keys with design copy are listed in their phase.

### V1.3 `lib/l10n/l10n.dart` (new)
```dart
export 'app_localizations.dart';
const appName = 'Memō';
const supportedLanguages = ['en', 'hi', 'bn'];
const endonyms = {'en': 'English', 'hi': 'हिन्दी', 'bn': 'বাংলা'};

/// The interface language code in force: the pref, else the first device
/// locale Memō supports, else English.
String interfaceLanguage() {
  final pref = sl.isRegistered<AppPrefs>() ? sl<AppPrefs>().interfaceLocale : 'en';
  if (pref != 'system') return pref;
  for (final l in PlatformDispatcher.instance.locales) {
    if (supportedLanguages.contains(l.languageCode)) return l.languageCode;
  }
  return 'en';
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
  final bn = numberFormatSymbols['bn']!;
  numberFormatSymbols['bn'] = NumberSymbols(NAME: bn.NAME, …every field copied…, ZERO_DIGIT: '0');
}
```
`numberFormatSymbols` is a mutable top-level map in `package:intl/number_symbols_data.dart` (verified in intl 0.20.3); `NumberSymbols` has no
`copyWith`, so list every constructor field. Call `useWesternDigits()` as the first line of `configureDependencies()` (`lib/core/di.dart`), which also
covers the iOS background isolate.

### V1.4 `lib/core/app_prefs.dart`
```dart
String get interfaceLocale => _prefs.getString('interface_locale') ?? 'en';   // system|en|hi|bn
String get inputLocale => _prefs.getString('input_locale') ?? 'en';           // en|hi|bn
String get playbackLocale => _prefs.getString('playback_locale') ?? 'follow'; // follow|en|hi|bn
String get themeMode => _prefs.getString('theme_mode') ?? 'system';           // system|light|dark
Future<void> setInterfaceLocale(String v) / setInputLocale / setPlaybackLocale / setThemeMode
```
Seeding, in `AppPrefs.open()` after construction, once (guard: key `interface_locale` absent):
- `onboardingDone` true (existing install) → write `interface_locale = 'en'`, `input_locale = 'en'`.
- else (fresh install) → write `interface_locale = 'system'`; `input_locale` = first device locale language in `{en, hi, bn}`, else `en`.
`playback_locale` is not written (default `follow`). Test both branches with `SharedPreferences.setMockInitialValues`.

### V1.5 `lib/core/app_settings_cubit.dart` (new) and app root
```dart
class AppSettings { const AppSettings({required this.interfaceLocale, required this.inputLocale,
    required this.playbackLocale, required this.themeMode}); … }
class AppSettingsCubit extends Cubit<AppSettings> {
  AppSettingsCubit(this._prefs, {this.onLanguageChanged}) : super(/* read all four from prefs */);
  final Future<void> Function()? onLanguageChanged; // V7/V8 pass SyncAlarms
  Future<void> setInterfaceLocale(String v) async { await _prefs.setInterfaceLocale(v); emit(…); await onLanguageChanged?.call(); }
  Future<void> setInputLocale(String v) …      // no resync
  Future<void> setPlaybackLocale(String v) …   // resync
  Future<void> setThemeMode(String v) …
}
```
- `di.dart`: `sl.registerSingleton(AppSettingsCubit(prefs))` (after `AppPrefs`).
- `app.dart` `build`: wrap in `BlocProvider.value(value: sl<AppSettingsCubit>(), child: BlocBuilder<AppSettingsCubit, AppSettings>(builder: …))`.
  `MaterialApp.router(`: remove `title:`; add `onGenerateTitle: (_) => appName`, `localizationsDelegates: AppLocalizations.localizationsDelegates`,
  `supportedLocales: AppLocalizations.supportedLocales`, `locale: s.interfaceLocale == 'system' ? null : Locale(s.interfaceLocale)`, `themeMode:
  switch (s.themeMode) {'light' => ThemeMode.light, 'dark' => ThemeMode.dark, _ => ThemeMode.system}`.
- `test/fakes.dart` `themed()` and the second `MaterialApp` in `test/home_page_test.dart` (~line 223): add the two l10n parameters. Tests keep English
  expectations.

### V1.6 `lib/core/utils/date_format.dart` rewrite (every function takes `BuildContext c` first)
```dart
String _lang(BuildContext c) => Localizations.localeOf(c).languageCode;
/// Latin digits and AM/PM in every language; the device decides 12 or 24 hours.
String formatTime(BuildContext c, DateTime t) =>
    DateFormat(MediaQuery.alwaysUse24HourFormatOf(c) ? 'HH:mm' : 'h:mm a', 'en').format(t);
String formatDate(BuildContext c, DateTime d) => DateFormat('EEE d MMM', _lang(c)).format(d);
String formatLongDate(BuildContext c, DateTime d) => DateFormat('d MMM y', _lang(c)).format(d);
String weekdayShort(BuildContext c, int weekday) =>
    DateFormat.E(_lang(c)).format(DateTime(2024, 1, weekday)); // 1 Jan 2024 is a Monday
```
`dayHeaderLabel(c, day, now)`: `c.l10n.dateToday / dateTomorrow / dateYesterday`, else `formatDate`. `formatWhen(c, at, now)`: new ARB `whenDayTime` =
`{day} · {time}` (design separator), day = `dayHeaderLabel`. `formatLateness(c, late)`: `lateDays / lateHours / lateMinutes(n.clamp(1, 59))`. Keep
`two()` and `isSameDay()`. Callers (15 call sites): `alarm_page`, `archive_page`, `detail_page`, `edit_sheet`, `capture_bar`, `capture_sheets`,
`home_page` — pass `context`. English output changes on purpose: 12h devices now show "8:30 PM"; `formatWhen` gains " · ".
`core/ui/memo_pickers.dart`: delete the `alwaysUse24HourFormat: true` `MediaQuery` builder; Cupertino `use24hFormat:
MediaQuery.alwaysUse24HourFormatOf(context)`. `core/ui/minutes_sheet.dart`: `nagLabel(AppLocalizations l, int m)`, `preAlarmLabel(AppLocalizations l,
int m)`; callers pass `context.l10n` (`label: (m) => nagLabel(context.l10n, m)`).

### V1.7 Replace `S` (one commit per group; then delete `lib/l10n/strings.dart`)
Groups: (1) `core/ui/*`, `app.dart`; (2) onboarding pages; (3) `home/*`; (4) `edit/*`; (5) `detail/*`, `alarm/*`, `archive/*`; (6) `widgets/*`,
`voice/hold_recorder.dart`; (7) `settings/*`; (8) `data/*` (`spoken_reminder`, `android_alarm_scheduler`, `local_notification_scheduler`). Rules:
- Widgets: `S.x` → `context.l10n.x` (or a local `final l = context.l10n;`). Remove `const` where needed.
- Cubits, `HoldRecorder`, schedulers: `S.x` → `l10n().x`.
- `SnoozePreset.label` (until V3 deletes it): `String Function(AppLocalizations)`.
- `RepeatSegmentedControl` static labels → built in `build()`.
- Weekday names (`capture_bar.dart _Chips._repeat`, `detail_page.dart _repeatLabel`, `weekday_selector.dart`) → `weekdayShort(context, d)`. Move the
  two duplicate repeat-label functions into one: new `presentation/repeat_label.dart` `String repeatLabel(BuildContext c, RepeatRule r, {required
  String none})` (logic of `_Chips._repeat`).
- `SpokenReminder.textFor` → `l10n('en').spokenReminder(...)` / `spokenReminderNote(...)`: speech stays English until V7, on purpose. Leave a `// V7:
  language comes from the speech plan` note.
- `home_page.dart` brand `Text('Memō')` → `Text(appName)`.

### V1.8 App language picker
- New `lib/core/ui/memo_radio_list.dart`: `class MemoRadioList<T> extends StatelessWidget { options: List<MemoRadioOption<T>>, value: T, onChanged:
  ValueChanged<T> }`, `MemoRadioOption(value, title, {hint, enabled = true})`. A `SectionCard` of rows: 22 px ring (1.5 px `ink70` border; selected:
  `ink` border + 12 px `ink` dot), title `bodyLarge` w400, hint 13/18 `ink70`. Each row `Semantics(inMutuallyExclusiveGroup: true, checked: selected,
  button: true)`, min height 52, whole row tappable.
- New `lib/features/settings/language_page.dart` `LanguagePage`: `MemoNavBar`, title (`MemoType.title`) `languageTitle`, section `settingsAppLanguage`
  with options `system` (title `languageSystem`, hint = endonym of the resolved device language), `en` "English", `hi` "हिन्दी" (hint
  `languageHindi`), `bn` "বাংলা" (hint `languageBengali`). `onChanged: context.read<AppSettingsCubit>().setInterfaceLocale`. The page watches
  `AppSettingsCubit` (`BlocBuilder`).
- Route `/settings/language` in `app.dart`. In the current `settings_page.dart` add, as the first section, `DaySectionHeader(settingsLanguageVoice)` +
  `KeyValueRow(label: settingsAppLanguage, onTap: push, child: PillValue(<endonym or languageSystem>))`. (V5 rebuilds the page around it.)
- New keys: `languageTitle` Language · `settingsLanguageVoice` Language and voice · `settingsAppLanguage` App language · `languageSystem` System
  default · `languageHindi` Hindi · `languageBengali` Bengali · `whenDayTime`.

### V1.9 Tests
- Delete `test/strings_test.dart`. New `test/l10n_test.dart`:
  1. Key parity: load the three ARB files (`dart:io` + `jsonDecode`); every non-`@` key of `en` exists in `hi` and `bn`, no extras; for every
     `@key.placeholders` each `{name}` appears in all three values.
  2. Guard (port of the old test): scan `lib/` for `(?:Text\(|hintText:|label:|tooltip:)\s*['"]…`; allowed only: interpolation-only or glyph-only
     strings. Skip `lib/l10n/` and `tokens.dart`.
  3. Digits: `useWesternDigits()`; pump `MaterialApp(locale: Locale('bn'), delegates…)`; assert `formatDate`, `formatLongDate`,
     `MaterialLocalizations.of(c).formatDecimal(2026)` and `formatTime` contain no char in `[০-৯०-९]`; same for `hi`.
  4. `formatTime`: 20:05 under `MediaQueryData(alwaysUse24HourFormat: false)` → `8:05 PM` in en/hi/bn; true → `20:05`.
  5. `formatLateness`, `nagLabel`, `preAlarmLabel` (port the old expectations: `1 min late`, `2 h late`, `3 d late`, `Every minute`, `Every 59 min`,
     `2 h before`).
- `test/app_settings_cubit_test.dart`: setters persist and emit; seeding (V1.4).
- Widget test: pump `LanguagePage` inside the app shell, tap "हिन्दी", expect `find.text('सेटिंग्स')` on a `Text(context.l10n.settingsTitle)` sibling
  without restarting.
- `DaySectionHeader` under `Locale('hi')`: not uppercased, `letterSpacing` null, size 13.

Verify V1: shared verify + gen-l10n check + `! grep -rn "l10n/strings.dart\|\bS\.[a-z]" lib test`.

---------------------------------------------------------------------------------------------------
## V2 — Capture, confirmation, tap-to-record

### V2.1 Parser: expose ambiguity (English only here) — `domain/parser/reminder_parser.dart`
```dart
enum AmbiguityKind { amPm, noTime, dayWord }   // dayWord is produced from V6 on
class TimeAmbiguity {
  const TimeAmbiguity(this.kinds, this.choices, {this.span});
  final Set<AmbiguityKind> kinds;
  final List<DateTime> choices;   // complete date-times, soonest first, all in the future
  final SourceSpan? span;         // the words that were unclear, for the reason line
}
```
`ParsedReminder` gains `final TimeAmbiguity? ambiguity;` (default null). In "Combine": when `ambiguous` is true, build `choices` from the same
`candidates` list (each rolled forward one day while not after `now` and `day == null`), sorted; `span` = the span added for that clock match (keep it
in a local `SourceSpan? clockSpan`). `dueAt` stays exactly what it is today. When `guessed` is true: `TimeAmbiguity({AmbiguityKind.noTime}, [due])`.
Also (span safety, no behaviour change for ASCII): replace `var work = input.toLowerCase();` with `var work = input.replaceAllMapped(RegExp('[A-Z]'),
(m) => m[0]!.toLowerCase());`, and in `_title` replace `t[0].toUpperCase() + t.substring(1)` with an upper-casing of the first code unit only when it
is `a-z`. Tests (append to `test/reminder_parser_test.dart`, existing cases untouched): "call mum tomorrow at 8" → `kinds == {amPm}`, choices
`[tomorrow 08:00, tomorrow 20:00]`, span text "at 8"; "pay rent" → `{noTime}`; "pills at 8pm" → `ambiguity == null`; "at 8 tonight" → null; "İstanbul
at 8pm" → spans still index the original string.

### V2.2 `HoldRecorder` — tap, hold, cancel, level (`presentation/voice/hold_recorder.dart`, `data/voice_clip.dart`)
- `VoiceClip`: `Future<double> level()` → `(await _recorder.getAmplitude()).current` mapped from dBFS `[-45, 0]` to `[0, 1]`, clamped; `0` on error.
- `HoldDropped.notice` becomes `String?` (null = say nothing).
- `HoldRecorder`: `static const tapThreshold = Duration(milliseconds: 300);` fields `DateTime? _downAt; bool _latched = false;` getter `latched`.
  `onTick` signature becomes `void Function(Duration elapsed, double level)`.
  - `press()`: if `_recording && _latched` → `await _finish(); return;` (second tap stops). Else as today, with `_downAt = DateTime.now()`. After
    `start`: `if (!_holding && !_latched) { cancel; drop }`. The ticker calls `onTick(_clock.elapsed, await _voice.level())` and, at the cap,
    `_finish()`.
  - `release()`: `final quick = _downAt != null && DateTime.now().difference(_downAt!) < tapThreshold;` `_holding = false; if (quick) { _latched =
    true; return; }` `if (!_recording || _latched) return; await _finish();` (a quick release that lands before `start` returns sets `_latched`, so
    the start is kept).
  - `_finish()`: today's stop logic (min length → `HoldDropped(l10n().holdHint)`, else `HoldKept`); resets `_latched`.
  - `cancel()`: stop ticker, `_voice.cancel()`, reset flags, `onResult(const HoldDropped(null))`.
  - `toggle()` (screen readers): `_recording ? _finish() : (_latched = true, press())`.
- Tests in `test/hold_to_record_test.dart` (existing hold tests stay green): quick down/up keeps recording and a second tap yields `HoldKept`;
  `cancel()` yields `HoldDropped(null)` and no file; 30 s cap in latched mode yields `HoldKept`.

### V2.3 `CaptureCubit` / `CaptureState` (`presentation/home/capture_cubit.dart`)
- `enum CapturePhase { idle, typing, recording, transcribing, voiceFailed, confirming, saving }`.
- New state fields: `bool spoken` (text came from speech), `bool latched`, `double level`, `VoiceFailure? failure` (`enum VoiceFailure { unavailable,
  empty, cancelled }`), `bool micDenied`, `Reminder? saved` (set for one emit after a successful save).
- Getters: `TimeAmbiguity? get unsure => dueOverride == null ? parsed?.ambiguity : null;` `bool get canContinue => phase == typing &&
  (title.isNotEmpty || hasClip);` `bool get canSave => phase == confirming && unsure == null && (title.isNotEmpty || hasClip);` Delete `timeGuessed`
  (its only reader, the dashed chip, now reads `unsure != null`).
- Methods: `review()` (typing → confirming, only when `canContinue`); `backToTyping()`; `chooseTime(DateTime at)` = `setDueAt`; `toggleRecording()` →
  `_hold?.toggle()`; `cancelRecording()` → `_hold?.cancel()`; `typeInstead()` (voiceFailed → typing, clip kept); `saveAsVoiceNote()` (voiceFailed →
  confirming; title falls back to `voiceNoteTitle`; `parsed` is `parseReminder('', …)` so `unsure` is `noTime` and a time must be picked);
  `tryAgain()` (discard draft, then `toggleRecording()`).
- `onTick`: also store `level` and `latched`.
- `_onHold`: `HoldDropped(null)` → back to idle/typing silently; `denied` → `micDenied: true` + error. `HoldKept` → `transcribing`; transcript
  non-empty and field empty → `setText(transcript)`, `spoken: true`, phase `confirming`; field already has text → `typing` (typed words win, as
  today); transcript empty → `voiceFailed` with `failure: (await stt?.available() ?? false) ? VoiceFailure.empty : VoiceFailure.unavailable`. Delete
  the `captureVoiceSaved` notice path and its ARB key.
- `cancelTranscription()` → `voiceFailed` with `VoiceFailure.cancelled` (clip kept).
- `save()`: guard `canSave`; on success `emit(CaptureState(readAloud: readAloudDefault(), saved: reminder, error: error))`. `draft()` in
  `saveAsVoiceNote` mode must not invent a time: it uses `state.dueAt!` (guaranteed by `canSave`).
- Update `test/capture_cubit_test.dart`: save now needs `review()` first; add: ambiguous text → `canSave` false until `chooseTime`; empty transcript →
  `voiceFailed`; `typeInstead` keeps `hasClip`; `saveAsVoiceNote` requires a time; `saved` is set once.

### V2.4 Capture bar (`presentation/home/capture_bar.dart`)
- Idle row: field, camera (flag), mic. Under the chrome, when `phase == idle`: `Text(l.captureHintLine)` 13/18 `ink70`, centred, inside the same fade.
- Bar row: `ConstrainedBox(constraints: BoxConstraints(minHeight: MemoSpace.barHeight))` instead of `SizedBox(height:)`.
- Typing panel (solid, as today) top to bottom: visible label `reminderHint` (13 `ink70`), the field, chips, full-width
  `ElevatedButton(l.commonContinue)` enabled by `canContinue` → `cubit.review()`. `onSubmitted` → `cubit.review()`. Remove the trailing "Save" text
  button.
- `_Chips`: exactly Date chip (`dayHeaderLabel`), Time chip (`formatTime`), Repeat chip (`repeatChip` = `Repeat: {value}` with `repeatLabel`), and the
  clip chip when `hasClip`. Delete the Tag, Read aloud and More chips (they live behind "Edit details"). Date and Time chips are dashed when
  `state.unsure != null`. Chip container: `ConstrainedBox(minHeight: MemoSpace.hitMin)` around a 34 px visual; drop the fixed `SizedBox(height: 46)`
  (use `Wrap` with `spacing/runSpacing: space2` so chips wrap at 320 px and 200 % text).
- `_Mic`: 44 px circle, fill `accentText` / pressed `accentPressed`, icon `onAccent`; `Opacity(0.4)` when `state.micDenied`. Keep the `Listener` (down
  → `startRecording`, up/cancel → `stopRecording`). `Semantics(button: true, label: l.micRecord, hint: recording ? l.micTapToStop : l.micTapToStart,
  onTap: cubit.toggleRecording, excludeSemantics: true)`.
- The mic error row gets `TextButton(l.openSettings, onPressed: openAppSettings)` when `micDenied`.
- While `phase` is recording / transcribing / voiceFailed / confirming the bar's own row shows only the mic slot (field hidden,
  `Visibility(maintainState: true, visible: false)` for the field — the mic stays mounted in its slot). The panels of V2.5–V2.6 are drawn above it by
  `home_page.dart`.

### V2.5 Recording panel — new `presentation/voice/recording_panel.dart`
`class RecordingPanel extends StatelessWidget` reading `CaptureState`; sheet-shaped `MemoChrome(shape: ChromeShape.sheet, solid: true)` anchored to
the bottom of the Home `Stack` (not a route). Three bodies by phase:
- recording: row [12 px `accentText` dot, `Text(l.recRecording)` bodyLarge w600, spacer, mono `recTimer` = `{elapsed} / {max}`]; `Text(l.recHint)`
  body; `_LevelMeter(level)` (7 bars, 6 px wide, height = 4 + 16 × level × per-bar weight `[.5,.8,1,.7,1,.6,.4]`, `accentText`, `ExcludeSemantics`, no
  implicit animation); row [`OutlinedButton(l.commonCancel)` → `cancelRecording`, 88 px circle Stop (`accentText` fill, 24 px `onAccent` rounded
  square + `Text(l.recStop)`; `Semantics(label: l.recStopLabel)`) → `toggleRecording`]; `Text(state.latched ? l.recTipHold : l.recReleaseToStop)` 13
  `ink70`.
- transcribing: row [`MemoLoader`, `Text(l.recUnderstanding)`]; `Text(l.recOnThisPhone(endonym))` (V2 passes `endonyms['en']`; V7 passes the input
  language); `SectionCard[KeyValueRow(l.recRecording, PillValue(length))]`; `OutlinedButton(l.commonCancel)` → `cancelTranscription`.
- voiceFailed: `SheetHeading` title = `cancelled ? l.recKeptTitle : l.recFailedTitle`, body = `unavailable ? l.recFailedUnavailable(endonym) : empty ?
  l.recFailedEmpty : l.recKeptBody`; `SectionCard[row: play `MemoIconButton` (plays `media.draftVoicePath`), mono length, PillValue(l.recKept)]`;
  `ElevatedButton(l.recTypeInstead)`, `OutlinedButton(l.recSaveAsNote)`, `TextButton(l.commonTryAgain)`.
The panel has `Semantics(liveRegion: true)` on its first line.

### V2.6 Confirmation — new `presentation/home/reminder_confirmation.dart`
`class ReminderConfirmation extends StatelessWidget` (reads `CaptureState`, calls `CaptureCubit`): card `surface`, hairline border, radius
`MemoRadius.sheet`, padding 20, margin `space3`, bottom-anchored.
- `Text(state.spoken ? l.confirmYouSaid(state.text) : l.confirmYouWrote(state.text))` body 15/22 `ink70` — `state.text` verbatim, never re-cased.
  Voice-note-only: `l.voiceNoteTitle(length)` and no quote line.
- `Text(title)` 22/28 w600 (`MemoType.title`), header semantics.
- If `state.unsure != null`: `UnsureTimeBlock` (below) in place of the When row. Else a row `fieldWhen` — mono 15 `formatWhen(context, due, now)`;
  tapping it opens `showWhenSheet`.
- Row `fieldRepeat` — `repeatLabel(...)` (tap → `showRepeatSheet`). Row `fieldTag` only when `state.tag != null`.
- V7 adds the voice notice line here.
- `ElevatedButton(l.confirmSave)` `onPressed: state.canSave ? cubit.save : null`; `OutlinedButton(l.confirmEdit)` → the existing `_more` flow (move
  `_more` from `_CaptureBarState` to a top-level `Future<void> openEditDetails(BuildContext, CaptureCubit, List<String> knownTags)` in
  `capture_bar.dart`, same body).
`class UnsureTimeBlock` (same file): `cautionSoft` ground, 1.5 px `caution` border, radius `card`; row [badge `l.confirmTimeBadge` (11 mono w500,
`onAccent` on `caution`, radius 6; uppercase through `sectionLabelText`), `Text(l.confirmTimeQuestion)` 17 w600]; reason 13 `ink70`: `amPm` →
`l.confirmReasonAmPm(quoted)` where `quoted = state.text.substring(span.start, span.end).trim()`, `noTime` → `l.confirmReasonNoTime`, `dayWord` (V6) →
`l.confirmReasonDayWord(quoted)`; a `Wrap` of `OptionButton`s (new `core/ui/option_button.dart`: `OptionButton({label, selected = false, onTap})`, min
44 px, mono 15, hairline border, radius 12; selected = `ink` fill, `onInk` text; reused by the editor in V4): one per `choices` entry — label
`formatTime` when all choices share a day, else `formatWhen` — → `cubit.chooseTime(choice)`; plus `l.confirmOtherTime` → `showWhenSheet(context,
choices.first)` → `chooseTime`. The block is announced: `Semantics(container: true, liveRegion: true)`.

### V2.7 Home wiring (`presentation/home/home_page.dart`, `home_cubit.dart`, `home_state.dart`, `core/ui/memo_toast.dart`)
- In the `Stack`, above the scrim and below nothing else: `BlocBuilder<CaptureCubit, CaptureState>` showing `RecordingPanel` for
  recording/transcribing/voiceFailed and `ReminderConfirmation` for confirming/saving, each inside `AnimatedSwitcher` (fade + 8 % slide up,
  `MemoMotion.base`, zero when reduce-motion). Scrim tap: confirming → `backToTyping()`; recording → nothing (Stop/Cancel decide).
- `MemoToast`: `action` and `onAction` become nullable; no button when null.
- `HomeReady.saved` (`Reminder?`) + `HomeCubit.showSaved(Reminder r)` (5 s timer like `_undoTimer`, clears `undo`; one toast at a time) +
  `dismissSaved()`. `BlocListener<CaptureCubit, CaptureState>(listenWhen: (a, b) => b.saved != null && a.saved != b.saved, listener: (c, s) =>
  c.read<HomeCubit>().showSaved(s.saved!))`. Toast text (whole sentences): `savedToday(time)` "Reminder set for today at {time}.",
  `savedTomorrow(time)` "Reminder set for tomorrow at {time}.", `savedOn(date, time)` "Reminder set for {date} at {time}."
- `edit/edit_sheet.dart` `_HoldToRecord`: same `Semantics(onTap:)` + `accentText` fill; `EditCubit` gains `toggleRecording()` and passes the new
  `onTick` signature. No panel in the sheet; its inline text switches between `recTipHold` wording and "Tap Stop"-free copy: `latched ? l.micTapToStop
  : l.editReleaseToStop`.

### V2.8 ARB keys added in V2 (en · hi · bn where the design gives it)
captureHintLine "Type, or tap the mic and speak" · लिखें, या माइक टैप करके बोलें · লিখুন, অথবা মাইক ট্যাপ করে বলুন — commonContinue (exists) —
repeatChip "Repeat: {value}" — micRecord "Record a reminder" — micTapToStart "Double tap to start recording" — micTapToStop "Tap to stop" —
openSettings "Open Settings" — recRecording "Recording" — recTimer "{elapsed} / {max}" — recHint "Say what and when. For example: “Pay the bill on
Friday at 10”." — recStop "Stop" — recStopLabel "Stop recording" — recTipHold "Tip: press and hold the mic to record, release to stop." —
recReleaseToStop "Release to stop, or tap Stop." — recUnderstanding "Understanding your recording" — recOnThisPhone "On this phone, in {language}.
Nothing is sent anywhere." — recFailedTitle "Couldn’t turn that into text" — recFailedUnavailable "{language} speech isn’t available offline on this
phone. Your recording is kept." — recFailedEmpty "Nothing was recognised. Your recording is kept." — recKeptTitle "Recording kept" — recKeptBody
"Choose what to do with it." — recKept "Kept" — recTypeInstead "Type it instead" — recSaveAsNote "Save as voice note, pick a time" — confirmYouWrote
"You wrote: “{text}”" · — · আপনি লিখেছেন: “{text}” — confirmYouSaid "You said: “{text}”" · आपने कहा: “{text}” · আপনি বলেছেন: “{text}” — confirmSave
"Save reminder" · रिमाइंडर सेव करें · রিমাইন্ডার সেভ করুন — confirmEdit "Edit details" · बदलें · বদলান — confirmTimeBadge "Confirm time" · — · সময়
নিশ্চিত করুন — confirmTimeQuestion "Is this the right time?" · — · এটা কি ঠিক সময়? — confirmReasonAmPm "You said “{phrase}”. Pick morning or
evening." · — · আপনি “{phrase}” বলেছেন। সকাল না সন্ধ্যা, বেছে নিন। — confirmReasonNoTime "No time was given. Pick one." — confirmReasonDayWord
"“{phrase}” can mean two days. Pick one." — confirmOtherTime "Other time…" — savedToday / savedTomorrow / savedOn. Update `holdMicOn` → "Microphone
on. Tap the mic to record.", `holdHint` → "Tap the mic, speak, then tap Stop.", `homeEmptyBody` → "Bins, pills, that call.\nType below, or tap the mic
and speak.", `welcomeBody1`: add key `welcomeBody1NoPhoto` "Type or say the thing you keep forgetting. Memō rings at that time, even with the app
closed and no signal." and use it in `welcome_page.dart` when `!flags.imageCapture`. (hi `captureHintLine` deliberately says tap, not the board's
"दबाकर".)

### V2.9 Widget tests — `test/capture_flow_test.dart`
Type "Call mum tomorrow at 8" → Continue → "Confirm time" visible, "Save reminder" disabled → tap "8:00 PM" → enabled → tap → `SaveReminder` fake got
20:00 tomorrow and the toast text appears once. Type "…at 8 AM" → Continue → Save enabled at once. Tap mic (fake `VoiceClip`) → "Recording" and "Stop"
visible, the mic `Listener` is the same element before and after (`tester.element` identity). Empty transcript → three failure buttons.
`SemanticsTester`: mic exposes a tap action.

Verify V2: shared verify; on device: tap flow, hold flow, deny mic → Open Settings.

---------------------------------------------------------------------------------------------------
## V3 — Alarm, snooze sheet, detail

### V3.1 `SnoozeReminder` (`domain/usecases/snooze_reminder.dart`) — additive
`Reminder call(Reminder reminder, {required DateTime now, Duration? by, DateTime? until})`: `final next = until ?? (by == null ? <tomorrow formula,
unchanged> : now.add(by));`. Nothing else moves. Test: `until` wins; a repeat still only gets `snoozedUntil`.

### V3.2 Snooze sheet — new `presentation/widgets/snooze_sheet.dart` (delete `snooze_preset_row.dart`)
`Future<DateTime?> showSnoozeSheet(BuildContext context, Reminder r)` → the instant to ring again. `showMemoSheet`; `SheetHeading(l.snoozeTitle, body:
l.snoozeBody)`; three `OutlinedButton(style: MemoButtons.large(c))`, each a `Row[Expanded(Text(label)), Text(formatWhen-or- formatTime, mono 13
ink70)]`: `snooze10` / `snooze1h` / `snoozeTomorrow`. The time shown is `const SnoozeReminder()(r, now: now, by: …).ringsAt` (the use case is the only
place that computes it). `TextButton(l.snoozePick)` → `pickDate` then `pickTime`; ignore a result not after now. Callers pass the result as `until:`.
- `AlarmCubit.snooze(DateTime until)` and `DetailCubit.snooze(DateTime until)` replace the `Duration? by` variants (`grep -rn "\.snooze(" lib test`).
  `HomeCubit.snooze(by: 10 min)` stays.
Keys: snoozeTitle "Snooze until…" — snoozeBody "It will ring again, same sound." — snooze10 "Snooze 10 minutes" — snooze1h "Snooze 1 hour" —
snoozeTomorrow "Tomorrow, same time" — snoozePick "Pick a time". Delete `snoozeTenMinutes`, `snoozeOneHour`, `alarmSlideToDone`.

### V3.3 Alarm page (`presentation/alarm/alarm_page.dart`)
Delete `SlideToDone` and the `SnoozePresetRow`. Body, top to bottom (wrap the column in `SingleChildScrollView` with the two buttons pinned below it
in the outer `Column`):
1. Row: `DaySectionHeader(l.alarmReminder)` · late text (`sectionLabelStyle`, `accentText`).
2. Clock: `Text.rich` — time part `MemoType.clock`, AM/PM part `MemoType.labelMedium` sized 20 (split the `formatTime` string at the space; 24h has no
   second part). `FittedBox(scaleDown)`.
3. Title `MemoType.alarmTitle`, `Semantics(header: true)`, no `maxLines`.
4. Note (`body`, `ink70`).
5. If repeating: `Row[Icon(Icons.repeat_rounded, 16, ink70), Text(repeatLabel)]` 13 `ink70`.
6. If `state.speakingIn != null`: `Row[Icon(Icons.volume_up_outlined, 16), Text(l.alarmReadingIn(endonym))]`. `AlarmState.speakingIn` (`String?`
   language code) is set in `AlarmCubit.load` when it speaks or a native alarm is sounding with speech; V3 sets `'en'` whenever `reminder.readAloud`;
   V7 sets the plan's language.
7. Voice-note row as today (ground `accentText`).
8. `ElevatedButton.icon(icon: check, label: l.commonDone, style: MemoButtons.large(c))` → `cubit.done`; `OutlinedButton(l.detailSnooze, style:
   MemoButtons.large(c))` → `final at = await showSnoozeSheet(context, reminder); if (at != null) cubit.snooze(at);`
Both platforms use this page; Android reaches it through the full-screen intent (`memo:///alarm/<id>`, unchanged). Nothing here applies to the
AlarmKit alert. Key: alarmReadingIn "Reading aloud in {language}" · {language} में पढ़कर सुनाया जा रहा है · {language}-য় পড়ে শোনানো হচ্ছে (board
strings use the inflected forms "हिन्दी में…", "বাংলায়…"; translator decides: fixed per-language keys `alarmReadingInEn/Hi/Bn` are acceptable if the
placeholder reads badly). hi/bn: commonDone as V1; detailSnooze बाद में याद दिलाएँ · পরে মনে করাও.

### V3.4 Detail page (`presentation/detail/detail_page.dart`)
- Header label (`sectionLabel*`): one-off `formatWhen`; repeat `detailRepeatNext(repeat, when)` "{repeat} · next {when}".
- `SectionCard`: Next, Repeat, Created, plus (only when set) Nag, Remind me earlier, Tag. No "This week" row.
- Actions row: `Expanded(ElevatedButton.icon(check, reminder.repeat.repeats ? l.detailDoneToday : l.commonMarkDone))` +
  `Expanded(OutlinedButton(l.detailSnooze))` → `showSnoozeSheet`. Under it, for repeats: `Text(l.detailMovesTo(formatWhen(context, const
  CompleteReminder()(reminder, now: now).dueAt, now)))`. Done reminders keep "Reopen". Then `OutlinedButton(l.detailDelete)` in `destructive` (confirm
  dialog stays).
- Remove the "Snooze" section header + preset row.
Keys: detailRepeatNext — detailDoneToday "Mark done for today" — detailMovesTo "Marking done moves it to {when}." — detailDelete "Delete reminder" —
repeatEveryDayLong "Every day" (use in `repeatLabel` for daily on Detail and Alarm; the segmented control keeps `repeatDaily`).

### V3.5 Tests
`test/alarm_test.dart`: finds "Done" and "Snooze" buttons ≥ 64 px high; tapping Snooze shows three options with times; choosing "Snooze 1 hour" calls
save with `ringsAt == now + 1 h`; no `SlideToDone` type exists (`grep` in verify). `test/detail_page_test.dart`: update for the new actions; repeat
shows "Mark done for today" and the moves-to line.

Verify V3: shared verify + `! grep -rn "SlideToDone\|SnoozePresetRow" lib test`. Device: alarm over the lock screen on the Samsung; Done / each
snooze; iPhone in-app alarm page.

---------------------------------------------------------------------------------------------------
## V4 — Home, archive, editor, motion, large text

### V4.1 Home header (`home_page.dart` `_Header`)
- Summary: `scheduled == 0 ? l.homeSummaryNone : overdue > 0 ? l.homeScheduledOverdue(scheduled, overdue) : l.homeScheduled(scheduled)`.
- Next line, when a not-overdue live reminder exists (`ready.upcoming` first with `ringsAt` after `now`): `Wrap(crossAxisAlignment:
  baseline-equivalent, spacing: space2)[Text(l.homeNext, 13 ink70), Text(title, 17 w600, maxLines 2, ellipsis), Text(l.homeNextWhen(formatTime,
  formatUntil), mono 13 ink70)]`. No card, no background.
- `formatUntil(c, Duration d)` in `date_format.dart`: `untilDays` "in {count} d" / `untilHours` "in {count} h" / `untilMinutes` "in {count} min" (min
  1).
Keys: homeNext "Next" · अगला · পরেরটা — homeNextWhen "{time} · {until}" — untilHours · {count} घंटे में · {count} ঘণ্টা পরে — untilMinutes —
untilDays.

### V4.2 Rows (`widgets/reminder_row.dart`, `widgets/swipeable_reminder_row.dart`, `home_page.dart` `_Row`)
- Title `maxLines: 3`, `softWrap: true`; row keeps `minHeight: rowMin`, no fixed height.
- `CheckControl` semantics label: `l.markDoneNamed(title)` "Mark {title} done" (new optional `semanticLabel` parameter on `CheckControl`; fall back to
  today's label).
- `SwipeableReminderRow.actionWidth` 52 → 72; labels `swipeSnooze` "Snooze\n10 min" and `commonDelete` (delete key `commonDeleteShort`); the complete
  band shows check + `commonDone`.
- New parameter `onEdit`; `customSemanticsActions` gains Edit. `onLongPress` on the row → `showRowActions(context, …)`: `showMemoSheet` with
  `SheetHeading(title)` and a `SectionCard` of four `KeyValueRow`s (`commonMarkDone`, `commonSnoozeTenMinutes`, `commonEdit`, `commonDelete` in
  `destructive`), each pops then runs the same callback as the swipe. `HapticFeedback.selectionClick()` on open. `_Row` passes `onEdit: () =>
  showEditSheet(context, existing: reminder, knownTags: …)`.
- Row tap still opens Detail (where all four are visible buttons).

### V4.3 Archive (`presentation/archive/archive_page.dart`, `archive_cubit.dart`)
- Above the field a visible label `archiveSearchLabel` "Search done reminders"; hint `archiveSearchHint` → "Search".
- Group by `doneAt` day with `DaySectionHeader(dayHeaderLabel(...))` (reuse `groupByDay` in `day_grouping.dart` if its signature fits a `DateTime
  Function(Reminder)` key; else add that parameter with default `(r) => r.ringsAt`).
- Row trailing: `TagChip`-styled "Reopen" (min hit 44).
- Empty: `EmptyRing`, `archiveEmptyTitle` "Nothing done yet", `archiveEmptyBody` "Reminders you mark done show up here. You can reopen them."

### V4.4 Editor (`presentation/edit/edit_sheet.dart`, `edit_cubit.dart`)
- `EditState.advanced` (`bool`, default false) + `EditCubit.showAdvanced(bool)`.
- Basic view: header row [`TextButton(commonCancel)`, title, `TextButton(commonSave)`]; label `editWhat` "What" + title field;
  `DaySectionHeader(fieldWhen)`; `OptionButton`s (from V2.6) `dateToday` / `dateTomorrow` / third = `editPickDate` "Pick date" or the picked date via
  `formatDate` (selected) → `pickDate`; second row: current time (selected) + `editChangeTime` "Change time" → `pickTime`;
  `DaySectionHeader(fieldRepeat)` + existing `_RepeatPicker`; `OutlinedButton(editMoreOptions)` "More options: note, tag, nag, sound".
- Advanced view (same sheet, `AnimatedSwitcher` on `state.advanced`): header [`TextButton(editBackBasic "‹ Basic")`, `editMoreTitle` "More options",
  Save]; label `editNote` "Note" + note field; `SectionCard`: `fieldTag` (existing `_TagPicker` in a sheet), `fieldPreAlarm` → value text changes to
  "Remind me earlier", `editNagTitle` → "If I don’t respond" with pill `nagSummary` "Every {minutes} min, 6 times", `editSound` (existing `_SoundCard`
  content), `editReadAloudWhenRings` → "Read title aloud"; footer `editOptionalBody` "These are optional. Most reminders only need what and when."
- All existing cubit logic (draft clip, past-time guard, save) is untouched; only layout moves.
- Update `test/edit_sheet_test.dart`: fields under "More options" need a tap on that button first.

### V4.5 Motion (new `lib/core/ui/motion.dart`: `Duration motion(BuildContext c, Duration d) => MediaQuery.disableAnimationsOf(c) ? Duration.zero : d;`)
| Where | Effect | Token |
|---|---|---|
| `memo_sheet.dart` | `sheetAnimationStyle: AnimationStyle(duration: motion(c, slow), reverseDuration: motion(c, base), curve: MemoMotion.curve)` | slow / base |
| `check_control.dart` | idle → done: disc scales in, tick fades in (`AnimatedScale` + `AnimatedOpacity`); `HapticFeedback.lightImpact()` on tap | base |
| `home_page.dart` `_Row` | completing a one-off or deleting: `SizeTransition` + fade out, then call the cubit; repeats call at once | base |
| Home toast slot | `AnimatedSwitcher`, fade + slide from `Offset(0, .5)`, keyed by message | base |
| `capture_bar.dart` chrome column | `AnimatedSize(alignment: bottomCenter)` | base |
| `RepeatSegmentedControl` | sliding thumb (`AnimatedAlign`), `selectionClick` | base |
| `swipeable_reminder_row.dart` | `selectionClick` once when the offset crosses `completeThreshold` | — |
Haptics do not depend on reduce-motion. Save success: `lightImpact`; delete: `mediumImpact`.

### V4.6 Large text and narrow screens
- Replace fixed heights with `minHeight` in: tag filter bar (`home_page.dart`, `SizedBox(height: 46)`), `RepeatSegmentedControl` (36 → min 44),
  `WeekdaySelector` tiles (36 → min 44), `TagChip` (30 visual inside a 44 hit box), `MemoToast` (`minHeight: hitMin`, `maxLines: 2`), `KeyValueRow`,
  all buttons (theme `minimumSize` already; remove any `fixedSize`).
- New `test/a11y_layout_test.dart`: pump Home (5 reminders incl. one 80-char title), the confirmation card (ambiguous, Bengali strings), Alarm,
  Settings at (a) `textScaler: TextScaler.linear(2.0)` on 390×844 and (b) 320×690 at 1.0; `expect(tester.takeException(), isNull)`. Tap-target test:
  `tester.getSize` ≥ 44×44 for mic, chips, check control, option buttons, radio rows, swipe actions.

Verify V4: shared verify. Device: TalkBack / VoiceOver row actions; long-press menu; Reduce Motion on/off.

---------------------------------------------------------------------------------------------------
## V5 — Settings reorganisation, alarm health

### V5.1 Native (additive methods on `memo/alarm`, `MainActivity.kt`)
```kotlin
"battery" -> result.success(mapOf(
    "unrestricted" to getSystemService(android.os.PowerManager::class.java).isIgnoringBatteryOptimizations(packageName),
    "maker" to Build.MANUFACTURER))
"openBatterySettings" -> { startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName"))); result.success(null) }
```
No manifest change. `native_alarm.dart`: `Future<({bool unrestricted, String maker})> battery()`, `Future<void> openBatterySettings()`.

### V5.2 `SettingsCubit` / `SettingsState`
- State adds `bool? batteryUnrestricted`, `String maker`, `DateTime? lastTestAt`. `refresh()` reads them (Android only; `NativeAlarmError` → null).
- `List<HealthItem> get health` on the state. `HealthItem(id, status)` with `enum HealthStatus { allowed, ok, fix, off }` and ids: Android
  `notifications` (off when denied), `exactAlarms` (off), `fullScreen` (fix; only when not null), `overlay` (fix), `battery` (fix); iOS `alarms`
  (AlarmKit: off when denied, fix when `notDetermined`; absent below iOS 26), `notifications` (off), `focus` (allowed when AlarmKit authorised, else
  fix), `backgroundRefresh` (always ok). `int get toFix` = count of fix + off.
- `Future<void> fix(String id)`: dispatches to the existing `requestNotifications`, `requestExactAlarms`, `openFullScreenSettings`,
  `openOverlaySettings`, `requestAlarms`, and new `openBatterySettings`; `focus` → `requestAlarms`.
- `Future<void> ringTest()`: `await sl<SaveReminder>()(Reminder(id: 'memo-test', title: l10n().testAlarmTitle, dueAt: now + 10 s, createdAt: now,
  nagMin: null, readAloud: _prefs.readAloudDefault))` (inject `SaveReminder` through the constructor), then `_prefs.setLastTestAt(now)` (new pref key
  `last_test_at`, epoch ms) and `refresh()`. `ScheduleFailure` → state `error`.
- Delete: `setVoiceGender` stays; Phase 2 and Capture-section code goes.

### V5.3 Widgets — `features/settings/permission_status_row.dart` (new)
- `StatusPill(HealthStatus s)`: `PillValue`-shaped; text `healthAllowed` / `healthOk` / `healthFix` / `healthOff`; colours: allowed, ok → text `ok`,
  ground `ok.withValues(alpha: .12)`; fix → `caution` on `cautionSoft`; off → `accentText` on `accentSoft`. Word always present (never colour alone).
- `PermissionStatusRow(title, state, status, onTap)`: min height 60, title `bodyLarge`, state line 13 `ink70`, pill trailing; tappable only for
  fix/off; `Semantics(label: '$title, $state, $pill')`.

### V5.4 Pages
`settings_page.dart` rebuilt (`ListView` of sections, all rows `KeyValueRow` + `PillValue`):
1. `settingsReminders`: `settingsNoResponse` "If I don’t respond" (existing nag sheet) · `settingsReadTitle` "Read title aloud" (toggle).
2. `settingsLanguageVoice`: `settingsAppLanguage` (V1). Until V7 also the existing Voice (Female/Male + preview) row. V7 adds two rows.
3. `settingsReliability`: `settingsHealth` "Alarm health" → `/settings/health`, pill `toFix == 0 ? healthAllSet : healthToFix(toFix)` (ICU plural "1
   thing to fix" / "{count} things to fix") coloured like `StatusPill`; `settingsTest` "Test alarm" pill `settingsTestValue` "Ring in 10 s" →
   `ringTest()` then a toast `testStarted` "Lock the phone. It rings in 10 seconds."
4. `settingsAppearance`: `settingsTheme` "Theme" → `showMemoSheet` with `MemoRadioList` System / Light / Dark → `AppSettingsCubit.setThemeMode`.
5. `settingsAbout`: `settingsPrivacy` "Privacy" pill `settingsPrivacyValue` "Nothing leaves this phone" → `showMemoSheet` with
   `SheetHeading(settingsPrivacy)` and body `privacyBody` (three plain sentences: storage on device, speech on device, no account/analytics). Footer
   `settingsFooter(version)`.
New `features/settings/health_page.dart` (`/settings/health`, own `SettingsCubit..refresh()`, refresh on resume like the settings page): title
`healthTitle`; body `toFix == 0 ? healthBodyOk : healthBodyFix(toFix)`; `SectionCard` of `PermissionStatusRow`s; primary button
`healthFixFirst(title)` when something needs fixing → `HealthFixPage`; `OutlinedButton/ElevatedButton(healthTestButton)` "Ring a test alarm in 10
seconds"; `lastTestAt != null` → `healthLastTest(when)` "Last test started: {when}." New `features/settings/health_fix_page.dart`
(`/settings/health/fix/:id`): label `healthFixStep(n, total)` "Fix {n} of {total}", title and body per id, numbered steps (`SectionCard`, 3–4 ARB
strings per id), on Android `healthDetected(maker)` "Detected: {maker}."; `ElevatedButton(healthOpen…)` → `cubit.fix(id)`;
`OutlinedButton(healthCheckAgain)` "I changed it, check again" → `refresh()`; when that item is no longer fix/off: go to the next one, or pop when
none is left. Per-id copy keys (title · state-ok · state-bad): `healthNotifications` "Notifications" · "Banners and sound" · "Off: reminders cannot
ring" — `healthExact` "Exact alarms" · "Allowed" · "Off: alarms can ring late" — `healthFullScreen` "Full-screen alarms" · "Allowed" · "Off: alarm
shows as a small banner" — `healthOverlay` "Take over the screen" · "Allowed" · "Off: only a banner while you use the phone" — `healthBattery`
"Battery" · "Unrestricted" · "Restricted: phone may stop Memō" — `healthAlarms` "Alarms" · "Allowed for Memō" · "Off: Memō falls back to
notifications" — `healthFocus` "Focus and silent mode" · "Alarms ring through" · "Focus can silence reminders" — `healthBackground` "Background
refresh" · "Not needed". Body: `healthBodyOk` "This phone is set up to ring Memō reminders. No phone can promise every alarm, so test once." /
`healthBodyFix` plural "{count} settings may stop reminders from ringing on time." Battery fix steps: "Tap “Open battery settings” below." / "Choose
Battery." / "Choose Unrestricted." / "Come back to Memō." Delete ARB keys no longer referenced (`settingsPhase2`, `settingsCloudSync`,
`settingsShared`, `settingsSoon`, `settingsLook`, `settingsGlass`, `settingsFollowsIos`, `settingsSolid`, `settingsCapture`, `settingsDictation*`,
`settingsReadPhotos`, `settingsNoSpeechModel`, `settingsTakeOverHint`, `settingsNotificationsHint`) — the l10n guard test plus `grep` per key before
deleting.

### V5.5 Android onboarding step 3 (`features/onboarding/`)
New `pages/battery_page.dart`: label `onbStep3` "Step 3 of 3", title `onbBatteryTitle` "Keep alarms alive", body `onbBatteryBody`, card with step 1
"Allow in background — Battery · Memō · Unrestricted" and, only when `maker.toLowerCase()` ∈ {xiaomi, redmi, poco, vivo, oppo, realme, oneplus}, step
2 "Allow autostart"; buttons `healthOpenBattery` "Open battery settings", `onbDidThis` "I did this", `onbSkipRisk` "Skip, I will risk it".
`OnboardingCubit.requestPermissionAndFinish`: on Android, when `!(await native.battery()).unrestricted && !prefs.batteryStepDone`, emit a new status
`OnboardingStatus.battery` (the `PageView` moves to page 3) instead of finishing; each button calls `prefs.setBatteryStepDone()` then finishes. iOS
never shows it. `permission_primer_page.dart`: show `permBody2` only on Android.

### V5.6 Tests
`test/settings_health_test.dart`: fake native → `health` list per platform flag; `toFix`; `fix('battery')` calls `openBatterySettings`; `ringTest`
saves id `memo-test` due ≈ now + 10 s. Widget: health page shows a "Fix" pill and the fix page advances after `refresh()` reports it fixed. Onboarding
cubit: Android + restricted → `battery` status; iOS → finished.

Verify V5: shared verify. Device (Samsung): Settings → Apps → Memō → Battery → Restricted, then walk the fix.

---------------------------------------------------------------------------------------------------
## V6 — Parser: Hindi and Bengali

### V6.1 New `domain/parser/parser_packs.dart` (data only)
```dart
class ParserPack {
  const ParserPack({required this.language, required this.today, required this.tomorrow,
    required this.dayAfter, required this.ambiguousDays, required this.weekdays, required this.months,
    required this.parts, required this.clock, required this.daily, required this.every,
    required this.after, required this.units, required this.numbers, required this.fractions,
    required this.specials, required this.glue, required this.latin});
  final String language;                       // 'hi' | 'bn'
  final List<String> today, tomorrow, dayAfter;
  final List<String> ambiguousDays;            // subset of tomorrow/dayAfter that can also mean the past
  final Map<String, int> weekdays, months;
  final Map<String, (int, int, bool)> parts;   // part of day → default (h, m), isPm
  final List<String> clock, daily, every, after;
  final Map<String, String> units;             // word → m|h|d|w|mo|y
  final Map<String, int> numbers;              // "आठ": 8, "aath": 8 … 1–12
  final Map<String, int> fractions;            // "साढ़े": 30, "सवा": 15, "पौने": -15 (minutes)
  final Map<String, (int, int)> specials;      // "डेढ़": (1, 30), "ढाई": (2, 30)
  final List<String> glue;                     // phrases stripped from the title ends
  final Set<String> latin;                     // which of the words above are Latin transliteration
}
const hindi = ParserPack(…); const bengali = ParserPack(…);
```
Word tables: take the lists from `docs/plans/memo-fixes-l10n/guidelines.md` section C1 (weekdays, months, parts, clock, daily, every, after, units,
glue for hi and bn) unchanged, including its two collision rules (no Latin `rat`; Latin units, clock suffixes and postpositions only directly after a
number). Add:
- hi `ambiguousDays`: `कल, kal, परसों, parso, parson`. bn: `কাল, kal, kaal, পরশু, porshu, porsu`. bn `tomorrow` also has the unambiguous `আগামীকাল,
  agamikal`; `গতকাল` is not in any table (past).
- hi `numbers`: एक ek 1, दो do 2, तीन teen 3, चार char 4, पाँच पांच paanch 5, छह छः chhah 6, सात saat 7, आठ aath 8, नौ nau 9, दस das 10, ग्यारह gyarah
  11, बारह barah 12. bn: এক ek 1, দুই dui 2, তিন tin 3, চার char 4, পাঁচ panch 5, ছয় chhoy 6, সাত shat 7, আট aat 8, নয় noy 9, দশ dosh 10, এগারো
  egaro 11, বারো baro 12. Bengali clock forms attach the suffix ("আটটায়", "৮টায়"): the clock regex allows zero whitespace before the suffix.
- hi `fractions`: साढ़े साढे saade sadhe 30, सवा sava sawa 15, पौने paune -15; `specials`: डेढ़ dedh (1,30), ढाई dhai (2,30). bn: সাড়ে sare 30, সোয়া
  shoa 15, পৌনে poune -15; দেড় der (1,30), আড়াই arai (2,30).
- hi glue adds the phrases `की याद दिलाना`, `याद दिलाना`, `याद दिला देना`, `yaad dilana`; bn adds `মনে করিয়ে দিও`, `মনে করিয়ে দাও`, `mone koriye
  dio`. Longest phrase first. The title is never re-inflected ("दवाई लेने" stays as said).

### V6.2 `reminder_parser.dart`
1. Signature: add `String language = 'en', bool latinPacks = false`. Callers: `CaptureCubit.setText` passes `language: prefs.inputLocale`,
   `latinPacks: {'hi','bn'}.intersection({inputLocale, interfaceLanguage()}).isNotEmpty` (inject both as getters like `defaultNagMin`).
2. First line: map `०-९` (U+0966–096F) and `০-৯` (U+09E6–09EF) to `0-9` in `work` (BMP, one code unit each: length and offsets unchanged). Offsets
   everywhere are UTF-16 code-unit offsets into `input`.
3. Boundaries for pack words: `const _l = r'(?<![\p{L}\p{M}\p{N}])', _r = r'(?![\p{L}\p{M}\p{N}])';` every pack `RegExp(..., unicode: true)`;
   alternations built longest-first by `String _alt(Iterable<String> w)` (sort by length desc, `RegExp.escape`, join `|`). Because a match starts and
   ends at a letter/mark/number boundary it never splits a surrogate pair or a conjunct. Skip a pack word when `pack.latin.contains(word) &&
   !latinPacks`.
4. Pack order: `[pack for language, the other]`; both always run (mixed input).
5. After each English section, only when that section found nothing, run the packs:
   - Repeat: daily words; `every` + weekday(s) joined by `,|aur|और|o|ও|ar|আর`.
   - Relative: `(num)\s*(unit)\s*(after)?` — num = `\d+` or a `numbers` word.
   - Date: dayAfter (+2), tomorrow (+1), today (0), `(\d{1,2})\s*(month)`, weekday (same rule as English weekdays). If the matched word is in
     `ambiguousDays`, remember `dayWordSpan`.
   - Time: `(fraction\s+)?(num)(?:[:.](\d{2}))?\s*(clock)` and `(special)\s*(clock)`; fraction adds its minutes (−15 borrows from the previous hour);
     bare hour 1–12 is `ambiguous`; a part-of-day word resolves it exactly like English "tonight/morning" (`raat 12` → 00:00); a part word alone gives
     its default. Every match goes through `take()` so title and spans work unchanged.
6. Ambiguity: `kinds` gains `dayWord` when `dayWordSpan != null`; `choices` as built today (the day is the future reading); `span` = dayWord span
   joined with the clock span when both exist (`SourceSpan(min start, max end)`). With `dayWord` only: `choices = [due]`.
7. `_title`: also strip pack glue at both ends.
8. `UnsureTimeBlock`: reason for `{dayWord}` → `confirmReasonDayWord`; `{dayWord, amPm}` → new `confirmReasonDayAndTime(phrase)` "“{phrase}” is not
   clear. Pick the day and time."; labels use `formatWhen`.

### V6.3 Tests — `test/reminder_parser_hi_bn_test.dart` (now = Fri 2026-11-20 14:30)
hi, `latinPacks: true`: "kal subah 8 baje dawai" → 21 Nov 08:00, title "Dawai", `kinds == {dayWord}`; "कल सुबह 8 बजे दवाई" → same, title "दवाई"; "कल
सुबह आठ बजे दवाई लेने की याद दिलाना" → 08:00, title "दवाई लेने"; "kal 8 baje" → `{dayWord, amPm}`, choices 21 Nov 08:00 and 20:00; "आज शाम साढ़े 6
बजे" → today 18:30, `ambiguity == null`; "पौने 9 बजे सुबह" → 08:45; "ढाई बजे" → `{amPm}` 02:30/14:30; "2 ghante baad call" → 16:30; "har somvar gym" →
weekly {1}; "रोज़ रात 9 बजे दवाई" → daily 21:00; "buy rat poison" → `{noTime}`, title "Buy rat poison". bn: "কাল সকাল ৮টায় ওষুধ" → 21 Nov 08:00
`{dayWord}`; "আগামীকাল সকাল আটটায় ওষুধ" → 08:00, null; "protidin raat 9 ta" → daily 21:00; "3 din pore" → 23 Nov 14:30; "সাড়ে ৫টায় বিকেলে" → 17:30.
Mixed: "call mom कल 8pm" → 21 Nov 20:00 `{dayWord}`, title "Call mom". Gating: `latinPacks: false`: "sham marriage talk" → no time, title unchanged;
"kal 8 baje" → not parsed. Spans: for every case assert `input.substring(span.start, span.end)` is non-empty and contains no half surrogate
(`String.fromCharCodes(...)` round-trips). `reminder_parser_test.dart` passes unchanged.

### V6 Implementation notes (deviations from the text above)
- `ParserPack` has no `language` or `latin` fields: a word is Latin when it starts with an ASCII letter. Extra optional fields: `next`
  ("अगले/আগামী" before a weekday, +7 on the same weekday like English `next`), `weakClock` (bn `টা`/`ta`), `quantities` ("डेढ़/ढाई/आधे घंटे बाद").
- `parts` carry no `isPm`. Each part has explicit hour windows (`PartRule`); a spoken hour outside its part's windows stays unsure (asks).
  A night part resolving to 00:00-04:xx with a day word moves to the next calendar day ("कल रात 12 बजे" is 22 Nov 00:00).
- Latin words are gated per input (`_latinIntent`): `latinPacks` alone does not read "Call Kal at 5pm". Latin is read only for a weekday, "parso" or
  "2 ghante baad" (never English), two different anchor words (day, part, `baje`, `har`), or one anchor touching a digit or native-script word.
  Dropped from the Latin tables: `aj`, `parson`, `sham`, `roz`, `roj`, bn month `me`.
- A relative time needs the postposition (`बाद/में/পরে`): a bare "2 घंटे" is a length. A bare bn `টা`/`ta` is a time only beside a part of day or `বাজে/baje`.
- Tags accept any Unicode letter, mark or digit (`#दवा`); "#café" now keeps its accent. ASCII tags are unchanged.
- Known and untouched: English `_title` leaves a literal `$1` for a space before punctuation ("a , b"); the regression test locks English output.

Verify V6: shared verify + both parser test files.

---------------------------------------------------------------------------------------------------
## V7 — STT and TTS by locale

### V7.1 STT (`data/speech_to_text.dart`, `SttPlugin.kt`, `SttPlugin.swift`)
Dart: `String sttTag(String language)` → `hi-IN`, `bn-IN`; `en` → first device locale with language `en` (`toLanguageTag()`), else `en-IN`.
`Future<String> availability(String tag)` → `installed | downloadable | unavailable` (catch → `unavailable`); keep `available()` as
`availability(sttTag(input)) == 'installed'`. `transcribeFile(path, tag)` sends `{'path', 'locale'}`. `CaptureCubit` gets `String Function()
inputLocale`. Kotlin: delete `language()`; `transcribe(path, tag)` uses `tag` for `EXTRA_LANGUAGE`; new method `"availability"`: SDK < 33 or
`!isOnDeviceRecognitionAvailable` → `unavailable`; else `createOnDeviceSpeechRecognizer(context).checkRecognitionSupport(intent(tag), mainExecutor,
callback)`: language in `installedOnDeviceLanguages` → `installed`; in `supportedOnDeviceLanguages` or `pendingOnDeviceLanguages` → `downloadable`;
else / `onError` → `unavailable`; compare by `Locale.forLanguageTag(x).language`; destroy the recogniser; reply once on the main thread. Keep the
existing partial-results fallback and `triggerModelDownload` (a model download, no audio leaves the phone). Keep `"available"` answering for old
callers. Swift: no stored recogniser; `SFSpeechRecognizer(locale: Locale(identifier: tag))`; `"availability"` → `supportsOnDeviceRecognition &&
isAvailable ? "installed" : "unavailable"`; `requiresOnDeviceRecognition = true` stays.

### V7.2 Speech plan — new `domain/speech_plan.dart` (pure Dart)
```dart
enum TitleScript { latin, hi, bn }
TitleScript scriptOf(String text); // count letters in U+0900–097F and U+0980–09FF; the larger wins; neither → latin
/// The language to speak [title] in, or null when it must not be spoken.
String? speechLanguage({required String title, required String playback, required Set<String> voices}) {
  final s = scriptOf(title);
  final wanted = switch (s) { TitleScript.hi => 'hi', TitleScript.bn => 'bn',
      TitleScript.latin => playback == 'follow' ? 'en' : playback };
  return voices.contains(wanted) ? wanted : null;
}
String? wantedLanguage(…) // same without the voices check: for the "No X voice" notice
```
Tests: Bengali title + playback `en` + voices `{en}` → null (never English); Latin + `hi` + `{en,hi}` → `hi`; Latin + `follow` → `en`; mixed title →
majority script.

### V7.3 TTS (`data/spoken_reminder.dart`, `TtsPlugin.kt`, `TtsPlugin.swift`)
Dart `SpokenReminder`:
- Constructor adds `String Function() playback` and caches `Future<Set<String>> voices()` → channel `'voices'` (languages among en/hi/bn with an
  offline voice); refreshed by `refreshVoices()` (called from Settings and on app resume).
- `_render(r)`: `lang = speechLanguage(title: r.title, playback: playback(), voices: await voices())`; null → return null. `l = l10n(lang)`; note =
  first line of `r.note` only when `scriptOf(note)` is latin or equals the title's script; text = `l.spokenReminderNote(title, note)` or
  `l.spokenReminder(title)`. Args add `'language': lang`; name = `say-${r.id}-${_hash('$g|$lang|$text')}`. The native call no longer deletes other
  files (see below).
- `Future<void> prune(String reminderId, String? keep)` → channel `'prune'` `{prefix: 'say-<id>-', keep}`.
- `say(r)`, `preview(language)` pass `language`; `preview` returns `Future<bool>`.
- Schedulers: `android_alarm_scheduler.dart` / `ios_alarm_scheduler.dart` / the `soundFor` closure in `di.dart`: after the native `schedule` /
  `replaceAll` / notification scheduling **returned**, call `prune(r.id, <basename of the sound just used, or null>)` for each reminder. Order
  matters: an armed alarm never points at a deleted file.
- Android fallback: in `AndroidAlarmScheduler._entries`, `'speech': speech ?? (r.hasVoice && r.readAloud ? media.voicePath(r.id) : null)` (inject
  `MediaStore`; the Kotlin loop already plays any file path after the chime). iOS unchanged.
Kotlin `TtsPlugin`:
- `render`: write to `File(dir, "$name.wav.tmp")`, on `onDone` `renameTo` the final file, then reply; on error delete the tmp. Remove the
  delete-older-files line. Startup: delete stray `*.tmp`.
- `pickVoice(engine, gender, language): Boolean`: offline voices with `locale.language == language`; rank own country, then `IN`; English keeps the
  gender codes and the pitched fallback; hi/bn take the first offline voice (gender best-effort, no pitch change); none → false → `render` replies
  null, `preview` replies false.
- New `"voices"` → list of languages in `{en, hi, bn}` for which `pickVoice` would succeed; `"prune"` → delete files starting with `prefix` except
  `keep`; `"openTtsSettings"` → `startActivity(Intent("com.android.settings.TTS_SETTINGS").addFlags(FLAG_ACTIVITY_NEW_TASK))` in try/catch.
Swift `TtsPlugin`: `utterance(text, gender, language) -> AVSpeechUtterance?` (voices with `language.hasPrefix(lang)`; preferred gender, then any; none
→ nil, English keeps today's fallback); `render` writes to `<name>.caf.tmp` then moves it into place; no pre-delete; `"voices"`, `"prune"` as above;
`preview` returns Bool.

### V7.4 UI
- `language_page.dart` gains section `settingsSpeaking` "Speaking language": `MemoRadioList` en/hi/bn with hint from `availability`: `sttInstalled`
  "Offline on this phone" / `sttDownloadable` "Needs a download in phone settings" / `sttUnavailable` "Not available on this phone" (still selectable;
  the failure panel explains). Footer `sttOneLanguage` "Memō listens in one language at a time. Automatic detection is not available yet." →
  `AppSettingsCubit.setInputLocale`.
- New `features/settings/voice_page.dart` (`/settings/voice`): title `voiceTitle` "Read-aloud voice"; body `voiceBody` "When a reminder rings, Memō
  can read its title aloud. It reads your words as written; it does not translate them."; `MemoRadioList` `follow` (`voiceFollow` "Follow reminder
  language", hint `voiceFollowHint` "Hindi reminders in Hindi, English in English"), en, hi, bn (hint `voiceMissing(language)` "No offline {language}
  voice on this phone" when absent) → `setPlaybackLocale` (which runs `SyncAlarms`); `OutlinedButton.icon(volume, voicePreview)` "Preview: “Take
  medicine”" → `SpokenReminder.preview(lang)` with the sample `spokenPreview` of that language (`follow` → interface language); a `SectionCard` row
  per missing voice with `StatusPill`-style `voiceNotInstalled` "Not installed"; existing Female/Male row (`settingsVoice`) with hint
  `voiceGenderHint` "English voices"; `TextButton(voiceHowTo)` "How to install a voice" → sheet with platform steps (`voiceHowToAndroid`,
  `voiceHowToIos`) and, on Android, a button → `openTtsSettings`.
- `settings_page.dart` section 2: add rows `settingsSpeaking` (pill = endonym) → `/settings/language` and `settingsReadAloudVoice` (pill =
  `voiceFollowShort` "Follow reminder" or endonym) → `/settings/voice`; remove the temporary Voice row from the main page.
- `AppSettingsCubit` in `di.dart`: `onLanguageChanged: () => sl<SyncAlarms>()()` (register after `SyncAlarms`).
- `RecordingPanel`: `recOnThisPhone(endonyms[inputLocale])`, `recFailedUnavailable(endonyms[inputLocale])`.
- Notice line (13 `ink70`, `caution` info icon) when `r.readAloud && speechLanguage(...) == null`, text `voiceNoticeNote` "No {language} voice on this
  phone. It rings with your voice note." when `hasVoice` on Android, else `voiceNotice` "No {language} voice on this phone. It rings with the chime."
  — shown on `ReminderConfirmation`, Detail and under the "Read title aloud" row of the editor.
- `AlarmCubit.load`: `speakingIn` = the plan language (null hides the line); when the plan is null, `reminder.hasVoice` and nothing native is sounding
  → `togglePlay()` once.

### V7.5 Tests
`test/speech_plan_test.dart` (V7.2). `test/spoken_reminder_test.dart`: mock channel — a Bengali title with voices `{en}` never calls `render`; name
changes when playback changes; `prune` is called after the scheduler's native call (record call order with fakes); concurrent `soundFor` still serial.
`capture_cubit_test`: `transcribeFile` receives `hi-IN` when input is `hi`. Integration (device): `integration_test/stt_test.dart`, `tts_test.dart`
extended with hi/bn fixtures.

Verify V7: shared verify + `cd android && JAVA_HOME=… ./gradlew :app:compileDebugKotlin`. Device matrix rows 7–10.

---------------------------------------------------------------------------------------------------
## V8 — Native strings

- `android_alarm_scheduler.dart` `_entries`: `final l = l10n();` add `'doneLabel': l.commonDone, 'snoozeLabel': l.commonSnoozeTenMinutes,
  'channelName': l.notifAlarmChannel, 'channelDescription': l.notifAlarmChannelBody, 'missedChannelName': l.notifMissedChannel`; `missedText` already
  there (now `l.missed(r.title)`).
- `AlarmService.kt`: `"Missed"` → `entry.optString("missedChannelName").ifEmpty { "Missed" }`; `description =
  entry.optString("channelDescription").ifEmpty { "Reminders ringing now" }`; fallback literal `"Snooze 10m"` → `"Snooze 10 minutes"`. Channels are
  re-created with the same ids on every ring (Android updates name and description in place).
- `ios_alarm_scheduler.dart` `_entries`: `'doneLabel'`, `'snoozeLabel'`. `AlarmKitPlugin.swift`: `MemoFire` gets `var doneLabel: String?`, `var
  snoozeLabel: String?`; `MemoAlarms.add`: `let done = fire.doneLabel ?? defaults.string(forKey: "memo.alarmkit.done") ?? "Done"` (same for snooze,
  default "Snooze 10 minutes"); when the fire carries labels, write them to those two `UserDefaults` keys; `AlarmButton(text:
  LocalizedStringResource(stringLiteral: done), …)`. `MemoSnoozeIntent` is unchanged (its re-armed fire has nil labels and reads the stored ones).
- `local_notification_scheduler.dart`: action titles, channel name and description from `l10n()` at `initialize()` / `_details()` (iOS categories
  refresh on next launch; documented limitation).
- iOS files (UTF-8; the owner adds them to the target, Owner steps 3): `ios/Runner/{en,hi,bn}.lproj/InfoPlist.strings` —
  `NSMicrophoneUsageDescription` (en: "Memō records the reminder you speak. It stays on this phone."), `NSSpeechRecognitionUsageDescription`,
  `NSAlarmKitUsageDescription` (en = current text); update the same en texts in `Info.plist`. `ios/Runner/{en,hi,bn}.lproj/Localizable.strings` —
  `"Mark done"`, `"Snooze 10 minutes"`, `"Reminder"`, `"Title"`, `"Sound"`, `"Snooze alarm"`. `Info.plist`: `CFBundleLocalizations` = en, hi, bn.
- Android: `res/xml/locales_config.xml` (`<locale-config>` with en, hi, bn) and `android:localeConfig="@xml/locales_config"` on `<application>`. No
  `strings.xml`.
- New keys: notifAlarmChannel "Alarms" — notifAlarmChannelBody "Reminders ringing now" — notifMissedChannel "Missed".
- Test: `android_alarm_scheduler` entries contain the Hindi labels when the interface pref is `hi` (fake `NativeAlarm` capturing the JSON).
Verify V8: shared verify; owner: `fvm flutter build ios --debug --no-codesign` after the Xcode steps; device: switch App language → lock → alarm
buttons in that language (both platforms).

---------------------------------------------------------------------------------------------------
## V9 — Stabilisation

1. Apply the native-speaker review to `app_hi.arb`, `app_bn.arb`, `*.lproj`; remove `@@x-review`.
2. `README.md`: features, design tokens table, localisation section, "Not in this build"; version `0.2.0+4` in `pubspec.yaml`;
   `test/app_version_test.dart`.
3. `.github/workflows/ci.yml`: add `flutter gen-l10n` + `git diff --exit-code lib/l10n` after `pub get`; `java-version: '21'`.
4. Dead code: `grep -rn "chromeModeOverride\|voice_gender\|timeGuessed" lib` — keep only what is read. Unused ARB keys: for each key, `grep -rn
   "\.key\b" lib`; delete keys with no hit in all three files.
5. Update `integration_test/*` for tap-to-record, the confirmation step and the new alarm buttons.
6. Device QA matrix (owner + implementer, record pass/fail in the PR):

| # | Check | SM-G781B (Android 13) | iPhone iOS 26+ | iPhone iOS 17/18 |
|---|---|---|---|---|
| 1 | Fresh install: onboarding, permissions, battery step (Android) | ✓ | ✓ | ✓ |
| 2 | Update over 0.1.0: stays English, reminders and alarms intact | ✓ | ✓ | ✓ |
| 3 | Type → chips → Continue → confirm → toast; ambiguous "at 8" blocks Save | ✓ | ✓ | ✓ |
| 4 | Tap-to-record, hold-to-record, Cancel, 30 s cap, mic denied → Open Settings | ✓ | ✓ | ✓ |
| 5 | Alarm locked / unlocked / silent / Focus; Done; each snooze option; nag continues | ✓ | ✓ (AlarmKit) | ✓ (notification) |
| 6 | Two reminders same minute; reboot; time-zone change (Phase A regressions) | ✓ | — | — |
| 7 | App language en → hi → bn live; 12h and 24h; digits 0-9; Android per-app language setting | ✓ | ✓ | ✓ |
| 8 | Hindi and Bengali dictation with the pack installed, and without it (failure panel) | ✓ | ✓ | ✓ |
| 9 | Hindi and Bengali title: voice installed → speaks; removed → chime + notice; never English voice | ✓ | ✓ | ✓ |
| 10 | Change Read-aloud voice with 20 reminders: alarms still ring during and after the re-render | ✓ | ✓ | ✓ |
| 11 | Alarm health: each row Fix → deep link → check again; test alarm | ✓ | ✓ | ✓ |
| 12 | Text size 200 %, smallest phone width, dark mode, Reduce Motion, TalkBack / VoiceOver full pass | ✓ | ✓ | ✓ |
| 13 | Native labels (alarm buttons, channel names, Missed, permission prompts) per language | ✓ | ✓ | ✓ |
ADB id `RZCTC0T77MD`. After a killed integration run: `adb forward --remove-all` + force-stop.

---------------------------------------------------------------------------------------------------
## Owner steps (manual, not for the implementer)

1. Before V0 — fonts: from Google Fonts download Noto Sans Devanagari and Noto Sans Bengali, take the static `Regular`, `Medium`, `SemiBold` TTFs of
   each into `assets/fonts/`, copy `OFL.txt` to `assets/fonts/OFL-Noto.txt` (SIL OFL 1.1; the licence text ships through `LicenseRegistry`).
2. Before V8 — rebrand prerequisites (other agent's work, listed for completeness): Apple developer portal bundle id `in.appamania.memo` and App Group
   `group.in.appamania.memo`; Play Console app with the new package id; `USE_EXACT_ALARM` and `USE_FULL_SCREEN_INTENT` declarations.
3. During V8 — Xcode: Runner project → Info → Localizations → add Hindi and Bengali; drag `en.lproj/InfoPlist.strings` and `Localizable.strings` into
   the Runner group (target Runner), File inspector → Localize → tick English, Hindi, Bengali (overwrite any empty copies Xcode makes with the plan's
   files); commit `project.pbxproj`.
4. Before V9 — native-speaker review of both ARB files and the `.lproj` strings (Hindi and Bengali reviewers; pay attention to plural forms, the alarm
   buttons and the confirmation card).
5. Devices for V7 and V9: on the Samsung install Hindi and Bengali on-device speech packs and Google TTS voices (and remove them again for the
   fallback rows); on iPhone Settings → Accessibility → Spoken Content → Voices → Hindi / Bengali.
6. Answer the open questions in `prd.md` §9 (defaults apply otherwise). Q2 and Q4 change scope.
