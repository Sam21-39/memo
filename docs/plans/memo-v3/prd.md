# Memō v3 — quick templates, per-occurrence history, Share to Memō

Technical PRD. Steps live in `guidelines.md` (same folder). Baseline: branch `dev` at ffda45a (0.2.0+4), 762 tests, Flutter 3.47.8 via `fvm`, sqflite
schema v3, package id `in.appamania.memo`.

Sources read: `docs/plans/memo-v2/*`, every use case in `domain/usecases/`, `reminder_db.dart`, `reminder_repository_impl.dart`,
`rewall_repeats.dart`, `capture_cubit.dart`, `capture_bar.dart`, `reminder_confirmation.dart`, `home_page.dart`, `home_cubit.dart`, `detail_*`,
`alarm_cubit.dart`, `archive_cubit.dart`, `app.dart`, `di.dart`, `native_alarm.dart`, `parser_packs.dart`, `MainActivity.kt`, `AlarmStore.kt`,
`AndroidManifest.xml`, `AppDelegate.swift`, `AlarmPlugin.swift`, `test/fakes.dart`, `test/a11y_layout_test.dart`. Parser claims in 5.1 were run
against the real parser (7 weekdays × 2 input languages for each of en/hi/bn, plus title-only prefills), not assumed.

## 1. Problem

1. An empty capture field gives no starting point. Typing the same "Take medicine …" every time is the commonest first action.
2. A repeat keeps one row and one `due_at`. Completing it moves the time forward and the past is gone (`complete_reminder.dart` carries the
   `ponytail:` note asking for an occurrences table). The Detail board's "This week 5 of 6 done" was marked Planned in v2 for this reason.
3. Text in another app (a message, a mail line) has to be retyped. Memō is not a share target on either platform.

## 2. Scope: four phases, in this order, each built, reviewed, fixed and committed on `dev`

| Phase | Ships | Depends on |
|---|---|---|
| T1 | Five localised quick-start chips under the empty capture field; a tap prefills the field | — |
| H1 | Schema v4 `occurrences` table; done / snoozed / open events for repeats; 90-day prune; History list and "This week N of M done" on Detail | — |
| S1 | Android share target (`text/plain`), pending-share store, shared confirmation on Home, sanitiser | — |
| S2 | iOS Share Extension writing to the App Group; Runner reads it through the S1 Dart path; version 0.3.0+5, README, QA matrix | S1 |

## 3. Non-goals

- User-defined templates, template storage, template ordering, usage counts.
- History for one-offs (the Done archive already covers them). History editing: no marking a past occurrence done after the fact (see Q5).
- The word "missed" anywhere. The OS cannot confirm an alarm rang; an occurrence nobody answered is "Not marked done".
- Undo for a repeat's Done (there is none today: `HomeCubit.complete` gives a repeat no toast). Charts, streaks, export.
- Sharing images, files, URLs-as-type, or several items. Only `EXTRA_TEXT` / plain text. `EXTRA_STREAM` is never read.
- Auto-saving a shared reminder, on any input. Reading anything the user did not share.
- Changes to `AlarmIds`, `fire_plan.dart`, `repeat_rule.dart`, `MainActivity`'s launch mode, existing migrations, existing native entry fields.
- New pub dependencies (none needed: one platform channel, two methods).

## 4. Requirements

### 4.1 Quick templates (T1)
- Five chips, fixed order: Take medicine, Pay a bill, Call someone, Follow up, Weekly routine. Label and prefill are separate ARB strings in en/hi/bn.
- Shown only when `CaptureState.phase == idle` (field empty, no clip), under the bar, under a section label "Quick start". Gone on the first character.
- Tap: `CaptureCubit.setText(prefill + ' ')`, field focused, cursor at end. Nothing else: the existing parser, chips, Continue and confirmation run
  unchanged. No storage, no new state field.
- One horizontally scrolling row, each chip at least 44 px high. No overflow at 2.0x text, at 320 px, or both together. No new animation; if one is
  added it goes through `motion()`.

### 4.2 Per-occurrence history (H1)
- Table `occurrences(reminder_id, due_at, event, at, until)`; `event` is `done | snoozed | open`. `until` (snooze target) is the one column beyond the
  approved four (see Q3).
