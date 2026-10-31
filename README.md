# Memō

A reminder app that lives on your phone. One line, one time. No account, no cloud, works with no signal, rings even when the app is closed.

Version 0.0.1 · iOS and Android · Flutter 3.47.8

## What it is

Memō is for the things you keep forgetting: bins, pills, that call. You type a line, pick a time, and the phone rings at that time. That is the whole product.

Everything stays on the device. Nothing is sent anywhere. There is no sign-up, no sync, no analytics.

## What it does

**Reminders**

- Title, optional note, date and time.
- Repeat: none, daily, weekly, or custom weekdays.
- One optional tag per reminder (Home, Work, Health, anything you type). Tag colour is derived from its name.

**Upcoming list**

- Grouped by day: Today, Tomorrow, then dated sections. Time is the hierarchy, not folders.
- Overdue reminders sit at the top in their own tinted section with "2h late" style wording.
- Header shows "N scheduled · M overdue".
- Filter bar by tag when any tag exists.

**Acting on a reminder**

- Tap the circle or swipe right to mark done. One-offs get a 5-second Undo.
- Swipe left to reveal Snooze (10 minutes) and Delete.
- Open a reminder to see Next, Repeat and Created, snooze by 10m / 1h / Tomorrow, edit, or delete.
- Completing a repeating reminder moves it to its next occurrence instead of archiving it.

**Notifications**

- Scheduled locally through the OS. They fire with the app killed, in airplane mode, or with no signal.
- The alert has Done and Snooze buttons. Tapping the body opens the reminder, including from a cold start.
- On iOS, alerts are marked Time Sensitive so they break through Focus modes.

**Done archive**

- Completed one-offs, newest first, with a Reopen button.

**Settings**

- Notification permission status with a shortcut to request it or open OS settings.
- Which features are on. Cloud sync is listed greyed as Phase 2.

**First run**

- Two screens: a short welcome, then a plain-language explanation of why the app asks for notification permission before the OS dialog appears. Skippable.

## How it works

**Storage.** One SQLite table, `reminders`, in `memo.db`. A reminder is one row. The onboarding-complete flag is in shared preferences. Nothing else is stored.

**Scheduling.** Every save writes the row and (re)schedules its alarm in the same step. A saved reminder that never rings is the one failure the app cannot have. Alarm IDs are a stable hash of the reminder ID, so cancelling always finds the right one. A weekly rule with several weekdays schedules one alarm per weekday, because the OS can only match a single day-of-week per alarm.

**Repeats.** Completing or snoozing recomputes the next occurrence with calendar arithmetic (not durations), so 07:00 stays 07:00 across a daylight-saving change. If a repeating reminder is left alone for several cycles, the app rolls it forward to its next real occurrence on launch, so it never shows as permanently overdue.

**iOS limit.** iOS keeps only the 64 soonest pending notifications and silently drops the rest. When the app has more live alarms than that, it re-registers the soonest 64 on every load.

**Notification taps.** Done and Snooze from the alert open the app briefly and apply the action against the database. Taps are made idempotent for a few seconds so a double delivery never snoozes twice.

**Permissions.** Android asks for notifications (13+) and the exact-alarm grant. iOS asks for alert, badge and sound. The app asks only after its own primer screen, never on its own.

**Architecture.** Flutter, Cubit for state, get_it for wiring. Domain layer (entities, pure use cases) knows nothing about SQLite or notifications. Data layer owns the schema. Presentation owns screens and widgets. Feature flags gate repeat, snooze and tags at the call site, so a flag flip never touches screen code. Cloud sync is a second repository implementation swapped in DI, not yet written.

```
lib/
  core/        DI, feature flags, theme, date formatting, notification scheduler
  features/
    reminders/ domain · data · presentation
    onboarding/
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
- Swipe row: right reveals an accent complete band that fills with distance; left reveals a neutral snooze button and a red delete button, 52 wide each.
- Buttons: primary is ink fill, 50 high, radius 14; secondary is outlined with a hairline. Both use the sans face at 16.
- Bottom bar: "New reminder" primary button plus a 52-square outlined check that opens the Done archive, over a canvas gradient so the list fades beneath it.
- Empty state: a 64 ring containing "00" in mono, a one-line title and two lines of body copy.

**Copy voice**

Short, plain, concrete. "Remind me to…", "Nothing scheduled", "Bins, pills, that call." No exclamation marks, no emoji.

## Testing notes for TestFlight

- First launch shows onboarding once. To see it again, delete and reinstall.
- Alarms depend on notification permission. If you tapped "Not now", Settings → Notifications requests it again.
- Lock the phone and kill the app after creating a reminder; the alarm should still ring.
- Try a daily repeat, mark it done, and confirm it moves to tomorrow instead of disappearing.
- Try Focus mode on iOS; the alert should still come through.

## Not in this build

Cloud sync, shared reminders, location triggers, voice input, monthly repeats, per-occurrence history for repeats, localisation (English, 24-hour only), home-screen widgets.
