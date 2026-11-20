import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
    Locale('hi'),
  ];

  /// Shared button or label
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// Shared button or label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Shared button or label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// Shared button or label
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// Shared button or label
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get commonSet;

  /// Shared button or label
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// Shared button or label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// Shared button or label
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get commonUndo;

  /// Shared button or label
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get commonOn;

  /// Shared button or label
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get commonOff;

  /// Shared button or label
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// Shared button or label
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get commonSkip;

  /// Shared button or label
  ///
  /// In en, this message translates to:
  /// **'‹ Back'**
  String get commonBack;

  /// Shared button or label
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get commonWorking;

  /// Shared button or label
  ///
  /// In en, this message translates to:
  /// **'Mark done'**
  String get commonMarkDone;

  /// Shared button or label
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get commonReopen;

  /// Shared button or label
  ///
  /// In en, this message translates to:
  /// **'Snooze 10 minutes'**
  String get commonSnoozeTenMinutes;

  /// Shared button or label
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonTryAgain;

  /// Reminder field label or hint
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get fieldWhen;

  /// Reminder field label or hint
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get fieldTime;

  /// Reminder field label or hint
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get fieldDate;

  /// Reminder field label or hint
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get fieldRepeat;

  /// Reminder field label or hint
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get fieldTag;

  /// Reminder field label or hint
  ///
  /// In en, this message translates to:
  /// **'Pre-alarm'**
  String get fieldPreAlarm;

  /// Reminder field label or hint
  ///
  /// In en, this message translates to:
  /// **'Remind me to…'**
  String get reminderHint;

  /// Reminder field label or hint
  ///
  /// In en, this message translates to:
  /// **'This reminder no longer exists.'**
  String get reminderMissing;

  /// Date and lateness wording
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dateToday;

  /// Date and lateness wording
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get dateTomorrow;

  /// Date and lateness wording
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dateYesterday;

  /// Overdue row trailing phrase
  ///
  /// In en, this message translates to:
  /// **'{count} d late'**
  String lateDays(int count);

  /// Overdue row trailing phrase
  ///
  /// In en, this message translates to:
  /// **'{count} h late'**
  String lateHours(int count);

  /// Overdue row trailing phrase
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 min late} other{{count} min late}}'**
  String lateMinutes(int count);

  /// Date and lateness wording
  ///
  /// In en, this message translates to:
  /// **'{when} · {late}'**
  String whenLate(String when, String late);

  /// Day and time joined, e.g. Today · 8:30 PM
  ///
  /// In en, this message translates to:
  /// **'{day} · {time}'**
  String whenDayTime(String day, String time);

  /// Home screen text
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get homeAll;

  /// Home screen text
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get homeOverdue;

  /// Home screen text
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled'**
  String get homeSummaryNone;

  /// Home summary line when nothing is overdue
  ///
  /// In en, this message translates to:
  /// **'{count} scheduled'**
  String homeScheduled(int count);

  /// Home summary line with overdue count
  ///
  /// In en, this message translates to:
  /// **'{scheduled} scheduled · {overdue} overdue'**
  String homeScheduledOverdue(int scheduled, int overdue);

  /// Home screen text
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled'**
  String get homeEmptyTitle;

  /// Home screen text
  ///
  /// In en, this message translates to:
  /// **'Bins, pills, that call.\nType below, or tap the mic and speak.'**
  String get homeEmptyBody;

  /// Home screen text
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your reminders'**
  String get homeLoadFailedTitle;

  /// Home screen text
  ///
  /// In en, this message translates to:
  /// **'They are still saved on this device. Alarms already scheduled keep firing.'**
  String get homeLoadFailedBody;

  /// Home screen text
  ///
  /// In en, this message translates to:
  /// **'{title} deleted'**
  String homeDeleted(String title);

  /// Home screen text
  ///
  /// In en, this message translates to:
  /// **'{title} done'**
  String homeCompleted(String title);

  /// Capture bar and capture sheets
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get captureAddPhoto;

  /// Capture bar and capture sheets
  ///
  /// In en, this message translates to:
  /// **'● {elapsed}'**
  String captureElapsed(String elapsed);

  /// Capture bar and capture sheets
  ///
  /// In en, this message translates to:
  /// **'Weekdays'**
  String get captureRepeatWeekdays;

  /// Repeat chip for one weekday, e.g. Every Mon
  ///
  /// In en, this message translates to:
  /// **'Every {day}'**
  String repeatEveryDay(String day);

  /// Capture bar and capture sheets
  ///
  /// In en, this message translates to:
  /// **'Time: {when}'**
  String captureTime(String when);

  /// Capture bar and capture sheets
  ///
  /// In en, this message translates to:
  /// **'Time, a guess: {when}'**
  String captureTimeGuess(String when);

  /// Capture bar and capture sheets
  ///
  /// In en, this message translates to:
  /// **'{length} · your note'**
  String clipNote(String length);

  /// Alarm voice note line while playing
  ///
  /// In en, this message translates to:
  /// **'{length} · your note · playing'**
  String clipNotePlaying(String length);

  /// Capture bar and capture sheets
  ///
  /// In en, this message translates to:
  /// **'Done moves it to the next time instead of archiving.'**
  String get repeatSheetBody;

  /// Capture bar and capture sheets
  ///
  /// In en, this message translates to:
  /// **'One per reminder. Colour comes from the name.'**
  String get tagSheetBody;

  /// Capture bar and capture sheets
  ///
  /// In en, this message translates to:
  /// **'New tag…'**
  String get tagNewHint;

  /// Capture bar and capture sheets
  ///
  /// In en, this message translates to:
  /// **'Voice note · {length}'**
  String voiceNoteTitle(String length);

  /// Capture bar and capture sheets
  ///
  /// In en, this message translates to:
  /// **'Microphone on. Tap the mic to record.'**
  String get holdMicOn;

  /// Capture bar and capture sheets
  ///
  /// In en, this message translates to:
  /// **'Microphone not allowed. Turn it on in Settings.'**
  String get holdMicDenied;

  /// Capture bar and capture sheets
  ///
  /// In en, this message translates to:
  /// **'Tap the mic, speak, then tap Stop.'**
  String get holdHint;

  /// Edit reminder sheet
  ///
  /// In en, this message translates to:
  /// **'New reminder'**
  String get editNew;

  /// Edit reminder sheet
  ///
  /// In en, this message translates to:
  /// **'Edit reminder'**
  String get editExisting;

  /// Edit reminder sheet
  ///
  /// In en, this message translates to:
  /// **'Add a note'**
  String get editNoteHint;

  /// Edit reminder sheet
  ///
  /// In en, this message translates to:
  /// **'An early heads-up before it rings.'**
  String get editPreAlarmBody;

  /// Edit reminder sheet
  ///
  /// In en, this message translates to:
  /// **'If I don’t respond'**
  String get editNagTitle;

  /// Edit reminder sheet
  ///
  /// In en, this message translates to:
  /// **'Rings again up to 6 times, until you mark it done.'**
  String get editNagBody;

  /// Edit reminder sheet
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get editSound;

  /// Edit reminder sheet
  ///
  /// In en, this message translates to:
  /// **'Tap to record a voice note'**
  String get editHoldToRecordNote;

  /// Edit reminder sheet
  ///
  /// In en, this message translates to:
  /// **'Release to stop'**
  String get editReleaseToStop;

  /// Edit reminder sheet
  ///
  /// In en, this message translates to:
  /// **'Read title aloud'**
  String get editReadAloudWhenRings;

  /// Edit reminder sheet
  ///
  /// In en, this message translates to:
  /// **'+ New'**
  String get editNewTagChip;

  /// Edit reminder sheet
  ///
  /// In en, this message translates to:
  /// **'New tag'**
  String get editNewTagTitle;

  /// Edit reminder sheet
  ///
  /// In en, this message translates to:
  /// **'Home, Work, Health…'**
  String get editTagHint;

  /// Edit reminder sheet
  ///
  /// In en, this message translates to:
  /// **' / {max}'**
  String editRecordingMax(String max);

  /// Voice note control label
  ///
  /// In en, this message translates to:
  /// **'Play voice note'**
  String get voicePlay;

  /// Voice note control label
  ///
  /// In en, this message translates to:
  /// **'Stop voice note'**
  String get voiceStop;

  /// Voice note control label
  ///
  /// In en, this message translates to:
  /// **'Delete voice note'**
  String get voiceDelete;

  /// Repeat option label
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get repeatNone;

  /// Repeat option label
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get repeatNever;

  /// Repeat option label
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get repeatDaily;

  /// Repeat option label
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get repeatWeekly;

  /// Repeat option label
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get repeatCustom;

  /// Repeat option label
  ///
  /// In en, this message translates to:
  /// **'Repeats'**
  String get repeatsSemantic;

  /// Reminder detail screen
  ///
  /// In en, this message translates to:
  /// **'Delete this reminder?'**
  String get detailDeleteTitle;

  /// Reminder detail screen
  ///
  /// In en, this message translates to:
  /// **'It will stop ringing. This cannot be undone.'**
  String get detailDeleteBody;

  /// Reminder detail screen
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get detailNext;

  /// Reminder detail screen
  ///
  /// In en, this message translates to:
  /// **'Nag'**
  String get detailNag;

  /// Reminder detail screen
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get detailCreated;

  /// Reminder detail screen
  ///
  /// In en, this message translates to:
  /// **'Snooze'**
  String get detailSnooze;

  /// Alarm screen
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get alarmReminder;

  /// Done archive screen
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get archiveSearchHint;

  /// Done archive screen
  ///
  /// In en, this message translates to:
  /// **'Nothing matches.'**
  String get archiveNoMatch;

  /// Done archive screen
  ///
  /// In en, this message translates to:
  /// **'{n} this week'**
  String archiveThisWeek(int n);

  /// Minutes picker sheet
  ///
  /// In en, this message translates to:
  /// **'Custom minutes'**
  String get minutesCustomHint;

  /// Nag interval label
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{Every minute} other{Every {minutes} min}}'**
  String everyMinutes(int minutes);

  /// Pre-alarm label
  ///
  /// In en, this message translates to:
  /// **'{h} h before'**
  String hoursBefore(int h);

  /// Pre-alarm label
  ///
  /// In en, this message translates to:
  /// **'{m} min before'**
  String minutesBefore(int m);

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings section heading
  ///
  /// In en, this message translates to:
  /// **'Language and voice'**
  String get settingsLanguageVoice;

  /// Settings row and language page section
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get settingsAppLanguage;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'New reminders ring again this often until done. Each one can change it.'**
  String get settingsDefaultNagBody;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get settingsVoice;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get settingsFemale;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get settingsMale;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsSystem;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Memō {version} · Nothing leaves this phone.'**
  String settingsFooter(String version);

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get settingsReminders;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'If I don’t respond'**
  String get settingsNoResponse;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Read title aloud'**
  String get settingsReadTitle;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Alarm reliability'**
  String get settingsReliability;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Alarm health'**
  String get settingsHealth;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'All set'**
  String get healthAllSet;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 thing to fix} other{{count} things to fix}}'**
  String healthToFix(int count);

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Test alarm'**
  String get settingsTest;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Ring in 10 s'**
  String get settingsTestValue;

  /// Toast after starting a test alarm
  ///
  /// In en, this message translates to:
  /// **'Lock the phone. It rings in about 10 seconds.'**
  String get testStarted;

  /// Shown when the test alarm could not be scheduled
  ///
  /// In en, this message translates to:
  /// **'Couldn’t set the test alarm. Try again.'**
  String get testFailed;

  /// Title of the test reminder
  ///
  /// In en, this message translates to:
  /// **'Test alarm'**
  String get testAlarmTitle;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsLight;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsDark;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// Settings screen
  ///
  /// In en, this message translates to:
  /// **'Nothing leaves this phone'**
  String get settingsPrivacyValue;

  /// Privacy sheet
  ///
  /// In en, this message translates to:
  /// **'Your reminders are stored on this phone. Speech is turned into text on this phone. There is no account and no analytics.'**
  String get privacyBody;

  /// Alarm health screen
  ///
  /// In en, this message translates to:
  /// **'Alarm health'**
  String get healthTitle;

  /// Alarm health screen
  ///
  /// In en, this message translates to:
  /// **'This phone is set up to ring Memō reminders. No phone can promise every alarm, so test once.'**
  String get healthBodyOk;

  /// Alarm health screen
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 setting may stop reminders from ringing on time.} other{{count} settings may stop reminders from ringing on time.}}'**
  String healthBodyFix(int count);

  /// Status pill
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get healthAllowed;

  /// Status pill
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get healthOk;

  /// Status pill
  ///
  /// In en, this message translates to:
  /// **'Fix'**
  String get healthFix;

  /// Status pill
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get healthOff;

  /// Alarm health screen
  ///
  /// In en, this message translates to:
  /// **'Fix: {title}'**
  String healthFixFirst(String title);

  /// Alarm health screen
  ///
  /// In en, this message translates to:
  /// **'Ring a test alarm in 10 seconds'**
  String get healthTestButton;

  /// Alarm health screen
  ///
  /// In en, this message translates to:
  /// **'Last test started: {when}.'**
  String healthLastTest(String when);

  /// Alarm health fix screen
  ///
  /// In en, this message translates to:
  /// **'Fix {n} of {total}'**
  String healthFixStep(int n, int total);

  /// Alarm health fix screen
  ///
  /// In en, this message translates to:
  /// **'Detected: {maker}.'**
  String healthDetected(String maker);

  /// Alarm health fix screen
  ///
  /// In en, this message translates to:
  /// **'Open battery settings'**
  String get healthOpenBattery;

  /// Alarm health fix screen
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get healthOpenSettings;

  /// Alarm health fix screen
  ///
  /// In en, this message translates to:
  /// **'I changed it, check again'**
  String get healthCheckAgain;

  /// Alarm health screen
  ///
  /// In en, this message translates to:
  /// **'Banners and sound'**
  String get healthNotificationsOk;

  /// Alarm health screen
  ///
  /// In en, this message translates to:
  /// **'Off: reminders cannot ring'**
  String get healthNotificationsBad;

  /// Alarm health fix screen
  ///
  /// In en, this message translates to:
  /// **'Without notifications a reminder can be saved but not heard.'**
  String get healthNotificationsBody;

  /// Alarm health fix screen
  ///
  /// In en, this message translates to:
  /// **'Tap “Open settings” below.'**
  String get healthNotificationsStep1;

  /// Alarm health fix screen
  ///
  /// In en, this message translates to:
  /// **'Choose Notifications.'**
  String get healthNotificationsStep2;

  /// Alarm health fix screen
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications, then come back to Memō.'**
  String get healthNotificationsStep3;

  /// Alarm health screen
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get healthExactOk;

  /// Alarm health screen
  ///
  /// In en, this message translates to:
  /// **'Off: alarms can ring late'**
  String get healthExactBad;

  /// Alarm health fix screen
  ///
  /// In en, this message translates to:
  /// **'Without exact alarms the phone may delay a reminder by many minutes.'**
  String get healthExactBody;

  /// Alarm health fix screen
  ///
  /// In en, this message translates to:
  /// **'Tap “Open settings” below.'**
  String get healthExactStep1;

  /// Alarm health fix screen
  ///
  /// In en, this message translates to:
  /// **'Find Memō in the list.'**
  String get healthExactStep2;

  /// Alarm health fix screen
  ///
  /// In en, this message translates to:
  /// **'Turn on Allow, then come back to Memō.'**
  String get healthExactStep3;

  /// Alarm health screen
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get healthFullScreenOk;

  /// Alarm health screen
  ///
  /// In en, this message translates to:
  /// **'Off: alarm shows as a small banner'**
  String get healthFullScreenBad;

  /// Alarm health fix screen
  ///
  /// In en, this message translates to:
  /// **'Without this, an alarm on a locked phone shows as a small banner.'**
  String get healthFullScreenBody;

  /// Alarm health fix screen
  ///
  /// In en, this message translates to:
  /// **'Tap “Open settings” below.'**
  String get healthFullScreenStep1;

  /// Alarm health fix screen
  ///
  /// In en, this message translates to:
  /// **'Turn on full-screen notifications for Memō.'**
  String get healthFullScreenStep2;

  /// Alarm health fix screen
  ///
  /// In en, this message translates to:
  /// **'Come back to Memō.'**
  String get healthFullScreenStep3;

  /// Alarm health screen
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get healthOverlayOk;

  /// Alarm health screen
  ///
  /// In en, this message translates to:
  /// **'Off: only a banner while you use the phone'**
  String get healthOverlayBad;

  /// Alarm health fix screen
  ///
  /// In en, this message translates to:
  /// **'Without this, an alarm while you use the phone is only a banner.'**
  String get healthOverlayBody;

  /// Alarm health fix screen
  ///
  /// In en, this message translates to:
  /// **'Tap “Open settings” below.'**
  String get healthOverlayStep1;

  /// Alarm health fix screen
  ///
  /// In en, this message translates to:
  /// **'Choose Memō.'**
  String get healthOverlayStep2;

  /// Alarm health fix screen
  ///
  /// In en, this message translates to:
  /// **'Turn on display over other apps, then come back to Memō.'**
  String get healthOverlayStep3;

  /// Alarm health screen
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get healthBattery;

  /// Alarm health screen
  ///
  /// In en, this message translates to:
  /// **'Unrestricted'**
  String get healthBatteryOk;

  /// Alarm health screen
  ///
  /// In en, this message translates to:
  /// **'Not unrestricted: phone may stop Memō'**
  String get healthBatteryBad;

  /// Alarm health fix screen
  ///
  /// In en, this message translates to:
  /// **'Unless a phone lets an app run unrestricted, it can stop it, and its alarms may not ring.'**
  String get healthBatteryBody;

  /// Alarm health fix screen
  ///
  /// In en, this message translates to:
  /// **'Tap “Open battery settings” below.'**
  String get healthBatteryStep1;

  /// Alarm health fix screen
  ///
  /// In en, this message translates to:
  /// **'Choose Battery.'**
  String get healthBatteryStep2;

  /// Alarm health fix screen
  ///
  /// In en, this message translates to:
  /// **'Choose Unrestricted.'**
  String get healthBatteryStep3;

  /// Alarm health fix screen
  ///
  /// In en, this message translates to:
  /// **'Come back to Memō.'**
  String get healthBatteryStep4;

  /// Alarm health screen
  ///
  /// In en, this message translates to:
  /// **'Allowed for Memō'**
  String get healthAlarmsOk;

  /// Alarm health screen
  ///
  /// In en, this message translates to:
  /// **'Off: Memō falls back to notifications'**
  String get healthAlarmsBad;

  /// Alarm health fix screen
  ///
  /// In en, this message translates to:
  /// **'Without alarm permission Memō can only send notifications, which silent mode can hide.'**
  String get healthAlarmsBody;

  /// Alarm health fix screen
  ///
  /// In en, this message translates to:
  /// **'Tap “Open settings” below.'**
  String get healthAlarmsStep1;

  /// Alarm health fix screen
  ///
  /// In en, this message translates to:
  /// **'Choose Alarms, or allow when the phone asks.'**
  String get healthAlarmsStep2;

  /// Alarm health fix screen
  ///
  /// In en, this message translates to:
  /// **'Turn it on, then come back to Memō.'**
  String get healthAlarmsStep3;

  /// Alarm health screen
  ///
  /// In en, this message translates to:
  /// **'Focus and silent mode'**
  String get healthFocus;

  /// Alarm health screen
  ///
  /// In en, this message translates to:
  /// **'Alarms ring through'**
  String get healthFocusOk;

  /// Alarm health screen, iOS before 26: informational
  ///
  /// In en, this message translates to:
  /// **'Focus can silence reminders'**
  String get healthFocusInfo;

  /// Alarm health screen
  ///
  /// In en, this message translates to:
  /// **'Focus can silence reminders'**
  String get healthFocusBad;

  /// Alarm health fix screen
  ///
  /// In en, this message translates to:
  /// **'Real alarms can ring through Focus and silent mode. Without alarm permission they cannot.'**
  String get healthFocusBody;

  /// Alarm health fix screen
  ///
  /// In en, this message translates to:
  /// **'Tap “Open settings” below.'**
  String get healthFocusStep1;

  /// Alarm health fix screen
  ///
  /// In en, this message translates to:
  /// **'Allow alarms for Memō.'**
  String get healthFocusStep2;

  /// Alarm health fix screen
  ///
  /// In en, this message translates to:
  /// **'Come back to Memō.'**
  String get healthFocusStep3;

  /// Alarm health screen
  ///
  /// In en, this message translates to:
  /// **'Background refresh'**
  String get healthBackground;

  /// Alarm health screen
  ///
  /// In en, this message translates to:
  /// **'Not needed'**
  String get healthBackgroundOk;

  /// Onboarding screens
  ///
  /// In en, this message translates to:
  /// **'Step 3 of 3'**
  String get onbStep3;

  /// Onboarding screens
  ///
  /// In en, this message translates to:
  /// **'Keep alarms alive'**
  String get onbBatteryTitle;

  /// Onboarding screens
  ///
  /// In en, this message translates to:
  /// **'Some phones stop background apps to save battery, which can make an alarm ring late or not at all. One setting lowers that risk.'**
  String get onbBatteryBody;

  /// Onboarding screens
  ///
  /// In en, this message translates to:
  /// **'Allow in background: Battery · Memō · Unrestricted'**
  String get onbBatteryStep1;

  /// Onboarding screens
  ///
  /// In en, this message translates to:
  /// **'Allow autostart: find Memō in your phone’s autostart list and turn it on.'**
  String get onbBatteryStep2;

  /// Onboarding screens
  ///
  /// In en, this message translates to:
  /// **'I did this'**
  String get onbDidThis;

  /// Onboarding screens
  ///
  /// In en, this message translates to:
  /// **'Skip, I will risk it'**
  String get onbSkipRisk;

  /// Alarm health screen
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get healthNotifications;

  /// Alarm health screen
  ///
  /// In en, this message translates to:
  /// **'Exact alarms'**
  String get healthExact;

  /// Alarm health screen
  ///
  /// In en, this message translates to:
  /// **'Full-screen alarms'**
  String get healthFullScreen;

  /// Alarm health screen
  ///
  /// In en, this message translates to:
  /// **'Take over the screen'**
  String get healthOverlay;

  /// Alarm health screen
  ///
  /// In en, this message translates to:
  /// **'Alarms'**
  String get healthAlarms;

  /// Language picker
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// Language picker
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// Language picker
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get languageHindi;

  /// Language picker
  ///
  /// In en, this message translates to:
  /// **'Bengali'**
  String get languageBengali;

  /// Onboarding screens
  ///
  /// In en, this message translates to:
  /// **'One line,\none time.'**
  String get welcomeTitle;

  /// Onboarding screens
  ///
  /// In en, this message translates to:
  /// **'Type, say or snap the thing you keep forgetting. Memō rings at that time, even with the app closed and no signal.'**
  String get welcomeBody1;

  /// Onboarding screens
  ///
  /// In en, this message translates to:
  /// **'Nothing leaves your phone. No account, no sync, no analytics.'**
  String get welcomeBody2;

  /// Onboarding screens
  ///
  /// In en, this message translates to:
  /// **'Let Memō ring'**
  String get permTitle;

  /// Onboarding screens
  ///
  /// In en, this message translates to:
  /// **'Alarms are notifications. The next screen is the phone asking you to allow them. Nothing else is asked for.'**
  String get permBody1;

  /// Onboarding screens
  ///
  /// In en, this message translates to:
  /// **'On Android you will also be asked to allow exact alarms so a 7:00 reminder rings at 7:00, not 7:40.'**
  String get permBody2;

  /// Onboarding screens
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get permAllow;

  /// Onboarding screens
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get permNotNow;

  /// Notification or spoken text
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get notifChannelName;

  /// Notification or spoken text
  ///
  /// In en, this message translates to:
  /// **'Scheduled reminder alarms'**
  String get notifChannelDescription;

  /// Notification or spoken text
  ///
  /// In en, this message translates to:
  /// **'Snooze 10m'**
  String get notifSnooze;

  /// Notification or spoken text
  ///
  /// In en, this message translates to:
  /// **'Alarms'**
  String get notifAlarmChannel;

  /// Notification or spoken text
  ///
  /// In en, this message translates to:
  /// **'Reminders ringing now'**
  String get notifAlarmChannelBody;

  /// Notification or spoken text
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get notifMissedChannel;

  /// Notification or spoken text
  ///
  /// In en, this message translates to:
  /// **'Missed: {title}'**
  String missed(String title);

  /// Text read aloud when a reminder rings
  ///
  /// In en, this message translates to:
  /// **'Reminder. {title}.'**
  String spokenReminder(String title);

  /// Text read aloud when a reminder with a note rings
  ///
  /// In en, this message translates to:
  /// **'Reminder. {title}. {note}.'**
  String spokenReminderNote(String title, String note);

  /// Notification or spoken text
  ///
  /// In en, this message translates to:
  /// **'Reminder. Take your pills.'**
  String get spokenPreview;

  /// Error message toast
  ///
  /// In en, this message translates to:
  /// **'Saved, but the alarm could not be set. Memō retries when you next open it.'**
  String get scheduleFailed;

  /// Error message toast
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Nothing changed, try again.'**
  String get saveFailed;

  /// Error message toast
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete. Try again.'**
  String get deleteFailed;

  /// Error message toast
  ///
  /// In en, this message translates to:
  /// **'That time has passed. Pick a later time.'**
  String get timePassed;

  /// V2 capture, confirmation and voice
  ///
  /// In en, this message translates to:
  /// **'Type, or tap the mic and speak'**
  String get captureHintLine;

  /// V2 capture, confirmation and voice
  ///
  /// In en, this message translates to:
  /// **'Repeat: {value}'**
  String repeatChip(String value);

  /// V2 capture, confirmation and voice
  ///
  /// In en, this message translates to:
  /// **'Record a reminder'**
  String get micRecord;

  /// V2 capture, confirmation and voice
  ///
  /// In en, this message translates to:
  /// **'Double tap to start recording'**
  String get micTapToStart;

  /// V2 capture, confirmation and voice
  ///
  /// In en, this message translates to:
  /// **'Tap to stop'**
  String get micTapToStop;

  /// V2 capture, confirmation and voice
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// V2 capture, confirmation and voice
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get recRecording;

  /// V2 capture, confirmation and voice
  ///
  /// In en, this message translates to:
  /// **'{elapsed} / {max}'**
  String recTimer(String elapsed, String max);

  /// V2 capture, confirmation and voice
  ///
  /// In en, this message translates to:
  /// **'Say what and when. For example: “Pay the bill on Friday at 10”.'**
  String get recHint;

  /// V2 capture, confirmation and voice
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get recStop;

  /// V2 capture, confirmation and voice
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get recStopLabel;

  /// V2 capture, confirmation and voice
  ///
  /// In en, this message translates to:
  /// **'Tip: press and hold the mic to record, release to stop.'**
  String get recTipHold;

  /// V2 capture, confirmation and voice
  ///
  /// In en, this message translates to:
  /// **'Release to stop, or tap Stop.'**
  String get recReleaseToStop;

  /// V2 capture, confirmation and voice
  ///
  /// In en, this message translates to:
  /// **'Understanding your recording'**
  String get recUnderstanding;

  /// V2 capture, confirmation and voice
  ///
  /// In en, this message translates to:
  /// **'On this phone, in {language}. Nothing is sent anywhere.'**
  String recOnThisPhone(String language);

  /// V2 capture, confirmation and voice
  ///
  /// In en, this message translates to:
  /// **'Couldn’t turn that into text'**
  String get recFailedTitle;

  /// V2 capture, confirmation and voice
  ///
  /// In en, this message translates to:
  /// **'{language} speech isn’t available offline on this phone. Your recording is kept.'**
  String recFailedUnavailable(String language);

  /// V2 capture, confirmation and voice
  ///
  /// In en, this message translates to:
  /// **'Nothing was recognised. Your recording is kept.'**
  String get recFailedEmpty;

  /// V2 capture, confirmation and voice
  ///
  /// In en, this message translates to:
  /// **'Recording kept'**
  String get recKeptTitle;

  /// V2 capture, confirmation and voice
  ///
  /// In en, this message translates to:
  /// **'Choose what to do with it.'**
  String get recKeptBody;

  /// V2 capture, confirmation and voice
  ///
  /// In en, this message translates to:
  /// **'Kept'**
  String get recKept;

  /// V2 capture, confirmation and voice
  ///
  /// In en, this message translates to:
  /// **'Type it instead'**
  String get recTypeInstead;

  /// V2 capture, confirmation and voice
  ///
  /// In en, this message translates to:
  /// **'Save as voice note, pick a time'**
  String get recSaveAsNote;

  /// V2 capture, confirmation and voice
  ///
  /// In en, this message translates to:
  /// **'You wrote: “{text}”'**
  String confirmYouWrote(String text);

  /// V2 capture, confirmation and voice
  ///
  /// In en, this message translates to:
  /// **'You said: “{text}”'**
  String confirmYouSaid(String text);

  /// V2 capture, confirmation and voice
  ///
  /// In en, this message translates to:
  /// **'Save reminder'**
  String get confirmSave;

  /// V2 capture, confirmation and voice
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get confirmEdit;

  /// V2 capture, confirmation and voice
  ///
  /// In en, this message translates to:
  /// **'Confirm time'**
  String get confirmTimeBadge;

  /// V2 capture, confirmation and voice
  ///
  /// In en, this message translates to:
  /// **'Is this the right time?'**
  String get confirmTimeQuestion;

  /// V2 capture, confirmation and voice
  ///
  /// In en, this message translates to:
  /// **'You said “{phrase}”. Pick morning or evening.'**
  String confirmReasonAmPm(String phrase);

  /// V2 capture, confirmation and voice
  ///
  /// In en, this message translates to:
  /// **'No time was given. Pick one.'**
  String get confirmReasonNoTime;

  /// V2 capture, confirmation and voice
  ///
  /// In en, this message translates to:
  /// **'“{phrase}” can mean two days. Pick one.'**
  String confirmReasonDayWord(String phrase);

  /// V2 capture, confirmation and voice
  ///
  /// In en, this message translates to:
  /// **'“{phrase}” is not clear. Pick the day and time.'**
  String confirmReasonDayAndTime(String phrase);

  /// V2 capture, confirmation and voice
  ///
  /// In en, this message translates to:
  /// **'Other time…'**
  String get confirmOtherTime;

  /// V2 capture, confirmation and voice
  ///
  /// In en, this message translates to:
  /// **'Reminder set for today at {time}.'**
  String savedToday(String time);

  /// V2 capture, confirmation and voice
  ///
  /// In en, this message translates to:
  /// **'Reminder set for tomorrow at {time}.'**
  String savedTomorrow(String time);

  /// V2 capture, confirmation and voice
  ///
  /// In en, this message translates to:
  /// **'Reminder set for {date} at {time}.'**
  String savedOn(String date, String time);

  /// V2 capture, confirmation and voice
  ///
  /// In en, this message translates to:
  /// **'Type or say the thing you keep forgetting. Memō rings at that time, even with the app closed and no signal.'**
  String get welcomeBody1NoPhoto;

  /// Snooze sheet heading
  ///
  /// In en, this message translates to:
  /// **'Snooze until…'**
  String get snoozeTitle;

  /// Snooze sheet body
  ///
  /// In en, this message translates to:
  /// **'It will ring again, same sound.'**
  String get snoozeBody;

  /// Snooze sheet option
  ///
  /// In en, this message translates to:
  /// **'Snooze 10 minutes'**
  String get snooze10;

  /// Snooze sheet option
  ///
  /// In en, this message translates to:
  /// **'Snooze 1 hour'**
  String get snooze1h;

  /// Snooze sheet option
  ///
  /// In en, this message translates to:
  /// **'Tomorrow, same time'**
  String get snoozeTomorrow;

  /// Snooze sheet link to a date and time picker
  ///
  /// In en, this message translates to:
  /// **'Pick a time'**
  String get snoozePick;

  /// Snooze sheet error when the picked time is not in the future
  ///
  /// In en, this message translates to:
  /// **'That time has passed. Pick a later one.'**
  String get snoozePastTime;

  /// Alarm screen, spoken-reminder status
  ///
  /// In en, this message translates to:
  /// **'Reading aloud in English'**
  String get alarmReadingInEn;

  /// Alarm screen, spoken-reminder status
  ///
  /// In en, this message translates to:
  /// **'Reading aloud in Hindi'**
  String get alarmReadingInHi;

  /// Alarm screen, spoken-reminder status
  ///
  /// In en, this message translates to:
  /// **'Reading aloud in Bengali'**
  String get alarmReadingInBn;

  /// Detail header for a repeating reminder
  ///
  /// In en, this message translates to:
  /// **'{repeat} · next {when}'**
  String detailRepeatNext(String repeat, String when);

  /// Detail button on a repeating reminder
  ///
  /// In en, this message translates to:
  /// **'Mark done for today'**
  String get detailDoneToday;

  /// Detail note under Mark done for today
  ///
  /// In en, this message translates to:
  /// **'Marking done moves it to {when}.'**
  String detailMovesTo(String when);

  /// Detail delete button
  ///
  /// In en, this message translates to:
  /// **'Delete reminder'**
  String get detailDelete;

  /// Daily repeat in the detail page and alarm screen
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get repeatEveryDayLong;

  /// Home screen text
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get homeNext;

  /// Home next-reminder line: time then how far off
  ///
  /// In en, this message translates to:
  /// **'{time} · {until}'**
  String homeNextWhen(String time, String until);

  /// How far off the next reminder is
  ///
  /// In en, this message translates to:
  /// **'in {count} d'**
  String untilDays(int count);

  /// How far off the next reminder is
  ///
  /// In en, this message translates to:
  /// **'in {count} h'**
  String untilHours(int count);

  /// How far off the next reminder is
  ///
  /// In en, this message translates to:
  /// **'in {count} min'**
  String untilMinutes(int count);

  /// Screen reader label for a reminder's check
  ///
  /// In en, this message translates to:
  /// **'Mark {title} done'**
  String markDoneNamed(String title);

  /// Swipe action label, two lines
  ///
  /// In en, this message translates to:
  /// **'Snooze\n10 min'**
  String get swipeSnooze;

  /// Done archive screen
  ///
  /// In en, this message translates to:
  /// **'Search done reminders'**
  String get archiveSearchLabel;

  /// Done archive screen
  ///
  /// In en, this message translates to:
  /// **'Nothing done yet'**
  String get archiveEmptyTitle;

  /// Done archive screen
  ///
  /// In en, this message translates to:
  /// **'Reminders you mark done show up here. You can reopen them.'**
  String get archiveEmptyBody;

  /// Shared button or label
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get commonNone;

  /// Edit reminder sheet
  ///
  /// In en, this message translates to:
  /// **'What'**
  String get editWhat;

  /// Edit reminder sheet
  ///
  /// In en, this message translates to:
  /// **'Pick date'**
  String get editPickDate;

  /// Edit reminder sheet
  ///
  /// In en, this message translates to:
  /// **'Change time'**
  String get editChangeTime;

  /// Edit reminder sheet
  ///
  /// In en, this message translates to:
  /// **'More options: note, tag, nag, sound'**
  String get editMoreOptions;

  /// Edit reminder sheet
  ///
  /// In en, this message translates to:
  /// **'‹ Basic'**
  String get editBackBasic;

  /// Edit reminder sheet
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get editMoreTitle;

  /// Edit reminder sheet
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get editNote;

  /// Edit reminder sheet
  ///
  /// In en, this message translates to:
  /// **'Remind me earlier'**
  String get editRemindEarlier;

  /// Edit reminder sheet: nag value
  ///
  /// In en, this message translates to:
  /// **'Every {minutes} min, 6 times'**
  String nagSummary(int minutes);

  /// Edit reminder sheet
  ///
  /// In en, this message translates to:
  /// **'These are optional. Most reminders only need what and when.'**
  String get editOptionalBody;

  /// V7 Settings row and language page section
  ///
  /// In en, this message translates to:
  /// **'Speaking language'**
  String get settingsSpeaking;

  /// V7 Settings row
  ///
  /// In en, this message translates to:
  /// **'Read-aloud voice'**
  String get settingsReadAloudVoice;

  /// V7 Language name in a sentence
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// V7 Speaking language availability
  ///
  /// In en, this message translates to:
  /// **'Offline on this phone'**
  String get sttInstalled;

  /// V7 Speaking language availability
  ///
  /// In en, this message translates to:
  /// **'Needs a download in phone settings'**
  String get sttDownloadable;

  /// V7 Speaking language availability
  ///
  /// In en, this message translates to:
  /// **'Not available on this phone'**
  String get sttUnavailable;

  /// V7 Speaking language footer
  ///
  /// In en, this message translates to:
  /// **'Memō listens in one language at a time. Automatic detection is not available yet.'**
  String get sttOneLanguage;

  /// V7 Read-aloud voice page title
  ///
  /// In en, this message translates to:
  /// **'Read-aloud voice'**
  String get voiceTitle;

  /// V7 Read-aloud voice page
  ///
  /// In en, this message translates to:
  /// **'When a reminder rings, Memō can read its title aloud. It reads your words as written; it does not translate them.'**
  String get voiceBody;

  /// V7 Read-aloud voice option
  ///
  /// In en, this message translates to:
  /// **'Follow reminder language'**
  String get voiceFollow;

  /// V7 Read-aloud voice option hint
  ///
  /// In en, this message translates to:
  /// **'Hindi reminders in Hindi, English in English'**
  String get voiceFollowHint;

  /// V7 Settings row value
  ///
  /// In en, this message translates to:
  /// **'Follow reminder'**
  String get voiceFollowShort;

  /// V7 Read-aloud voice option hint when absent
  ///
  /// In en, this message translates to:
  /// **'No offline {language} voice on this phone'**
  String voiceMissing(String language);

  /// V7 Read-aloud voice preview button
  ///
  /// In en, this message translates to:
  /// **'Preview: “Take medicine”'**
  String get voicePreview;

  /// V7 Read-aloud voice preview message
  ///
  /// In en, this message translates to:
  /// **'No offline voice for that language, so nothing was played.'**
  String get voicePreviewFailed;

  /// V7 Read-aloud voice status
  ///
  /// In en, this message translates to:
  /// **'Not installed'**
  String get voiceNotInstalled;

  /// V7 Read-aloud voice gender hint
  ///
  /// In en, this message translates to:
  /// **'English voices'**
  String get voiceGenderHint;

  /// V7 Read-aloud voice help link
  ///
  /// In en, this message translates to:
  /// **'How to install a voice'**
  String get voiceHowTo;

  /// V7 Read-aloud voice help, Android
  ///
  /// In en, this message translates to:
  /// **'Open your phone’s settings, then Text-to-speech output, then the settings of your engine and install the voice for the language. Choose an offline voice.'**
  String get voiceHowToAndroid;

  /// V7 Read-aloud voice help, iOS
  ///
  /// In en, this message translates to:
  /// **'Open Settings, then Accessibility, Spoken Content, Voices. Pick the language and download a voice.'**
  String get voiceHowToIos;

  /// V7 Read-aloud voice help button
  ///
  /// In en, this message translates to:
  /// **'Open text-to-speech settings'**
  String get voiceOpenSettings;

  /// V7 Notice under a read-aloud reminder with no voice
  ///
  /// In en, this message translates to:
  /// **'No {language} voice on this phone. It rings with the chime.'**
  String voiceNotice(String language);

  /// V7 Notice under a read-aloud reminder with no voice, with a voice note
  ///
  /// In en, this message translates to:
  /// **'No {language} voice on this phone. It rings with your voice note.'**
  String voiceNoticeNote(String language);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
