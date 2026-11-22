# V9 device QA matrix

Build 0.2.0+4. Fill each cell with pass, fail (with a note or issue link) or n/a. Record the result in the PR.

Columns: Samsung SM-G781B (Android 13), iPhone on iOS 26 or later (AlarmKit), iPhone on iOS 17 or 18 (notifications).

| # | Check | SM-G781B (Android 13) | iPhone iOS 26+ | iPhone iOS 17/18 |
|---|---|---|---|---|
| 1 | Fresh install: onboarding, permissions, battery step (Android) | | | |
| 2 | Update over 0.1.0: n/a for store builds (new app id). To test migration behaviour, use a local debug install of an old commit with the new id | n/a | n/a | n/a |
| 3 | Type, chips, Continue, confirm, toast; ambiguous "at 8" blocks Save | | | |
| 4 | Tap-to-record, hold-to-record, Cancel, 30 s cap, mic denied shows Open Settings | | | |
| 5 | Alarm locked / unlocked / silent / Focus; Done; each snooze option; nag continues | | | |
| 6 | Two reminders in the same minute; reboot; time-zone change (Phase A regressions) | | n/a | n/a |
| 7 | App language en, hi, bn live; 12h and 24h; digits 0-9; Android per-app language setting | | | |
| 8 | Hindi and Bengali dictation with the pack installed, and without it (failure panel) | | | |
| 9 | Hindi and Bengali title: voice installed speaks; removed gives chime and notice; never an English voice | | | |
| 10 | Change Read-aloud voice with 20 reminders: alarms still ring during and after the re-render | | | |
| 11 | Alarm health: each row Fix, deep link, check again; test alarm | | | |
| 12 | Text size 200 %, smallest phone width, dark mode, Reduce Motion, TalkBack / VoiceOver full pass | | | |
| 13 | Native labels (alarm buttons, channel names, Missed, permission prompts) per language; an AlarmKit title with `%`, e.g. "50% rent", renders verbatim | | | |

## ADB notes

- Samsung device id: `RZCTC0T77MD`. Use `adb -s RZCTC0T77MD ...`.
- After a killed integration run: `adb forward --remove-all`, then `adb -s RZCTC0T77MD shell am force-stop in.appamania.memo`.
- Integration tests (`integration_test/`) cover the alarm ring, nag, STT and TTS paths on a device. They do not drive the capture UI; rows 3 and 4 are manual.
- Time-zone change (row 6): `adb shell settings put global time_zone Europe/London` (or change it in Settings), then check that a 07:00 repeat still shows 07:00.
- Per-app language (row 7): `adb shell cmd locale set-app-locales in.appamania.memo --locales hi` (Android 13+).

## Owner steps

1. Fonts: done. Noto Sans Devanagari and Bengali (Regular, Medium, SemiBold) and `OFL-Noto.txt` are in `assets/fonts/`.
2. Xcode: Runner project, Info, Localizations: add Hindi and Bengali. Drag `en.lproj/InfoPlist.strings` and `Localizable.strings` into the Runner group (target Runner), File inspector, Localize, tick English, Hindi, Bengali. Commit `project.pbxproj`. No `Verbatim.strings` file is needed: a table with no file makes AlarmKit labels render as written.
3. Apple developer portal: bundle id `in.appamania.memo` and App Group `group.in.appamania.memo`.
4. Play Console: app with package id `in.appamania.memo`; declare `USE_EXACT_ALARM` and `USE_FULL_SCREEN_INTENT`.
5. Native-speaker review of `lib/l10n/app_hi.arb`, `lib/l10n/app_bn.arb` and the `ios/Runner/*.lproj` strings (plural forms, alarm buttons, confirmation card). Then remove the `@@x-review` markers. Not done: both files are drafts.
6. Devices: on the Samsung install Hindi and Bengali on-device speech packs and Google TTS voices, and remove them again for the fallback rows. On iPhone: Settings, Accessibility, Spoken Content, Voices, Hindi / Bengali.
7. Answer the open questions in `prd.md` section 9 (defaults apply otherwise).

## Known limitations

- Swift is not built in the development environment. `AlarmKitPlugin.swift` (including the verbatim `LocalizedStringResource` labels) and the App Intents have not been compiled by the implementer; build on a Mac with Xcode 26 before TestFlight. In that build, also schedule a reminder titled "50% rent" and confirm the AlarmKit alert shows the title verbatim.
- On-device Hindi and Bengali speech packs and TTS voices vary by phone and Android version; some phones will always take the fallback path.
- iOS notification categories (action button titles) refresh on the next app launch after a language change.
- The "Speaking language" setting uses the shipped UI string; hi and bn wording may change after native review.
- `kal gym` on its own is not parsed with Latin transliteration packs; the title keeps the words and the time stays unset.
- The caution colour is 3.8:1 on canvas: fine for borders and badges, not for body text.
- The AlarmKit alert (iOS 26+) cannot be redesigned; only its title and the two button labels are ours.
