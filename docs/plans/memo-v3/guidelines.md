# Memō v3 — implementation guidelines

Read `prd.md` first. Order: T1, H1, S1, S2. One phase = build, review, fix, one commit on `dev` (no feature branches, no PRs). Do the steps in
order. Kotlin lives in `android/app/src/main/kotlin/in/appamania/memo/` (package line is ``package `in`.appamania.memo``). Paths below that start
with `domain/`, `data/` or `presentation/` are under `lib/features/reminders/`.

## 0. Rules for every phase

Hard rules
- The v2 hard rules still hold (`docs/plans/memo-v2/guidelines.md` §0): do not touch `AlarmIds`, `fire_plan.dart`, `repeat_rule.dart`, shipped
  migrations, existing native entry fields; no colour literal outside `tokens.dart`; no user-visible literal outside ARB; state through Cubits; the
  mic `Listener` keeps its tree slot.
- Do not change `MainActivity`'s `launchMode` or `taskAffinity`. Do not reorder `_catchUp` in `lib/app.dart`: native queues drain before
  `SyncAlarms` (history attribution depends on it, PRD 5.4).
- Reuse before writing: `_Chip` (`capture_bar.dart`), `sectionLabelText` / `sectionLabelStyle`, `SectionCard`, `StatusPill`
  (`features/settings/permission_status_row.dart`), `formatTime` / `formatDate` / `formatWhen` / `isSameDay`, `motion()`, `NativeAlarm._call`,
  `ReminderConfirmation`, `UnsureTimeBlock`, `InMemoryRepository`, `themed()` and the `_cases` loop in `test/a11y_layout_test.dart`.
- No new pub dependency. No new channel. No new Cubit.
- Every new ARB key goes in `app_en.arb` (with `@key` metadata and placeholders), `app_hi.arb`, `app_bn.arb`. hi/bn are drafts; the files already
  carry `"@@x-review": "pending"`, leave it. The parity test in `test/l10n_test.dart` must stay green.
- Shared text is untrusted on every line that touches it. It reaches `setText` only through `sanitizeShared`.
- Commit messages and code comments in normal prose. Mark deliberate ceilings with `// ponytail:`.

Shared verify (run all, every phase)
```
fvm dart format --output=none --set-exit-if-changed .
fvm flutter gen-l10n && git diff --exit-code lib/l10n
fvm dart run tool/gen_tokens.dart --check
! grep -rn 'Color(0x' lib | grep -v lib/core/theme/tokens.dart
fvm flutter analyze
fvm flutter test
JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home fvm flutter build apk --debug
```
The gen-l10n line is a drift check: run `fvm flutter gen-l10n` after editing ARB, commit the generated files, then the diff must be empty.
Test count must not drop (baseline 762).

Commit subjects: `feat: T1 quick-start templates`, `feat: H1 per-occurrence history for repeats`, `feat: S1 share to Memō on Android`,
`feat: S2 share to Memō on iOS, release 0.3.0+5`.

---------------------------------------------------------------------------------------------------
## T1 — Quick templates

Files: `presentation/home/capture_bar.dart`, `presentation/home/home_page.dart`, three ARB files, `test/capture_flow_test.dart`,
`test/a11y_layout_test.dart`, `test/reminder_parser_hi_bn_test.dart`.

### T1.1 ARB keys

| Key | en | hi (draft) | bn (draft) |
|---|---|---|---|
| `quickStartLabel` | Quick start | झटपट शुरू करें | চটজলদি শুরু |
| `templateMedicine` | Take medicine | दवा लेना | ওষুধ খাওয়া |
| `templateMedicineFill` | Take medicine | दवा लेनी है | ওষুধ খেতে হবে |
| `templateBill` | Pay a bill | बिल भरना | বিল দেওয়া |
| `templateBillFill` | Pay bill | बिल भरना है | বিল দিতে হবে |
| `templateCall` | Call someone | किसी को फ़ोन करना | কাউকে ফোন করা |
| `templateCallFill` | Call | फ़ोन करना है | ফোন করতে হবে |
| `templateFollowUp` | Follow up | फ़ॉलो-अप | ফলো-আপ |
| `templateFollowUpFill` | Follow up | फ़ॉलो-अप करना है | ফলো-আপ করতে হবে |
| `templateWeekly` | Weekly routine | हर हफ़्ते का काम | সাপ্তাহিক কাজ |
| `templateWeeklyFill` (placeholder `day`, String) | Every {day} | हर {day} | প্রতি {day} |

Fill strings carry no trailing space; the code appends one (translators lose trailing spaces).

### T1.2 `capture_bar.dart`
- Add `static const quickStartExtent = 80.0;` on `CaptureBar` (label 18 + gap 8 + chip 44 + gap 8, rounded).
- New private `_QuickStart` widget in this file (it reuses the private `_Chip`; do not make a second chip):
  - `Semantics(header: true)` label: `Text(sectionLabelText(context, l.quickStartLabel), style: sectionLabelStyle(context).copyWith(color: c.ink70))`.
  - `SingleChildScrollView(scrollDirection: Axis.horizontal)` → `Row` of five `_Chip(label: …, dashed: true, onTap: …)` with `MemoSpace.space2`
    between. `_Chip` already gives the 44 px hit height and button semantics.
  - `day` for the weekly fill: `DateFormat.EEEE(Localizations.localeOf(context).languageCode).format(DateTime.now())`.
  - `onPick(String fill)` callback supplied by `_CaptureBarState`.
- In `_CaptureBarState.build`, the idle slot under `MemoChrome` (today: the `captureHintLine` text when `phase == idle`) becomes a `Column`: the
  `_QuickStart` block first, the existing hint line under it. Still `SizedBox.shrink()` in every other phase. Keep it outside `MemoChrome` and its
  `AnimatedSize`; add no animation.
