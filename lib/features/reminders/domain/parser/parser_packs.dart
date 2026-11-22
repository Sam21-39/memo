/// Hindi and Bengali parser rule tables. Data only: the generic pass lives
/// in `reminder_parser.dart`.
///
/// Words starting with an ASCII letter are Latin transliteration ("kal",
/// "baje"); the parser only uses them when the user opted in. Nukta letters
/// may be written precomposed or decomposed here; the parser accepts both.
///
/// ponytail: tables, not a framework. A third language is a third const.
class ParserPack {
  const ParserPack({
    required this.today,
    required this.tomorrow,
    required this.dayAfter,
    required this.ambiguousDays,
    required this.weekdays,
    required this.months,
    required this.parts,
    required this.clock,
    required this.daily,
    required this.every,
    required this.after,
    required this.units,
    required this.numbers,
    required this.fractions,
    required this.specials,
    required this.glue,
    this.next = const [],
    this.weakClock = const [],
    this.quantities = const {},
  });

  final List<String> today, tomorrow, dayAfter;

  /// Day words that can also mean the past ("कल" is yesterday or tomorrow).
  /// The parser picks the future reading and asks.
  final List<String> ambiguousDays;
  final Map<String, int> weekdays, months;

  /// Part of day → [PartRule]. A spoken hour beside it is read through the
  /// rule's windows; outside every window the time stays unsure.
  final Map<String, PartRule> parts;
  final List<String> clock, daily, every, after;

  /// Word → m | h | d | w | mo | y.
  final Map<String, String> units;

  /// Number words 1-12.
  final Map<String, int> numbers;

  /// "साढ़े 6": minutes added to the hour; negative borrows ("पौने 9" 8:45).
  final Map<String, int> fractions;

  /// "डेढ़ बजे": a whole time, no number.
  final Map<String, (int, int)> specials;

  /// Filler stripped from the title ends, longest phrase first not required.
  final List<String> glue;

  /// "अगले सोमवार": optional prefix before a weekday, same +7 rule as English.
  final List<String> next;

  /// Clock words that are also counting words ("৫টা ডিম" is five eggs): they
  /// count as a time only beside a part of day. Subset of [clock].
  final List<String> weakClock;

  /// "आधे घंटे बाद": a fractional amount for a relative time, in units.
  final Map<String, double> quantities;
}

/// A part of day: default (hour, minute), and the spoken hours it settles.
/// Each window is (first, last, pm) over spoken hours 1-12; pm adds 12.
typedef PartRule = (int, int, List<(int, int, bool)>);

const _subah = (8, 0, [(4, 11, false)]);
const _dopahar = (13, 0, [(12, 12, true), (1, 4, true)]);
const _shaam = (18, 0, [(3, 11, true)]);
const _raat = (21, 0, [(7, 11, true), (12, 12, false), (1, 5, false)]);
const _bhor = (5, 0, [(3, 7, false)]);
const _bikel = (16, 0, [(3, 6, true)]);
const _sondhya = (18, 0, [(5, 9, true)]);

