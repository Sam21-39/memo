# V3 device QA matrix

Build 0.3.0+5. Fill each cell with pass, fail (with a note or issue link) or n/a. Record the result in the commit or issue.

Columns: Samsung SM-G781B (Android 13), iPhone on iOS 26 or later (AlarmKit), iPhone on iOS 17 or 18 (notifications).

| # | Check | SM-G781B (Android 13) | iPhone iOS 26+ | iPhone iOS 17/18 |
|---|---|---|---|---|
| 1 | Update over 0.2.0+4: reminders, alarms and settings intact; a repeat's Detail shows no History yet | | | |
| 2 | Quick start: chips under the empty field, with the keyboard up, in en / hi / bn; each chip prefills, cursor at end; gone while typing | | | |
| 3 | "Weekly routine" + task + time saves a weekly repeat on today's weekday in en, hi, bn | | | |
| 4 | Quick start at text size 200 %, smallest width, both; TalkBack / VoiceOver reads the heading and five buttons | | | |
| 5 | History: Done from the list, Detail, alarm screen, notification action, native alarm with Memō killed: each adds one row with the right time | | | |
| 6 | History: snooze 10 min then Done shows one row "Snoozed 10 min, done ..."; a running snooze shows no row | | | |
| 7 | History: leave a daily unanswered for three days: "Not marked done" rows; the word "missed" appears nowhere | | | |
| 8 | History: delete then Undo keeps it; delete and wait removes it; test alarm leaves none; time-zone change does not duplicate rows | | | |
| 9 | Share (Android): text from a browser and a messaging app; Memō killed / background / on Settings; one Memō card in Recents | | n/a | n/a |
| 9a | Share (Android): `adb shell am start -n in.appamania.memo/.ShareActivity -a android.intent.action.SEND -t text/plain --es android.intent.extra.TEXT "Call mum at 6pm"` with Memō killed (cold) | | n/a | n/a |
| 9b | Same command with Memō in the background (warm) | | n/a | n/a |
| 9c | Same command with Settings in the foreground | | n/a | n/a |
| 9d | Recents shows a single Memō task after each of 9a-9c | | n/a | n/a |
| 9e | Share sheet and Recents label read "Memō" (not the package name) | | n/a | n/a |
| 9f | Share while editing on the reminder page: the card waits until the bar is idle | | n/a | n/a |
| 9g | Share while the Done archive is open: the card waits | | n/a | n/a |
| 10 | Share: text with a time saves in two taps; text without a time shows Confirm time and Save is off; nothing saved without a tap | | | |
| 11 | Share: during a ringing alarm the alarm stays; the card is there after Done | | n/a | n/a |
| 12 | Share: very long text, emoji, Hindi and Bengali text with conjuncts render correctly and are cut cleanly | | | |
| 13 | Share (iOS): Memō in the share sheet for selected text; extension confirms in the device language; opening Memō shows the card; two shares in a row | n/a | | |
| 13a | Share (iOS): extension alert in en, hi, bn device languages | n/a | | |
| 13b | Share (iOS): share a URL or an image only: "Memō can only take text." or text-only behaviour, no crash | n/a | | |
| 14 | Share at 200 % text and smallest width: card scrolls, nothing clipped | | | |

## ADB notes

- Samsung device id: `RZCTC0T77MD`. Use `adb -s RZCTC0T77MD ...`.
- After a killed run: `adb forward --remove-all`, then `adb -s RZCTC0T77MD shell am force-stop in.appamania.memo`.
- Time-zone change (row 8): `adb shell settings put global time_zone Europe/London`, then check that a 07:00 repeat still shows 07:00.
- Per-app language: `adb shell cmd locale set-app-locales in.appamania.memo --locales hi` (Android 13+).

## Owner steps (Xcode, S2)

1. File, New, Target, Share Extension. Product name `ShareExtension`, Swift, bundle id `in.appamania.memo.ShareExtension`, embed in Runner. Do not activate the new scheme.
2. The wizard may overwrite `ios/ShareExtension/ShareViewController.swift` and `Info.plist`. Right after creating the target run `git checkout -- ios/ShareExtension` to restore the repo files, delete only `MainInterface.storyboard` (Move to Trash) and make sure it is out of the target. If Xcode made `ShareExtension` a synchronized folder, add `Info.plist` and the entitlements file as membership exceptions so they are not copied as resources. Then add the repo files to the target: the Swift file, `Info.plist`, entitlements, the three `.lproj/Localizable.strings` (add hi and bn as localisations).
3. Target ShareExtension, Build Settings: `INFOPLIST_FILE = ShareExtension/Info.plist`, `CODE_SIGN_ENTITLEMENTS = ShareExtension/ShareExtension.entitlements`, iOS Deployment Target 17.0, `MARKETING_VERSION = $(FLUTTER_BUILD_NAME)`, `CURRENT_PROJECT_VERSION = $(FLUTTER_BUILD_NUMBER)`, and set the target's Debug/Release base configuration to `Flutter/Debug.xcconfig` / `Flutter/Release.xcconfig` (as Runner does) so those variables resolve. Versions must equal the app's on every release or App Store Connect rejects it (ITMS-90473); never hardcode them.
4. Signing & Capabilities, App Groups, `group.in.appamania.memo` on both Runner and ShareExtension (this updates `ios/Runner/Runner.entitlements`); register the group and both app ids in the developer portal if automatic signing does not.
5. Target Runner, Build Phases: drag "Embed Foundation Extensions" above "Thin Binary".
6. Do not add the extension to the Podfile.
7. Build and run on a device; select text in Notes, Share, Memō. Commit `project.pbxproj` and entitlements.
8. `fvm flutter build ios --debug --no-codesign`, then rows 13 and 14 on a device.
9. Native-speaker review of the new hi/bn strings before any store build.

## Known limitations

- Swift (`AlarmPlugin.swift` share methods, `ShareViewController.swift`) is syntax-checked only; compile in Xcode before TestFlight.
- Until the App Group is enabled on Runner, the iOS share queue is empty and Share to Memō does nothing on iOS.
