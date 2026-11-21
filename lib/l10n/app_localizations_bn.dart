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
  String get editNagTitle => 'আমি সাড়া না দিলে';

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
  String get editReadAloudWhenRings => 'শিরোনাম পড়ে শোনান';

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
  String get alarmReminder => 'রিমাইন্ডার';

  @override
  String get archiveSearchHint => 'খুঁজুন';

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
  String get settingsDefaultNagBody =>
      'নতুন রিমাইন্ডার সম্পন্ন না হওয়া পর্যন্ত এত ব্যবধানে আবার বাজে। প্রতিটিতে এটি বদলানো যায়।';

  @override
  String get settingsVoice => 'কণ্ঠ';

  @override
  String get settingsFemale => 'নারী';

  @override
  String get settingsMale => 'পুরুষ';

  @override
  String get settingsAppearance => 'দেখার ধরন';

  @override
  String get settingsSystem => 'সিস্টেম';

  @override
  String settingsFooter(String version) {
    return 'Memō $version · কিছুই এই ফোনের বাইরে যায় না।';
  }

  @override
  String get settingsReminders => 'রিমাইন্ডার';

  @override
  String get settingsNoResponse => 'সাড়া না দিলে';

  @override
  String get settingsReadTitle => 'শিরোনাম পড়ে শোনান';

  @override
  String get settingsReliability => 'অ্যালার্মের নির্ভরযোগ্যতা';

  @override
  String get settingsHealth => 'অ্যালার্মের অবস্থা';

  @override
  String get healthAllSet => 'সব ঠিক আছে';

  @override
  String healthToFix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ঠিক করার মতো $countটি বিষয়',
    );
    return '$_temp0';
  }

  @override
  String get settingsTest => 'টেস্ট অ্যালার্ম';

  @override
  String get settingsTestValue => '10 সেকেন্ডে বাজবে';

  @override
  String get testStarted => 'ফোন লক করুন। প্রায় 10 সেকেন্ডে বাজবে।';

  @override
  String get testFailed => 'টেস্ট অ্যালার্ম সেট করা গেল না। আবার চেষ্টা করুন।';

  @override
  String get testAlarmTitle => 'টেস্ট অ্যালার্ম';

  @override
  String get settingsTheme => 'থিম';

  @override
  String get settingsLight => 'হালকা';

  @override
  String get settingsDark => 'গাঢ়';

  @override
  String get settingsAbout => 'সম্পর্কে';

  @override
  String get settingsPrivacy => 'গোপনীয়তা';

  @override
  String get settingsPrivacyValue => 'কিছুই এই ফোনের বাইরে যায় না';

  @override
  String get privacyBody =>
      'আপনার রিমাইন্ডার এই ফোনেই থাকে। কথা থেকে লেখা এই ফোনেই তৈরি হয়। কোনো অ্যাকাউন্ট নেই, কোনো অ্যানালিটিক্সও নেই।';

  @override
  String get healthTitle => 'অ্যালার্মের অবস্থা';

  @override
  String get healthBodyOk =>
      'এই ফোন Memō-র রিমাইন্ডার বাজানোর জন্য তৈরি। কোনো ফোনই প্রতিটি অ্যালার্মের নিশ্চয়তা দিতে পারে না, তাই একবার টেস্ট করে নিন।';

  @override
  String healthBodyFix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি সেটিং রিমাইন্ডারকে সময়মতো বাজতে বাধা দিতে পারে।',
    );
    return '$_temp0';
  }

  @override
  String get healthAllowed => 'অনুমতি আছে';

  @override
  String get healthOk => 'ঠিক আছে';

  @override
  String get healthFix => 'ঠিক করুন';

  @override
  String get healthOff => 'বন্ধ';

  @override
  String healthFixFirst(String title) {
    return 'ঠিক করুন: $title';
  }

  @override
  String get healthTestButton => '10 সেকেন্ডে টেস্ট অ্যালার্ম বাজান';

  @override
  String healthLastTest(String when) {
    return 'শেষ টেস্ট শুরু হয়েছে: $when।';
  }

  @override
  String healthFixStep(int n, int total) {
    return 'সমাধান $n/$total';
  }

  @override
  String healthDetected(String maker) {
    return 'শনাক্ত হয়েছে: $maker।';
  }

  @override
  String get healthOpenBattery => 'ব্যাটারি সেটিংস খুলুন';

  @override
  String get healthOpenSettings => 'সেটিংস খুলুন';

  @override
  String get healthCheckAgain => 'আমি বদলেছি, আবার দেখুন';

  @override
  String get healthNotificationsOk => 'ব্যানার ও শব্দ';

  @override
  String get healthNotificationsBad => 'বন্ধ: রিমাইন্ডার বাজতে পারবে না';

  @override
  String get healthNotificationsBody =>
      'নোটিফিকেশন ছাড়া রিমাইন্ডার সেভ হয়, কিন্তু শোনা যায় না।';

  @override
  String get healthNotificationsStep1 => 'নিচে “সেটিংস খুলুন” চাপুন।';

  @override
  String get healthNotificationsStep2 => 'নোটিফিকেশন বেছে নিন।';

  @override
  String get healthNotificationsStep3 =>
      'নোটিফিকেশনের অনুমতি চালু করুন, তারপর Memō-তে ফিরে আসুন।';

  @override
  String get healthExactOk => 'অনুমতি আছে';

  @override
  String get healthExactBad => 'বন্ধ: অ্যালার্ম দেরিতে বাজতে পারে';

  @override
  String get healthExactBody =>
      'সঠিক সময়ের অ্যালার্ম ছাড়া ফোন রিমাইন্ডার কয়েক মিনিট দেরিতে বাজাতে পারে।';

  @override
  String get healthExactStep1 => 'নিচে “সেটিংস খুলুন” চাপুন।';

  @override
  String get healthExactStep2 => 'তালিকায় Memō খুঁজুন।';

  @override
  String get healthExactStep3 => 'অনুমতি চালু করুন, তারপর Memō-তে ফিরে আসুন।';

  @override
  String get healthFullScreenOk => 'অনুমতি আছে';

  @override
  String get healthFullScreenBad => 'বন্ধ: অ্যালার্ম ছোট ব্যানার হয়ে আসে';

  @override
  String get healthFullScreenBody =>
      'এটি ছাড়া লক করা ফোনে অ্যালার্ম শুধু ছোট ব্যানার হয়ে দেখা দেয়।';

  @override
  String get healthFullScreenStep1 => 'নিচে “সেটিংস খুলুন” চাপুন।';

  @override
  String get healthFullScreenStep2 =>
      'Memō-র জন্য ফুল-স্ক্রিন নোটিফিকেশন চালু করুন।';

  @override
  String get healthFullScreenStep3 => 'Memō-তে ফিরে আসুন।';

  @override
  String get healthOverlayOk => 'অনুমতি আছে';

  @override
  String get healthOverlayBad => 'বন্ধ: ফোন ব্যবহারের সময় শুধু ব্যানার';

  @override
  String get healthOverlayBody =>
      'এটি ছাড়া ফোন ব্যবহারের সময় অ্যালার্ম শুধু ব্যানার হয়ে আসে।';

  @override
  String get healthOverlayStep1 => 'নিচে “সেটিংস খুলুন” চাপুন।';

  @override
  String get healthOverlayStep2 => 'Memō বেছে নিন।';

  @override
  String get healthOverlayStep3 =>
      'অন্য অ্যাপের উপরে দেখানোর অনুমতি চালু করুন, তারপর Memō-তে ফিরে আসুন।';

  @override
  String get healthBattery => 'ব্যাটারি';

  @override
  String get healthBatteryOk => 'বিধিনিষেধহীন';

  @override
  String get healthBatteryBad => 'বিধিনিষেধহীন নয়: ফোন Memō বন্ধ করতে পারে';

  @override
  String get healthBatteryBody =>
      'অ্যাপ বিধিনিষেধহীন না থাকলে ফোন তা বন্ধ করে দিতে পারে, তখন তার অ্যালার্ম নাও বাজতে পারে।';

  @override
  String get healthBatteryStep1 => 'নিচে “ব্যাটারি সেটিংস খুলুন” চাপুন।';

  @override
  String get healthBatteryStep2 => 'ব্যাটারি বেছে নিন।';

  @override
  String get healthBatteryStep3 => 'বিধিনিষেধহীন (Unrestricted) বেছে নিন।';

  @override
  String get healthBatteryStep4 => 'Memō-তে ফিরে আসুন।';

  @override
  String get healthAlarmsOk => 'Memō-র জন্য অনুমতি আছে';

  @override
  String get healthAlarmsBad => 'বন্ধ: Memō নোটিফিকেশনে ফিরে যায়';

  @override
  String get healthAlarmsBody =>
      'অ্যালার্মের অনুমতি ছাড়া Memō শুধু নোটিফিকেশন পাঠাতে পারে, যা সাইলেন্ট মোডে চাপা পড়তে পারে।';

  @override
  String get healthAlarmsStep1 => 'নিচে “সেটিংস খুলুন” চাপুন।';

  @override
  String get healthAlarmsStep2 =>
      'অ্যালার্ম বেছে নিন, অথবা ফোন জিজ্ঞেস করলে অনুমতি দিন।';

  @override
  String get healthAlarmsStep3 => 'এটি চালু করুন, তারপর Memō-তে ফিরে আসুন।';

  @override
  String get healthFocus => 'ফোকাস ও সাইলেন্ট মোড';

  @override
  String get healthFocusOk => 'অ্যালার্ম বাজে';

  @override
  String get healthFocusInfo => 'ফোকাস রিমাইন্ডার চুপ করিয়ে দিতে পারে';

  @override
  String get healthFocusBad => 'ফোকাস রিমাইন্ডার চুপ করিয়ে দিতে পারে';

  @override
  String get healthFocusBody =>
      'আসল অ্যালার্ম ফোকাস ও সাইলেন্ট মোডেও বাজতে পারে। অ্যালার্মের অনুমতি ছাড়া তা হয় না।';

  @override
  String get healthFocusStep1 => 'নিচে “সেটিংস খুলুন” চাপুন।';

  @override
  String get healthFocusStep2 => 'Memō-র জন্য অ্যালার্মের অনুমতি দিন।';

  @override
  String get healthFocusStep3 => 'Memō-তে ফিরে আসুন।';

  @override
  String get healthBackground => 'ব্যাকগ্রাউন্ড রিফ্রেশ';

  @override
  String get healthBackgroundOk => 'দরকার নেই';

  @override
  String get onbStep3 => 'ধাপ 3/3';

  @override
  String get onbBatteryTitle => 'অ্যালার্ম সচল রাখুন';

  @override
  String get onbBatteryBody =>
      'কিছু ফোন ব্যাটারি বাঁচাতে ব্যাকগ্রাউন্ড অ্যাপ বন্ধ করে দেয়, তাতে অ্যালার্ম দেরিতে বা একেবারেই বাজতে নাও পারে। একটি সেটিং এই ঝুঁকি কমায়।';

  @override
  String get onbBatteryStep1 =>
      'ব্যাকগ্রাউন্ডে চলতে দিন: ব্যাটারি · Memō · বিধিনিষেধহীন';

  @override
  String get onbBatteryStep2 =>
      'অটোস্টার্টের অনুমতি দিন: ফোনের অটোস্টার্ট তালিকায় Memō খুঁজে চালু করুন।';

  @override
  String get onbDidThis => 'আমি করেছি';

  @override
  String get onbSkipRisk => 'বাদ দিন, আমি ঝুঁকি নিচ্ছি';

  @override
  String get healthNotifications => 'নোটিফিকেশন';

  @override
  String get healthExact => 'সঠিক সময়ের অ্যালার্ম';

  @override
  String get healthFullScreen => 'ফুল-স্ক্রিন অ্যালার্ম';

  @override
  String get healthOverlay => 'স্ক্রিন দখল করুন';

  @override
  String get healthAlarms => 'অ্যালার্ম';

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
  String get notifAlarmChannel => 'অ্যালার্ম';

  @override
  String get notifAlarmChannelBody => 'এখন বাজছে এমন রিমাইন্ডার';

  @override
  String get notifMissedChannel => 'মিস হয়েছে';

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
  String confirmReasonDayAndTime(String phrase) {
    return '“$phrase” স্পষ্ট নয়। দিন ও সময় বেছে নিন।';
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

  @override
  String get homeNext => 'পরেরটা';

  @override
  String homeNextWhen(String time, String until) {
    return '$time · $until';
  }

  @override
  String untilDays(int count) {
    return '$count দিন পরে';
  }

  @override
  String untilHours(int count) {
    return '$count ঘণ্টা পরে';
  }

  @override
  String untilMinutes(int count) {
    return '$count মিনিট পরে';
  }

  @override
  String markDoneNamed(String title) {
    return '$title সম্পন্ন করুন';
  }

  @override
  String get swipeSnooze => 'স্নুজ\n10 মিনিট';

  @override
  String get archiveSearchLabel => 'সম্পন্ন রিমাইন্ডার খুঁজুন';

  @override
  String get archiveEmptyTitle => 'এখনও কিছু সম্পন্ন হয়নি';

  @override
  String get archiveEmptyBody =>
      'যে রিমাইন্ডার সম্পন্ন করবেন, সেগুলো এখানে দেখা যাবে। সেগুলো আবার খুলতে পারবেন।';

  @override
  String get commonNone => 'কোনোটি নয়';

  @override
  String get editWhat => 'কী';

  @override
  String get editPickDate => 'তারিখ বাছুন';

  @override
  String get editChangeTime => 'সময় বদলান';

  @override
  String get editMoreOptions =>
      'আরও বিকল্প: নোট, ট্যাগ, বারবার মনে করানো, শব্দ';

  @override
  String get editBackBasic => '‹ মূল';

  @override
  String get editMoreTitle => 'আরও বিকল্প';

  @override
  String get editNote => 'নোট';

  @override
  String get editRemindEarlier => 'আগে মনে করান';

  @override
  String nagSummary(int minutes) {
    return 'প্রতি $minutes মিনিটে, 6 বার';
  }

  @override
  String get editOptionalBody =>
      'এগুলো ঐচ্ছিক। বেশির ভাগ রিমাইন্ডারে শুধু কী আর কখন দরকার।';

  @override
  String get settingsSpeaking => 'বলার ভাষা';

  @override
  String get settingsReadAloudVoice => 'পড়ে শোনানোর কণ্ঠ';

  @override
  String get languageEnglish => 'ইংরেজি';

  @override
  String get sttInstalled => 'এই ফোনে অফলাইনে আছে';

  @override
  String get sttDownloadable => 'ফোনের সেটিংসে ডাউনলোড করতে হবে';

  @override
  String get sttUnavailable => 'এই ফোনে পাওয়া যায় না';

  @override
  String get sttOneLanguage =>
      'Memō একবারে একটি ভাষায় শোনে। নিজে থেকে চেনা এখনও পাওয়া যায় না।';

  @override
  String get voiceTitle => 'পড়ে শোনানোর কণ্ঠ';

  @override
  String get voiceBody =>
      'রিমাইন্ডার বাজলে Memō তার শিরোনাম পড়ে শোনাতে পারে। আপনার লেখা যেমন আছে তেমনই পড়ে; অনুবাদ করে না।';

  @override
  String get voiceFollow => 'রিমাইন্ডারের ভাষা অনুসারে';

  @override
  String get voiceFollowHint => 'হিন্দি রিমাইন্ডার হিন্দিতে, ইংরেজি ইংরেজিতে';

  @override
  String get voiceFollowShort => 'রিমাইন্ডার অনুসারে';

  @override
  String voiceMissing(String language) {
    return 'এই ফোনে $language অফলাইন কণ্ঠ নেই';
  }

  @override
  String get voicePreview => 'শুনুন: “ওষুধ খান”';

  @override
  String get voicePreviewFailed =>
      'সেই ভাষার কোনো অফলাইন কণ্ঠ নেই, তাই কিছু বাজেনি।';

  @override
  String get voiceNotInstalled => 'ইনস্টল করা নেই';

  @override
  String get voiceGenderHint => 'ইংরেজি কণ্ঠ';

  @override
  String get voiceHowTo => 'কণ্ঠ কীভাবে ইনস্টল করবেন';

  @override
  String get voiceHowToAndroid =>
      'ফোনের সেটিংস খুলুন, তারপর টেক্সট-টু-স্পিচ আউটপুট, তারপর আপনার ইঞ্জিনের সেটিংসে গিয়ে সেই ভাষার কণ্ঠ ইনস্টল করুন। অফলাইন কণ্ঠ বেছে নিন।';

  @override
  String get voiceHowToIos =>
      'সেটিংস খুলুন, তারপর অ্যাক্সেসিবিলিটি, স্পোকেন কনটেন্ট, ভয়েস। ভাষা বেছে একটি কণ্ঠ ডাউনলোড করুন।';

  @override
  String get voiceOpenSettings => 'টেক্সট-টু-স্পিচ সেটিংস খুলুন';

  @override
  String voiceNotice(String language) {
    return 'এই ফোনে $language কণ্ঠ নেই। এটি চাইম দিয়ে বাজবে।';
  }

  @override
  String voiceNoticeNote(String language) {
    return 'এই ফোনে $language কণ্ঠ নেই। এটি আপনার ভয়েস নোট দিয়ে বাজবে।';
  }

  @override
  String get quickStartLabel => 'চটজলদি শুরু';

  @override
  String get templateMedicine => 'ওষুধ খাওয়া';

  @override
  String get templateMedicineFill => 'ওষুধ খেতে হবে';

  @override
  String get templateBill => 'বিল দেওয়া';

  @override
  String get templateBillFill => 'বিল দিতে হবে';

  @override
  String get templateCall => 'কাউকে ফোন করা';

  @override
  String get templateCallFill => 'ফোন করতে হবে';

  @override
  String get templateFollowUp => 'ফলো-আপ';

  @override
  String get templateFollowUpFill => 'ফলো-আপ করতে হবে';

  @override
  String get templateWeekly => 'সাপ্তাহিক কাজ';

  @override
  String templateWeeklyFill(String day) {
    return 'প্রতি $day';
  }

  @override
  String get detailHistory => 'আগের রেকর্ড';

  @override
  String historyWeek(int done, int total) {
    return 'এই সপ্তাহে $totalটির মধ্যে $doneটি হয়েছে';
  }

  @override
  String historyDoneAt(String time) {
    return '$time-এ হয়েছে';
  }

  @override
  String historySnoozedDone(int minutes, String time) {
    return '$minutes মিনিট পিছিয়ে, $time-এ হয়েছে';
  }

  @override
  String historySnoozedLongDone(String time) {
    return 'পিছিয়ে, $time-এ হয়েছে';
  }

  @override
  String get historyNotDone => 'হয়েছে বলে চিহ্নিত নয়';

  @override
  String get historyOpen => 'বাকি';

  @override
  String get shareTitle => 'Memō-তে পাঠানো হয়েছে';

  @override
  String get shareFootnote =>
      'শুধু আপনি যা পাঠান। Memō কখনও আপনার মেল পড়ে না।';

  @override
  String get captureDiscard => 'বাদ দিন';
}