// Latin words that are also English ("aj", "parson", "sham", "roz", "rat") are
// deliberately absent: "Call AJ", "parson street", "buy rat poison".
const hindi = ParserPack(
  today: ['aaj', 'आज'],
  tomorrow: ['kal', 'कल'],
  dayAfter: ['parso', 'परसों', 'परसो'],
  ambiguousDays: ['kal', 'कल', 'parso', 'परसों', 'परसो'],
  weekdays: {
    'somvar': 1, 'somwar': 1, 'सोमवार': 1,
    'mangalvar': 2, 'mangalwar': 2, 'मंगलवार': 2,
    'budhvar': 3, 'budhwar': 3, 'बुधवार': 3,
    'guruvar': 4, 'guruwar': 4, 'brihaspativar': 4,
    'गुरुवार': 4, 'बृहस्पतिवार': 4,
    'shukravar': 5, 'shukrawar': 5, 'शुक्रवार': 5,
    'shanivar': 6, 'shaniwar': 6, 'शनिवार': 6,
    'ravivar': 7, 'raviwar': 7, 'itvar': 7, 'रविवार': 7, 'इतवार': 7, //
  },
  months: {
    'janvari': 1, 'जनवरी': 1,
    'farvari': 2, 'फ़रवरी': 2, 'फरवरी': 2,
    'march': 3, 'मार्च': 3,
    'april': 4, 'अप्रैल': 4,
    'mai': 5, 'मई': 5,
    'joon': 6, 'जून': 6,
    'julai': 7, 'जुलाई': 7,
    'agast': 8, 'अगस्त': 8,
    'sitambar': 9, 'सितंबर': 9, 'सितम्बर': 9,
    'aktubar': 10, 'अक्टूबर': 10,
    'navambar': 11, 'नवंबर': 11, 'नवम्बर': 11,
    'disambar': 12, 'दिसंबर': 12, 'दिसम्बर': 12, //
  },
  parts: {
    'subah': _subah, 'subha': _subah, 'सुबह': _subah,
    'dopahar': _dopahar, 'dopehar': _dopahar, 'दोपहर': _dopahar,
    'shaam': _shaam, 'शाम': _shaam,
    'raat': _raat, 'रात': _raat, //
  },
  clock: ['baje', 'बजे'],
  daily: [
    'har roz', 'har din', 'rozana', //
    'हर रोज़', 'हर रोज', 'हर दिन', 'रोज़ाना', 'रोजाना', 'रोज़', 'रोज',
  ],
  every: ['har', 'हर'],
  after: ['mein', 'me', 'baad', 'bad', 'में', 'बाद'],
  units: {
    'minute': 'm', 'minat': 'm', 'min': 'm', 'मिनट': 'm',
    'ghanta': 'h', 'ghante': 'h', 'घंटा': 'h', 'घंटे': 'h',
    'घण्टा': 'h', 'घण्टे': 'h',
    'din': 'd', 'दिन': 'd',
    'hafta': 'w', 'hafte': 'w', 'हफ्ता': 'w', 'हफ्ते': 'w', 'हफ़्ते': 'w',
    'mahina': 'mo', 'mahine': 'mo', 'महीना': 'mo', 'महीने': 'mo',
    'saal': 'y', 'साल': 'y', //
  },
  numbers: {
    'ek': 1, 'एक': 1,
    'do': 2, 'दो': 2,
    'teen': 3, 'तीन': 3,
    'char': 4, 'चार': 4,
    'paanch': 5, 'panch': 5, 'पाँच': 5, 'पांच': 5,
    'chhah': 6, 'chhe': 6, 'छह': 6, 'छः': 6, 'छ': 6,
    'saat': 7, 'सात': 7,
    'aath': 8, 'आठ': 8,
    'nau': 9, 'नौ': 9,
    'das': 10, 'दस': 10,
    'gyarah': 11, 'ग्यारह': 11,
    'barah': 12, 'बारह': 12, //
  },
  fractions: {
    'साढ़े': 30, 'साढे': 30, 'saade': 30, 'sadhe': 30,
    'सवा': 15, 'sava': 15, 'sawa': 15,
    'पौने': -15, 'paune': -15, //
  },
  specials: {'डेढ़': (1, 30), 'dedh': (1, 30), 'ढाई': (2, 30), 'dhai': (2, 30)},
  next: ['agle', 'agla', 'अगले', 'अगला'],
  quantities: {
    'डेढ़': 1.5, 'dedh': 1.5, 'ढाई': 2.5, 'dhai': 2.5, //
    'आधे': 0.5, 'aadhe': 0.5, 'adhe': 0.5,
  },
  glue: [
    'की याद दिलाना', 'याद दिलाना', 'याद दिला देना', 'याद दिलाओ',
    'yaad dilana', 'ko', 'ki', 'ka', 'ke', 'yaad', 'dilana', 'dilao',
    'mujhe', 'को', 'की', 'का', 'के', 'याद', 'दिलाना', 'मुझे', //
  ],
);

