/// Every user-visible English string in one place, so localisation later
/// swaps this file (ARB/intl) without touching call sites. Plain strings are
/// consts; anything with a number or name is a function that returns the
/// whole sentence, never a fragment to be glued together at the call site.
abstract final class S {
  // Common
  static const appName = 'Memō';
  static const commonDone = 'Done';
  static const commonCancel = 'Cancel';
  static const commonSave = 'Save';
  static const commonAdd = 'Add';
  static const commonSet = 'Set';
  static const commonEdit = 'Edit';
  static const commonDelete = 'Delete';
  static const commonUndo = 'Undo';
  static const commonOn = 'On';
  static const commonOff = 'Off';
  static const commonContinue = 'Continue';
  static const commonSkip = 'Skip';
  static const commonBack = '‹ Back';
  static const commonWorking = 'Working';
  static const commonMarkDone = 'Mark done';
  static const commonReopen = 'Reopen';
  static const commonMore = 'More';
  static const commonSnoozeTenMinutes = 'Snooze 10 minutes';
  static const commonDeleteShort = 'Del';
  static const commonTryAgain = 'Try again';

  // Reminder fields (labels shared by Edit, Detail and the sheets)
  static const fieldWhen = 'When';
  static const fieldTime = 'Time';
  static const fieldDate = 'Date';
  static const fieldRepeat = 'Repeat';
  static const fieldTag = 'Tag';
  static const fieldPreAlarm = 'Pre-alarm';
  static const reminderHint = 'Remind me to…';
  static const reminderMissing = 'This reminder no longer exists.';

  // Dates
  static const dateToday = 'Today';
  static const dateTomorrow = 'Tomorrow';
  static const dateYesterday = 'Yesterday';
  static const weekdaysShort = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  static const monthsShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  static String dateShort(int weekday, int day, int month) =>
      '${weekdaysShort[weekday - 1]} $day ${monthsShort[month - 1]}';
  static String dateLong(int day, int month, int year) =>
      '$day ${monthsShort[month - 1]} $year';
  static String dayAtTime(String day, String time) => '$day $time';
  static String lateDays(int d) => '${d}d late';
  static String lateHours(int h) => '${h}h late';
  static String lateMinutes(int m) => '$m min late';
  static String whenLate(String when, String late) => '$when · $late';

  // Home
  static const homeAll = 'All';
  static const homeOverdue = 'Overdue';
  static const homeSummaryNone = 'Nothing scheduled';
  static String homeSummary(int scheduled, int overdue) =>
      '$scheduled scheduled${overdue > 0 ? ' · $overdue overdue' : ''}';
  static const homeEmptyTitle = 'Nothing scheduled';
  static const homeEmptyBody =
      'Bins, pills, that call.\nType below to add one.';
  static const homeLoadFailedTitle = "Couldn't load your reminders";
  static const homeLoadFailedBody =
      'They are still saved on this device. '
      'Alarms already scheduled keep firing.';
  static String homeDeleted(String title) => '$title deleted';
  static String homeCompleted(String title) => '$title done';

  // Capture
  static const captureAddPhoto = 'Add a photo';
  static const captureHoldToRecord = 'Hold to record';
  static const captureReleaseToStop =
      'Release to stop. Transcript becomes the title.';
  static const captureSaving = 'Saving';
  static String captureListening(String elapsed) => 'Listening · $elapsed';
  static String captureElapsed(String elapsed) => '● $elapsed';
  static String captureLeft(String left) => '● $left left';
  static const captureRepeatNone = '+ Repeat';
  static const captureRepeatWeekdays = 'Weekdays';
  static String captureEveryDay(String day) => 'Every $day';
  static const captureTagNone = '+ Tag';
  static const captureReadAloud = 'Read aloud';
  static const captureSilent = 'Silent';
  static const captureReadAloudOn = 'Read aloud when it rings: on';
  static const captureReadAloudOff = 'Read aloud when it rings: off';
  static String captureTime(String when) => 'Time: $when';
  static String captureTimeGuess(String when) => 'Time, a guess: $when';
  static String clipNote(String length) => '$length · your note';
  static const repeatSheetBody =
      'Done moves it to the next time instead of archiving.';
  static const tagSheetBody = 'One per reminder. Colour comes from the name.';
  static const tagNewHint = 'New tag…';
  static const captureVoiceSaved =
      'Saved as a voice note. Type a title if you like.';
  static String voiceNoteTitle(String length) => 'Voice note · $length';
  static const holdMicOn = 'Microphone on. Hold the mic to record.';
  static const holdMicDenied =
      'Microphone not allowed. Turn it on in Settings.';
  static const holdHint = 'Hold the mic to record.';

  // Edit
  static const editNew = 'New reminder';
  static const editExisting = 'Edit reminder';
  static const editNoteHint = 'Add a note';
  static const editPreAlarmBody = 'An early heads-up before it rings.';
  static const editNagTitle = 'Nag until done';
  static const editNagBody =
      'Rings again up to 6 times, until you '
      'mark it done.';
  static const editSound = 'Sound';
  static const editHoldToRecordNote = 'Hold to record a voice note';
  static const editReleaseToStop = 'Release to stop';
  static const editReadAloudWhenRings = 'Read aloud when it rings';
  static const editNewTagChip = '+ New';
  static const editNewTagTitle = 'New tag';
  static const editTagHint = 'Home, Work, Health…';
  static String editRecordingMax(String max) => ' / $max';

