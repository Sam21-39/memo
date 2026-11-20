// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get commonDone => 'हो गया';

  @override
  String get commonCancel => 'रद्द करें';

  @override
  String get commonSave => 'सहेजें';

  @override
  String get commonAdd => 'जोड़ें';

  @override
  String get commonSet => 'सेट करें';

  @override
  String get commonEdit => 'बदलें';

  @override
  String get commonDelete => 'मिटाएँ';

  @override
  String get commonUndo => 'वापस करें';

  @override
  String get commonOn => 'चालू';

  @override
  String get commonOff => 'बंद';

  @override
  String get commonContinue => 'आगे बढ़ें';

  @override
  String get commonSkip => 'छोड़ें';

  @override
  String get commonBack => '‹ वापस';

  @override
  String get commonWorking => 'हो रहा है';

  @override
  String get commonMarkDone => 'पूरा करें';

  @override
  String get commonReopen => 'फिर खोलें';

  @override
  String get commonSnoozeTenMinutes => '10 मिनट बाद फिर बजाएँ';

  @override
  String get commonTryAgain => 'फिर कोशिश करें';

  @override
  String get fieldWhen => 'कब';

  @override
  String get fieldTime => 'समय';

  @override
  String get fieldDate => 'तारीख़';

  @override
  String get fieldRepeat => 'दोहराना';

  @override
  String get fieldTag => 'टैग';

  @override
  String get fieldPreAlarm => 'पहले की चेतावनी';

  @override
  String get reminderHint => 'मुझे याद दिलाना…';

  @override
  String get reminderMissing => 'यह रिमाइंडर अब मौजूद नहीं है।';

  @override
  String get dateToday => 'आज';

  @override
  String get dateTomorrow => 'कल';

  @override
  String get dateYesterday => 'बीता कल';

  @override
  String lateDays(int count) {
    return '$count दिन देर';
  }

  @override
  String lateHours(int count) {
    return '$count घंटे देर';
  }

  @override
  String lateMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count मिनट देर',
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
  String get homeAll => 'सभी';

  @override
  String get homeOverdue => 'देर हो गई';

  @override
  String get homeSummaryNone => 'कुछ तय नहीं';

  @override
  String homeScheduled(int count) {
    return '$count बाकी';
  }

  @override
  String homeScheduledOverdue(int scheduled, int overdue) {
    return '$scheduled बाकी · $overdue देर से';
  }

  @override
  String get homeEmptyTitle => 'कुछ तय नहीं';

  @override
  String get homeEmptyBody =>
      'कूड़ा, दवा, वो फ़ोन कॉल।\nनीचे लिखें, या माइक टैप करके बोलें।';

  @override
  String get homeLoadFailedTitle => 'आपके रिमाइंडर लोड नहीं हो सके';

  @override
  String get homeLoadFailedBody =>
      'ये अब भी इस फ़ोन में सुरक्षित हैं। जो अलार्म लग चुके हैं, वे बजते रहेंगे।';

  @override
  String homeDeleted(String title) {
    return '$title मिटा दिया गया';
  }

  @override
  String homeCompleted(String title) {
    return '$title हो गया';
  }

  @override
  String get captureAddPhoto => 'फ़ोटो जोड़ें';

  @override
  String captureElapsed(String elapsed) {
    return '● $elapsed';
  }

  @override
  String get captureRepeatWeekdays => 'कार्यदिवस';

  @override
  String repeatEveryDay(String day) {
    return 'हर $day';
  }

  @override
  String captureTime(String when) {
    return 'समय: $when';
  }

  @override
  String captureTimeGuess(String when) {
    return 'समय, अंदाज़ा: $when';
  }

  @override
  String clipNote(String length) {
    return '$length · आपका नोट';
  }

  @override
  String clipNotePlaying(String length) {
    return '$length · आपका नोट · बज रहा है';
  }

  @override
  String get repeatSheetBody =>
      '\'हो गया\' दबाने पर यह संग्रह में जाने की जगह अगले समय पर चला जाता है।';

  @override
  String get tagSheetBody => 'हर रिमाइंडर पर एक। रंग नाम से तय होता है।';

  @override
  String get tagNewHint => 'नया टैग…';

  @override
  String voiceNoteTitle(String length) {
    return 'वॉइस नोट · $length';
  }

  @override
  String get holdMicOn =>
      'माइक्रोफ़ोन चालू है। रिकॉर्ड करने के लिए माइक टैप करें।';

  @override
  String get holdMicDenied =>
      'माइक्रोफ़ोन की अनुमति नहीं है। इसे सेटिंग्स में चालू करें।';

  @override
  String get holdHint => 'माइक टैप करें, बोलें, फिर रोकें दबाएँ।';

  @override
  String get editNew => 'नया रिमाइंडर';

  @override
  String get editExisting => 'रिमाइंडर बदलें';

  @override
  String get editNoteHint => 'नोट जोड़ें';

  @override
  String get editPreAlarmBody => 'बजने से पहले एक पूर्व सूचना।';

  @override
  String get editNagTitle => 'अगर मैं जवाब न दूँ';

  @override
  String get editNagBody => 'जब तक आप \'हो गया\' न करें, 6 बार तक फिर बजता है।';

  @override
  String get editSound => 'आवाज़';

  @override
  String get editHoldToRecordNote => 'वॉइस नोट रिकॉर्ड करने के लिए टैप करें';

  @override
  String get editReleaseToStop => 'रोकने के लिए छोड़ें';

  @override
  String get editReadAloudWhenRings => 'शीर्षक पढ़कर सुनाएँ';

  @override
  String get editNewTagChip => '+ नया';

  @override
  String get editNewTagTitle => 'नया टैग';

  @override
  String get editTagHint => 'घर, काम, सेहत…';

  @override
  String editRecordingMax(String max) {
    return ' / $max';
  }

  @override
  String get voicePlay => 'वॉइस नोट चलाएँ';

  @override
  String get voiceStop => 'वॉइस नोट रोकें';

  @override
  String get voiceDelete => 'वॉइस नोट मिटाएँ';

  @override
  String get repeatNone => 'नहीं';

  @override
  String get repeatNever => 'कभी नहीं';

  @override
  String get repeatDaily => 'रोज़';

  @override
  String get repeatWeekly => 'हर हफ़्ते';

  @override
  String get repeatCustom => 'अपनी पसंद';

  @override
  String get repeatsSemantic => 'दोहराता है';

  @override
  String get detailDeleteTitle => 'यह रिमाइंडर मिटाएँ?';

  @override
  String get detailDeleteBody =>
      'यह बजना बंद कर देगा। इसे वापस नहीं लाया जा सकता।';

  @override
  String get detailNext => 'अगला';

  @override
  String get detailNag => 'बार-बार';

  @override
  String get detailCreated => 'बनाया गया';

  @override
  String get detailSnooze => 'बाद में याद दिलाएँ';

  @override
  String get alarmReminder => 'रिमाइंडर';

  @override
  String get archiveSearchHint => 'खोजें';

  @override
  String get archiveNoMatch => 'कुछ मेल नहीं खाता।';

  @override
  String archiveThisWeek(int n) {
    return 'इस हफ़्ते $n';
  }

  @override
  String get minutesCustomHint => 'अपने मिनट';

  @override
  String everyMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'हर $minutes मिनट',
      one: 'हर मिनट',
    );
    return '$_temp0';
  }

  @override
  String hoursBefore(int h) {
    return '$h घंटे पहले';
  }

  @override
  String minutesBefore(int m) {
    return '$m मिनट पहले';
  }

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get settingsLanguageVoice => 'भाषा और आवाज़';

  @override
  String get settingsAppLanguage => 'ऐप की भाषा';

  @override
  String get settingsDefaultNagBody =>
      'नए रिमाइंडर हो जाने तक इतने अंतराल पर फिर बजते हैं। हर रिमाइंडर में इसे बदला जा सकता है।';

  @override
  String get settingsVoice => 'आवाज़';

  @override
  String get settingsFemale => 'महिला';

  @override
  String get settingsMale => 'पुरुष';

  @override
  String get settingsAppearance => 'दिखावट';

  @override
  String get settingsSystem => 'सिस्टम';

  @override
  String settingsFooter(String version) {
    return 'Memō $version · कुछ भी इस फ़ोन से बाहर नहीं जाता।';
  }

  @override
  String get settingsReminders => 'रिमाइंडर';

  @override
  String get settingsNoResponse => 'जवाब न देने पर';

  @override
  String get settingsReadTitle => 'शीर्षक पढ़कर सुनाएँ';

  @override
  String get settingsReliability => 'अलार्म की विश्वसनीयता';

  @override
  String get settingsHealth => 'अलार्म की स्थिति';

  @override
  String get healthAllSet => 'सब ठीक है';

  @override
  String healthToFix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count चीज़ें ठीक करनी हैं',
      one: '1 चीज़ ठीक करनी है',
    );
    return '$_temp0';
  }

  @override
  String get settingsTest => 'टेस्ट अलार्म';

  @override
  String get settingsTestValue => '10 सेकंड में बजेगा';

  @override
  String get testStarted => 'फ़ोन लॉक कर दें। यह करीब 10 सेकंड में बजेगा।';

  @override
  String get testFailed => 'टेस्ट अलार्म सेट नहीं हो सका। फिर कोशिश करें।';

  @override
  String get testAlarmTitle => 'टेस्ट अलार्म';

  @override
  String get settingsTheme => 'थीम';

  @override
  String get settingsLight => 'हल्का';

  @override
  String get settingsDark => 'गहरा';

  @override
  String get settingsAbout => 'जानकारी';

  @override
  String get settingsPrivacy => 'गोपनीयता';

  @override
  String get settingsPrivacyValue => 'कुछ भी फ़ोन से बाहर नहीं जाता';

  @override
  String get privacyBody =>
      'आपके रिमाइंडर इसी फ़ोन में रखे जाते हैं। आवाज़ को लिखित रूप में इसी फ़ोन पर बदला जाता है। कोई खाता नहीं है और कोई एनालिटिक्स नहीं।';

  @override
  String get healthTitle => 'अलार्म की स्थिति';

  @override
  String get healthBodyOk =>
      'यह फ़ोन Memō के रिमाइंडर बजाने के लिए तैयार है। कोई भी फ़ोन हर अलार्म की गारंटी नहीं दे सकता, इसलिए एक बार टेस्ट कर लें।';

  @override
  String healthBodyFix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count सेटिंग रिमाइंडर को समय पर बजने से रोक सकती हैं।',
      one: '1 सेटिंग रिमाइंडर को समय पर बजने से रोक सकती है।',
    );
    return '$_temp0';
  }

  @override
  String get healthAllowed => 'अनुमति है';

  @override
  String get healthOk => 'ठीक';

  @override
  String get healthFix => 'ठीक करें';

  @override
  String get healthOff => 'बंद';

  @override
  String healthFixFirst(String title) {
    return 'ठीक करें: $title';
  }

  @override
  String get healthTestButton => '10 सेकंड में टेस्ट अलार्म बजाएँ';

  @override
  String healthLastTest(String when) {
    return 'आख़िरी टेस्ट शुरू हुआ: $when।';
  }

  @override
  String healthFixStep(int n, int total) {
    return 'सुधार $n/$total';
  }

  @override
  String healthDetected(String maker) {
    return 'पहचाना गया: $maker।';
  }

  @override
  String get healthOpenBattery => 'बैटरी सेटिंग खोलें';

  @override
  String get healthOpenSettings => 'सेटिंग खोलें';

  @override
  String get healthCheckAgain => 'मैंने बदल दिया, फिर जाँचें';

  @override
  String get healthNotificationsOk => 'बैनर और आवाज़';

  @override
  String get healthNotificationsBad => 'बंद: रिमाइंडर नहीं बज सकते';

  @override
  String get healthNotificationsBody =>
      'सूचनाओं के बिना रिमाइंडर सहेजा तो जा सकता है, पर सुनाई नहीं देगा।';

  @override
  String get healthNotificationsStep1 => 'नीचे “सेटिंग खोलें” दबाएँ।';

  @override
  String get healthNotificationsStep2 => 'सूचनाएँ चुनें।';

  @override
  String get healthNotificationsStep3 =>
      'सूचनाओं की अनुमति चालू करें, फिर Memō पर लौट आएँ।';

  @override
  String get healthExactOk => 'अनुमति है';

  @override
  String get healthExactBad => 'बंद: अलार्म देर से बज सकते हैं';

  @override
  String get healthExactBody =>
      'सटीक अलार्म के बिना फ़ोन रिमाइंडर को कई मिनट देर से बजा सकता है।';

  @override
  String get healthExactStep1 => 'नीचे “सेटिंग खोलें” दबाएँ।';

  @override
  String get healthExactStep2 => 'सूची में Memō ढूँढें।';

  @override
  String get healthExactStep3 => 'अनुमति चालू करें, फिर Memō पर लौट आएँ।';

  @override
  String get healthFullScreenOk => 'अनुमति है';

  @override
  String get healthFullScreenBad => 'बंद: अलार्म छोटे बैनर की तरह दिखता है';

  @override
  String get healthFullScreenBody =>
      'इसके बिना लॉक फ़ोन पर अलार्म सिर्फ़ छोटे बैनर की तरह दिखता है।';

  @override
  String get healthFullScreenStep1 => 'नीचे “सेटिंग खोलें” दबाएँ।';

  @override
  String get healthFullScreenStep2 =>
      'Memō के लिए फ़ुल-स्क्रीन सूचनाएँ चालू करें।';

  @override
  String get healthFullScreenStep3 => 'Memō पर लौट आएँ।';

  @override
  String get healthOverlayOk => 'अनुमति है';

  @override
  String get healthOverlayBad => 'बंद: फ़ोन इस्तेमाल करते समय सिर्फ़ बैनर';

  @override
  String get healthOverlayBody =>
      'इसके बिना फ़ोन इस्तेमाल करते समय अलार्म सिर्फ़ बैनर बनकर आता है।';

  @override
  String get healthOverlayStep1 => 'नीचे “सेटिंग खोलें” दबाएँ।';

  @override
  String get healthOverlayStep2 => 'Memō चुनें।';

  @override
  String get healthOverlayStep3 =>
      'दूसरे ऐप्स के ऊपर दिखाने की अनुमति चालू करें, फिर Memō पर लौट आएँ।';

  @override
  String get healthBattery => 'बैटरी';

  @override
  String get healthBatteryOk => 'बिना पाबंदी';

  @override
  String get healthBatteryBad => 'बिना पाबंदी नहीं: फ़ोन Memō को रोक सकता है';

  @override
  String get healthBatteryBody =>
      'जब तक ऐप बिना पाबंदी न चले, फ़ोन उसे रोक सकता है, और उसके अलार्म नहीं बज सकते।';

  @override
  String get healthBatteryStep1 => 'नीचे “बैटरी सेटिंग खोलें” दबाएँ।';

  @override
  String get healthBatteryStep2 => 'बैटरी चुनें।';

  @override
  String get healthBatteryStep3 => 'बिना पाबंदी चुनें।';

  @override
  String get healthBatteryStep4 => 'Memō पर लौट आएँ।';

  @override
  String get healthAlarmsOk => 'Memō के लिए अनुमति है';

  @override
  String get healthAlarmsBad => 'बंद: Memō सूचनाओं पर लौट आता है';

  @override
  String get healthAlarmsBody =>
      'अलार्म की अनुमति के बिना Memō सिर्फ़ सूचनाएँ भेज सकता है, जिन्हें साइलेंट मोड छिपा सकता है।';

  @override
  String get healthAlarmsStep1 => 'नीचे “सेटिंग खोलें” दबाएँ।';

  @override
  String get healthAlarmsStep2 => 'अलार्म चुनें, या फ़ोन पूछे तो अनुमति दें।';

  @override
  String get healthAlarmsStep3 => 'इसे चालू करें, फिर Memō पर लौट आएँ।';

  @override
  String get healthFocus => 'फ़ोकस और साइलेंट मोड';

  @override
  String get healthFocusOk => 'अलार्म बजते हैं';

  @override
  String get healthFocusInfo => 'फ़ोकस रिमाइंडर को शांत कर सकता है';

  @override
  String get healthFocusBad => 'फ़ोकस रिमाइंडर को शांत कर सकता है';

  @override
  String get healthFocusBody =>
      'असली अलार्म फ़ोकस और साइलेंट मोड में भी बज सकते हैं। अलार्म की अनुमति के बिना ऐसा नहीं होता।';

  @override
  String get healthFocusStep1 => 'नीचे “सेटिंग खोलें” दबाएँ।';

  @override
  String get healthFocusStep2 => 'Memō के लिए अलार्म की अनुमति दें।';

  @override
  String get healthFocusStep3 => 'Memō पर लौट आएँ।';

  @override
  String get healthBackground => 'बैकग्राउंड रिफ़्रेश';

  @override
  String get healthBackgroundOk => 'ज़रूरी नहीं';

  @override
  String get onbStep3 => 'चरण 3 / 3';

  @override
  String get onbBatteryTitle => 'अलार्म चालू रखें';

  @override
  String get onbBatteryBody =>
      'कुछ फ़ोन बैटरी बचाने के लिए बैकग्राउंड ऐप रोक देते हैं, जिससे अलार्म देर से या बिल्कुल नहीं बज सकता। एक सेटिंग इस जोखिम को घटाती है।';

  @override
  String get onbBatteryStep1 =>
      'बैकग्राउंड में चलने दें: बैटरी · Memō · बिना पाबंदी';

  @override
  String get onbBatteryStep2 =>
      'ऑटोस्टार्ट की अनुमति दें: अपने फ़ोन की ऑटोस्टार्ट सूची में Memō ढूँढकर उसे चालू करें।';

  @override
  String get onbDidThis => 'मैंने कर दिया';

  @override
  String get onbSkipRisk => 'छोड़ें, मैं जोखिम लूँगा';

  @override
  String get healthNotifications => 'सूचनाएँ';

  @override
  String get healthExact => 'सटीक अलार्म';

  @override
  String get healthFullScreen => 'फ़ुल-स्क्रीन अलार्म';

  @override
  String get healthOverlay => 'स्क्रीन पर छा जाएँ';

  @override
  String get healthAlarms => 'अलार्म';

  @override
  String get languageTitle => 'भाषा';

  @override
  String get languageSystem => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get languageBengali => 'बंगाली';

  @override
  String get welcomeTitle => 'एक पंक्ति,\nएक समय।';

  @override
  String get welcomeBody1 =>
      'जो बात आप भूल जाते हैं, उसे लिखें, बोलें या उसकी फ़ोटो लें। Memō ठीक उसी समय बजता है, ऐप बंद हो या नेटवर्क न हो तब भी।';

  @override
  String get welcomeBody2 =>
      'कुछ भी आपके फ़ोन से बाहर नहीं जाता। न खाता, न सिंक, न एनालिटिक्स।';

  @override
  String get permTitle => 'Memō को बजने दें';

  @override
  String get permBody1 =>
      'अलार्म सूचनाएँ ही होते हैं। अगली स्क्रीन पर फ़ोन आपसे इनकी अनुमति माँगेगा। इसके अलावा कुछ और नहीं माँगा जाता।';

  @override
  String get permBody2 =>
      'Android पर आपसे सटीक अलार्म की अनुमति भी माँगी जाएगी, ताकि 7:00 का रिमाइंडर 7:00 पर ही बजे, 7:40 पर नहीं।';

  @override
  String get permAllow => 'सूचनाओं की अनुमति दें';

  @override
  String get permNotNow => 'अभी नहीं';

  @override
  String get notifChannelName => 'रिमाइंडर';

  @override
  String get notifChannelDescription => 'तय किए गए रिमाइंडर अलार्म';

  @override
  String get notifSnooze => '10 मि स्नूज़';

  @override
  String get notifAlarmChannel => 'अलार्म';

  @override
  String get notifAlarmChannelBody => 'अभी बज रहे रिमाइंडर';

  @override
  String get notifMissedChannel => 'छूटे';

  @override
  String missed(String title) {
    return 'छूटा: $title';
  }

  @override
  String spokenReminder(String title) {
    return 'रिमाइंडर। $title।';
  }

  @override
  String spokenReminderNote(String title, String note) {
    return 'रिमाइंडर। $title। $note।';
  }

  @override
  String get spokenPreview => 'रिमाइंडर। अपनी दवा लीजिए।';

  @override
  String get scheduleFailed =>
      'सहेजा गया, पर अलार्म सेट नहीं हो सका। अगली बार ऐप खोलने पर Memō फिर कोशिश करेगा।';

  @override
  String get saveFailed => 'सहेजा नहीं जा सका। कुछ नहीं बदला, फिर कोशिश करें।';

  @override
  String get deleteFailed => 'मिटाया नहीं जा सका। फिर कोशिश करें।';

  @override
  String get timePassed => 'वह समय बीत चुका है। बाद का कोई समय चुनें।';

  @override
  String get captureHintLine => 'लिखें, या माइक टैप करके बोलें';

  @override
  String repeatChip(String value) {
    return 'दोहराएँ: $value';
  }

  @override
  String get micRecord => 'रिमाइंडर रिकॉर्ड करें';

  @override
  String get micTapToStart => 'रिकॉर्डिंग शुरू करने के लिए दो बार टैप करें';

  @override
  String get micTapToStop => 'रोकने के लिए टैप करें';

  @override
  String get openSettings => 'सेटिंग्स खोलें';

  @override
  String get recRecording => 'रिकॉर्डिंग';

  @override
  String recTimer(String elapsed, String max) {
    return '$elapsed / $max';
  }

  @override
  String get recHint =>
      'क्या और कब, बोलिए। जैसे: “शुक्रवार को 10 बजे बिल भरना”।';

  @override
  String get recStop => 'रोकें';

  @override
  String get recStopLabel => 'रिकॉर्डिंग रोकें';

  @override
  String get recTipHold => 'सुझाव: माइक को दबाए रखें, छोड़ने पर रुक जाएगा।';

  @override
  String get recReleaseToStop => 'रोकने के लिए छोड़ें, या रोकें दबाएँ।';

  @override
  String get recUnderstanding => 'आपकी रिकॉर्डिंग समझी जा रही है';

  @override
  String recOnThisPhone(String language) {
    return 'इसी फ़ोन पर, $language में। कुछ भी कहीं नहीं भेजा जाता।';
  }

  @override
  String get recFailedTitle => 'इसे टेक्स्ट में नहीं बदल सके';

  @override
  String recFailedUnavailable(String language) {
    return 'इस फ़ोन पर $language बोली ऑफ़लाइन उपलब्ध नहीं है। आपकी रिकॉर्डिंग रखी गई है।';
  }

  @override
  String get recFailedEmpty =>
      'कुछ पहचाना नहीं गया। आपकी रिकॉर्डिंग रखी गई है।';

  @override
  String get recKeptTitle => 'रिकॉर्डिंग रखी गई';

  @override
  String get recKeptBody => 'इसका क्या करना है, चुनें।';

  @override
  String get recKept => 'रखी गई';

  @override
  String get recTypeInstead => 'इसके बजाय लिखें';

  @override
  String get recSaveAsNote => 'वॉइस नोट सेव करें, समय चुनें';

  @override
  String confirmYouWrote(String text) {
    return 'आपने लिखा: “$text”';
  }

  @override
  String confirmYouSaid(String text) {
    return 'आपने कहा: “$text”';
  }

  @override
  String get confirmSave => 'रिमाइंडर सेव करें';

  @override
  String get confirmEdit => 'बदलें';

  @override
  String get confirmTimeBadge => 'समय पक्का करें';

  @override
  String get confirmTimeQuestion => 'क्या यह सही समय है?';

  @override
  String confirmReasonAmPm(String phrase) {
    return 'आपने “$phrase” कहा। सुबह या शाम, चुनें।';
  }

  @override
  String get confirmReasonNoTime => 'कोई समय नहीं बताया गया। एक चुनें।';

  @override
  String confirmReasonDayWord(String phrase) {
    return '“$phrase” दो दिनों का हो सकता है। एक चुनें।';
  }

  @override
  String confirmReasonDayAndTime(String phrase) {
    return '“$phrase” स्पष्ट नहीं है। दिन और समय चुनें।';
  }

  @override
  String get confirmOtherTime => 'दूसरा समय…';

  @override
  String savedToday(String time) {
    return 'रिमाइंडर आज $time के लिए सेट है।';
  }

  @override
  String savedTomorrow(String time) {
    return 'रिमाइंडर कल $time के लिए सेट है।';
  }

  @override
  String savedOn(String date, String time) {
    return 'रिमाइंडर $date को $time के लिए सेट है।';
  }

  @override
  String get welcomeBody1NoPhoto =>
      'जो बात आप भूल जाते हैं, उसे लिखें या बोलें। Memō ठीक उसी समय बजता है, ऐप बंद हो या नेटवर्क न हो तब भी।';

  @override
  String get snoozeTitle => 'कब तक स्नूज़ करें…';

  @override
  String get snoozeBody => 'यह फिर बजेगा, उसी आवाज़ में।';

  @override
  String get snooze10 => '10 मिनट के लिए स्नूज़ करें';

  @override
  String get snooze1h => '1 घंटे के लिए स्नूज़ करें';

  @override
  String get snoozeTomorrow => 'कल, इसी समय';

  @override
  String get snoozePick => 'समय चुनें';

  @override
  String get snoozePastTime => 'वह समय बीत चुका है। आगे का समय चुनें।';

  @override
  String get alarmReadingInEn => 'अंग्रेज़ी में पढ़कर सुनाया जा रहा है';

  @override
  String get alarmReadingInHi => 'हिन्दी में पढ़कर सुनाया जा रहा है';

  @override
  String get alarmReadingInBn => 'बंगाली में पढ़कर सुनाया जा रहा है';

  @override
  String detailRepeatNext(String repeat, String when) {
    return '$repeat · अगला $when';
  }

  @override
  String get detailDoneToday => 'आज के लिए पूरा करें';

  @override
  String detailMovesTo(String when) {
    return 'पूरा करने पर यह $when पर चला जाएगा।';
  }

  @override
  String get detailDelete => 'रिमाइंडर मिटाएँ';

  @override
  String get repeatEveryDayLong => 'हर दिन';

  @override
  String get homeNext => 'अगला';

  @override
  String homeNextWhen(String time, String until) {
    return '$time · $until';
  }

  @override
  String untilDays(int count) {
    return '$count दिन में';
  }

  @override
  String untilHours(int count) {
    return '$count घंटे में';
  }

  @override
  String untilMinutes(int count) {
    return '$count मिनट में';
  }

  @override
  String markDoneNamed(String title) {
    return '$title पूरा करें';
  }

  @override
  String get swipeSnooze => 'स्नूज़\n10 मिनट';

  @override
  String get archiveSearchLabel => 'पूरे किए रिमाइंडर खोजें';

  @override
  String get archiveEmptyTitle => 'अभी कुछ पूरा नहीं हुआ';

  @override
  String get archiveEmptyBody =>
      'जो रिमाइंडर आप पूरे करते हैं, वे यहाँ दिखते हैं। आप उन्हें फिर खोल सकते हैं।';

  @override
  String get commonNone => 'कोई नहीं';

  @override
  String get editWhat => 'क्या';

  @override
  String get editPickDate => 'तारीख़ चुनें';

  @override
  String get editChangeTime => 'समय बदलें';

  @override
  String get editMoreOptions => 'और विकल्प: नोट, टैग, बार-बार याद, आवाज़';

  @override
  String get editBackBasic => '‹ मूल';

  @override
  String get editMoreTitle => 'और विकल्प';

  @override
  String get editNote => 'नोट';

  @override
  String get editRemindEarlier => 'पहले याद दिलाएँ';

  @override
  String nagSummary(int minutes) {
    return 'हर $minutes मिनट, 6 बार';
  }

  @override
  String get editOptionalBody =>
      'ये वैकल्पिक हैं। ज़्यादातर रिमाइंडर को बस क्या और कब चाहिए।';

  @override
  String get settingsSpeaking => 'बोलने की भाषा';

  @override
  String get settingsReadAloudVoice => 'पढ़कर सुनाने की आवाज़';

  @override
  String get languageEnglish => 'अंग्रेज़ी';

  @override
  String get sttInstalled => 'इस फ़ोन पर ऑफ़लाइन';

  @override
  String get sttDownloadable => 'फ़ोन की सेटिंग में डाउनलोड करना होगा';

  @override
  String get sttUnavailable => 'इस फ़ोन पर उपलब्ध नहीं';

  @override
  String get sttOneLanguage =>
      'Memō एक बार में एक ही भाषा सुनता है। अपने-आप पहचान अभी उपलब्ध नहीं है।';

  @override
  String get voiceTitle => 'पढ़कर सुनाने की आवाज़';

  @override
  String get voiceBody =>
      'रिमाइंडर बजने पर Memō उसका शीर्षक पढ़कर सुना सकता है। यह आपके शब्द जैसे लिखे हैं वैसे ही पढ़ता है; अनुवाद नहीं करता।';

  @override
  String get voiceFollow => 'रिमाइंडर की भाषा के अनुसार';

  @override
  String get voiceFollowHint =>
      'हिन्दी रिमाइंडर हिन्दी में, अंग्रेज़ी अंग्रेज़ी में';

  @override
  String get voiceFollowShort => 'रिमाइंडर के अनुसार';

  @override
  String voiceMissing(String language) {
    return 'इस फ़ोन पर $language की ऑफ़लाइन आवाज़ नहीं है';
  }

  @override
  String get voicePreview => 'सुनें: “दवा लीजिए”';

  @override
  String get voicePreviewFailed =>
      'उस भाषा की कोई ऑफ़लाइन आवाज़ नहीं है, इसलिए कुछ नहीं बजा।';

  @override
  String get voiceNotInstalled => 'इंस्टॉल नहीं है';

  @override
  String get voiceGenderHint => 'अंग्रेज़ी आवाज़ें';

  @override
  String get voiceHowTo => 'आवाज़ कैसे इंस्टॉल करें';

  @override
  String get voiceHowToAndroid =>
      'फ़ोन की सेटिंग खोलें, फिर टेक्स्ट-टू-स्पीच आउटपुट, फिर अपने इंजन की सेटिंग में जाकर उस भाषा की आवाज़ इंस्टॉल करें। ऑफ़लाइन आवाज़ चुनें।';

  @override
  String get voiceHowToIos =>
      'सेटिंग खोलें, फिर एक्सेसिबिलिटी, स्पोकन कंटेंट, आवाज़ें। भाषा चुनें और एक आवाज़ डाउनलोड करें।';

  @override
  String get voiceOpenSettings => 'टेक्स्ट-टू-स्पीच सेटिंग खोलें';

  @override
  String voiceNotice(String language) {
    return 'इस फ़ोन पर $language की आवाज़ नहीं है। यह घंटी के साथ बजेगा।';
  }

  @override
  String voiceNoticeNote(String language) {
    return 'इस फ़ोन पर $language की आवाज़ नहीं है। यह आपके वॉइस नोट के साथ बजेगा।';
  }
}
