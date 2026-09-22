import 'package:shamsi_date/shamsi_date.dart';

class ShamsiFormat {
  ShamsiFormat._();

  static const _digits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

  static String full(DateTime date) {
    final f = Jalali.fromDateTime(date).formatter;
    return _fa('${f.d} ${f.mN} ${f.yyyy}');
  }

  static String monthYear(DateTime date) {
    final f = Jalali.fromDateTime(date).formatter;
    return _fa('${f.mN} ${f.yyyy}');
  }

  static String monthDay(DateTime date) {
    final f = Jalali.fromDateTime(date).formatter;
    return _fa('${f.d} ${f.mN}');
  }

  static String numeric(DateTime date) {
    final f = Jalali.fromDateTime(date).formatter;
    return _fa('${f.yyyy}/${f.mm}/${f.dd}');
  }

  static String withTime(DateTime date) {
    final time =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return _fa('${full(date)}، $time');
  }

  static String fileStamp(DateTime date) {
    final j = Jalali.fromDateTime(date);
    final month = j.month.toString().padLeft(2, '0');
    final day = j.day.toString().padLeft(2, '0');
    return '${j.year}$month$day';
  }

  static String fileStampTime(DateTime date) {
    final time =
        '${date.hour.toString().padLeft(2, '0')}${date.minute.toString().padLeft(2, '0')}';
    return '${fileStamp(date)}-$time';
  }

  static String _fa(String raw) {
    final buffer = StringBuffer();
    for (final unit in raw.codeUnits) {
      if (unit >= 48 && unit <= 57) {
        buffer.write(_digits[unit - 48]);
      } else {
        buffer.writeCharCode(unit);
      }
    }
    return buffer.toString();
  }
}
