import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:kargah_yar/core/utils/toman_input_formatter.dart';

void main() {
  test('groups toman input every three digits', () {
    final formatter = TomanInputFormatter();
    final next = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '1850000', selection: TextSelection.collapsed(offset: 7)),
    );
    expect(next.text, '1,850,000');
    expect(TomanInputFormatter.parse(next.text), 1850000);
  });

  test('parses persian digits and separators', () {
    expect(TomanInputFormatter.parse('۱٬۲۵۰٬۰۰۰'), 1250000);
    expect(TomanInputFormatter.parse('450,000'), 450000);
  });
}
