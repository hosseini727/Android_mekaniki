import 'entities/vehicle.dart';

class PlateParser {
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

  static const _latinToLetter = {
    'B': 'ب',
    'C': 'ج',
    'J': 'ج',
    'D': 'د',
    'S': 'س',
    'W': 'ش',
    'Q': 'ق',
    'L': 'ل',
    'M': 'م',
    'N': 'ن',
    'V': 'و',
    'O': 'و',
    'H': 'ه',
    'Y': 'ی',
    'T': 'ت',
    'A': 'ع',
    'E': 'ع',
    'P': 'پ',
    'F': 'ف',
    'K': 'ک',
    'G': 'گ',
    'Z': 'ز',
  };

  static const _multiAliases = {
    'SH': 'ش',
    'GH': 'ق',
    'KH': 'خ',
    'ZH': 'ژ',
    'AIN': 'ع',
    'TE': 'ت',
  };

  static final _platePattern = RegExp(
    r'(\d{2})([A-Za-z]|[آابپتثجچحخدذرزژسشصضطظعغفقکگلمنوهیئي])(\d{3})(\d{2})',
  );

  static IranPlate? fromOcr(String raw) {
    final compact = _normalize(raw);
    for (final match in _platePattern.allMatches(compact)) {
      final letter = _canonicalLetter(match.group(2)!);
      if (letter == null) {
        continue;
      }
      return IranPlate(
        two: match.group(1)!,
        letter: letter,
        three: match.group(3)!,
        region: match.group(4)!,
      );
    }
    return _fromDigitsOnly(compact);
  }

  static String? _canonicalLetter(String token) {
    if (IranPlate.letters.contains(token)) {
      return token;
    }
    return _latinToLetter[token.toUpperCase()];
  }

  static IranPlate? _fromDigitsOnly(String compact) {
    final digits = compact.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7) {
      return null;
    }
    for (var i = 0; i <= digits.length - 7; i++) {
      final slice = digits.substring(i, i + 7);
      final region = slice.substring(5, 7);
      if (region == '00') {
        continue;
      }
      return IranPlate(
        two: slice.substring(0, 2),
        letter: IranPlate.empty().letter,
        three: slice.substring(2, 5),
        region: region,
      );
    }
    return null;
  }

  static String _normalize(String raw) {
    final buffer = StringBuffer();
    for (final rune in raw.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_persianDigits[char] ?? char);
    }
    var text = buffer.toString().toUpperCase();
    text = text.replaceAll(RegExp(r'I\.?\s*R\.?\s*IRAN'), '');
    text = text.replaceAll(RegExp(r'اير[اآ]ن'), '');
    text = text.replaceAll(RegExp(r'ایر[اآ]ن'), '');
    text = text.replaceAll('IRAN', '');
    _multiAliases.forEach((alias, letter) {
      text = text.replaceAll(alias, letter);
    });
    return text.replaceAll(RegExp(r'[^0-9A-Zآ-یي]'), '');
  }
}
