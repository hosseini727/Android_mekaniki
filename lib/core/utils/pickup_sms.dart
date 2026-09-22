import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/settings/domain/entities/shop_settings.dart';
import '../../features/vehicles/domain/entities/vehicle.dart';

class PickupSms {
  static String message({
    required Vehicle vehicle,
    required String jobTitle,
    ShopSettings? shop,
  }) {
    final shopName = (shop?.shopName.isNotEmpty ?? false) ? shop!.shopName : 'کارگاه';
    final buffer = StringBuffer();
    buffer.writeln('سلام ${vehicle.ownerName}');
    buffer.writeln('کار «$jobTitle» روی خودرو با پلاک ${vehicle.plate.display} تمام شد.');
    buffer.writeln('لطفاً برای تحویل ماشین به $shopName تشریف بیاورید.');
    if (shop != null && shop.address.isNotEmpty) {
      buffer.writeln('آدرس: ${shop.address}');
    }
    if (shop != null && shop.phone.isNotEmpty) {
      buffer.writeln('تماس کارگاه: ${shop.phone}');
    }
    return buffer.toString().trim();
  }

  static String normalizePhone(String raw) {
    var phone = raw.replaceAll(RegExp(r'[\s-]'), '');
    if (phone.startsWith('+98')) {
      phone = '0${phone.substring(3)}';
    } else if (phone.startsWith('0098')) {
      phone = '0${phone.substring(4)}';
    } else if (phone.startsWith('98') && phone.length >= 12) {
      phone = '0${phone.substring(2)}';
    }
    return phone;
  }

  static Future<SmsSendResult> openOnDevice({
    required String phone,
    required String body,
  }) async {
    final number = normalizePhone(phone);
    if (number.isEmpty) {
      return SmsSendResult.missingPhone;
    }
    // فاصله باید %20 باشد نه + — خیلی از اپ‌های پیامک + را فاصله حساب نمی‌کنند
    final uri = Uri.parse('sms:$number?body=${Uri.encodeComponent(body)}');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (launched) {
        return SmsSendResult.opened;
      }
    } catch (_) {}
    await Clipboard.setData(ClipboardData(text: body));
    return SmsSendResult.copied;
  }
}

enum SmsSendResult { opened, copied, missingPhone }
