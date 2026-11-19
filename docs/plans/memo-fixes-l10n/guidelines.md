# Implementation guidelines — Memō fixes + l10n

Read `prd.md` first. Work on `dev`, one branch per phase (`fix/phase-a`, `feat/l10n-b`,
`feat/l10n-c`, `feat/polish-d`). Each phase merges green on its own; B must land before C/D.

Rules for the implementer
- Use `fvm flutter` / `fvm dart`. Absolute paths below are relative to `/Users/sp/Dev/memo`.
- Keep invariants from `README.md`: one write path (`SaveReminder`), SQL only in Dart, mic keeps one
  tree slot while recording (raw pointer events), no `Color(0x` outside `lib/core/theme/tokens.dart`,
  `tokens.dart` is generated — edit `tool/gen_tokens.dart`, then run `fvm dart run tool/gen_tokens.dart`.
- No new packages beyond those named. No new abstractions beyond those named.
- After every step: `fvm flutter analyze`. After every phase: the phase's Verify block.

Shared verify (every phase)
```
fvm flutter pub get
fvm dart format --output=none --set-exit-if-changed .
fvm flutter analyze
fvm dart run tool/gen_tokens.dart --check
! grep -rn 'Color(0x' lib | grep -v lib/core/theme/tokens.dart
fvm flutter test
TZ=Europe/London fvm flutter test test/fire_plan_test.dart test/usecases_test.dart
TZ=America/New_York fvm flutter test test/fire_plan_test.dart test/usecases_test.dart
```

---------------------------------------------------------------------------------------------------
## PHASE A — Bugs

Step order: A9, A7, A6 fakes, A1, A2, A5, A6, A8, A10, A11, A3+A4, A12. Commit per item.

### A0 test fakes — `test/fakes.dart`
- `InMemoryRepository`: add `bool failSave = false;` — `save()` throws `StateError('db')` when true.
  Add `bool failDelete = false;` — same in `delete()`.
- `FakeScheduler`: add `bool failSync = false;` — `syncAll()` throws `StateError('sync')` when true.

### A9 `lib/features/reminders/domain/usecases/sync_alarms.dart`
- Delete the block `if (current.needsSchedule) { current = current.copyWith(needsSchedule: false); }`.
- After `await _scheduler.syncAll(live);` add: for each `r` in `live` where `r.needsSchedule`,
  `await _repository.save(r.copyWith(needsSchedule: false));`. If `syncAll` throws, let it propagate
  (flags stay set; `_catchUp` already runs it in `finally`).
- Test `test/usecases_test.dart`: group `SyncAlarms` → (1) flagged row + `failSync` → throws, row still
  `needsSchedule`; (2) success → flag cleared.

### A7 new `lib/features/reminders/domain/usecases/reopen_reminder.dart`
```dart
class ReopenReminder {
  const ReopenReminder();
  /// A one-off whose time passed moves to the next whole hour so it rings.
  Reminder call(Reminder r, {required DateTime now}) => r.copyWith(
    clearDone: true, nagCount: 0, clearSnooze: true,
    dueAt: r.repeat.repeats || r.dueAt.isAfter(now)
        ? r.dueAt : DateTime(now.year, now.month, now.day, now.hour + 1));
}
```
- `archive_cubit.dart` `reopen`: `_save(const ReopenReminder()(reminder, now: DateTime.now()))`.
- `detail_cubit.dart` `reopen`: `_write((r, now) => const ReopenReminder()(r, now: now))`.
- Tests in `test/usecases_test.dart`: past one-off → next hour, not done; future one-off keeps `dueAt`.

### A1 voice draft — files: `edit_cubit.dart`, `capture_cubit.dart`, `capture_bar.dart`, `media_store.dart`
1. `MediaStore`: add `bool get hasDraft => File(draftVoicePath).existsSync();` and
   `Future<void> uncommitVoice(String id)` — if `voicePath(id)` exists rename it to `draftVoicePath`,
   then `await removeSound?.call(id)`.
2. `EditCubit` constructor, `existing == null` branch: build from `draft` when given:
   `title: draft?.title ?? ''`, `note: draft?.note ?? ''`, `dueAt: draft?.dueAt ?? _nextHour(...)`,
   `repeat: draft?.repeat ?? RepeatRule.none`, `tag: draft?.tag`,
   `nagMin: draft == null ? defaultNagMin : draft.nagMin`,
   `readAloud: draft?.readAloud ?? readAloudDefault`, `hasClip: draftClip`, `draftClip: draftClip`.
   Add field `final bool _inheritedDraft;` initialised `_inheritedDraft = draftClip` in the initializer list.
3. `EditCubit.close()`: `if (!_saved && !_inheritedDraft) await media?.discardDraft();`
4. `EditCubit.save()` media block: `final ok = await m.commitVoice(reminder.id);
   reminder = reminder.copyWith(hasVoice: ok);` (keep the `removeClip` branch).
5. `CaptureCubit.save()`: same — `hasVoice: await media!.commitVoice(reminder.id)`.
6. `CaptureCubit`: add `void syncClip()` — if `state.hasClip && !(media?.hasDraft ?? false)`, emit
   `state.copyWith(hasClip: false)`; if then `state.text.trim().isEmpty`, emit `CaptureState(readAloud: state.readAloud)`.
7. `capture_bar.dart` `_more`: pass `draft: cubit.draft().copyWith(title: cubit.state.title,
   readAloud: cubit.state.readAloud)`; after the sheet: `if (saved) { await cubit.discard(); } else { cubit.syncClip(); }`.
- Tests: new `test/edit_cubit_test.dart` — (a) `EditCubit(save, draft: reminder('d','Bins',t), draftClip: true, media: m)`
  state has title 'Bins', `hasClip`; (b) close without save keeps `m.draftVoicePath` file; (c) capture test:
  delete the draft file then `save()` → saved reminder `hasVoice == false`.

### A2 `lib/features/reminders/presentation/home/capture_cubit.dart`, `lib/app.dart`
- Add top-level `int? _noNag() => null;` and `bool _yes() => true;`.
- Constructor params: `this.defaultNagMin = _noNag` typed `final int? Function() defaultNagMin;`,
  `bool Function() readAloudDefault = _yes` stored as `final bool Function() _readAloudDefault;`.
  Initial `super(CaptureState(readAloud: readAloudDefault()))`.
- Replace every `_readAloudDefault` read with `_readAloudDefault()`; `draft()` uses `defaultNagMin()`.
- `setText`: when `state.phase == CapturePhase.idle`, use `readAloud: _readAloudDefault()` in the emitted state.
- `app.dart`: `defaultNagMin: () => sl<AppPrefs>().defaultNagMin, readAloudDefault: () => sl<AppPrefs>().readAloudDefault`.
- EditCubit unchanged (built per sheet open; already live). Test: capture test with a mutable variable getter.

### A5 soft delete — `home_state.dart`, `home_cubit.dart`, `home_page.dart`
- `HomeReady`: add `final Reminder? pendingDelete;` + `copyWith(pendingDelete:, clearPendingDelete:)`.
  `upcoming` also skips `r.id == pendingDelete?.id`.
- `HomeCubit`: `Timer? _deleteTimer;`
  - `Future<void> delete(Reminder r)`: `await _commitDelete(); dismissUndo();` emit `pendingDelete: r`;
    `_deleteTimer = Timer(undoWindow, _commitDelete);`
  - `void undoDelete()`: cancel timer; emit `clearPendingDelete: true`.
  - `Future<void> _commitDelete()`: take `pendingDelete` (return if null), cancel timer,
    `try { await _delete(r.id); } catch (_) { emit error deleteFailed; }` then emit `clearPendingDelete: true`
    (guard `isClosed`).
  - `complete()`: call `await _commitDelete();` first.
  - `close()`: `_deleteTimer?.cancel();` then if `pendingDelete` set, `await _delete(id)` (no emit), then super.
- `home_page.dart`: `_Row.onDelete: () => cubit.delete(reminder)`. Toast: if `ready.pendingDelete != null`
  show `MemoToast(message: '${title} deleted', action: 'Undo', onAction: cubit.undoDelete)`, else existing undo toast.
- `detail_page.dart` `_delete` body text: `'It will stop ringing. This cannot be undone.'`.
- Tests `test/home_page_test.dart`: swipe left, tap 'Del' → row gone, "Pills deleted" shown, tap Undo → row back,
  repo still has it; second test: wait `HomeCubit.undoWindow` (`tester.pump(Duration(seconds: 6))`) → repo empty.

