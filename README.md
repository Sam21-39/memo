# Memō

A reminder app that lives on your phone. Type it or say it, and the phone rings like an alarm at that time, reading the reminder aloud. No account, no cloud, works with no signal, rings even when the app is closed.

Version 0.3.0 (build 5) · iOS 17+ and Android 8+ · Flutter 3.47.8 · bundle and package id `in.appamania.memo`

## What it is

Memō is for the things you keep forgetting: bins, pills, that call. You say or type one line, and the phone rings at that time until you deal with it.

Everything stays on the device. Speech is turned into text on the phone, and the app's voice is generated on the phone. Nothing is sent anywhere. There is no sign-up, no sync, no analytics.

Hindi and Bengali text in the app is a draft: it has not yet been reviewed by native speakers (the ARB files carry an `@@x-review: pending` marker until it is). Treat it as unreviewed.

## What it does

**Capture**

- Type into the bar at the bottom: "Pills at 8 tonight every day #health" becomes chips for the time (20:00), repeat (Daily) and tag. Press Continue to reach the confirmation step.
- Tap the mic, speak, tap again to stop (hold also works; 30 s cap, Cancel while recording). The recording is transcribed on the phone and becomes the title and chips. If nothing is recognised it saves as "Voice note · 0:08". A denied microphone shows an Open Settings action.
- Confirmation step: a card shows what will be saved. When the parser cannot tell (for example "at 8" with no AM or PM, or a bare "kal"), the card shows a "Confirm time" block with options and Save stays disabled until one is chosen. Saving shows one toast.
- Quick start: on an empty bar, five chips (Take medicine, Pay a bill, Call someone, Follow up, Weekly routine) prefill the text; the normal parser and confirmation run unchanged.
- Share to Memō (Android and iOS): share text from any app. On Android, Memō opens its confirmation card. On iOS the share extension only queues the text; open Memō to see the card (needs the one-time Xcode setup, not yet done). Nothing is saved until you tap Save.
- Tap any chip to fix it, or "More options" for the full form.

**Reminders**

- Title, note, date, time, repeat (none, daily, weekly, custom weekdays), one optional tag.
- Nag: rings again every 10 minutes (or any interval) up to 6 times until marked done.
- Pre-alarm: an early heads-up 5, 15, 30 or 60 minutes before.
- Read aloud: when it rings, the app's own voice says "Reminder. Take your pills." between chimes, in the language of the reminder when a voice for it is installed (see Languages).

**Ringing**

- Alarm screen with a large clock, the title, and two labelled buttons: Done (primary) and Snooze (secondary). Snooze opens a sheet with "Snooze 10 minutes", "Snooze 1 hour", "Tomorrow, same time" (each with the resulting time) and "Pick a time". No slide gesture.
- iPhone (iOS 26+): a real alarm (AlarmKit), full screen on the lock screen, through silent mode and Focus, with Done and Snooze 10 minutes. The AlarmKit alert itself cannot be redesigned. Older iOS uses Time Sensitive notifications.
- Android: full screen over the lock screen, the chime and voice looping until Done, Snooze or 2 minutes. With "Take over the screen" allowed it also fills the screen when the phone is unlocked.
- Done and Snooze work from the alarm without opening the app.

**Upcoming list**

- Repeats keep a history on their Detail page: "This week N of M done" and the last 90 days. An occurrence nobody answered reads "Not marked done".
- Grouped by day: Today, Tomorrow, then dates. Overdue reminders sit at the top in a tinted card with "2h late".
- Tap the circle or swipe right to mark done; one-offs get a 5-second Undo. Swipe left for Snooze and Delete, long-press for a menu.
- Completing a repeat moves it to its next time. Snoozing a repeat moves only that one time, never its schedule.
- Filter by tag. Done archive with search and Reopen. Detail page with Mark done, Snooze and Delete.

**Settings**

Sections: Reminders, Language and voice, Alarm reliability, Appearance, About.

- Alarm health: one row for each thing that affects ringing (notifications, exact alarms, full-screen alarms, take over the screen, Android battery restriction). Each shows Allowed, Fix or Off, opens the right system page, and has "I changed it, check again". A test alarm rings through the real production path; mark it Done like any reminder.
- Defaults for nag and read aloud; theme.
- Language and voice: see below.

### Languages

Three independent preferences, because they are three different questions:

