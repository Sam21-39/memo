// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get commonDone => 'হয়ে গেছে';

  @override
  String get commonCancel => 'বাতিল';

  @override
  String get commonSave => 'সংরক্ষণ';

  @override
  String get commonAdd => 'যোগ করুন';

  @override
  String get commonSet => 'সেট করুন';

  @override
  String get commonEdit => 'সম্পাদনা';

  @override
  String get commonDelete => 'মুছুন';

  @override
  String get commonUndo => 'ফিরিয়ে আনুন';

  @override
  String get commonOn => 'চালু';

  @override
  String get commonOff => 'বন্ধ';

  @override
  String get commonContinue => 'চালিয়ে যান';

  @override
  String get commonSkip => 'এড়িয়ে যান';

  @override
  String get commonBack => '‹ ফিরে যান';

  @override
  String get commonWorking => 'হচ্ছে';

  @override
  String get commonMarkDone => 'সম্পন্ন করুন';

  @override
  String get commonReopen => 'আবার খুলুন';

  @override
  String get commonSnoozeTenMinutes => '10 মিনিট স্নুজ';

  @override
  String get commonDeleteShort => 'মুছুন';

  @override
  String get commonTryAgain => 'আবার চেষ্টা করুন';

  @override
  String get fieldWhen => 'কখন';

  @override
  String get fieldTime => 'সময়';

  @override
  String get fieldDate => 'তারিখ';

  @override
  String get fieldRepeat => 'পুনরাবৃত্তি';

  @override
  String get fieldTag => 'ট্যাগ';

  @override
  String get fieldPreAlarm => 'আগাম সতর্কতা';

  @override
  String get reminderHint => 'মনে করিয়ে দিন…';

  @override
  String get reminderMissing => 'এই রিমাইন্ডারটি আর নেই।';

  @override
  String get dateToday => 'আজ';

  @override
  String get dateTomorrow => 'কাল';

  @override
  String get dateYesterday => 'গতকাল';

  @override
  String lateDays(int count) {
    return '$count দিন দেরি';
  }

  @override
  String lateHours(int count) {
    return '$count ঘণ্টা দেরি';
  }

  @override
  String lateMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count মিনিট দেরি',
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
  String get homeAll => 'সব';

  @override
  String get homeOverdue => 'দেরি হয়ে গেছে';

  @override
  String get homeSummaryNone => 'কিছু নির্ধারিত নেই';

  @override
  String homeScheduled(int count) {
    return '$countটি বাকি';
  }

  @override
  String homeScheduledOverdue(int scheduled, int overdue) {
    return '$scheduledটি বাকি · $overdueটি দেরিতে';
  }

  @override
  String get homeEmptyTitle => 'কিছু নির্ধারিত নেই';

  @override
  String get homeEmptyBody =>
      'ময়লা ফেলা, ওষুধ, সেই ফোন।\nনিচে লিখুন, অথবা মাইক ট্যাপ করে বলুন।';

  @override
  String get homeLoadFailedTitle => 'আপনার রিমাইন্ডার লোড করা যায়নি';

  @override
  String get homeLoadFailedBody =>
      'এগুলো এখনও এই ফোনে সংরক্ষিত আছে। যেসব অ্যালার্ম সেট করা আছে সেগুলো বাজতে থাকবে।';

  @override
  String homeDeleted(String title) {
    return '$title মুছে ফেলা হয়েছে';
  }

  @override
  String homeCompleted(String title) {
    return '$title সম্পন্ন';
  }

  @override
  String get captureAddPhoto => 'ছবি যোগ করুন';

  @override
  String captureElapsed(String elapsed) {
    return '● $elapsed';
  }

  @override
  String get captureRepeatWeekdays => 'কর্মদিবস';

  @override
  String repeatEveryDay(String day) {
    return 'প্রতি $day';
  }

  @override
  String captureTime(String when) {
    return 'সময়: $when';
  }

  @override
  String captureTimeGuess(String when) {
    return 'সময়, আন্দাজ: $when';
  }

  @override
  String clipNote(String length) {
    return '$length · আপনার নোট';
  }

  @override
  String clipNotePlaying(String length) {
    return '$length · আপনার নোট · চলছে';
  }

  @override
  String get repeatSheetBody =>
      '‘সম্পন্ন’ করলে এটি আর্কাইভে না গিয়ে পরের সময়ে চলে যায়।';

  @override
  String get tagSheetBody => 'প্রতি রিমাইন্ডারে একটি। রং নাম থেকে ঠিক হয়।';

  @override
  String get tagNewHint => 'নতুন ট্যাগ…';

  @override
  String voiceNoteTitle(String length) {
    return 'ভয়েস নোট · $length';
  }

  @override
  String get holdMicOn => 'মাইক চালু। রেকর্ড করতে মাইক ট্যাপ করুন।';

  @override
  String get holdMicDenied => 'মাইক্রোফোনের অনুমতি নেই। সেটিংসে চালু করুন।';

  @override
  String get holdHint => 'মাইক ট্যাপ করুন, বলুন, তারপর থামান চাপুন।';

  @override
  String get editNew => 'নতুন রিমাইন্ডার';

  @override
  String get editExisting => 'রিমাইন্ডার সম্পাদনা';

  @override
  String get editNoteHint => 'নোট যোগ করুন';

  @override
  String get editPreAlarmBody => 'বাজার আগে একটি আগাম সতর্কতা।';

  @override
  String get editNagTitle => 'সম্পন্ন না হওয়া পর্যন্ত বারবার';

  @override
  String get editNagBody =>
      'আপনি ‘সম্পন্ন’ না করা পর্যন্ত 6 বার পর্যন্ত আবার বাজে।';

  @override
  String get editSound => 'শব্দ';

  @override
  String get editHoldToRecordNote => 'ভয়েস নোট রেকর্ড করতে ট্যাপ করুন';

  @override
  String get editReleaseToStop => 'থামাতে ছেড়ে দিন';

  @override
  String get editReadAloudWhenRings => 'বাজলে পড়ে শোনান';

  @override
  String get editNewTagChip => '+ নতুন';

  @override
  String get editNewTagTitle => 'নতুন ট্যাগ';

  @override
  String get editTagHint => 'বাড়ি, কাজ, স্বাস্থ্য…';

  @override
  String editRecordingMax(String max) {
    return ' / $max';
  }

  @override
  String get voicePlay => 'ভয়েস নোট চালান';

  @override
  String get voiceStop => 'ভয়েস নোট থামান';

  @override
  String get voiceDelete => 'ভয়েস নোট মুছুন';

  @override
  String get repeatNone => 'নেই';

  @override
  String get repeatNever => 'কখনো না';

  @override
  String get repeatDaily => 'প্রতিদিন';

  @override
  String get repeatWeekly => 'প্রতি সপ্তাহে';

  @override
  String get repeatCustom => 'কাস্টম';

  @override
  String get repeatsSemantic => 'পুনরাবৃত্তি হয়';

  @override
  String get detailDeleteTitle => 'এই রিমাইন্ডারটি মুছবেন?';

  @override
  String get detailDeleteBody => 'এটি আর বাজবে না। এটি ফেরানো যাবে না।';

  @override
  String get detailNext => 'পরবর্তী';

  @override
  String get detailNag => 'বারবার';

  @override
  String get detailCreated => 'তৈরি হয়েছে';

  @override
  String get detailSnooze => 'পরে মনে করাও';

  @override
  String get snoozeTenMinutes => '10 মিনিট';

  @override
  String get alarmReminder => 'রিমাইন্ডার';

  @override
  String get archiveSearchHint => 'সম্পন্ন খুঁজুন';

  @override
  String get archiveEmpty => 'এখনও কিছু সম্পন্ন হয়নি।';

  @override
  String get archiveNoMatch => 'কিছু মেলেনি।';

  @override
  String archiveThisWeek(int n) {
    return 'এই সপ্তাহে $nটি';
  }

  @override
  String get minutesCustomHint => 'নিজের মিনিট';

  @override
  String everyMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'প্রতি $minutes মিনিটে',
      one: 'প্রতি মিনিটে',
    );
    return '$_temp0';
  }

  @override
  String hoursBefore(int h) {
    return '$h ঘণ্টা আগে';
  }

  @override
  String minutesBefore(int m) {
    return '$m মিনিট আগে';
  }

  @override
  String get settingsTitle => 'সেটিংস';

  @override
  String get settingsLanguageVoice => 'ভাষা ও কণ্ঠ';

  @override
  String get settingsAppLanguage => 'অ্যাপের ভাষা';

  @override
  String get settingsAlarms => 'অ্যালার্ম';

  @override
  String get settingsNotifications => 'নোটিফিকেশন';

  @override
  String get settingsExactAlarms => 'সঠিক সময়ের অ্যালার্ম';

  @override
  String get settingsFullScreenAlarms => 'ফুল-স্ক্রিন অ্যালার্ম';

  @override
  String get settingsTakeOver => 'স্ক্রিন দখল করুন';

  @override
  String get settingsFullScreenAlarm => 'ফুল-স্ক্রিন অ্যালার্ম';

  @override
  String get settingsDefaultNag => 'ডিফল্ট বারবার বাজা';

  @override
  String get settingsDefaultNagBody =>
      'নতুন রিমাইন্ডার সম্পন্ন না হওয়া পর্যন্ত এত ব্যবধানে আবার বাজে। প্রতিটিতে এটি বদলানো যায়।';

  @override
  String get settingsReadAloud => 'রিমাইন্ডার পড়ে শোনান';

  @override
  String get settingsVoice => 'কণ্ঠ';

  @override
  String get settingsFemale => 'নারী';

  @override
  String get settingsMale => 'পুরুষ';

  @override
  String get settingsAllowed => 'অনুমতি আছে';

  @override
  String get settingsNotAllowed => 'অনুমতি নেই';

  @override
  String get settingsTakeOverHint =>
      '\"স্ক্রিন দখল করুন\" অনুমতি দিন, যাতে ফোন ব্যবহার করার সময়ও অ্যালার্ম পুরো স্ক্রিনে দেখায়, শুধু ব্যানারে নয়।';

  @override
  String get settingsNotificationsHint =>
      'এটি ছাড়া রিমাইন্ডার সংরক্ষণ করা যায়, কিন্তু কখনো শোনা যাবে না।';

  @override
  String get settingsCapture => 'ক্যাপচার';

  @override
  String get settingsDictation => 'ডিক্টেশনের ভাষা';

  @override
  String get settingsDictationNone => 'এই ফোনে নেই';

  @override
  String get settingsEnglish => 'ইংরেজি';

  @override
  String get settingsReadPhotos => 'ছবি ডিভাইসেই পড়ুন';

  @override
  String get settingsNoSpeechModel =>
      'এই ফোনে অন-ডিভাইস স্পিচ মডেল নেই, তাই চেপে রেকর্ড করা ভয়েস নোট ক্লিপসহ বাজে, কিন্তু শিরোনাম থাকে \"ভয়েস নোট\"। কিছুই সার্ভারে পাঠানো হয় না।';

  @override
  String get settingsLook => 'চেহারা';

  @override
  String get settingsAppearance => 'দেখার ধরন';

  @override
  String get settingsSystem => 'সিস্টেম';

  @override
  String get settingsGlass => 'গ্লাস ক্রোম';

  @override
  String get settingsFollowsIos => 'iOS অনুযায়ী';

  @override
  String get settingsSolid => 'সলিড';

  @override
  String get settingsPhase2 => 'ধাপ 2';

  @override
  String get settingsCloudSync => 'ক্লাউড সিঙ্ক';

  @override
  String get settingsShared => 'শেয়ার করা রিমাইন্ডার';

  @override
  String get settingsSoon => 'শীঘ্রই';

  @override
  String settingsFooter(String version) {
    return 'Memō $version · কিছুই এই ফোনের বাইরে যায় না।';
  }

  @override
  String get languageTitle => 'ভাষা';

  @override
  String get languageSystem => 'সিস্টেম ডিফল্ট';

  @override
  String get languageHindi => 'হিন্দি';

  @override
  String get languageBengali => 'বাংলা';

  @override
  String get welcomeTitle => 'এক লাইন,\nএক সময়।';

  @override
  String get welcomeBody1 =>
      'যে কথা ভুলে যান, তা লিখুন, বলুন বা ছবি তুলুন। অ্যাপ বন্ধ থাকলেও, সিগন্যাল না থাকলেও Memō ঠিক সেই সময়ে বাজে।';

  @override
  String get welcomeBody2 =>
      'কিছুই আপনার ফোনের বাইরে যায় না। অ্যাকাউন্ট নেই, সিঙ্ক নেই, অ্যানালিটিক্স নেই।';

  @override
  String get permTitle => 'Memō-কে বাজতে দিন';

  @override
  String get permBody1 =>
      'অ্যালার্ম আসলে নোটিফিকেশন। পরের স্ক্রিনে ফোন আপনার কাছে এর অনুমতি চাইবে। আর কিছু চাওয়া হয় না।';

  @override
  String get permBody2 =>
      'Android-এ সঠিক সময়ের অ্যালার্মের অনুমতিও চাওয়া হবে, যাতে 7:00-এর রিমাইন্ডার 7:00-তেই বাজে, 7:40-এ নয়।';

  @override
  String get permAllow => 'নোটিফিকেশনের অনুমতি দিন';

  @override
  String get permNotNow => 'এখন নয়';

  @override
  String get notifChannelName => 'রিমাইন্ডার';

  @override
  String get notifChannelDescription => 'নির্ধারিত রিমাইন্ডার অ্যালার্ম';

  @override
  String get notifSnooze => 'স্নুজ 10 মি';

  @override
  String missed(String title) {
    return 'মিস হয়েছে: $title';
  }

  @override
  String spokenReminder(String title) {
    return 'রিমাইন্ডার। $title।';
  }

  @override
  String spokenReminderNote(String title, String note) {
    return 'রিমাইন্ডার। $title। $note।';
  }

  @override
  String get spokenPreview => 'রিমাইন্ডার। ওষুধ খান।';

  @override
  String get scheduleFailed =>
      'সংরক্ষিত হয়েছে, কিন্তু অ্যালার্ম সেট করা যায়নি। পরেরবার অ্যাপ খুললে Memō আবার চেষ্টা করবে।';

  @override
  String get saveFailed =>
      'সংরক্ষণ করা যায়নি। কিছু বদলায়নি, আবার চেষ্টা করুন।';

  @override
  String get deleteFailed => 'মোছা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get timePassed => 'সেই সময় পেরিয়ে গেছে। পরের কোনো সময় বেছে নিন।';

  @override
  String get captureHintLine => 'লিখুন, অথবা মাইক ট্যাপ করে বলুন';

  @override
  String repeatChip(String value) {
    return 'পুনরাবৃত্তি: $value';
  }

  @override
  String get micRecord => 'রিমাইন্ডার রেকর্ড করুন';

  @override
  String get micTapToStart => 'রেকর্ডিং শুরু করতে দুবার ট্যাপ করুন';

  @override
  String get micTapToStop => 'থামাতে ট্যাপ করুন';

  @override
  String get openSettings => 'সেটিংস খুলুন';

  @override
  String get recRecording => 'রেকর্ডিং';

  @override
  String recTimer(String elapsed, String max) {
    return '$elapsed / $max';
  }

  @override
  String get recHint => 'কী আর কখন, বলুন। যেমন: “শুক্রবার 10টায় বিল দেওয়া”।';

  @override
  String get recStop => 'থামান';

  @override
  String get recStopLabel => 'রেকর্ডিং থামান';

  @override
  String get recTipHold => 'টিপ: মাইক চেপে ধরে রাখুন, ছাড়লে থামবে।';

  @override
  String get recReleaseToStop => 'থামাতে ছাড়ুন, বা থামান চাপুন।';

  @override
  String get recUnderstanding => 'আপনার রেকর্ডিং বোঝা হচ্ছে';

  @override
  String recOnThisPhone(String language) {
    return 'এই ফোনেই, $language-এ। কিছুই কোথাও পাঠানো হয় না।';
  }

  @override
  String get recFailedTitle => 'লেখায় বদলানো গেল না';

  @override
  String recFailedUnavailable(String language) {
    return 'এই ফোনে $language বলা অফলাইনে পাওয়া যায় না। আপনার রেকর্ডিং রাখা হয়েছে।';
  }

  @override
  String get recFailedEmpty => 'কিছু বোঝা যায়নি। আপনার রেকর্ডিং রাখা হয়েছে।';

  @override
  String get recKeptTitle => 'রেকর্ডিং রাখা হয়েছে';

  @override
  String get recKeptBody => 'এটা নিয়ে কী করবেন, বেছে নিন।';

  @override
  String get recKept => 'রাখা হয়েছে';

  @override
  String get recTypeInstead => 'বরং লিখুন';

  @override
  String get recSaveAsNote => 'ভয়েস নোট হিসেবে সেভ করুন, সময় বেছে নিন';

  @override
  String confirmYouWrote(String text) {
    return 'আপনি লিখেছেন: “$text”';
  }

  @override
  String confirmYouSaid(String text) {
    return 'আপনি বলেছেন: “$text”';
  }

  @override
  String get confirmSave => 'রিমাইন্ডার সেভ করুন';

  @override
  String get confirmEdit => 'বদলান';

  @override
  String get confirmTimeBadge => 'সময় নিশ্চিত করুন';

  @override
  String get confirmTimeQuestion => 'এটা কি ঠিক সময়?';

  @override
  String confirmReasonAmPm(String phrase) {
    return 'আপনি “$phrase” বলেছেন। সকাল না সন্ধ্যা, বেছে নিন।';
  }

  @override
  String get confirmReasonNoTime => 'কোনো সময় বলা হয়নি। একটি বেছে নিন।';

  @override
  String confirmReasonDayWord(String phrase) {
    return '“$phrase” দুটি দিন হতে পারে। একটি বেছে নিন।';
  }

  @override
  String get confirmOtherTime => 'অন্য সময়…';

  @override
  String savedToday(String time) {
    return 'রিমাইন্ডার আজ $time-এর জন্য সেট হয়েছে।';
  }

  @override
  String savedTomorrow(String time) {
    return 'রিমাইন্ডার কাল $time-এর জন্য সেট হয়েছে।';
  }

  @override
  String savedOn(String date, String time) {
    return 'রিমাইন্ডার $date $time-এর জন্য সেট হয়েছে।';
  }

  @override
  String get welcomeBody1NoPhoto =>
      'যে কথা ভুলে যান, তা লিখুন বা বলুন। অ্যাপ বন্ধ থাকলেও, সিগন্যাল না থাকলেও Memō ঠিক সেই সময়ে বাজে।';

  @override
  String get snoozeTitle => 'কখন পর্যন্ত স্নুজ করবেন…';

  @override
  String get snoozeBody => 'এটি আবার বাজবে, একই শব্দে।';

  @override
  String get snooze10 => '10 মিনিটের জন্য স্নুজ করুন';

  @override
  String get snooze1h => '1 ঘণ্টার জন্য স্নুজ করুন';

  @override
  String get snoozeTomorrow => 'কাল, একই সময়ে';

  @override
  String get snoozePick => 'সময় বেছে নিন';

  @override
  String get snoozePastTime =>
      'সেই সময় পেরিয়ে গেছে। পরের কোনো সময় বেছে নিন।';

  @override
  String get alarmReadingInEn => 'ইংরেজিতে পড়ে শোনানো হচ্ছে';

  @override
  String get alarmReadingInHi => 'হিন্দিতে পড়ে শোনানো হচ্ছে';

  @override
  String get alarmReadingInBn => 'বাংলায় পড়ে শোনানো হচ্ছে';

  @override
  String detailRepeatNext(String repeat, String when) {
    return '$repeat · পরবর্তী $when';
  }

  @override
  String get detailDoneToday => 'আজকের জন্য সম্পন্ন করুন';

  @override
  String detailMovesTo(String when) {
    return 'সম্পন্ন করলে এটি $when-এ সরে যাবে।';
  }

  @override
  String get detailDelete => 'রিমাইন্ডার মুছুন';

  @override
  String get repeatEveryDayLong => 'প্রতিদিন';
}