### A6 exceptions
- `CaptureCubit.save`: wrap `_save` in `try { } on ScheduleFailure { error = scheduleFailedMessage; }
  catch (_) { if committed: await media!.uncommitVoice(reminder.id); emit(state.copyWith(phase: CapturePhase.typing,
  error: saveFailedMessage)); return; }`. Track `committed` from step A1.5.
- `EditCubit.save`: same shape; on generic catch: uncommit if committed, `_saved = false`,
  emit `status: EditStatus.editing, error: saveFailedMessage`.
- `ArchiveState`: add `final String? error;`; `ArchiveCubit.reopen`: try/catch → emit with `error`
  (`ScheduleFailure` → `scheduleFailedMessage`, else `saveFailedMessage`); add `clearError()`.
  `archive_page.dart`: wrap body in `BlocListener` (listenWhen `b.error != null`) → SnackBar, then `clearError()`.
- `HomeCubit._write`: add `catch (_) { emit error saveFailedMessage }`; `load()` already catches.
- `DetailCubit._write`: add generic catch → `DetailReady.copyWith(error: saveFailedMessage)`.
  `delete()` → `Future<bool>`: try `_delete(id)` return true; catch → emit error `deleteFailedMessage`, return false.
  `detail_page.dart` `_delete`: `if (await cubit.delete()) navigator.pop();`
- `home_cubit.dart` next to `scheduleFailedMessage` add:
  `const saveFailedMessage = "Couldn't save. Nothing changed, try again.";`
  `const deleteFailedMessage = "Couldn't delete. Try again.";`
- Tests: one per cubit using `repo.failSave` / `repo.failDelete`; assert state not stuck and error set.

### A8 parser — `lib/features/reminders/domain/parser/reminder_parser.dart`
(a) Weekday: add `var fromWeekday = false;` set true in the weekday branch. After "Combine", before the
    weekly/daily block: `if (fromWeekday && !due.isAfter(now)) due = DateTime(due.year, due.month, due.day + 7, due.hour, due.minute);`
(b) Add `bool _valid(int y, int m, int d) { final t = DateTime(y, m, d); return t.month == m && t.day == d; }`.
    `_futureDate` returns `DateTime?`: try years `today.year .. today.year + 4`, return the first valid date
    not before `today`; else null. Explicit-year branch: `_valid(...) ? DateTime(...) : null`.
    In all three date branches: when the computed date is null, set `day = null` and **remove** the span
    (do not add to `timeSpans`) and restore `work` (use a local `before = work` copy before `take`, reassign on invalid).
(c) Relative regex unit group becomes
    `(minutes?|mins?|m|hours?|hrs?|h|days?|d|weeks?|w|months?|mos?|years?|yrs?|y)` and the switch keys on
    the full unit: minutes / hours / days / weeks as today; months: `_addMonths(now, n)`; years: `_addMonths(now, 12*n)`.
    `_addMonths(DateTime t, int n)`: target month `t.month + n`, day clamped to that month's last day
    (`DateTime(y, m + 1, 0).day`), keep hour/minute.
    Bare ordinal, new branch after the `d/m` branch and before weekdays:
    `RegExp(r'\b(?:on\s+)?the\s+(\d{1,2})(?:st|nd|rd|th)\b')` → next date ≥ today whose day == N, checking
    this month then the next 12 with `_valid`; invalid N (0, >31) ignored as in (b).
(d) `EditState`: add `bool pastBlocked(DateTime now) => isPastOneOff(now) && (existing == null || dueAt != existing!.dueAt);`
    `canSave` gains `&& !pastBlocked(DateTime.now())`. `edit_sheet.dart`: replace the "will not ring" text with
    `'That time has passed. Pick a later time.'`, shown when `state.pastBlocked(DateTime.now())`.
    `CaptureCubit.save`: if `!state.repeat.repeats && state.dueAt!.isBefore(_clock())` emit
    `error: 'That time has passed. Pick a later time.'` and return.
- Tests `test/reminder_parser_test.dart` (now = Fri 2026-11-20 14:30): "bins by friday" → 2026-11-27 09:00;
  "this friday at 9am" → 11-27 09:00; "dentist 29 feb 2027" → no date span, title keeps "29 feb 2027";
  "dentist 29 feb" → 2028-02-29; "31/04" → ignored; "in 2 months" → 2027-01-20 14:30; "in 1 year";
  31 Jan + 1 month → 28/29 Feb; "pay rent the 5th" → 2026-12-05 09:00 guessed. Edit test: past new one-off → Save disabled.

### A10 `lib/features/reminders/data/spoken_reminder.dart`
- Remove `const` from the constructor. Add `Future<void> _last = Future.value();`.
- Rename the body of `soundFor` to `Future<String?> _render(Reminder r)`; new `soundFor`:
  `final run = _last.then((_) => _render(r)); _last = run.then((_) {}, onError: (_) {}); return run;`
- Fix any `const SpokenReminder(` call sites (`grep -rn "SpokenReminder(" lib test`).
- Test `test/spoken_reminder_test.dart`: mock `memo/tts` with `TestDefaultBinaryMessengerBinding` handler that
  increments `active`, awaits 20 ms, records `maxActive`, decrements; fire 3 `soundFor` → `maxActive == 1`.

### A11 new `lib/core/ui/minute_clock.dart`
```dart
/// ponytail: one app-wide ticker; runs only while something listens and the app is foreground.
class MinuteClock extends ValueNotifier<DateTime> {
  MinuteClock._() : super(DateTime.now());
  static final instance = MinuteClock._();
  Timer? _timer; AppLifecycleListener? _life;
  // addListener: first listener → _start() and create _life(onResume: _start, onPause: _stop).
  // removeListener: last listener gone → _stop(), _life?.dispose(), _life = null.
  // _start(): value = DateTime.now(); _timer?.cancel(); _timer = Timer(<until next whole minute>, () { value = DateTime.now(); _start(); });
  // _stop(): _timer?.cancel(); _timer = null;
}
```
Override `addListener`/`removeListener` (call super), use `hasListeners` to detect first/last.
- `home_page.dart`: wrap the `builder:` body of the `BlocConsumer` in
  `ValueListenableBuilder<DateTime>(valueListenable: MinuteClock.instance, builder: (context, now, _) { ...existing, using now... })`
  and delete `final now = DateTime.now();`.
- Same in `alarm_page.dart` (the `late` computation) and `detail_page.dart` `_Body.build`.
- Test `test/minute_clock_test.dart`: pump a `ValueListenableBuilder` showing `now.minute`, `tester.pump(Duration(minutes: 1, seconds: 1))`
  → rebuilt; unmount → `MinuteClock.instance.hasListeners == false`.

### A3 + A4 Android `android/app/src/main/kotlin/com/appamania/memo/AlarmService.kt`
State: `private var current: JSONObject? = null`, `private val queue = ArrayDeque<JSONObject>()`.
- `notifId(reminderId) = (reminderId.hashCode() and 0x3FFFFFFF) or 0x10000000`;
  `missedId(reminderId) = notifId(reminderId) xor 0x20000000`. Delete `NOTIFICATION_ID`.
- `onStartCommand`, ring branch → `enqueue(entry)`:
  if `current == null` → `ring(entry)`; else if same `reminderId` as current → ignore;
  else replace any queued entry with the same `reminderId`, append, and post `notification(entry, ringing = false)`
  via `NotificationManager.notify(notifId, …)`. In every branch that does not call `ring`, re-call
  `startForeground(notifId(current), notification(current, true), …)`: each `startForegroundService` must be
  answered by a `startForeground`, even when the service is already foreground (else ANR/crash).
- Actions: `ACTION_DONE` / `ACTION_SNOOZE` keep `quietOccurrence` + `appendAction` (+ `snooze`), then `finish(reminderId)`.
  New `ACTION_STOP` (from Dart `stopRinging`): `quietOccurrence` only, then `finish(reminderId)`.
- `finish(id)`: cancel `notifId(id)`; remove it from `queue`; if `current?.reminderId == id` → `advance()`;
  if nothing is current and the queue is empty → `stopSelf()`.
- `advance()`: `player?.release()`; `handler.removeCallbacksAndMessages(null)`; `current = null`;
  `queue.removeFirstOrNull()?.let(::ring) ?: stopSelf()`.
