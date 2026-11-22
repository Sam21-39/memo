# Memō 0.2 — Fixes, localization (en/hi/bn), language-aware capture, UI polish

Technical PRD. Owner decisions in the task brief are final and are not repeated as questions.
Implementation steps live in `guidelines.md` (same folder). Each phase ships on its own.

Baseline (dev @ cfc8625): `fvm flutter analyze` clean, `fvm flutter test` 221 pass.

## 1. Problem

1. Data-loss and silent-failure bugs: a voice clip deleted by "More", a second alarm that
   replaces the first, a timed-out alarm that leaves no trace, a swipe delete with no undo,
   cubits stuck in "saving" after an exception, reopened reminders that never ring, parser
   dates that roll over silently, a `needsSchedule` flag cleared before scheduling succeeds,
   overlapping TTS renders, "2h late" text that never refreshes, repeats that shift hours
   after a time-zone change.
2. The app is English-only with forced 24h time; the India market needs Hindi and Bengali UI,
   parser, dictation and voice, with fonts that render both scripts.
3. The UI is static: no motion feedback, sub-44 touch targets, dead Settings rows, a
   hold-only mic that screen-reader users cannot operate.

## 2. Scope by phase

### Phase A — Bugs (A1–A12)
| Id | Fix (one line) |
|---|---|
| A1 | EditCubit uses `draft`/`draftClip`; it never deletes a draft it inherited; capture re-checks the draft after "More"; `commitVoice` result decides `hasVoice` in both cubits. |
| A2 | CaptureCubit takes `defaultNagMin` / `readAloudDefault` as getters (EditCubit is built per sheet open, so it already reads live values). |
| A3 | AlarmService rings one reminder at a time and queues the rest; each reminder gets its own notification id and PendingIntent request codes, so nothing is replaced. |
| A4 | On the 2-minute timeout AlarmService posts a dismissible "Missed: <title>" notification that opens the reminder. |
| A5 | Home swipe-delete is a soft delete with a 5 s Undo toast; Detail keeps its confirm dialog. |
| A6 | Every cubit write path catches all exceptions, restores state, shows an error. |
| A7 | `ReopenReminder` use case: a done one-off with a past `dueAt` moves to the next whole hour, nags/snooze reset, then rescheduled. |
| A8 | Parser: same-day weekday rolls a week when past; invalid dates ignored (29 Feb → next leap year when no year given); "in N months/years"; bare ordinals "the 5th"; past one-off save blocked with a clear message. |
| A9 | SyncAlarms clears `needsSchedule` only after `syncAll` succeeds. |
| A10 | SpokenReminder serializes renders through a Dart async queue. |
| A11 | One shared `MinuteClock` ticker (paused in background) rebuilds Home, Alarm and Detail time text. |
| A12 | Repeats keep wall-clock time across a time-zone change (Clock-app behaviour): Kotlin re-walls stored repeat entries on `TIMEZONE_CHANGED`; Dart re-walls repeat `dueAt` on the next catch-up. `TIME_SET` keeps today's behaviour (epoch instants are already right). |

### Phase B — Localization foundation
- `flutter_localizations` (SDK) + `intl: 0.20.3` (the exact version the SDK's
  flutter_localizations requires and pubspec.lock already resolves).
- `l10n.yaml`, `lib/l10n/app_{en,hi,bn}.arb`, generated `AppLocalizations`, ICU plurals.
- Every user-visible string in `lib/` moves to ARB. Non-widget code uses one helper `l10n()`.
- `date_format.dart` rewritten on `intl` `DateFormat`, locale-aware, device 12/24h
  (`MediaQuery.alwaysUse24HourFormatOf`). Pickers follow the device setting.
- Western digits everywhere: patch intl's `bn` number symbols to ASCII zero at startup.
- `AppPrefs.languageOverride` ('system'|'en'|'hi'|'bn') + `AppPrefs.revision` notifier;
  MaterialApp rebuilds on change. Settings → Language sheet (System / English / हिन्दी / বাংলা).
- Native strings: **approach = Dart passes localized strings in each fire entry** (see §5).
  iOS App Intent titles and Info.plist usage texts use `.strings` files (static, cannot be passed).
- iOS `CFBundleLocalizations` + `InfoPlist.strings` / `Localizable.strings` for en/hi/bn.
- Android `android:localeConfig` + `res/xml/locales_config.xml` (per-app language in system settings).
- Fonts: Noto Sans Devanagari + Noto Sans Bengali (SIL OFL 1.1) bundled as `fontFamilyFallback`
  through the token generator.
