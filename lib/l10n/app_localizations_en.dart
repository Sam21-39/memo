// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonDone => 'Done';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonSet => 'Set';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonUndo => 'Undo';

  @override
  String get commonOn => 'On';

  @override
  String get commonOff => 'Off';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonSkip => 'Skip';

  @override
  String get commonBack => '‹ Back';

  @override
  String get commonWorking => 'Working';

  @override
  String get commonMarkDone => 'Mark done';

  @override
  String get commonReopen => 'Reopen';

  @override
  String get commonSnoozeTenMinutes => 'Snooze 10 minutes';

  @override
  String get commonTryAgain => 'Try again';

  @override
  String get fieldWhen => 'When';

  @override
  String get fieldTime => 'Time';

  @override
  String get fieldDate => 'Date';

  @override
  String get fieldRepeat => 'Repeat';

  @override
  String get fieldTag => 'Tag';

  @override
  String get fieldPreAlarm => 'Pre-alarm';

  @override
  String get reminderHint => 'Remind me to…';

  @override
  String get reminderMissing => 'This reminder no longer exists.';

  @override
  String get dateToday => 'Today';

  @override
  String get dateTomorrow => 'Tomorrow';

  @override
  String get dateYesterday => 'Yesterday';

  @override
  String lateDays(int count) {
    return '$count d late';
  }

  @override
  String lateHours(int count) {
    return '$count h late';
  }

  @override
  String lateMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min late',
      one: '1 min late',
    );
    return '$_temp0';
  }

  @override
  String whenLate(String when, String late) {
    return '$when · $late';
  }

  @override
  String whenDayTime(String day, String time) {
    return '$day · $time';
  }

  @override
  String get homeAll => 'All';

  @override
  String get homeOverdue => 'Overdue';

  @override
  String get homeSummaryNone => 'Nothing scheduled';

  @override
  String homeScheduled(int count) {
    return '$count scheduled';
  }

  @override
  String homeScheduledOverdue(int scheduled, int overdue) {
    return '$scheduled scheduled · $overdue overdue';
  }

  @override
  String get homeEmptyTitle => 'Nothing scheduled';

  @override
  String get homeEmptyBody =>
      'Bins, pills, that call.\nType below, or tap the mic and speak.';

  @override
  String get homeLoadFailedTitle => 'Couldn\'t load your reminders';

  @override
  String get homeLoadFailedBody =>
      'They are still saved on this device. Alarms already scheduled keep firing.';

  @override
  String homeDeleted(String title) {
    return '$title deleted';
  }

  @override
  String homeCompleted(String title) {
    return '$title done';
  }

  @override
  String get captureAddPhoto => 'Add a photo';

  @override
  String captureElapsed(String elapsed) {
    return '● $elapsed';
  }

  @override
  String get captureRepeatWeekdays => 'Weekdays';

  @override
  String repeatEveryDay(String day) {
    return 'Every $day';
  }

  @override
  String captureTime(String when) {
    return 'Time: $when';
  }

  @override
  String captureTimeGuess(String when) {
    return 'Time, a guess: $when';
  }

  @override
  String clipNote(String length) {
    return '$length · your note';
  }

  @override
  String clipNotePlaying(String length) {
    return '$length · your note · playing';
  }

  @override
  String get repeatSheetBody =>
      'Done moves it to the next time instead of archiving.';

  @override
  String get tagSheetBody => 'One per reminder. Colour comes from the name.';

  @override
  String get tagNewHint => 'New tag…';

  @override
  String voiceNoteTitle(String length) {
    return 'Voice note · $length';
  }

  @override
  String get holdMicOn => 'Microphone on. Tap the mic to record.';

  @override
  String get holdMicDenied => 'Microphone not allowed. Turn it on in Settings.';

  @override
  String get holdHint => 'Tap the mic, speak, then tap Stop.';

  @override
  String get editNew => 'New reminder';

  @override
  String get editExisting => 'Edit reminder';

  @override
  String get editNoteHint => 'Add a note';

  @override
  String get editPreAlarmBody => 'An early heads-up before it rings.';

  @override
  String get editNagTitle => 'If I don’t respond';

  @override
  String get editNagBody =>
      'Rings again up to 6 times, until you mark it done.';

  @override
  String get editSound => 'Sound';

  @override
  String get editHoldToRecordNote => 'Tap to record a voice note';

  @override
  String get editReleaseToStop => 'Release to stop';

  @override
  String get editReadAloudWhenRings => 'Read title aloud';

  @override
  String get editNewTagChip => '+ New';

  @override
  String get editNewTagTitle => 'New tag';

  @override
  String get editTagHint => 'Home, Work, Health…';

  @override
  String editRecordingMax(String max) {
    return ' / $max';
  }

  @override
  String get voicePlay => 'Play voice note';

  @override
  String get voiceStop => 'Stop voice note';

  @override
  String get voiceDelete => 'Delete voice note';

  @override
  String get repeatNone => 'None';

  @override
  String get repeatNever => 'Never';

  @override
  String get repeatDaily => 'Daily';

  @override
  String get repeatWeekly => 'Weekly';

  @override
  String get repeatCustom => 'Custom';

  @override
  String get repeatsSemantic => 'Repeats';

  @override
  String get detailDeleteTitle => 'Delete this reminder?';

  @override
  String get detailDeleteBody => 'It will stop ringing. This cannot be undone.';

  @override
  String get detailNext => 'Next';

  @override
  String get detailNag => 'Nag';

  @override
  String get detailCreated => 'Created';

  @override
  String get detailSnooze => 'Snooze';

  @override
  String get alarmReminder => 'Reminder';

  @override
  String get archiveSearchHint => 'Search';

  @override
  String get archiveNoMatch => 'Nothing matches.';

  @override
  String archiveThisWeek(int n) {
    return '$n this week';
  }

  @override
  String get minutesCustomHint => 'Custom minutes';

  @override
  String everyMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Every $minutes min',
      one: 'Every minute',
    );
    return '$_temp0';
  }

  @override
  String hoursBefore(int h) {
    return '$h h before';
  }

  @override
  String minutesBefore(int m) {
    return '$m min before';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguageVoice => 'Language and voice';

  @override
  String get settingsAppLanguage => 'App language';

  @override
  String get settingsAlarms => 'Alarms';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsExactAlarms => 'Exact alarms';

  @override
  String get settingsFullScreenAlarms => 'Full-screen alarms';

  @override
  String get settingsTakeOver => 'Take over the screen';

  @override
  String get settingsFullScreenAlarm => 'Full-screen alarm';

  @override
  String get settingsDefaultNag => 'Default nag';

  @override
  String get settingsDefaultNagBody =>
      'New reminders ring again this often until done. Each one can change it.';

  @override
  String get settingsReadAloud => 'Read reminders aloud';

  @override
  String get settingsVoice => 'Voice';

  @override
  String get settingsFemale => 'Female';

  @override
  String get settingsMale => 'Male';

  @override
  String get settingsAllowed => 'Allowed';

  @override
  String get settingsNotAllowed => 'Not allowed';

  @override
  String get settingsTakeOverHint =>
      'Allow \"Take over the screen\" so an alarm fills the screen while you use the phone, not just a banner.';

  @override
  String get settingsNotificationsHint =>
      'Without this a reminder can be saved but never heard.';

  @override
  String get settingsCapture => 'Capture';

  @override
  String get settingsDictation => 'Dictation language';

  @override
  String get settingsDictationNone => 'Not on this phone';

  @override
  String get settingsEnglish => 'English';

  @override
  String get settingsReadPhotos => 'Read photos on device';

  @override
  String get settingsNoSpeechModel =>
      'This phone has no on-device speech model, so a held voice note keeps its clip and rings, but is titled \"Voice note\". Nothing is sent to a server.';

  @override
  String get settingsLook => 'Look';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsSystem => 'System';

  @override
  String get settingsGlass => 'Glass chrome';

  @override
  String get settingsFollowsIos => 'Follows iOS';

  @override
  String get settingsSolid => 'Solid';

  @override
  String get settingsPhase2 => 'Phase 2';

  @override
  String get settingsCloudSync => 'Cloud sync';

  @override
  String get settingsShared => 'Shared reminders';

  @override
  String get settingsSoon => 'Soon';

  @override
  String settingsFooter(String version) {
    return 'Memō $version · Nothing leaves this phone.';
  }

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageHindi => 'Hindi';

  @override
  String get languageBengali => 'Bengali';

  @override
  String get welcomeTitle => 'One line,\none time.';

  @override
  String get welcomeBody1 =>
      'Type, say or snap the thing you keep forgetting. Memō rings at that time, even with the app closed and no signal.';

  @override
  String get welcomeBody2 =>
      'Nothing leaves your phone. No account, no sync, no analytics.';

  @override
  String get permTitle => 'Let Memō ring';

  @override
  String get permBody1 =>
      'Alarms are notifications. The next screen is the phone asking you to allow them. Nothing else is asked for.';

  @override
  String get permBody2 =>
      'On Android you will also be asked to allow exact alarms so a 7:00 reminder rings at 7:00, not 7:40.';

  @override
  String get permAllow => 'Allow notifications';

  @override
  String get permNotNow => 'Not now';

  @override
  String get notifChannelName => 'Reminders';

  @override
  String get notifChannelDescription => 'Scheduled reminder alarms';

  @override
  String get notifSnooze => 'Snooze 10m';

  @override
  String missed(String title) {
    return 'Missed: $title';
  }

  @override
  String spokenReminder(String title) {
    return 'Reminder. $title.';
  }

  @override
  String spokenReminderNote(String title, String note) {
    return 'Reminder. $title. $note.';
  }

  @override
  String get spokenPreview => 'Reminder. Take your pills.';

  @override
  String get scheduleFailed =>
      'Saved, but the alarm could not be set. Memō retries when you next open it.';

  @override
  String get saveFailed => 'Couldn\'t save. Nothing changed, try again.';

  @override
  String get deleteFailed => 'Couldn\'t delete. Try again.';

  @override
  String get timePassed => 'That time has passed. Pick a later time.';

  @override
  String get captureHintLine => 'Type, or tap the mic and speak';

  @override
  String repeatChip(String value) {
    return 'Repeat: $value';
  }

  @override
  String get micRecord => 'Record a reminder';

  @override
  String get micTapToStart => 'Double tap to start recording';

  @override
  String get micTapToStop => 'Tap to stop';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get recRecording => 'Recording';

  @override
  String recTimer(String elapsed, String max) {
    return '$elapsed / $max';
  }

  @override
  String get recHint =>
      'Say what and when. For example: “Pay the bill on Friday at 10”.';

  @override
  String get recStop => 'Stop';

  @override
  String get recStopLabel => 'Stop recording';

  @override
  String get recTipHold =>
      'Tip: press and hold the mic to record, release to stop.';

  @override
  String get recReleaseToStop => 'Release to stop, or tap Stop.';

  @override
  String get recUnderstanding => 'Understanding your recording';

  @override
  String recOnThisPhone(String language) {
    return 'On this phone, in $language. Nothing is sent anywhere.';
  }

  @override
  String get recFailedTitle => 'Couldn’t turn that into text';

  @override
  String recFailedUnavailable(String language) {
    return '$language speech isn’t available offline on this phone. Your recording is kept.';
  }

  @override
  String get recFailedEmpty =>
      'Nothing was recognised. Your recording is kept.';

  @override
  String get recKeptTitle => 'Recording kept';

  @override
  String get recKeptBody => 'Choose what to do with it.';

  @override
  String get recKept => 'Kept';

  @override
  String get recTypeInstead => 'Type it instead';

  @override
  String get recSaveAsNote => 'Save as voice note, pick a time';

  @override
  String confirmYouWrote(String text) {
    return 'You wrote: “$text”';
  }

  @override
  String confirmYouSaid(String text) {
    return 'You said: “$text”';
  }

  @override
  String get confirmSave => 'Save reminder';

  @override
  String get confirmEdit => 'Edit details';

  @override
  String get confirmTimeBadge => 'Confirm time';

  @override
  String get confirmTimeQuestion => 'Is this the right time?';

  @override
  String confirmReasonAmPm(String phrase) {
    return 'You said “$phrase”. Pick morning or evening.';
  }

  @override
  String get confirmReasonNoTime => 'No time was given. Pick one.';

  @override
  String confirmReasonDayWord(String phrase) {
    return '“$phrase” can mean two days. Pick one.';
  }

  @override
  String get confirmOtherTime => 'Other time…';

  @override
  String savedToday(String time) {
    return 'Reminder set for today at $time.';
  }

  @override
  String savedTomorrow(String time) {
    return 'Reminder set for tomorrow at $time.';
  }

  @override
  String savedOn(String date, String time) {
    return 'Reminder set for $date at $time.';
  }

  @override
  String get welcomeBody1NoPhoto =>
      'Type or say the thing you keep forgetting. Memō rings at that time, even with the app closed and no signal.';

  @override
  String get snoozeTitle => 'Snooze until…';

  @override
  String get snoozeBody => 'It will ring again, same sound.';

  @override
  String get snooze10 => 'Snooze 10 minutes';

  @override
  String get snooze1h => 'Snooze 1 hour';

  @override
  String get snoozeTomorrow => 'Tomorrow, same time';

  @override
  String get snoozePick => 'Pick a time';

  @override
  String get snoozePastTime => 'That time has passed. Pick a later one.';

  @override
  String get alarmReadingInEn => 'Reading aloud in English';

  @override
  String get alarmReadingInHi => 'Reading aloud in Hindi';

  @override
  String get alarmReadingInBn => 'Reading aloud in Bengali';

  @override
  String detailRepeatNext(String repeat, String when) {
    return '$repeat · next $when';
  }

  @override
  String get detailDoneToday => 'Mark done for today';

  @override
  String detailMovesTo(String when) {
    return 'Marking done moves it to $when.';
  }

  @override
  String get detailDelete => 'Delete reminder';

  @override
  String get repeatEveryDayLong => 'Every day';

  @override
  String get homeNext => 'Next';

  @override
  String homeNextWhen(String time, String until) {
    return '$time · $until';
  }

  @override
  String untilDays(int count) {
    return 'in $count d';
  }

  @override
  String untilHours(int count) {
    return 'in $count h';
  }

  @override
  String untilMinutes(int count) {
    return 'in $count min';
  }

  @override
  String markDoneNamed(String title) {
    return 'Mark $title done';
  }

  @override
  String get swipeSnooze => 'Snooze\n10 min';

  @override
  String get archiveSearchLabel => 'Search done reminders';

  @override
  String get archiveEmptyTitle => 'Nothing done yet';

  @override
  String get archiveEmptyBody =>
      'Reminders you mark done show up here. You can reopen them.';

  @override
  String get commonNone => 'None';

  @override
  String get editWhat => 'What';

  @override
  String get editPickDate => 'Pick date';

  @override
  String get editChangeTime => 'Change time';

  @override
  String get editMoreOptions => 'More options: note, tag, nag, sound';

  @override
  String get editBackBasic => '‹ Basic';

  @override
  String get editMoreTitle => 'More options';

  @override
  String get editNote => 'Note';

  @override
  String get editRemindEarlier => 'Remind me earlier';

  @override
  String nagSummary(int minutes) {
    return 'Every $minutes min, 6 times';
  }

  @override
  String get editOptionalBody =>
      'These are optional. Most reminders only need what and when.';
}
