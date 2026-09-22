import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class TomanInputFormatter extends TextInputFormatter {
  TomanInputFormatter();

  static final _grouped = NumberFormat('#,###', 'en_US');
  static const _persian = '۰۱۲۳۴۵۶۷۸۹';
  static const _arabic = '٠١٢٣٤٥٦٧٨٩';

  static String formatInt(int amount) {
    if (amount <= 0) {
      return '';
    }
    return _grouped.format(amount);
  }

  static int parse(String raw) {
    final latin = toLatinDigits(raw).replaceAll(RegExp(r'[^0-9]'), '');
    if (latin.isEmpty) {
      return 0;
    }
    return int.tryParse(latin) ?? 0;
  }

  static String toLatinDigits(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);
      final persian = _persian.indexOf(char);
      if (persian >= 0) {
        buffer.write(persian);
        continue;
      }
      final arabic = _arabic.indexOf(char);
      if (arabic >= 0) {
        buffer.write(arabic);
        continue;
      }
      buffer.write(char);
    }
    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final latin = toLatinDigits(newValue.text).replaceAll(RegExp(r'[^0-9]'), '');
    if (latin.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final trimmed = latin.replaceFirst(RegExp(r'^0+'), '');
    final digits = trimmed.isEmpty ? '0' : trimmed;
    final formatted = _grouped.format(int.parse(digits));
    final before = toLatinDigits(
      newValue.text.substring(0, newValue.selection.end.clamp(0, newValue.text.length)),
    ).replaceAll(RegExp(r'[^0-9]'), '');
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: _offsetForDigits(formatted, before.length)),
    );
  }

  static int _offsetForDigits(String formatted, int digitCount) {
    if (digitCount <= 0) {
      return 0;
    }
    var seen = 0;
    for (var i = 0; i < formatted.length; i++) {
      final unit = formatted.codeUnitAt(i);
      if (unit >= 48 && unit <= 57) {
        seen++;
        if (seen >= digitCount) {
          return i + 1;
        }
      }
    }
    return formatted.length;
  }
}