- Written in exactly three places, each in the same SQLite transaction as the reminder row it belongs to:
  1. Done → `SaveReminder.done` (new). Every Done path already ends in `SaveReminder`: Home, Detail, Alarm screen, `ApplyAlarmAction` (notification
     tap, iOS background isolate, Android and AlarmKit native queues).
  2. Snooze → `SaveReminder.snooze` (new), same callers.
  3. Roll-forward → `SyncAlarms`, one `open` per cycle it steps over, at most the latest 90.
- Never written for a one-off, for `testReminderId`, by an edit, by `RewallRepeats`, or by `ReopenReminder`.
- Pruned in `SyncAlarms`: rows with `due_at` older than 90 days. A prune failure never blocks alarm sync.
- Deleted with the reminder, in `ReminderRepositoryImpl.delete`'s transaction. The 5 s Undo is in-memory (`HomeReady.pendingDelete`); the row and
  its history are untouched until the window ends, so history survives Undo with no code.
- Detail, repeats only: section "History", line "This week N of M done" (hidden when M = 0), then one row per occurrence, newest first: date, a
  sentence ("Done at 6:04 PM" / "Snoozed 10 min, done 6:15 PM" / "Not marked done") and a pill (Done / Open).

### 4.3 Share to Memō, Android (S1)
- `text/plain` `ACTION_SEND` reaches Memō; the text is stored natively (capped), Memō comes to the front, Home shows the confirmation card in its
  shared form: heading "Shared to Memō", the shared text quoted, parsed title, When, Repeat, Save reminder, Edit details, footnote "Only what you
  share. Memō never reads your mail."
- Same `CaptureCubit` state, same `ReminderConfirmation`, same ambiguity gate: a shared text with no clear time shows `UnsureTimeBlock` and Save is off.
- Shared text is untrusted: capped natively (4,000 chars) and in Dart (200 code points), control and bidi-override characters stripped, whitespace
  collapsed, never executed, never used as a route, never saved without a tap.
- One at a time; a share is removed from the native store when it is put on screen. A share that arrives while the user is typing or recording waits
  for the bar to be idle. Nothing is shown before onboarding is finished; the share waits.

### 4.4 Share to Memō, iOS (S2)
- Share Extension target appends `{id, text, at}` to `UserDefaults(suiteName: "group.in.appamania.memo")`, shows "Added to Memō. Open Memō to set the
  time." and completes. No Flutter, no pods, no network in the extension.
- Runner serves the same two channel methods as Android; Dart is unchanged from S1.
- Version 0.3.0+5, README feature list, `docs/plans/memo-v3/qa-matrix.md`.

## 5. Key decisions (problem → options → pick)

5.1 **What "Weekly routine" prefills.** It must parse to a weekly repeat in all three languages once a time is typed. Options: (a) "Every week " —
English only; the Hindi and Bengali packs have no bare-week rule (`every: ['har','हर']` and `['proti','prati','প্রতি']` need a weekday after them);
(b) add week words to the packs — parser change for a chip; (c) "Every {today's weekday} " with the name from `DateFormat.EEEE(interface language)`.
Pick (c): zero parser change, same shape in every language, and the weekday is visible instead of implied. Verified against the parser for all 7
days: "Every Friday …", "हर शुक्रवार …", "প্রতি শুক্রবার …" each give `weekly {5}`, with either `en` or the native language as input language (native
script packs are always active). The other four prefill a title only; a time typed after them parses as usual ("दवा लेनी है रात 9 बजे" → 21:00).

5.2 **Chip layout.** Options: (a) `Wrap` — five chips at 2.0x on 320 px is five rows, about 300 px over the keyboard; (b) one horizontally scrolling
row. Pick (b): fixed height, cannot overflow, list stays visible.

5.3 **Where history is written.** Options: (a) each cubit calls a logger next to its save — four Done sites, four Snooze sites, easy to miss one;
(b) `SaveReminder` diffs old and new rows and guesses the event — an edit that moves the time looks like a Done; (c) `SaveReminder.done(reminder,
at)` / `.snooze(reminder, at, …)` wrap the pure use cases and pass the events to `ReminderRepository.save(reminder, log: …)`. Pick (c): `SaveReminder`
is already "the one write path", call sites get shorter, a grep proves no cubit bypasses it, and row plus events commit together.