- Test fails if any locale lacks a key or a placeholder.

### Phase C — Language-aware parser, STT, TTS
- `parseReminder(..., language:)`; English rules unchanged; one data table per extra language
  (hi, bn), each with native-script and Latin words. App language pack first, then the other,
  so mixed input works. Native digits in input (STT output) are normalized to ASCII first.
- STT: Dart picks the tag (`hi-IN`, `bn-IN`, device English or `en-IN`); `available(tag)` returns
  `installed | downloadable | unavailable` on both platforms.
- TTS: voice chosen by language; spoken template from ARB in that language; no voice → `null`
  → chime only (never a Hindi title in an English voice). Speech language = script of the
  title (Devanagari → hi, Bengali → bn) else app language.
- Settings shows the real dictation language and per-language voice/dictation availability.

### Phase D — UI/UX polish
- Motion spec per interaction (see guidelines D-table), all through `MemoMotion` tokens, all
  zero-duration under `MediaQuery.disableAnimationsOf`.
- Settings: Appearance works (System/Light/Dark), Glass chrome works (iOS only), Phase 2 rows removed.
- Tap-to-record alongside hold; Semantics `onTap` on mics.
- Touch targets ≥ 44 (capture chips, TagChip, RepeatSegmentedControl, WeekdaySelector).
- Onboarding copy per platform/flags; notifications-off banner on Home; "Open Settings" on mic
  denial; correct recording hint without dictation; full-word swipe labels; case-insensitive tags;
  iPhone locked to portrait; hint copy says "Tap or hold".

## 3. Non-goals
- Languages other than en/hi/bn; RTL; native-digit display; translated brand name (stays "Memō").
- Per-occurrence history, monthly repeats, sync, widgets, Siri/Assistant, photo capture.
- Parser ML or a generic NLP framework; Hindi fractional times ("saade 8", "sava 8") — add later.
- Re-registering iOS notification categories mid-session after a language change (takes effect
  on next launch; AlarmKit and Android labels update on the immediate re-sync).
- Kotlin/Swift unit-test infrastructure (native changes are verified on device).
- Separate dictation-language setting (dictation follows app language).

## 4. Acceptance checks
Per phase, all of: `fvm flutter analyze` clean · `fvm flutter test` green (≥ 221 + new) ·
`fvm dart format --output=none --set-exit-if-changed .` · `fvm dart run tool/gen_tokens.dart --check` ·
`! grep -rn 'Color(0x' lib | grep -v lib/core/theme/tokens.dart`.

Phase A
- "More" from a typed capture opens the form prefilled (title, time, repeat, tag, read-aloud, clip);
  Cancel keeps the clip chip playable; Save stores the clip on the new reminder.
- A missing draft file never yields `hasVoice: true`.
- Changing Default nag / Read aloud in Settings applies to the next capture without restart.
- Android, two reminders at the same minute: both notifications visible, both ring in turn,
  Done on either acts on the right reminder. Unanswered for 2 min: "Missed: <title>" stays
  in the shade; tapping opens Detail.
- Swipe Delete hides the row, shows "<title> deleted · Undo" for 5 s; Undo restores; otherwise
  the row and alarms are gone. Detail still confirms.
- Forcing a repository throw in each cubit leaves the UI interactive with an error message.
- Reopening a done one-off from Archive or Detail gives a future time and rings.
- Parser: "by friday" on Friday 14:30 → next Friday 09:00; "29 feb 2027" ignored; "29 feb" →
  next leap year; "31/04" ignored; "in 2 months" / "in 1 year" / "the 5th" parse.
- Edit sheet: a new one-off in the past cannot be saved and says why.
- SyncAlarms with a failing scheduler leaves `needsSchedule` set.
- Concurrent `soundFor` calls never overlap on the channel.
- Home "12 min late" updates each minute while open; no timers survive dispose.
- Android, change time zone with a daily 07:00 repeat: it still rings at 07:00 local.

Phase B
- Switching Settings → Language to हिन्दी / বাংলা re-renders every screen without restart;
  "System" follows the device. No English left on any screen (except the endonym list).