- `ring(entry)`: `current = entry; ringing = reminderId;` `startForeground(notifId(reminderId), notification(entry, true), …)`
  (keep the Q+ service-type branch), overlay + `playLoop` as today, then
  `handler.postDelayed({ missed(entry); finish(reminderId) }, TIMEOUT_MS)`.
- `notification(entry, ringing: Boolean)`: request codes `notifId*4+0` (open), `+1` (done), `+2` (snooze);
  `setFullScreenIntent` and `setOngoing(true)` only when `ringing`; `setOnlyAlertOnce(true)` when not.
  Labels: `entry.optString("doneLabel").ifEmpty { "Done" }`, `optString("snoozeLabel").ifEmpty { "Snooze 10m" }`,
  channel name `optString("channelName").ifEmpty { "Alarms" }`.
- `missed(entry)`: channel `"missed"` (`IMPORTANCE_DEFAULT`, `setSound(null, null)`), notify `missedId(reminderId)`:
  title `entry.optString("missedText").ifEmpty { "Missed: " + entry.optString("title") }`,
  `setAutoCancel(true)`, content intent opens `memo:///reminder/<id>` (request code `notifId*4+3`, same flags as `alarmIntent`).
- `companion.stop(context)` → `stop(context, reminderId: String?)`: `context.startService(Intent(context, AlarmService::class.java).setAction(ACTION_STOP).putExtra("reminderId", reminderId))`;
  if `reminderId == null` keep `stopService`. Update `MainActivity` `"stopRinging"` to call it with the id.
- `onDestroy`: also `queue.clear(); current = null`.
- Dart `android_alarm_scheduler.dart` `_entries`: add `'missedText': 'Missed: ${r.title}'` (Phase B localizes).
- Device test on SM-G781B: two reminders same minute; leave one unanswered 2 min.

### A12 time-zone change
Kotlin `AlarmStore.kt`: add `var zone: String?` backed by prefs key `"zone"`.
`MainActivity` `"schedule"` and `"replaceAll"`: after saving, `store.zone = java.time.ZoneId.systemDefault().id`.
`AlarmReceiver.kt` `BootReceiver.onReceive`: if `intent.action == Intent.ACTION_TIMEZONE_CHANGED` and `store.zone != null`:
for each entry with `repeat != "none"`: `val wall = Instant.ofEpochMilli(at).atZone(ZoneId.of(store.zone)).toLocalDateTime()`;
`var t = wall.atZone(ZoneId.systemDefault()).toInstant().toEpochMilli()`; `if (t <= now) t = AlarmArm.next(t, repeat, now)!!`;
`entry.put("at", t)`. Then cancel+re-arm all as today; `store.zone = ZoneId.systemDefault().id`. Other actions: unchanged.
Dart:
- `AppPrefs`: `String? get lastTimeZone` / `setLastTimeZone(String)` (key `last_time_zone`).
- New `lib/features/reminders/data/rewall_repeats.dart`: `class RewallRepeats { const RewallRepeats(this._repo); Future<void> call(String from, String to) }`
  — for each live repeat: `final old = tz.TZDateTime.from(r.dueAt, tz.getLocation(from));`
  `final moved = tz.TZDateTime(tz.getLocation(to), old.year, old.month, old.day, old.hour, old.minute);`
  `await _repo.save(r.copyWith(dueAt: DateTime.fromMillisecondsSinceEpoch(moved.millisecondsSinceEpoch), clearSnooze: true));`
- `lib/core/di.dart`: register `RewallRepeats(repository)`.
- `app.dart` `_catchUp`, before `finally`: `final zone = (await FlutterTimezone.getLocalTimezone()).identifier;`
  `final last = sl<AppPrefs>().lastTimeZone; if (last != null && last != zone) { tz.setLocalLocation(tz.getLocation(zone)); await sl<RewallRepeats>()(last, zone); }`
  `await sl<AppPrefs>().setLastTimeZone(zone);` (wrap in try/catch; failures must not block sync).
- Test `test/usecases_test.dart`: daily 07:00 in `Asia/Kolkata`, rewall to `Europe/London` → 07:00 London wall time.

### Verify A
Shared verify, plus `cd android && ./gradlew :app:compileDebugKotlin && cd ..`, plus
`fvm flutter build apk --debug`, then owner device checks (see Owner steps).

---------------------------------------------------------------------------------------------------
## PHASE B — Localization foundation

### B1 deps and config
- `pubspec.yaml` `dependencies:` add (exact pins, same style):
  ```
  flutter_localizations:
    sdk: flutter
  intl: 0.20.3
  ```
  Under `flutter:` add `generate: true`. Fonts (after owner fetched files, see Owner steps):
  ```
    - family: Noto Sans Devanagari
      fonts:
        - asset: assets/fonts/NotoSansDevanagari-Regular.ttf
          weight: 400
        - asset: assets/fonts/NotoSansDevanagari-Medium.ttf
          weight: 500
        - asset: assets/fonts/NotoSansDevanagari-SemiBold.ttf
          weight: 600
    - family: Noto Sans Bengali   # same three weights, NotoSansBengali-*.ttf
  ```
  Add `assets: [assets/fonts/OFL-Noto.txt]` and in `main.dart` before `runApp`:
  `LicenseRegistry.addLicense(() async* { yield LicenseEntryWithLineBreaks(['Noto Sans'], await rootBundle.loadString('assets/fonts/OFL-Noto.txt')); });`
- New `l10n.yaml`:
  ```
  arb-dir: lib/l10n
  template-arb-file: app_en.arb
  output-localization-file: app_localizations.dart
  output-class: AppLocalizations
  nullable-getter: false
  format: true
  ```
  Generated `lib/l10n/app_localizations*.dart` is committed.

### B2 `lib/l10n/l10n.dart` (new)
- `export 'app_localizations.dart';`
- `Locale appLocale()`: override = `sl.isRegistered<AppPrefs>() ? sl<AppPrefs>().languageOverride : 'system'`;
  if not 'system' → `Locale(override)`; else first of `PlatformDispatcher.instance.locales` whose `languageCode`
  is in `{'en','hi','bn'}` → `Locale(code)`; else `Locale('en')`.
- `AppLocalizations l10n() => lookupAppLocalizations(appLocale());` — for cubits and data code.
- `extension L10nContext on BuildContext { AppLocalizations get l10n => AppLocalizations.of(this); }` — for widgets.
- `void useWesternDigits()`: copy `numberFormatSymbols['bn']` (from `package:intl/number_symbols_data.dart`)
  into a new `NumberSymbols(...)` with every field equal except `ZERO_DIGIT: '0'`; assign back; then
  `DateFormat.useNativeDigitsByDefaultFor('bn', false)`. Call it first thing in `configureDependencies()`.

### B3 AppPrefs + app root
- `AppPrefs`: `final revision = ValueNotifier<int>(0);`
  `String get languageOverride => _prefs.getString('language') ?? 'system';`
  `Future<void> setLanguageOverride(String v) async { await _prefs.setString('language', v); revision.value++; }`
- `app.dart` `build`: wrap `MaterialApp.router` in `ValueListenableBuilder<int>(valueListenable: sl<AppPrefs>().revision, …)`;
  add `localizationsDelegates: AppLocalizations.localizationsDelegates`, `supportedLocales: AppLocalizations.supportedLocales`,
  `locale: lang == 'system' ? null : Locale(lang)`, replace `title:` with `onGenerateTitle: (c) => c.l10n.appTitle`.
- `test/fakes.dart` `themed()` and the second `MaterialApp` in `test/home_page_test.dart` (line ~193): add the same
  two delegate/supportedLocales params. Tests keep English expectations (test locale is en).

### B4 ARB files `lib/l10n/app_en.arb`, `app_hi.arb`, `app_bn.arb`
- `@@locale` set; every key has an `@key` description in `app_en.arb` only; placeholders typed (`String` or `int`),
  **no `format` on int placeholders** (keeps 0-9). Plurals use `=1{…} other{…}` (hi and bn plural: one/other).
- Key naming: lowerCamel, screen prefix where ambiguous. Full key list = section B9. hi/bn values: natural
  everyday Hindi/Bengali, Western digits, keep "Memō". Mark the PR "translations need native review".