- Pick handler in `_CaptureBarState`: `cubit.setText('${fill.trimRight()} '); _focus.requestFocus();`. The existing `BlocConsumer` listener already
  copies `state.text` into `_text` with the selection collapsed at the end; do not set the controller by hand.
- Do not touch `_Mic`, `_micKey`, or the fixed slots inside `MemoChrome`.

### T1.3 `home_page.dart` clearance
Four sites assume the bar zone is `MemoSpace.barHeight * 2` tall: the toast (`_toast`, line ~211), the list bottom padding (~449), `_EmptyState`
(~615), `_FailureState` (~646). Add `MediaQuery.textScalerOf(context).scale(CaptureBar.quickStartExtent)` to the first two; add the plain constant
to the two `const EdgeInsets` (drop `const`, or accept the unscaled value there and say so in a `// ponytail:` comment).

### T1.4 Tests
- `test/capture_flow_test.dart`: (1) idle shows "Quick start" and five chips; (2) tap "Take medicine" → `CaptureCubit.state.text == 'Take medicine '`,
  phase `typing`, the `TextField` has focus and `selection.baseOffset == 14`, chips gone; (3) type "8pm", Continue → confirmation with title "Take
  medicine"; (4) tap "Weekly routine" → text is `'Every ${DateFormat.EEEE('en').format(DateTime.now())} '` (the chip reads the real clock, so the
  test computes the day the same way).
- `test/a11y_layout_test.dart`: one `testWidgets('Home quick start: $tag')` inside the `_cases` loop, plus one explicit case at `Size(320, 690)`
  with text scale 2.0: no exception from `tester.takeException()`, every chip's `tester.getSize` height ≥ 44, run once per locale en/hi/bn.
- `test/reminder_parser_hi_bn_test.dart` (now = Fri 2026-11-20 14:30, as in that file): for each of en/hi/bn and each weekday, the weekly fill built
  with `DateFormat.EEEE(lang)` + a task + a time parses to `RepeatType.weekly` with exactly that weekday, with `language: 'en'` and with
  `language: lang`. For each of the four title fills per language, fill + a time phrase in that language ("8pm", "रात 9 बजे", "রাত ৯টায়") parses with
  `title == fill` and `ambiguity == null`. If a fill collides with a parser word, change the fill, not the parser.

Verify T1: shared verify. Device: keyboard up with empty field shows chips above it; TalkBack reads "Quick start" as a heading and each chip as a button.

---------------------------------------------------------------------------------------------------
## H1 — Per-occurrence history

Files: `data/reminder_db.dart`, `data/reminder_row.dart`, `data/reminder_repository_impl.dart`, `domain/repositories/reminder_repository.dart`,
new `domain/entities/occurrence.dart`, `domain/usecases/save_reminder.dart`, `apply_alarm_action.dart`, `sync_alarms.dart`,
`complete_reminder.dart` (comment only), `presentation/home/home_cubit.dart`, `presentation/alarm/alarm_cubit.dart`,
`presentation/detail/detail_cubit.dart`, `presentation/detail/detail_page.dart`, ARB, `test/fakes.dart`, tests.