  // Voice note
  static const voicePlay = 'Play voice note';
  static const voiceStop = 'Stop voice note';
  static const voiceDelete = 'Delete voice note';

  // Repeat
  static const repeatNone = 'None';
  static const repeatNever = 'Never';
  static const repeatDaily = 'Daily';
  static const repeatWeekly = 'Weekly';
  static const repeatCustom = 'Custom';
  static const repeatsSemantic = 'Repeats';

  // Detail
  static const detailDeleteTitle = 'Delete this reminder?';
  static const detailDeleteBody =
      'It will stop ringing. This cannot be undone.';
  static const detailNext = 'Next';
  static const detailNag = 'Nag';
  static const detailCreated = 'Created';
  static const detailSnooze = 'Snooze';

  // Snooze
  static const snoozeTenMinutes = '10m';
  static const snoozeOneHour = '1h';

  // Alarm
  static const alarmReminder = 'Reminder';
  static const alarmSlideToDone = 'Slide to mark done';
  static String alarmClip(String length, bool playing) =>
      '$length · your note${playing ? ' · playing' : ''}';

  // Archive
  static const archiveSearchHint = 'Search done';
  static const archiveEmpty = 'Nothing completed yet.';
  static const archiveNoMatch = 'Nothing matches.';
  static String archiveThisWeek(int n) => '$n this week';

  // Minutes sheet
  static const minutesCustomHint = 'Custom minutes';
  static String everyMinutes(int m) => 'Every $m min';
  static String hoursBefore(int h) => '$h h before';
  static String minutesBefore(int m) => '$m min before';

  // Settings
  static const settingsTitle = 'Settings';
  static const settingsAlarms = 'Alarms';
  static const settingsNotifications = 'Notifications';
  static const settingsExactAlarms = 'Exact alarms';
  static const settingsFullScreenAlarms = 'Full-screen alarms';
  static const settingsTakeOver = 'Take over the screen';
  static const settingsFullScreenAlarm = 'Full-screen alarm';
  static const settingsDefaultNag = 'Default nag';
  static const settingsDefaultNagBody =
      'New reminders ring again this often '
      'until done. Each one can change it.';
  static const settingsReadAloud = 'Read reminders aloud';
  static const settingsVoice = 'Voice';
  static const settingsFemale = 'Female';
  static const settingsMale = 'Male';
  static const settingsAllowed = 'Allowed';
  static const settingsNotAllowed = 'Not allowed';
  static const settingsTakeOverHint =
      'Allow "Take over the screen" so an alarm fills the '
      'screen while you use the phone, not just a banner.';
  static const settingsNotificationsHint =
      'Without this a reminder can be saved but never '
      'heard.';
  static const settingsCapture = 'Capture';
  static const settingsDictation = 'Dictation language';
  static const settingsDictationNone = 'Not on this phone';
  static const settingsEnglish = 'English';
  static const settingsReadPhotos = 'Read photos on device';
  static const settingsNoSpeechModel =
      'This phone has no on-device speech model, so a '
      'held voice note keeps its clip and rings, but is '
      'titled "Voice note". Nothing is sent to a server.';
  static const settingsLook = 'Look';
  static const settingsAppearance = 'Appearance';
  static const settingsSystem = 'System';
  static const settingsGlass = 'Glass chrome';
  static const settingsFollowsIos = 'Follows iOS';
  static const settingsSolid = 'Solid';
  static const settingsPhase2 = 'Phase 2';
  static const settingsCloudSync = 'Cloud sync';
  static const settingsShared = 'Shared reminders';
  static const settingsSoon = 'Soon';
  static String settingsFooter(String version) =>
      'Memō $version · Nothing leaves this phone.';

  // Onboarding
  static const welcomeTitle = 'One line,\none time.';
  static const welcomeBody1 =
      'Type, say or snap the thing you keep forgetting. Memō rings at that '
      'time, even with the app closed and no signal.';
  static const welcomeBody2 =
      'Nothing leaves your phone. No account, no sync, no analytics.';
  static const permTitle = 'Let Memō ring';
  static const permBody1 =
      'Alarms are notifications. The next screen is the phone asking you to '
      'allow them. Nothing else is asked for.';
  static const permBody2 =
      'On Android you will also be asked to allow exact alarms so a 7:00 '
      'reminder rings at 7:00, not 7:40.';
  static const permAllow = 'Allow notifications';
  static const permNotNow = 'Not now';

  // Notifications and spoken text
  static const notifChannelName = 'Reminders';
  static const notifChannelDescription = 'Scheduled reminder alarms';
  static const notifSnooze = 'Snooze 10m';
  static String missed(String title) => 'Missed: $title';
  static String spokenReminder(String title, String? note) => [
    'Reminder.',
    '$title.',
    if (note != null && note.isNotEmpty) '$note.',
  ].join(' ');
  static const spokenPreview = 'Reminder. Take your pills.';

  // Errors
  static const scheduleFailed =
      'Saved, but the alarm could not be set. Memō retries when you next open it.';
  static const saveFailed = "Couldn't save. Nothing changed, try again.";
  static const deleteFailed = "Couldn't delete. Try again.";
  static const timePassed = 'That time has passed. Pick a later time.';
}