### B5 replace strings (one commit per file group)
Inventory (every literal in these must go; verify with the grep in Verify B):
`app.dart`; `core/ui/{memo_dialog,memo_nav_bar,memo_loader,minutes_sheet,memo_pickers}.dart`;
`features/onboarding/presentation/pages/{welcome_page,permission_primer_page}.dart`;
`features/reminders/presentation/home/{home_page,capture_bar,capture_sheets,capture_cubit,home_cubit}.dart`;
`edit/{edit_sheet,edit_cubit}.dart`; `detail/{detail_page,detail_cubit}.dart`; `alarm/alarm_page.dart`;
`archive/{archive_page,archive_cubit}.dart`; `voice/hold_recorder.dart`;
`widgets/{swipeable_reminder_row,check_control,reminder_row,repeat_segmented_control,weekday_selector,snooze_preset_row}.dart`;
`settings/{settings_page,settings_cubit}.dart`; `data/{spoken_reminder,media_store}.dart`;
`data/alarm/{local_notification_scheduler,android_alarm_scheduler,ios_alarm_scheduler}.dart`.
Rules:
- Widgets: `context.l10n.key`. Remove `const` where a child now reads l10n.
- Cubits / data / hold_recorder: `l10n().key`. `scheduleFailedMessage`, `saveFailedMessage`, `deleteFailedMessage`
  become getters: `String get scheduleFailedMessage => l10n().scheduleFailed;` (same name, so call sites stay).
- `SnoozePreset.label` becomes `String Function(AppLocalizations) label`; presets use `(l) => l.snooze10m` etc.
- `RepeatSegmentedControl._labels` → build in `build()` from `context.l10n`.
- `minutes_sheet.dart` `nagLabel`/`preAlarmLabel` take `(AppLocalizations l, int m)`; callers pass `context.l10n`
  (`showMinutesSheet(label:)` becomes `(m) => nagLabel(context.l10n, m)`).
- Weekday short names: `weekdayShort(BuildContext c, int weekday)` in `date_format.dart` =
  `DateFormat.E(_loc(c)).format(DateTime(2024, 1, weekday))` (1 Jan 2024 is a Monday). Use it in
  `capture_bar.dart _Chips._repeat`, `detail_page.dart _repeatLabel`, `weekday_selector.dart`.
- `local_notification_scheduler.dart`: action titles and channel name/description from `l10n()` at the time
  `_details()` / `initialize()` runs (iOS categories update on next launch — documented non-goal).

### B6 `lib/core/utils/date_format.dart` rewrite (all take `BuildContext c` first)
`_loc(c) = Localizations.localeOf(c).languageCode`; `_h24(c) = MediaQuery.alwaysUse24HourFormatOf(c)`.
- `formatTime(c, t)`: `(_h24(c) ? DateFormat.Hm(_loc(c)) : DateFormat.jm(_loc(c))).format(t)`.
- `formatDate(c, d)`: `DateFormat('EEE d MMM', _loc(c)).format(d)`; `formatLongDate(c, d)`: `DateFormat('d MMM y', _loc(c))`.
- `dayHeaderLabel(c, day, now)`: `c.l10n.today/tomorrow/yesterday` else `formatDate`.
- `formatWhen(c, at, now)`: `c.l10n.whenAt(dayPart, formatTime(c, at))` where dayPart = today label or `formatDate`.
- `formatLateness(c, late)`: `c.l10n.lateDays(n)` / `lateHours(n)` / `lateMinutes(n.clamp(1, 59))`.
- Keep `two()` and `isSameDay()`. Update every caller (`grep -rn "formatTime\|formatDate\|dayHeaderLabel\|formatWhen\|formatLateness\|formatLongDate" lib`).
- `memo_pickers.dart`: delete the `alwaysUse24HourFormat: true` MediaQuery override; Cupertino `use24hFormat: MediaQuery.alwaysUse24HourFormatOf(context)`.
- Test `test/date_format_test.dart`: pump `MaterialApp(locale: Locale('bn'), …)` with `MediaQuery(alwaysUse24HourFormat: false)`;
  assert `formatTime` of 20:05 contains `8:05` and no char in `০-৯`; same for `hi` and `en` 24h → `20:05`.

### B7 native strings (approach: Dart passes them)
- `android_alarm_scheduler.dart` `_entries`: `final l = l10n();` add `'doneLabel': l.notifDone, 'snoozeLabel': l.notifSnooze,
  'channelName': l.alarmChannel, 'missedText': l.missedAlarm(r.title)`.
- `ios_alarm_scheduler.dart` `_entries`: add `'doneLabel': l.notifDone, 'snoozeLabel': l.notifSnooze`.
- `ios/Runner/AlarmKitPlugin.swift`: `MemoFire` add `var doneLabel: String?` and `var snoozeLabel: String?`;
  `AlarmButton(text: LocalizedStringResource(stringLiteral: fire.doneLabel ?? "Done"), …)` and the snooze button likewise.
  `MemoSnoozeIntent.perform()` `MemoFire(...)` init passes `doneLabel: nil, snoozeLabel: nil`.
- Language change: `SettingsCubit.setLanguage(v)` → `await _prefs.setLanguageOverride(v); await sl<SyncAlarms>()(); await refresh();`
  (inject `SyncAlarms` as optional ctor param, default `sl<SyncAlarms>()` resolved lazily).
- iOS files (create as UTF-8 text; owner adds them in Xcode, see Owner steps):
  `ios/Runner/{en,hi,bn}.lproj/InfoPlist.strings` keys `NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription`,
  `NSAlarmKitUsageDescription` (en = current Info.plist text). `ios/Runner/{en,hi,bn}.lproj/Localizable.strings` keys
  `"Mark done"`, `"Snooze 10 minutes"`, `"Reminder"`, `"Title"`, `"Sound"`, `"Snooze alarm"` (App Intent titles/params).
  `Info.plist`: add `CFBundleLocalizations` array `en`, `hi`, `bn`.
- Android: `android/app/src/main/res/xml/locales_config.xml`
  `<locale-config xmlns:android="http://schemas.android.com/apk/res/android"><locale android:name="en"/><locale android:name="hi"/><locale android:name="bn"/></locale-config>`;
  `AndroidManifest.xml` `<application … android:localeConfig="@xml/locales_config">`. No `strings.xml` (label is the brand).

### B8 fonts — `tool/gen_tokens.dart`
- In `_type`, after the `mono` line write `static const fallback = ['Noto Sans Devanagari', 'Noto Sans Bengali'];`
  and in each style `fontFamilyFallback: fallback,` after `fontFamily:`. Regenerate tokens.
- `memo_theme.dart` `ThemeData(... fontFamilyFallback: MemoType.fallback, ...)`.
- Settings language sheet (B10) uses endonyms; they need these fonts.

