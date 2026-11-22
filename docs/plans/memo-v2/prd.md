# Memō v2 — revamped design, en/hi/bn, tap-to-record, confirmation, alarm health

Technical PRD. Steps live in `guidelines.md` (same folder). Supersedes Phases B, C, D of `docs/plans/memo-fixes-l10n/` (Phase A is shipped in
e0a1193). Baseline: branch `dev`, 265 tests, Flutter 3.47.8 via `fvm`, package id `in.appamania.memo` (rebrand is another agent's work, assumed done).

Sources read: `README.md`, old plan, `lib/l10n/strings.dart` (class `S`), all of `lib/`, Kotlin and Swift plugins, design system `tokens.json` +
README + 17 component READMEs, 45 canvas boards.

## 1. Problem

1. The shipped UI contradicts the revamped design: hold-only mic, no confirmation step, a time the parser guessed is scheduled without asking,
   slide-to-done alarm, "10m"/"Del" labels, dead Settings rows, accent and ink-45 used as small text below contrast.
2. English only. Strings are compile-time constants (`S`), dates are hand-formatted and forced to 24h, speech-to-text and the voice are hard-wired to
   English on both platforms.
3. Nothing tells the user why an alarm might not ring (battery restriction is not even checked).

## 2. Scope: ten phases, each shippable to `dev` on its own

| Phase | Ships | Depends on |
|---|---|---|
| V0 | Tokens (accent-text, caution, ok, alarm-title, button-large), Noto fallback fonts, contrast fixes, section-label rule | — |
| V1 | ARB + `flutter_localizations` + `intl`, `S` removed, `AppSettingsCubit`, three language prefs, intl date/time, Western digits, App language picker | V0 |
| V2 | Capture: live chips → Continue → `ReminderConfirmation`; ambiguity blocks Save; tap-to-record with recording / processing / failure panel; one success toast | V1 |
| V3 | Alarm screen with Done + Snooze buttons, snooze sheet, Detail page | V1 |
| V4 | Home (summary, Next line, row menu, full-word swipe labels), Archive, Editor basic/advanced, motion, large text and 320 px | V3 |
| V5 | Settings reorganised, Alarm health + remediation + test alarm, Android battery onboarding step | V1 |
| V6 | Parser rule tables for Hindi and Bengali (native script, Latin, numerals, number words) | V2 |
| V7 | Locale-aware STT and TTS, playback policy, atomic rendered audio, Speaking language and Read-aloud voice settings | V6 |
| V8 | Native strings (Android entries, AlarmKit labels, `.strings`, locale config) | V1 |
| V9 | Stabilisation, README, CI checks, device QA matrix, translation review applied | all |

Order changes against the suggested V0–V8, with reasons:
- Suggested V3 is split into V3 (alarm, snooze, detail) and V4 (home, archive, editor, motion): one review per risk area; the alarm path must not wait
  on list polish.
- Speaking-language and Read-aloud-voice rows land in V7, not with the Settings reorg (V5): a row that changes nothing is the dead row the design
  tells us to remove. Prefs are persisted from V1.
- The English half of the parser ambiguity API lands in V2 because the confirmation step needs it; V6 only adds tables.
- V8 depends only on V1 and may be pulled forward any time.

### v1-implementable now vs planned (document only)

| Design item | Status |
|---|---|
| Tokens, fonts, Splash mark, Onboarding (welcome, primer, Android battery step) | Build |
| Home list/empty, Capture typing, Confirm (valid, ambiguous), Voice recording/processing/success/failure | Build |
| Editor basic + advanced, Detail one-off, Detail recurring (without "This week 5 of 6 done") | Build |
| Alarm (Memō screen, both platforms), Snooze sheet, Archive list/empty | Build |
| Settings main, Languages, Read-aloud voice, Alarm health OK / restricted / fix, Test alarm | Build |
| Hindi and Bengali boards, 200 % text, 320 px | Build |
| iOS AlarmKit alert | OS-drawn. Memō sets title, tint, two button labels, sound. Nothing else is designable |
| "This week 5 of 6 done", Future-History | Planned (needs per-occurrence history, a schema change) |
| EscalationSelector profiles, Share to Memō, Quick templates, Backup/restore, Widgets, Siri card | Planned |
| Photo capture (camera button, Capture-Image) | Stays behind `FeatureFlags.imageCapture` (off) |
| "Snooze choices" setting | Not built (see Q4) |
| Splash text "Nothing leaves this phone" | Not built: native launch screen carries the mark only |

## 3. Non-goals

- Languages beyond en/hi/bn, RTL, native-digit display, translating the brand "Memō".
- Translating or rewriting anything the user wrote. Titles stay verbatim; no inflection clean-up (the design's "दवाई लेने की…" → "दवाई लेना" example
  is not achievable with rule tables).
- Cloud speech or cloud voices, ever. No language auto-detection for dictation.
- DB migration. No per-reminder language column (script of the title decides, see 5.6).
- Changes to reminder ids, alarm id scheme (`AlarmIds`), recurrence maths (`RepeatRule`, `fire_plan`), or the meaning of existing native entry fields.
  Native additions are new optional fields and new channel methods only.
- Kotlin/Swift unit-test infrastructure; native work is verified on devices.
- Redesigning OS surfaces: AlarmKit alert, permission prompts, system pickers.

## 4. Requirements

### 4.1 Design system (V0)
- `design/tokens.json` matches the design system; `lib/core/theme/tokens.dart` is regenerated; `gen_tokens --check` and the `Color(0x` grep stay
  green.
- `accent` is never small text: text, links, the mic fill and overdue times use `accent-text`. `ink-45` is never text: labels, placeholders and done
  titles use `ink-70`.
- Font stack: Instrument Sans → Noto Sans Devanagari → Noto Sans Bengali; mono styles carry the same fallback. Uppercase tracked `label-small` is
  Latin only; Hindi and Bengali headers are 13/500 sentence case, no tracking.
- Status pill tints: design draws `#E4F2EA` for ok, which is not a token. Plan: token colour at 12 % alpha for ok, `caution-soft` and `accent-soft`
  for the others. No literals outside `tokens.dart`.

### 4.2 Localisation (V1, V8)
- `flutter_localizations` (SDK) and `intl: 0.20.3` (the version the 3.47.8 SDK resolves; verified in `pubspec.lock` and
  `flutter_localizations/pubspec.yaml`).
- `lib/l10n/app_{en,hi,bn}.arb`; ARB key = old `S` member name, so the call-site rewrite is mechanical. ICU plurals; whole sentences, never glued
  fragments.
- `AppPrefs`: `interfaceLocale` (`system|en|hi|bn`), `inputLocale` (`en|hi|bn`), `playbackLocale` (`follow|en|hi|bn`). Seeded once at first run of the
  new build: installs that already finished onboarding get `en / en / follow` (nothing changes for them); fresh installs get `system / <resolved
  interface language> / follow`.
- `AppSettingsCubit` (root) drives `MaterialApp.locale` and `themeMode`. No `setState` for either.
- Dates through `intl` in the interface language. Times always `h:mm a` or `HH:mm` by the device 12/24h setting, formatted with the `en` pattern, so
  digits and AM/PM are Latin in every language (as the Hindi and Bengali boards draw rows and the alarm clock).
- Digits 0-9 everywhere: `DateFormat.useNativeDigitsByDefaultFor('bn', false)` plus a patched `numberFormatSymbols['bn']` (zero digit `0`) before any
  delegate loads. Covers Material pickers.
- Native strings: see 5.5.

### 4.3 Capture and confirmation (V2)
- Idle bar: field, mic, camera only when `imageCapture`. Hint under the bar: "Type, or tap the mic and speak".
- Typing: chips Date, Time, Repeat (tap to edit) and a Continue button. Keyboard action = Continue.
- `ReminderConfirmation`: original text verbatim ("You wrote: …" / "You said: …"), interpreted title, When and Repeat rows (Tag row only when a tag
  was parsed), Save reminder, Edit details.
- Unsure time: `UnsureTimeBlock` with badge "Confirm time", the question, a one-line reason quoting the user's words, option buttons and "Other
  time…". Save reminder is disabled until one is chosen. Applies to: bare hour ("at 8", "8:30"), no time at all, and (V6) Hindi/Bengali day words that
  can point either way. Nothing is scheduled from a guess.
- After save, one toast (`liveRegion`): "Reminder set for tomorrow at 6:00 PM."

### 4.4 Voice (V2, V7)
- Tap the mic to start, Stop to end; Cancel discards. Press-and-hold still works: a press shorter than 300 ms latches into tap mode, a longer one
  stops on release. Screen-reader `onTap` toggles.
- Recording panel: steady dot + the word "Recording", `0:06 / 0:30`, 7-bar meter driven by real input level, 88 px Stop, Cancel, tip about hold. The
  mic widget keeps its tree slot (see 5.3).
- Processing: loader, "Understanding your recording", "On this phone, in {language}. Nothing is sent anywhere.", Cancel.
- Success → confirmation with "You said: …". Failure keeps the clip: Type it instead / Save as voice note, pick a time / Try again.

### 4.5 Alarm (V3)
- Memō alarm screen (Flutter route `/alarm/:id`; Android full-screen intent and iOS in-app): header, late text, clock, title in `alarm-title`, note,
  repeat line, "Reading aloud in {language}" line, voice-note control, Done (primary, 64 px, `button-large`) and Snooze (secondary, 64 px).
- Snooze sheet: "Snooze 10 minutes", "Snooze 1 hour", "Tomorrow, same time", each with the resulting time in mono, plus "Pick a time".
- Slide-to-done is deleted. No gesture is the only way to do anything.
- Notification / AlarmKit quick Snooze stays 10 minutes (native contract unchanged); its label becomes the full sentence.

### 4.6 Home, Detail, Archive, Editor (V3, V4)
- Home: summary line, a typographic "Next" line (no card), full-word swipe labels (72 px actions), long-press row menu (Mark done, Snooze 10 minutes,
  Edit, Delete), same actions for screen readers, titles wrap to 3 lines, no fixed heights that clip at 200 % text or 320 px.
- Detail: Mark done (recurring: "Mark done for today" + where it moves), Snooze (same sheet), Delete reminder.
- Archive: labelled search, day groups, Reopen, new empty state.
- Editor: basic (What, When, Repeat) and "More options" (note, tag, remind me earlier, if I don't respond, sound, read title aloud).

### 4.7 Settings and alarm health (V5, V7)
- Sections: Reminders, Language and voice, Alarm reliability, Appearance, About. Removed: Phase 2 rows, static Appearance row, Glass chrome row,
  Capture section.
- Alarm health: one `PermissionStatusRow` per thing that affects ringing, pill Allowed / Fix / Off, remediation step with a deep link and "I changed
  it, check again", refresh on resume, test alarm. Copy never promises delivery and never says a test "rang".
- Android battery restriction is read natively (`PowerManager.isIgnoringBatteryOptimizations`) and fixed through the app's system settings page. No
  new manifest permission.

### 4.8 Parser (V2, V6)
- All existing English tests pass unchanged. `ParsedReminder` gains `ambiguity` (additive).
- Hindi and Bengali are const tables consumed by one generic pass after the English rules. Native script always active; Latin transliteration active
  only when hi or bn is the input or interface language (so English users never see "sham" become 18:00).
- Devanagari and Bengali digits are normalised 1:1 before matching; number words and half/quarter words are matched through lookup groups, never by
  rewriting the text. Offsets stay UTF-16 offsets into the original string; lowering is ASCII-only so length never changes.

### 4.9 STT and TTS (V7)
- STT tag from `inputLocale`: `hi-IN`, `bn-IN`, or the device's English (`en-IN` fallback). `available(tag)` → `installed | downloadable |
  unavailable` on both platforms. On-device only.
- TTS voice chosen by language; spoken templates are ARB sentences in the voice's language.
- Rendered audio: cached by a hash of voice + language + text; rendered to a temp file and renamed; older renders are pruned only after the alarm was
  re-registered. A language or voice change triggers one `SyncAlarms`; unchanged reminders hit the cache.

## 5. Key decisions (problem → options → pick)

5.1 **String access without a BuildContext** (cubits, schedulers, background isolate). Options: (a) pass `AppLocalizations` into every cubit; (b) emit
error codes and map in widgets; (c) one global `l10n()` that resolves the locale from `AppPrefs`. Pick (c): mechanical migration, works in the iOS
background isolate, ~10 lines.

5.2 **Where ambiguity lives.** Options: (a) recompute in the cubit from spans; (b) parser returns it. Pick (b): the parser already knows `ambiguous`;
one optional field, English `dueAt` unchanged.

5.3 **Recording UI container.** Options: (a) modal sheet route; (b) in-tree overlay in the Home `Stack`. Pick (b): a route above the mic risks the
known lost-release bug (memory note: the mic must keep its slot); the overlay only looks like a sheet.

5.4 **Time format.** Options: (a) `DateFormat.jm(locale)` (hi gives "am", bn "AM", digits vary); (b) fixed `en` pattern everywhere. Pick (b): one
line, Latin digits guaranteed, matches the boards.

5.5 **Native strings.** Options: (a) Dart passes localised labels in each alarm entry; (b) native resource files following the OS language; (c)
Android `LocaleManager` per-app locale (no iOS equivalent for a running app). Pick (a) again: follows the in-app language, one source (ARB), survives
reboot because entries are stored. Static texts that cannot be passed (Info.plist usage strings, App Intent titles) use `.strings` and follow the
device language. AlarmKit labels for a natively re-armed snooze are read from `UserDefaults` written at schedule time (no intent changes).

5.6 **Playback language vs reminder language.** A voice only reads text it can pronounce. `script(title)`: Devanagari → hi, Bengali → bn, otherwise
Latin.
- Native-script title → wanted voice = that language, whatever the pref says.
- Latin title → wanted voice = `en` under "Follow reminder", else the chosen language.
- Wanted voice installed offline → speak, template in that language.
- Else, in order: the reminder's voice note (Android rings it after the chime; iOS plays it when the alarm screen opens), else chime with the title on
  screen. In every fallback case the confirmation card, Detail and Read-aloud settings say so: "No Bengali voice on this phone. It rings with the
  chime." Bengali is never read with an English voice.

5.7 **Test alarm.** Options: (a) unsaved reminder (alarm screen would show "no longer exists"); (b) real reminder with fixed id `memo-test`. Pick (b):
rings through the exact production path, upsert keeps a single row, user marks it Done like any other.

5.8 **Root reactive state.** One `AppSettingsCubit` for locale prefs and theme, not two cubits.

## 6. Acceptance checks

Every phase: `dart format` clean, `flutter analyze` clean, `flutter test` green with test count ≥ previous, `gen_tokens --check`, no `Color(0x`
outside `tokens.dart`, debug APK builds on JDK 21.

- V0: Hindi and Bengali sample text renders in Noto in sans and mono styles; mic fill and text buttons are `accent-text`; no `ink45` in any
  `TextStyle`.
- V1: switching App language re-renders every screen at once; a device set to 12h shows "8:30 PM", 24h shows "20:30"; Bengali UI shows 0-9 in dates,
  counts and pickers; an existing install updated in place stays English; `lib/l10n/strings.dart` is gone; ARB parity test fails on a missing key.
- V2: "Call mum tomorrow at 8" → confirmation shows the unsure block and Save is disabled until 8:00 AM / 8:00 PM / Other time is chosen; "…at 8 AM"
  saves in two taps; tap mic → Stop → confirm; hold still works; a failed transcription keeps the clip and offers the three choices; one toast.
- V3: alarm shows two labelled buttons; Snooze sheet shows resulting times; Done and each snooze act on the right reminder and stop native ringing; no
  `SlideToDone` symbol left.
- V4: every swipe action is reachable by long-press menu and screen reader; Home, Confirm, Alarm throw no overflow at text scale 2.0 and at 320 px
  width (widget tests).
- V5: Samsung with battery "Restricted" shows Fix; after choosing Unrestricted and "check again" the row turns Allowed; test alarm rings ~10 s later
  over the lock screen.
- V6: "कल सुबह 8 बजे दवाई" → tomorrow 08:00 with the day-word confirmation; "kal 8 baje" → both day and AM/PM asked in one block; "কাল সকাল ৮টায়
  ওষুধ" → 08:00; "buy rat poison" → no time; English suite unchanged.
- V7: Hindi dictation on a phone with the hi-IN pack; without it, the failure panel names the reason; a Bengali title on a phone without a Bengali
  voice rings with chime and says so beforehand; killing the app mid-render never leaves an alarm pointing at a missing or partial file.
- V8: Android alarm buttons, channel names, "Missed" text and AlarmKit buttons follow the in-app language after the automatic re-sync; iOS permission
  prompts follow the device language.
- V9: device matrix (guidelines) signed off by the owner.

## 7. Architecture audit

| Component | Problem | Fix | Risk | Severity |
|---|---|---|---|---|
| `reminder_parser.dart` Combine | Bare "at 8" silently becomes the next 8:00 or 20:00 and is scheduled | Expose `ambiguity`; confirmation blocks Save | Capture tests change | High |
| `reminder_parser.dart` `toLowerCase()` | Can change string length for non-ASCII input, shifting spans | ASCII-only lowering | None for ASCII input | Medium |
| Parser `\b` boundaries | Not Unicode-aware; useless for Devanagari/Bengali | Explicit `\p{L}\p{M}\p{N}` look-arounds for pack rules | Regex cost (still sub-ms) | Medium |
| `S` / `date_format.dart` | Compile-time English, forced 24h | ARB + intl | Wide mechanical diff | Medium |
| `TtsPlugin.kt` / `.swift` | Voice filter hard-coded to English; a Hindi title is read by an English voice | Language parameter, no cross-script speech | Voice inventory differs per OEM | High |
| TTS `render` | Deletes older renders before the new one exists and before alarms are re-registered | Temp file + rename; prune after schedule | A few stale files until next sync | Medium |
| `SttPlugin.kt` / `.swift` | Locale hard-coded (device English / en-US) | Tag from `inputLocale` | Pack availability varies | High |
| `capture_bar.dart` `_Mic` | Hold-only, `Semantics` has no `onTap`: unusable with TalkBack/VoiceOver or switch control | Tap default, hold optional | Tap/hold timing | High (a11y) |
| `alarm_page.dart` | Slide gesture is the primary action; snooze labels "10m", "1h" | Buttons + sheet | None | Medium (a11y) |
| Theme | `accent` (3.05:1) and `ink-45` (2.95:1) used as small text | `accent-text`, `ink-70` | Visual shift | Medium (a11y) |
| Fixed heights (bar 60, chips 46, buttons 50) | Clip at 200 % text | `minHeight` constraints | Layout shifts of a few px | Medium |
| `settings_page.dart` | Dead rows; battery restriction never checked | Reorg + Alarm health | New native method | Medium |
| `app.dart` root | Reads prefs directly, nothing reactive | `AppSettingsCubit` | Small | Low |
| Kotlin / Swift labels | English literals ("Done", "Snooze 10m", "Missed") | Dart-passed labels | Stale until next sync (automatic) | Low |
| iOS notification categories | Registered once at init; titles stale after a language change until relaunch | Accepted limitation, documented | iOS < 26 only | Low |
| Voice note | Never rings natively although capture copy suggests it | Android: used as fallback sound (5.6) | iOS unchanged | Low |
| CI | Builds with JDK 17, local builds use JDK 21 | Move CI to 21 in V9 | None | Low |
| SQLite | — | No migration needed | — | — |

## 8. Risks

- hi/bn copy is machine-drafted (design boards cover about 25 strings) until a native speaker reviews.
- Latin transliteration collides with English words; mitigated by gating (4.8) and number adjacency.
- On-device Hindi/Bengali STT and offline voices are missing on many phones; the product must read as honest, not broken (failure panel, per-option
  availability).
- `numberFormatSymbols` patch is global mutable state; must run before `runApp` and in the iOS background isolate (`configureDependencies`).
- AlarmKit: whether tapping the system alert opens Memō's alarm screen is unverified; the plan does not rely on it.
- Blocking Save on every "कल" adds a tap to the most common Hindi phrase (see Q2).
- pbxproj edits (localisations, `.strings` membership) are done by the owner in Xcode.
- Design inconsistencies resolved in favour of the system README and v2 boards: AlarmOverlay and CaptureBar READMEs still describe slide-to-done and
  hold-only; Sheet README says glass (v2 boards and principle 5 say solid); Toast README says "no other toasts" (README adds the success toast); Hindi
  home hint says "माइक दबाकर" (press) where the behaviour is tap.

## 9. Open questions (default applied if unanswered)

1. Existing installs stay English after the update even on a Hindi device (default: yes, per brief).
2. Hindi/Bengali "कल / কাল / परसों / পরশু" block Save until confirmed (default: yes, binding rule "never silently guess"). Alternative: treat as
   future, highlight the When row, no block.
3. Times in sentences: design shows "शाम 6:00" in the Next line and When row but "6:00 PM" in rows and the clock. Default: "6:00 PM" everywhere in v1.
4. "Snooze choices" setting: quick snooze is fixed at 10 minutes in Kotlin and in the iOS App Intent. Default: no setting in v1 (it would be a native
   contract change with no defect behind it).
5. Voice gender (Female/Male) is not in the new design. Default: keep it, inside Read-aloud voice, applied to English voices only.
6. Archive empty copy says "for 30 days" but nothing purges. Default: drop the clause; never delete user data without a decision.
7. Help row: no content or URL exists. Default: omit until there is one (avoids a new dependency).
8. iOS voice-note fallback: replace the chime with the raw clip natively? Default: no; chime rings, the clip auto-plays when the alarm screen opens.
9. Status pill tints are not tokens (4.1). Default: derive from tokens; ask the designer for `ok-soft` later.
10. Done titles: design CSS still draws them in ink-45. Default: ink-70 + strike-through (token rule).
11. Test alarm leaves a "Test alarm" entry in Done. Default: acceptable.
12. A parsed `#tag` shows as an extra row on the confirmation card (not on the board). Default: yes, otherwise the tag is saved unseen.
