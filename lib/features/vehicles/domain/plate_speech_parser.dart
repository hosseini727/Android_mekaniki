import 'entities/vehicle.dart';
import 'plate_parser.dart';

class PlateSpeechParser {
  static const _persianDigits = {
    '۰': '0',
    '۱': '1',
    '۲': '2',
    '۳': '3',
    '۴': '4',
    '۵': '5',
    '۶': '6',
    '۷': '7',
    '۸': '8',
    '۹': '9',
    '٠': '0',
    '١': '1',
    '٢': '2',
    '٣': '3',
    '٤': '4',
    '٥': '5',
    '٦': '6',
    '٧': '7',
    '٨': '8',
    '٩': '9',
  };

  static const _letterNames = [
    MapEntry('شین', 'ش'),
    MapEntry('سین', 'س'),
    MapEntry('جیم', 'ج'),
    MapEntry('دال', 'د'),
    MapEntry('صاد', 'ص'),
    MapEntry('قاف', 'ق'),
    MapEntry('لام', 'ل'),
    MapEntry('میم', 'م'),
    MapEntry('نون', 'ن'),
    MapEntry('واو', 'و'),
    MapEntry('عین', 'ع'),
    MapEntry('الف', 'ا'),
    MapEntry('کاف', 'ک'),
    MapEntry('گاف', 'گ'),
    MapEntry('طا', 'ط'),
    MapEntry('ته', 'ت'),
    MapEntry('په', 'پ'),
    MapEntry('ثا', 'ث'),
    MapEntry('ژه', 'ژ'),
    MapEntry('زه', 'ز'),
    MapEntry('فه', 'ف'),
    MapEntry('یه', 'ی'),
    MapEntry('یای', 'ی'),
    MapEntry('با', 'ب'),
    MapEntry('به', 'ب'),
  ];

  static const _numberWords = {
    'نهصد': 900,
    'هشتصد': 800,
    'هفتصد': 700,
    'ششصد': 600,
    'پانصد': 500,
    'چهارصد': 400,
    'سیصد': 300,
    'دویست': 200,
    'صد': 100,
    'نوزده': 19,
    'هجده': 18,
    'هفده': 17,
    'شانزده': 16,
    'پانزده': 15,
    'چهارده': 14,
    'سیزده': 13,
    'دوازده': 12,
    'یازده': 11,
    'نود': 90,
    'هشتاد': 80,
    'هفتاد': 70,
    'شصت': 60,
    'پنجاه': 50,
    'چهل': 40,
    'سی': 30,
    'بیست': 20,
    'ده': 10,
    'نه': 9,
    'هشت': 8,
    'هفت': 7,
    'شش': 6,
    'پنج': 5,
    'چهار': 4,
    'سه': 3,
    'دو': 2,
    'یک': 1,
    'صفر': 0,
  };

  static IranPlate? fromSpeech(String raw) {
    final prepared = _prepare(raw);
    return PlateParser.fromOcr(prepared);
  }

  static String _prepare(String raw) {
    final buffer = StringBuffer();
    for (final rune in raw.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_persianDigits[char] ?? char);
    }
    var text = ' ${buffer.toString()} ';
    text = text.replaceAll(RegExp(r'پلاک|ایران|ايران'), ' ');
    final letterKeys = [..._letterNames]..sort((a, b) => b.key.length.compareTo(a.key.length));
    for (final entry in letterKeys) {
      text = text.replaceAll(entry.key, ' ${entry.value} ');
    }
    final numberKeys = _numberWords.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
    for (final word in numberKeys) {
      text = text.replaceAll(word, ' ${_numberWords[word]} ');
    }
    text = text.replaceAll(RegExp(r'[،,]'), ' ');
    return _composeNumbers(text.replaceAll(RegExp(r'\s+'), ' ').trim());
  }

  static String _composeNumbers(String text) {
    if (text.isEmpty) {
      return text;
    }
    final tokens = text.split(' ');
    final out = <String>[];
    int? acc;
    var joinWithVa = false;

    void flush() {
      if (acc != null) {
        out.add('$acc');
        acc = null;
      }
      joinWithVa = false;
    }

    for (final token in tokens) {
      if (token == 'و') {
        if (acc != null) {
          joinWithVa = true;
        }
        continue;
      }
      final letter = _letterToken(token);
      if (letter != null) {
        flush();
        out.add(letter);
        continue;
      }
      final number = int.tryParse(token);
      if (number == null) {
        flush();
        out.add(token);
        continue;
      }
      if (acc == null) {
        acc = number;
        joinWithVa = false;
        continue;
      }
      if (joinWithVa || _shouldAdd(acc!, number)) {
        acc = acc! + number;
        joinWithVa = false;
      } else {
        acc = int.parse('$acc$number');
      }
    }
    flush();
    return out.join(' ');
  }

  static const _letterTokens = {
    'بی': 'ب',
    'به': 'ب',
    'با': 'ب',
    'be': 'ب',
    'ba': 'ب',
    'b': 'ب',
    'je': 'ج',
    'dal': 'د',
    'sin': 'س',
    'shin': 'ش',
  };

  static String? _letterToken(String token) {
    if (IranPlate.letters.contains(token)) {
      return token;
    }
    return _letterTokens[token.toLowerCase()];
  }

  static bool _shouldAdd(int acc, int next) {
    if (acc % 10 != 0) {
      return false;
    }
    if (acc >= 100 && next < 100) {
      return true;
    }
    if (acc >= 20 && acc < 100 && next < 10) {
      return true;
    }
    return false;
  }
}
