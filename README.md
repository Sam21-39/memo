# Memō

A reminder app that lives on your phone. Type it or say it, and the phone rings like an alarm at that time, reading the reminder aloud. No account, no cloud, works with no signal, rings even when the app is closed.

Version 0.1.0 · iOS 17+ and Android 8+ · Flutter 3.47.8

## What it is

Memō is for the things you keep forgetting: bins, pills, that call. You say or type one line, and the phone rings at that time until you deal with it.

Everything stays on the device. Speech is turned into text on the phone, and the app's voice is generated on the phone. Nothing is sent anywhere. There is no sign-up, no sync, no analytics.

## What it does

**Capture**

- Type into the bar at the bottom: "Pills at 8 tonight every day #health" becomes chips for the time (20:00), repeat (Daily) and tag. A time the app had to guess is shown outlined.
- Hold the mic and speak. The recording is transcribed on the phone and becomes the title and chips. If nothing is recognised it saves as "Voice note · 0:08".
- Tap any chip to fix it, or "More" for the full form.

**Reminders**

- Title, note, date, time, repeat (none, daily, weekly, custom weekdays), one optional tag.
- Nag: rings again every 10 minutes (or any interval) up to 6 times until marked done.
- Pre-alarm: an early heads-up 5, 15, 30 or 60 minutes before.
- Read aloud: when it rings, the app's own voice says "Reminder. Take your pills." between chimes. Female or male voice, chosen in Settings.

**Ringing**

- iPhone (iOS 26+): a real alarm, full screen on the lock screen, through silent mode and Focus, with Done and Snooze. Older iOS uses Time Sensitive notifications.
- Android: full screen over the lock screen, the chime and voice looping until Done, Snooze or 2 minutes. With "Take over the screen" allowed it also fills the screen when the phone is unlocked.
- Done and Snooze work from the alarm without opening the app.

**Upcoming list**

- Grouped by day: Today, Tomorrow, then dates. Overdue reminders sit at the top in a tinted card with "2h late".
- Tap the circle or swipe right to mark done; one-offs get a 5-second Undo. Swipe left for Snooze 10m and Delete.
- Completing a repeat moves it to its next time. Snoozing a repeat moves only that one time, never its schedule.
- Filter by tag. Done archive with search and Reopen.

**Settings**

- Notifications, exact alarms, full-screen alarms and "Take over the screen", each with a shortcut to fix it.
- Default nag, read aloud, voice (with a spoken sample), dictation availability.

## How it works

**Storage.** One SQLite table, `reminders` (schema v3), plus media files named by reminder id: the recorded note and the rendered voice. Settings live in shared preferences.

**One write path.** Every save writes the row and schedules its alarms in the same use case. If scheduling fails, the row is flagged and retried on next launch, and the user sees why.

**Fire plan.** Pure Dart computes every alarm a reminder needs: the main fire, the pre-alarm, up to 6 nags, the iOS one-minute retry, a snooze. Each has a stable id. Repeats use calendar arithmetic, so 07:00 stays 07:00 across daylight saving.

**Android.** Dart hands the plan to Kotlin, which arms exact alarms, re-arms repeats as they ring, and re-arms everything after a reboot. A foreground service plays the chime and voice on the alarm stream. Done and Snooze tapped there are queued and applied by Dart on next open.

**iOS.** AlarmKit alarms on iOS 26+, notifications before that. Only the 64 soonest fires are registered, re-chosen on every open. Done and Snooze run as App Intents without opening the app.

**Voice.** Speech-to-text and text-to-speech both run on the phone. The spoken reminder is rendered to a sound file at save time, because an alarm cannot run speech while the app is closed.

**Architecture.** Flutter, one Cubit per screen, go_router, get_it. Domain (entities, pure use cases, fire plan, parser) knows nothing about SQLite or platforms. Data owns the schema and the platform channels (`memo/alarm`, `memo/alarmkit`, `memo/stt`, `memo/tts`). Colours, type and spacing are generated from the design system's `tokens.json`.

```
lib/
  core/        DI, prefs, flags, theme tokens, chrome (glass/solid), shared UI
  features/
    reminders/ domain · data · presentation (home, capture, edit, detail, alarm, archive)
    onboarding/
    settings/
    tags/
```

