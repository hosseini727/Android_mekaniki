class VoiceLine {
  const VoiceLine({
    required this.label,
    required this.amount,
    required this.isLabor,
  });

  final String label;
  final int amount;
  final bool isLabor;
}

class VoiceParseResult {
  const VoiceParseResult({
    required this.raw,
    required this.title,
    required this.note,
    required this.laborAmount,
    required this.partsAmount,
    required this.lines,
  });

  final String raw;
  final String title;
  final String note;
  final int laborAmount;
  final int partsAmount;
  final List<VoiceLine> lines;

  int get amount => laborAmount + partsAmount;
  bool get hasAmount => amount > 0;
}

class VoiceParser {
  static const _persianDigits = {
    '۰': '0', '۱': '1', '۲': '2', '۳': '3', '۴': '4',
    '۵': '5', '۶': '6', '۷': '7', '۸': '8', '۹': '9',
    '٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4',
    '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9',
  };

  static const _units = {
    'صفر': 0, 'یک': 1, 'یه': 1, 'دو': 2, 'سه': 3,
    'چهار': 4, 'چار': 4, 'پنج': 5, 'شش': 6, 'شیش': 6,
    'هفت': 7, 'هشت': 8, 'نه': 9, 'ده': 10,
    'یازده': 11, 'دوازده': 12, 'سیزده': 13, 'چهارده': 14,
    'پانزده': 15, 'شانزده': 16, 'هفده': 17, 'هجده': 18, 'نوزده': 19,
    'بیست': 20, 'سی': 30, 'چهل': 40, 'پنجاه': 50, 'شصت': 60,
    'هفتاد': 70, 'هشتاد': 80, 'نود': 90,
    'صد': 100, 'دویست': 200, 'سیصد': 300,
    'چهارصد': 400, 'چارصد': 400,
    'پانصد': 500, 'پونصد': 500,
    'ششصد': 600, 'شیشصد': 600,
    'هفتصد': 700, 'هشتصد': 800, 'نهصد': 900,
  };

  static final _laborKeywords = RegExp(r'اجرت|دستمزد|دست مزد|کارمزد|کار مزد|کارگر');
  static final _currencyWords = {'تومان', 'تومن', 'تومانی', 'تومون', 'ریال'};

  static VoiceParseResult fromSpeech(String raw) {
    final compact = _normalize(raw);
    final hasLaborKeyword = _laborKeywords.hasMatch(compact);
    final laborSplit = compact.split(_laborKeywords);
    final workPart = laborSplit.first.trim();
    final laborPart = laborSplit.length > 1 ? laborSplit.sublist(1).join(' ').trim() : '';

    var partsAmount = _parseAmount(workPart);
    var laborAmount = _parseAmount(laborPart);

    // «دو میلیون و پونصد هزار تومن اجرت» → کل مبلغ = اجرت
    if (hasLaborKeyword && laborAmount == 0 && partsAmount > 0) {
      final titleOnly = _titleFrom(workPart);
      if (titleOnly == 'ثبت صوتی کار') {
        laborAmount = partsAmount;
        partsAmount = 0;
      }
    }

    // اگر فقط یک مبلغ در کل متن است و کلمه اجرت هست
    if (hasLaborKeyword && laborAmount == 0 && partsAmount == 0) {
      final fallback = _parseAmount(compact);
      laborAmount = fallback;
    }

    if (laborAmount == 0 && partsAmount == 0) {
      final fallback = _parseAmount(compact);
      return VoiceParseResult(
        raw: raw,
        title: _titleFrom(workPart.isEmpty ? compact : workPart),
        note: compact,
        laborAmount: hasLaborKeyword ? fallback : 0,
        partsAmount: hasLaborKeyword ? 0 : fallback,
        lines: [
          if (fallback > 0)
            VoiceLine(
              label: hasLaborKeyword ? 'اجرت' : 'مبلغ',
              amount: fallback,
              isLabor: hasLaborKeyword,
            ),
        ],
      );
    }

    final title = _titleFrom(workPart);
    return VoiceParseResult(
      raw: raw,
      title: title == 'ثبت صوتی کار' && laborAmount > 0 ? 'اجرت' : title,
      note: compact,
      laborAmount: laborAmount,
      partsAmount: partsAmount,
      lines: [
        if (partsAmount > 0) VoiceLine(label: title, amount: partsAmount, isLabor: false),
        if (laborAmount > 0) VoiceLine(label: 'اجرت', amount: laborAmount, isLabor: true),
      ],
    );
  }

