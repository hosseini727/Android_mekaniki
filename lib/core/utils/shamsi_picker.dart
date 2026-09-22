import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

class ShamsiPicker {
  ShamsiPicker._();

  static Future<DateTime?> date(
    BuildContext context, {
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final picked = await showPersianDatePicker(
      context: context,
      initialDate: Jalali.fromDateTime(initialDate),
      firstDate: Jalali.fromDateTime(firstDate ?? DateTime(2001, 3, 21)),
      lastDate: Jalali.fromDateTime(lastDate ?? DateTime.now()),
      helpText: 'انتخاب تاریخ',
      cancelText: 'انصراف',
      confirmText: 'تأیید',
      textDirection: TextDirection.rtl,
      locale: const Locale('fa', 'IR'),
    );
    return picked?.toDateTime();
  }
}