### B9 ARB key list (en values; `{x}` = placeholder)
appTitle=Memō · cancel=Cancel · done=Done · save=Save · back=‹ Back · edit=Edit · delete=Delete · undo=Undo · on=On · off=Off ·
allowed=Allowed · notAllowed=Not allowed · working=Working · saving=Saving · set=Set · add=Add · tryAgain=Try again ·
today=Today · tomorrow=Tomorrow · yesterday=Yesterday · whenAt={day} {time} ·
lateMinutes={count, plural, =1{1 min late} other{{count} min late}} · lateHours={count}h late · lateDays={count}d late ·
nagEvery={minutes, plural, =1{Every minute} other{Every {minutes} min}} · preAlarmMinutes={minutes} min before · preAlarmHours={hours} h before ·
repeatNone=None · repeatNever=Never · repeatDaily=Daily · repeatWeekly=Weekly · repeatCustom=Custom · repeatWeekdays=Weekdays ·
repeatEvery=Every {day} · repeatAdd=+ Repeat · tagAdd=+ Tag · tagNew=+ New · readAloud=Read aloud · silent=Silent · more=More ·
captureHint=Remind me to… · recordingHint=Release to stop. Transcript becomes the title. · recordingLeft=● {time} left ·
listening=Listening · {time} · savedAsVoiceNote=Saved as a voice note. Type a title if you like. · voiceNoteTitle=Voice note · {length} ·
yourNote={length} · your note · yourNotePlaying={length} · your note · playing · addPhoto=Add a photo ·
semTime=Time: {when} · semTimeGuess=Time, a guess: {when} · semReadAloudOn=Read aloud when it rings: on · semReadAloudOff=Read aloud when it rings: off ·
micOn=Microphone on. Hold the mic to record. · micDenied=Microphone not allowed. Turn it on in Settings. · holdToRecordShort=Hold the mic to record. ·
scheduleFailed=Saved, but the alarm could not be set. Memō retries when you next open it. · saveFailed=Couldn't save. Nothing changed, try again. ·
deleteFailed=Couldn't delete. Try again. · pastTime=That time has passed. Pick a later time. ·
homeNothing=Nothing scheduled · homeScheduled={count} scheduled · homeOverdue={count} overdue · overdue=Overdue ·
emptyBody=Bins, pills, that call.\nType below to add one. · loadFailedTitle=Couldn't load your reminders ·
loadFailedBody=They are still saved on this device. Alarms already scheduled keep firing. · toastDone={title} done · toastDeleted={title} deleted ·
settings=Settings · markDone=Mark done · snooze10Semantic=Snooze 10 minutes · swipeSnooze=10m · swipeDelete=Del · repeatsSemantic=Repeats ·
newReminder=New reminder · editReminder=Edit reminder · addNote=Add a note · when=When · time=Time · date=Date · preAlarm=Pre-alarm ·
preAlarmBody=An early heads-up before it rings. · nagUntilDone=Nag until done · nagBody=Rings again up to 6 times, until you mark it done. ·
repeat=Repeat · repeatSheetBody=Done moves it to the next time instead of archiving. · tag=Tag · tagSheetBody=One per reminder. Colour comes from the name. ·
newTagField=New tag… · newTag=New tag · newTagHint=Home, Work, Health… · customMinutes=Custom minutes · sound=Sound ·
playVoiceNote=Play voice note · stopVoiceNote=Stop voice note · deleteVoiceNote=Delete voice note · releaseToStop=Release to stop ·
holdToRecordNote=Hold to record a voice note · holdToRecord=Hold to record · readAloudWhenRings=Read aloud when it rings ·
reminderGone=This reminder no longer exists. · deleteConfirmTitle=Delete this reminder? · deleteConfirmBody=It will stop ringing. This cannot be undone. ·
next=Next · nag=Nag · created=Created · snooze=Snooze · reopen=Reopen · snooze10m=10m · snooze1h=1h · snoozeTomorrow=Tomorrow ·
alarmHeader=Reminder · slideToDone=Slide to mark done · archiveTitle=Done · archiveThisWeek={count} this week · archiveSearch=Search done ·
archiveEmpty=Nothing completed yet. · archiveNoMatch=Nothing matches. · settingsAlarms=Alarms · notifications=Notifications · exactAlarms=Exact alarms ·
fullScreenAlarms=Full-screen alarms · takeOverScreen=Take over the screen · fullScreenAlarm=Full-screen alarm · defaultNag=Default nag ·
defaultNagBody=New reminders ring again this often until done. Each one can change it. · readRemindersAloud=Read reminders aloud · voice=Voice ·
female=Female · male=Male · overlayHint=Allow "Take over the screen" so an alarm fills the screen while you use the phone, not just a banner. ·
notificationsOffHint=Without this a reminder can be saved but never heard. · settingsCapture=Capture · dictationLanguage=Dictation language ·
notOnThisPhone=Not on this phone · readPhotos=Read photos on device · noDictationHint=This phone has no on-device speech model, so a held voice note keeps its clip and rings, but is titled "Voice note". Nothing is sent to a server. ·
look=Look · appearance=Appearance · system=System · glassChrome=Glass chrome · followsIos=Follows iOS · solid=Solid ·
footer=Memō {version} · Nothing leaves this phone. · language=Language ·
welcomeTitle=One line,\none time. · welcomeBody=Type, say or snap the thing you keep forgetting. Memō rings at that time, even with the app closed and no signal. ·
welcomePrivacy=Nothing leaves your phone. No account, no sync, no analytics. · continueLabel=Continue · skip=Skip · primerTitle=Let Memō ring ·
primerBody=Alarms are notifications. The next screen is the phone asking you to allow them. Nothing else is asked for. ·
primerAndroid=On Android you will also be asked to allow exact alarms so a 7:00 reminder rings at 7:00, not 7:40. ·
allowNotifications=Allow notifications · notNow=Not now · spokenPrefix=Reminder. · voiceSample=Reminder. Take your pills. ·
alarmChannel=Alarms · alarmChannelBody=Reminders ringing now · remindersChannel=Reminders · remindersChannelBody=Scheduled reminder alarms ·
notifDone=Done · notifSnooze=Snooze 10m · missedAlarm=Missed: {title}

### B10 Settings language row — new `lib/core/ui/options_sheet.dart`
`Future<T?> showOptionsSheet<T>(BuildContext context, {required String title, required List<(T, String)> options, required T current})`
— `showMemoSheet` + `SheetHeading(title)` + `SectionCard` of `KeyValueRow(label: text, onTap: pop(value), child: value == current ? Icon(Icons.check_rounded) : SizedBox.shrink())`.
Settings: new section "Language" first: `KeyValueRow(label: l.language, child: PillValue(_langName(l, state.language)))`
opening the sheet with `[('system', l.system), ('en','English'), ('hi','हिन्दी'), ('bn','বাংলা')]` (endonyms in a `const` map,
not ARB). `SettingsState` gains `language`.

### B11 key-parity test — `test/l10n_keys_test.dart`
Load the three ARB files with `dart:io` + `jsonDecode`; for each non-`@` key in en assert present in hi and bn;
assert no extra keys; for each `@key.placeholders` in en assert every `{name}` appears in the hi and bn value.

### Verify B
Shared verify, plus `fvm flutter gen-l10n` (no diff after), `fvm flutter build apk --debug`,
`! grep -rnE "Text\(\s*'[A-Za-z]|hintText: '[A-Za-z]|label: '[A-Za-z]|tooltip: '[A-Za-z]|title: '[A-Za-z]|body: '[A-Za-z]" lib`,
`! grep -rn "'Voice note\|'Reminder\.\|'Done'\|'Snooze 10m'" lib --include=*.dart | grep -v lib/l10n`,
owner: `fvm flutter build ios --debug --no-codesign` after the Xcode steps.

---------------------------------------------------------------------------------------------------
## PHASE C — Language-aware parser, STT, TTS

Requires B. Step order: C1 parser, C2 STT, C3 TTS, C4 Settings.

### C1 parser — new `lib/features/reminders/domain/parser/parser_packs.dart` + edits to `reminder_parser.dart`
Data only (ponytail: tables, not a framework):
```dart
class ParserPack {
  const ParserPack({required this.today, required this.tomorrow, required this.dayAfter,
    required this.weekdays, required this.months, required this.parts, required this.clock,
    required this.daily, required this.every, required this.after, required this.units,
    this.glue = const []});
  final List<String> today, tomorrow, dayAfter;   // words
  final Map<String, int> weekdays;                // Mon = 1
  final Map<String, int> months;
  final Map<String, (int, int, bool)> parts;      // part of day → default (h, m), isPm
  final List<String> clock;                       // suffix after a number: "baje", "बजे", "ta", "টা", "টায়"
  final List<String> daily;                       // whole-phrase daily words
  final List<String> every;                       // prefix before a weekday: "har", "हर", "proti", "প্রতি"
  final List<String> after;                       // postposition after "N unit": "mein", "baad", "pore"
  final Map<String, String> units;                // word → 'm' | 'h' | 'd' | 'w' | 'mo' | 'y'
  final List<String> glue;                        // trailing/leading filler stripped from the title
}
const hindi = ParserPack(...); const bengali = ParserPack(...);
List<ParserPack> packsFor(String language) => switch (language) {
  'hi' => const [hindi, bengali], 'bn' => const [bengali, hindi], _ => const [hindi, bengali] };
```
Tables (each Latin word also as listed variants; Devanagari / Bengali script alongside):
- hi.today `aaj, aj, आज` · tomorrow `kal, कल` · dayAfter `parso, parson, परसों` ·
  weekdays `somvar, somwar, सोमवार=1; mangalvar, mangalwar, मंगलवार=2; budhvar, budhwar, बुधवार=3;
  guruvar, guruwar, brihaspativar, गुरुवार, बृहस्पतिवार=4; shukravar, shukrawar, शुक्रवार=5; shanivar, shaniwar, शनिवार=6;
  ravivar, raviwar, itvar, रविवार, इतवार=7` ·
  months `janvari, जनवरी=1; farvari, फ़रवरी, फरवरी=2; march, मार्च=3; april, अप्रैल=4; mai, मई=5; joon, जून=6;
  julai, जुलाई=7; agast, अगस्त=8; sitambar, सितंबर, सितम्बर=9; aktubar, अक्टूबर=10; navambar, नवंबर, नवम्बर=11; disambar, दिसंबर, दिसम्बर=12` ·
  parts `subah, सुबह=(8,0,am); dopahar, dopehar, दोपहर=(13,0,pm); shaam, sham, शाम=(18,0,pm); raat, रात=(21,0,pm)` ·
  (no Latin `rat` in either pack: "buy rat poison" must not become 21:00) ·
  clock `baje, बजे` · daily `har roz, har din, rozana, roz, रोज़, रोज, हर रोज़, हर दिन, रोज़ाना` · every `har, हर` ·
  after `mein, me, baad, bad, में, बाद` · units `minute, minat, min, मिनट=m; ghanta, ghante, घंटा, घंटे=h; din, दिन=d;
  hafta, hafte, हफ्ता, हफ्ते, हफ़्ते=w; mahina, mahine, महीना, महीने=mo; saal, साल=y` ·
  glue `ko, ki, ka, ke, yaad, dilana, dilao, mujhe, को, की, का, के, याद, दिलाना, मुझे`.