| Preference | Controls |
|---|---|
| App language (en, hi, bn) | Every screen, notification text, alarm button labels, the language of the spoken template |
| Speaking language | Which on-device recogniser the mic uses (Hindi, Bengali, or the device's English) |
| Read-aloud voice | "Follow reminder language", or a fixed language |

- **UI:** English, Hindi, Bengali. Changing the app language applies live.
- **Parsing:** English, Hindi and Bengali phrases ("कल सुबह 8 बजे दवाई", "কাল সকাল ৮টায়"). Devanagari and Bengali digits and number words are understood. Latin transliteration ("kal 8 baje") is active only when Hindi or Bengali is the speaking or interface language, so English users never see "sham" become 18:00.
- **Dictation:** on-device only; if the language pack is missing the failure panel says so and points to the phone's settings. It never falls back to a network recogniser.
- **Spoken voice, fallback policy:** a native-script title is read by that language's voice. A Latin title follows the Read-aloud setting. If the wanted voice is not installed offline, the reminder's own voice note plays when there is one, otherwise it rings with the chime and the title on screen, and the confirmation card, Detail and settings say so. Bengali is never read with an English voice.

## How it works

**Storage.** One SQLite table, `reminders`, plus media files named by reminder id: the recorded note and the rendered voice. Settings live in shared preferences.

**One write path.** Every save writes the row and schedules its alarms in the same use case. If scheduling fails, the row is flagged and retried on next launch, and the user sees why.

**Fire plan.** Pure Dart computes every alarm a reminder needs: the main fire, the pre-alarm, up to 6 nags, the iOS one-minute retry, a snooze. Each has a stable id. Repeats use calendar arithmetic, so 07:00 stays 07:00 across daylight saving.

**Android.** Dart hands the plan to Kotlin, which arms exact alarms, re-arms repeats as they ring, and re-arms everything after a reboot. A foreground service plays the chime and voice on the alarm stream. Done and Snooze tapped there are queued and applied by Dart on next open.

**iOS.** AlarmKit alarms on iOS 26+, notifications before that. Only the 64 soonest fires are registered, re-chosen on every open. Done and Snooze run as App Intents without opening the app. AlarmKit labels are plain strings from Dart, rendered verbatim so the in-app language wins.

**Voice.** Speech-to-text and text-to-speech both run on the phone. The spoken reminder is rendered to a sound file at save time, because an alarm cannot run speech while the app is closed. Renders are cached by a hash of voice, language and text, written to a temp file and renamed, so an alarm never finds half a file. Older renders are pruned only after the alarm was re-registered.

**Phase-A invariants** (from the first stabilisation pass, kept by tests): the alarm schedulers run behind one serial lock so two saves in the same minute cannot interleave; two reminders in the same minute both ring; reboot and time-zone changes re-arm and re-wall repeats; a failed schedule is flagged, not lost; every launch and resume runs `SyncAlarms`.

**Architecture.** Flutter, one Cubit per screen plus a root `AppSettingsCubit` for language prefs and theme, go_router, get_it. Domain (entities, pure use cases, fire plan, parser) knows nothing about SQLite or platforms. Data owns the schema and the platform channels (`memo/alarm`, `memo/alarmkit`, `memo/stt`, `memo/tts`). Colours, type and spacing are generated from `design/tokens.json`. Strings outside a `BuildContext` (cubits, schedulers, the iOS background isolate) come from one `l10n()` that reads the language pref.

**Rebrand.** Bundle id and Android package are `in.appamania.memo`; the iOS App Group is `group.in.appamania.memo`.

```
lib/
  core/        DI, prefs, flags, theme tokens, chrome (glass/solid), shared UI
  l10n/        ARB files (en, hi, bn) and generated localisations
  features/
    reminders/ domain · data · presentation (home, capture, edit, detail, alarm, archive)
    onboarding/
    settings/
    tags/
```

## Localisation

- Strings live in `lib/l10n/app_en.arb` (template), `app_hi.arb`, `app_bn.arb`. Run `flutter gen-l10n` after editing; CI regenerates and fails if the generated files differ from what is committed. A test checks all three files have the same keys and placeholders.
- Digits are always 0-9 and AM/PM is Latin in every language. 12 or 24 hour display follows the device setting.
- Android has a per-app language setting in system settings that works with the app language.
- Native strings: Dart passes the localised labels (alarm buttons, notification channel names, Missed) with each alarm, so they follow the in-app language, not the phone's, and survive a reboot. Texts the OS shows by itself (Info.plist permission prompts, App Intent titles) use `ios/Runner/{en,hi,bn}.lproj/*.strings` and follow the device language.
- Hindi and Bengali text, including the `.lproj` files, is a draft pending native-speaker review. Do not ship it to the stores as reviewed.
- Hindi and Bengali section labels are sentence case with no letter spacing. Uppercase tracked labels are Latin only.

## Design system

The look comes from one idea: a paper list, not a dashboard. Hairlines instead of shadows, type instead of chrome, time as the only hierarchy. `design/tokens.json` is the source; `tool/gen_tokens.dart` writes `lib/core/theme/tokens.dart`, and CI fails on drift or on any colour literal outside that file.

**Principles**

1. Time is the hierarchy. Day headers organise the list; cards do not.
2. Elevation is a hairline and a change of surface. No drop shadows anywhere.
3. The check control is the only circle in the system. Idle is a thin ring, done is a filled accent disc, overdue is a dashed accent ring.
4. One flat tag, optional. No nesting, no folders.

**Colour**

| Token | Light | Dark |
|---|---|---|
| canvas (screen) | `#F4F3F0` | `#121110` |
| surface (cards) | `#FBFAF8` | `#1B1A18` |
| ink | `#191816` | `#F2F0EC` |
| ink 70 % | `#5C5A55` | ink at 70 % alpha |
| ink 45 % | `#918E87` | ink at 45 % alpha |
| hairline | `#E4E2DC` | `#2B2A27` |
| accent | `#FF5A5F` | `#FF7E82` |
| accent-text | `#C2363C` | `#FF7E82` |
| accent pressed | `#D93B41` | `#FF7E82` |
| accent soft | `#FFEBEC` | accent at 16 % alpha |
| destructive | `#A33A2A` | `#E06A58` |
| caution | `#B26A00` | `#E0A040` |
| caution-soft | `#FFF4E5` | `#2E2412` |
| ok | `#2E7D4F` | `#7CC79A` |

Accent is for large marks: the done disc, overdue ring, complete band. Anything small that carries meaning as text or an icon uses accent-text (4.7:1 on canvas), because accent alone is 3.05:1. Caution marks a thing that needs a decision (the Confirm time block, health warnings) and is never used for overdue or delete; it is 3.8:1, so it is for borders and badges, not body text. ok is for Alarm health only.

**Type**

Three families. Instrument Sans for anything a person reads. IBM Plex Mono for anything a clock produces: times, dates, counts and section labels. Noto Sans Devanagari and Noto Sans Bengali (bundled, SIL OFL 1.1, text in `assets/fonts/OFL-Noto.txt`) are the fallback for both, so Hindi and Bengali text keeps the same weights.

| Role | Face | Size / weight | Notes |
|---|---|---|---|
| Alarm title (alarm screen only) | Sans | 40 / 600 | −2 % tracking |
| Display (screen title, reminder title on detail) | Sans | 34 / 600 | −2 % tracking |
| Title (sheet and page titles) | Sans | 22 / 600 | −1.5 % tracking |
| Button large (alarm Done, Snooze) | Sans | 20 / 600 | 64 high buttons |
| Body large (row title) | Sans | 17 / 500 | |
| Body medium (notes, hints) | Sans | 15 / 400 | ink 70 % |
| Label medium (times, pill values) | Mono | 13 | ink 70 %, accent-text when overdue |
| Label small (section headers) | Mono | 11, uppercase | +12 % tracking; Latin only. Hindi and Bengali use 13 / 500 sentence case, no tracking |

**Spacing and shape**

4-point scale: 4, 8, 12, 16, 24, 32. Screen gutter 20. Minimum row height 60. Minimum hit target 44.

Radii: chip 8, card 14, sheet 20, pill 999.

**Components**

- Section card: grouped rows on one surface, hairline border, hairline separators, radius 14.
- Reminder row: check control, title, mono time, tag dot and label, repeat glyph. No border of its own; the card owns grouping.
- Day section header: mono uppercase label with an optional faint count on the right. Overdue header is accent-text.
- Key/value row and pill value: label on the left, a rounded mono pill on the right.
- Tag chip: 30 high, radius 8. Solid ink at 6 % when idle, inverted when selected, dashed border for "+ New".
- Segmented control (repeat): ink 6 % track, surface-coloured selected segment with hairline, 36 high.
- Weekday selector: seven tiles, single letter when compact, three letters in the sheet. Selected tiles invert.
- Snooze sheet: three outlined options with the resulting time in mono, and "Pick a time".
- Swipe row: right reveals an accent complete band; left reveals Snooze and Delete as full words, 72 wide each. Rows are always opaque so the actions never show through.
- Buttons: primary is ink fill, 50 high (64 on the alarm screen), radius 14; secondary is outlined with a hairline.
- Capture bar: a floating chrome bar (glass on iOS, solid on Android) with "Remind me to…" and a mic, over a canvas fade, with the hint "Type, or tap the mic and speak". Typing expands it into chips and Continue.
- Confirmation card and unsure block: caution border and badge, a one-line reason quoting the user's words, option buttons and "Other time".
- Empty state: a 64 ring containing "00" in mono, a one-line title and two lines of body copy.

**Copy voice**

Short, plain, concrete. "Remind me to…", "Nothing scheduled", "Bins, pills, that call." No exclamation marks, no emoji.

## Testing notes for TestFlight (0.3.0 build 5)

This is the first build under the new bundle id `in.appamania.memo`, so it installs as a new app next to any old one.

- Install fresh, allow notifications and alarms when asked. There is no update path from 0.1.0: it shipped as `com.appamania.memo`, so store builds cannot update it and nothing carries over. Migration is not tested in this build.
- Make a reminder 2 minutes out and lock the phone: it should take over the lock screen and speak. Tap Done, then repeat and tap Snooze to try each option in the sheet.
- Try it again with the phone unlocked and another app open, and with silent mode or Focus on.
- Tap the mic in the bar, say "call mum tomorrow at 6pm", tap again; check the chips. Type "call mum at 8" and check that Save waits for AM or PM.
- Settings → Language and voice: switch App language to Hindi and Bengali; check digits stay 0-9. Hindi and Bengali are drafts pending native review, so report wording problems rather than treating them as final.
- Settings → Alarm reliability: every row should be Allowed or give a Fix; send a test alarm.
- Leave a reminder unanswered: it should ring again every 10 minutes, up to 6 times.

- Quick start chips under the empty bar, history on a repeat's Detail, and Share to Memō (select text in another app, Share, Memō; nothing is saved until you tap Save).

The full device checklists are `docs/plans/memo-v3/qa-matrix.md` and `docs/plans/memo-v2/qa-matrix.md`.

## Not in this build

Photo capture, home-screen widgets, Siri and Assistant, cloud sync, shared reminders, escalation profiles, user-defined templates, history for one-offs, backup and restore, a "snooze choices" setting, per-reminder language, location triggers, monthly repeats, languages other than English, Hindi and Bengali.

---

# Product, business logic and market strategy

This part of the README is for the owner, contributors and anyone judging the product. Facts about the code are taken from the repository as of 0.3.0+5 on `dev`. Anything about the market, pricing or growth is a **proposal**: the repo holds no user or market data, so no figure below is measured.

## 1. Product in one paragraph

Memō is an offline, private reminder app whose alarm behaves like the Clock app: it takes the lock screen, rings through silent mode, reads the reminder aloud in the app's own voice, and nags until the user marks it done. Capture is one line of text or one tap on the mic, then a confirmation step. No account, no cloud, no analytics.

**Core promise:** a reminder that is saved will ring. Every design choice protects that promise.

## 2. Complete feature list

### Capture
| Feature | Behaviour | Where |
|---|---|---|
| Free-text capture bar | One line becomes title, time, repeat and tag chips as the user types | `capture_bar.dart`, `reminder_parser.dart` |
| Natural-language parser | English, Hindi and Bengali rules, no ML; a bare "at 8" or "kal" is flagged ambiguous and blocks Save until the user picks. English: Relative (`in 45 min`), days (`tomorrow`, `friday`, `next fri`), dates (`5 may`, `3/11` day-first), clock times (`8pm`, `20:30`, `at 8`), named times (`tonight`, `noon`), repeats (`daily`, `every mon wed`, `weekdays`), tags (`#health`, `for work`) | `reminder_parser.dart` |
| Confirmation step | Continue opens a card; an unsure time shows "Confirm time" and disables Save until chosen | `capture_cubit.dart` |
| Tap-to-record | Tap to start, tap to stop (hold also works), Cancel, 1 s minimum, 30 s cap, WAV 16 kHz mono | `hold_recorder.dart`, `voice_clip.dart` |
| On-device dictation | Android 13+ on-device recogniser, iOS `SFSpeechRecognizer` on-device only. Empty result saves as "Voice note · 0:08" | `SttPlugin.kt`, `SttPlugin.swift` |
| Full edit sheet | Title, note, time, date, pre-alarm, nag, repeat, tag, voice note, read-aloud | `edit_sheet.dart` |

### Reminders
- One-off, daily, weekly, custom weekdays. Calendar arithmetic keeps 07:00 at 07:00 across DST.
- One optional flat tag. Colour is derived from the name.
- Nag: re-ring every N minutes, up to 6 times, until done. Default 10 min, user-configurable.
- Pre-alarm: heads-up 5, 15, 30, 60 or custom minutes before.
- Snooze 10 minutes / 1 hour / tomorrow same time / pick a time, from a sheet on the alarm screen; the native quick Snooze is 10 minutes. Snoozing a repeat moves only that occurrence, never the series.
- Completing a repeat moves it to its next time. Completing a one-off archives it with a 5-second Undo.
- Voice note attached to a reminder, played from the alarm screen.
- Read aloud: "Reminder. <title>. <note>." rendered offline to a sound file at save time.

### Ringing
- **Android:** exact alarms via `AlarmManager`, a foreground media service looping chime and voice on the alarm stream for up to 2 minutes, full-screen intent over the lock screen, optional "take over the screen" overlay when unlocked. Re-armed after reboot, app update, clock or time-zone change.
- **iOS 26+:** AlarmKit. Full-screen, through silent and Focus, Done and Snooze as App Intents without opening the app.
- **iOS < 26:** Time Sensitive notifications with the rendered sound, a one-minute burst retry, 64-slot budget re-chosen on every open.

### Lists and history
- Home grouped by day, Overdue section at top with "2h late".
- Swipe right = done, swipe left = Snooze / Delete, long-press for a menu. Screen-reader actions mirror the swipes.
- Tag filter. Done archive with search and Reopen.

### Settings and onboarding
- Permission status rows with shortcuts: notifications, exact alarms, full-screen alarms, overlay, battery restriction (Android).
- Default nag, read-aloud default, voice gender with spoken sample.
- Onboarding: welcome, permission primer, battery step (Android only).

### Platform and safety
- One write path (`SaveReminder`): row and alarms change together. A scheduling failure flags the row `needsSchedule` and retries on next launch, and tells the user.
- Every launch and resume runs `SyncAlarms`: roll forward stale repeats, re-register every alarm.
- Native Done/Snooze are queued and applied by Dart on next open, so SQL lives in one language.

## 3. Business logic, step by step

**Capture → reminder.** `parseReminder` blanks every match out of a same-length copy of the input, so spans stay valid for chip highlighting; what survives is the title. User edits to a chip override the parse. `CreateReminder` builds the entity; `SaveReminder` persists then schedules.

**Fire plan.** `firesFor(reminder)` is pure. For each occurrence it emits the main fire, an optional pre-alarm, up to 6 nags, and on iOS-notification mode a +1 min burst. Weekly rules emit one main per weekday because the OS matches one weekday per alarm. A snoozed repeat adds a one-off snooze fire and its own nags. Ids come from `AlarmIds` (stable FNV-style hash, XOR offsets) so cancel always finds what schedule registered.

**Completion.** One-off: `doneAt = now`. Repeat: `dueAt = rule.nextAfterNow(dueAt, now)`, nags reset, snooze cleared. Per-occurrence history is recorded separately (schema v4).

**Snooze.** One-off moves `dueAt`. Repeat sets `snoozedUntil`, leaving the series time untouched.

**Roll-forward.** A repeat more than one full cycle late jumps to its next real occurrence; one cycle late stays overdue so today's missed pills still show.

**Storage.** SQLite `reminders` table, numbered migrations never edited after shipping. Media files named by reminder id. Preferences in shared preferences.

**Privacy invariant.** Speech-to-text never falls back to a network recogniser; TTS never uses network voices; there are no analytics or accounts.

## 4. Architecture

Flutter, one Cubit per screen, `go_router`, `get_it`. Domain (entities, use cases, fire plan, parser) has no SQLite or platform imports. Data owns schema and channels `memo/alarm`, `memo/alarmkit`, `memo/stt`, `memo/tts`. Design tokens are generated from `design/tokens.json` and CI fails on drift or on any colour literal outside `tokens.dart`. CI also runs the repeat arithmetic tests under two time zones.

## 5. Quality status (0.3.0+5)

`flutter analyze` is clean and `flutter test` passes in CI. Swift is not built in the development environment, and the device QA matrix in `docs/plans/memo-v3/qa-matrix.md` (and v2's) is still to be filled in on real phones. Hindi and Bengali copy awaits native-speaker review.

## 6. Localization (built in 0.2.0; table lists what each layer needed)

Target languages: English, Hindi and Bengali only, for the Indian market. Spanish and French are out of scope; the ARB layout makes adding a locale later one file plus a parser rule table.

Localization here is wider than translating labels. Each layer needs work:

| Layer | Work |
|---|---|
| UI strings | `flutter_localizations` + `intl`, ARB files for `en`, `hi`, `bn` |
| Dates and times | Replace the hand-written English formatters in `date_format.dart` with `intl`; follow the device 12/24-hour setting instead of forcing 24h |
| Parser | A rule table per language (day, month and time words, "tomorrow", "every"). Rules, not a framework |
| Dictation | The recogniser follows the Speaking language setting, not the app locale. On-device support for Hindi and Bengali is limited, so the fallback voice note must be honest |
| Read-aloud voice | Pick the TTS voice by language. Voice is chosen by language and never falls back to an English voice for Hindi or Bengali text |
| Spoken template | Was hardcoded English "Reminder."; now localised through ARB `spokenReminder` and `spokenReminderNote` in en, hi and bn |
| Fonts | Instrument Sans and IBM Plex Mono have no Devanagari or Bengali. Bundle Noto Sans Devanagari / Bengali as fallbacks so the look is consistent |
| Native strings | Android `values-xx/strings.xml` (notification channel, Done, Snooze 10m); iOS `Localizable` and `InfoPlist` strings (permission texts, App Intent titles); `CFBundleLocalizations` |
| Copy | Pluralisation ("1 min", "2 min"), no string concatenation for sentences |

## 7. Market strategy (proposal)

**Positioning.** "The reminder that actually rings." Not a to-do manager, not a calendar. It competes with the habit of setting a phone alarm for things that are not alarms.

**Who it is for.**
1. People who miss reminders because notifications are silent and easy to swipe away.
2. People managing medicine and routines, for whom a missed alert has a real cost.
3. Privacy-minded users who refuse accounts and cloud sync.
4. Hindi- and Bengali-speaking users in India, poorly served by English-first reminder apps. The owner's own locale (India, day-first dates) shapes the parser already.

**Differentiators, all verifiable in the code.** Alarm-grade ringing on both platforms; voice reads the reminder; nag until done; one-line capture; fully offline; no account; no tracking.

**Honest weaknesses.** Single-device only (no sync); English, Hindi and Bengali only (Hindi and Bengali copy unreviewed); no widgets, Siri or Assistant yet; no photo capture; Android reliability depends on OEM battery and exact-alarm settings.

**Pricing.** Free for now (owner decision, 2026-10-31). Proposed later model, to validate before building: free core, one-time or low annual "Plus" for sync, shared reminders and widgets. Avoid ads and data monetisation, which would contradict the privacy promise.

**Phased go-to-market.**
| Phase | Goal | Actions |
|---|---|---|
| 0, now | Reliability proof | TestFlight and Play internal testing with 20–50 people; collect "did it ring" reports on many phone makes |
| 1 | Localised launch | Ship English, Hindi and Bengali, localised India store listings and screenshots, a short privacy-first pitch in each |
| 2 | Organic discovery | App-store keyword work per language, short demo videos of the lock-screen alarm and voice capture, community posts where medicine-reminder and ADHD-routine users gather |
| 3 | Monetise | Introduce Plus only after retention is known |

**Metrics to track** (without analytics, use store consoles, opt-in surveys and testers): day-7 and day-30 retention from store data, "missed alarm" reports per 100 users, onboarding permission-grant rate, crash-free sessions, rating per locale.

**Risks.**
- Play Store policy on `USE_EXACT_ALARM` and `USE_FULL_SCREEN_INTENT`: both are restricted to alarm or calendar apps and need a clear declaration.
- OEM battery killers on Android.
- Apple AlarmKit is iOS 26+ only; older iOS rides Time Sensitive notifications, which Focus can still mute.
- Privacy stance limits growth levers such as referral tracking.

## 8. Roadmap order (suggested)

1. Device QA on the matrix, then native-speaker review of Hindi and Bengali.
2. Photo capture, widgets, Siri / Assistant.
3. Phase 2: sync and shared reminders, then Plus.