5.4 **Which occurrence a Done belongs to.** `CompleteReminder` can step over several cycles (`nextAfterNow`). Rule: list the cycles from the old
`dueAt` up to, not including, the new one; the last is `done`, any before it are `open`. One pure helper (`cyclesBetween`) serves this and the
roll-forward (where all are `open`). A Done tapped early (before `dueAt`) yields one cycle, the coming one. A queued native Done carries its tap time
`at`, and `_catchUp` drains queues before `SyncAlarms`, so a tap from two days ago lands on the occurrence it was tapped for. That order must stay.

5.5 **Snooze then Done, shown as one row.** Events are append-only; display groups by `due_at`. Status: `done` if the group has a done event, else
`open` if it has an open event, else the group is not shown. That last case is a snooze still running, or one orphaned when an edit or a time-zone
re-wall moved `due_at` under it (`RewallRepeats` clears the snooze anyway). Pending snoozes therefore never appear as "Not marked done".

5.6 **Time-zone re-wall and edits.** History rows are past facts keyed by the instant that was due; neither `RewallRepeats` nor the editor rewrites
them. Shown in the current zone. Accepted: after a zone change an old row's date can sit one day off its original wall date.

5.7 **Reopen.** `ReopenReminder` only ever runs on a row with `doneAt`, and a repeat never has one. There is no repeat "done record" to remove, so
Reopen writes and deletes nothing in `occurrences`. A repeat later edited into a one-off keeps its old rows until they age out; Detail shows History
for repeats only.

5.8 **Android entry point.** The approved wording puts the `SEND` filter on `MainActivity`. Traced problem: `MainActivity` is `singleTop` with
`taskAffinity=""`; a share target is started inside the sharing app's task, so a second `MainActivity`, a second Flutter engine and a second Dart
isolate (second `configureDependencies`, second `SyncAlarms`, two Homes) would run while the first is alive. Options: (a) filter on `MainActivity` +
`launchMode="singleTask"` — changes how the alarm full-screen intent and notification taps are delivered, the path v2 forbids touching casually;
(b) a 30-line `ShareActivity` (plain `Activity`, `Theme.NoDisplay`) that stores the text and starts Memō's launcher intent, then finishes. Pick (b):
`MainActivity` and the alarm path are untouched, cold and warm start are the same code (Dart pulls on launch and resume), the text survives Memō
being killed before it is shown, and iOS (S2) needs exactly this pull model. **Deviation from decision 4's wording; needs the owner's nod (Q1).**

5.9 **Channel.** Options: (a) new `memo/share` channel + new Swift plugin file (pbxproj edit in Runner); (b) two methods on the existing
`memo/alarm`, which both platforms already serve (`MainActivity.kt`, `AlarmPlugin.swift`) and Dart already wraps with timeout and typed error
(`NativeAlarm`). Pick (b): no new registration on either side. Methods: `pendingShares` → JSON `[{id, text, at}]`, `ackShare {id}`.

5.10 **Peek + ack, not drain.** `drainActions` clears on read; a share drained and then lost to an app kill is user data gone. Dart reads the list,
shows the first, acks it once it is on screen, and asks again when the bar is idle. No Dart-side queue.

5.11 **Where the shared card lives.** Options: (a) new route / `showMemoSheet` with its own cubit; (b) the existing in-tree confirmation panel on
Home. Pick (b): the transcript path already does "set text, jump to confirming" (`_onHold`); sharing is the same two lines plus a `shared` flag
mirroring `spoken`. Routing is one rule: if something other than `/alarm/…` covers Home, `go('/')`; a ringing alarm is never covered or replaced, the
card waits under it.

5.12 **"Shared from <app>".** Not reliably knowable. Android: the chooser hides the origin, `getReferrer()` often names the system or the resolver,
and package visibility (API 30+) blocks reading another app's label; iOS gives an extension no host identity at all. A wrong name is worse than none.
Pick: always the generic heading "Shared to Memō"; no `from` field anywhere (Q2).

5.13 **Share-sheet label.** Android shows the activity label, iOS the extension's display name. Both are the brand "Memō", which is never
translated (v2 non-goal), so there is nothing to localise in the system sheet. The extension's one confirmation sentence uses `.lproj` strings and
follows the device language, the v2 rule for text Dart cannot pass.

## 6. Acceptance checks

Every phase: shared verify in guidelines §0 green, test count ≥ previous (baseline 762), debug APK builds on JDK 21.