- bn.today `aaj, aj, আজ` · tomorrow `kal, kaal, কাল, আগামীকাল` · dayAfter `porshu, porsu, পরশু` ·
  weekdays `shombar, sombar, সোমবার=1; mongolbar, মঙ্গলবার=2; budhbar, বুধবার=3; brihoshpotibar, bishudbar, বৃহস্পতিবার=4;
  shukrobar, sukrobar, শুক্রবার=5; shonibar, sonibar, শনিবার=6; robibar, রবিবার=7` ·
  months `jonuari, জানুয়ারি=1; februari, ফেব্রুয়ারি=2; march, মার্চ=3; epril, april, এপ্রিল=4; me, মে=5; jun, জুন=6; julai, জুলাই=7;
  agost, আগস্ট=8; september, সেপ্টেম্বর=9; oktobor, অক্টোবর=10; november, নভেম্বর=11; disembor, ডিসেম্বর=12` ·
  parts `shokal, sokal, সকাল=(8,0,am); dupur, দুপুর=(13,0,pm); bikel, bikal, বিকেল=(16,0,pm);
  shondhya, sondhya, sondhe, সন্ধ্যা=(18,0,pm); raat, রাত=(21,0,pm)` ·
  clock `ta, tay, টা, টায়` · daily `protidin, roj, rojj, প্রতিদিন, রোজ` · every `proti, prati, প্রতি` ·
  after `pore, por, পরে, পর` · units `minit, minute, মিনিট=m; ghonta, ghanta, ঘণ্টা, ঘন্টা=h; din, দিন=d; shoptaho, saptaho, সপ্তাহ=w;
  mash, mas, মাস=mo; bochor, bachar, বছর=y` · glue `ke, ki, mone, koriye, dio, debe, আমাকে, মনে, করিয়ে, দিও, দেবে`.
Parser edits (`reminder_parser.dart`):
1. Signature: add `String language = 'en'`. First line: normalize digits — map `०-९` (U+0966..096F) and `০-৯`
   (U+09E6..09EF) to `0-9` in `input` (same length, spans stay valid).
2. Word boundaries for pack words: `const _l = r'(?<![\p{L}\p{M}\p{N}])'; const _r = r'(?![\p{L}\p{M}\p{N}])';`
   build every pack regex with `unicode: true`. Alternations sort words longest first (`har roz` before `har`).
   Helper `String _alt(Iterable<String> w) => (w.toList()..sort((a, b) => b.length - a.length)).map(RegExp.escape).join('|');`
3. After each English section, only if that section found nothing, loop `packsFor(language)`:
   - Repeat: `_l(daily)_r` → daily; `_l(every)\s+(weekdays)_r` (+ more weekdays joined by `,|aur|और|o|ও`) → weekly set.
   - Relative: `(\d+)\s*(units)\s*(after)?_r` → same arithmetic as English (months via `_addMonths` from A8).
   - Date: dayAfter → +2, tomorrow → +1, today → 0; `(\d{1,2})\s*(months)_r` → `_futureDate`; weekdays (repeat none) → A8 weekday rule.
   - Time: `(\d{1,2})(?:[:.](\d{2}))?\s*(clock)_r` → hour/min, ambiguous if 1..12; part-of-day word → if hour null use
     its default, else when ambiguous apply its am/pm (`raat 12` → 0:00). Part word without number and no hour → its default.
   Every match is blanked with `take()` exactly like English, so title and spans work unchanged.
4. `_title`: also strip pack `glue` words at start/end (same loop, pack words joined with `_alt`).
5. CaptureCubit: `parseReminder(text, now: …, knownTags: …, language: appLocale().languageCode)`.
Tests `test/reminder_parser_hi_bn_test.dart` (now = Fri 2026-11-20 14:30, language 'hi' unless stated):
"kal subah 8 baje dawai" → 11-21 08:00 title "Dawai"; "कल सुबह 8 बजे दवाई" → same, title "दवाई";
"parso shaam 6 baje gas" → 11-22 18:00; "raat 10 baje" → 22:00 today; "2 ghante baad call" → 16:30;
"har somvar gym" → weekly {1}; "har roz dawai" → daily; "शुक्रवार" → 11-27 09:00 guessed;
bn: "kal shokal 8 ta oshudh" → 11-21 08:00; "কাল সকাল ৮টায় ওষুধ" → 11-21 08:00 (native digit normalized);
"protidin raat 9 ta" → daily 21:00; "buy rat poison" (hi) → no time found, title "Buy rat poison"; "3 din pore" → 11-23 14:30;
en app: "call mom kal 8pm" → 11-21 20:00 title "Call mom". All existing `reminder_parser_test.dart` pass unchanged.

### C2 STT — `speech_to_text.dart`, `SttPlugin.kt`, `SttPlugin.swift`
Dart:
- `String sttTag(String lang)`: `'hi' → 'hi-IN'`, `'bn' → 'bn-IN'`, `'en'` → first `PlatformDispatcher.instance.locales`
  with languageCode `en` → `toLanguageTag()`, else `'en-IN'`. Put it in `speech_to_text.dart`.
- `Future<String> available(String tag)` → `'installed' | 'downloadable' | 'unavailable'` (catch → `'unavailable'`).
- `transcribeFile(String path, String tag)` passes `{'path', 'locale': tag}`.
- CaptureCubit `_onHold`: `stt?.transcribeFile(path, sttTag(appLocale().languageCode))`. Update `_Stt` fakes in tests.
Kotlin `SttPlugin.kt`:
- Delete `language()`. `transcribe(path, tag)` uses `tag` for `EXTRA_LANGUAGE`.
- `"available"`: if SDK < 33 or `!isOnDeviceRecognitionAvailable` → `"unavailable"`; else
  `createOnDeviceSpeechRecognizer(context).checkRecognitionSupport(intentWithLanguage(tag), mainExecutor, callback)`:
  `onSupportResult(s)`: tag (or its language) in `s.installedOnDeviceLanguages` → `"installed"`; in
  `supportedOnDeviceLanguages` or `pendingOnDeviceLanguages` → `"downloadable"`; else `"unavailable"`; `onError` → `"unavailable"`;
  destroy the recognizer; reply on main thread once. Match by `Locale.forLanguageTag(x).language == Locale.forLanguageTag(tag).language`.
Swift `SttPlugin.swift`:
- Remove the stored `recognizer`; `func recognizer(_ tag: String) -> SFSpeechRecognizer? { SFSpeechRecognizer(locale: Locale(identifier: tag)) }`.
- `"available"`: `r?.supportsOnDeviceRecognition == true && r?.isAvailable == true ? "installed" : "unavailable"`.
- `"transcribeFile"` reads `locale` arg (default `"en-US"`).

### C3 TTS — `spoken_reminder.dart`, `TtsPlugin.kt`, `TtsPlugin.swift`
Dart `SpokenReminder`:
- `static String speechLanguage(String text, String appLang)`: any char in U+0900..097F → `'hi'`; in U+0980..09FF → `'bn'`; else `appLang`.
- `textFor(Reminder r)` → `textFor(Reminder r, AppLocalizations l)` = `'${l.spokenPrefix} ${r.title}.' + note part` (same shape as today).
- `_render(r)`: `lang = speechLanguage(r.title, appLocale().languageCode)`; `l = lookupAppLocalizations(Locale(lang))`;
  args add `'language': lang`; name hash input `'$g|$lang|$text'`.