## Design system

The look comes from one idea: a paper list, not a dashboard. Hairlines instead of shadows, type instead of chrome, time as the only hierarchy.

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
| accent pressed | `#D93B41` | — |
| accent soft | `#FFEBEC` | accent at 16 % alpha |
| destructive | `#A33A2A` | same |

Accent is used for overdue, the done check, primary text buttons and the snooze/complete affordances. Everything else is ink on paper.

**Type**

Two families. Instrument Sans for anything a person reads. IBM Plex Mono for anything a clock produces: times, dates, counts and section labels.

| Role | Face | Size / weight | Notes |
|---|---|---|---|
| Display (screen title, reminder title on detail) | Sans | 34 / 600 | −2 % tracking |
| Title (sheet and page titles) | Sans | 22 / 600 | −1.5 % tracking |
| Body large (row title) | Sans | 17 / 500 | |
| Body medium (notes, hints) | Sans | 15 / 400 | ink 70 % |
| Label medium (times, pill values) | Mono | 13 | ink 70 % |
| Label small (section headers) | Mono | 11, uppercase | +12 % tracking, ink 45 % |

**Spacing and shape**

4-point scale: 4, 8, 12, 16, 24, 32. Screen gutter 20. Minimum row height 60. Minimum hit target 44.

Radii: chip 8, card 14, sheet 20, pill 999.

**Components**

- Section card: grouped rows on one surface, hairline border, hairline separators, radius 14.
- Reminder row: check control, title, mono time, tag dot and label, repeat glyph. No border of its own; the card owns grouping.
- Day section header: mono uppercase label with an optional faint count on the right. Overdue header is accent.
- Key/value row and pill value: label on the left, a rounded mono pill on the right. The active field (Time while editing) inverts to ink on paper.
- Tag chip: 30 high, radius 8. Solid ink at 6 % when idle, inverted when selected, dashed border for "+ New".
- Segmented control (repeat): ink 6 % track, surface-coloured selected segment with hairline, 36 high.
- Weekday selector: seven tiles, single letter when compact, three letters in the sheet. Selected tiles invert.
- Snooze presets: three equal outlined buttons, 44 high.
- Swipe row: right reveals an accent complete band that fills with distance; left reveals "10m" (neutral) and "Del" (destructive) as words, 52 wide each. Rows are always opaque so the actions never show through.
- Buttons: primary is ink fill, 50 high, radius 14; secondary is outlined with a hairline. Both use the sans face at 16.
- Capture bar: a floating chrome bar (glass on iOS, solid on Android) with "Remind me to…" and a hold-to-record mic, over a canvas fade. Typing or speaking expands it, solid, into chips (Time, Repeat, Tag, Read aloud, More) and Save. The Done archive and Settings are round buttons in the header.
- Empty state: a 64 ring containing "00" in mono, a one-line title and two lines of body copy.

**Copy voice**

Short, plain, concrete. "Remind me to…", "Nothing scheduled", "Bins, pills, that call." No exclamation marks, no emoji.

## Testing notes for TestFlight (0.1.0)

- Delete any earlier build first, then install. Allow notifications and alarms when asked.
- Make a reminder 2 minutes out and lock the phone: it should take over the lock screen and speak.
- Try it again with the phone unlocked and another app open, and with silent mode or Focus on.
- Tap Snooze 10m on the alarm without opening the app; it should ring again 10 minutes later.
- Hold the mic in the bar and say "call mum tomorrow at 6pm"; check the chips.
- Settings → Voice switches between female and male, with a sample.
- Leave a reminder unanswered: it should ring again every 10 minutes, up to 6 times.

## Not in this build

Photo capture (next), home-screen widgets, Siri and Assistant, cloud sync, shared reminders, location triggers, monthly repeats, per-occurrence history, languages other than English, 12-hour time.

---

# Product, business logic and market strategy

This part of the README is for the owner, contributors and anyone judging the product. Facts about the code are taken from the repository as of 0.1.0+3 on `dev`. Anything about the market, pricing or growth is a **proposal**: the repo holds no user or market data, so no figure below is measured.

## 1. Product in one paragraph