### H1.1 Migration v4 — append to `ReminderDb.migrations`, edit nothing above it
```
// v4 — per-occurrence history for repeats. No foreign key: the pragma is
// off, and delete() removes both in one transaction.
[
  '''
  CREATE TABLE occurrences (
    reminder_id TEXT NOT NULL,
    due_at INTEGER NOT NULL,
    event TEXT NOT NULL,
    at INTEGER NOT NULL,
    until INTEGER
  )
  ''',
  'CREATE INDEX occurrences_by_reminder ON occurrences (reminder_id, due_at)',
],
```
`event` is `done | snoozed | open` (the Dart enum's `name`). `until` is set only for `snoozed`. All times are epoch milliseconds like `due_at`.

### H1.2 `domain/entities/occurrence.dart` (new, pure Dart)
- `enum OccurrenceEvent { done, snoozed, open }`
- `class Occurrence { reminderId, dueAt, event, at, until? }` (const, all final).
- `const historyDays = 90;`
- `List<DateTime> cyclesBetween(RepeatRule rule, DateTime from, DateTime before, {int cap = historyDays})`: `from`, then `rule.nextAfter` repeatedly
  while the value is before `before`; return the latest `cap`. Empty when `rule` does not repeat.
- `List<Occurrence> doneLog(Reminder was, Reminder next, DateTime at)`: `[]` when `!was.repeat.repeats || was.id == testReminderId`. Else
  `cyclesBetween(was.repeat, was.dueAt, next.dueAt)`: last → `done`, earlier ones → `open`, all with `at`.
- `List<Occurrence> snoozeLog(Reminder was, Reminder next, DateTime at)`: same guard; one `snoozed` for `was.dueAt`, `until: next.snoozedUntil`.
- `List<Occurrence> openLog(Reminder was, DateTime newDue, DateTime at)`: same guard; every cycle in `cyclesBetween(...)` → `open`.
- Display model, also here so it is unit-tested without widgets:
  `class OccurrenceRow { dueAt, DateTime? doneAt, int? snoozedMinutes; bool get done => doneAt != null; }`
  `List<OccurrenceRow> historyRows(List<Occurrence> log)`: group by `dueAt`; keep a group only if it has a `done` or an `open` event (PRD 5.5);
  `doneAt` = earliest `done.at`; `snoozedMinutes` = minutes from the first snooze's `at` to the last snooze's `until`, rounded, only when the group
  is done and has snoozes; newest `dueAt` first.
  `({int done, int total}) weekTally(List<OccurrenceRow> rows, DateTime now)`: rows with `dueAt` in the Monday-to-Monday local week containing `now`.
  `// ponytail: week starts Monday; use MaterialLocalizations.firstDayOfWeekIndex if a locale needs Sunday.`

### H1.3 Repository — three touches to the interface, no more
`domain/repositories/reminder_repository.dart`:
```
/// Insert or replace. [log] rows commit with it or not at all.
Future<void> save(Reminder reminder, {List<Occurrence> log = const []});
/// History for one reminder, newest occurrence first.
Future<List<Occurrence>> occurrences(String reminderId);
/// Drops history due before [before].
Future<void> pruneOccurrences(DateTime before);
```
`delete(String id)` keeps its signature.

`data/reminder_repository_impl.dart`:
- `save`: when `log` is empty keep today's single insert; else `_db.db.transaction` with the reminder insert and one insert per log row. One
  `_changes.add(null)` after.
- `occurrences`: `where: 'reminder_id = ?'`, `orderBy: 'due_at DESC, at ASC'`, `limit: 400` (`// ponytail: 90 days of a daily with snoozes fits`).
- `pruneOccurrences`: `DELETE … WHERE due_at < ?`. No `_changes` event.
- `delete`: transaction deleting from `occurrences` then `reminders`.
- Row mapping (`toRow` / `occurrenceFromRow`) goes in `data/reminder_row.dart` beside the reminder mapping.

`test/fakes.dart` `InMemoryRepository`: add `final log = <Occurrence>[]`; `save` appends `log` after the `failSave` check; `occurrences` filters
and sorts the same way; `pruneOccurrences` and `delete` remove. The subclasses in `usecases_test.dart`, `cubit_failures_test.dart` and
`home_page_test.dart` that override `save` add the `{List<Occurrence> log = const []}` parameter and pass it to `super`.

### H1.4 `SaveReminder` — the funnel
```
Future<void> call(Reminder reminder, {List<Occurrence> log = const []})
Future<void> done(Reminder reminder, DateTime at)
Future<void> snooze(Reminder reminder, DateTime at, {Duration? by, DateTime? until})
```
- `call`: the first `_repository.save(clean, log: log)` carries the log; the `needsSchedule` re-save in the `catch` does not (no duplicates).
- `done`: `final next = const CompleteReminder()(reminder, now: at); return call(next, log: doneLog(reminder, next, at));`
- `snooze`: same shape with `const SnoozeReminder()(reminder, now: at, by: by, until: until)` and `snoozeLog`.
- A `ScheduleFailure` after the row was written leaves the history written too. That is correct: the user did mark it done.

### H1.5 Call-site sweep (each is a one-line swap; behaviour otherwise unchanged)
| File | From | To |
|---|---|---|
| `apply_alarm_action.dart` | `_save(switch … CompleteReminder / SnoozeReminder)` | `switch` on action: `_save.done(reminder, at)` / `_save.snooze(reminder, at, by: snoozeBy)` |
| `home_cubit.dart` `complete` | `_save(const CompleteReminder()(reminder, now: DateTime.now()))` | `_save.done(reminder, DateTime.now())` |
| `home_cubit.dart` `snooze` | `_save(const SnoozeReminder()(…))` | `_save.snooze(reminder, DateTime.now(), by: by)` |
| `alarm_cubit.dart` `_finish` | takes `Reminder Function(Reminder, DateTime) change`, calls `_save(change(…))` | takes `Future<void> Function(Reminder r, DateTime now) write`; `done` passes `_save.done`, `snooze` passes `(r, now) => _save.snooze(r, now, until: until)` |
| `detail_cubit.dart` `_write` | same pattern | same change; `reopen` keeps `_save(const ReopenReminder()(r, now: now))` |

Leave alone: `detail_page.dart:319` and `snooze_sheet.dart:22` (pure previews), `archive_cubit.dart` reopen, `HomeCubit.undo` (restores a
one-off), `edit_cubit.dart`, `settings_cubit.dart` (test alarm), `RewallRepeats`. `ApplyAlarmAction` keeps passing the queued tap time `at` through.
Delete the `ponytail:` paragraph in `complete_reminder.dart`; the table exists now.

Guard, add to this phase's verify:
```
! grep -rn 'CompleteReminder()(\|SnoozeReminder()(' lib | grep -v 'usecases/save_reminder.dart\|detail_page.dart\|snooze_sheet.dart'
```

### H1.6 `SyncAlarms`
- In the roll-forward branch: `await _repository.save(current, log: openLog(reminder, current.dueAt, at));` (replaces the plain save for that
  branch; `openLog` already returns `[]` for the test reminder).
- After the loop, before `_scheduler.syncAll`: prune, and never let it stop the sync:
  `try { await _repository.pruneOccurrences(at.subtract(const Duration(days: historyDays))); } catch (_) {}` with a one-line comment saying alarms
  matter more than tidiness.
- Update the class doc comment (new step between 1 and 2).

### H1.7 Detail
`detail_cubit.dart`: `DetailReady` gains `final List<Occurrence> history` (default `const []`), kept by `copyWith`. `load()` reads
`_repository.occurrences(id)` only when `reminder.repeat.repeats`. The existing `changes` subscription already reloads after Done and Snooze.

`detail_page.dart`, repeats only, between the action block and the Delete button, only when `historyRows(history)` is not empty:
- Section label `detailHistory` (same `sectionLabelText` / `sectionLabelStyle` pattern as other sections).
- `historyWeek(done, total)` in 13 px `ink70`, hidden when `total == 0`.
- `SectionCard` with one private `_HistoryRow` per `OccurrenceRow`: a `Wrap` (so 320 px and 2.0x reflow, never clip) holding the date
  (`formatDate(context, row.dueAt)`, mono), the sentence, and `StatusPill(HealthStatus.allowed, text: l.commonDone)` or
  `StatusPill(HealthStatus.fix, text: l.historyOpen)`. Reusing `StatusPill` across features is intended; do not copy it.
- Sentence: not done → `historyNotDone`. Done with `snoozedMinutes` in 1..90 → `historySnoozedDone(minutes, time)`. Done with a longer snooze →
  `historySnoozedLongDone(time)`. Else → `historyDoneAt(time)`. `time` = `formatTime(context, doneAt)` when `isSameDay(doneAt, dueAt)`, else
  `formatWhen(context, doneAt, now)`.
- `Semantics` per row: one merged label (date, sentence, pill word). The pill is not a button.

### H1.8 ARB keys
| Key | en | hi (draft) | bn (draft) |
|---|---|---|---|
| `detailHistory` | History | पिछला रिकॉर्ड | আগের রেকর্ড |
| `historyWeek` (`done`, `total` int) | This week {done} of {total} done | इस हफ़्ते {total} में से {done} पूरे | এই সপ্তাহে {total}টির মধ্যে {done}টি হয়েছে |
| `historyDoneAt` (`time`) | Done at {time} | {time} पर हो गया | {time}-এ হয়েছে |
| `historySnoozedDone` (`minutes` int, `time`) | Snoozed {minutes} min, done {time} | {minutes} मिनट टाला, {time} पर हो गया | {minutes} মিনিট পিছিয়ে, {time}-এ হয়েছে |
| `historySnoozedLongDone` (`time`) | Snoozed, done {time} | टाला, {time} पर हो गया | পিছিয়ে, {time}-এ হয়েছে |
| `historyNotDone` | Not marked done | पूरा नहीं किया गया | হয়েছে বলে চিহ্নিত নয় |
| `historyOpen` | Open | बाकी | বাকি |

No string may say or imply "missed".

### H1.9 Tests
- `test/reminder_db_test.dart`: (1) a database created with `migrations[0..2]` and one repeat row opens at v4 with the row intact,
  `upgradedFrom == 3`, and `occurrences` empty; (2) `save(log:)` + `occurrences()` round-trip every field including a null `until`; (3) `delete`
  removes the reminder's history and leaves another reminder's; (4) `pruneOccurrences` removes only older rows.
- New `test/occurrence_test.dart` (pure): `cyclesBetween` daily, weekly `{1,3}`, cap; `doneLog` for on-time, early, and two cycles behind (open +
  done); one-off and `memo-test` give `[]`; `historyRows` merges snooze + done into one row with minutes, hides a snooze-only group, shows an
  open group, keeps done when both open and done exist; `weekTally` across a Monday boundary.
- `test/write_path_test.dart`: `SaveReminder.done` on a daily writes one done row keyed by the old `dueAt` and none on the `needsSchedule` re-save
  (use `FakeScheduler.fail`); `SaveReminder.snooze` on a repeat writes `until`; `ApplyAlarmAction` with `at` a day in the past stores that `at` and
  the occurrence of that day; `SyncAlarms` three cycles behind writes open rows for the stepped-over cycles, one cycle behind writes none; a
  second `SyncAlarms` adds none; rows older than 90 days are gone after a sync; a throwing `pruneOccurrences` still reaches `syncAll`.
- `test/home_page_test.dart` or `cubit_failures_test.dart`: `HomeCubit.delete` then `undoDelete` leaves `repo.log` intact; `commitPendingDelete`
  empties it for that id.
- `test/detail_page_test.dart`: a daily with seeded history shows "This week 1 of 2 done", "Snoozed 10 min, done 6:15 PM", "Not marked done"; a
  one-off shows no History.
- `test/a11y_layout_test.dart`: extend the existing `Detail: $tag` case with a seeded history (hi locale for one of them).

Verify H1: shared verify + the grep in H1.5. Device (Samsung, `adb -s RZCTC0T77MD`): update over a 0.2.0+4 debug install keeps reminders; Done
from the lock-screen alarm with Memō killed, then open Memō → Detail shows the row with the tap time.

---------------------------------------------------------------------------------------------------
## S1 — Share to Memō, Android

Blocked on PRD Q1 only in the sense that the owner may veto `ShareActivity`; the default is to build what follows.

Files: `AndroidManifest.xml`, new `ShareActivity.kt`, `MainActivity.kt`, `data/alarm/native_alarm.dart`, new `data/share_inbox.dart`,
`presentation/home/capture_cubit.dart`, `reminder_confirmation.dart`, `home_page.dart`, `lib/app.dart`, ARB, tests.

### S1.1 Native
`AndroidManifest.xml`, inside `<application>` after `MainActivity`:
```
<!-- Share target. A trampoline, not MainActivity: a share opens inside the
     sharing app's task and would start a second Flutter engine there. -->
<activity
    android:name=".ShareActivity"
    android:exported="true"
    android:theme="@android:style/Theme.NoDisplay"
    android:excludeFromRecents="true"
    android:noHistory="true"
    android:taskAffinity="">
    <intent-filter>
        <action android:name="android.intent.action.SEND"/>
        <category android:name="android.intent.category.DEFAULT"/>
        <data android:mimeType="text/plain"/>
    </intent-filter>
</activity>
```
No `android:label`: the share sheet shows the app label "Memō". No new permission.

`ShareActivity.kt` (new, plain `android.app.Activity`, about 40 lines with the store):
- `onCreate`: after `super`, if `intent.action == Intent.ACTION_SEND && intent.type == "text/plain"`, read
  `intent.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString()`, `take(4000)`, skip when blank, `ShareStore(this).add(text)`. Then
  `packageManager.getLaunchIntentForPackage(packageName)?.let(::startActivity)` and `finish()`, all inside `onCreate` (`Theme.NoDisplay` requires
  finishing before `onResume`). Whole body in `try/catch (e: Exception)` that still finishes: a malformed intent must not crash.
- Never read `EXTRA_STREAM`, `clipData`, `EXTRA_HTML_TEXT` or the referrer.
- `class ShareStore(context)` in the same file: SharedPreferences file `memo_shares`, key `pending`, a JSON array of `{id, text, at}`
  (`id` = `UUID.randomUUID().toString()`, `at` = `System.currentTimeMillis()`). `add` appends and keeps the latest 20; `pending(): String`;
  `ack(id: String)` removes that id. Mirror the JSON-in-prefs style of `AlarmStore.kt`.

`MainActivity.kt`, two cases in the existing `memo/alarm` handler: `"pendingShares" -> result.success(ShareStore(this).pending())` and
`"ackShare" -> { ShareStore(this).ack(call.argument<String>("id")!!); result.success(null) }`. Nothing else in this file changes.

### S1.2 Dart data — `native_alarm.dart`, new `data/share_inbox.dart`
`NativeAlarm`: `Future<String> pendingShares() async => await _call<String>('pendingShares') ?? '[]';` and
`Future<void> ackShare(String id) => _call<void>('ackShare', {'id': id});`.

`share_inbox.dart`:
- `const sharedTextMax = 200;`
- `String sanitizeShared(String raw)`, in this order:
  1. keep the first 4,000 code units (the native cap again; never trust the other side);
  2. `\r \n \t U+2028 U+2029` → space;
  3. remove `U+0000–U+001F`, `U+007F–U+009F`, `U+200B`, `U+200E`, `U+200F`, `U+202A–U+202E`, `U+2060–U+2069`, `U+FEFF`. **Keep `U+200C` and
     `U+200D`**: Hindi and Bengali conjuncts need them;
  4. collapse whitespace runs to one space, trim;
  5. `String.fromCharCodes(text.runes.take(sharedTextMax))`, `trimRight()`.
     `// ponytail: cuts by code point, may split a grapheme cluster at the cap; use package:characters if that shows.`
- `class SharedText { final String id, text; }`
- `class ShareInbox { const ShareInbox(this._native); Future<SharedText?> next(); Future<void> ack(String id); }`. `next()`: read `pendingShares`,
  decode defensively (wrong shape, non-string fields, `FormatException` → treat the entry as empty), sanitise each in order; an entry that is empty
  after sanitising is acked and skipped; return the first non-empty. Any `NativeAlarmError` (including iOS before S2, where the method is not
  implemented) → `null`. `ack` swallows `NativeAlarmError`.
- Register in `lib/core/di.dart`: `..registerSingleton(ShareInbox(native))`.

### S1.3 `capture_cubit.dart`
- `CaptureState`: `final bool shared;` (default `false`), in the constructor and `copyWith({bool? shared})`, exactly like `spoken`.
- `setText` passes `shared: false` next to `spoken: false`.
- Constructor: optional `this.shares` (`final ShareInbox? shares`), default null so the existing test constructions compile unchanged.
- New:
  ```
  /// A text shared from another app goes straight to the confirmation, like a
  /// transcript. Only from idle: never over something the user is doing.
  Future<bool> pullShare()
  ```
  Return false when `shares == null` or `state.phase != CapturePhase.idle`. `final next = await shares!.next();` return false when null, closed, or
  no longer idle. Then `setText(next.text); emit(state.copyWith(phase: CapturePhase.confirming, shared: true)); await shares!.ack(next.id);
  return true;`. Ack comes after the emit: a crash in between shows the share again, it never loses it.
- No change to `save()`, `canSave`, `unsure`: the ambiguity gate applies untouched. `save()` already resets to a fresh `CaptureState`.
- `lib/app.dart`: pass `shares: sl<ShareInbox>()` in the `/` route's `CaptureCubit(...)`.

### S1.4 `reminder_confirmation.dart`
- When `state.shared`: replace the "You wrote / You said" line with (a) a header `Semantics(header: true)` using `sectionLabelText(context,
  l.shareTitle)` / `sectionLabelStyle`, (b) the quote: `Text(state.text, maxLines: 3, overflow: TextOverflow.ellipsis)` in `MemoType.body`,
  `ink70`, with a 2 px `c.hairline` left border and `space3` left padding. The interpreted title gets `maxLines: 3` + ellipsis in the shared case.
- Under the two buttons when `state.shared`: `l.shareFootnote`, 13 px, `ink70`, centred.
- Make the card safe for the extra height at 2.0x: wrap the card's `Column` in `SingleChildScrollView` inside
  `ConstrainedBox(maxHeight: MediaQuery.sizeOf(context).height - MediaQuery.paddingOf(context).top - MemoSpace.space6)`. This also protects the
  existing unsure block. The existing confirmation a11y test must stay green.
- Shared text is rendered only as `Text` data. Never pass it to a route, a `Uri`, a file name or a format string.

### S1.5 `home_page.dart`
- `Future<void> _pullShare()` on `_HomePageState`: `if (!await context.read<CaptureCubit>().pullShare() || !mounted) return;` then bring Home
  forward unless an alarm is on top:
  `final router = GoRouter.maybeOf(context); final top = router?.routerDelegate.currentConfiguration.last.matchedLocation;`
  `if (top != null && top != '/' && !top.startsWith('/alarm')) router!.go('/');`
  (`maybeOf`: the existing Home widget tests pump without a router.)
- Call it from: `initState` in a post-frame callback (cold start; Home is not built until onboarding is done, so the gate is free), the existing
  `AppLifecycleListener.onResume`, and a `BlocListener<CaptureCubit, CaptureState>` with
  `listenWhen: (a, b) => a.phase != CapturePhase.idle && b.phase == CapturePhase.idle` (the next queued share, one at a time).
- The scrim tap in the `confirming` case stays `backToTyping()`: the shared text lands in the field for editing.

### S1.6 ARB keys
| Key | en | hi (draft) | bn (draft) |
|---|---|---|---|
| `shareTitle` | Shared to Memō | Memō में भेजा गया | Memō-তে পাঠানো হয়েছে |
| `shareFootnote` | Only what you share. Memō never reads your mail. | सिर्फ़ वही जो आप भेजते हैं। Memō आपकी मेल कभी नहीं पढ़ता। | শুধু আপনি যা পাঠান। Memō কখনও আপনার মেল পড়ে না। |

### S1.7 Tests
- New `test/share_inbox_test.dart`: sanitiser table — newlines and tabs become one space; NUL / ESC / C1 removed; `U+202E` and `U+2066` removed;
  `"क्‍ष"` (with ZWJ) and a Bengali ZWNJ sequence unchanged; 50,000 `'a'` → length 200; an emoji at the cap is not split into a lone surrogate;
  only-control input → `''`. `ShareInbox.next()` with `TestDefaultBinaryMessengerBinding` mocking `memo/alarm`: skips and acks an empty entry,
  returns the first real one, returns null on malformed JSON, on a thrown `PlatformException`, and on `MissingPluginException`.
- `test/capture_cubit_test.dart` (fake `ShareInbox` subclass): `pullShare` from idle → phase `confirming`, `shared` true, text set, ack called once;
  from `typing` → false, nothing acked; "Call the bank" → `canSave` false until `chooseTime`; "Dentist Friday 3pm" → `canSave` true but the
  repository stays empty until `save()`; after `save()` state is fresh and `shared` false; `setText` clears `shared`.
- `test/capture_flow_test.dart`: Home with a queued share shows "Shared to Memō", the quote, the footnote, a disabled Save for a timeless text; after
  Save the second queued share appears; with capture in `typing` the share waits and appears after discard.
- `test/a11y_layout_test.dart`: shared confirmation with a 200-character Bengali text and an unsure block, in the `_cases` loop plus 320×690 @2.0:
  no exception.

Verify S1: shared verify + `cd android && JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home ./gradlew :app:compileDebugKotlin`.
Device:
```
adb -s RZCTC0T77MD shell am start -a android.intent.action.SEND -t text/plain --es android.intent.extra.TEXT "Dentist Friday 3pm" -n in.appamania.memo/.ShareActivity
```
with Memō killed, backgrounded, on Settings, and during a ringing alarm; then a real share from a browser and from a messaging app; check Recents
shows a single Memō card each time.

---------------------------------------------------------------------------------------------------
## S2 — Share to Memō, iOS; release 0.3.0+5

Swift is not compiled in this environment. Keep every Swift change minimal and reviewable by reading. Do not edit `project.pbxproj`,
`Runner.entitlements` or the Podfile: the owner does the Xcode work (Owner steps).

Files: `ios/Runner/AlarmPlugin.swift`; new `ios/ShareExtension/ShareViewController.swift`, `ios/ShareExtension/Info.plist`,
`ios/ShareExtension/ShareExtension.entitlements`, `ios/ShareExtension/{en,hi,bn}.lproj/Localizable.strings`; `pubspec.yaml`,
`lib/core/app_version.dart`, `README.md`, new `docs/plans/memo-v3/qa-matrix.md`.

### S2.1 Shared contract (both Swift sides)
`UserDefaults(suiteName: "group.in.appamania.memo")`, key `"shares"`, value `[[String: Any]]` with `id` (String, UUID), `text` (String), `at`
(Int, epoch ms). Latest 20 kept. Same JSON shape as Android once serialised.

### S2.2 `ios/Runner/AlarmPlugin.swift` — two cases before `default`
- `"pendingShares"`: read the array (missing suite or key → `[]`), `JSONSerialization` to a String, `result(json)`.
- `"ackShare"`: read `id` from the arguments, write the array back without it, `result(nil)`.
No Dart change: `ShareInbox` already calls these, and until the owner enables the App Group the suite is private and empty, which is harmless.

### S2.3 `ios/ShareExtension/ShareViewController.swift` (about 40 lines)
- `class ShareViewController: UIViewController`, no storyboard, clear background.
- `viewDidAppear`: first `NSItemProvider` among `extensionContext?.inputItems` (as `NSExtensionItem`) `.attachments` that
  `hasItemConformingToTypeIdentifier(UTType.plainText.identifier)`; `loadItem(forTypeIdentifier:)`; accept `String` (or `NSAttributedString`'s
  `.string`); on the main queue: trim, `prefix(4000)`, skip when empty, append to the suite array (S2.1), keep the latest 20.
- Then a `UIAlertController` with message `NSLocalizedString("share_added", comment: "")` (or `"share_nothing"` when no text was found) and one
  OK action calling `extensionContext?.completeRequest(returningItems: nil)`.
- No network, no Flutter import, no file access, no logging of the text.

`Localizable.strings`:
| Key | en | hi (draft) | bn (draft) |
|---|---|---|---|
| `share_added` | Added to Memō. Open Memō to set the time. | Memō में जोड़ा गया। समय तय करने के लिए Memō खोलें। | Memō-তে যোগ হয়েছে। সময় ঠিক করতে Memō খুলুন। |
| `share_nothing` | Memō can only take text. | Memō सिर्फ़ टेक्स्ट ले सकता है। | Memō শুধু টেক্সট নিতে পারে। |
| `OK` | OK | ठीक है | ঠিক আছে |

`Info.plist`: `CFBundleDisplayName` = `Memō`, `CFBundleShortVersionString` = `$(MARKETING_VERSION)`, `CFBundleVersion` =
`$(CURRENT_PROJECT_VERSION)`, `NSExtension` → `NSExtensionPointIdentifier` = `com.apple.share-services`, `NSExtensionPrincipalClass` =
`$(PRODUCT_MODULE_NAME).ShareViewController`, `NSExtensionAttributes` → `NSExtensionActivationRule` → `NSExtensionActivationSupportsText` = true.
`ShareExtension.entitlements`: `com.apple.security.application-groups` = [`group.in.appamania.memo`].

### S2.4 Release
- `pubspec.yaml` `version: 0.3.0+5`; `lib/core/app_version.dart` to match (`test/app_version_test.dart` enforces it).
- `README.md`: version line (line 5), "What it does" gains three bullets (quick-start chips; history for repeats with "This week N of M done" and
  the 90-day window, wording "Not marked done", never "missed"; Share to Memō on both platforms with "nothing is saved until you tap Save"), the
  TestFlight notes heading, the "as of 0.2.0+4" sentence, the Quality status heading, and the schema note (v4) wherever v3 is mentioned.
- `docs/plans/memo-v2/prd.md` is not edited.
- New `docs/plans/memo-v3/qa-matrix.md`, same header, columns and ADB notes as the v2 file, "Build 0.3.0+5", rows:

| # | Check |
|---|---|
| 1 | Update over 0.2.0+4: reminders, alarms and settings intact; a repeat's Detail shows no History yet |
| 2 | Quick start: chips under the empty field, with the keyboard up, in en / hi / bn; each chip prefills, cursor at end; gone while typing |
| 3 | "Weekly routine" + task + time saves a weekly repeat on today's weekday in en, hi, bn |
| 4 | Quick start at text size 200 %, smallest width, both; TalkBack / VoiceOver reads the heading and five buttons |
| 5 | History: Done from the list, Detail, alarm screen, notification action, native alarm with Memō killed — each adds one row with the right time |
| 6 | History: snooze 10 min then Done shows one row "Snoozed 10 min, done …"; a running snooze shows no row |
| 7 | History: leave a daily unanswered for three days → "Not marked done" rows; the word "missed" appears nowhere |
| 8 | History: delete then Undo keeps it; delete and wait removes it; test alarm leaves none; time-zone change does not duplicate rows |
| 9 | Share (Android): text from a browser and a messaging app; Memō killed / background / on Settings; one Memō card in Recents |
| 10 | Share: text with a time saves in two taps; text without a time shows Confirm time and Save is off; nothing saved without a tap |
| 11 | Share: during a ringing alarm the alarm stays; the card is there after Done |
| 12 | Share: very long text, emoji, Hindi and Bengali text with conjuncts render correctly and are cut cleanly |
| 13 | Share (iOS): Memō in the share sheet for selected text; extension confirms in the device language; opening Memō shows the card; two shares in a row |
| 14 | Share at 200 % text and smallest width: card scrolls, nothing clipped |

Android column is n/a for 13; iOS columns are n/a for 9.

Verify S2: shared verify. Owner, after Owner steps: `fvm flutter build ios --debug --no-codesign`, then rows 13 and 14 on a device.

---------------------------------------------------------------------------------------------------
## Owner steps (manual, not for the implementer)

Before S1: answer PRD Q1 (ShareActivity) or accept the default.

For S2, in Xcode (`ios/Runner.xcworkspace`), after the S2 commit:
1. File → New → Target → Share Extension. Product name `ShareExtension`, language Swift, bundle id `in.appamania.memo.ShareExtension`, embed in
   Runner. Do not activate the new scheme when asked.
2. The wizard may overwrite `ios/ShareExtension/ShareViewController.swift` and `Info.plist`. Right after creating the target run `git checkout -- ios/ShareExtension` to restore the repo files, delete only `MainInterface.storyboard` (Move to Trash) and make sure it is out of the target. If Xcode made `ShareExtension` a synchronized folder, add `Info.plist` and the entitlements file as membership exceptions so they are not copied as resources. Then add the repo files to the target: the Swift file, `Info.plist`, entitlements, the three `.lproj/Localizable.strings` (add hi and bn as localisations).
3. Target `ShareExtension` → Build Settings: `INFOPLIST_FILE = ShareExtension/Info.plist`, `CODE_SIGN_ENTITLEMENTS =
   ShareExtension/ShareExtension.entitlements`, iOS Deployment Target 17.0, `MARKETING_VERSION = $(FLUTTER_BUILD_NAME)`, `CURRENT_PROJECT_VERSION = $(FLUTTER_BUILD_NUMBER)`, and set the target's Debug/Release base configuration to `Flutter/Debug.xcconfig` / `Flutter/Release.xcconfig` (as Runner does) so those variables resolve. Versions must equal the app's on every release or App Store Connect rejects it (ITMS-90473); never hardcode them.
4. Signing & Capabilities → `+ Capability` → App Groups → `group.in.appamania.memo`, on **both** targets, Runner and ShareExtension. For Runner
   this adds the group to `ios/Runner/Runner.entitlements`; commit that change. Register the group and both app ids in the developer portal if
   automatic signing does not.
5. Target Runner → Build Phases: drag "Embed Foundation Extensions" above "Thin Binary" (otherwise Xcode reports a build cycle with Flutter's
   script phases).
6. Do not add the extension to the Podfile. It links no pods.
7. Build, run on a device, select text in Notes → Share → Memō. Commit the `project.pbxproj` and entitlements changes.

Native-speaker review of the new hi/bn strings (T1.1, H1.8, S1.6, S2.3) before any store build, as for v2.

---------------------------------------------------------------------------------------------------
## C1 — Cancel / Clear while creating a reminder

PRD: `prd.md` § C1. Section 0 rules apply, the mic invariant above all. Baseline 830 tests. One commit on `dev`:
`feat: C1 discard a draft from the capture bar, confirmation and voice panel`.

Files: `presentation/home/capture_cubit.dart`, `presentation/home/capture_bar.dart`, `presentation/home/reminder_confirmation.dart`,
`presentation/voice/recording_panel.dart`, three ARB files plus generated l10n, `test/capture_cubit_test.dart`, `test/capture_flow_test.dart`,
`test/a11y_layout_test.dart`. Not touched: `home_page.dart`, `hold_recorder.dart`, `_Mic`, `_micKey`, the bar's `Row` children.

### C1.1 ARB key

| Key | en | hi (draft) | bn (draft) |
|---|---|---|---|
| `captureDiscard` | Discard | हटा दें | বাদ দিন |

`@captureDiscard` description: "C1: throws away the reminder being created (text, voice clip, parsed result)". Then `fvm flutter gen-l10n`.

### C1.2 `capture_cubit.dart`
First line of `discard()`: `if (state.phase == CapturePhase.saving) return;`, with a one-line comment (Save is moving the clip). Nothing else.
All existing callers (`tryAgain`, `openEditDetails`, the scrim) run outside `saving`.

### C1.3 `capture_bar.dart`
- `_field(context, cubit)` gains a `bool clear` parameter; the call site passes `typing` (already computed in the builder).
- In its `InputDecoration`: `suffixIcon: clear ? MemoIconButton(icon: Icons.close_rounded, label: context.l10n.captureDiscard, onPressed:
  cubit.discard) : null`. `MemoIconButton` is already imported (`memo_nav_bar.dart`) and gives the 44 px minimum, tooltip and semantics label.
- Nothing else. The listener already empties the controller and unfocuses when the state resets to idle. Do not add a child to the `Row`, do not
  wrap `_Mic`, do not set the controller or focus by hand.

### C1.4 `reminder_confirmation.dart`
After the Edit details `OutlinedButton`, before the share footnote: `SizedBox(height: MemoSpace.space1)` and
`TextButton(onPressed: state.phase == CapturePhase.confirming ? cubit.discard : null, child: Text(l.captureDiscard))`.
Enabled while the unsure-time block shows; disabled only while saving. Same for typed, spoken, voice-only and shared cards.

### C1.5 `recording_panel.dart`, `_failed`
Replace the last `TextButton` (Try again) with
`Wrap(alignment: WrapAlignment.center, spacing: MemoSpace.space2, children: [<the same Try again button>, TextButton(onPressed: cubit.discard,
child: Text(l.captureDiscard))])`. `_recording` and `_transcribing` are unchanged.
Deviation: the kept-clip row's `Flexible(PillValue)` becomes `Expanded(child: Align(alignment: Alignment.centerRight, child: PillValue(...)))`
so the pill stays right-aligned at 1.0x and still fits bn 320x690 @2.0x.

### C1.6 Tests
`test/capture_cubit_test.dart`
1. `discard from typing with a clip deletes the draft and returns to idle`.
2. `discard on a shared confirmation returns to idle; the share is acked once and not offered again` (`FakeShares`, `pullShare`, `discard`,
   `pullShare`).
3. `discard from voiceFailed deletes the clip and does not record`.
4. `discard while saving does nothing` (a `SaveReminder` that parks on a `Completer`; the draft file and phase are unchanged until it completes).

`test/capture_flow_test.dart`
5. `typing: the clear button appears with the first character and discards`: no `Icons.close_rounded` in idle; type "abc"; tap it; controller
   text empty, phase idle, "Quick start" back, field not focused.
6. Extend `the mic keeps its element from typing through recording`: same `Element`, same `getRect(...).left` and size across idle → typing
   (clear button visible) → clear tapped → recording.
7. `confirmation: Discard returns to idle`, once for a stated time and once with `_confirmTime` showing (Save disabled, Discard enabled).
8. `shared card: Discard drops it and the next share shows` (`FakeShares` with two texts).
9. Extend `an empty transcript offers the three ways out` to four; a second test taps Discard: panel gone, `media.hasDraft` false, phase idle.

`test/a11y_layout_test.dart`
10. In the existing `capture bar typing and ambiguous confirmation (bn)` case: the clear button and the card's Discard are each ≥ 44 × 44.
11. The same case once more at `Size(320, 690)` @2.0x: `_fits`.
12. New `Voice failed panel: 320x690 @ 2.0x`, per locale en/hi/bn, using that file's `_Voice` and `_EmptyStt`: `_fits`, Discard ≥ 44 high.

### C1.7 Verify
Shared verify (§0); test count ≥ 830. Device, light and dark, en and one of hi/bn:
- Type, tap "×": field empties, keyboard closes, chips return. TalkBack / VoiceOver reads "Discard, button".
- Hold the mic right after tapping "×": recording starts and the release stops it.
- Record, cancel the transcription, Discard on "Recording kept": back to the empty bar; the mic does not start.
- Share a text to Memō, Discard: card gone; opening Memō again does not show it.
- Text size 200 % on the smallest device: the card and the voice panel show Discard without clipping.
- Reduce motion on: no new movement.
