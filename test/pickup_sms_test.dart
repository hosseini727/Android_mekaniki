import 'package:flutter_test/flutter_test.dart';
import 'package:kargah_yar/core/utils/pickup_sms.dart';
import 'package:kargah_yar/features/settings/domain/entities/shop_settings.dart';
import 'package:kargah_yar/features/vehicles/domain/entities/vehicle.dart';

void main() {
  test('normalizes Iranian phone numbers', () {
    expect(PickupSms.normalizePhone('+98 912 123 4567'), '09121234567');
    expect(PickupSms.normalizePhone('989121234567'), '09121234567');
  });

  test('builds pickup sms for the customer', () {
    const vehicle = Vehicle(
      id: 1,
      plateKey: '12ب34522',
      ownerName: 'علی رضایی',
      ownerPhone: '09121234567',
      make: 'پژو',
      model: '۲۰۶',
      year: '1398',
      color: 'سفید',
      mileage: 80000,
    );
    final text = PickupSms.message(
      vehicle: vehicle,
      jobTitle: 'تعویض لنت',
      shop: ShopSettings.defaults,
    );
    expect(text.contains('علی رضایی'), isTrue);
    expect(text.contains('تمام شد'), isTrue);
    expect(text.contains('12 ب 345'), isTrue);
  });
}