Memō is an offline, private reminder app whose alarm behaves like the Clock app: it takes the lock screen, rings through silent mode, reads the reminder aloud in the app's own voice, and nags until the user marks it done. Capture is one line of text or one held mic press. No account, no cloud, no analytics.

**Core promise:** a reminder that is saved will ring. Every design choice protects that promise.

## 2. Complete feature list

### Capture
| Feature | Behaviour | Where |
|---|---|---|
| Free-text capture bar | One line becomes title, time, repeat and tag chips as the user types | `capture_bar.dart`, `reminder_parser.dart` |
| Natural-language parser | English rules, no ML. Relative (`in 45 min`), days (`tomorrow`, `friday`, `next fri`), dates (`5 may`, `3/11` day-first), clock times (`8pm`, `20:30`, `at 8`), named times (`tonight`, `noon`), repeats (`daily`, `every mon wed`, `weekdays`), tags (`#health`, `for work`) | `reminder_parser.dart` |
| Guess marking | A time the parser had to invent is drawn as a dashed chip | `capture_cubit.dart` |
| Hold-to-record | Raw pointer events, 1 s minimum, 30 s cap, WAV 16 kHz mono | `hold_recorder.dart`, `voice_clip.dart` |
| On-device dictation | Android 13+ on-device recogniser, iOS `SFSpeechRecognizer` on-device only. Empty result saves as "Voice note · 0:08" | `SttPlugin.kt`, `SttPlugin.swift` |
| Full edit sheet | Title, note, time, date, pre-alarm, nag, repeat, tag, voice note, read-aloud | `edit_sheet.dart` |

### Reminders
- One-off, daily, weekly, custom weekdays. Calendar arithmetic keeps 07:00 at 07:00 across DST.
- One optional flat tag. Colour is derived from the name.
- Nag: re-ring every N minutes, up to 6 times, until done. Default 10 min, user-configurable.
- Pre-alarm: heads-up 5, 15, 30, 60 or custom minutes before.
- Snooze 10 min / 1 h / tomorrow. Snoozing a repeat moves only that occurrence, never the series.
- Completing a repeat moves it to its next time. Completing a one-off archives it with a 5-second Undo.
- Voice note attached to a reminder, played from the alarm screen.
- Read aloud: "Reminder. <title>. <note>." rendered offline to a sound file at save time.

### Ringing
- **Android:** exact alarms via `AlarmManager`, a foreground media service looping chime and voice on the alarm stream for up to 2 minutes, full-screen intent over the lock screen, optional "take over the screen" overlay when unlocked. Re-armed after reboot, app update, clock or time-zone change.
- **iOS 26+:** AlarmKit. Full-screen, through silent and Focus, Done and Snooze as App Intents without opening the app.
- **iOS < 26:** Time Sensitive notifications with the rendered sound, a one-minute burst retry, 64-slot budget re-chosen on every open.

### Lists and history
- Home grouped by day, Overdue section at top with "2h late".
- Swipe right = done, swipe left = Snooze 10m / Delete. Screen-reader actions mirror the swipes.
- Tag filter. Done archive with search and Reopen.

### Settings and onboarding
- Permission status rows with shortcuts: notifications, exact alarms, full-screen alarms, overlay.
- Default nag, read-aloud default, voice gender with spoken sample.
- Two-screen onboarding: welcome, permission primer.

### Platform and safety
- One write path (`SaveReminder`): row and alarms change together. A scheduling failure flags the row `needsSchedule` and retries on next launch, and tells the user.
- Every launch and resume runs `SyncAlarms`: roll forward stale repeats, re-register every alarm.
- Native Done/Snooze are queued and applied by Dart on next open, so SQL lives in one language.

## 3. Business logic, step by step

**Capture → reminder.** `parseReminder` blanks every match out of a same-length copy of the input, so spans stay valid for chip highlighting; what survives is the title. User edits to a chip override the parse. `CreateReminder` builds the entity; `SaveReminder` persists then schedules.

**Fire plan.** `firesFor(reminder)` is pure. For each occurrence it emits the main fire, an optional pre-alarm, up to 6 nags, and on iOS-notification mode a +1 min burst. Weekly rules emit one main per weekday because the OS matches one weekday per alarm. A snoozed repeat adds a one-off snooze fire and its own nags. Ids come from `AlarmIds` (stable FNV-style hash, XOR offsets) so cancel always finds what schedule registered.