- T1: empty field shows "Quick start" and five chips; tapping "Take medicine" gives field text "Take medicine " with the cursor at the end and the
  keyboard up; typing "8pm" then Continue reaches the normal confirmation. "Weekly routine" + "water plants 9am" confirms as weekly on today's
  weekday, in en, hi and bn. Chips vanish once anything is typed and return after Save or discard. No overflow at 390×844 @2.0, 320×690 @1.0, 320×690
  @2.0. Every chip ≥ 44 px high.
- H1: a v3 database opens at v4 with rows intact and an empty `occurrences`. Done on a daily repeat adds one `done` row keyed by the old `due_at`;
  a one-off and `memo-test` add none. Snooze then Done shows one row "Snoozed 10 min, done …". A repeat three cycles behind gets `open` rows from
  `SyncAlarms` and reads "Not marked done". Swipe-delete then Undo keeps history; letting the window end removes it. Rows older than 90 days are gone
  after a sync. A native-queue Done applied a day late is stored with its tap time. `grep` finds no `CompleteReminder()(` / `SnoozeReminder()(` in a
  cubit.
- S1: sharing "Dentist Friday 3pm" from another app opens Memō on the shared card with that text quoted and Friday 3:00 PM; sharing "Call the bank"
  shows the unsure-time block and Save is disabled; nothing is ever saved without a tap. Works with Memō not running, in the background, and on
  Settings. Recents shows one Memō card afterwards. A 50,000-character share, a share of only control characters, and one with bidi overrides do not
  crash, hang or spoof the card. A share during a ringing alarm does not replace the alarm screen.
- S2 (owner, on device): Memō appears in the iOS share sheet for selected text; the extension confirms and closes; opening Memō shows the card; two
  shares show one after the other; nothing reappears after it was shown. `pubspec.yaml`, `app_version.dart`, README say 0.3.0 (5).

## 7. Architecture audit

| Component | Problem | Fix | Risk | Severity |
|---|---|---|---|---|
| `complete_reminder.dart` | A repeat's completion leaves no record | `occurrences` + `SaveReminder.done` | Call-site sweep (8 lines) | Medium |
| `ReminderRepository.save` | No way to commit a row and its events together | Optional `log:` parameter, one transaction | Three test fakes extend `InMemoryRepository`; default arg keeps them compiling | Low |
| `SyncAlarms` roll-forward | Steps over cycles silently | Writes `open` rows, capped | Row volume (bounded: ≤ 90 per reminder per sync, pruned at 90 days) | Low |
| `SyncAlarms` roll-forward (existing behaviour, not changed here) | With `dueAt` two or more cycles back, a sync one minute after today's ring also steps over today's occurrence; a Done tapped in the list afterwards completes tomorrow's. History makes this visible ("Not marked done" for an alarm that just rang) | Out of scope; owner call (Q6) | — | Medium |
| `capture_bar.dart` idle zone | Grows by a label and a chip row; toast offset and list bottom padding in `home_page.dart` assume `barHeight * 2` | Shared constant added to the four sites | Toast overlap if a site is missed | Low |
| `MainActivity` | `singleTop`, empty affinity: unsafe as a share target (5.8) | `ShareActivity` trampoline | Task bring-to-front differs per OEM; QA row | High if ignored |
| Shared text | Arbitrary length and content from another app, fed to a regex parser and into a title | Native cap + Dart sanitiser before `setText` | Over-stripping: ZWJ/ZWNJ must stay, Hindi and Bengali conjuncts need them | High |
| `ReminderConfirmation` | Unscrollable column; heading + quote + footnote can exceed the screen at 2.0x | Height cap + scroll inside the card | Layout shift for existing confirmation (covered by existing a11y test) | Medium |
| iOS Runner | No App Group yet (memory note confirms) | Owner adds capability to both targets | Without it Runner reads an empty private suite: harmless | Low |

## 8. Risks

- hi/bn template and history strings are machine drafts (`@@x-review: pending`). Hindi and Bengali put the verb last, so a name or time typed after
  "फ़ोन करना है " reads less naturally than in English; the parse is still correct.
- A browser shares a URL as the text; the title becomes the URL. Honest, ugly; Edit details fixes it (Q4).
- `getLaunchIntentForPackage` is expected to bring the existing Memō task forward and not create a second one; verified only on device (QA row).
- Swift for S2 cannot be compiled in this environment. The extension is one file and about 40 lines to keep review-by-reading credible; the owner's
  first Xcode build is the real check.