- `preview(gender)` → speaks `l10n().voiceSample` with `language: appLocale().languageCode`; returns `Future<bool>` from channel.
- `say(r)` uses the same language rule.
- New `Future<bool> hasVoice(String lang)` → channel `'hasVoice'` `{language}`; catch → false.
Kotlin `TtsPlugin.kt`:
- `pickVoice(engine, gender, language): Boolean` — filter `it.locale.language == language` (instead of `"en"`), same offline
  filters; rank by country == `Locale.getDefault().country`, then `"IN"`; if none → return false.
  English keeps today's pitched-default fallback; for `hi`/`bn` no voice → `false`.
- `render`: `if (!pickVoice(...)) return done(false)` → Dart gets `null` → chime only (existing behaviour of null).
- `preview`: speak only when `pickVoice` true; reply the bool.
- New `"hasVoice"` → `withTts { e -> result.success(e != null && pickVoice(e, "female", language)) }`.
Swift `TtsPlugin.swift`:
- `utterance(text, gender, language) -> AVSpeechUtterance?`: voices with `language.hasPrefix(lang)`; prefer gender, then any;
  for `en` keep today's fallback; for `hi`/`bn` with no voice return nil.
- `render`: nil utterance → `done(false)`; `preview`: nil → `result(false)` else speak and `result(true)`; add `"hasVoice"`.

### C4 Settings — `settings_cubit.dart`, `settings_page.dart`
- `SettingsState`: replace `bool? dictation` with `String? dictation` (`installed|downloadable|unavailable`), add `bool? voice`.
- `refresh()`: `lang = appLocale().languageCode`; `dictation = await _stt.available(sttTag(lang))`; `voice = await sl<SpokenReminder>().hasVoice(lang)`.
- "Dictation language" pill: endonym of `lang` when installed; ARB `dictationDownloads` ("Downloads on first use") when downloadable;
  `notOnThisPhone` when unavailable. Footnote `noDictationHint` only when unavailable.
- New footnote under Voice when `voice == false`: ARB `noVoiceHint` = "No {language} voice on this phone. Alarms ring with the chime only."
  (`{language}` = endonym). Add both keys to all three ARBs.

### Verify C
Shared verify; `fvm flutter test test/reminder_parser_test.dart test/reminder_parser_hi_bn_test.dart`;
`cd android && ./gradlew :app:compileDebugKotlin`; owner device checks C (see Owner steps).

---------------------------------------------------------------------------------------------------
## PHASE D — UI/UX polish

Requires B. Every animation reads `final still = MediaQuery.disableAnimationsOf(context);` and uses
`Duration.zero` (or skips the effect) when `still`. Curves: `MemoMotion.curve` in, `Curves.easeInCubic` out. No overshoot.

### D0 token — `tool/gen_tokens.dart` `_fixed` → `MemoMotion` add
`static const pulse = Duration(milliseconds: 1200);` and `static const exitCurve = Curves.easeInCubic;` Regenerate.
Also add helper in `lib/core/ui/motion.dart`: `Duration motion(BuildContext c, Duration d) => MediaQuery.disableAnimationsOf(c) ? Duration.zero : d;`

### D1 motion table (widget · effect · duration · curve · reduce-motion)
| # | Where | Effect | Token |
|---|---|---|---|
| 1 | `check_control.dart` → `StatefulWidget` with `AnimationController` | idle→done: accent disc scales 0→1, tick drawn by `PathMetric.extractPath(0, len*t)`; `HapticFeedback.lightImpact()` on tap | `base`, `curve`; still = jump to end |
| 2 | `home_page.dart` `_Row` → `StatefulWidget` | on complete of a one-off and on delete: `SizeTransition`+`FadeTransition` reverse, then call the cubit; a repeat's complete calls the cubit at once (it moves, not leaves) | `base`, `exitCurve`; still = call immediately |
| 3 | `home_page.dart` `_ReminderList` → `StatefulWidget` keeping `Set<String> _seen` | rows whose id is new since last build (not first build) enter with `SizeTransition`+`FadeTransition` | `slow`, `curve`; still = none |
| 4 | `swipeable_reminder_row.dart` | `HapticFeedback.selectionClick()` once when `_offset` crosses `completeThreshold` and once when actions open; check icon `AnimatedScale(scale: past ? 1.2 : 1)` | `fast` |
| 5 | `memo_sheet.dart` `showModalBottomSheet` | `sheetAnimationStyle: still ? AnimationStyle.noAnimation : AnimationStyle(duration: MemoMotion.slow, reverseDuration: MemoMotion.base, curve: MemoMotion.curve)` | `slow`/`base` |
| 6 | `capture_bar.dart` `MemoChrome` child `Column` | wrap in `AnimatedSize` (alignment bottomCenter); message row in `AnimatedSwitcher` (fade) | `base` / `fast` |
| 7 | `capture_bar.dart` trailing slot | `AnimatedSwitcher(transitionBuilder: ScaleTransition+Fade)`; mic child `key: const ValueKey('mic')`, Save `ValueKey('save')`. The mic key never changes between idle and recording (invariant) | `fast` |
| 8 | `capture_bar.dart` `_Chip`, `tag_chip.dart` | label `AnimatedSwitcher` (fade) + `AnimatedSize` on the chip; `HapticFeedback.selectionClick()` on tap | `fast` |
| 9 | new `lib/core/ui/mic_pulse.dart` `MicPulse({required bool active, required Widget child})`, used inside `capture_bar.dart _Mic` and `edit_sheet.dart _HoldToRecord` around the existing `AnimatedContainer` (the `Listener` stays the outermost widget, same slot) | StatefulWidget, `AnimationController(duration: MemoMotion.pulse)..repeat()` while `active`, stopped otherwise; `Stack` with an accentSoft circle behind the child, scale 1→1.35, opacity 0.6→0 | `pulse`; still = no pulse, today's static 4 px border |
| 10 | `home_page.dart` `_Header` summary, `day_section_header.dart` count, `archive_page.dart` "N this week" | `TweenAnimationBuilder<double>(tween: Tween(end: count.toDouble()))`, render `value.round()` through the same l10n plural | `base`; still = end value |
| 11 | `home_page.dart` toast slot | `AnimatedSwitcher` with `SlideTransition(Offset(0, .5)→0)` + fade, keyed by toast message | `base` |
| 12 | `repeat_segmented_control.dart` | selected tile as `AnimatedAlign` sliding thumb behind labels (one decorated box), `selectionClick` on change | `base` |
| 13 | Home notifications banner (D5) | `AnimatedSwitcher` + `SizeTransition` | `base` |
Haptics never depend on reduce motion. Save success (capture, edit): `HapticFeedback.lightImpact()`; delete: `mediumImpact()`.
Tests `test/motion_test.dart`: (a) with `MediaQuery(data: MediaQueryData(disableAnimations: true))`, tapping a check
completes in one `pump()`; (b) without, `pump(MemoMotion.base ~/ 2)` shows the row still present, `pumpAndSettle()` removes it.

### D2 Settings — `app_prefs.dart`, `app.dart`, `settings_page.dart`, `settings_cubit.dart`
- `AppPrefs`: `String get themeMode => _prefs.getString('theme_mode') ?? 'system'` + setter bumping `revision`;
  `chromeModeOverride` setter `setChromeModeOverride(String? v)` (null removes key) bumping `revision`.
- `app.dart`: `themeMode: switch (prefs.themeMode) { 'light' => ThemeMode.light, 'dark' => ThemeMode.dark, _ => ThemeMode.system }`.
- Appearance row → `showOptionsSheet` (from B10) with System/Light/Dark (ARB `themeLight`, `themeDark`; reuse `system`).
- Glass chrome row only when `Theme.of(context).platform == TargetPlatform.iOS`; tap toggles `chromeModeOverride` null ↔ 'solid';
  pill `followsIos` / `solid`.
- Delete the "Phase 2" header and its `Opacity` card. Update the class doc comment.

