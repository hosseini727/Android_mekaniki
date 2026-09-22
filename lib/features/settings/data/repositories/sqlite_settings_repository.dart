import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/shop_settings.dart';
import '../../domain/repositories/settings_repository.dart';

class SqliteSettingsRepository implements SettingsRepository {
  @override
  Future<ShopSettings> read() async {
    final db = await AppDatabase.instance();
    final rows = await db.query('settings');
    final map = {for (final row in rows) row['key'] as String: row['value'] as String};
    return ShopSettings(
      shopName: map['shop_name'] ?? ShopSettings.defaults.shopName,
      ownerName: map['owner_name'] ?? ShopSettings.defaults.ownerName,
      phone: map['phone'] ?? ShopSettings.defaults.phone,
      address: map['address'] ?? ShopSettings.defaults.address,
    );
  }

  @override
  Future<ShopSettings> save(ShopSettings settings) async {
    final db = await AppDatabase.instance();
    final values = {
      'shop_name': settings.shopName,
      'owner_name': settings.ownerName,
      'phone': settings.phone,
      'address': settings.address,
    };
    for (final entry in values.entries) {
      await db.insert('settings', {'key': entry.key, 'value': entry.value}, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    return settings;
  }
}