- Extension and app versions must match for App Store validation; Flutter does not set the extension's version (Owner steps).
- "This week" starts Monday (`DateTime.weekday`), not the locale's first day (Q7).
- History `at` for iOS Done from a delivered notification is when the background isolate ran, which is the tap time in practice.

## 9. Open questions (default applied if unanswered)

1. **Android share entry is a separate `ShareActivity`, not a filter on `MainActivity`** (5.8). Default: yes. Answer wanted before S1 starts. If
   refused: filter on `MainActivity` plus `launchMode="singleTask"`, and the alarm rows of the v2 QA matrix are re-run.
2. Heading is always "Shared to Memō"; no app name (5.12). Default: yes.
3. `occurrences.until` is a fifth column so "Snoozed 10 min" can be stated truthfully. Default: add it now (a later migration costs more). Without
   it the row would read "Snoozed, done 6:15 PM".
4. A shared URL: keep as the title (default), or also read `EXTRA_SUBJECT` (page title) and move the URL to the note? iOS: also accept URL items
   (`NSExtensionActivationSupportsWebURLWithMaxCount`)? Default: text only on both.
5. The Open / Done pill is a status, not a button: no retroactive "mark done". Default: status only.
6. Roll-forward steps over an occurrence that rang a minute ago when the reminder was already a cycle behind (audit row). Default: leave as is in v3.
7. Week starts Monday. Default: yes.
8. Shared text cap 200 code points for the parsed text and title. Default: 200; the rest is dropped, not moved to the note.
9. Prefill wording, e.g. "Call " rather than "Call someone ", "Pay bill ", "Every Friday ". Default: as listed in guidelines T1.2.

---------------------------------------------------------------------------------------------------
## C1 — Cancel / Clear while creating a reminder

Owner request, verbatim: "Need to add a cancel button or clear button for discarding edits or recording during creating new Reminders".
Baseline: `dev` at 31533b0 (0.3.0+5), 830 tests. Steps: `guidelines.md` § C1. Sources read: `capture_cubit.dart`, `capture_bar.dart`,
`reminder_confirmation.dart`, `voice/recording_panel.dart`, `voice/hold_recorder.dart`, `home_page.dart`, `memo_nav_bar.dart`, `memo_theme.dart`,
`test/capture_flow_test.dart`, `test/a11y_layout_test.dart`, `test/fakes.dart`.

### C1.1 Problem — audit of every capture phase

| Phase | Ways to throw the draft away today | Gap |
|---|---|---|
| idle | Nothing to throw away | — |
| typing | Backspace to empty; scrim tap discards only when text is empty and there is no clip | No visible control. With a clip attached (after "Type it instead", or a take recorded over typed words) the clip cannot be removed at all short of re-recording or killing the app |
| recording | Cancel (`cancelRecording`) | — |
| transcribing | Cancel (`cancelTranscription`): stops, keeps the clip, lands on the "Recording kept" panel | None here; the exit is the panel it lands on |
| voiceFailed | Type it instead, Save as voice note, Try again (discards, then records again). Scrim tap does nothing | No way out that does not keep the clip or switch the microphone on |
| confirming | Save, Edit details; scrim tap steps back to typing (not discoverable, and it leaves a shared or spoken text sitting in the field) | No Discard. While the time is unsure both Save and Edit details are disabled, so the card's only exits are picking a time or the scrim |
| saving | Transient | No control wanted; a discard here would race `commitVoice` |

### C1.2 Scope
- typing: a trailing "×" inside the text field.
- confirming (typed, spoken, voice-only, shared): a "Discard" text button under Edit details.
- voiceFailed: a "Discard" text button beside Try again.
- One guard in `CaptureCubit.discard()` so it is a no-op while saving.
- One new ARB key in en/hi/bn. Tests. No release bump.

All three controls call the existing `CaptureCubit.discard()`: stop any take, delete the draft clip, reset to idle.

### C1.3 Non-goals
- Undo, or a confirm dialog, for a discarded clip (C1.4, decision 4; Q1).
- Changes to recording or transcribing: both already have Cancel.
- Changing what the scrim tap does. Handling the Android back button (there is no `PopScope` on Home today; Q3).
- A second "clear text only, keep the clip" control. A new cubit method, state field, toast or animation.