const bengali = ParserPack(
  today: ['aaj', 'আজ', 'আজকে'],
  tomorrow: [
    'kal', 'kaal', 'agamikal', 'কাল', 'কালকে', 'আগামীকাল', 'আগামীকালকে', //
  ],
  dayAfter: ['porshu', 'porsu', 'পরশু', 'পরশুদিন', 'পরশুকে'],
  ambiguousDays: [
    'kal', 'kaal', 'কাল', 'কালকে', //
    'porshu', 'porsu', 'পরশু', 'পরশুদিন', 'পরশুকে',
  ],
  weekdays: {
    'shombar': 1, 'sombar': 1, 'সোমবার': 1, 'সোমবারে': 1,
    'mongolbar': 2, 'মঙ্গলবার': 2, 'মঙ্গলবারে': 2,
    'budhbar': 3, 'বুধবার': 3, 'বুধবারে': 3,
    'brihoshpotibar': 4, 'bishudbar': 4, 'বৃহস্পতিবার': 4, 'বৃহস্পতিবারে': 4,
    'shukrobar': 5, 'sukrobar': 5, 'শুক্রবার': 5, 'শুক্রবারে': 5,
    'shonibar': 6, 'sonibar': 6, 'শনিবার': 6, 'শনিবারে': 6,
    'robibar': 7, 'রবিবার': 7, 'রবিবারে': 7, //
  },
  months: {
    'jonuari': 1, 'জানুয়ারি': 1,
    'februari': 2, 'ফেব্রুয়ারি': 2,
    'march': 3, 'মার্চ': 3,
    'epril': 4, 'april': 4, 'এপ্রিল': 4,
    'মে': 5,
    'jun': 6, 'জুন': 6,
    'julai': 7, 'জুলাই': 7,
    'agost': 8, 'আগস্ট': 8,
    'september': 9, 'সেপ্টেম্বর': 9,
    'oktobor': 10, 'অক্টোবর': 10,
    'november': 11, 'নভেম্বর': 11,
    'disembor': 12, 'ডিসেম্বর': 12, //
  },
  parts: {
    'shokal': _subah, 'shokale': _subah, 'sokal': _subah,
    'সকাল': _subah, 'সকালে': _subah,
    'bhor': _bhor, 'ভোর': _bhor, 'ভোরে': _bhor,
    'dupur': _dopahar, 'dupure': _dopahar,
    'দুপুর': _dopahar, 'দুপুরে': _dopahar,
    'bikel': _bikel, 'bikal': _bikel, 'bikele': _bikel,
    'বিকেল': _bikel, 'বিকেলে': _bikel, 'বিকাল': _bikel, 'বিকালে': _bikel,
    'shondhya': _sondhya, 'sondhya': _sondhya, 'sondhe': _sondhya,
    'সন্ধ্যা': _sondhya, 'সন্ধ্যায়': _sondhya, 'সন্ধ্যে': _sondhya,
    'raat': _raat, 'রাত': _raat, 'রাতে': _raat, //
  },
  clock: [
    'ta', 'tay', 'baje', 'টা', 'টায়', 'টার', 'টে', 'টার সময়', 'বাজে', //
  ],
  weakClock: ['ta', 'টা'],
  daily: ['protidin', 'rojj', 'প্রতিদিন', 'প্রতি দিন', 'রোজ'],
  every: ['proti', 'prati', 'প্রতি'],
  after: ['pore', 'por', 'পরে', 'পর'],
  units: {
    'minit': 'm', 'minute': 'm', 'মিনিট': 'm',
    'ghonta': 'h', 'ghanta': 'h', 'ঘণ্টা': 'h', 'ঘন্টা': 'h',
    'din': 'd', 'দিন': 'd',
    'shoptaho': 'w', 'saptaho': 'w', 'সপ্তাহ': 'w',
    'mash': 'mo', 'mas': 'mo', 'মাস': 'mo',
    'bochor': 'y', 'bachar': 'y', 'বছর': 'y', //
  },
  numbers: {
    'ek': 1, 'এক': 1,
    'dui': 2, 'দুই': 2, 'দু': 2,
    'tin': 3, 'তিন': 3,
    'char': 4, 'চার': 4,
    'panch': 5, 'পাঁচ': 5,
    'chhoy': 6, 'choy': 6, 'ছয়': 6, "ছ'": 6, 'ছ’': 6,
    'shat': 7, 'saat': 7, 'সাত': 7,
    'aat': 8, 'aath': 8, 'আট': 8,
    'noy': 9, 'নয়': 9, "ন'": 9, 'ন’': 9,
    'dosh': 10, 'দশ': 10,
    'egaro': 11, 'এগারো': 11,
    'baro': 12, 'বারো': 12, //
  },
  fractions: {
    'সাড়ে': 30, 'sare': 30, 'share': 30,
    'সোয়া': 15, 'shoa': 15,
    'পৌনে': -15, 'poune': -15, //
  },
  specials: {
    'দেড়': (1, 30),
    'der': (1, 30),
    'আড়াই': (2, 30),
    'arai': (2, 30),
  },
  next: ['agami', 'আগামী'],
  quantities: {'দেড়': 1.5, 'der': 1.5, 'আড়াই': 2.5, 'arai': 2.5, 'আধ': 0.5},
  glue: [
    'মনে করিয়ে দিও', 'মনে করিয়ে দাও', 'mone koriye dio', //
    'ke', 'ki', 'mone', 'koriye', 'dio', 'debe', //
    'আমাকে', 'মনে', 'করিয়ে', 'দিও', 'দেবে',
  ],
);
