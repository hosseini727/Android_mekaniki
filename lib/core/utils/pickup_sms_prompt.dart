import 'package:flutter/material.dart';

import '../../features/settings/domain/entities/shop_settings.dart';
import '../../features/vehicles/domain/entities/vehicle.dart';
import 'pickup_sms.dart';

class PickupSmsPrompt {
  static Future<void> show({
    required BuildContext context,
    required Vehicle vehicle,
    required String jobTitle,
    ShopSettings? shop,
  }) async {
    if (vehicle.ownerPhone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('موبایل مشتری ثبت نشده. اول شماره را در پرونده بگذار.')),
      );
      return;
    }
    final body = PickupSms.message(vehicle: vehicle, jobTitle: jobTitle, shop: shop);
    final send = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('اطلاع به مشتری'),
          content: Text(
            'کار تمام شد. پیامک از گوشی خودت برای ${vehicle.ownerName} باز می‌شود. ارسال را خودت در برنامه پیامک بزن.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('بعداً')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('باز کردن پیامک')),
          ],
        );
      },
    );
    if (send != true || !context.mounted) {
      return;
    }
    final result = await PickupSms.openOnDevice(phone: vehicle.ownerPhone, body: body);
    if (!context.mounted) {
      return;
    }
    switch (result) {
      case SmsSendResult.opened:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('پیامک باز شد. ارسال را روی گوشی تأیید کن.')),
        );
      case SmsSendResult.copied:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('متن کپی شد. روی گوشی در پیامک برای مشتری بفرست.')),
        );
      case SmsSendResult.missingPhone:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('موبایل مشتری ثبت نشده.')),
        );
    }
  }
}