### C1.4 Decisions (problem → options → pick)

1. **Typing control.** (a) `InputDecoration.suffixIcon` on the existing `TextField`; (b) a new child in the bar's `Row` before the mic; (c) a
   Cancel button beside Continue. Pick (a): it lives inside the field's `Expanded`, so the `Row`'s children, the mic's slot and the mic's position
   are untouched; it is the platform's own clear-button pattern; Flutter gives the suffix a 48 px minimum box. (b) adds a sibling that appears and
   disappears next to the mic, the shape of the earlier bug. (c) costs a row at 2.0x text.
2. **When "×" shows.** Whenever `phase == typing` (which already means "text or clip present"). Never in idle: nothing to clear.
3. **Label.** (a) reuse `commonCancel`; (b) one new key "Discard". Pick (b): Cancel already means "drop this take" while recording and "stop, keep
   the clip" while transcribing; a third meaning on the same flow is a trap. One key serves the two buttons and the "×" tooltip / semantics label.
4. **A recorded clip: confirm, Undo, or neither.** (a) confirm dialog when `hasClip`; (b) Undo toast (needs a second draft file, a restore path
   and toast plumbing through `HomeCubit`); (c) neither. Pick (c): the two existing clip-destroying actions (Cancel while recording, Try again)
   ask nothing, a clip is capped at `VoiceClip.maxLength`, and every C1 control is labelled Discard. Typed and shared text need no confirm.
5. **Focus after discard.** (a) keep the keyboard up; (b) let it close. Pick (b): zero code. The bar's listener already unfocuses on any phase
   other than typing, which is also what happens today when the field is backspaced to empty.
6. **Shared text.** `pullShare` acks the share after it is on screen, so Discard cannot bring it back. Discard returns to idle, and Home's existing
   listener (`phase → idle`) pulls the next queued share. No new code.
7. **voiceFailed layout.** (a) a fourth stacked button; (b) Try again and Discard in one centred `Wrap`. Pick (b): no extra height at normal text
   size; wraps to two lines at 2.0x / 320 px.
8. **Saving.** The card's Discard is enabled only in `confirming`; `discard()` also returns early in `saving`. The guard is one line and protects
   a clip that `commitVoice` is moving.

### C1.5 Acceptance checks
- Typing "abc": an "×" is in the field; tap → field empty, bar idle, quick-start chips back, keyboard closed.
- Typing with a clip attached: "×" removes text and clip; the draft file is gone.
- Confirmation (typed, spoken, voice-only, and with the unsure-time block showing): Discard → idle, nothing saved, draft file gone.
- Shared card: Discard → idle, the share does not come back; a second queued share shows next.
- "Couldn't turn that into text" and "Recording kept" panels: Discard → idle, draft file gone, microphone not started.
- While saving, Discard is disabled.
- The mic is the same `Element`, same left edge and size, from idle through typing, "×" tap, and recording.
- "×" and both Discard buttons are at least 44 × 44, carry the label "Discard", and nothing overflows at 390×844 @2.0x, 320×690 @1.0x,
  320×690 @2.0x in en, hi, bn. No new animation.
- Shared verify green; test count ≥ 830.

### C1.6 Risks
- A mis-tap on "×" (it sits next to the mic) loses the draft with no way back; with a clip that is up to `VoiceClip.maxLength` of speech (Q1).
- The suffix takes 48 px from the field: about 180 px of text width at 320 px. Single-line fields scroll, so nothing clips.
- The voiceFailed panel does not scroll. Its a11y case at 320×690 @2.0x is new; if the wrapped row overflows, cap and scroll the panel the way
  `ReminderConfirmation` does. Do not add that unless the test fails.
- hi/bn "Discard" are machine drafts (`@@x-review: pending`).

### C1.7 Open questions (default applied if unanswered)
1. Discarding a draft that holds a voice clip asks nothing. Default: no confirm, no Undo (decision 4). Alternative: a confirm only when `hasClip`.
2. Keyboard closes after "×". Default: yes (decision 5). Alternative: clear and keep typing (one `requestFocus` after `discard()`).
3. Android back while typing or confirming still leaves the app with the draft kept. Default: unchanged in C1.
4. Label "Discard" / "हटा दें" / "বাদ দিন", also read out for the "×". Default: as listed.
5. No version bump; C1 ships with the next release. Default: yes.
