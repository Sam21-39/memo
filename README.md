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