  static final _stopWords = {
    'میلیون', 'میلیارد', 'هزار', 'تومان', 'تومن', 'تومانی', 'تومون', 'ریال', 'و', 'نیم',
    'صفر', 'یک', 'یه', 'دو', 'سه', 'چهار', 'چار', 'پنج', 'شش', 'شیش', 'هفت', 'هشت', 'نه',
    'ده', 'یازده', 'دوازده', 'سیزده', 'چهارده', 'پانزده', 'شانزده',
    'هفده', 'هجده', 'نوزده', 'بیست', 'سی', 'چهل', 'پنجاه', 'شصت',
    'هفتاد', 'هشتاد', 'نود', 'صد', 'دویست', 'سیصد', 'چهارصد', 'چارصد',
    'پانصد', 'پونصد', 'ششصد', 'شیشصد', 'هفتصد', 'هشتصد', 'نهصد',
    'اجرت', 'دستمزد', 'کارمزد', 'کارگر', 'قطعه', 'هزینه', 'مبلغ', 'قیمت',
  };

  static String _titleFrom(String workPart) {
    final tokens = workPart
        .replaceAll(RegExp(r'[0-9]+'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty && !_stopWords.contains(t))
        .toList();
    final text = tokens.join(' ').trim();
    if (text.length < 2) return 'ثبت صوتی کار';
    return text;
  }

  /// پارس قوی مبالغ فارسی گفتاری
  static int _parseAmount(String raw) {
    if (raw.trim().isEmpty) return 0;

    final tokens = raw
        .replaceAll(RegExp(r'[،,]'), ' ')
        .split(RegExp(r'\s+'))
        .where((item) => item.isNotEmpty)
        .toList();

    var total = 0;
    var group = 0;
    var lastScale = 1;
    var found = false;
    var halfPending = false;

    void flush({int scale = 1, bool asThousandsAfterMillion = false}) {
      if (group == 0 && scale == 1 && !halfPending) return;
      var value = group;
      if (halfPending) {
        value = value == 0 ? 500 : value * 1000 + 500;
        // برای میلیون: «دو و نیم» → group=2, half → 2.5 → بعداً * میلیون
        if (scale == 1000000) {
          value = (group == 0 ? 1 : group) * 1000000 + 500000;
          total += value;
          group = 0;
          halfPending = false;
          found = true;
          lastScale = scale;
          return;
        }
        if (scale == 1000) {
          value = (group == 0 ? 1 : group) * 1000 + 500;
          // نیم هزار نادر است؛ بیشتر «نیم» قبل میلیون است
        }
        halfPending = false;
      }
      if (asThousandsAfterMillion && value > 0 && value < 1000) {
        value *= 1000;
      }
      if (value == 0 && scale > 1) value = 1;
      total += value * scale;
      group = 0;
      found = true;
      lastScale = scale;
    }

    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];

      if (token == 'و') continue;

      if (token == 'نیم') {
        // «نیم میلیون» یا «دو و نیم میلیون»
        if (i + 1 < tokens.length && tokens[i + 1] == 'میلیون') {
          if (group > 0) {
            total += group * 1000000 + 500000;
          } else {
            total += 500000;
          }
          group = 0;
          found = true;
          lastScale = 1000000;
          i++;
          continue;
        }
        halfPending = true;
        continue;
      }

      if (token == 'میلیارد') {
        if (group == 0) group = 1;
        flush(scale: 1000000000);
        continue;
      }
      if (token == 'میلیون') {
        if (halfPending) {
          flush(scale: 1000000);
          continue;
        }
        if (group == 0) group = 1;
        flush(scale: 1000000);
        continue;
      }
      if (token == 'هزار') {
        if (group == 0) group = 1;
        flush(scale: 1000);
        continue;
      }
      if (_currencyWords.contains(token)) {
        if (group > 0 || halfPending) {
          flush(scale: 1, asThousandsAfterMillion: lastScale == 1000000);
        }
        continue;
      }

      final unit = _units[token];
      if (unit != null) {
        group += unit;
        continue;
      }

      final digits = int.tryParse(token);
      if (digits != null) {
        // اعداد خام: اگر خیلی بزرگ بود مستقیم جمع کن
        if (digits >= 1000) {
          if (group > 0) flush(scale: 1);
          total += digits;
          found = true;
          lastScale = digits >= 1000000 ? 1000000 : (digits >= 1000 ? 1000 : 1);
        } else {
          group += digits;
        }
      }
    }

    if (group > 0 || halfPending) {
      flush(scale: 1, asThousandsAfterMillion: lastScale == 1000000);
    }