**Completion.** One-off: `doneAt = now`. Repeat: `dueAt = rule.nextAfterNow(dueAt, now)`, nags reset, snooze cleared. No per-occurrence history (documented ceiling).

**Snooze.** One-off moves `dueAt`. Repeat sets `snoozedUntil`, leaving the series time untouched.

**Roll-forward.** A repeat more than one full cycle late jumps to its next real occurrence; one cycle late stays overdue so today's missed pills still show.

**Storage.** SQLite `reminders` table, schema v3, numbered migrations never edited after shipping. Media files named by reminder id. Preferences in shared preferences.

**Privacy invariant.** Speech-to-text never falls back to a network recogniser; TTS never uses network voices; there are no analytics or accounts.

## 4. Architecture

Flutter, one Cubit per screen, `go_router`, `get_it`. Domain (entities, use cases, fire plan, parser) has no SQLite or platform imports. Data owns schema and channels `memo/alarm`, `memo/alarmkit`, `memo/stt`, `memo/tts`. Design tokens are generated from `design/tokens.json` and CI fails on drift or on any colour literal outside `tokens.dart`. CI also runs the repeat arithmetic tests under two time zones.

## 5. Quality status (0.1.0+3)

`flutter analyze`: clean. `flutter test`: 221 passing. The detailed audit, with every defect found and its proposed fix, is delivered with this README and is pending owner approval before any code changes.

## 6. Localization plan

Target languages: English, Hindi and Bengali only, for the Indian market. Spanish, French and Mexican Spanish are out of scope for now; the ARB layout makes adding a locale later one file plus a parser rule table.

Localization here is wider than translating labels. Each layer needs work:

| Layer | Work |
|---|---|
| UI strings | `flutter_localizations` + `intl`, ARB files for `en`, `hi`, `bn` |
| Dates and times | Replace the hand-written English formatters in `date_format.dart` with `intl`; follow the device 12/24-hour setting instead of forcing 24h |
| Parser | A rule table per language (day, month and time words, "tomorrow", "every"). Rules, not a framework |
| Dictation | Pass the app locale to Android and iOS recognisers. On-device support for Hindi and Bengali is limited, so the fallback voice note must be honest |
| Read-aloud voice | Pick the TTS voice by language. Today both platforms filter to English voices, so a Hindi title would be read with an English voice |
| Spoken template | "Reminder." is hardcoded English |
| Fonts | Instrument Sans and IBM Plex Mono have no Devanagari or Bengali. Bundle Noto Sans Devanagari / Bengali as fallbacks so the look is consistent |
| Native strings | Android `values-xx/strings.xml` (notification channel, Done, Snooze 10m); iOS `Localizable` and `InfoPlist` strings (permission texts, AlarmKit buttons, App Intent titles); `CFBundleLocalizations` |
| Copy | Pluralisation ("1 min", "2 min"), no string concatenation for sentences |

## 7. Market strategy (proposal)

**Positioning.** "The reminder that actually rings." Not a to-do manager, not a calendar. It competes with the habit of setting a phone alarm for things that are not alarms.

**Who it is for.**
1. People who miss reminders because notifications are silent and easy to swipe away.
2. People managing medicine and routines, for whom a missed alert has a real cost.
3. Privacy-minded users who refuse accounts and cloud sync.
4. Hindi- and Bengali-speaking users in India, poorly served by English-first reminder apps. The owner's own locale (India, day-first dates) shapes the parser already.

**Differentiators, all verifiable in the code.** Alarm-grade ringing on both platforms; voice reads the reminder; nag until done; one-line capture; fully offline; no account; no tracking.

**Honest weaknesses.** Single-device only (no sync); English parser today; no widgets, Siri or Assistant yet; no photo capture; Android reliability depends on OEM battery and exact-alarm settings.

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

1. Fix the audited defects, especially data-loss and silent-failure items.
2. Localisation foundation (strings, formatters, fonts, native strings).
3. Per-language parser, dictation and voice.
4. Photo capture, widgets, Siri / Assistant.
5. Phase 2: sync and shared reminders, then Plus.