- 12h device shows "8:30 PM"-style times in lists, chips, pickers; 24h device shows "20:30".
- Bengali shows Western digits in times, dates, counts, pickers.
- Android alarm buttons, channel name, missed text and iOS AlarmKit buttons are in the app language.
- iOS permission prompts are in the device language for en/hi/bn.
- Devanagari and Bengali glyphs render in Noto (not tofu, not system font mix) in sans and mono styles.
- `test/l10n_keys_test.dart` fails when a key or placeholder is missing in any ARB.

Phase C
- "kal subah 8 baje dawai" → tomorrow 08:00, title "Dawai"; "कल सुबह 8 बजे दवाई" same;
  "kal shokal 8 ta" → tomorrow 08:00; "har somvar" → weekly Mon; "protidin" → daily;
  "call mom kal 8pm" (en app) → tomorrow 20:00. Existing English tests unchanged.
- Hindi dictation works on a phone with the hi-IN on-device pack; without it, the clip saves as
  "Voice note · 0:08" (localized) and Settings says why.
- A Hindi reminder rings in a Hindi voice when installed; otherwise chime only and Settings says so.

Phase D
- Each animation in the D-table plays at its token duration and is instant with reduce motion.
- All listed targets measure ≥ 44×44 in widget tests; hold-to-record tests still pass; tap-to-record works.
- Appearance changes theme live; Glass chrome toggles on iOS; no "Phase 2" rows.

## 5. Key design decisions
- **Native strings via Dart.** The in-app language picker overrides the device language; native
  `values-xx` / `Localizable.strings` follow the OS, not the app. Passing strings in each fire entry
  (Android: `doneLabel`, `snoozeLabel`, `channelName`, `missedText`; iOS AlarmKit: `doneLabel`,
  `snoozeLabel`) keeps one source (ARB) on both platforms and survives boot (entries are stored).
  Exceptions that cannot be passed: iOS App Intent `title`s and Info.plist usage strings →
  `.strings` files. Android needs no `strings.xml` (label is the brand, unchanged).
- **Soft delete** lives in HomeCubit state (`pendingDelete`), not the DB: killing the app inside the
  5 s window keeps the reminder (safe direction).
- **A12 wall-clock** for repeats only; one-offs keep their instant.
- **Parser packs** are const tables (`ParserPack`) consumed by one generic pass after the English rules.
- **`l10n()`** global lookup for cubits/data (no BuildContext) mirrors Flutter's locale resolution.

## 6. Risks
- Machine-quality hi/bn copy until a native speaker reviews (owner step).
- intl symbol patch for `bn` is global state; must run before any `DateFormat`/`NumberFormat`
  (both main isolate and iOS background isolate) — covered by calling it in `configureDependencies`.
- Android per-language on-device STT availability varies by OEM; Samsung may report no hi/bn pack.
- iOS on-device recognition for bn-IN likely unavailable; Hindi voice exists (Lekha), Bengali voice may not.
- Alarm queue (A3) is in-memory in a foreground service; if the OS kills the service, queued
  reminders still have their posted notifications and nags.
- Soft delete: an alarm due inside the 5 s window still rings once.
- A12 relies on the process seeing the new default zone; Dart re-wall uses the `timezone` package,
  not VM local time.
- pbxproj localization edits are done in Xcode by the owner (not by Haiku) to avoid corrupting the project.
- Height changes for 44 pt targets shift layout by a few px; widget tests that tap by text still pass.
- `MemoMotion` says "nothing bounces"; Phase D uses no overshoot curves.
- Latin transliterations collide with English words (dropped `rat`; units, clock suffixes and postpositions such as
  `din`, `me`, `ta`, `mein` only match right after a number; day words like `kal`, `aaj` match alone). Expect a few false positives; tests pin the known ones.
- Android `startForegroundService` for a queued second alarm must still be answered by `startForeground` (A3 step covers it).

## 7. Open questions (defaults applied if unanswered)
1. A12: repeats follow local wall-clock after a time-zone change; one-offs keep the instant. (Default: yes.)
2. Native-digit input (e.g. "৮টা" from STT) is normalized to 0-9 before parsing; display is always 0-9. (Default: yes.)
3. RepeatSegmentedControl and WeekdaySelector grow visually 36 → 44 (simplest; hit area = visual).
   Chips keep 30/34 visual with an invisible 44 hit area. (Default: yes.)
4. Swipe action width 52 → 72 to fit full words ("Snooze", "Delete", स्नूज़, মুছুন). (Default: yes.)
5. Android stays rotatable (decision only locks iPhone). (Default: yes.)
