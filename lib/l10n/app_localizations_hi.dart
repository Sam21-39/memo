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
  String get commonDeleteShort => 'मिटाएँ';

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
  String get editNagTitle => 'हो जाने तक बार-बार';

  @override
  String get editNagBody => 'जब तक आप \'हो गया\' न करें, 6 बार तक फिर बजता है।';

  @override
  String get editSound => 'आवाज़';

  @override
  String get editHoldToRecordNote => 'वॉइस नोट रिकॉर्ड करने के लिए टैप करें';

  @override
  String get editReleaseToStop => 'रोकने के लिए छोड़ें';

  @override
  String get editReadAloudWhenRings => 'बजने पर पढ़कर सुनाएँ';

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
  String get detailSnooze => 'स्नूज़';

  @override
  String get snoozeTenMinutes => '10 मिनट';

  @override
  String get snoozeOneHour => '1 घंटा';

  @override
  String get alarmReminder => 'रिमाइंडर';

  @override
  String get alarmSlideToDone => 'हो गया करने के लिए स्लाइड करें';

  @override
  String get archiveSearchHint => 'पूरे किए हुए खोजें';

  @override
  String get archiveEmpty => 'अभी तक कुछ पूरा नहीं हुआ।';

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
  String get settingsAlarms => 'अलार्म';

  @override
  String get settingsNotifications => 'सूचनाएँ';

  @override
  String get settingsExactAlarms => 'सटीक अलार्म';

  @override
  String get settingsFullScreenAlarms => 'फ़ुल-स्क्रीन अलार्म';

  @override
  String get settingsTakeOver => 'स्क्रीन पर छा जाएँ';

  @override
  String get settingsFullScreenAlarm => 'फ़ुल-स्क्रीन अलार्म';

  @override
  String get settingsDefaultNag => 'बार-बार बजने की डिफ़ॉल्ट अवधि';

  @override
  String get settingsDefaultNagBody =>
      'नए रिमाइंडर हो जाने तक इतने अंतराल पर फिर बजते हैं। हर रिमाइंडर में इसे बदला जा सकता है।';

  @override
  String get settingsReadAloud => 'रिमाइंडर पढ़कर सुनाएँ';

  @override
  String get settingsVoice => 'आवाज़';

  @override
  String get settingsFemale => 'महिला';

  @override
  String get settingsMale => 'पुरुष';

  @override
  String get settingsAllowed => 'अनुमति है';

  @override
  String get settingsNotAllowed => 'अनुमति नहीं';

  @override
  String get settingsTakeOverHint =>
      '\"स्क्रीन पर छा जाएँ\" की अनुमति दें, ताकि फ़ोन इस्तेमाल करते समय भी अलार्म पूरी स्क्रीन पर दिखे, सिर्फ़ बैनर नहीं।';

  @override
  String get settingsNotificationsHint =>
      'इसके बिना रिमाइंडर सहेजा तो जा सकता है, पर सुनाई कभी नहीं देगा।';

  @override
  String get settingsCapture => 'कैप्चर';

  @override
  String get settingsDictation => 'बोलकर लिखने की भाषा';

  @override
  String get settingsDictationNone => 'इस फ़ोन में नहीं है';

  @override
  String get settingsEnglish => 'अंग्रेज़ी';

  @override
  String get settingsReadPhotos => 'फ़ोटो डिवाइस पर ही पढ़ें';

  @override
  String get settingsNoSpeechModel =>
      'इस फ़ोन में ऑन-डिवाइस स्पीच मॉडल नहीं है, इसलिए दबाकर रिकॉर्ड किया वॉइस नोट क्लिप के साथ बजता है, पर उसका शीर्षक \"वॉइस नोट\" रहता है। कुछ भी सर्वर पर नहीं भेजा जाता।';

  @override
  String get settingsLook => 'रूप';

  @override
  String get settingsAppearance => 'दिखावट';

  @override
  String get settingsSystem => 'सिस्टम';

  @override
  String get settingsGlass => 'ग्लास क्रोम';

  @override
  String get settingsFollowsIos => 'iOS के अनुसार';

  @override
  String get settingsSolid => 'ठोस';

  @override
  String get settingsPhase2 => 'चरण 2';

  @override
  String get settingsCloudSync => 'क्लाउड सिंक';

  @override
  String get settingsShared => 'साझा रिमाइंडर';

  @override
  String get settingsSoon => 'जल्द';

  @override
  String settingsFooter(String version) {
    return 'Memō $version · कुछ भी इस फ़ोन से बाहर नहीं जाता।';
  }

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
}