### D3 tap-to-record — `hold_recorder.dart`, both cubits, both mic widgets
- `HoldRecorder`: `static const tapThreshold = Duration(milliseconds: 300);` fields `DateTime? _downAt; bool _tapped = false; bool _latched = false;`
  getter `bool get latched => _latched;`
  - `press({bool latch = false})`: if `_recording && _latched` → `_latched = false; await _finish(); return;`
    else as today but set `_downAt = DateTime.now(); _tapped = latch;` and after `start` use
    `if (!_holding && !_tapped) { cancel; drop }`; after `_recording = true` set `_latched = _tapped`.
  - `release()`: `final quick = _downAt != null && DateTime.now().difference(_downAt!) < tapThreshold; _holding = false;`
    `if (quick && !_latched) { _tapped = true; if (_recording) _latched = true; return; }` `if (!_recording || _latched) return;` `await _finish();`
  - `_finish()` = today's stop logic (min length, keep/drop). The 30 s cap calls `_finish()` (not `release()`).
  - `toggle()` = `_recording ? press() : press(latch: true)`.
- Cubits: add `bool latched` to `CaptureState` / `EditState`, set from `_hold!.latched` in `onTick`; add `toggleRecording()` → `_hold?.toggle()`.
- Mic widgets: `Semantics(button: true, label: l.recordVoiceNote, hint: active ? l.tapToStop : l.tapToStart, onTap: cubit.toggleRecording, child: …)`.
  Recording hint text: `latched ? l.tapToStop : l.releaseToStop`.
- Copy: `holdToRecordShort` → "Tap or hold the mic to record.", `micOn` → "Microphone on. Tap or hold the mic to record.",
  `holdToRecordNote` → "Tap or hold to record a voice note". New keys `recordVoiceNote`, `tapToStart`, `tapToStop`, `recordingHintNoDictation`
  ("Release to stop. It saves as a voice note.").
- Tests in `test/hold_to_record_test.dart`: quick tap (down/up < 300 ms) keeps recording; second tap stops → `HoldKept`;
  existing hold tests unchanged and green.

### D4 touch targets
- `tag_chip.dart`: outer `GestureDetector(behavior: HitTestBehavior.opaque)` → `ConstrainedBox(minHeight: MemoSpace.hitMin)` →
  `Center` → existing 30 px `Container`. Callers: `home_page.dart _TagFilterBar` `SizedBox(height: 46 → 53)`, top padding 16 → 9;
  every `Wrap` of TagChips `runSpacing: MemoSpace.space2 → 0`.
- `capture_bar.dart _Chip`: same wrapper (visual 34); chips `SizedBox(height: 46 → 51)`, top padding `space3 → 7`.
- `repeat_segmented_control.dart` height 36 → 44; `weekday_selector.dart` tile height 36 → 44 (prd Q3).
- `swipeable_reminder_row.dart` `actionWidth` 52 → 72 (prd Q4).
- Test `test/touch_targets_test.dart`: `expect(tester.getSize(find.byType(TagChip)).height, greaterThanOrEqualTo(44))` and same for
  `_Chip` (find by text 'More'), segmented control, weekday tile.

### D5 copy, banner, misc
- Onboarding `welcome_page.dart`: body = `flags.imageCapture ? l.welcomeBody : l.welcomeBodyNoPhoto` (new key without "snap":
  "Type or say the thing you keep forgetting. …"). `permission_primer_page.dart`: `primerAndroid` paragraph only when
  `Theme.of(context).platform == TargetPlatform.android`.
- Home banner: `HomePage({this.notificationsGranted = _granted})` with top-level
  `Future<bool> _granted() async { try { return await Permission.notification.isGranted; } catch (_) { return true; } }`.
  State `bool _notifOff = false`, refreshed in `initState` and the existing `onResume`. Banner under `_Header`: accentSoft card,
  text `l.notificationsOffBanner` ("Notifications are off. Reminders will not ring."), trailing `TextButton(l.openSettings)` → `openAppSettings()`.
- Mic denied: `CaptureState.micDenied` / `EditState.micDenied` (from `HoldDropped.denied`); the error row shows a `TextButton(l.openSettings)` → `openAppSettings()`.
- Recording hint: `CaptureState.dictation` (bool, set once in the constructor from `stt?.available(...) == 'installed'`, default true);
  hint = `dictation ? l.recordingHint : l.recordingHintNoDictation`.
- Swipe labels: `swipeSnooze` → "Snooze", `swipeDelete` → "Delete" (all ARBs); update `home_page_test.dart` expectations `'10m'/'Del'`.
- Tags case-insensitive: make `_matchTag` public as `String? canonicalTag(String word, List<String> known)` in `reminder_parser.dart`.
  Use it in `capture_sheets.dart showTagSheet onSubmitted` (`final t = canonicalTag(name.trim(), tags) ?? name.trim(); if (!tags.contains(t)) tags.add(t);`),
  in `edit_sheet.dart _TagPicker._addTag` (`onChanged(canonicalTag(name, knownTags) ?? name)`), and `HomeReady.tagsInUse` / `filterTags`
  dedupe by `toLowerCase()` keeping the first spelling.
- Portrait: `ios/Runner/Info.plist` `UISupportedInterfaceOrientations` → only `UIInterfaceOrientationPortrait` (leave `~ipad` as is).
- New ARB keys for D (add to all three): `themeLight, themeDark, welcomeBodyNoPhoto, notificationsOffBanner, openSettings,
  recordVoiceNote, tapToStart, tapToStop, recordingHintNoDictation`.

### Verify D
Shared verify; `fvm flutter test test/motion_test.dart test/touch_targets_test.dart test/hold_to_record_test.dart`;
manual pass on both phones with Settings → Accessibility → Reduce Motion / Remove animations on and off.

---------------------------------------------------------------------------------------------------
## Owner-side manual steps (not for the implementer)

Before B (fonts, offline-safe; no network assumed by the plan)
1. Download from https://fonts.google.com/noto/specimen/Noto+Sans+Devanagari and
   https://fonts.google.com/noto/specimen/Noto+Sans+Bengali ("Download family"), unzip, take from `static/`:
   `NotoSansDevanagari-Regular.ttf`, `NotoSansDevanagari-Medium.ttf`, `NotoSansDevanagari-SemiBold.ttf`,
   `NotoSansBengali-Regular.ttf`, `NotoSansBengali-Medium.ttf`, `NotoSansBengali-SemiBold.ttf` → `assets/fonts/`.
   Copy the zip's `OFL.txt` to `assets/fonts/OFL-Noto.txt`. License: SIL Open Font License 1.1 (bundling allowed,
   license text must ship — done via LicenseRegistry). Instrument Sans and IBM Plex Mono are also OFL: add their OFL text the same way.
During B (Xcode, after Haiku created the `.strings` files)
2. Open `ios/Runner.xcworkspace` → Runner project → Info → Localizations → "+" Hindi, "+" Bengali (check no resources to localize).
3. Drag `ios/Runner/en.lproj/InfoPlist.strings` and `Localizable.strings` into the Runner group (target Runner, "Create groups").
   Select each → File inspector → Localize… → English, then tick Hindi and Bengali; Xcode links the existing `hi.lproj`/`bn.lproj`
   files (if it creates empty copies, overwrite them with Haiku's). Commit `project.pbxproj`.
4. Native-speaker review of `app_hi.arb`, `app_bn.arb`, `hi.lproj/*`, `bn.lproj/*` before release.
Device checks (Samsung SM-G781B, `adb -s RZCTC0T77MD`, Android 13; iPhone on iOS 26 and one on iOS 17/18)
5. A: two reminders same minute (both ring in turn, Done hits the right one); leave one 2 min → "Missed" notification opens Detail;
   swipe delete + Undo; reopen from Archive rings; change time zone in Settings → Date & time with a daily 07:00 → rings 07:00 local;
   `adb -s RZCTC0T77MD shell cmd alarm` / `dumpsys alarm | grep memo` to confirm re-armed times.
6. B: switch app language (in-app and Android per-app language: Settings → Apps → Memō → Language); 12h/24h device toggle;
   Bengali digits stay 0-9 in pickers; alarm buttons and channel name in the app language; iOS permission prompts in hi/bn.
7. C: Settings → Google → speech/on-device recognition: install Hindi, Bengali packs on the Samsung; dictate "kal subah 8 baje dawai";
   Google TTS: install Hindi/Bengali voices; check alarm speech and the chime-only fallback with voices removed. iPhone: Settings →
   Accessibility → Spoken Content → Voices → Hindi.
8. D: Reduce Motion (iOS) / Remove animations (Android) on and off; TalkBack/VoiceOver: double-tap mic starts and stops recording.
9. Integration test hang after a killed run: `adb forward --remove-all` + force-stop (see memory notes).
