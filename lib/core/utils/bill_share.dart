import '../../features/settings/domain/entities/shop_settings.dart';
import '../../features/vehicles/domain/entities/vehicle.dart';
import '../../features/visits/domain/entities/service_visit.dart';
import '../constants/app_info.dart';
import 'money_format.dart';
import 'shamsi_format.dart';

class BillShare {
  static String text({
    required ServiceVisit visit,
    Vehicle? vehicle,
    ShopSettings? shop,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(shop?.shopName ?? AppInfo.nameFa);
    if (shop != null && shop.phone.isNotEmpty) {
      buffer.writeln('تماس: ${shop.phone}');
    }
    buffer.writeln('----------------');
    if (vehicle != null) {
      if (vehicle.title.isNotEmpty) {
        buffer.writeln('ماشین: ${vehicle.title}');
      }
      if (vehicle.ownerName.isNotEmpty) {
        buffer.writeln('مالک: ${vehicle.ownerName}');
      }
    }
    buffer.writeln('کار: ${visit.title}');
    buffer.writeln('تاریخ: ${ShamsiFormat.full(visit.happenedAt)}');
    if (visit.note.isNotEmpty) {
      buffer.writeln('توضیحات: ${visit.note}');
    }
    buffer.writeln('اجرت: ${MoneyFormat.toman(visit.laborAmount)}');
    if (visit.partLines.isNotEmpty) {
      for (final line in visit.partLines) {
        final qty = line.qty > 1 ? ' × ${line.qty}' : '';
        buffer.writeln('${line.name}$qty: ${MoneyFormat.toman(line.total)}');
      }
    } else if (visit.partsAmount > 0) {
      buffer.writeln('قطعه: ${MoneyFormat.toman(visit.partsAmount)}');
    }
    buffer.writeln('جمع: ${MoneyFormat.toman(visit.amount)}');
    buffer.writeln(visit.paid ? 'وضعیت: تسویه شد' : 'وضعیت: پرداخت نشده');
    return buffer.toString().trim();
  }
}
