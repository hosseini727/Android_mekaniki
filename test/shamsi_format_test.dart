import 'package:flutter_test/flutter_test.dart';
import 'package:kargah_yar/core/utils/shamsi_format.dart';

void main() {
  test('formats Gregorian date as Jalali with Persian digits', () {
    final date = DateTime(2026, 8, 17);
    expect(ShamsiFormat.numeric(date), '۱۴۰۵/۰۵/۲۶');
    expect(ShamsiFormat.full(date), '۲۶ مرداد ۱۴۰۵');
    expect(ShamsiFormat.monthDay(date), '۲۶ مرداد');
    expect(ShamsiFormat.fileStamp(date), '14050526');
  });
}