    if (!found) {
      final digits = RegExp(r'\d+').allMatches(raw).map((m) => int.parse(m.group(0)!)).toList();
      if (digits.isEmpty) return 0;
      return digits.reduce((a, b) => a > b ? a : b);
    }
    return total;
  }

  static const _knownWords = [
    'تعویض', 'فیلتر', 'روغن', 'ترمز', 'دیسک', 'باتری', 'رادیاتور',
    'کاربوراتور', 'شمع', 'تسمه', 'کلاچ', 'سوپاپ', 'سیلندر', 'گیربکس',
    'کمک‌فنر', 'کمک فنر', 'فنر', 'لنت', 'پمپ', 'واتر', 'واتر پمپ',
    'اگزوز', 'مفصل', 'میل', 'میل گاردان', 'اویل', 'اویل پمپ',
    'دستمزد', 'کارمزد', 'اجرت',
  ];

  static String _fixSplitWords(String text) {
    var result = text;
    for (final word in _knownWords) {
      if (result.contains(word)) continue;
      final chars = word.runes.toList();
      for (var split = 1; split < chars.length; split++) {
        final part1 = String.fromCharCodes(chars.sublist(0, split));
        final part2 = String.fromCharCodes(chars.sublist(split));
        final broken = '$part1 $part2';
        if (result.contains(broken)) {
          result = result.replaceAll(broken, word);
          break;
        }
      }
    }
    return result;
  }

  static const _spokenFixes = {
    'تع ویض': 'تعویض', 'تع یض': 'تعویض', 'تعوی ض': 'تعویض',
    'تعو یض': 'تعویض', 'تع و یض': 'تعویض', 'ت عویض': 'تعویض',
    'عوض شد': 'تعویض', 'عوضش کردم': 'تعویض', 'عوض کردم': 'تعویض',
    'فیل تر': 'فیلتر', 'فی لتر': 'فیلتر', 'فیلت ر': 'فیلتر',
    'روغ ن': 'روغن', 'رو غن': 'روغن',
    'ت رمز': 'ترمز', 'تر مز': 'ترمز', 'ترم ز': 'ترمز',
    'دیس ک': 'دیسک', 'دی سک': 'دیسک',
    'باط ری': 'باتری', 'بات ری': 'باتری', 'با تری': 'باتری',
    'رادیات ور': 'رادیاتور', 'رادیا تور': 'رادیاتور', 'رادی اتور': 'رادیاتور',
    'کار بوراتور': 'کاربوراتور', 'کارب وراتور': 'کاربوراتور',
    'تس مه': 'تسمه', 'سوپ اپ': 'سوپاپ', 'سو پاپ': 'سوپاپ',
    'دست مزد': 'دستمزد', 'کار مزد': 'کارمزد',
  };

  static String _normalize(String raw) {
    final buffer = StringBuffer();
    for (final rune in raw.runes) {
      final char = String.fromCharCode(rune);
      // فاصله‌های خاص، نیم‌فاصله، خط جدید → فاصله معمولی
      if (rune == 0x200C || rune == 0x200D || rune == 0x200B ||
          rune == 0x00A0 || rune == 0x202F || rune == 0x2009 ||
          rune == 0x000A || rune == 0x000D || rune == 0x2028 || rune == 0x2029) {
        buffer.write(' ');
      } else if (char == '+' || char == '|' || char == '·' || char == '•') {
        buffer.write(' ');
      } else {
        buffer.write(_persianDigits[char] ?? char);
      }
    }

    var result = buffer.toString();
    // بعضی گوشی‌ها بین کلمات خط جدید می‌گذارند
    result = result.replaceAll(RegExp(r'[\r\n\t]+'), ' ');
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();

    const amountFixes = {
      'پونصد': 'پانصد',
      'شیشصد': 'ششصد',
      'چارصد': 'چهارصد',
      'تومن': 'تومان',
      'تومون': 'تومان',
      'تومانی': 'تومان',
      'میلیونتومان': 'میلیون تومان',
      'هزارتومان': 'هزار تومان',
      'دومیلیون': 'دو میلیون',
      'سهمیلیون': 'سه میلیون',
      'یه میلیون': 'یک میلیون',
      'یهمیلیون': 'یک میلیون',
      'نیم میلیون': 'نیم میلیون',
      'نیممیلیون': 'نیم میلیون',
      'دوونیم': 'دو و نیم',
      'دو و نیم': 'دو و نیم',
      'یک و نیم': 'یک و نیم',
      'یه و نیم': 'یک و نیم',
    };
    for (final entry in amountFixes.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    for (final entry in _spokenFixes.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    result = _fixSplitWords(result);
    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
